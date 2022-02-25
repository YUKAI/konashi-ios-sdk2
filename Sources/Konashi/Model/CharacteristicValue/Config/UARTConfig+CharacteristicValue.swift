//
//  UART.Config+CharacteristicValue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

extension UART.Config: CharacteristicValue {
    public static func parse(data: Data) -> Result<UART.Config, Error> {
        let bytes = [UInt8](data)
        return UART.Config.parse(bytes, info: nil)
    }
}
