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
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        let first = bytes[0]
        let (mfsb, lsfb) = first.split2()
        guard let parity = UART.Parity(rawValue: mfsb) else {
            return .failure(UART.ParseError.invalidParity)
        }
        guard let stopBit = UART.StopBit(rawValue: lsfb) else {
            return .failure(UART.ParseError.invalidStopBit)
        }
        let flag = first.bits()
        return .success(UARTConfig(
            value: UART.Config(
                isEnabled: flag[7] == 1,
                parity: parity,
                stopBit: stopBit,
                baudrate: UInt32.compose(
                    first: bytes[1],
                    second: bytes[2],
                    third: bytes[3],
                    forth: bytes[4]
                )
            )
        ))
    }
}
