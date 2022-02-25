//
//  AnalogxValue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

public struct AnalogxOutputValue: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 22
    }

    /// Output values of AIO.
    public let values: [Analog.OutputValue]
    /// VDAC voltage reference
    public let reference: Analog.VDACVoltageReference
    /// IDAC current step size
    public let stepSize: Analog.IDACCurrentStepSize

    public static func parse(data: Data) -> Result<AnalogxOutputValue, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }

        var values = [Analog.OutputValue]()
        let newBytes = [UInt8](bytes.dropFirst())
        let (msb, lsb) = bytes[0].split2()
        guard let vdacReference = Analog.VDACVoltageReference(rawValue: msb) else {
            return .failure(Analog.ParseError.invalidVDACVoltageReference)
        }
        guard let stepSize = Analog.IDACCurrentStepSize(rawValue: lsb) else {
            return .failure(Analog.ParseError.invalidIDACCurrentStepSize)
        }
        let chunk = newBytes.chunked(by: 7)
        for (index, byte) in chunk.enumerated() {
            let first = byte[0]
            guard let pin = Analog.Pin(rawValue: UInt8(index)) else {
                return .failure(CharacteristicValueParseError.invalidPinNumber)
            }
            values.append(
                Analog.OutputValue(
                    pin: pin,
                    isValid: first.split2().lsfb == 1,
                    value: UInt16.compose(fsb: byte[1], lsb: byte[2]),
                    transitionDuration: UInt32.compose(
                        first: byte[3],
                        second: byte[4],
                        third: byte[5],
                        forth: byte[6]
                    )
                )
            )
        }
        return .success(
            AnalogxOutputValue(
                values: values,
                reference: vdacReference,
                stepSize: stepSize
            )
        )
    }
}
