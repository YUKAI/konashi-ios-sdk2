//
//  Array+Service.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/15.
//

import CoreBluetooth
import Foundation

extension [Service] {
    func find(service target: CBService) -> Element? {
        return first {
            $0.uuid.uuidString == target.uuid.uuidString
        }
    }

    func find(characteristic target: CBCharacteristic) -> Characteristic? {
        let service = first {
            #if compiler(>=5.5)
                return $0.uuid.uuidString == target.service?.uuid.uuidString
            #else
                return $0.uuid.uuidString == target.service.uuid.uuidString
            #endif
        }
        guard let service else {
            return nil
        }
        return service.characteristics.first {
            $0.characteristicUUID == target.uuid
        }
    }
}
