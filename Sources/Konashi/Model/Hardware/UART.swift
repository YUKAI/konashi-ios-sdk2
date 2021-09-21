//
//  UART.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/13.
//

// swiftlint:disable identifier_name

import Foundation

public enum UART {
    public enum ParseError: LocalizedError {
        case invalidParity
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

    public struct Config: ParsablePayload, Hashable {
        static var byteSize: UInt {
            return 5
        }

        public let isEnabled: Bool
        public let parity: Parity
        public let stopBit: StopBit
        public let baudrate: UInt32

        static func parse(_ data: [UInt8], info: [String: Any]?) -> Result<UART.Config, Error> {
            if data.count != byteSize {
                return .failure(PayloadParseError.invalidByteSize)
            }
            let first = data[0]
            let (mfsb, lsfb) = first.split2()
            guard let parity = UART.Parity(rawValue: mfsb) else {
                return .failure(UART.ParseError.invalidParity)
            }
            guard let stopBit = UART.StopBit(rawValue: lsfb) else {
                return .failure(UART.ParseError.invalidStopBit)
            }
            let flag = first.bits()
            return .success(UART.Config(
                isEnabled: flag[7] == 1,
                parity: parity,
                stopBit: stopBit,
                baudrate: UInt32.compose(
                    first: data[1],
                    second: data[2],
                    third: data[3],
                    forth: data[4]
                )
            ))
        }

        func compose() -> [UInt8] {
            var firstByte: UInt8 = 0
            if isEnabled {
                firstByte |= 0x80
            }
            firstByte |= parity.rawValue << 2
            firstByte |= stopBit.rawValue

            return [firstByte] + baudrate.byteArray().reversed()
        }
    }

    public struct SendControlPayload: Payload {
        public let data: [UInt8]

        func compose() -> [UInt8] {
            return [UInt8](data[0 ..< 127])
        }
    }
}

// swiftlint:enable identifier_name
