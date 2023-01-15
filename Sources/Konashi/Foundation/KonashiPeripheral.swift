//
//  KonashiPeripheral.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Combine
import CombineExt
import CoreBluetooth
import nRFMeshProvision
import Promises

public extension KonashiPeripheral {
    /// A string key to retrieve a peripheral instance from a notification userInfo.
    static let instanceKey: String = "KonashiPeripheral.instanceKey"
}

// MARK: - KonashiPeripheral

/// A remote peripheral device.
public final class KonashiPeripheral: Peripheral {
    // MARK: Lifecycle

    public init(peripheral: CBPeripheral, advertisementData: [String: Any]) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        prepareCombine()
        prepareKVO()
    }

    deinit {
        readRssiTimer?.invalidate()
    }

    // MARK: Public

    /// A service of a peripheral's setting.
    public let settingsService = SettingsService()
    /// A service of a peripheral's config.
    public let configService = ConfigService()
    /// A service to control a peripheral.
    public let controlService = ControlService()

    /// A collection of services of a peripheral.
    public private(set) lazy var services: [Service] = {
        return [
            settingsService,
            configService,
            controlService
        ]
    }()

    /// A publisher of peripheral state.
    @Published public private(set) var currentConnectionStatus: ConnectionStatus = .disconnected

    /// A publisher of RSSI value.
    @Published public internal(set) var rssi: NSNumber?
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

    // TODO: Add document
    public var meshNode: NodeCompatible?
    @Published public private(set) var currentProvisioningState: ProvisioningState?

    /// A name of a peripheral.
    public var name: String? {
        return peripheral.name
    }

    /// A connection status of a peripheral.
    public var status: Published<ConnectionStatus>.Publisher {
        return $currentConnectionStatus
    }

    public var provisioningState: Published<ProvisioningState?>.Publisher {
        return $currentProvisioningState
    }

    public var isProvisionable: Bool {
        return UnprovisionedDevice(advertisementData: advertisementData) != nil
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
                guard let self else {
                    return
                }
                if ready {
                    NotificationCenter.default.post(
                        name: KonashiPeripheral.readyToUse,
                        object: nil,
                        userInfo: [KonashiPeripheral.instanceKey: self]
                    )
                    resolve(self)
                }
            }.store(in: &cancellable)
            CentralManager.shared.didConnectSubject.sink { [weak self] connectedPeripheral in
                guard let self else {
                    return
                }
                if connectedPeripheral == self.peripheral {
                    NotificationCenter.default.post(
                        name: KonashiPeripheral.didConnect,
                        object: nil,
                        userInfo: [KonashiPeripheral.instanceKey: self]
                    )
                }
            }.store(in: &cancellable)
            CentralManager.shared.didFailedToConnectSubject.sink { [weak self] result in
                guard let self else {
                    return
                }
                if result.0 == self.peripheral, let error = result.1 {
                    NotificationCenter.default.post(
                        name: KonashiPeripheral.didFailedToConnect,
                        object: nil,
                        userInfo: [KonashiPeripheral.instanceKey: self]
                    )
                    reject(error)
                    self.currentConnectionStatus = .error(error)
                    self.operationErrorSubject.send(error)
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
            guard let self else {
                return
            }
            self.readyPromise = Promise<Void>.pending()
            CentralManager.shared.didDisconnectSubject.sink { [weak self] result in
                guard let self else {
                    return
                }
                if result.0 == self.peripheral {
                    if let error = result.1 {
                        NotificationCenter.default.post(
                            name: KonashiPeripheral.didFailedToDisconnect,
                            object: nil,
                            userInfo: [KonashiPeripheral.instanceKey: self]
                        )
                        reject(error)
                        self.currentConnectionStatus = .error(error)
                        self.operationErrorSubject.send(error)
                    }
                    else {
                        NotificationCenter.default.post(
                            name: KonashiPeripheral.didDisconnect,
                            object: nil,
                            userInfo: [KonashiPeripheral.instanceKey: self]
                        )
                        self.currentConnectionStatus = .disconnected
                        resolve(())
                    }
                }
            }.store(in: &cancellable)
            CentralManager.shared.disconnect(self.peripheral)
        }.always { [weak self] in
            if let self {
                self.readRssiTimer?.invalidate()
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
                guard let self else {
                    return
                }
                self.readRSSI()
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
            guard let self else {
                return
            }
            if let characteristic = self.peripheral.services?.find(characteristic: characteristic) {
                if type == .withResponse {
                    self.didWriteValueSubject.sink { uuid, error in
                        if uuid == characteristic.uuid {
                            if let error {
                                promise.reject(error)
                                self.operationErrorSubject.send(error)
                            }
                            else {
                                promise.fulfill(self)
                            }
                        }
                    }.store(in: &cancellable)
                }
                self.peripheral.writeValue(command.compose(), for: characteristic, type: type)
                if type == .withoutResponse {
                    promise.fulfill(self)
                }
            }
            else {
                promise.reject(PeripheralOperationError.couldNotFindCharacteristic)
                self.operationErrorSubject.send(PeripheralOperationError.couldNotFindCharacteristic)
            }
        }.catch { [weak self] error in
            promise.reject(error)
            guard let self else {
                return
            }
            self.operationErrorSubject.send(error)
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
            guard let self else {
                return
            }
            if let targetCharacteristic = self.peripheral.services?.find(characteristic: characteristic) {
                self.didUpdateValueSubject.sink { updatedCharacteristic, error in
                    if updatedCharacteristic != targetCharacteristic {
                        return
                    }
                    if let error {
                        promise.reject(error)
                        self.operationErrorSubject.send(error)
                        return
                    }
                    guard let value = updatedCharacteristic.value else {
                        promise.reject(PeripheralOperationError.invalidReadValue)
                        self.operationErrorSubject.send(PeripheralOperationError.invalidReadValue)
                        return
                    }
                    switch characteristic.parse(data: value) {
                    case let .success(value):
                        promise.fulfill(value)
                    case let .failure(error):
                        promise.reject(error)
                        self.operationErrorSubject.send(error)
                    }
                }.store(in: &cancellable)
                self.peripheral.readValue(for: targetCharacteristic)
            }
            else {
                promise.reject(PeripheralOperationError.couldNotFindCharacteristic)
                self.operationErrorSubject.send(PeripheralOperationError.couldNotFindCharacteristic)
            }
        }.catch { [weak self] error in
            promise.reject(error)
            guard let self else {
                return
            }
            self.operationErrorSubject.send(error)
        }
        promise.always {
            cancellable.removeAll()
        }
        return promise
    }

    // MARK: - Mesh

    @discardableResult
    public func provision(for manager: MeshManager) async throws -> NodeCompatible {
        if manager.connection == nil {
            throw MeshManager.NetworkError.noNetworkConnection
        }
        guard let unprovisionedDevice = UnprovisionedDevice(advertisementData: advertisementData) else {
            throw MeshManager.ConfigurationError.invalidUnprovisionedDevice
        }
        guard let networkKey = manager.networkKey else {
            throw MeshManager.ConfigurationError.invalidNetworkKey
        }

        if currentConnectionStatus == .disconnected {
            try await connect()
        }

        // Enable mesh feature
        try await asyncWrite(
            characteristic: SettingsService.settingsCommand,
            command: .bluetooth(
                payload: SettingsService.BluetoothSettingPayload(
                    bluetoothFunction: .init(
                        function: .mesh,
                        enabled: true
                    )
                )
            )
        )
        try await asyncWrite(
            characteristic: SettingsService.settingsCommand,
            command: .system(
                payload: .nvmUseSet(enabled: true)
            )
        )
        try await disconnect()

        // Workaround: Wait 1 sec to prepare for connection again
        try await Task.sleep(nanoseconds: 1000 * 1000000)

        let bearer = MeshBearer(for: PBGattBearer(target: peripheral))
        bearer.originalBearer.logger = manager.logger
        do {
            let provisioningManager = try manager.provision(
                unprovisionedDevice: unprovisionedDevice,
                over: bearer.originalBearer
            )
            provisioningManager.logger = manager.logger
            provisioningManager.networkKey = networkKey
            let provisioner = MeshProvisioner(
                for: provisioningManager,
                context: MeshProvisioner.Context(
                    algorithm: .fipsP256EllipticCurve,
                    publicKey: .noOobPublicKey,
                    authenticationMethod: .noOob
                ),
                bearer: bearer
            )
            let cancellable = provisioner.state.sink { [weak self] newState in
                guard let self else {
                    return
                }
                self.currentProvisioningState = newState
            }
            try await MeshProvisionQueue.waitForProvision(provisioner)
            try manager.save()
            try await bearer.close()
            guard let node = MeshNode(manager: manager, uuid: unprovisionedDevice.uuid) else {
                throw NodeOperationError.invalidNode
            }
            meshNode = node
            // Set name
            try node.updateName(name)
            cancellable.cancel()
            return node
        }
        catch {
            try await bearer.close()
            throw error
        }
    }

    // MARK: Internal

    @Published internal var isCharacteristicsDiscovered = false
    @Published internal var isCharacteristicsConfigured = false
    internal let didUpdateValueSubject = PassthroughSubject<(characteristic: CBCharacteristic, error: Error?), Never>()
    internal var readyPromise = Promise<Void>.pending()
    internal var discoveredServices = [CBService]()
    internal var configuredCharacteristics = [CBCharacteristic]()

    internal func discoverCharacteristics() {
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

    internal func store(characteristic: CBCharacteristic) {
        services.find(characteristic: characteristic)?.update(data: characteristic.value)
    }

    // MARK: Fileprivate

    @Published fileprivate var isConnected = false
    @Published fileprivate var isConnecting = false

    // MARK: Private

    // swiftlint:disable:next weak_delegate
    private lazy var delegate: KonashiPeripheralDelegate = .init(peripheral: self)

    private let advertisementData: [String: Any]

    private var readRssiTimer: Timer?
    private let peripheral: CBPeripheral
    private var observation: NSKeyValueObservation?
    private var internalCancellable = Set<AnyCancellable>()

    private var kvoCancellable: AnyCancellable?

    private func discoverServices() {
        print(">>> discoverServices")
        peripheral.delegate = delegate
        peripheral.discoverServices(services.map(\.serviceUUID))
    }

    private func configureCharacteristics() {
        for service in services {
            service.applyAttributes(peripheral: peripheral)
        }
    }

    private func prepareCombine() {
        internalCancellable.removeAll()
        CentralManager.shared.didDisconnectSubject.sink { [weak self] peripheral, _ in
            guard let self else {
                return
            }
            if peripheral == self.peripheral {
                self.readRssiTimer?.invalidate()
                self.internalCancellable.removeAll()
            }
        }.store(in: &internalCancellable)
        $isConnecting.removeDuplicates().sink { [weak self] connecting in
            guard let self else {
                return
            }
            if connecting {
                self.currentConnectionStatus = .connecting
            }
        }.store(in: &internalCancellable)
        $isConnected.removeDuplicates().sink { [weak self] connected in
            guard let self else {
                return
            }
            if connected {
                self.currentConnectionStatus = .connected
                self.discoverServices()
            }
        }.store(in: &internalCancellable)
        $isCharacteristicsDiscovered.removeDuplicates().sink { [weak self] discovered in
            guard let self else {
                return
            }
            if discovered {
                self.configureCharacteristics()
            }
        }.store(in: &internalCancellable)
        isReady.removeDuplicates().sink { [weak self] ready in
            guard let self else {
                return
            }
            if ready {
                self.currentConnectionStatus = .readyToUse
                self.readyPromise.fulfill(())
            }
            else {
                self.readyPromise = Promise<Void>.pending()
            }
        }.store(in: &internalCancellable)
    }

    private func prepareKVO() {
        kvoCancellable?.cancel()
        kvoCancellable = peripheral.publisher(for: \.state).removeDuplicates().sink { [weak self] state in
            guard let self else {
                return
            }
            print("new state \(state.rawValue)")
            switch state {
            case .connected:
                self.isConnected = true
                self.isConnecting = false
            case .connecting:
                self.isConnected = false
                self.isConnecting = true
            case .disconnected:
                self.isConnected = false
                self.isConnecting = false
            case .disconnecting:
                self.isConnected = false
                self.isConnecting = true
            @unknown default:
                break
            }
        }
    }
}
