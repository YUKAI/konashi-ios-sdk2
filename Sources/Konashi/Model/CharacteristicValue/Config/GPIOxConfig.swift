//
//  GPIOConfig.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/12.
//

import Foundation

public struct GPIOxConfig: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 16
    }

    public let values: [GPIO.PinConfig]

    public static func parse(data: Data) -> Result<GPIOxConfig, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        let chunk = bytes.chunked(by: 2)
        var configs = [GPIO.PinConfig]()
        for (index, config) in chunk.enumerated() {
            let first = config[0]
            let second = config[1].bits()
            guard let function = GPIO.Function(rawValue: first) else {
                return .failure(GPIO.ParseError.invalidFunction)
            }
            guard let direction = Direction(rawValue: second[3]) else {
                return .failure(CharacteristicValueParseError.invalidDirection)
            }
            guard let wiredFunction = GPIO.WiredFunction(rawValue: second[2]) else {
                return .failure(GPIO.ParseError.invalidWiredFunction)
            }
            guard let pin = GPIO.Pin(rawValue: UInt8(index)) else {
                return .failure(CharacteristicValueParseError.invalidPinNumber)
            }
            configs.append(
                GPIO.PinConfig(
                    pin: pin,
                    function: function,
                    notifyOnInputChange: second[4] == 1,
                    direction: direction,
                    wiredFunction: wiredFunction,
                    pullUp: second[1] == 1,
                    pullDown: second[0] == 1
                )
            )
        }
        return .success(GPIOxConfig(values: configs))
    }
}
