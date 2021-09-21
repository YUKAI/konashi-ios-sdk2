//
//  Payload.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Foundation

protocol Payload {
    func compose() -> [UInt8]
}

protocol ParsablePayload: Payload {
    static var byteSize: UInt { get }

    static func parse(_ data: [UInt8], info: [String: Any]?) -> Result<Self, Error>
}

public enum PayloadParseError: LocalizedError {
    case invalidByteSize
    case invalidInfo
}
