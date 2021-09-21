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

    public struct Config: ParsablePayload, Hashable {
        static var byteSize: UInt {
            return 5
        }

        public let isEnabled: Bool
        public let endian: Endian
        public let mode: Mode
        public let bitrate: UInt32

        static func parse(_ data: [UInt8], info: [String: Any]?) -> Result<SPI.Config, Error> {
            if data.count != byteSize {
                return .failure(PayloadParseError.invalidByteSize)
            }
            let first = data[0]
            let (mfsb, lsfb) = first.split2()
            guard let endian = SPI.Endian(rawValue: mfsb) else {
                return .failure(SPI.ParseError.invalidEndian)
            }
            var mode: SPI.Mode? {
                switch lsfb {
                case 0x0:
                    return .init(polarity: .low, phase: .low)
                case 0x01:
                    return .init(polarity: .low, phase: .high)
                case 0x02:
                    return .init(polarity: .high, phase: .low)
                case 0x03:
                    return .init(polarity: .high, phase: .high)
                default:
                    return nil
                }
            }
            guard let mode = mode else {
                return .failure(SPI.ParseError.invalidMode)
            }
            let flag = first.bits()
            return .success(SPI.Config(
                isEnabled: flag[7] == 1,
                endian: endian,
                mode: mode,
                bitrate: UInt32.compose(
                    first: data[4],
                    second: data[3],
                    third: data[2],
                    forth: data[1]
                )
            ))
        }

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
