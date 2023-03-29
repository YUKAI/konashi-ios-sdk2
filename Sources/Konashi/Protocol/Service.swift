//
//  Service.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import CoreBluetooth

// MARK: - Service

/// An interface for BLE Service.
public protocol Service {
    static var uuid: UUID { get }
    var uuid: UUID { get }
    var characteristics: [Characteristic] { get }
    var notifiableCharacteristics: [Characteristic] { get }

    func applyAttributes(peripheral: CBPeripheral)
}

public extension Service {
    static var serviceUUID: CBUUID {
        return CBUUID(nsuuid: Self.uuid)
    }

    var uuid: UUID {
        return UUID(uuidString: Self.serviceUUID.uuidString)!
    }

    var serviceUUID: CBUUID {
        return CBUUID(nsuuid: uuid)
    }

    func applyAttributes(peripheral: CBPeripheral) {
        for characteristic in notifiableCharacteristics {
            if let characteristic = peripheral.services?.find(characteristic: characteristic) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
}
