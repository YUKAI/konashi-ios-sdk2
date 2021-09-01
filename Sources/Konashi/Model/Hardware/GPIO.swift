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

    public enum RegisterState {
        case none
        case pullUp
        case pullDown
        
        static func compose(pullUp: Bool, pullDown: Bool) -> RegisterState {
            if pullUp == false, pullDown == false {
                return .none
            }
            if pullUp == true {
                return .pullUp
            }
            return .pullDown
        }
    }

    public enum PinMode {
        case disable
        case input
        case output
        case openSource // wired or, input
        case openDrain // wired and, input

        static func compose(enabled: Bool, direction: Direction, wiredFunction: WiredFunction) -> PinMode {
            if enabled == false {
                return .disable
            }
            if direction == .input {
                if wiredFunction == .wiredOr {
                    return .openSource
                }
                return .openDrain
            }
            return .output
        }

        func unwrap() -> (enabled: Bool, direction: Direction, wiredFunction: WiredFunction) {
            switch self {
            case .disable:
                return (false, .output, .disabled)
            case .input:
                return (true, .input, .disabled)
            case .output:
                return (true, .output, .disabled)
            case .openSource:
                return (true, .input, .wiredOr)
            case .openDrain:
                return (true, .input, .wiredAnd)
            }
        }

        func toDirection() -> Direction {
            switch self {
            case .output:
                return .output
            default:
                return .input
            }
        }

        func toWiredFunction() -> WiredFunction {
            switch self {
            case .openSource:
                return .wiredOr
            case .openDrain:
                return .wiredAnd
            default:
                return .disabled
            }
        }
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
        public let mode: PinMode
        public var registerState: RegisterState = .none
        public var notifyOnInputChange = false

        func compose() -> [UInt8] {
            var firstByte: UInt8 = pin.rawValue << 4
            if mode != .disable {
                firstByte |= 0x01
            }
            var secondByte: UInt8 = 0
            if notifyOnInputChange {
                secondByte |= 0x20
            }
            secondByte |= mode.toDirection().rawValue << 4
            secondByte |= mode.toWiredFunction().rawValue << 2
            if registerState == .pullUp {
                secondByte |= 0x02
            }
            else if registerState == .pullDown {
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
