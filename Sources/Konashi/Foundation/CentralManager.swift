//
//  CentralManager.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Combine
import CoreBluetooth
import nRFMeshProvision

// MARK: - CentralManager

// TODO: actorにしたい
/// A utility class of managiment procetudes such as discover, connect and disconnect peripherals.
/// This class is a wrapper of CBCentralManager.
public final class CentralManager: NSObject, Loggable {
    // MARK: Lifecycle

    override private init() {
        super.init()
        didConnectSubject.sink { [weak self] _ in
            guard let self else {
                return
            }
            numberOfConnectingPeripherals += 1
        }.store(in: &cancellable)
        didFailedToConnectSubject.sink { [weak self] _ in
            guard let self else {
                return
            }
            numberOfConnectingPeripherals -= 1
        }.store(in: &cancellable)
    }

    // MARK: Public

    public enum OperationError: LocalizedError {
        case invalidManagerState

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .invalidManagerState:
                return "CBCentralManager is not power on."
            }
        }
    }

    public enum ScanTarget {
        case all
        case meshNode
    }

    public static let sharedLogOutput = LogOutput()
    /// A shared instance of CentralManager.
    public static let shared = CentralManager()

    public let logOutput = LogOutput()

    // TODO: Add document
    public var discoversUniquePeripherals = true

    /// A publisher that sends any operation errors.
    public private(set) lazy var operationErrorPublisher = operationErrorSubject.eraseToAnyPublisher()

    /// A publisher that sends discovered peripheral and advertisement datas.
    public private(set) lazy var didDiscoverPublisher = didDiscoverSubject.eraseToAnyPublisher()

    /// A publisher that sends a peripheral that is connected.
    public private(set) lazy var didConnectPublisher = didConnectSubject.eraseToAnyPublisher()

    /// A publisher that sends a peripheral when a peripheral is disconnected.
    public private(set) lazy var didDisconnectPublisher = didDisconnectSubject.eraseToAnyPublisher()

    /// A publisher that sends a peripheral when failed to connect.
    public private(set) lazy var didFailedToConnectPublisher = didFailedToConnectSubject.eraseToAnyPublisher()

    /// This value indicates that a centeral manager is scanning peripherals.
    @Published public private(set) var isScanning = false
    /// This value indicates that a centeral manager is connecting a peripheral.
    @Published public private(set) var isConnecting = false

    /// Represents the current state of a CBManager.
    public var state: CBManagerState {
        return manager.state
    }

    // TODO: Make async function
    /// Attempt to scan available peripherals.
    public func scan(timeoutInterval: TimeInterval = 5) async throws {
        log(.trace("Start scan"))

        if manager.state != .poweredOn {
            // Wait until the state of manager becomes power on
            do {
                _ = try await manager.publisher(for: \.state)
                    .timeout(.seconds(timeoutInterval), scheduler: DispatchQueue.global())
                    .filter { $0 == .poweredOn }
                    .eraseToAnyPublisher()
                    .konashi_makeAsync()
            }
            catch {
                operationErrorSubject.send(OperationError.invalidManagerState)
                throw OperationError.invalidManagerState
            }
        }
        isScanning = true
        manager.scanForPeripherals(
            withServices: [
                SettingsService.serviceUUID,
                MeshProvisioningService.uuid
            ],
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: !discoversUniquePeripherals
            ]
        )
        try await Task.sleep(nanoseconds: UInt64(timeoutInterval * 1000000000))
    }

    /// Attempt to find a peripheral.
    /// - Parameters:
    ///   - name: Peripheral name to find.
    ///   - timeoutInterval: The duration of timeout.
    ///   - target: Filter mesh node or not
    /// - Returns: Found peripheral
    public func find(name: String, timeoutInterval: TimeInterval = 5, target: ScanTarget = .all) async throws -> (any Peripheral)? {
        log(.trace("Start find \(name), timeout: \(timeoutInterval)"))
        if let foundPeripheral = foundPeripherals.first(where: { $0.name == name }) {
            log(.debug("Peripheral is already found \(name)"))
            return foundPeripheral
        }
        try await scan()
        try await Task.sleep(nanoseconds: UInt64(timeoutInterval * 1000000000))
        guard let foundPeripheral = foundPeripherals.filter({
            if target == .meshNode {
                return $0.isProvisionable
            }
            return true
        }).first(where: { $0.name == name }) else {
            log(.debug("Counld not find the peripheral \(name)"))
            return nil
        }
        log(.debug("Peripheral found \(name)"))
        return foundPeripheral
    }

    /// Stop scanning peripherals.
    public func stopScan() {
        log(.trace("Stop scan"))
        isScanning = false
        manager.stopScan()
    }

    @discardableResult
    public func removeFoundPeripheal(for identifier: UUID) -> Bool {
        if foundPeripherals.contains(where: {
            $0.identifier == identifier
        }) {
            foundPeripherals.removeAll {
                $0.identifier == identifier
            }
            return true
        }
        return false
    }

    public func clearFoundPeripherals() {
        log(.trace("Clear found peripherals"))
        foundPeripherals.removeAll { $0.state != .connected }
    }

    // MARK: Internal

    let operationErrorSubject = PassthroughSubject<Error, Never>()
    let didDiscoverSubject = PassthroughSubject<any Peripheral, Never>()
    let didConnectSubject = PassthroughSubject<CBPeripheral, Never>()
    let didDisconnectSubject = PassthroughSubject<(CBPeripheral, Error?), Never>()
    let didFailedToConnectSubject = PassthroughSubject<(CBPeripheral, Error?), Never>()

    /// Connect to peripheral.
    /// - Parameter peripheral: A peripheral to connect.
    func connect(_ peripheral: CBPeripheral) {
        log(.trace("Connect to \(peripheral.konashi_debugName): \(peripheral.identifier)"))
        numberOfConnectingPeripherals += 1
        manager.connect(peripheral, options: nil)
    }

    /// Disconnect peripheral.
    /// - Parameter peripheral: A peripheral to disconnect.
    func disconnect(_ peripheral: CBPeripheral) {
        log(.trace("Disconnect to \(peripheral.konashi_debugName): \(peripheral.identifier)"))

        manager.cancelPeripheralConnection(peripheral)
    }

    func clearFoundPeripheralsIfNeeded() {
        log(.trace("Clear outdated peripherals"))
        foundPeripherals.removeAll(where: \.isOutdated)
    }

    // MARK: Fileprivate

    fileprivate var numberOfConnectingPeripherals = 0 {
        didSet {
            if numberOfConnectingPeripherals == 0 {
                isConnecting = false
            }
            else {
                isConnecting = true
            }
        }
    }

    // MARK: Private

    private var foundPeripherals = [any Peripheral]()

    private var cancellable = Set<AnyCancellable>()
    private lazy var manager = CBCentralManager(delegate: self, queue: nil)
}

// MARK: CBCentralManagerDelegate

extension CentralManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        log(.trace("Did update central manager state: \(central.state.konashi_description)"))
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let result: any Peripheral = {
            guard let existingPeripheral = foundPeripherals.first(where: { $0.identifier == peripheral.identifier }) else {
                log(.trace("Did discover peripheral: \(peripheral.konashi_debugName), mesh: \(UnprovisionedDevice(advertisementData: advertisementData) != nil ? true : false), rssi: \(RSSI), advertising data: \(advertisementData)"))
                return KonashiPeripheral(
                    peripheral: peripheral,
                    advertisementData: advertisementData,
                    rssi: RSSI
                )
            }

            existingPeripheral.setRSSI(RSSI)
            existingPeripheral.setAdvertisementData(advertisementData)
            return existingPeripheral
        }()
        foundPeripherals.append(result)
        didDiscoverSubject.send(result)
        // TODO: clear found peripherals
        // clearFoundPeripheralsIfNeeded()
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log(.trace("Did connect: \(peripheral.konashi_debugName)"))
        didConnectSubject.send(peripheral)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error {
            if let existingPeripheral = foundPeripherals.first(where: { $0.identifier == peripheral.identifier }) {
                existingPeripheral.recordError(error)
            }
            operationErrorSubject.send(error)
            log(.error("Failed to disconnect: \(peripheral.konashi_debugName), error: \(error.localizedDescription)"))
        }
        else {
            log(.trace("Did disconnect: \(peripheral.konashi_debugName)"))
        }
        didDisconnectSubject.send(
            (peripheral, error)
        )
        foundPeripherals.removeAll { $0.identifier == peripheral.identifier }
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log(.trace("Did fail to connect: \(peripheral.konashi_debugName), error: \(error?.localizedDescription ?? "nil")"))
        if let error {
            if let existingPeripheral = foundPeripherals.first(where: { $0.identifier == peripheral.identifier }) {
                existingPeripheral.recordError(error)
            }
            operationErrorSubject.send(error)
        }
        didFailedToConnectSubject.send(
            (peripheral, error)
        )
    }
}
