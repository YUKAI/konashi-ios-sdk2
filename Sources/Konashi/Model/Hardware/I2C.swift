//
//  I2C.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/13.
//

import Foundation

public enum I2C {
    /// Errors for parsing bytes of I2C configuration.
    public enum ParseError: LocalizedError {
        case invalidMode
        case invalidResult
    }

    // swiftlint:disable inclusive_language
    public enum OperationError: LocalizedError {
        case invalidSlaveAddress
        case badWriteLength
        case badReadLength
    }

    // swiftlint:enable inclusive_language

    public enum Operation: UInt8 {
        case write
        case read
        case readWrite
    }

    public enum Mode: UInt8 {
        case standard
        case fast
    }

    public struct Value: Hashable {
        public enum OperationResult: UInt8 {
            /// Transfer completed successfully
            case done
            /// NACK received during transfer
            case nack
            /// Bus error during transfer (misplaced START/STOP)
            case busError
            /// Arbitration lost during transfer
            case arbLost
            /// Usage fault
            case usageFault
            /// SW fault
            case swFault
        }

        public let result: OperationResult
        /// Slave address
        public let address: UInt8
        /// The read data, if any (0~126 bytes)
        public let readBytes: [UInt8]
    }

    public enum Config: ParsablePayload, Hashable {
        static var byteSize: UInt {
            return 1
        }

        case enable(mode: Mode)
        case disable

        static func parse(_ data: [UInt8], info: [String: Any]? = nil) -> Result<I2C.Config, Error> {
            if data.count != byteSize {
                return .failure(PayloadParseError.invalidByteSize)
            }
            let flag = data[0].bits()
            guard let mode = I2C.Mode(rawValue: flag[0]) else {
                return .failure(I2C.ParseError.invalidMode)
            }
            if flag[1] == 1 {
                return .success(I2C.Config.enable(mode: mode))
            }
            return .success(I2C.Config.disable)
        }

        func compose() -> [UInt8] {
            switch self {
            case let .enable(mode):
                var byte: UInt8 = 0
                byte |= 0x01 << 1
                byte |= mode.rawValue
                return [byte]
            case .disable:
                return [0x00]
            }
        }
    }

    public struct TransferControlPayload: Payload {
        public let operation: Operation
        public let readLength: UInt8
        public let address: UInt8
        public let writeData: [UInt8]

        func compose() -> [UInt8] {
            var data: [UInt8] {
                if writeData.count >= 124 {
                    return [UInt8](writeData[0 ..< 124])
                }
                return writeData
            }
            return [operation.rawValue, readLength, address] + data
        }
    }
}
