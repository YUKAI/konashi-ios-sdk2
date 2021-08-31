//
//  I2CConfig.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

public struct I2CConfig: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 1
    }

    public let value: I2C.Config

    public static func parse(data: Data) -> Result<I2CConfig, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        let first = bytes[0]
        let flag = first.bits()
        guard let mode = I2C.Mode(rawValue: flag[0]) else {
            return .failure(I2C.ParseError.invalidMode)
        }
        return .success(I2CConfig(
            value: I2C.Config(
                isEnabled: flag[1] == 1,
                mode: mode
            )
        ))
    }
}
