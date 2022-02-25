//
//  GPIOxValue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/15.
//

import Foundation

/// Values of GPIOs.
public struct GPIOxValue: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 8
    }

    /// Values for each GPIOs.
    public let values: [GPIO.Value]

    public static func parse(data: Data) -> Result<GPIOxValue, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }

        var values = [GPIO.Value]()
        for (index, byte) in bytes.enumerated() {
            let bits = byte.bits()
            guard let level = Level(rawValue: bits[0]) else {
                return .failure(CharacteristicValueParseError.invalidLevel)
            }
            guard let pin = GPIO.Pin(rawValue: UInt8(index)) else {
                return .failure(CharacteristicValueParseError.invalidPinNumber)
            }
            values.append(
                GPIO.Value(
                    pin: pin,
                    isValid: bits[4] == 1,
                    level: level
                )
            )
        }
        return .success(GPIOxValue(values: values))
    }
}
