//
//  PWMPin.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/04.
//

// swiftlint:disable identifier_name

import Foundation

public enum PWM {
    public enum ParseError: LocalizedError {
        case invalidControlValue
        case invalidClock
        case invalidPrescaler
    }

    public enum Pin: UInt8, CaseIterable, CustomStringConvertible {
        public var description: String {
            switch self {
            case .pin0:
                return "PWM0"
            case .pin1:
                return "PWM1"
            case .pin2:
                return "PWM2"
            case .pin3:
                return "PWM3"
            }
        }

        case pin0
        case pin1
        case pin2
        case pin3
    }

    public enum Software {
        public enum DriveConfig: Hashable {
            case disable
            case duty(millisec: UInt16)
            case period(ratio: Float)
        }

        public enum ControlValue: Hashable {
            case duty(ratio: Float)
            case period(millisec: UInt16)
        }

        public struct Value: Hashable {
            public let pin: Pin
            public let controlValue: ControlValue?
            public let transitionDuration: UInt32
        }

        public struct PinConfig: Payload, Hashable {
            public let pin: PWM.Pin
            public let driveConfig: DriveConfig

            func compose() -> [UInt8] {
                var firstByte: UInt8 = pin.rawValue << 4
                var bytes = [UInt8]()
                switch driveConfig {
                case let .duty(millisec):
                    firstByte |= 0x01
                    bytes = millisec.byteArray()
                case let .period(ratio):
                    firstByte |= 0x02
                    bytes = UInt16(ratio * 1000).byteArray()
                case .disable:
                    firstByte |= 0x00
                    bytes = [0x00, 0x00]
                }

                return [firstByte] + bytes.reversed()
            }
        }

        public struct ControlPayload: Payload {
            public let pin: Pin
            public let value: ControlValue
            public let transitionDuration: UInt32

            func compose() -> [UInt8] {
                let firstByte: UInt8 = pin.rawValue
                var byteValue: [UInt8] {
                    switch value {
                    case let .duty(ratio):
                        return UInt16(ratio * 1000).byteArray().reversed()
                    case let .period(millisec):
                        return millisec.byteArray().reversed()
                    }
                }
                return [firstByte] + byteValue + transitionDuration.byteArray().reversed()
            }
        }
    }

    public enum Hardware {
        public enum Clock: UInt8, CaseIterable, CustomStringConvertible {
            public var description: String {
                switch self {
                case ._38_4M:
                    return "38.4MHz"
                case ._20k:
                    return "20kHz"
                }
            }

            case _38_4M
            case _20k
        }

        public enum Prescaler: UInt8, CaseIterable, CustomStringConvertible {
            public var description: String {
                switch self {
                case .div1:
                    return "div1"
                case .div2:
                    return "div2"
                case .div4:
                    return "div4"
                case .div8:
                    return "div8"
                case .div16:
                    return "div8"
                case .div32:
                    return "div32"
                case .div64:
                    return "div64"
                case .div128:
                    return "div128"
                case .div256:
                    return "div256"
                case .div512:
                    return "div512"
                case .div1024:
                    return "div1024"
                }
            }

            case div1
            case div2
            case div4
            case div8
            case div16
            case div32
            case div64
            case div128
            case div256
            case div512
            case div1024
        }

        public struct PinConfig: Payload, Hashable {
            public let pin: PWM.Pin
            public let isEnabled: Bool

            func compose() -> [UInt8] {
                var byte: UInt8 = pin.rawValue << 4
                if isEnabled {
                    byte |= 0x01
                }

                return [byte]
            }
        }

        public struct ClockConfig: Payload, Hashable {
            public let clock: Clock
            public let prescaler: Prescaler
            public let timerValue: UInt16

            func compose() -> [UInt8] {
                let firstByte: UInt8 = 0xFF
                var secondByte: UInt8 = clock.rawValue << 4
                secondByte |= prescaler.rawValue & 0x0F

                return [firstByte, secondByte] + timerValue.byteArray().reversed()
            }
        }

        public struct Value: Hashable {
            public let pin: Pin
            public let value: UInt16
            public let transitionDuration: UInt32
        }

        public struct ConfigPayload: Payload {
            public var pinConfig: [PinConfig]?
            public var clockConfig: ClockConfig?

            func compose() -> [UInt8] {
                var bytes = [UInt8]()
                if let payload = pinConfig {
                    bytes += payload.compose()
                }
                if let payload = clockConfig {
                    bytes += payload.compose()
                }
                return bytes
            }
        }

        public struct ControlPayload: Payload {
            public let pin: Pin
            public let controlValue: UInt16
            public let transitionDurationMillisec: UInt32

            func compose() -> [UInt8] {
                let firstByte: UInt8 = pin.rawValue
                return [firstByte] + controlValue.byteArray().reversed() + transitionDurationMillisec.byteArray().reversed()
            }
        }
    }
}

// swiftlint:enable identifier_name
