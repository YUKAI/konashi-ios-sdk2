//
//  CentralManager.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Combine
import CoreBluetooth
import Promises

public final class CentralManager: NSObject {
    public static let shared = CentralManager()

    public var state: CBManagerState {
        return manager.state
    }

    public let operationErrorSubject = PassthroughSubject<Error, Never>()
    public let didDiscoverSubject = PassthroughSubject<(peripheral: Peripheral, advertisementData: [String: Any], rssi: NSNumber), Never>()
    public let didConnectSubject = PassthroughSubject<CBPeripheral, Never>()
    public let didDisconnectSubject = PassthroughSubject<(CBPeripheral, Error?), Never>()
    public let didFailedToConnectSubject = PassthroughSubject<(CBPeripheral, Error?), Never>()

    @Published public private(set) var isScanning = false
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

    @discardableResult
    public func stopScan() -> Promise<Void> {
        let promise = Promise<Void>.pending()
        isScanning = false
        manager.stopScan()
        promise.fulfill(())
        return promise
    }

    func connect(_ peripheral: CBPeripheral) {
        numberOfConnectingPeripherals += 1
        manager.connect(peripheral, options: nil)
    }

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
