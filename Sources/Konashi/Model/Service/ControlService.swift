//
//  ControlService.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import CoreBluetooth
import Foundation

/// A BLE service to control Konashi.
public struct ControlService: Service {
    /// Service UUID of control service.
    public static var uuid: UUID {
        return UUID(uuidString: "064D0300-8251-49D9-B6F3-F7BA35E5D0A1")!
    }

    /// An array of all characteristics of control service.
    public var characteristics: [Characteristic] {
        return [
            controlCommand,
            gpioOutput,
            gpioInput,
            softwarePWMOutput,
            hardwarePWMOutput,
            analogOutput,
            analogInput,
            i2cDataInput,
            uartDataInput,
            uartSendDone,
            spiDataInput
        ]
    }

    /// An array of characteristics that can notify update.
    public var notifiableCharacteristics: [Characteristic] {
        return [
            gpioInput,
            gpioOutput,
            softwarePWMOutput,
            hardwarePWMOutput,
            analogInput,
            analogOutput,
            i2cDataInput,
            uartSendDone,
            uartDataInput,
            spiDataInput
        ]
    }

    public let controlCommand = WriteableCharacteristic<ControlCommand>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0301-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let gpioOutput = ReadableCharacteristic<GPIOxValue>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0302-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let gpioInput = ReadableCharacteristic<GPIOxValue>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0303-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let softwarePWMOutput = ReadableCharacteristic<SoftwarePWMxOutput>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0304-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let hardwarePWMOutput = ReadableCharacteristic<HardwarePWMxOutput>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0305-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let analogOutput = ReadableCharacteristic<AnalogxOutputValue>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0306-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let analogInput = ReadableCharacteristic<AnalogxInputValue>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0307-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let i2cDataInput = NotifiableCharacteristic<I2C.Value>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0308-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let uartDataInput = NotifiableCharacteristic<UARTInputValue>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0309-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let uartSendDone = NotifiableCharacteristic<UARTDataSendResult>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D030A-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    public let spiDataInput = NotifiableCharacteristic<SPIInputValue>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D030B-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )

    public enum ControlCommand: Command {
        case gpio([GPIO.ControlPayload])
        case softwarePWM([PWM.Software.ControlPayload])
        case hardwarePWM([PWM.Hardware.ControlPayload])
        case analog([Analog.ControlPayload])
        case i2cTransfer(I2C.TransferControlPayload)
        case uartSend(UART.SendControlPayload)
        case spiTransfer(SPI.TransferControlPayload)

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
            case .i2cTransfer:
                return 0x05
            case .uartSend:
                return 0x06
            case .spiTransfer:
                return 0x07
            }
        }

        public func compose() -> Data {
            var bytes = [UInt8]()
            bytes.append(commandIdentifier())
            var payload: [UInt8] {
                switch self {
                case let .gpio(payload):
                    return payload.compose()
                case let .softwarePWM(payload):
                    return payload.compose()
                case let .hardwarePWM(payload):
                    return payload.compose()
                case let .analog(payload):
                    return payload.compose()
                case let .i2cTransfer(payload):
                    return payload.compose()
                case let .uartSend(payload):
                    return payload.compose()
                case let .spiTransfer(payload):
                    return payload.compose()
                }
            }
            bytes.append(contentsOf: payload)
            return Data(bytes)
        }
    }
}

public extension ControlService {
    static let controlCommand = WriteableCharacteristic<ControlCommand>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0301-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let gpioOutput = ReadableCharacteristic<GPIOxValue>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0302-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let gpioInput = ReadableCharacteristic<GPIOxValue>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0303-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let softwarePWMOutput = ReadableCharacteristic<SoftwarePWMxOutput>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0304-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let hardwarePWMOutput = ReadableCharacteristic<HardwarePWMxOutput>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0305-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let analogOutput = ReadableCharacteristic<AnalogxOutputValue>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0306-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let analogInput = ReadableCharacteristic<AnalogxInputValue>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0307-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let i2cDataInput = NotifiableCharacteristic<I2C.Value>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0308-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let uartDataInput = NotifiableCharacteristic<UARTInputValue>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D0309-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let uartSendDone = NotifiableCharacteristic<UARTDataSendResult>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D030A-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
    static let spiDataInput = NotifiableCharacteristic<SPIInputValue>(
        serviceUUID: ControlService.uuid,
        uuid: UUID(
            uuidString: "064D030B-8251-49D9-B6F3-F7BA35E5D0A1"
        )!
    )
}
