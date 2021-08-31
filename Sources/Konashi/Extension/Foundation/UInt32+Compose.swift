//
//  UInt32+Compose.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

extension UInt32 {
    static func compose(first: UInt8, second: UInt8, third: UInt8, forth: UInt8) -> UInt32 {
        let bytes = [first, second, third, forth]
        return bytes.withUnsafeBytes { $0.load(as: UInt32.self) }
    }
}
