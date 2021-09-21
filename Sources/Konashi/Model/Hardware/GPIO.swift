//
//  GPIO.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Foundation

public enum GPIO {
    public enum ParseError: LocalizedError {
        case invalidDirection
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
                else if wiredFunction == .wiredAnd {
                    return .openDrain
                }
                return .input
            }
            return .output
        }

        func unwrap() -> (enabled: Bool, direction: Direction, wiredFunction: WiredFunction) {
            switch self {
            case .disable:
                return (false, .input, .disabled)
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

    public struct PinConfig: ParsablePayload, Hashable {
        enum InfoKey: String {
            case pin
        }

        static var byteSize: UInt {
            return 2
        }

        public let pin: GPIO.Pin
        public let mode: PinMode
        public var registerState: RegisterState = .none
        public var notifyOnInputChange = false
        public var function: Function?
        public var direction: Direction {
            return mode.toDirection()
        }

        public var wiredFunction: WiredFunction {
            return mode.toWiredFunction()
        }

        static func parse(_ data: [UInt8], info: [String: Any]?) -> Result<GPIO.PinConfig, Error> {
            if data.count != byteSize {
                return .failure(PayloadParseError.invalidByteSize)
            }
            guard let info = info, let pin = info[InfoKey.pin.rawValue] as? GPIO.Pin else {
                return .failure(PayloadParseError.invalidInfo)
            }
            let first = data[0]
            let second = data[1].bits()
            guard let function = GPIO.Function(rawValue: first) else {
                return .failure(GPIO.ParseError.invalidFunction)
            }
            guard let direction = Direction(rawValue: second[4]) else {
                return .failure(GPIO.ParseError.invalidDirection)
            }
            guard let wiredFunction = GPIO.WiredFunction(rawValue: second[3] << 1 | second[2]) else {
                return .failure(GPIO.ParseError.invalidWiredFunction)
            }
            var state: GPIO.RegisterState {
                if second[0] == 0, second[1] == 0 {
                    return .none
                }
                if second[1] == 1 {
                    return .pullUp
                }
                if second[0] == 1 {
                    return .pullDown
                }
                return .none
            }
            return .success(PinConfig(
                pin: pin,
                mode: .compose(enabled: function == .gpio, direction: direction, wiredFunction: wiredFunction),
                registerState: state,
                notifyOnInputChange: second[4] == 1,
                function: function
            ))
        }

        func compose() -> [UInt8] {
            var firstByte: UInt8 = pin.rawValue << 4
            if mode != .disable {
                firstByte |= 0x01
            }
            var secondByte: UInt8 = 0
            if notifyOnInputChange {
                secondByte |= 0x20
            }
            secondByte |= direction.rawValue << 4
            secondByte |= wiredFunction.rawValue << 2
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
