//
//  CBPeripheral+Debug.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/27.
//

import CoreBluetooth

extension CBPeripheral {
    var konashi_debugName: String {
        return "\(name ?? "Unknown"): \(identifier)"
    }
}
