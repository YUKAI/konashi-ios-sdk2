//
//  Service.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import CoreBluetooth
import Foundation

/// A BLE service of Konashi settings.
public struct SettingsService: Service {
    /// Service UUID of settings service.
    public static var uuid: UUID {
        return UUID(uuidString: "064d0100-8251-49d9-b6f3-f7ba35e5d0a1")!
    }

    /// An array of all characteristics of setting services.
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

    /// A payload for system setting.
    public enum SystemSettingPayload: Payload {
        /// A payload to set if NVM is used or not.
        case nvmUseSet(enabled: Bool)
        /// A payload to set the NVM save trigger.
        case nvmSaveTriggerSet(trigger: NVMSaveTrigger)
        /// A payload to save all to NVM immediately.
        case nvmSaveNow
        /// A payload to erase all from NVM immediately.
        case nvmEraseNow
        /// A payload to emulate a function button simple press.
        case emulateFunctionButtonPress
        /// A payload to emulate a function button long press.
        case emulateFunctionButtonLongPress
        /// A payload to emulate a function button very long press.
        case emulatefunctionButtonVeryLongPress

        func compose() -> [UInt8] {
            switch self {
            case let .nvmUseSet(enabled):
                if enabled {
                    return [0x01, 0x01]
                }
                return [0x01, 0x0]
            case let .nvmSaveTriggerSet(trigger):
                if trigger == .automatic {
                    return [0x02, 0x0]
                }
                return [0x02, 0x01]
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

    /// A payload for bluetooth setting.
    public struct BluetoothSettingPayload: Payload {
        /// A setting of input value from GPIO.
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

            /// A bit representation of GPIO0.
            public static var gpio0 = GPIOxInputValue(rawValue: 0b00000001)
            /// A bit representation of GPIO1.
            public static var gpio1 = GPIOxInputValue(rawValue: 0b00000010)
            /// A bit representation of GPIO2.
            public static var gpio2 = GPIOxInputValue(rawValue: 0b00000100)
            /// A bit representation of GPIO3.
            public static var gpio3 = GPIOxInputValue(rawValue: 0b00001000)
            /// A bit representation of GPIO4.
            public static var gpio4 = GPIOxInputValue(rawValue: 0b00010000)
            /// A bit representation of GPIO5.
            public static var gpio5 = GPIOxInputValue(rawValue: 0b00100000)
            /// A bit representation of GPIO6.
            public static var gpio6 = GPIOxInputValue(rawValue: 0b01000000)
            /// A bit representation of GPIO7.
            public static var gpio7 = GPIOxInputValue(rawValue: 0b10000000)
            /// A bit representation of all GPIOs.
            public static var gpioAll = GPIOxInputValue(rawValue: 0xff)

            /// A bit representation of GPIOs.
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

        /// A setting of input value from AIO.
        public struct AIOxInputValue: OptionSet, CaseIterable {
            public static var allCases: [AIOxInputValue] = [
                .aio0,
                .aio1,
                .aio2
            ]

            /// A bit representation of AIO0.
            public static var aio0 = AIOxInputValue(rawValue: 0b00010000)
            /// A bit representation of AIO1.
            public static var aio1 = AIOxInputValue(rawValue: 0b00100000)
            /// A bit representation of AIO2.
            public static var aio2 = AIOxInputValue(rawValue: 0b01000000)
            /// A bit representation of all GPIOs.
            public static var aioAll = GPIOxInputValue(rawValue: 0x70)

            /// A bit representation of AIOs.
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

        /// A representation of advertiser contents.
        public struct AdvertiserContents {
            public let manufacturerData: Bool
            public let deviceUUID: Bool
            public let deviceName: Bool
            public let gpioxInputValue: GPIOxInputValue
            public let aioxInputValue: AIOxInputValue
        }

        /// A representation of bluetooth function setting.
        public struct BluetoothFunction {
            /// Functions of Bluetooth
            public enum Function {
                case mesh
                case exAdvertiser
            }

            /// The function to enable or disable.
            var function: Function
            /// Enable or disable a Bluetooth functionality.
            var enabled: Bool
        }

        /// Enable or disable a Bluetooth functionality.
        var bluetoothFunction: BluetoothFunction?
        /// The main advertiser Secondary PHY.
        var mainAdvertiserSecondaryPHY: PHY?
        /// The main preferred connection PHYs. Multiple preferred PHYs can be set in the form of a bitmask.
        var mainAdvertiserPreferredConnectionPHY: PHYsBitmask?
        /// The secondary advertiser primary PHYs.
        var extraAdvertiserPrimaryPHY: PHY?
        /// The secondary advertiser secondary PHYs.
        var extraAdvertiserSecondaryPHY: PHY?
        /// The secondary advertiser advertising contents.
        /// If the resulting advertising data length is longer than 31 bytes, advertising will automatically be in extended mode, otherwise it will be legacy mode.
        var extraAdvertiserContents: AdvertiserContents?

        func compose() -> [UInt8] {
            var bytes = [UInt8]()
            if let bluetoothFunction = bluetoothFunction {
                var byte: UInt8 = 0b00000000
                if bluetoothFunction.function == .exAdvertiser {
                    byte |= 0b00010000
                }
                if bluetoothFunction.enabled {
                    byte |= 0b00000001
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
        /// A command to change system setting.
        case system(payload: SystemSettingPayload)
        /// A command to change bluetooth setting.
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
