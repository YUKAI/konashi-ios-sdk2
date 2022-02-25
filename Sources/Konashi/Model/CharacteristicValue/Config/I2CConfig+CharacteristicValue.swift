//
//  File.swift
//  
//
//  Created by Akira Matsuda on 2022/02/26.
//

import Foundation

extension I2C.Config: CharacteristicValue {
    public static func parse(data: Data) -> Result<I2C.Config, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        return I2C.Config.parse(bytes, info: nil)
    }
}
