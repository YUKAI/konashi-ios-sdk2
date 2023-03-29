//
//  PHYsBitmask.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/10.
//

// swiftlint:disable identifier_name

import Foundation

/// A representation of bluetooth physical layer bitmask.
public struct PHYsBitmask: OptionSet, CustomStringConvertible, CaseIterable {
    // MARK: Lifecycle

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    // MARK: Public

    /// 1M PHY uncoded
    public static var _1MUncoded = PHYsBitmask(rawValue: 0x01)
    /// 2M PHY uncoded
    public static var _2MUncoded = PHYsBitmask(rawValue: 0x02)
    /// Coded PHY 125k
    public static var coded125k = PHYsBitmask(rawValue: 0x04)
    /// Coded PHY 500k
    public static var coded500k = PHYsBitmask(rawValue: 0x08)

    public static var allCases: [PHYsBitmask] = [
        _1MUncoded,
        _2MUncoded,
        coded125k,
        coded500k
    ]

    public let rawValue: UInt8

    public var description: String {
        return String(format: "0x%02X", rawValue)
    }

    // MARK: Internal

    static func convert(_ value: UInt8) -> PHYsBitmask {
        var mask = PHYsBitmask()
        for phy in PHYsBitmask.allCases where (value & phy.rawValue) > 0 {
            mask = mask.union(phy)
        }
        return mask
    }
}

// swiftlint:enable identifier_name
