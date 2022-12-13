//
//  Array+CBCharacteristic.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/10.
//

import CoreBluetooth

extension [CBCharacteristic] {
    func find(uuid: UUID) -> CBCharacteristic? {
        for characteristic in self where characteristic.uuid.uuidString == uuid.uuidString {
            return characteristic
        }
        return nil
    }
}
