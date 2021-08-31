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
        let first = bytes[0]
        let (mfsb, lsfb) = first.split2()
        guard let endian = SPI.Endian(rawValue: mfsb) else {
            return .failure(SPI.ParseError.invalidEndian)
        }
        var mode: SPI.Mode? {
            switch lsfb {
            case 0x0:
                return .init(polarity: .low, phase: .low)
            case 0x01:
                return .init(polarity: .low, phase: .high)
            case 0x02:
                return .init(polarity: .high, phase: .low)
            case 0x03:
                return .init(polarity: .high, phase: .high)
            default:
                return nil
            }
        }
        guard let mode = mode else {
            return .failure(SPI.ParseError.invalidMode)
        }
        let flag = first.bits()
        return .success(SPIConfig(
            value: SPI.Config(
                isEnabled: flag[7] == 1,
                endian: endian,
                mode: mode
            )
        ))
    }
}
