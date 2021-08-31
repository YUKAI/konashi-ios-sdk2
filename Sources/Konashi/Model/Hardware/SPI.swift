//
//  SPI.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/13.
//

import Foundation

public enum SPI {
    public enum ParseError: LocalizedError {
        case invalidEndian
        case invalidMode
    }

    public enum Endian: UInt8 {
        case lsbFirst
        case msbFirst
    }

    public struct Mode: Payload, Hashable {
        public static let mode0 = Mode(polarity: .low, phase: .low)
        public static let mode1 = Mode(polarity: .low, phase: .high)
        public static let mode2 = Mode(polarity: .high, phase: .low)
        public static let mode3 = Mode(polarity: .high, phase: .high)

        public enum Polarity: UInt8 {
            case low
            case high
        }

        public enum Phase: UInt8 {
            case low
            case high
        }

        public let polarity: Polarity
        public let phase: Phase

        func compose() -> [UInt8] {
            return [(polarity.rawValue << 1) & (phase.rawValue)]
        }
    }

    public struct Config: Hashable {
        public let isEnabled: Bool
        public let endian: Endian
        public let mode: Mode
    }

    public struct ConfigPayload: Payload {
        public let isEnabled: Bool
        public let endian: Endian
        public let mode: Mode
        public let bitrate: UInt32

        func compose() -> [UInt8] {
            var firstByte: UInt8 = 0
            if isEnabled {
                firstByte |= 0x80
            }
            firstByte |= endian.rawValue << 3
            firstByte |= mode.compose().first!

            return [firstByte] + bitrate.byteArray().reversed()
        }
    }

    public struct TransferControlPayload: Payload {
        public let data: [UInt8]

        func compose() -> [UInt8] {
            return [UInt8](data[0 ..< 127])
        }
    }
}
