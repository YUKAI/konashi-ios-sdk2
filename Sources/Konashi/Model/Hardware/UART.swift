//
//  UART.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/13.
//

// swiftlint:disable identifier_name

import Foundation

/// A hardware declaration of UART.
public enum UART {
    /// Errors for parsing bytes of UART configuration.
    public enum ParseError: LocalizedError {
        /// An error raised when attempt to parse invalid parity.
        case invalidParity
        /// An error raised when attempt to parse invalid stop bit.
        case invalidStopBit
    }

    public enum Parity: UInt8 {
        case none
        case odd
        case even
    }

    public enum StopBit: UInt8 {
        case _0_5
        case _1
        case _1_5
        case _2
    }

    /// A payload of UART configuration.
    public enum Config: ParsablePayload, Hashable {
        public static var byteSize: UInt {
            return 5
        }

        /// A payload to enable UART.
        case enable(parity: Parity, stopBit: StopBit, baudrate: UInt32)
        /// A payload to disable UART.
        case disable

        static func parse(_ data: [UInt8], info: [String: Any]? = nil) -> Result<UART.Config, Error> {
            if data.count != byteSize {
                return .failure(PayloadParseError.invalidByteSize)
            }
            let first = data[0]
            let (_, lsfb) = first.split2()
            guard let parity = UART.Parity(rawValue: lsfb >> 2) else {
                return .failure(UART.ParseError.invalidParity)
            }
            guard let stopBit = UART.StopBit(rawValue: lsfb & 0b00000011) else {
                return .failure(UART.ParseError.invalidStopBit)
            }
            let flag = first.bits()
            if flag[7] == 1 {
                return .success(
                    UART.Config.enable(
                        parity: parity,
                        stopBit: stopBit,
                        baudrate: UInt32.compose(
                            first: data[1],
                            second: data[2],
                            third: data[3],
                            forth: data[4]
                        )
                    )
                )
            }
            return .success(UART.Config.disable)
        }

        func compose() -> [UInt8] {
            switch self {
            case let .enable(parity, stopBit, baudrate):
                var firstByte: UInt8 = 0
                firstByte |= 0x80
                firstByte |= parity.rawValue << 2
                firstByte |= stopBit.rawValue
                return [firstByte] + baudrate.byteArray().reversed()
            case .disable:
                return [0x00, 0x00, 0x00, 0x00, 0x00]
            }
        }
    }

    /// A payload of UART send control.
    public struct SendControlPayload: Payload {
        /// Bytes to send.
        public let data: [UInt8]

        func compose() -> [UInt8] {
            if data.count >= 127 {
                return [UInt8](data[0 ..< 127])
            }
            return data
        }
    }
}

// swiftlint:enable identifier_name
