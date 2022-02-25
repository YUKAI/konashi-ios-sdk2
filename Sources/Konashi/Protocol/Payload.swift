//
//  Payload.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Foundation

/// An interface for command payload.
protocol Payload {
    func compose() -> [UInt8]
}

/// An interface for command payload that can be structured from byte data.
protocol ParsablePayload: Payload {
    static var byteSize: UInt { get }

    static func parse(_ data: [UInt8], info: [String: Any]?) -> Result<Self, Error>
}

/// An errors that is raised when received data can not be parsed into payload.
public enum PayloadParseError: LocalizedError {
    /// Received byte size is not suitable to parse.
    case invalidByteSize
    /// Invalid additional info is passed.
    case invalidInfo
}
