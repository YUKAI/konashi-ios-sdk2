//
//  I2CInputValue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

public struct I2CInputValue: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 128
    }

    public let value: I2C.Value

    public static func parse(data: Data) -> Result<I2CInputValue, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .lessThan) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }

        guard let result = I2C.Value.Result(rawValue: bytes[0]) else {
            return .failure(I2C.ParseError.invalidResult)
        }
        return .success(I2CInputValue(
            value: I2C.Value(
                result: result,
                address: bytes[1],
                readBytes: [UInt8](bytes[2 ..< 128])
            )
        ))
    }
}
