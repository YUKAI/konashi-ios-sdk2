//
//  BluetoothSettings.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/10.
//

import Foundation

/// A representation of bluetooth setting characteristic.
public struct BluetoothSettings: CharacteristicValue {
    public enum ParseError: LocalizedError {
        case invalidAdvertiserStatus
    }

    public static var byteSize: UInt {
        return 7
    }

    public enum AdvertiserStatus: UInt8, CustomStringConvertible {
        public var description: String {
            switch self {
            case .disabled:
                return "disabled"
            case .legacyAdvertising:
                return "Legacy advertising"
            case .extendedAdvertising:
                return "Extended advertising"
            case .error:
                return "error"
            }
        }

        case disabled = 0x0
        case legacyAdvertising = 0x01
        case extendedAdvertising = 0x02
        case error = 0x0F
    }

    public let isExadvEnabled: Bool
    public let isMeshEnabled: Bool
    public let secondaryPHY: PHY
    public let preferredConnectionPHYs: PHYsBitmask
    public let exadvPrimaryPHY: PHY
    public let exadvSecondaryPHY: PHY
    public let advertiserStatus: AdvertiserStatus
    public let isManufacturerDataEnabled: Bool
    public let isDeviceUUIDEnabled: Bool
    public let isDeviceNameEnabled: Bool
    public let isGPIOxInputValueEnabled: [Bool]
    public let isAIOxInputValueEnabled: [Bool]

    public static func parse(data: Data) -> Result<BluetoothSettings, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) == false {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        let mainAdv = bytes[1].konashi_split2()
        guard let secondaryPHY = PHY(rawValue: mainAdv.lsfb) else {
            return .failure(CharacteristicValueParseError.invalidPHY)
        }
        let preferredConnectionPHYs = PHYsBitmask.convert(mainAdv.msfb)

        let exAdv = bytes[2].konashi_split2()
        guard let exadvPrimaryPHY = PHY(rawValue: exAdv.lsfb) else {
            return .failure(CharacteristicValueParseError.invalidPHY)
        }
        guard let exadvSecondaryPHY = PHY(rawValue: exAdv.msfb) else {
            return .failure(CharacteristicValueParseError.invalidPHY)
        }

        let exAdvertiserContents = bytes[3].konashi_split2()
        guard let advertiserStatus = AdvertiserStatus(rawValue: exAdvertiserContents.msfb) else {
            return .failure(BluetoothSettings.ParseError.invalidAdvertiserStatus)
        }
        let flags = exAdvertiserContents.lsfb.konashi_bits()

        let gpioValues = bytes[4].konashi_bits()
        let aioValues = bytes[5].konashi_split2().msfb.konashi_bits()[...min(Analog.Pin.allCases.count, 7)]
        return .success(BluetoothSettings(
            isExadvEnabled: (bytes[0] & 0x02) != 0,
            isMeshEnabled: (bytes[0] & 0x01) != 0,
            secondaryPHY: secondaryPHY,
            preferredConnectionPHYs: preferredConnectionPHYs,
            exadvPrimaryPHY: exadvPrimaryPHY,
            exadvSecondaryPHY: exadvSecondaryPHY,
            advertiserStatus: advertiserStatus,
            isManufacturerDataEnabled: flags[2] == 1,
            isDeviceUUIDEnabled: flags[1] == 1,
            isDeviceNameEnabled: flags[0] == 1,
            isGPIOxInputValueEnabled: gpioValues.map {
                return $0 > 0
            },
            isAIOxInputValueEnabled: aioValues.dropLast(1).map {
                return $0 > 0
            }
        ))
    }
}
