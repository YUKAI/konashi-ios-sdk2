//
//  AnalogxConfig.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

public struct AnalogxConfig: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 7
    }

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
        for (index, config) in bytes[0 ..< 3].enumerated() {
            guard let pin = Analog.Pin(rawValue: UInt8(index)) else {
                return .failure(CharacteristicValueParseError.invalidPinNumber)
            }
            let flag = config.bits()
            guard let direction = Direction(rawValue: UInt8(flag[0])) else {
                return .failure(CharacteristicValueParseError.invalidDirection)
            }
            configs.append(
                Analog.PinConfig(
                    pin: pin,
                    isEnabled: flag[3] == 1,
                    notifyOnInputChange: flag[1] == 1,
                    direction: direction
                )
            )
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
