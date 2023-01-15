//
//  ConnectionStatus.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/12/12.
//

import Foundation

/// A confition of a peripheral.
public enum ConnectionStatus: Hashable {
    case error(Error)
    case disconnected
    case connecting
    case connected
    case readyToUse

    // MARK: Public

    public static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .error(error):
            hasher.combine(error.localizedDescription)
        case .disconnected:
            hasher.combine("disconnected")
        case .connecting:
            hasher.combine("connecting")
        case .connected:
            hasher.combine("connected")
        case .readyToUse:
            hasher.combine("readyToUse")
        }
    }
}
