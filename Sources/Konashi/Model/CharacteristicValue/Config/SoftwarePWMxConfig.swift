//
//  SoftwarePWMxConfig.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

/// A representation of software PWMs configration.
public struct SoftwarePWMxConfig: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 12
    }

    /// Configurations for each software PWM pins.
    public let values: [PWM.Software.PinConfig]

    public static func parse(data: Data) -> Result<SoftwarePWMxConfig, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        let chunk = bytes.chunked(by: 3)
        var configs = [PWM.Software.PinConfig]()
        for (index, payload) in chunk.enumerated() {
            guard let pin = PWM.Pin(rawValue: UInt8(index)) else {
                return .failure(CharacteristicValueParseError.invalidPinNumber)
            }
            switch PWM.Software.PinConfig.parse(payload, info: [PWM.Software.PinConfig.InfoKey.pin.rawValue: pin]) {
            case let .success(config):
                configs.append(config)
            case let .failure(error):
                return .failure(error)
            }
        }
        return .success(SoftwarePWMxConfig(values: configs))
    }
}
