//
//  Analog.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/13.
//

// swiftlint:disable identifier_name

import Foundation

public enum Analog {
    public enum ParseError: LocalizedError {
        case invalidADCVoltageReference
        case invalidVDACVoltageReference
        case invalidIDACCurrentStepSize
    }

    public enum Pin: UInt8, CaseIterable, CustomStringConvertible {
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

        case pin0
        case pin1
        case pin2
    }

    public enum ADCVoltageReference: UInt8, CaseIterable {
        case disable
        case _1V25
        case _2V5
        case vdd
    }

    public enum VDACVoltageReference: UInt8, CaseIterable {
        case disable
        case _1V25LowNoise
        case _2V5LowNoise
        case _1V25
        case _2V5
        case avdd
    }

    public enum IDACCurrentStepSize: UInt8, CaseIterable {
        case disable
        case step50nA
        case step100nA
        case step500nA
        case step2000nA
    }

    public struct OutputValue: Hashable {
        public let pin: Analog.Pin
        public let isValid: Bool
        public let value: UInt16
        public let transitionDuration: UInt32
    }

    public struct InputValue: Hashable {
        public let pin: Analog.Pin
        public let isValid: Bool
        public let step: UInt16
    }

    public struct PinConfig: Payload, Hashable {
        public let pin: Analog.Pin
        public let isEnabled: Bool
        public let notifyOnInputChange: Bool
        public let direction: Direction

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
        public var pinConfig: [PinConfig]?
        public var adcUpdatePeriod: ADCUpdatePeriodConfig?
        public var adcVoltageReferenceConfig: ADCVoltageReferenceConfig?
        public var vdacVoltageReferenceConfig: VDACVoltageReferenceConfig?
        public var idacCurrentRangeConfig: IDACCurrentRangeConfig?

        func compose() -> [UInt8] {
            var bytes = [UInt8]()
            if let payload = pinConfig {
                bytes += payload.compose()
            }
            if let payload = adcUpdatePeriod {
                bytes += payload.compose()
            }
            if let payload = adcVoltageReferenceConfig {
                bytes += payload.compose()
            }
            if let payload = vdacVoltageReferenceConfig {
                bytes += payload.compose()
            }
            if let payload = idacCurrentRangeConfig {
                bytes += payload.compose()
            }

            return bytes
        }
    }

    public struct ADCUpdatePeriodConfig: Payload {
        public let updatePeriodStep: UInt8

        func compose() -> [UInt8] {
            return [0b11110000, updatePeriodStep]
        }
    }

    public struct ADCVoltageReferenceConfig: Payload {
        public let reference: ADCVoltageReference

        func compose() -> [UInt8] {
            return [0b11100000 | reference.rawValue]
        }
    }

    public struct VDACVoltageReferenceConfig: Payload {
        public let reference: VDACVoltageReference

        func compose() -> [UInt8] {
            return [0b11010000 | reference.rawValue]
        }
    }

    public struct IDACCurrentRangeConfig: Payload {
        public let step: IDACCurrentStepSize

        func compose() -> [UInt8] {
            return [0b11000000 | step.rawValue]
        }
    }

    public struct ControlPayload: Payload {
        public let pin: Pin
        public let stepValue: UInt16
        public let transitionDurationMillisec: UInt32

        func compose() -> [UInt8] {
            let firstByte: UInt8 = pin.rawValue
            return [firstByte] + stepValue.byteArray().reversed() + transitionDurationMillisec.byteArray().reversed()
        }
    }
}

// swiftlint:enable identifier_name
