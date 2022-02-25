//
//  HardwarePWMxValue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/28.
//

import Foundation

/// Output values of hardware PWM.
public struct HardwarePWMxOutput: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 24
    }

    /// Output values for each hardware PWM pins.
    public let values: [PWM.Hardware.Value]

    public static func parse(data: Data) -> Result<HardwarePWMxOutput, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }

        var values = [PWM.Hardware.Value]()
        let chunk = bytes.chunked(by: 6)
        for (index, byte) in chunk.enumerated() {
            guard let pin = PWM.Pin(rawValue: UInt8(index)) else {
                return .failure(CharacteristicValueParseError.invalidPinNumber)
            }

            values.append(
                PWM.Hardware.Value(
                    pin: pin,
                    value: UInt16.compose(fsb: byte[0], lsb: byte[1]),
                    transitionDuration: UInt32.compose(
                        first: byte[2],
                        second: byte[3],
                        third: byte[4],
                        forth: byte[5]
                    )
                )
            )
        }
        return .success(HardwarePWMxOutput(values: values))
    }
}
