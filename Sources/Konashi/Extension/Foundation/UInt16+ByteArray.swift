//
//  UInt16+ByteArray.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Foundation

extension UInt16 {
    func byteArray() -> [UInt8] {
        var endian = bigEndian
        let count = MemoryLayout<UInt16>.size
        let bytePtr = withUnsafePointer(to: &endian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return Array(bytePtr)
    }
}
