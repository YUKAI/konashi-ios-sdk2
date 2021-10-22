//
//  Service.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import CoreBluetooth
import Foundation

public struct SettingsService: Service {
    /// Service UUID of settings service.
    public static var uuid: UUID {
        return UUID(uuidString: "064d0100-8251-49d9-b6f3-f7ba35e5d0a1")!
    }

    /// An array of all characteristics of settings service.
    public var characteristics: [Characteristic] {
        return [
            settingsCommand,
            systemSettings,
            bluetoothSettings
        ]
    }

    /// An array of characteristics that can notify update.
    public var notifiableCharacteristics: [Characteristic] {
        return [
            systemSettings,
            bluetoothSettings
        ]
    }

    let settingsCommand = WriteableCharacteristic<SettingCommand>(
        serviceUUID: SettingsService.uuid,
        uuid: UUID(
            uuidString: "064D0101-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    let systemSettings = ReadableCharacteristic<SystemSettings>(
        serviceUUID: SettingsService.uuid,
        uuid: UUID(
            uuidString: "064D0102-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    let bluetoothSettings = ReadableCharacteristic<BluetoothSettings>(
        serviceUUID: SettingsService.uuid,
        uuid: UUID(
            uuidString: "064D0103-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )

    public enum SystemSettingPayload: Payload {
        case nvmUseSet(enabled: Bool)
        case nvmSaveTriggerSet(trigger: NVMSaveTrigger)
        case nvmSaveNow
        case nvmEraseNow
        case emulateFunctionButtonPress
        case emulateFunctionButtonLongPress
        case emulatefunctionButtonVeryLongPress

        func compose() -> [UInt8] {
            switch self {
            case let .nvmUseSet(enabled):
                if enabled {
                    return [0x01]
                }
                return [0x0]
            case let .nvmSaveTriggerSet(trigger):
                if trigger == .automatic {
                    return [0x0]
                }
                return [0x01]
            case .nvmSaveNow:
                return [0x03]
            case .nvmEraseNow:
                return [0x04]
            case .emulateFunctionButtonPress:
                return [0x05]
            case .emulateFunctionButtonLongPress:
                return [0x06]
            case .emulatefunctionButtonVeryLongPress:
                return [0x07]
            }
        }
    }

    public struct BluetoothSettingPayload: Payload {
        public struct GPIOxInputValue: OptionSet, CaseIterable {
            public static var allCases: [GPIOxInputValue] = [
                .gpio0,
                .gpio1,
                .gpio2,
                .gpio3,
                .gpio4,
                .gpio5,
                .gpio6,
                .gpio7
            ]

            public static var gpio0 = GPIOxInputValue(rawValue: 0b00000001)
            public static var gpio1 = GPIOxInputValue(rawValue: 0b00000010)
            public static var gpio2 = GPIOxInputValue(rawValue: 0b00000100)
            public static var gpio3 = GPIOxInputValue(rawValue: 0b00001000)
            public static var gpio4 = GPIOxInputValue(rawValue: 0b00010000)
            public static var gpio5 = GPIOxInputValue(rawValue: 0b00100000)
            public static var gpio6 = GPIOxInputValue(rawValue: 0b01000000)
            public static var gpio7 = GPIOxInputValue(rawValue: 0b10000000)

            public let rawValue: UInt8

            public init(rawValue: UInt8) {
                self.rawValue = rawValue
            }

            static func convert(_ values: [Bool]) -> GPIOxInputValue {
                var mask = GPIOxInputValue()
                for (index, enabled) in values.enumerated() where enabled == true {
                    mask = mask.union(allCases[index])
                }
                return mask
            }
        }

        public struct AIOxInputValue: OptionSet, CaseIterable {
            public static var allCases: [AIOxInputValue] = [
                .apio0,
                .apio1,
                .apio2
            ]

            public static var apio0 = AIOxInputValue(rawValue: 0b00010000)
            public static var apio1 = AIOxInputValue(rawValue: 0b00100000)
            public static var apio2 = AIOxInputValue(rawValue: 0b01000000)

            public let rawValue: UInt8

            public init(rawValue: UInt8) {
                self.rawValue = rawValue
            }

            static func convert(_ values: [Bool]) -> AIOxInputValue {
                var mask = AIOxInputValue()
                for (index, enabled) in values.enumerated() where enabled == true {
                    mask = mask.union(allCases[index])
                }
                return mask
            }
        }

        public struct AdvertiserContents {
            public let manufacturerData: Bool
            public let deviceUUID: Bool
            public let deviceName: Bool
            public let gpioxInputValue: GPIOxInputValue
            public let aioxInputValue: AIOxInputValue
        }

        public struct BluetoothFunction {
            public enum Function {
                case mesh
                case exAdvertiser
            }

            var function: Function
            var enabled: Bool
        }

        var bluetoothFunction: BluetoothFunction?
        var mainAdvertiserSecondaryPHY: PHY?
        var mainAdvertiserPreferredConnectionPHY: PHYsBitmask?
        var extraAdvertiserPrimaryPHY: PHY?
        var extraAdvertiserSecondaryPHY: PHY?
        var extraAdvertiserContents: AdvertiserContents?

        func compose() -> [UInt8] {
            var bytes = [UInt8]()
            if let bluetoothFunction = bluetoothFunction {
                var byte: UInt8 = 0b00000000
                if bluetoothFunction.function == .mesh {
                    byte |= 0b00000001
                }
                if bluetoothFunction.enabled {
                    byte |= 0b01000000
                }
                bytes.append(byte)
            }
            if let phy = mainAdvertiserSecondaryPHY {
                var byte: UInt8 = 0b11110000
                byte |= phy.rawValue
                bytes.append(byte)
            }
            if let phyBitMask = mainAdvertiserPreferredConnectionPHY {
                var byte: UInt8 = 0b11100000
                byte |= phyBitMask.rawValue
                bytes.append(byte)
            }
            if let phy = extraAdvertiserPrimaryPHY {
                var byte: UInt8 = 0b11010000
                byte |= phy.rawValue
                bytes.append(byte)
            }
            if let phy = extraAdvertiserSecondaryPHY {
                var byte: UInt8 = 0b11000000
                byte |= phy.rawValue
                bytes.append(byte)
            }
            if let contents = extraAdvertiserContents {
                var byte: UInt8 = 0b10110000
                if contents.manufacturerData {
                    byte |= 0b00000100
                }
                if contents.deviceUUID {
                    byte |= 0b00000010
                }
                if contents.deviceName {
                    byte |= 0b00000001
                }

                bytes.append(contentsOf: [
                    byte,
                    contents.gpioxInputValue.rawValue,
                    contents.aioxInputValue.rawValue,
                    0x00
                ])
            }
            return bytes
        }
    }

    public enum SettingCommand: Command {
        case system(payload: SystemSettingPayload)
        case bluetooth(payload: BluetoothSettingPayload)

        public func compose() -> Data {
            var bytes = [UInt8]()
            switch self {
            case let .system(payload):
                bytes.append(0x01)
                for data in payload.compose() {
                    bytes.append(data)
                }
            case let .bluetooth(payload):
                bytes.append(0x02)
                for data in payload.compose() {
                    bytes.append(data)
                }
            }

            return Data(bytes)
        }
    }
}

public extension SettingsService {
    static let settingsCommand = WriteableCharacteristic<SettingCommand>(
        serviceUUID: SettingsService.uuid,
        uuid: UUID(
            uuidString: "064D0101-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let systemSettings = ReadableCharacteristic<SystemSettings>(
        serviceUUID: SettingsService.uuid,
        uuid: UUID(
            uuidString: "064D0102-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let bluetoothSettings = ReadableCharacteristic<BluetoothSettings>(
        serviceUUID: SettingsService.uuid,
        uuid: UUID(
            uuidString: "064D0103-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
}
