//
//  AnalogxConfig.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

/// A representation of configration for each AIOs.
public struct AnalogxConfig: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 7
    }

    /// Configurations for each AIO pins.
    public let values: [Analog.PinConfig]
    public let adcUpdatePeriod: UInt8
    public let adcVoltageReference: Analog.ADCVoltageReference
    public let vdacVoltageReference: Analog.VDACVoltageReference
    public let idacCurrentStepSize: Analog.IDACCurrentStepSize

    public static func parse(data: Data) -> Result<AnalogxConfig, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        var configs = [Analog.PinConfig]()
        for (index, payload) in bytes[0 ..< 3].enumerated() {
            guard let pin = Analog.Pin(rawValue: UInt8(index)) else {
                return .failure(CharacteristicValueParseError.invalidPinNumber)
            }
            switch Analog.PinConfig.parse([payload], info: [Analog.PinConfig.InfoKey.pin.rawValue: pin]) {
            case let .success(config):
                configs.append(config)
            case let .failure(error):
                return .failure(error)
            }
        }
        guard let adcVoltageReference = Analog.ADCVoltageReference(rawValue: bytes[4]) else {
            return .failure(Analog.ParseError.invalidADCVoltageReference)
        }
        guard let vdacVoltageReference = Analog.VDACVoltageReference(rawValue: bytes[5]) else {
            return .failure(Analog.ParseError.invalidVDACVoltageReference)
        }
        guard let idacCurrentStepSize = Analog.IDACCurrentStepSize(rawValue: bytes[6]) else {
            return .failure(Analog.ParseError.invalidIDACCurrentStepSize)
        }
        return .success(
            AnalogxConfig(
                values: configs,
                adcUpdatePeriod: bytes[3],
                adcVoltageReference: adcVoltageReference,
                vdacVoltageReference: vdacVoltageReference,
                idacCurrentStepSize: idacCurrentStepSize
            )
        )
    }
}
