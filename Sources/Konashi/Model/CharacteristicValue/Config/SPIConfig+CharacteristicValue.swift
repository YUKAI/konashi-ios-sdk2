//
//  SPI.Config+CharacteristicValue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

extension SPI.Config: CharacteristicValue {
    public static func parse(data: Data) -> Result<SPI.Config, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        return SPI.Config.parse(bytes, info: nil)
    }
}
