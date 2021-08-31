//
//  UARTInputValue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

public struct UARTInputValue: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 128
    }

    public let value: [UInt8]

    public static func parse(data: Data) -> Result<UARTInputValue, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .lessThan) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        return .success(UARTInputValue(value: bytes))
    }
}
