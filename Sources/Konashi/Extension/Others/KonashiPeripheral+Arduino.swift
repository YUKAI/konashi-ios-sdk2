//
//  KonashiPeripheral+Arduino.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/17.
//

import Combine
import Foundation
import Promises

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
    /// - Returns: A peripheral this method call.
    @discardableResult
    func pinMode(_ pin: GPIO.Pin, mode: PinMode, wiredFunction: GPIO.WiredFunction = .disabled) -> Promise<any Peripheral> {
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
        return write(
            characteristic: ConfigService.configCommand,
            command: .gpio([
                GPIO.PinConfig(
                    pin: pin,
                    mode: .compose(enabled: true, direction: direction, wiredFunction: wiredFunction),
                    registerState: state,
                    notifyOnInputChange: notifyOnInputChange
                )
            ])
        )
    }

    /// Reads the value from a specified GPIO.
    /// - Parameter pin: A GPIO to read value.
    /// - Returns: A value of GPIO.
    @discardableResult
    func digitalRead(_ pin: GPIO.Pin) -> Promise<Level> {
        return Promise<Level> { [weak self] resolve, reject in
            guard let self else {
                return
            }
            self.read(characteristic: ControlService.gpioInput).then { readValue in
                let value = readValue.values.first { val in
                    return val.pin == pin
                }
                guard let value else {
                    reject(PeripheralOperationError.couldNotReadValue)
                    return
                }
                if value.isValid == false {
                    reject(PeripheralOperationError.invalidReadValue)
                    return
                }
                resolve(value.level)
            }.catch { error in
                reject(error)
            }
        }
    }

    /// Writes a level value to a GPIO.
    /// - Parameters:
    ///   - pin: A GPIO to write value.
    ///   - level: A value of level.
    /// - Returns: A peripheral this method call.
    @discardableResult
    func digitalWrite(_ pin: GPIO.Pin, value: Level) -> Promise<any Peripheral> {
        return write(
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
    /// - Returns: A peripheral this method call.
    @discardableResult
    func analogBegin(pin: Analog.Pin, config: Analog.ConfigPayload) -> Promise<any Peripheral> {
        return write(
            characteristic: ConfigService.configCommand,
            command: .analog(config: config)
        )
    }

    /// Reads value of AIO.
    /// - Parameters:
    ///   - pin: An AIO to read value.
    ///   - config: A configuration of AIO.
    /// - Returns: A peripheral this method call.
    @discardableResult
    func analogRead(_ pin: Analog.Pin) -> Promise<Analog.InputValue> {
        return Promise<Analog.InputValue> { [weak self] resolve, reject in
            guard let self else {
                return
            }
            self.read(characteristic: ControlService.analogInput).then { readValue in
                let value = readValue.values.first { val in
                    return val.pin == pin
                }
                guard let value else {
                    reject(PeripheralOperationError.couldNotReadValue)
                    return
                }
                if value.isValid == false {
                    reject(PeripheralOperationError.invalidReadValue)
                    return
                }
                resolve(value)
            }.catch { error in
                reject(error)
            }
        }
    }

    /// Writes value of AIO.
    /// - Parameters:
    ///   - pin: An AIO to read value.
    ///   - value: A value that is written.
    ///   - transitionDuration: A duration for transitioning current value to specified value.
    /// - Returns: A peripheral this method call.
    @discardableResult
    func analogWrite(_ pin: Analog.Pin, value: UInt16, transitionDuration: UInt32 = 0) -> Promise<any Peripheral> {
        return write(
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
    /// - Returns: A peripheral this method call.
    @discardableResult
    func softwarePWMMode(pin: PWM.Pin, config: PWM.Software.DriveConfig) -> Promise<any Peripheral> {
        return write(
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
    /// - Returns: A peripheral this method call.
    @discardableResult
    func softwarePWMDrive(pin: PWM.Pin, value: PWM.Software.ControlValue, transitionDuration: UInt32 = 0) -> Promise<any Peripheral> {
        return write(
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
    /// - Returns: A peripheral this method call.
    @discardableResult
    func hardwarePWMMode(pin: PWM.Pin, clock: PWM.Hardware.Clock, prescaler: PWM.Hardware.Prescaler, value: UInt16) -> Promise<any Peripheral> {
        return write(
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
    /// - Returns: A peripheral this method call.
    @discardableResult
    func hardwarePWMDrive(pin: PWM.Pin, value: UInt16, transitionDuration: UInt32 = 0) -> Promise<any Peripheral> {
        return write(
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
    /// - Returns: A peripheral this method call.
    @discardableResult
    func serialBegin(baudrate: UInt32, parity: UART.Parity = .none, stopBit: UART.StopBit = ._0_5) -> Promise<any Peripheral> {
        return write(
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
    /// - Returns: A peripheral this method call.
    @discardableResult
    func serialWrite(data: [UInt8]) -> Promise<any Peripheral> {
        return write(
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
    /// - Returns: A peripheral this method call.
    @discardableResult
    func spiBegin(bitrate: UInt32, endian: SPI.Endian = .lsbFirst, mode: SPI.Mode = .mode0) -> Promise<any Peripheral> {
        return write(
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
    /// - Returns: A peripheral this method call.
    @discardableResult
    func spiTransfer(data: [UInt8]) -> Promise<any Peripheral> {
        return write(
            characteristic: ControlService.controlCommand,
            command: .spiTransfer(
                SPI.TransferControlPayload(data: data)
            )
        )
    }

    /// Attempt to configure I2C mode.
    /// - Parameters:
    ///   - mode: I2C mode.
    /// - Returns: A peripheral this method call.
    @discardableResult
    func i2cBegin(_ mode: I2C.Mode) -> Promise<any Peripheral> {
        return write(
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
    /// - Returns: A peripheral this method call.
    @discardableResult
    func i2cWrite(address: UInt8, writeData: [UInt8]) -> Promise<any Peripheral> {
        return i2cTransfer(address: address, operation: .write, readLength: 0, writeData: writeData)
    }

    /// Attempt to read data from I2C slave.
    /// - Parameters:
    ///   - address: The I2C slave address (address range is 0x00 to 0x7F).
    ///   - readLength: The length of the data to read (0 to 126 bytes).
    /// - Returns: Byte arrey of read from I2C slave.
    @discardableResult
    func i2cRead(address: UInt8, readLength: UInt8) -> Promise<[UInt8]> {
        var cancellable = Set<AnyCancellable>()
        return Promise<[UInt8]> { [weak self] resolve, reject in
            guard let self else {
                return
            }
            self.controlService.i2cDataInput.value.sink { readValue in
                if readValue.address == address {
                    resolve(readValue.readBytes)
                }
            }.store(in: &cancellable)
            self.i2cTransfer(
                address: address,
                operation: .read,
                readLength: readLength,
                writeData: []
            ).catch { error in
                reject(error)
            }
        }.always {
            cancellable.removeAll()
        }
    }

    /// Attempt to transfer data.
    /// - Parameters:
    ///   - address: The I2C slave address (address range is 0x00 to 0x7F).
    ///   - operation: The transaction operation.
    ///   - readLength: The length of the data to read (0 to 126 bytes).
    ///   - writeData: The data to write (valid length 0 to 124 bytes).
    /// - Returns: A peripheral this method call.
    @discardableResult
    func i2cTransfer(address: UInt8, operation: I2C.Operation, readLength: UInt8, writeData: [UInt8]) -> Promise<any Peripheral> {
        return Promise<any Peripheral> { [weak self] resolve, reject in
            guard let self else {
                return
            }
            if address > 0x7F {
                reject(I2C.OperationError.invalidSlaveAddress)
                return
            }
            if readLength > 126 {
                reject(I2C.OperationError.badReadLength)
                return
            }
            if writeData.count > 124 {
                reject(I2C.OperationError.badWriteLength)
                return
            }
            self.write(
                characteristic: ControlService.controlCommand,
                command: .i2cTransfer(
                    I2C.TransferControlPayload(
                        operation: operation,
                        readLength: readLength,
                        address: address,
                        writeData: writeData
                    )
                )
            ).then { peripheral in
                resolve(peripheral)
            }.catch { error in
                reject(error)
            }
        }
    }
}
