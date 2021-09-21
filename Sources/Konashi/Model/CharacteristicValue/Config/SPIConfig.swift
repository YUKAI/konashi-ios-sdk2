//
//  SPIConfig.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

public struct SPIConfig: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 5
    }

    public let value: SPI.Config

    public static func parse(data: Data) -> Result<SPIConfig, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        switch SPI.Config.parse(bytes, info: nil) {
        case let .success(config):
            return .success(SPIConfig(value: config))
        case let .failure(error):
            return .failure(error)
        }
    }
}
