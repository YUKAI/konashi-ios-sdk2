//
//  SPIInputValue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

/// Received the read data of an SPI transfer.
public struct SPIInputValue: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 128
    }

    /// The read data, if any (0~127 bytes). The length of the read data would be the same length as the sent data.
    public let value: [UInt8]

    public static func parse(data: Data) -> Result<SPIInputValue, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .lessThan) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        return .success(SPIInputValue(value: bytes))
    }
}
