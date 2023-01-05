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

/// A utility class of managiment procetudes such as discover, connect and disconnect peripherals.
/// This class is a wrapper of CBCentralManager.
public final class CentralManager: NSObject {
    public enum ScanError: Error, LocalizedError {
        /// The Konashi device was not found within the timeout time.
        case peripheralNotFound
        
        public var errorDescription: String? {
            switch self {
            case .peripheralNotFound:
                return "Counld not find any peripherals."
            }
        }
    }

    public enum ScanTarget {
        case all
        case meshNode
    }

    /// A shared instance of CentralManager.
    public static let shared = CentralManager()

    /// Represents the current state of a CBManager.
    public var state: CBManagerState {
        return manager.state
    }

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

    private var statePromise = Promise<Void>.pending()
    private var cancellable = Set<AnyCancellable>()
    private lazy var manager: CBCentralManager = .init(delegate: self, queue: nil)

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

    override public init() {
        super.init()
        didConnectSubject.sink { [weak self] _ in
            guard let weakSelf = self else {
                return
            }
            weakSelf.numberOfConnectingPeripherals -= 1
        }.store(in: &cancellable)
        didFailedToConnectSubject.sink { [weak self] _ in
            guard let weakSelf = self else {
                return
            }
            weakSelf.numberOfConnectingPeripherals -= 1
        }.store(in: &cancellable)
        didFailedToConnectSubject.sink { [weak self] _ in
            guard let weakSelf = self else {
                return
            }
            weakSelf.numberOfConnectingPeripherals -= 1
        }.store(in: &cancellable)
    }

    /// Attempt to scan available peripherals.
    /// - Returns: A promise object for this method.
    public func scan(for target: ScanTarget = .all) -> Promise<Void> {
        if manager.state == .poweredOn {
            statePromise.fulfill(())
        }
        return Promise<Void> { [weak self] resolve, _ in
            guard let weakSelf = self else {
                return
            }
            weakSelf.statePromise.then { [weak self] _ in
                guard let weakSelf = self else {
                    return
                }
                var services: [CBUUID] {
                    if target == .meshNode {
                        return [
                            MeshProvisioningService.uuid
                        ]
                    }
                    return [
                        SettingsService.serviceUUID
                    ]
                }
                weakSelf.isScanning = true
                weakSelf.manager.scanForPeripherals(
                    withServices: services,
                    options: [
                        CBCentralManagerScanOptionAllowDuplicatesKey: false
                    ]
                )
                resolve(())
            }
        }
    }

    /// Attempt to find a peripheral.
    /// - Parameters:
    ///   - name: Peripheral name to find.
    ///   - timeoutInterval: The duration of timeout.
    /// - Returns: A promise object for this method.
    public func find(name: String, timeoutInterval: TimeInterval = 5) -> Promise<any Peripheral> {
        var cancellable = Set<AnyCancellable>()
        return Promise<any Peripheral> { [weak self] resolve, reject in
            guard let weakSelf = self else {
                return
            }
            var didFound = false
            weakSelf.scan().delay(timeoutInterval).then { [weak self] _ in
                guard let weakSelf = self else {
                    return
                }
                if didFound == false {
                    reject(ScanError.peripheralNotFound)
                }
                weakSelf.stopScan()
            }
            weakSelf.didDiscoverSubject.sink { peripheral, _, _ in
                if peripheral.name == name {
                    didFound = true
                    resolve(peripheral)
                    weakSelf.stopScan()
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
        let promise = Promise<Void>.pending()
        isScanning = false
        manager.stopScan()
        promise.fulfill(())
        return promise
    }

    /// Connect to peripheral.
    /// - Parameter peripheral: A peripheral to connect.
    func connect(_ peripheral: CBPeripheral) {
        numberOfConnectingPeripherals += 1
        manager.connect(peripheral, options: nil)
    }

    /// Disconnect peripheral.
    /// - Parameter peripheral: A peripheral to disconnect.
    func disconnect(_ peripheral: CBPeripheral) {
        manager.cancelPeripheralConnection(peripheral)
    }
}

extension CentralManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
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
        didConnectSubject.send(peripheral)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error {
            operationErrorSubject.send(error)
        }
        didDisconnectSubject.send(
            (peripheral, error)
        )
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error {
            operationErrorSubject.send(error)
        }
        didFailedToConnectSubject.send(
            (peripheral, error)
        )
    }
}
