//
//  HardwarePWMxConfig.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

public struct HardwarePWMxConfig: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 7
    }

    public let values: [PWM.Hardware.PinConfig]
    public let clockConfig: PWM.Hardware.ClockConfig

    public static func parse(data: Data) -> Result<HardwarePWMxConfig, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }

        var configs = [PWM.Hardware.PinConfig]()
        for (index, payload) in bytes[0 ..< 4].enumerated() {
            guard let pin = PWM.Pin(rawValue: UInt8(index)) else {
                return .failure(CharacteristicValueParseError.invalidPinNumber)
            }
            switch PWM.Hardware.PinConfig.parse([payload], info: [PWM.Hardware.PinConfig.InfoKey.pin.rawValue: pin]) {
            case let .success(config):
                configs.append(config)
            case let .failure(error):
                return .failure(error)
            }
        }

        let configBytes = [UInt8](bytes[4 ..< 7])
        let (clk, presc) = configBytes[0].split2()
        guard let clock = PWM.Hardware.Clock(rawValue: clk) else {
            return .failure(PWM.ParseError.invalidClock)
        }
        guard let prescaler = PWM.Hardware.Prescaler(rawValue: presc) else {
            return .failure(PWM.ParseError.invalidPrescaler)
        }

        return .success(
            HardwarePWMxConfig(
                values: configs,
                clockConfig: PWM.Hardware.ClockConfig(
                    clock: clock,
                    prescaler: prescaler,
                    timerValue: UInt16.compose(fsb: configBytes[1], lsb: configBytes[2])
                )
            )
        )
    }
}
