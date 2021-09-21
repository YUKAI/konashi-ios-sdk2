//
//  ConfigService.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import CoreBluetooth
import Foundation

public struct ConfigService: Service {
    public static var uuid: UUID {
        return UUID(uuidString: "064d0200-8251-49d9-b6f3-f7ba35e5d0a1")!
    }

    public var characteristics: [Characteristic] {
        return [
            configCommand,
            gpioConfig,
            softwarePWMConfig,
            hardwarePWMConfig,
            analogConfig,
            i2cConfig,
            uartConfig,
            spiConfig
        ]
    }

    public var notifiableCharacteristics: [Characteristic] {
        return [
            gpioConfig,
            softwarePWMConfig,
            hardwarePWMConfig,
            analogConfig,
            i2cConfig,
            uartConfig,
            spiConfig
        ]
    }

    public let configCommand = WriteableCharacteristic<ConfigCommand>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0201-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let gpioConfig = ReadableCharacteristic<GPIOxConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0202-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let softwarePWMConfig = ReadableCharacteristic<SoftwarePWMxConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0203-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let hardwarePWMConfig = ReadableCharacteristic<HardwarePWMxConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0204-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let analogConfig = ReadableCharacteristic<AnalogxConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0205-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let i2cConfig = ReadableCharacteristic<AnalogxConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0206-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let uartConfig = ReadableCharacteristic<UARTConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0207-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let spiConfig = ReadableCharacteristic<SPIConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0208-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )

    public enum ConfigCommand: Command {
        case gpio([GPIO.PinConfig])
        case softwarePWM([PWM.Software.PinConfig])
        case hardwarePWM(config: PWM.Hardware.ConfigPayload)
        case analog(config: Analog.ConfigPayload)
        case i2c(config: I2C.Config)
        case uart(config: UART.Config)
        case spi(config: SPI.Config)

        func commandIdentifier() -> UInt8 {
            switch self {
            case .gpio:
                return 0x01
            case .softwarePWM:
                return 0x02
            case .hardwarePWM:
                return 0x03
            case .analog:
                return 0x04
            case .i2c:
                return 0x05
            case .uart:
                return 0x06
            case .spi:
                return 0x07
            }
        }

        public func compose() -> Data {
            var bytes = [UInt8]()
            bytes.append(commandIdentifier())
            var payload: [UInt8] {
                switch self {
                case let .gpio(config):
                    return config.compose()
                case let .softwarePWM(config):
                    return config.compose()
                case let .hardwarePWM(config):
                    return config.compose()
                case let .analog(config):
                    return config.compose()
                case let .i2c(config):
                    return config.compose()
                case let .uart(config):
                    return config.compose()
                case let .spi(config):
                    return config.compose()
                }
            }
            bytes.append(contentsOf: payload)
            return Data(bytes)
        }
    }
}

public extension ConfigService {
    static let configCommand = WriteableCharacteristic<ConfigCommand>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0201-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let gpioConfig = ReadableCharacteristic<GPIOxConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0202-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let softwarePWMConfig = ReadableCharacteristic<SoftwarePWMxConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0203-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let hardwarePWMConfig = ReadableCharacteristic<HardwarePWMxConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0204-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let analogConfig = ReadableCharacteristic<AnalogxConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0205-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let i2cConfig = ReadableCharacteristic<AnalogxConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0206-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let uartConfig = ReadableCharacteristic<UARTConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0207-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let spiConfig = ReadableCharacteristic<SPIConfig>(
        serviceUUID: ConfigService.uuid,
        uuid: UUID(
            uuidString: "064D0208-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
}
