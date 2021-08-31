//
//  Array+Service.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/15.
//

import CoreBluetooth
import Foundation

extension Array where Element == Service {
    func find(service target: CBService) -> Element? {
        return first {
            $0.uuid.uuidString == target.uuid.uuidString
        }
    }

    func find(characteristic target: CBCharacteristic) -> Characteristic? {
        let service = first {
            $0.uuid.uuidString == target.service.uuid.uuidString
        }
        guard let service = service else {
            return nil
        }
        return service.characteristics.first {
            $0.characteristicUUID == target.uuid
        }
    }
}
