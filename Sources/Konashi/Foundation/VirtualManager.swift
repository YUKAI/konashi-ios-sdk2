//
//  VirtualManager.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/08/20.
//

import Combine
import CoreBluetooth
import Foundation

class VirtualManager: NSObject, PeripheralConnectivity {
    // MARK: Lifecycle

    required init(delegate: CBCentralManagerDelegate?, queue: DispatchQueue?) {}

    // MARK: Internal

    var isScanning: Bool = false
    var state: CBManagerState = .poweredOn

    func setManager(_ manager: CentralManager) {
        self.manager = manager
    }

    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral] {
        return []
    }

    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheral] {
        return []
    }

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]? = nil) {
        isScanning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let self else {
                return
            }
            manager?.didFoundPeripheral(VirtualPeripheral())
        })
    }

    func stopScan() {
        isScanning = false
        timer?.invalidate()
    }

    func connect(_ peripheral: CBPeripheral, options: [String: Any]? = nil) {}
    func cancelPeripheralConnection(_ peripheral: CBPeripheral) {}
    func registerForConnectionEvents(options: [CBConnectionEventMatchingOption: Any]? = nil) {}

    // MARK: Private

    private weak var manager: CentralManager?
    private var timer: Timer?
}
