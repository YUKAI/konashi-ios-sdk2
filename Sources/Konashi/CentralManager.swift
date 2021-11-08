//
//  CentralManager.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Combine
import CoreBluetooth
import Promises

/// A utility class of managiment procetudes such as discover, connect and disconnect peripherals.
/// This class is a wrapper of CBCentralManager. All procedure should proceed through this class.
public final class CentralManager: NSObject {
    /// A shared instance of CentralManager.
    public static let shared = CentralManager()

    /// Represents the current state of a CBManager.
    public var state: CBManagerState {
        return manager.state
    }

    /// A subject that sends any operation errors.
    public let operationErrorSubject = PassthroughSubject<Error, Never>()
    /// A subject that sends discovered peripheral and advertisement datas.
    public let didDiscoverSubject = PassthroughSubject<(peripheral: Peripheral, advertisementData: [String: Any], rssi: NSNumber), Never>()
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
    private lazy var manager: CBCentralManager = {
        return CBCentralManager(delegate: self, queue: nil)
    }()
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
    public func scan() -> Promise<Void> {
        if manager.state == .poweredOn {
            statePromise.fulfill(())
        }
        let promise = Promise<Void>.pending()
        statePromise.then { [weak self] _ in
            guard let weakSelf = self else {
                return
            }
            weakSelf.isScanning = true
            weakSelf.manager.scanForPeripherals(
                withServices: [
                    SettingsService.serviceUUID
                ],
                options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey: false
                ]
            )
            promise.fulfill(())
        }

        return promise
    }

    /// Attempt to find a peripheral.
    /// - Parameters:
    ///    - name: Peripheral name to find.
    ///    - timeoutInterval: The duration of timeout.
    /// - Returns: A promise object for this method.
    public func find(name: String, timeoutInterval: TimeInterval = 5) -> Promise<Peripheral> {
        var cancellable = Set<AnyCancellable>()
        return Promise<Peripheral> { [weak self] resolve, _ in
            guard let weakSelf = self else {
                return
            }
            weakSelf.scan().delay(timeoutInterval).then { [weak self] _ in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.stopScan()
            }
            weakSelf.didDiscoverSubject.sink { peripheral, _, _ in
                if peripheral.name == name {
                    resolve(peripheral)
                    weakSelf.stopScan()
                }
            }.store(in: &cancellable)
        }.always {
            cancellable.removeAll()
        }
    }

    /// Stop finding a peripheral.
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
    /// - Parameters:
    ///    - peripheral: A peripheral to connect.
    func connect(_ peripheral: CBPeripheral) {
        numberOfConnectingPeripherals += 1
        manager.connect(peripheral, options: nil)
    }

    /// Disconnect peripheral.
    /// - Parameters:
    ///    - peripheral: A peripheral to disconnect.
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
                peripheral: Peripheral(peripheral: peripheral),
                advertisementData: advertisementData,
                rssi: RSSI
            )
        )
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        didConnectSubject.send(peripheral)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            operationErrorSubject.send(error)
        }
        didDisconnectSubject.send(
            (peripheral, error)
        )
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            operationErrorSubject.send(error)
        }
        didFailedToConnectSubject.send(
            (peripheral, error)
        )
    }
}
