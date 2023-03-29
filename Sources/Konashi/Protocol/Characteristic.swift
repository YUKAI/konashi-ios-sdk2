//
//  Characteristic.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/10.
//

import Combine
import CoreBluetooth
import Foundation

// MARK: - Characteristic

/// An interface for BLE characteristics.
public protocol Characteristic {
    var serviceUUID: UUID { get }
    var uuid: UUID { get }

    func update(data: Data?)
}

public extension Characteristic {
    var characteristicUUID: CBUUID {
        return CBUUID(nsuuid: uuid)
    }
}
