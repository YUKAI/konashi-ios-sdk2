//
//  Analog.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/13.
//

// swiftlint:disable identifier_name

import Foundation

/// A hardware declaration of AIO.
public enum Analog {
    /// Errors for parsing bytes of AIO configuration.
    public enum ParseError: LocalizedError {
        case invalidDirection
        case invalidADCVoltageReference
        case invalidVDACVoltageReference
        case invalidIDACCurrentStepSize
    }

    public enum Pin: UInt8, CaseIterable, CustomStringConvertible {
        case pin0
        case pin1
        case pin2

        // MARK: Public

        public var description: String {
            switch self {
            case .pin0:
                return "AIO0"
            case .pin1:
                return "AIO1"
            case .pin2:
                return "AIO2"
            }
        }
    }

    public enum ADCVoltageReference: UInt8, CaseIterable {
        case disable
        case _1V25
        case _2V5
        case vdd
    }

    public enum VDACVoltageReference: UInt8, CaseIterable {
        case disable
        /// 1V25 low noise
        case _1V25LowNoise
        /// 2V5 lo noise
        case _2V5LowNoise
        /// 1V25
        case _1V25
        /// 2V5
        case _2V5
        // AVDD
        case avdd
    }

    /// IDAC current step size
    public enum IDACCurrentStepSize: UInt8, CaseIterable {
        case disable
        /// range 0.05~1.6uA, step 50nA
        case step50nA
        /// range 1.6~4.7uA, step 100nA
        case step100nA
        /// range 0.5~16uA, step 500nA
        case step500nA
        // range 2~64uA, step 2000nA
        case step2000nA
    }

    public struct OutputValue: Hashable {
        public let pin: Analog.Pin
        /// Indicates if the input value is valid.
        /// The pin is not an input, the value should be ignored.
        /// On the other hand, the pin is input and the value is true.
        public let isValid: Bool
        /// Current control value. The voltage or current step value currently set
        public let value: UInt16
        /// Transition duration remaining. Units of 1ms (0~4294967295)
        public let transitionDuration: UInt32
    }

    public struct InputValue: Hashable {
        public let pin: Analog.Pin
        /// Indicates if the input value is valid.
        /// The pin is not an input, the value should be ignored.
        /// On the other hand, the pin is input and the value is true.
        public let isValid: Bool
        /// Voltage step value (0~65535)
        public let step: UInt16
    }

    public struct PinConfig: ParsablePayload, Hashable {
        // MARK: Lifecycle

        public init(pin: Analog.Pin, isEnabled: Bool, notifyOnInputChange: Bool, direction: Direction) {
            self.pin = pin
            self.isEnabled = isEnabled
            self.notifyOnInputChange = notifyOnInputChange
            self.direction = direction
        }

        // MARK: Public

        public let pin: Analog.Pin
        public let isEnabled: Bool
        public let notifyOnInputChange: Bool
        public let direction: Direction

        // MARK: Internal

        enum InfoKey: String {
            case pin
        }

        static var byteSize: UInt {
            return 1
        }

        static func parse(_ data: [UInt8], info: [String: Any]? = nil) -> Result<Analog.PinConfig, Error> {
            if data.count != byteSize {
                return .failure(PayloadParseError.invalidByteSize)
            }
            guard let info, let pin = info[InfoKey.pin.rawValue] as? Analog.Pin else {
                return .failure(PayloadParseError.invalidInfo)
            }
            let flag = data[0].konashi_bits()
            guard let direction = Direction(rawValue: UInt8(flag[0])) else {
                return .failure(Analog.ParseError.invalidDirection)
            }
            return .success(PinConfig(
                pin: pin,
                isEnabled: flag[3] == 1,
                notifyOnInputChange: flag[1] == 1,
                direction: direction
            ))
        }

        func compose() -> [UInt8] {
            var byte: UInt8 = pin.rawValue << 4
            if isEnabled {
                byte |= 0x01 << 3
            }
            if notifyOnInputChange {
                byte |= 0x01 << 1
            }
            byte |= direction.rawValue

            return [byte]
        }
    }

    public struct ConfigPayload: Payload {
        // MARK: Lifecycle

        public init(pinConfig: [PinConfig]? = nil, adcUpdatePeriod: ADCUpdatePeriodConfig? = nil, adcVoltageReferenceConfig: ADCVoltageReferenceConfig? = nil, vdacVoltageReferenceConfig: VDACVoltageReferenceConfig? = nil, idacCurrentRangeConfig: IDACCurrentRangeConfig? = nil) {
            self.pinConfig = pinConfig
            self.adcUpdatePeriod = adcUpdatePeriod
            self.adcVoltageReferenceConfig = adcVoltageReferenceConfig
            self.vdacVoltageReferenceConfig = vdacVoltageReferenceConfig
            self.idacCurrentRangeConfig = idacCurrentRangeConfig
        }

        // MARK: Public

        public var pinConfig: [PinConfig]?
        public var adcUpdatePeriod: ADCUpdatePeriodConfig?
        public var adcVoltageReferenceConfig: ADCVoltageReferenceConfig?
        public var vdacVoltageReferenceConfig: VDACVoltageReferenceConfig?
        public var idacCurrentRangeConfig: IDACCurrentRangeConfig?

        // MARK: Internal

        func compose() -> [UInt8] {
            var bytes = [UInt8]()
            if let adcUpdatePeriod {
                bytes += adcUpdatePeriod.compose()
            }
            if let adcVoltageReferenceConfig {
                bytes += adcVoltageReferenceConfig.compose()
            }
            if let vdacVoltageReferenceConfig {
                bytes += vdacVoltageReferenceConfig.compose()
            }
            if let idacCurrentRangeConfig {
                bytes += idacCurrentRangeConfig.compose()
            }
            if let pinConfig {
                bytes += pinConfig.compose()
            }

            return bytes
        }
    }

    public struct ADCUpdatePeriodConfig: Payload {
        // MARK: Lifecycle

        public init(updatePeriodStep: UInt8) {
            self.updatePeriodStep = updatePeriodStep
        }

        // MARK: Public

        public let updatePeriodStep: UInt8

        // MARK: Internal

        func compose() -> [UInt8] {
            return [0b11110000, updatePeriodStep]
        }
    }

    public struct ADCVoltageReferenceConfig: Payload {
        // MARK: Lifecycle

        public init(reference: ADCVoltageReference) {
            self.reference = reference
        }

        // MARK: Public

        public let reference: ADCVoltageReference

        // MARK: Internal

        func compose() -> [UInt8] {
            return [0b11100000 | reference.rawValue]
        }
    }

    public struct VDACVoltageReferenceConfig: Payload {
        // MARK: Lifecycle

        public init(reference: VDACVoltageReference) {
            self.reference = reference
        }

        // MARK: Public

        public let reference: VDACVoltageReference

        // MARK: Internal

        func compose() -> [UInt8] {
            return [0b11010000 | reference.rawValue]
        }
    }

    public struct IDACCurrentRangeConfig: Payload {
        // MARK: Lifecycle

        public init(step: IDACCurrentStepSize) {
            self.step = step
        }

        // MARK: Public

        public let step: IDACCurrentStepSize

        // MARK: Internal

        func compose() -> [UInt8] {
            return [0b11000000 | step.rawValue]
        }
    }

    public struct ControlPayload: Payload {
        // MARK: Lifecycle

        public init(pin: Pin, stepValue: UInt16, transitionDurationMillisec: UInt32) {
            self.pin = pin
            self.stepValue = stepValue
            self.transitionDurationMillisec = transitionDurationMillisec
        }

        // MARK: Public

        public let pin: Pin
        public let stepValue: UInt16
        public let transitionDurationMillisec: UInt32

        // MARK: Internal

        func compose() -> [UInt8] {
            let firstByte: UInt8 = pin.rawValue
            return [firstByte] + stepValue.byteArray().reversed() + transitionDurationMillisec.byteArray().reversed()
        }
    }
}

// swiftlint:enable identifier_name
