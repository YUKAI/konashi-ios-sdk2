//
//  SystemSettings.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/10.
//

import Foundation

public struct SystemSettings: CharacteristicValue {
    public static var byteSize: UInt {
        return 2
    }

    public let isNVMUsed: Bool
    public let nvmSaveTrigger: NVMSaveTrigger

    public static func parse(data: Data) -> Result<SystemSettings, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        var trigger: NVMSaveTrigger {
            if bytes[1] == 0 {
                return .automatic
            }
            return .manual
        }

        return .success(SystemSettings(
            isNVMUsed: bytes[0] == 1,
            nvmSaveTrigger: trigger
        ))
    }
}
