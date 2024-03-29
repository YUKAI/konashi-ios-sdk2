//
//  SPI.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/13.
//

import Foundation

/// A hardware declaration of SPI.
public enum SPI {
    /// Errors for parsing bytes of SPI configuration.
    public enum ParseError: LocalizedError {
        case invalidEndian
        case invalidMode
    }

    /// A representation of SPI endian
    public enum Endian: UInt8 {
        case lsbFirst
        case msbFirst
    }

    /// A payload that represents SPI mode.
    public struct Mode: Payload, Hashable {
        // MARK: Public

        public enum Polarity: UInt8 {
            case low
            case high
        }

        public enum Phase: UInt8 {
            case low
            case high
        }

        /// SPI mode 0
        public static let mode0 = Mode(polarity: .low, phase: .low)
        /// SPI mode 1
        public static let mode1 = Mode(polarity: .low, phase: .high)
        /// SPI mode 2
        public static let mode2 = Mode(polarity: .high, phase: .low)
        /// SPI mode 3
        public static let mode3 = Mode(polarity: .high, phase: .high)

        public let polarity: Polarity
        public let phase: Phase

        // MARK: Internal

        func compose() -> [UInt8] {
            return [(polarity.rawValue << 1) | (phase.rawValue)]
        }
    }

    /// A payload to configure SPI.
    public enum Config: ParsablePayload, Hashable {
        case enable(bitrate: UInt32, endian: Endian, mode: Mode)
        case disable

        // MARK: Public

        public static var byteSize: UInt {
            return 5
        }

        // MARK: Internal

        static func parse(_ data: [UInt8], info: [String: Any]? = nil) -> Result<SPI.Config, Error> {
            if data.count != byteSize {
                return .failure(PayloadParseError.invalidByteSize)
            }
            let first = data[0]
            let (_, lsfb) = first.konashi_split2()
            guard let endian = SPI.Endian(rawValue: lsfb.konashi_bits()[3]) else {
                return .failure(SPI.ParseError.invalidEndian)
            }
            var mode: SPI.Mode? {
                switch lsfb & 0b00000011 {
                case 0x0:
                    return .mode0
                case 0x01:
                    return .mode1
                case 0x02:
                    return .mode2
                case 0x03:
                    return .mode3
                default:
                    return nil
                }
            }
            guard let mode else {
                return .failure(SPI.ParseError.invalidMode)
            }
            let flag = first.konashi_bits()
            if flag[7] == 0 {
                return .success(SPI.Config.disable)
            }
            return .success(
                SPI.Config.enable(
                    bitrate: UInt32.compose(
                        first: data[1],
                        second: data[2],
                        third: data[3],
                        forth: data[4]
                    ),
                    endian: endian,
                    mode: mode
                )
            )
        }

        func compose() -> [UInt8] {
            switch self {
            case let .enable(bitrate, endian, mode):
                var firstByte: UInt8 = 0
                firstByte |= 0x80
                firstByte |= endian.rawValue << 3
                firstByte |= mode.compose().first!
                return [firstByte] + bitrate.byteArray().reversed()
            case .disable:
                return [0x00, 0x00, 0x00, 0x00, 0x00]
            }
        }
    }

    /// A payload for sending data through SPI.
    public struct TransferControlPayload: Payload {
        // MARK: Public

        public let data: [UInt8]

        // MARK: Internal

        func compose() -> [UInt8] {
            if data.count >= 127 {
                return [UInt8](data[0 ..< 127])
            }
            return data
        }
    }
}
