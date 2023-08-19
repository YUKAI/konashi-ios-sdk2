//
//  KonashiPeripheral.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Combine
import CombineExt
import CoreBluetooth
import Foundation
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

    public init(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        currentRSSI = rssi
        lastUpdatedDate = Date()
        self.peripheral.delegate = delegate
        prepareCombine()
        prepareKVO()
    }

    deinit {
        readRssiTimer?.invalidate()
        log(.debug("Deinit \(debugName)"))
    }

    // MARK: Public

    public static let sharedLogOutput = LogOutput()

    public let logOutput = LogOutput()

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

    /// A publisher that indicates date of the peripheral updated advertisement data or RSSI.
    @Published public private(set) var lastUpdatedDate: Date

    /// This variable indicates that whether a peripheral is ready to use or not.
    public private(set) lazy var isReady: AnyPublisher<Bool, Never> = Publishers.CombineLatest(
        $currentConnectionState,
        $characteristicsState
    ).map { connectionState, characteristicsState in
        return connectionState == .connected && characteristicsState == .configured
    }.eraseToAnyPublisher()

    public func recordError(_ error: Error) {
        operationErrorSubject.send(error)
    }

    let operationErrorSubject = PassthroughSubject<Error, Never>()
    /// A publisher that sends any operation errors.
    public private(set) lazy var operationErrorPublisher = operationErrorSubject.eraseToAnyPublisher()

    let didWriteValueSubject = PassthroughSubject<(uuid: CBUUID, error: Error?), Never>()
    /// A publisher that sends value that is written to af peripheral.
    public private(set) lazy var didWriteValuePublisher = didWriteValueSubject.eraseToAnyPublisher()

    public var state: ConnectionState {
        return currentConnectionState
    }

    public var provisioningState: ProvisioningState? {
        return currentProvisioningState
    }

    public var rssiPublisher: Published<NSNumber>.Publisher {
        return $currentRSSI
    }

    public var isOutdated: Bool {
        return lastUpdatedDate.timeIntervalSinceNow < -60 // 1 min
    }

    /// A publisher of peripheral state.
    @Published public private(set) var currentConnectionState: ConnectionState = .disconnected {
        didSet {
            log(.debug("Update connection status: \(debugName), status: \(currentConnectionState)"))
        }
    }

    /// A publisher of RSSI value.
    @Published public internal(set) var currentRSSI: NSNumber {
        didSet {
            lastUpdatedDate = Date()
        }
    }

    /// A publisher that data of the peripheral advertised.
    @Published public internal(set) var advertisementData: [String: Any] {
        didSet {
            lastUpdatedDate = Date()
        }
    }

    // TODO: Add document
    public var meshNode: NodeCompatible? {
        didSet {
            guard let meshNode else {
                return
            }
            log(.debug("Node assigned: \(debugName), node: \(meshNode.uuid)"))
        }
    }

    @Published public private(set) var currentProvisioningState: ProvisioningState? {
        didSet {
            guard let currentProvisioningState else {
                return
            }
            log(.trace("Change provisioning state: \(debugName), state: \(currentProvisioningState)"))
        }
    }

    /// A name of a peripheral.
    public var name: String? {
        return peripheral.name
    }

    public var identifier: UUID {
        return peripheral.identifier
    }

    /// A connection status of a peripheral.
    public var statePublisher: Published<ConnectionState>.Publisher {
        return $currentConnectionState
    }

    public var provisioningStatePublisher: Published<ProvisioningState?>.Publisher {
        return $currentProvisioningState
    }

    public var isProvisionable: Bool {
        return unprovisionedDevice != nil
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
        log(.trace("Connecting: \(debugName)"))
        if currentConnectionState.isConnectable == false {
            if currentConnectionState == .connected {
                log(.debug("Peripheral is already connected: \(debugName)"))
                return Promise<any Peripheral>(self)
            }
            if currentConnectionState == .connecting {
                log(.debug("Peripheral is currently connecting: \(debugName)"))
                return Promise<any Peripheral>(self)
            }
        }
        var cancellable = Set<AnyCancellable>()
        characteristicsState = .invalidated
        discoveredServices.removeAll()
        configuredCharacteristics.removeAll()
        return Promise<any Peripheral> { [unowned self] resolve, reject in
            isReady.sink { [weak self] ready in
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
                    self.currentConnectionState = .error(error)
                    self.operationErrorSubject.send(error)
                    reject(error)
                }
            }.store(in: &cancellable)
            CentralManager.shared.connect(peripheral)
        }.always {
            cancellable.removeAll()
        }
    }

    /// Disconnects from a peripheral.
    @discardableResult
    public func disconnect() -> Promise<Void> {
        log(.trace("Disconnecting: \(debugName)"))
        if currentConnectionState == .disconnected {
            log(.debug("Peripheral is already disconnected: \(debugName)"))
            return Promise<Void>(())
        }

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
                        self.currentProvisioningState = nil
                        self.currentConnectionState = .error(error)
                        self.operationErrorSubject.send(error)
                    }
                    else {
                        NotificationCenter.default.post(
                            name: KonashiPeripheral.didDisconnect,
                            object: nil,
                            userInfo: [KonashiPeripheral.instanceKey: self]
                        )
                        self.currentProvisioningState = nil
                        self.currentConnectionState = .disconnected
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
        log(.trace("Read RSSI \(debugName)"))
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
        type writeType: CBCharacteristicWriteType = .withResponse
    ) -> Promise<any Peripheral> {
        log(.trace("Write value: \(debugName), characteristic: \(characteristic), command: \(command) \([UInt8](command.compose()).toHexString())"))
        var cancellable = Set<AnyCancellable>()
        let promise = Promise<any Peripheral>.pending()
        readyPromise.then { [weak self] _ in
            guard let self else {
                return
            }
            if let characteristic = self.peripheral.services?.find(characteristic: characteristic) {
                if writeType == .withResponse {
                    self.didWriteValueSubject.sink { [weak self] uuid, error in
                        guard let self else {
                            return
                        }
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
                self.peripheral.writeValue(command.compose(), for: characteristic, type: writeType)
                if writeType == .withoutResponse {
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
            self.log(.error(error.localizedDescription))
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
        log(.trace("Read value: \(debugName), characteristic: \(characteristic)"))
        var cancellable = Set<AnyCancellable>()
        let promise = Promise<Value>.pending()
        readyPromise.then { [weak self] _ in
            guard let self else {
                return
            }
            if let targetCharacteristic = self.peripheral.services?.find(characteristic: characteristic) {
                self.didUpdateValueSubject.sink { [weak self] updatedCharacteristic, error in
                    guard let self else {
                        return
                    }
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
            self.log(.error(error.localizedDescription))
            self.operationErrorSubject.send(error)
        }
        promise.always {
            cancellable.removeAll()
        }
        return promise
    }

    // MARK: - Mesh

    public func setMeshEnabled(_ enabled: Bool) async throws {
        log(.trace("Set mesh: \(debugName), \(enabled)"))
        do {
            if currentConnectionState != .connected {
                throw PeripheralOperationError.noConnection
            }
            try await asyncWrite(
                characteristic: SettingsService.settingsCommand,
                command: .system(
                    payload: .nvmUseSet(enabled: enabled)
                )
            )
            try await asyncWrite(
                characteristic: SettingsService.settingsCommand,
                command: .bluetooth(
                    payload: SettingsService.BluetoothSettingPayload(
                        bluetoothFunction: .init(
                            function: .mesh,
                            enabled: enabled
                        )
                    )
                )
            )
        }
        catch {
            log(.error(error.localizedDescription))
            throw error
        }
    }

    @discardableResult
    public func provision(for manager: MeshManager) async throws -> NodeCompatible {
        do {
            log(.trace("Start provision: \(debugName)"))
            if await manager.connection == nil {
                log(.error("No network connection: \(debugName)"))
                throw MeshManager.NetworkError.noNetworkConnection
            }
            guard let unprovisionedDevice else {
                log(.error("Invalid unprovisioned device: \(debugName)"))
                throw MeshManager.ConfigurationError.invalidUnprovisionedDevice
            }
            guard let networkKey = await manager.networkKey else {
                log(.error("Invalid network key: \(debugName)"))
                throw MeshManager.ConfigurationError.invalidNetworkKey
            }
            if currentConnectionState == .disconnected {
                log(.trace("Attempt to connect to \(debugName)"))
                try await connect()
            }
            let bearer = MeshBearer(for: PBGattBearer(target: peripheral))
            bearer.originalBearer.logger = await manager.logger
            do {
                log(.trace("Get provisioning manager: \(debugName)"))
                let provisioningManager = try await manager.provision(
                    unprovisionedDevice: unprovisionedDevice,
                    over: bearer.originalBearer
                )
                provisioningManager.logger = await manager.logger
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
                log(.trace("Wait for provision: \(debugName)"))
                try await MeshProvisionQueue.waitForProvision(provisioner)
                log(.trace("Provisioned: \(debugName)"))
                try await manager.save()
                try await bearer.close()
                guard let node = MeshNode(manager: manager, uuid: unprovisionedDevice.uuid, peripheral: self) else {
                    log(.critical("Can not find a mesh node of \(debugName), uuid: \(unprovisionedDevice.uuid)"))
                    throw NodeOperationError.invalidNode
                }
                meshNode = node
                log(.trace("Update node name: \(debugName)"))
                try await node.updateName(name)
                cancellable.cancel()
                return node
            }
            catch {
                try await bearer.close()
                throw error
            }
        }
        catch {
            log(.error(error.localizedDescription))
            throw error
        }
    }

    public func setRSSI(_ RSSI: NSNumber) {
        currentRSSI = RSSI
    }

    public func setAdvertisementData(_ advertisementData: [String: Any]) {
        if let unprovisionedDevice = UnprovisionedDevice(advertisementData: advertisementData) {
            self.unprovisionedDevice = unprovisionedDevice
        }
        else {
            self.advertisementData = advertisementData
        }
    }

    // MARK: Internal

    enum CharacteristicsConfigurationState {
        case invalidated
        case discovered
        case configured
    }

    internal let didUpdateValueSubject = PassthroughSubject<(characteristic: CBCharacteristic, error: Error?), Never>()
    internal var readyPromise = Promise<Void>.pending()
    internal var discoveredServices = [CBService]()
    internal var configuredCharacteristics = [CBCharacteristic]()

    var debugName: String {
        return "\(name ?? "Unknown"): \(peripheral.identifier)"
    }

    internal var unprovisionedDevice: UnprovisionedDevice? {
        didSet {
            lastUpdatedDate = Date()
        }
    }

    @Published internal var characteristicsState: CharacteristicsConfigurationState = .invalidated {
        didSet {
            log(.trace("Update characteristics state: \(debugName), state: \(characteristicsState)"))
        }
    }

    internal func discoverCharacteristics(for service: CBService) {
        if let foundService = services.find(service: service) {
            log(.trace("Discover characteristics: \(debugName), service: \(service.uuid)"))
            peripheral.discoverCharacteristics(foundService.characteristics.map(\.characteristicUUID), for: service)
        }
    }

    internal func store(characteristic: CBCharacteristic) {
        services.find(characteristic: characteristic)?.update(data: characteristic.value)
    }

    func didDiscoverService() {
        guard let foundServices = peripheral.services else {
            return
        }
        for service in foundServices {
            if service.characteristics == nil {
                discoverCharacteristics(for: service)
            }
            else {
                didDiscoverCharacteristics(for: service)
            }
        }
    }

    func didDiscoverCharacteristics(for service: CBService) {
        discoveredServices.append(service)
        if discoveredServices.count == services.count {
            log(.debug("Characteristics discovered: \(debugName)"))
            characteristicsState = .discovered
        }
    }

    // MARK: Private

    private var logCancellable = Set<AnyCancellable>()
    // swiftlint:disable:next weak_delegate
    private lazy var delegate: KonashiPeripheralDelegate = {
        let delegate = KonashiPeripheralDelegate(peripheral: self)
        delegate.logOutput.sink { [weak self] log in
            guard let self else {
                return
            }
            self.log(log.message)
        }.store(in: &self.logCancellable)
        return delegate
    }()

    private var readRssiTimer: Timer?
    private let peripheral: CBPeripheral
    private var observation: NSKeyValueObservation?
    private var internalCancellable = Set<AnyCancellable>()

    private var kvoCancellable: AnyCancellable?

    private func discoverServices() {
        log(.trace("Discover services: \(debugName)"))
        discoveredServices.append(contentsOf: peripheral.services ?? [])
        if discoveredServices.count < services.count {
            // Discover services
            peripheral.discoverServices(services.map(\.serviceUUID))
        }
        else {
            for service in discoveredServices {
                discoverCharacteristics(for: service)
            }
        }
    }

    private func configureCharacteristics() {
        log(.trace("Configure characteristics: \(debugName)"))
        for service in services {
            service.applyAttributes(peripheral: peripheral)
        }
    }

    private func reset() {
        log(.debug("Reset \(debugName)"))
        currentProvisioningState = nil
        currentConnectionState = .disconnected
        characteristicsState = .invalidated
        discoveredServices.removeAll()
        configuredCharacteristics.removeAll()
        readRssiTimer?.invalidate()
    }

    private func prepareCombine() {
        internalCancellable.removeAll()
        CentralManager.shared.didDisconnectSubject.sink { [weak self] peripheral, _ in
            guard let self else {
                return
            }
            if peripheral == self.peripheral {
                self.reset()
            }
        }.store(in: &internalCancellable)
        $currentConnectionState.removeDuplicates().sink { [weak self] status in
            guard let self else {
                return
            }
            if status == .connected {
                self.discoverServices()
            }
        }.store(in: &internalCancellable)
        $characteristicsState.removeDuplicates().sink { [weak self] state in
            guard let self else {
                return
            }
            if state == .discovered {
                self.configureCharacteristics()
            }
        }.store(in: &internalCancellable)
        isReady.removeDuplicates().sink { [weak self] ready in
            guard let self else {
                return
            }
            if ready {
                self.log(.trace("Ready: \(self.debugName)"))
                self.readyPromise.fulfill(())
            }
            else {
                self.log(.trace("Pending: \(self.debugName)"))
                self.readyPromise = Promise<Void>.pending()
            }
        }.store(in: &internalCancellable)
    }

    private func prepareKVO() {
        kvoCancellable?.cancel()
        kvoCancellable = peripheral.publisher(for: \.state)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else {
                    return
                }
                switch state {
                case .connected:
                    self.currentConnectionState = .connected
                case .connecting:
                    self.currentConnectionState = .connecting
                case .disconnected:
                    self.currentConnectionState = .disconnected
                case .disconnecting:
                    self.currentConnectionState = .disconnecting
                @unknown default:
                    break
                }
            }
    }
}
