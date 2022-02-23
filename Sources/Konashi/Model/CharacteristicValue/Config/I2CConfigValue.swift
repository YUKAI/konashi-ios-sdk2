//
//  I2CConfig.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

public struct I2CConfigValue: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 1
    }

    public let value: I2C.Config

    public static func parse(data: Data) -> Result<I2CConfigValue, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        switch I2C.Config.parse(bytes, info: nil) {
        case let .success(config):
            return .success(I2CConfigValue(value: config))
        case let .failure(error):
            return .failure(error)
        }
    }
}
