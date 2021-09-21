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
        for (index, payload) in chunk.enumerated() {
            guard let pin = GPIO.Pin(rawValue: UInt8(index)) else {
                return .failure(CharacteristicValueParseError.invalidPinNumber)
            }
            switch GPIO.PinConfig.parse(payload, info: [GPIO.PinConfig.InfoKey.pin.rawValue: pin]) {
            case let .success(config):
                configs.append(config)
            case let .failure(error):
                return .failure(error)
            }
        }
        return .success(GPIOxConfig(values: configs))
    }
}
