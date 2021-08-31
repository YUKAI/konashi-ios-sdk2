//
//  Array+Characteristic.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/15.
//

import CoreBluetooth
import Foundation

extension Array where Element == Characteristic {
    func find(characteristic target: CBCharacteristic) -> Element? {
        return first {
            $0.uuid.uuidString == target.uuid.uuidString
        }
    }
}
