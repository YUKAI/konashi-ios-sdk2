//
//  ConnectionState.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/12/12.
//

import Foundation

/// A confition of a peripheral.
public enum ConnectionState: Hashable {
    case error(Error)
    case disconnecting
    case disconnected
    case connecting
    case connected

    // MARK: Public

    public static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .error(error):
            hasher.combine(error.localizedDescription)
        case .disconnecting:
            hasher.combine("disconnecting")
        case .disconnected:
            hasher.combine("disconnected")
        case .connecting:
            hasher.combine("connecting")
        case .connected:
            hasher.combine("connected")
        }
    }
    
    var connectable: Bool {
        switch self {
        case .disconnected, .error:
            return true
        default:
            return false
        }
    }
}
