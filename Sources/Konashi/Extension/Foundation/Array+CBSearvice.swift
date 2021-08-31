//
//  Array+CBSearvice.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/10.
//

import CoreBluetooth

extension Array where Element == CBService {
    func find(uuid: UUID) -> CBService? {
        for service in self where service.uuid.uuidString == uuid.uuidString {
            return service
        }
        return nil
    }

    func find(uuid: UUID, characteristicUUID: UUID) -> CBCharacteristic? {
        for service in self where service.uuid.uuidString == uuid.uuidString {
            return service.characteristics?.find(uuid: characteristicUUID)
        }
        return nil
    }

    func find(characteristic: Characteristic) -> CBCharacteristic? {
        return find(uuid: characteristic.serviceUUID, characteristicUUID: characteristic.uuid)
    }
}
