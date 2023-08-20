//
//  Peripheral+Arduino.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/17.
//

import Combine
import Foundation

// MARK: - PinMode

public enum PinMode {
    case input
    case output
    case inputPullUp
}

public extension Peripheral {
    /// Configures the specified pin to behave either as an input or an output.
    /// - Parameters:
    ///   - pin: A GPIO to change pin mode.
    ///   - mode: A pin mode of GPIO.
    ///   - wiredFunction: A wired function mode of GPIO.
    ///   - timeoutInterval: Number of seconds before timeout.
    func pinMode(
        _ pin: GPIO.Pin,
        mode: PinMode,
        wiredFunction: GPIO.WiredFunction = .disabled,
        timeoutInterval: TimeInterval = 15
    ) async throws {
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
            ]), type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }

    /// Reads the value from a specified GPIO.
    /// - Parameters:
    ///   - pin: A GPIO to read value.
    ///   - timeoutInterval: Number of seconds before timeout.
    /// - Returns: An input value of GPIO.
    func digitalRead(
        _ pin: GPIO.Pin,
        timeoutInterval: TimeInterval = 15
    ) async throws -> Level {
        let readValue = try await read(
            characteristic: ControlService.gpioInput,
            timeoutInterval: timeoutInterval
        )
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
    ///   - timeoutInterval: Number of seconds before timeout.
    func digitalWrite(
        _ pin: GPIO.Pin,
        value: Level,
        timeoutInterval: TimeInterval = 15
    ) async throws {
        try await write(
            characteristic: ControlService.controlCommand,
            command: .gpio(
                [GPIO.ControlPayload(pin: pin, level: value)]
            ), type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }

    /// Configures AIO.
    /// - Parameters:
    ///   - pin: An AIO to configure.
    ///   - config: A configuration of AIO.
    ///   - timeoutInterval: Number of seconds before timeout.
    func analogBegin(
        pin: Analog.Pin,
        config: Analog.ConfigPayload,
        timeoutInterval: TimeInterval = 15
    ) async throws {
        try await write(
            characteristic: ConfigService.configCommand,
            command: .analog(config: config),
            type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }

    /// Reads value of AIO.
    /// - Parameters:
    ///   - pin: An AIO to read value.
    ///   - config: A configuration of AIO.
    ///   - timeoutInterval: Number of seconds before timeout.
    /// - Returns: An input value of AIO
    func analogRead(
        _ pin: Analog.Pin,
        timeoutInterval: TimeInterval = 15
    ) async throws -> Analog.InputValue {
        let readValue = try await read(
            characteristic: ControlService.analogInput,
            timeoutInterval: timeoutInterval
        )
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
    ///   - timeoutInterval: Number of seconds before timeout.
    func analogWrite(
        _ pin: Analog.Pin,
        value: UInt16,
        transitionDuration: UInt32 = 0,
        timeoutInterval: TimeInterval = 15
    ) async throws {
        try await write(
            characteristic: ControlService.controlCommand,
            command: .analog(
                [Analog.ControlPayload(
                    pin: pin,
                    stepValue: value,
                    transitionDurationMillisec: transitionDuration
                )]
            ),
            type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }

    /// Configures software PWM.
    /// - Parameters:
    ///   - pin: A software PWM to configure.
    ///   - config: A configuration of software PWM.
    ///   - timeoutInterval: Number of seconds before timeout.
    func softwarePWMMode(pin: PWM.Pin, config: PWM.Software.DriveConfig, timeoutInterval: TimeInterval = 15) async throws {
        try await write(
            characteristic: ConfigService.configCommand,
            command: .softwarePWM(
                [PWM.Software.PinConfig(
                    pin: pin,
                    driveConfig: config
                )]
            ),
            type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }

    /// Drives software PWM.
    /// - Parameters:
    ///   - pin: A software PWM to drive.
    ///   - value: A value of software PWM.
    ///   - transitionDuration: A duration for transitioning current value to specified value.
    ///   - timeoutInterval: Number of seconds before timeout.
    func softwarePWMDrive(
        pin: PWM.Pin,
        value: PWM.Software.ControlValue,
        transitionDuration: UInt32 = 0,
        timeoutInterval: TimeInterval = 15
    ) async throws {
        try await write(
            characteristic: ControlService.controlCommand,
            command: .softwarePWM(
                [PWM.Software.ControlPayload(
                    pin: pin,
                    value: value,
                    transitionDuration: transitionDuration
                )]
            ),
            type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }

    /// Configure hardware PWM.
    /// - Parameters:
    ///   - pin: A hardware PWM to configure.
    ///   - clock: The clock source for the PWM timer
    ///   - prescaler: The clock prescaler for the PWM timer
    ///   - value: A value of hardware PWM.
    ///   - timeoutInterval: Number of seconds before timeout.
    func hardwarePWMMode(
        pin: PWM.Pin,
        clock: PWM.Hardware.Clock,
        prescaler: PWM.Hardware.Prescaler,
        value: UInt16,
        timeoutInterval: TimeInterval = 15
    ) async throws {
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
            ),
            type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }

    /// Drives hardware PWM.
    /// - Parameters:
    ///   - pin: A hardware PWM to drive.
    ///   - value: A value of hardware PWM.
    ///   - transitionDuration: A duration for transitioning current value to specified value.
    ///   - timeoutInterval: Number of seconds before timeout.
    func hardwarePWMDrive(
        pin: PWM.Pin,
        value: UInt16,
        transitionDuration: UInt32 = 0,
        timeoutInterval: TimeInterval = 15
    ) async throws {
        try await write(
            characteristic: ControlService.controlCommand,
            command: .hardwarePWM(
                [PWM.Hardware.ControlPayload(
                    pin: pin,
                    controlValue: value,
                    transitionDurationMillisec: transitionDuration
                )]
            ),
            type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }

    /// Attempt to configure UART.
    /// - Parameters:
    ///   - baudrate: The UART baudrate.
    ///   - parity: The UART parity.
    ///   - stopBit: The UART number of stop bits.
    ///   - timeoutInterval: Number of seconds before timeout.
    func serialBegin(
        baudrate: UInt32,
        parity: UART.Parity = .none,
        stopBit: UART.StopBit = ._0_5,
        timeoutInterval: TimeInterval = 15
    ) async throws {
        try await write(
            characteristic: ConfigService.configCommand,
            command: .uart(
                config: UART.Config.enable(
                    parity: parity,
                    stopBit: stopBit,
                    baudrate: baudrate
                )
            ),
            type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }

    /// Attempt to send UART data.
    /// - Parameters:
    ///   - data: The data to send (length range is [1,127]).
    ///   - timeoutInterval: Number of seconds before timeout.
    func serialWrite(data: [UInt8], timeoutInterval: TimeInterval = 15) async throws {
        try await write(
            characteristic: ControlService.controlCommand,
            command: .uartSend(
                UART.SendControlPayload(data: data)
            ),
            type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }

    /// Attempt to configure SPI mode.
    /// - Parameters:
    ///   - bitrate: SPI bitrate.
    ///   - endian: An endian of data.
    ///   - mode: SPI mode.
    ///   - timeoutInterval: Number of seconds before timeout.
    func spiBegin(
        bitrate: UInt32,
        endian: SPI.Endian = .lsbFirst,
        mode: SPI.Mode = .mode0,
        timeoutInterval: TimeInterval = 15
    ) async throws {
        try await write(
            characteristic: ConfigService.configCommand,
            command: .spi(
                config: SPI.Config.enable(
                    bitrate: bitrate,
                    endian: endian,
                    mode: mode
                )
            ),
            type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }

    /// Attempt to transfer data through SPI bus.
    /// - Parameter data: The data to send (length range is [1,127]).
    func spiTransfer(data: [UInt8], timeoutInterval: TimeInterval = 15) async throws {
        try await write(
            characteristic: ControlService.controlCommand,
            command: .spiTransfer(
                SPI.TransferControlPayload(data: data)
            ),
            type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }

    /// Attempt to configure I2C mode.
    /// - Parameters:
    ///   - mode: I2C mode.
    ///   - timeoutInterval: Number of seconds before timeout.
    func i2cBegin(_ mode: I2C.Mode, timeoutInterval: TimeInterval = 15) async throws {
        try await write(
            characteristic: ConfigService.configCommand,
            command: .i2c(
                config: I2C.Config.enable(mode: mode)
            ),
            type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }

    /// Attempt to write data to I2C slave.
    /// - Parameters:
    ///   - address: The I2C slave address (address range is 0x00 to 0x7F).
    ///   - writeData: The data to write (valid length 0 to 124 bytes).
    ///   - timeoutInterval: Number of seconds before timeout.
    func i2cWrite(address: UInt8, writeData: [UInt8], timeoutInterval: TimeInterval = 15) async throws {
        try await i2cTransfer(
            address: address,
            operation: .write,
            readLength: 0,
            writeData: writeData,
            timeoutInterval: timeoutInterval
        )
    }

    /// Attempt to read data from I2C slave.
    /// - Parameters:
    ///   - address: The I2C slave address (address range is 0x00 to 0x7F).
    ///   - readLength: The length of the data to read (0 to 126 bytes).
    ///   - timeoutInterval: Number of seconds before timeout.
    /// - Returns: Byte arrey of read from I2C slave.
    func i2cRead(address: UInt8, readLength: UInt8, timeoutInterval: TimeInterval = 15) async throws -> [UInt8] {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                // TODO: Remove workaround
                guard let peripheral = self as? KonashiPeripheral else {
                    continuation.resume(returning: [])
                    return
                }
                var cancellable = Set<AnyCancellable>()
                peripheral.controlService.i2cDataInput.value.sink { readValue in
                    if readValue.address == address {
                        continuation.resume(with: .success(readValue.readBytes))
                    }
                }.store(in: &cancellable)
                do {
                    try await self.i2cTransfer(
                        address: address,
                        operation: .read,
                        readLength: readLength,
                        writeData: [],
                        timeoutInterval: timeoutInterval
                    )
                }
                catch {
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
    ///   - timeoutInterval: Number of seconds before timeout.
    func i2cTransfer(address: UInt8, operation: I2C.Operation, readLength: UInt8, writeData: [UInt8], timeoutInterval: TimeInterval = 15) async throws {
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
            ), type: .withResponse,
            timeoutInterval: timeoutInterval
        )
    }
}
