//
//  AnalogxInputValue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

public struct AnalogxInputValue: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 10
    }

    public let values: [Analog.InputValue]
    /// ADC voltage reference
    public let reference: Analog.ADCVoltageReference

    public static func parse(data: Data) -> Result<AnalogxInputValue, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }

        let newBytes = [UInt8](bytes.dropFirst())
        guard let adcReference = Analog.ADCVoltageReference(rawValue: bytes[0]) else {
            return .failure(Analog.ParseError.invalidADCVoltageReference)
        }
        var values = [Analog.InputValue]()
        let chunk = newBytes.chunked(by: 3)
        for (index, byte) in chunk.enumerated() {
            let first = byte[0]
            guard let pin = Analog.Pin(rawValue: UInt8(index)) else {
                return .failure(CharacteristicValueParseError.invalidPinNumber)
            }
            values.append(
                Analog.InputValue(
                    pin: pin,
                    isValid: first.split2().lsfb == 1,
                    step: UInt16.compose(fsb: byte[1], lsb: byte[2])
                )
            )
        }
        return .success(
            AnalogxInputValue(
                values: values,
                reference: adcReference
            )
        )
    }
}
