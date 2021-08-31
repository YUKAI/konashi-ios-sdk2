//
//  UInt16+Compose.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

// https://stackoverflow.com/questions/25267089/convert-a-two-byte-uint8-array-to-a-uint16-in-swift
extension UInt16 {
    static func compose(fsb: UInt8, lsb: UInt8) -> UInt16 {
        let bytes = [fsb, lsb]
        return bytes.withUnsafeBytes { $0.load(as: UInt16.self) }
    }
}
