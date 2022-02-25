//
//  I2CValue+CharacteristicValue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

extension I2C.Value: CharacteristicValue {
    public static var byteSize: UInt {
        return 128
    }

    public static func parse(data: Data) -> Result<I2C.Value, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .lessThan) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }

        guard let result = I2C.Value.OperationResult(rawValue: bytes[0]) else {
            return .failure(I2C.ParseError.invalidResult)
        }
        var readBytes: [UInt8] {
            let newBytes = bytes.dropFirst(2)
            if newBytes.isEmpty {
                return []
            }
            return [UInt8](newBytes)
        }
        return .success(I2C.Value(
            result: result,
            address: bytes[1],
            readBytes: readBytes
        ))
    }
}
