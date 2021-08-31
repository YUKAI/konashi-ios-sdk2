//
//  PWMxValue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

public struct SoftwarePWMxOutput: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 28
    }

    public let values: [PWM.Software.Value]

    public static func parse(data: Data) -> Result<SoftwarePWMxOutput, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }

        var values = [PWM.Software.Value]()
        let chunk = bytes.chunked(by: 7)
        for (index, byte) in chunk.enumerated() {
            guard let pin = PWM.Pin(rawValue: UInt8(index)) else {
                return .failure(CharacteristicValueParseError.invalidPinNumber)
            }
            let first = byte[0]
            var value: PWM.Software.ControlValue? {
                switch first {
                case 0x01:
                    return .duty(
                        ratio: Float(UInt16.compose(fsb: byte[1], lsb: byte[2])) / 1000.0
                    )
                case 0x02:
                    return .period(millisec: UInt16.compose(fsb: byte[1], lsb: byte[2]))
                default:
                    return nil
                }
            }
            values.append(
                PWM.Software.Value(
                    pin: pin,
                    controlValue: value,
                    transitionDuration: UInt32.compose(
                        first: byte[3],
                        second: byte[4],
                        third: byte[5],
                        forth: byte[6]
                    )
                )
            )
        }
        return .success(SoftwarePWMxOutput(values: values))
    }
}
