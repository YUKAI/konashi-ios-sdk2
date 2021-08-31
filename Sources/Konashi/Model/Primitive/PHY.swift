//
//  PHY.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/10.
//

// swiftlint:disable identifier_name

import Foundation

public enum PHY: UInt8, CaseIterable, CustomStringConvertible {
    public var description: String {
        switch self {
        case ._1M:
            return "1M PHY"
        case ._2M:
            return "2M PHY"
        case .coded:
            return "Coded PHY"
        }
    }

    case _1M = 0x01
    case _2M = 0x02
    case coded = 0x04
}

// swiftlint:enable identifier_name
