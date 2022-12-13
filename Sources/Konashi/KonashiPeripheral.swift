//
//  KonashiPeripheral.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Combine
import CombineExt
import CoreBluetooth
import Promises

private class KonashiPeripheralDelegate: NSObject {
    weak var parentPeripheral: KonashiPeripheral?

    init(peripheral: KonashiPeripheral) {
        parentPeripheral = peripheral
    }
}

public extension KonashiPeripheral {
    /// A string key to retrieve a peripheral instance from a notification userInfo.
    static let instanceKey: String = "KonashiPeripheral.instanceKey"
}

/// A remote peripheral device.
public final class KonashiPeripheral: Peripheral {
    /// An error that the reason of why a peripheral could not ready to use.
    public enum PeripheralError: Error {
        case couldNotFindCharacteristic
    }

    /// An error that a peripheral returns during read / write operation.
    public enum OperationError: LocalizedError {
        case invalidReadValue
        case couldNotReadValue
    }

    public static func == (lhs: KonashiPeripheral, rhs: KonashiPeripheral) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public static func == (lhs: KonashiPeripheral, rhs: CBPeripheral) -> Bool {
        return lhs.peripheral == rhs
    }

    public static func == (lhs: CBPeripheral, rhs: KonashiPeripheral) -> Bool {
        return lhs == rhs.peripheral
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(peripheral)
    }

    /// A service of a peripheral's setting.
    public let settingsService = SettingsService()
    /// A service of a peripheral's config.
    public let configService = ConfigService()
    /// A service to control a peripheral.
    public let controlService = ControlService()

    /// A name of a peripheral.
    public var name: String? {
        return peripheral.name
    }

    /// A collection of services of a peripheral.
    public private(set) lazy var services: [Service] = {
        return [
            settingsService,
            configService,
            controlService
        ]
    }()

    /// A connection status of a peripheral.
    public var status: ConnectionStatus {
        return currentStatus
    }

    /// A publisher of peripheral state.
    @Published public private(set) var currentStatus: ConnectionStatus = .disconnected
    /// A publisher of RSSI value.
    @Published public fileprivate(set) var rssi: NSNumber?
    /// This variable indicates that whether a peripheral is ready to use or not.
    public private(set) lazy var isReady: AnyPublisher<Bool, Never> = Publishers.CombineLatest3(
        $isConnected,
        $isCharacteristicsDiscovered,
        $isCharacteristicsConfigured
    ).map { connected, discovered, configured in
        return connected && discovered && configured
    }.eraseToAnyPublisher()

    /// A subject that sends any operation errors.
    public let operationErrorSubject = PassthroughSubject<Error, Never>()
    /// A subject that sends value that is written to af peripheral.
    public let didWriteValueSubject = PassthroughSubject<(uuid: CBUUID, error: Error?), Never>()

    // swiftlint:disable weak_delegate
    private lazy var delegate: KonashiPeripheralDelegate = .init(peripheral: self)

    // swiftlint:enable weak_delegate

    @Published fileprivate var isCharacteristicsDiscovered = false
    @Published fileprivate var isCharacteristicsConfigured = false
    @Published fileprivate var isConnected = false
    @Published fileprivate var isConnecting = false

    fileprivate let didUpdateValueSubject = PassthroughSubject<(characteristic: CBCharacteristic, error: Error?), Never>()
    fileprivate var readyPromise = Promise<Void>.pending()
    fileprivate var discoveredServices = [CBService]()
    fileprivate var configuredCharacteristics = [CBCharacteristic]()
    private var readRssiTimer: Timer?
    private let peripheral: CBPeripheral
    private var observation: NSKeyValueObservation?
    private var internalCancellable = Set<AnyCancellable>()

    public init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        prepareCombine()
        prepareKVO()
    }

    deinit {
        readRssiTimer?.invalidate()
    }

    // MARK: - Connection

    /// Connects to a peripheral.
    @discardableResult
    public func connect() -> Promise<any Peripheral> {
        var cancellable = Set<AnyCancellable>()
        isCharacteristicsDiscovered = false
        isCharacteristicsConfigured = false
        discoveredServices.removeAll()
        configuredCharacteristics.removeAll()
        return Promise<any Peripheral> { [unowned self] resolve, reject in
            self.isReady.sink { [weak self] ready in
                guard let weakSelf = self else {
                    return
                }
                if ready {
                    NotificationCenter.default.post(
                        name: KonashiPeripheral.readyToUse,
                        object: nil,
                        userInfo: [KonashiPeripheral.instanceKey: weakSelf]
                    )
                    resolve(weakSelf)
                }
            }.store(in: &cancellable)
            CentralManager.shared.didConnectSubject.sink { [weak self] connectedPeripheral in
                guard let weakSelf = self else {
                    return
                }
                if connectedPeripheral == weakSelf.peripheral {
                    NotificationCenter.default.post(
                        name: KonashiPeripheral.didConnect,
                        object: nil,
                        userInfo: [KonashiPeripheral.instanceKey: weakSelf]
                    )
                }
            }.store(in: &cancellable)
            CentralManager.shared.didFailedToConnectSubject.sink { [weak self] result in
                guard let weakSelf = self else {
                    return
                }
                if result.0 == weakSelf.peripheral, let error = result.1 {
                    NotificationCenter.default.post(
                        name: KonashiPeripheral.didFailedToConnect,
                        object: nil,
                        userInfo: [KonashiPeripheral.instanceKey: weakSelf]
                    )
                    reject(error)
                    weakSelf.currentStatus = .error(error)
                    weakSelf.operationErrorSubject.send(error)
                }
            }.store(in: &cancellable)
            CentralManager.shared.connect(self.peripheral)
        }.always {
            cancellable.removeAll()
        }
    }

    /// Disconnects from a peripheral.
    @discardableResult
    public func disconnect() -> Promise<Void> {
        var cancellable = Set<AnyCancellable>()
        return Promise<Void> { [weak self] resolve, reject in
            guard let weakSelf = self else {
                return
            }
            weakSelf.readyPromise = Promise<Void>.pending()
            CentralManager.shared.didDisconnectSubject.sink { [weak self] result in
                guard let weakSelf = self else {
                    return
                }
                if result.0 == weakSelf.peripheral {
                    if let error = result.1 {
                        NotificationCenter.default.post(
                            name: KonashiPeripheral.didFailedToDisconnect,
                            object: nil,
                            userInfo: [KonashiPeripheral.instanceKey: weakSelf]
                        )
                        reject(error)
                        weakSelf.currentStatus = .error(error)
                        weakSelf.operationErrorSubject.send(error)
                    }
                    else {
                        NotificationCenter.default.post(
                            name: KonashiPeripheral.didDisconnect,
                            object: nil,
                            userInfo: [KonashiPeripheral.instanceKey: weakSelf]
                        )
                        weakSelf.currentStatus = .disconnected
                        resolve(())
                    }
                }
            }.store(in: &cancellable)
            CentralManager.shared.disconnect(weakSelf.peripheral)
        }.always { [weak self] in
            if let weakSelf = self {
                weakSelf.readRssiTimer?.invalidate()
            }
            cancellable.removeAll()
        }
    }

    // MARK: - RSSI

    /// Reads RSSI value of a peripheral.
    /// - Parameters:
    ///   - repeats: Specify true to read RSSI repeatedly.
    ///   - interval: An interval of read RSSI value.
    public func readRSSI(repeats: Bool = false, interval: TimeInterval = 1) {
        peripheral.delegate = delegate
        if repeats {
            stopReadRSSI()
            readRssiTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.readRSSI()
            }
        }
        else {
            peripheral.readRSSI()
        }
    }

    /// Stops reading RSSI value.
    public func stopReadRSSI() {
        readRssiTimer?.invalidate()
    }

    // MARK: - Write/Read Command

    /// Writes command to the characteristic
    /// - Parameters:
    ///   - characteristic: The characteristic containing the value to write.
    ///   - command: The command to write.
    ///   - type: The type of write to execute. For a list of the possible types of writes to a characteristic’s value, see CBCharacteristicWriteType.
    @discardableResult
    public func write<WriteCommand: Command>(
        characteristic: WriteableCharacteristic<WriteCommand>,
        command: WriteCommand,
        type: CBCharacteristicWriteType = .withResponse
    ) -> Promise<any Peripheral> {
        print(">>> write \(characteristic) \n \(command) \n \([UInt8](command.compose()).toHexString())")
        var cancellable = Set<AnyCancellable>()
        let promise = Promise<any Peripheral>.pending()
        readyPromise.then { [weak self] _ in
            guard let weakSelf = self else {
                return
            }
            if let characteristic = weakSelf.peripheral.services?.find(characteristic: characteristic) {
                if type == .withResponse {
                    weakSelf.didWriteValueSubject.sink { uuid, error in
                        if uuid == characteristic.uuid {
                            if let error {
                                promise.reject(error)
                                weakSelf.operationErrorSubject.send(error)
                            }
                            else {
                                promise.fulfill(weakSelf)
                            }
                        }
                    }.store(in: &cancellable)
                }
                weakSelf.peripheral.writeValue(command.compose(), for: characteristic, type: type)
                if type == .withoutResponse {
                    promise.fulfill(weakSelf)
                }
            }
            else {
                promise.reject(PeripheralError.couldNotFindCharacteristic)
                weakSelf.operationErrorSubject.send(PeripheralError.couldNotFindCharacteristic)
            }
        }.catch { [weak self] error in
            promise.reject(error)
            guard let weakSelf = self else {
                return
            }
            weakSelf.operationErrorSubject.send(error)
        }
        promise.always {
            cancellable.removeAll()
        }
        return promise
    }

    /// Retrieves the value of a specified characteristic.
    /// - Parameter characteristic: The characteristic whose value you want to read.
    /// - Returns: A promise object of read value.
    @discardableResult
    public func read<Value: CharacteristicValue>(characteristic: ReadableCharacteristic<Value>) -> Promise<Value> {
        var cancellable = Set<AnyCancellable>()
        let promise = Promise<Value>.pending()
        readyPromise.then { [weak self] _ in
            guard let weakSelf = self else {
                return
            }
            if let targetCharacteristic = weakSelf.peripheral.services?.find(characteristic: characteristic) {
                weakSelf.didUpdateValueSubject.sink { updatedCharacteristic, error in
                    if updatedCharacteristic != targetCharacteristic {
                        return
                    }
                    if let error {
                        promise.reject(error)
                        weakSelf.operationErrorSubject.send(error)
                        return
                    }
                    guard let value = updatedCharacteristic.value else {
                        promise.reject(OperationError.invalidReadValue)
                        weakSelf.operationErrorSubject.send(OperationError.invalidReadValue)
                        return
                    }
                    switch characteristic.parse(data: value) {
                    case let .success(value):
                        promise.fulfill(value)
                    case let .failure(error):
                        promise.reject(error)
                        weakSelf.operationErrorSubject.send(error)
                    }
                }.store(in: &cancellable)
                weakSelf.peripheral.readValue(for: targetCharacteristic)
            }
            else {
                promise.reject(PeripheralError.couldNotFindCharacteristic)
                weakSelf.operationErrorSubject.send(PeripheralError.couldNotFindCharacteristic)
            }
        }.catch { [weak self] error in
            promise.reject(error)
            guard let weakSelf = self else {
                return
            }
            weakSelf.operationErrorSubject.send(error)
        }
        promise.always {
            cancellable.removeAll()
        }
        return promise
    }

    // MARK: - Private

    private func discoverServices() {
        print(">>> discoverServices")
        peripheral.delegate = delegate
        peripheral.discoverServices(services.map(\.serviceUUID))
    }

    fileprivate func discoverCharacteristics() {
        peripheral.delegate = delegate
        guard let discoveredSerices = peripheral.services else {
            return
        }
        for service in discoveredSerices {
            if let foundService = services.find(service: service) {
                print(">>> discoverCharacteristics \(foundService.uuid)")
                peripheral.discoverCharacteristics(foundService.characteristics.map(\.characteristicUUID), for: service)
            }
        }
    }

    private func configureCharacteristics() {
        for service in services {
            service.applyAttributes(peripheral: peripheral)
        }
    }

    fileprivate func store(characteristic: CBCharacteristic) {
        services.find(characteristic: characteristic)?.update(data: characteristic.value)
    }

    private func prepareCombine() {
        internalCancellable.removeAll()
        CentralManager.shared.didDisconnectSubject.sink { [weak self] peripheral, _ in
            guard let weakSelf = self else {
                return
            }
            if peripheral == weakSelf.peripheral {
                weakSelf.readRssiTimer?.invalidate()
                weakSelf.internalCancellable.removeAll()
            }
        }.store(in: &internalCancellable)
        $isConnecting.removeDuplicates().sink { [weak self] connecting in
            guard let weakSelf = self else {
                return
            }
            if connecting {
                weakSelf.currentStatus = .connecting
            }
        }.store(in: &internalCancellable)
        $isConnected.removeDuplicates().sink { [weak self] connected in
            guard let weakSelf = self else {
                return
            }
            if connected {
                weakSelf.currentStatus = .connected
                weakSelf.discoverServices()
            }
        }.store(in: &internalCancellable)
        $isCharacteristicsDiscovered.removeDuplicates().sink { [weak self] discovered in
            guard let weakSelf = self else {
                return
            }
            if discovered {
                weakSelf.configureCharacteristics()
            }
        }.store(in: &internalCancellable)
        isReady.removeDuplicates().sink { [weak self] ready in
            guard let weakSelf = self else {
                return
            }
            if ready {
                weakSelf.currentStatus = .readyToUse
                weakSelf.readyPromise.fulfill(())
            }
            else {
                weakSelf.readyPromise = Promise<Void>.pending()
            }
        }.store(in: &internalCancellable)
    }

    private func prepareKVO() {
        observation = peripheral.observe(
            \.state,
            options: [.old, .new]
        ) { [weak self] peripheral, _ in
            guard let weakSelf = self else {
                return
            }
            switch peripheral.state {
            case .connected:
                weakSelf.isConnected = true
                weakSelf.isConnecting = false
            case .connecting:
                weakSelf.isConnected = false
                weakSelf.isConnecting = true
            case .disconnected:
                weakSelf.isConnected = false
                weakSelf.isConnecting = false
            case .disconnecting:
                weakSelf.isConnected = false
                weakSelf.isConnecting = true
            @unknown default:
                break
            }
        }
    }
}

extension KonashiPeripheralDelegate: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print(">>> discoverServices done")
        if let error {
            parentPeripheral!.readyPromise.reject(error)
            parentPeripheral!.operationErrorSubject.send(error)
            return
        }
        parentPeripheral!.discoverCharacteristics()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print(">>> discoverCharacteristics done \(service.uuid)")
        if let error {
            parentPeripheral!.readyPromise.reject(error)
            parentPeripheral!.operationErrorSubject.send(error)
            return
        }
        parentPeripheral!.discoveredServices.append(service)
        if parentPeripheral!.discoveredServices.count == parentPeripheral!.services.count {
            parentPeripheral!.isCharacteristicsDiscovered = true
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error {
            parentPeripheral!.operationErrorSubject.send(error)
        }
        else {
            parentPeripheral!.rssi = RSSI
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print(">>> write value done")
        if let error {
            print(error.localizedDescription)
            parentPeripheral!.operationErrorSubject.send(error)
        }
        parentPeripheral!.didWriteValueSubject.send((characteristic.uuid, error))
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print(">>> update value")
        parentPeripheral!.didUpdateValueSubject.send((characteristic, error))
        if let error {
            parentPeripheral!.operationErrorSubject.send(error)
        }
        else {
            parentPeripheral!.store(characteristic: characteristic)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            parentPeripheral!.readyPromise.reject(error)
            parentPeripheral!.operationErrorSubject.send(error)
            return
        }
        parentPeripheral!.configuredCharacteristics.append(characteristic)
        let numberOfConfigureableCharacteristics = parentPeripheral!.services.flatMap(\.notifiableCharacteristics).count
        if parentPeripheral!.configuredCharacteristics.count == numberOfConfigureableCharacteristics {
            parentPeripheral!.isCharacteristicsConfigured = true
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {}
}
