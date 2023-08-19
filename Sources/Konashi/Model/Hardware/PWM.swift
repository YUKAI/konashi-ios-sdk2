//
//  PWM.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/04.
//

// swiftlint:disable identifier_name

import Foundation

/// A hardware declaration of PWM.
public enum PWM {
    /// Errors for parsing bytes of PWM configuration.
    public enum ParseError: LocalizedError {
        case invalidDriveConfig
        case invalidControlValue
        case invalidClock
        case invalidPrescaler
    }

    /// A representation of PWM pin.
    public enum Pin: UInt8, CaseIterable, CustomStringConvertible {
        case pin0
        case pin1
        case pin2
        case pin3

        // MARK: Public

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
    }

    public enum Software {
        /// A representation of software PWM configuration.
        public enum DriveConfig: Hashable {
            /// Disable software PWM
            case disable
            /// Drive software PWM by duty
            case duty(millisec: UInt16)
            /// Drive software PWM by period
            case period(ratio: Float)
        }

        /// A representation of software PWM control value.
        public enum ControlValue: Hashable {
            /// Duty ratio of software PWM
            case duty(ratio: Float)
            /// Period of software PWM
            case period(millisec: UInt16)
        }

        /// A representation of software PWM value.
        public struct Value: Hashable {
            public let pin: Pin
            public let controlValue: ControlValue?
            public let transitionDuration: UInt32
        }

        /// A payload of software PWM configuration.
        public struct PinConfig: ParsablePayload, Hashable {
            // MARK: Lifecycle

            public init(pin: PWM.Pin, driveConfig: DriveConfig) {
                self.pin = pin
                self.driveConfig = driveConfig
            }

            // MARK: Public

            /// A pin of configuration.
            public let pin: PWM.Pin
            /// Drive configuration of corresponding pin configuration.
            public let driveConfig: DriveConfig

            // MARK: Internal

            enum InfoKey: String {
                case pin
            }

            static var byteSize: UInt {
                return 3
            }

            static func parse(_ data: [UInt8], info: [String: Any]?) -> Result<PWM.Software.PinConfig, Error> {
                if data.count != byteSize {
                    return .failure(PayloadParseError.invalidByteSize)
                }
                guard let info, let pin = info[InfoKey.pin.rawValue] as? PWM.Pin else {
                    return .failure(PayloadParseError.invalidInfo)
                }
                let first = data[0] & 0x0F
                var driveConfig: PWM.Software.DriveConfig? {
                    switch first {
                    case 0x0:
                        return .disable
                    case 0x01:
                        return .duty(
                            millisec: UInt16.compose(fsb: data[1], lsb: data[2])
                        )
                    case 0x02:
                        return .period(
                            ratio: Float(UInt16.compose(fsb: data[1], lsb: data[2])) / 1000.0
                        )
                    default:
                        return nil
                    }
                }
                guard let driveConfig else {
                    return .failure(PWM.ParseError.invalidDriveConfig)
                }
                return .success(PWM.Software.PinConfig(
                    pin: pin,
                    driveConfig: driveConfig
                ))
            }

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

        /// A payload to control software PWM.
        public struct ControlPayload: Payload {
            // MARK: Lifecycle

            public init(pin: Pin, value: ControlValue, transitionDuration: UInt32) {
                self.pin = pin
                self.value = value
                self.transitionDuration = transitionDuration
            }

            // MARK: Public

            public let pin: Pin
            public let value: ControlValue
            public let transitionDuration: UInt32

            // MARK: Internal

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
        /// The clock source for the PWM timer
        public enum Clock: UInt8, CaseIterable, CustomStringConvertible {
            case _38_4M
            case _20k

            // MARK: Public

            public var description: String {
                switch self {
                case ._38_4M:
                    return "38.4MHz"
                case ._20k:
                    return "20kHz"
                }
            }
        }

        /// The clock prescaler for the PWM timer
        public enum Prescaler: UInt8, CaseIterable, CustomStringConvertible {
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

            // MARK: Public

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
        }

        /// A payload of harware PWM configuration.
        public struct PinConfig: ParsablePayload, Hashable {
            // MARK: Lifecycle

            public init(pin: PWM.Pin, isEnabled: Bool) {
                self.pin = pin
                self.isEnabled = isEnabled
            }

            // MARK: Public

            /// A pin of configuration.
            public let pin: PWM.Pin
            /// Enable or disable hardware PWM.
            public let isEnabled: Bool

            // MARK: Internal

            enum InfoKey: String {
                case pin
            }

            static var byteSize: UInt {
                return 1
            }

            static func parse(_ data: [UInt8], info: [String: Any]?) -> Result<PWM.Hardware.PinConfig, Error> {
                if data.count != byteSize {
                    return .failure(PayloadParseError.invalidByteSize)
                }
                guard let info, let pin = info[InfoKey.pin.rawValue] as? PWM.Pin else {
                    return .failure(PayloadParseError.invalidInfo)
                }

                return .success(PinConfig(
                    pin: pin,
                    isEnabled: data[0] & 0x01 == 1
                ))
            }

            func compose() -> [UInt8] {
                var byte: UInt8 = pin.rawValue << 4
                if isEnabled {
                    byte |= 0x01
                }

                return [byte]
            }
        }

        /// A payload to configure hardware PWM clock.
        public struct ClockConfig: Payload, Hashable {
            // MARK: Lifecycle

            public init(clock: Clock, prescaler: Prescaler, timerValue: UInt16) {
                self.clock = clock
                self.prescaler = prescaler
                self.timerValue = timerValue
            }

            // MARK: Public

            public let clock: Clock
            public let prescaler: Prescaler
            public let timerValue: UInt16

            // MARK: Internal

            func compose() -> [UInt8] {
                let firstByte: UInt8 = 0xFF
                var secondByte: UInt8 = clock.rawValue << 4
                secondByte |= prescaler.rawValue & 0x0F

                return [firstByte, secondByte] + timerValue.byteArray().reversed()
            }
        }

        /// A representation of hardware PWM value.
        public struct Value: Hashable {
            public let pin: Pin
            public let value: UInt16
            public let transitionDuration: UInt32
        }

        public struct ConfigPayload: Payload {
            // MARK: Lifecycle

            public init(pinConfig: [PinConfig]? = nil, clockConfig: ClockConfig? = nil) {
                self.pinConfig = pinConfig
                self.clockConfig = clockConfig
            }

            // MARK: Public

            public var pinConfig: [PinConfig]?
            public var clockConfig: ClockConfig?

            // MARK: Internal

            func compose() -> [UInt8] {
                var bytes = [UInt8]()
                if let clockConfig {
                    bytes += clockConfig.compose()
                }
                if let pinConfig {
                    bytes += pinConfig.compose()
                }
                return bytes
            }
        }

        /// A payload to control hardware PWM.
        public struct ControlPayload: Payload {
            // MARK: Lifecycle

            public init(pin: Pin, controlValue: UInt16, transitionDurationMillisec: UInt32) {
                self.pin = pin
                self.controlValue = controlValue
                self.transitionDurationMillisec = transitionDurationMillisec
            }

            // MARK: Public

            public let pin: Pin
            public let controlValue: UInt16
            public let transitionDurationMillisec: UInt32

            // MARK: Internal

            func compose() -> [UInt8] {
                let firstByte: UInt8 = pin.rawValue
                return [firstByte] + controlValue.byteArray().reversed() + transitionDurationMillisec.byteArray().reversed()
            }
        }
    }
}

// swiftlint:enable identifier_name
