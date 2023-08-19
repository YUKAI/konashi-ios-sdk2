//
//  KonashiPeripheral+Arduino.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/17.
//

import Combine
import Foundation

public extension KonashiPeripheral {
    enum PinMode {
        case input
        case output
        case inputPullUp
    }

    /// Configures the specified pin to behave either as an input or an output.
    /// - Parameters:
    ///   - pin: A GPIO to change pin mode.
    ///   - mode: A pin mode of GPIO.
    ///   - wiredFunction: A wired function mode of GPIO.
    func pinMode(_ pin: GPIO.Pin, mode: PinMode, wiredFunction: GPIO.WiredFunction = .disabled) async throws {
        var direction: Direction {
            switch mode {
            case .input, .inputPullUp:
                return .input
            case .output:
                return .output
            }
        }
        var notifyOnInputChange: Bool {
            if mode == .input || mode == .inputPullUp {
                return true
            }
            return false
        }
        var state: GPIO.RegisterState {
            if mode == .inputPullUp {
                return .pullUp
            }
            return .none
        }
        try await write(
            characteristic: ConfigService.configCommand,
            command: .gpio([
                GPIO.PinConfig(
                    pin: pin,
                    mode: .compose(enabled: true, direction: direction, wiredFunction: wiredFunction),
                    registerState: state,
                    notifyOnInputChange: notifyOnInputChange,
                    function: .gpio
                )
            ])
        )
    }

    /// Reads the value from a specified GPIO.
    /// - Parameter pin: A GPIO to read value.
    /// - Returns: An input value of GPIO.
    func digitalRead(_ pin: GPIO.Pin) async throws -> Level {
        let readValue = try await read(characteristic: ControlService.gpioInput)
        let value = readValue.values.first { val in
            return val.pin == pin
        }
        guard let value else {
            throw PeripheralOperationError.couldNotReadValue
        }
        if value.isValid == false {
            throw PeripheralOperationError.invalidReadValue
        }
        return value.level
    }

    /// Writes a level value to a GPIO.
    /// - Parameters:
    ///   - pin: A GPIO to write value.
    ///   - level: A value of level.
    func digitalWrite(_ pin: GPIO.Pin, value: Level) async throws {
        try await write(
            characteristic: ControlService.controlCommand,
            command: .gpio(
                [GPIO.ControlPayload(pin: pin, level: value)]
            )
        )
    }

    /// Configures AIO.
    /// - Parameters:
    ///   - pin: An AIO to configure.
    ///   - config: A configuration of AIO.
    func analogBegin(pin: Analog.Pin, config: Analog.ConfigPayload) async throws {
        try await write(
            characteristic: ConfigService.configCommand,
            command: .analog(config: config)
        )
    }

    /// Reads value of AIO.
    /// - Parameters:
    ///   - pin: An AIO to read value.
    ///   - config: A configuration of AIO.
    /// - Returns: An input value of AIO
    func analogRead(_ pin: Analog.Pin) async throws -> Analog.InputValue {
        let readValue = try await read(characteristic: ControlService.analogInput)
        let value = readValue.values.first { val in
            return val.pin == pin
        }
        guard let value else {
            throw PeripheralOperationError.couldNotReadValue
        }
        if value.isValid == false {
            throw PeripheralOperationError.invalidReadValue
        }
        return value
    }

    /// Writes value of AIO.
    /// - Parameters:
    ///   - pin: An AIO to read value.
    ///   - value: A value that is written.
    ///   - transitionDuration: A duration for transitioning current value to specified value.
    func analogWrite(_ pin: Analog.Pin, value: UInt16, transitionDuration: UInt32 = 0) async throws {
        try await write(
            characteristic: ControlService.controlCommand,
            command: .analog(
                [Analog.ControlPayload(
                    pin: pin,
                    stepValue: value,
                    transitionDurationMillisec: transitionDuration
                )]
            )
        )
    }

    /// Configures software PWM.
    /// - Parameters:
    ///   - pin: A software PWM to configure.
    ///   - config: A configuration of software PWM.
    func softwarePWMMode(pin: PWM.Pin, config: PWM.Software.DriveConfig) async throws {
        try await write(
            characteristic: ConfigService.configCommand,
            command: .softwarePWM(
                [PWM.Software.PinConfig(
                    pin: pin,
                    driveConfig: config
                )]
            )
        )
    }

    /// Drives software PWM.
    /// - Parameters:
    ///   - pin: A software PWM to drive.
    ///   - value: A value of software PWM.
    ///   - transitionDuration: A duration for transitioning current value to specified value.
    func softwarePWMDrive(pin: PWM.Pin, value: PWM.Software.ControlValue, transitionDuration: UInt32 = 0) async throws {
        try await write(
            characteristic: ControlService.controlCommand,
            command: .softwarePWM(
                [PWM.Software.ControlPayload(
                    pin: pin,
                    value: value,
                    transitionDuration: transitionDuration
                )]
            )
        )
    }

    /// Configure hardware PWM.
    /// - Parameters:
    ///   - pin: A hardware PWM to configure.
    ///   - clock: The clock source for the PWM timer
    ///   - prescaler: The clock prescaler for the PWM timer
    ///   - value: A value of hardware PWM.
    func hardwarePWMMode(pin: PWM.Pin, clock: PWM.Hardware.Clock, prescaler: PWM.Hardware.Prescaler, value: UInt16) async throws {
        try await write(
            characteristic: ConfigService.configCommand,
            command: .hardwarePWM(
                config: PWM.Hardware.ConfigPayload(
                    pinConfig: [PWM.Hardware.PinConfig(
                        pin: pin,
                        isEnabled: true
                    )],
                    clockConfig: PWM.Hardware.ClockConfig(
                        clock: clock,
                        prescaler: prescaler,
                        timerValue: value
                    )
                )
            )
        )
    }

    /// Drives hardware PWM.
    /// - Parameters:
    ///   - pin: A hardware PWM to drive.
    ///   - value: A value of hardware PWM.
    ///   - transitionDuration: A duration for transitioning current value to specified value.
    func hardwarePWMDrive(pin: PWM.Pin, value: UInt16, transitionDuration: UInt32 = 0) async throws {
        try await write(
            characteristic: ControlService.controlCommand,
            command: .hardwarePWM(
                [PWM.Hardware.ControlPayload(
                    pin: pin,
                    controlValue: value,
                    transitionDurationMillisec: transitionDuration
                )]
            )
        )
    }

    /// Attempt to configure UART.
    /// - Parameters:
    ///   - baudrate: The UART baudrate.
    ///   - parity: The UART parity.
    ///   - stopBit: The UART number of stop bits.
    func serialBegin(baudrate: UInt32, parity: UART.Parity = .none, stopBit: UART.StopBit = ._0_5) async throws {
        try await write(
            characteristic: ConfigService.configCommand,
            command: .uart(
                config: UART.Config.enable(
                    parity: parity,
                    stopBit: stopBit,
                    baudrate: baudrate
                )
            )
        )
    }

    /// Attempt to send UART data.
    /// - Parameters:
    ///   - data: The data to send (length range is [1,127]).
    func serialWrite(data: [UInt8]) async throws {
        try await write(
            characteristic: ControlService.controlCommand,
            command: .uartSend(
                UART.SendControlPayload(data: data)
            )
        )
    }

    /// Attempt to configure SPI mode.
    /// - Parameters:
    ///   - bitrate: SPI bitrate.
    ///   - endian: An endian of data.
    ///   - mode: SPI mode.
    func spiBegin(bitrate: UInt32, endian: SPI.Endian = .lsbFirst, mode: SPI.Mode = .mode0) async throws {
        try await write(
            characteristic: ConfigService.configCommand,
            command: .spi(
                config: SPI.Config.enable(
                    bitrate: bitrate,
                    endian: endian,
                    mode: mode
                )
            )
        )
    }

    /// Attempt to transfer data through SPI bus.
    /// - Parameter data: The data to send (length range is [1,127]).
    func spiTransfer(data: [UInt8]) async throws {
        try await write(
            characteristic: ControlService.controlCommand,
            command: .spiTransfer(
                SPI.TransferControlPayload(data: data)
            )
        )
    }

    /// Attempt to configure I2C mode.
    /// - Parameters:
    ///   - mode: I2C mode.
    func i2cBegin(_ mode: I2C.Mode) async throws {
        try await write(
            characteristic: ConfigService.configCommand,
            command: .i2c(
                config: I2C.Config.enable(mode: mode)
            )
        )
    }

    /// Attempt to write data to I2C slave.
    /// - Parameters:
    ///   - address: The I2C slave address (address range is 0x00 to 0x7F).
    ///   - writeData: The data to write (valid length 0 to 124 bytes).
    func i2cWrite(address: UInt8, writeData: [UInt8]) async throws {
        try await i2cTransfer(address: address, operation: .write, readLength: 0, writeData: writeData)
    }

    /// Attempt to read data from I2C slave.
    /// - Parameters:
    ///   - address: The I2C slave address (address range is 0x00 to 0x7F).
    ///   - readLength: The length of the data to read (0 to 126 bytes).
    /// - Returns: Byte arrey of read from I2C slave.
    func i2cRead(address: UInt8, readLength: UInt8) async throws -> [UInt8] {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                var cancellable = Set<AnyCancellable>()
                self.controlService.i2cDataInput.value.sink { readValue in
                    if readValue.address == address {
                        continuation.resume(with: .success(readValue.readBytes))
                    }
                }.store(in: &cancellable)
                do {
                    try await self.i2cTransfer(
                        address: address,
                        operation: .read,
                        readLength: readLength,
                        writeData: []
                    )
                } catch {
                    continuation.resume(with: .failure(error))
                }
            }
        }
    }

    /// Attempt to transfer data.
    /// - Parameters:
    ///   - address: The I2C slave address (address range is 0x00 to 0x7F).
    ///   - operation: The transaction operation.
    ///   - readLength: The length of the data to read (0 to 126 bytes).
    ///   - writeData: The data to write (valid length 0 to 124 bytes).
    func i2cTransfer(address: UInt8, operation: I2C.Operation, readLength: UInt8, writeData: [UInt8]) async throws {
        if address > 0x7F {
            throw I2C.OperationError.invalidSlaveAddress
        }
        if readLength > 126 {
            throw I2C.OperationError.badReadLength
        }
        if writeData.count > 124 {
            throw I2C.OperationError.badWriteLength
        }
        try await write(
            characteristic: ControlService.controlCommand,
            command: .i2cTransfer(
                I2C.TransferControlPayload(
                    operation: operation,
                    readLength: readLength,
                    address: address,
                    writeData: writeData
                )
            )
        )
    }
}
