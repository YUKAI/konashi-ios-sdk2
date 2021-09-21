//
//  UARTConfig.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

public struct UARTConfig: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 5
    }

    public let value: UART.Config

    public static func parse(data: Data) -> Result<UARTConfig, Error> {
        let bytes = [UInt8](data)
        switch UART.Config.parse(bytes, info: nil) {
        case let .success(config):
            return .success(UARTConfig(
                value: config
            ))
        case let .failure(error):
            return .failure(error)
        }
    }
}
