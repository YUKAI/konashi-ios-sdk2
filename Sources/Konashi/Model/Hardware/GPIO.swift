//
//  GPIO.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Foundation

public enum GPIO {
    public enum ParseError: LocalizedError {
        case invalidFunction
        case invalidWiredFunction
    }

    public enum Pin: UInt8, CaseIterable, CustomStringConvertible {
        public var description: String {
            switch self {
            case .pin0:
                return "GPIO0"
            case .pin1:
                return "GPIO1"
            case .pin2:
                return "GPIO2"
            case .pin3:
                return "GPIO3"
            case .pin4:
                return "GPIO4"
            case .pin5:
                return "GPIO5"
            case .pin6:
                return "GPIO6"
            case .pin7:
                return "GPIO7"
            }
        }

        case pin0
        case pin1
        case pin2
        case pin3
        case pin4
        case pin5
        case pin6
        case pin7
    }

    public enum Function: UInt8 {
        case disabled
        case gpio
        case pwm
        case i2c
        case spi
    }

    public enum WiredFunction: UInt8 {
        case disabled
        case wiredAnd
        case wiredOr
        case illegalValue
    }

    public struct Value: Hashable {
        public let pin: Pin
        public let isValid: Bool
        public let level: Level
    }

    public struct PinConfig: Hashable {
        public let pin: Pin
        public let function: Function
        public let notifyOnInputChange: Bool
        public let direction: Direction
        public let wiredFunction: WiredFunction
        public let pullUp: Bool
        public let pullDown: Bool
    }

    public struct ConfigPayload: Payload {
        public let pin: GPIO.Pin
        public var isEnabled = true
        public var notifyOnInputChange = false
        public var direction: Direction = .input
        public var wiredFunction: WiredFunction = .disabled
        public var pullUp = false
        public var pullDown = false

        func compose() -> [UInt8] {
            var firstByte: UInt8 = pin.rawValue << 4
            if isEnabled {
                firstByte |= 0x01
            }
            var secondByte: UInt8 = 0
            if notifyOnInputChange {
                secondByte |= 0x20
            }
            secondByte |= (direction == .input ? 0 : 1) << 4
            secondByte |= wiredFunction.rawValue << 2
            if pullUp {
                secondByte |= 0x02
            }
            if pullDown {
                secondByte |= 0x01
            }

            return [firstByte, secondByte]
        }
    }

    public struct ControlPayload: Payload {
        public let pin: GPIO.Pin
        public let level: Level

        func compose() -> [UInt8] {
            var byte: UInt8 = pin.rawValue << 4
            byte |= level.rawValue
            return [byte]
        }
    }
}
