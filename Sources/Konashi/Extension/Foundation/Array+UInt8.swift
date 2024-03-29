//
//  Array+UInt8.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/28.
//

import Foundation

// swiftlint:disable empty_count
// https://stackoverflow.com/questions/33546967/how-to-convert-array-of-bytes-uint8-into-hexa-string-in-swift
extension [UInt8] {
    func toHexString(spacing: String = " ") -> String {
        var hexString = ""
        var counter = count
        for byte in self {
            hexString.append(String(format: "0x%02X", byte))
            counter = counter - 1
            if counter > 0 {
                hexString.append(spacing)
            }
        }
        return hexString
    }
}

// swiftlint:enable empty_count
