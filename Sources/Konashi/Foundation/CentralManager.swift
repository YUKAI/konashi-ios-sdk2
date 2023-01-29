//
//  CentralManager.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Combine
import CoreBluetooth
import nRFMeshProvision
import Promises

// MARK: - CentralManager

// TODO: actorにしたい
/// A utility class of managiment procetudes such as discover, connect and disconnect peripherals.
/// This class is a wrapper of CBCentralManager.
public final class CentralManager: NSObject, Loggable {
    // MARK: Lifecycle

    public static let sharedLogOutput = LogOutput()
    public let logOutput = LogOutput()

    override private init() {
        super.init()
        didConnectSubject.sink { [weak self] _ in
            guard let self else {
                return
            }
            self.numberOfConnectingPeripherals += 1
        }.store(in: &cancellable)
        didFailedToConnectSubject.sink { [weak self] _ in
            guard let self else {
                return
            }
            self.numberOfConnectingPeripherals -= 1
        }.store(in: &cancellable)
    }

    // MARK: Public

    public enum ScanError: Error, LocalizedError {
        /// The Konashi device was not found within the timeout time.
        case peripheralNotFound

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .peripheralNotFound:
                return "Counld not find any peripherals."
            }
        }
    }

    /// A shared instance of CentralManager.
    public static let shared = CentralManager()

    // TODO: Add document
    public var discoversUniquePeripherals = true

    /// A subject that sends any operation errors.
    public let operationErrorSubject = PassthroughSubject<Error, Never>()
    /// A subject that sends discovered peripheral and advertisement datas.
    public let didDiscoverSubject = PassthroughSubject<(peripheral: any Peripheral, advertisementData: [String: Any], rssi: NSNumber), Never>()
    /// A subject that sends a peripheral that is connected.
    public let didConnectSubject = PassthroughSubject<CBPeripheral, Never>()
    /// A subject that sends a peripheral when a peripheral is disconnected.
    public let didDisconnectSubject = PassthroughSubject<(CBPeripheral, Error?), Never>()
    /// A subject that sends a peripheral when failed to connect.
    public let didFailedToConnectSubject = PassthroughSubject<(CBPeripheral, Error?), Never>()

    /// This value indicates that a centeral manager is scanning peripherals.
    @Published public private(set) var isScanning = false
    /// This value indicates that a centeral manager is connecting a peripheral.
    @Published public private(set) var isConnecting = false

    /// Represents the current state of a CBManager.
    public var state: CBManagerState {
        return manager.state
    }

    /// Attempt to scan available peripherals.
    /// - Returns: A promise object for this method.
    public func scan() -> Promise<Void> {
        log(.trace("Start scan"))

        if manager.state == .poweredOn {
            statePromise.fulfill(())
        }
        return Promise<Void> { [weak self] resolve, _ in
            guard let self else {
                return
            }
            self.statePromise.then { [weak self] _ in
                guard let self else {
                    return
                }
                self.isScanning = true
                self.manager.scanForPeripherals(
                    withServices: [
                        SettingsService.serviceUUID,
                        MeshProvisioningService.uuid
                    ],
                    options: [
                        CBCentralManagerScanOptionAllowDuplicatesKey: !self.discoversUniquePeripherals
                    ]
                )
                resolve(())
            }
        }
    }

    public enum ScanTarget {
        case all
        case meshNode
    }

    /// Attempt to find a peripheral.
    /// - Parameters:
    ///   - name: Peripheral name to find.
    ///   - timeoutInterval: The duration of timeout.
    ///   - target: Filter mesh node or not
    /// - Returns: A promise object for this method.
    public func find(name: String, timeoutInterval: TimeInterval = 5, target: ScanTarget = .all) -> Promise<any Peripheral> {
        log(.trace("Start find \(name), timeout: \(timeoutInterval)"))
        var cancellable = Set<AnyCancellable>()
        return Promise<any Peripheral> { [weak self] resolve, reject in
            guard let self else {
                return
            }
            var didFound = false
            self.scan().delay(timeoutInterval).then { [weak self] _ in
                guard let self else {
                    return
                }
                if didFound == false {
                    self.log(.error("Failed to find \(name)"))
                    reject(ScanError.peripheralNotFound)
                }
            }.catch { [weak self] error in
                guard let self else {
                    return
                }
                self.log(.error("Failed to find \(name)"))
            }
            self.didDiscoverSubject.filter { peripheral, _, _ in
                if target == .meshNode {
                    return peripheral.isProvisionable
                }
                return true
            }.sink { peripheral, _, _ in
                if peripheral.name == name {
                    didFound = true
                    self.log(.debug("Peripheral found \(name)"))
                    resolve(peripheral)
                }
            }.store(in: &cancellable)
        }.always {
            cancellable.removeAll()
        }
    }

    /// Stop scanning peripherals.
    /// - Returns: A promise object for this method.
    @discardableResult
    public func stopScan() -> Promise<Void> {
        log(.trace("Stop scan"))
        let promise = Promise<Void>.pending()
        isScanning = false
        manager.stopScan()
        promise.fulfill(())
        return promise
    }

    // MARK: Internal

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

    private var statePromise = Promise<Void>.pending()
    private var cancellable = Set<AnyCancellable>()
    private lazy var manager = CBCentralManager(delegate: self, queue: nil)
}

// MARK: CBCentralManagerDelegate

extension CentralManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        log(.trace("Did update central manager state: \(central.state.konashi_description)"))

        if central.state == .poweredOn {
            statePromise.fulfill(())
        }
        else {
            statePromise = Promise<Void>.pending()
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
//        log(.trace("Did discover peripheral: \(peripheral.konashi_debugName), mesh: \(UnprovisionedDevice(advertisementData: advertisementData) != nil ? true : false), rssi: \(RSSI), advertising data: \(advertisementData)"))

        didDiscoverSubject.send(
            (
                peripheral: KonashiPeripheral(
                    peripheral: peripheral,
                    advertisementData: advertisementData
                ),
                advertisementData: advertisementData,
                rssi: RSSI
            )
        )
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log(.trace("Did connect: \(peripheral.konashi_debugName)"))
        didConnectSubject.send(peripheral)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log(.trace("Did disconnect: \(peripheral.konashi_debugName), error: \(error?.localizedDescription ?? "nil")"))
        if let error {
            operationErrorSubject.send(error)
        }
        didDisconnectSubject.send(
            (peripheral, error)
        )
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log(.trace("Did fail to connect: \(peripheral.konashi_debugName), error: \(error?.localizedDescription ?? "nil")"))
        if let error {
            operationErrorSubject.send(error)
        }
        didFailedToConnectSubject.send(
            (peripheral, error)
        )
    }
}
