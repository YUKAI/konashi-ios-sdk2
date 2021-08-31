//
//  I2C.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/13.
//

import Foundation

public enum I2C {
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
        public enum Result: UInt8 {
            case done
            case nack
            case busError
            case arbLost
            case usageFault
            case swFault
        }

        public let result: Result
        public let address: UInt8
        public let readBytes: [UInt8]
    }

    public struct Config: Hashable {
        public let isEnabled: Bool
        public let mode: Mode
    }

    public struct ConfigPayload: Payload {
        public let isEnabled: Bool
        public let mode: Mode

        func compose() -> [UInt8] {
            var byte: UInt8 = 0
            if isEnabled {
                byte |= 0x01 << 1
            }
            byte |= mode.rawValue

            return [byte]
        }
    }

    public struct TransferControlPayload: Payload {
        public let operation: Operation
        public let readLength: UInt8
        public let address: UInt8
        public let writeData: [UInt8]

        func compose() -> [UInt8] {
            return [operation.rawValue, readLength, address] + writeData[0 ..< 124]
        }
    }
}
