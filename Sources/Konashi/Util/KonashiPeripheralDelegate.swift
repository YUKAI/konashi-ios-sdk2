//
//  KonashiPeripheralDelegate.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/10.
//

import CoreBluetooth
import Foundation

// MARK: - KonashiPeripheralDelegate

final class KonashiPeripheralDelegate: NSObject, Loggable {
    // MARK: Lifecycle

    init(peripheral: KonashiPeripheral) {
        parentPeripheral = peripheral
    }

    // MARK: Internal

    static let sharedLogOutput = LogOutput()

    let logOutput = LogOutput()

    weak var parentPeripheral: KonashiPeripheral!
}

// MARK: CBPeripheralDelegate

extension KonashiPeripheralDelegate: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            log(.error("Failed to discover services: \(peripheral.konashi_debugName), error: \(error.localizedDescription)"))
            parentPeripheral.operationErrorSubject.send(error)
            return
        }
        log(.trace("Did discover services: \(peripheral.konashi_debugName)"))
        parentPeripheral.didDiscoverService()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            log(.error("Failed to discover characteristic: \(peripheral.konashi_debugName), service: \(service.uuid), error: \(error.localizedDescription)"))
            parentPeripheral.operationErrorSubject.send(error)
            return
        }
        log(.trace("Did discover characteristics: \(peripheral.konashi_debugName), service: \(service.uuid)"))
        parentPeripheral.didDiscoverCharacteristics(for: service)
    }

    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error {
            log(.error("Failed to read RSSI: \(peripheral.konashi_debugName), error: \(error.localizedDescription)"))
            parentPeripheral.operationErrorSubject.send(error)
            return
        }
        log(.trace("Did read RSSI: \(peripheral.konashi_debugName), RSSI: \(RSSI)"))
        parentPeripheral.currentRSSI = RSSI
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            log(.error("Failed to write value for characteristic: \(peripheral.konashi_debugName), characteristic: \(characteristic.uuid), error: \(error.localizedDescription)"))
            parentPeripheral.operationErrorSubject.send(error)
        }
        log(.trace("Did write value: \(peripheral.konashi_debugName)"))
        parentPeripheral.didWriteValueSubject.send((characteristic.uuid, error))
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        parentPeripheral.didUpdateValueSubject.send((characteristic, error))
        if let error {
            log(.error("Failed to update value for characteristic: \(peripheral.konashi_debugName), characteristic: \(characteristic.uuid), error: \(error.localizedDescription)"))
            parentPeripheral.operationErrorSubject.send(error)
            return
        }
        log(.trace("Did update value for characteristic: \(peripheral.konashi_debugName), characteristic: \(characteristic.uuid)"))
        parentPeripheral.store(characteristic: characteristic)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            log(.error("Failed to update notification state: \(peripheral.konashi_debugName), characteristic: \(characteristic.uuid), error: \(error.localizedDescription)"))
            parentPeripheral.operationErrorSubject.send(error)
            return
        }
        log(.trace("Did update notification state: \(peripheral.konashi_debugName), characteristic: \(characteristic.uuid)"))
        parentPeripheral.configuredCharacteristics.append(characteristic)
        let numberOfConfigureableCharacteristics = parentPeripheral.services.flatMap(\.notifiableCharacteristics).count
        if parentPeripheral.configuredCharacteristics.count == numberOfConfigureableCharacteristics {
            log(.debug("Characteristics configured: \(peripheral.konashi_debugName)"))
            parentPeripheral.characteristicsState = .configured
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        log(.trace("Did modify services: \(peripheral.konashi_debugName), invalidated services: \(invalidatedServices)"))
    }
}
