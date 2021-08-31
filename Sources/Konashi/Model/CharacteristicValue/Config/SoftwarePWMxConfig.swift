//
//  SoftwarePWMxConfig.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

public struct SoftwarePWMxConfig: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 12
    }

    public let values: [PWM.Software.PinConfig]

    public static func parse(data: Data) -> Result<SoftwarePWMxConfig, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        let chunk = bytes.chunked(by: 3)
        var configs = [PWM.Software.PinConfig]()
        for (index, config) in chunk.enumerated() {
            guard let pin = PWM.Pin(rawValue: UInt8(index)) else {
                return .failure(CharacteristicValueParseError.invalidPinNumber)
            }
            let first = config[0]
            var driveConfig: PWM.Software.DriveConfig? {
                switch first {
                case 0x0:
                    return .disable
                case 0x01:
                    return .duty(
                        millisec: UInt16.compose(fsb: config[1], lsb: config[2])
                    )
                case 0x02:
                    return .period(
                        ratio: Float(UInt16.compose(fsb: config[1], lsb: config[2]) / 1000)
                    )
                default:
                    return nil
                }
            }
            guard let driveConfig = driveConfig else {
                return .failure(PWM.ParseError.invalidControlValue)
            }
            configs.append(
                PWM.Software.PinConfig(
                    pin: pin,
                    driveConfig: driveConfig
                )
            )
        }
        return .success(SoftwarePWMxConfig(values: configs))
    }
}
