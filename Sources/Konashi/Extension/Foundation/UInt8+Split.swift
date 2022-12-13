//
//  UInt8+Split.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/10.
//

import Foundation

struct BitArray {
    let value: [Bool]
}

extension UInt8 {
    func konashi_split2() -> (msfb: UInt8, lsfb: UInt8) {
        return (self >> 4, self & 0x0F)
    }

    func konashi_bits() -> [UInt8] {
        var byte = self
        var bits = [UInt8](repeating: .zero, count: 8)
        for index in 0 ..< 8 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[index] = 1
            }

            byte >>= 1
        }

        return bits
    }
}
