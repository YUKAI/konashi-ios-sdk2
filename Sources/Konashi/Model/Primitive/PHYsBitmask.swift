//
//  PHYsBitmask.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/10.
//

// swiftlint:disable identifier_name

import Foundation

public struct PHYsBitmask: OptionSet, CustomStringConvertible, CaseIterable {
    public static var _1MUncoded = PHYsBitmask(rawValue: 0x01)
    public static var _2MUncoded = PHYsBitmask(rawValue: 0x02)
    public static var coded125k = PHYsBitmask(rawValue: 0x04)
    public static var coded500k = PHYsBitmask(rawValue: 0x08)

    public static var allCases: [PHYsBitmask] = [
        _1MUncoded,
        _2MUncoded,
        coded125k,
        coded500k
    ]

    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public var description: String {
        return String(format: "0x%02X", rawValue)
    }

    static func convert(_ value: UInt8) -> PHYsBitmask {
        var mask = PHYsBitmask()
        for phy in PHYsBitmask.allCases where (value & phy.rawValue) > 0 {
            mask = mask.union(phy)
        }
        return mask
    }
}

// swiftlint:enable identifier_name
