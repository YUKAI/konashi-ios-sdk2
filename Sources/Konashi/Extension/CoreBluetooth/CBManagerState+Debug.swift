//
//  CBManagerState+Debug.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/27.
//

import CoreBluetooth

extension CBManagerState {
    var konashi_description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .resetting:
            return "resetting"
        case .unsupported:
            return "unsupported"
        case .unauthorized:
            return "unauthorized"
        case .poweredOff:
            return "poweredOff"
        case .poweredOn:
            return "poweredOn"
        }
    }
}
