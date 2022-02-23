//
//  Command.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Foundation

/// An interface for command payload. All BLE commands inherit this protocol.
public protocol Command {
    func compose() -> Data
}
