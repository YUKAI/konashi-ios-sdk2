//
//  KonashiPeripheralDelegate.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/10.
//

import CoreBluetooth
import Foundation

// MARK: - KonashiPeripheralDelegate

class KonashiPeripheralDelegate: NSObject {
    // MARK: Lifecycle

    init(peripheral: KonashiPeripheral) {
        parentPeripheral = peripheral
    }

    // MARK: Internal

    weak var parentPeripheral: KonashiPeripheral?
}

// MARK: CBPeripheralDelegate

extension KonashiPeripheralDelegate: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print(">>> discoverServices done")
        if let error {
            parentPeripheral!.readyPromise.reject(error)
            parentPeripheral!.operationErrorSubject.send(error)
            return
        }
        parentPeripheral?.didDiscoverService()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print(">>> discoverCharacteristics done \(service.uuid)")
        if let error {
            parentPeripheral!.readyPromise.reject(error)
            parentPeripheral!.operationErrorSubject.send(error)
            return
        }
        parentPeripheral?.didDiscoverCharacteristics(for: service)
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
