//
//  CBPeripheralState+Debug.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/27.
//

import CoreBluetooth

extension CBPeripheralState {
    var konashi_description: String {
        switch self {
        case .disconnected:
            return "disconnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .disconnecting:
            return "disconnecting"
        @unknown default:
            return "unknown"
        }
    }
}
