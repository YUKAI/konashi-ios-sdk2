//
//  Peripheral+Arduino.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/17.
//

import Combine
import Foundation
import Promises

public extension Peripheral {
    enum Mode {
        case input
        case output
        case inputPullUp
    }

    @discardableResult
    func pinMode(_ pin: GPIO.Pin, mode: Mode, wiredFunction: GPIO.WiredFunction = .disabled) -> Promise<Peripheral> {
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

    @discardableResult
    func digitalRead(_ pin: GPIO.Pin) -> Promise<Level> {
        return Promise<Level> { [weak self] resolve, reject in
            guard let weakSelf = self else {
                return
            }
            weakSelf.read(characteristic: ControlService.gpioInput).then { readValue in
                let value = readValue.values.first { val in
                    return val.pin == pin
                }
                guard let value = value else {
                    reject(OperationError.couldNotReadValue)
                    return
                }
                if value.isValid == false {
                    reject(OperationError.invalidReadValue)
                    return
                }
                resolve(value.level)
            }.catch { error in
                reject(error)
            }
        }
    }

    @discardableResult
    func digitalWrite(_ pin: GPIO.Pin, value: Level) -> Promise<Peripheral> {
        return write(
            characteristic: ControlService.controlCommand,
            command: .gpio(
                [GPIO.ControlPayload(pin: pin, level: value)]
            )
        )
    }

    @discardableResult
    func analogBegin(pin: Analog.Pin, config: Analog.ConfigPayload) -> Promise<Peripheral> {
        return write(
            characteristic: ConfigService.configCommand,
            command: .analog(config: config)
        )
    }

    @discardableResult
    func analogRead(_ pin: Analog.Pin) -> Promise<Analog.InputValue> {
        return Promise<Analog.InputValue> { [weak self] resolve, reject in
            guard let weakSelf = self else {
                return
            }
            weakSelf.read(characteristic: ControlService.analogInput).then { readValue in
                let value = readValue.values.first { val in
                    return val.pin == pin
                }
                guard let value = value else {
                    reject(OperationError.couldNotReadValue)
                    return
                }
                if value.isValid == false {
                    reject(OperationError.invalidReadValue)
                    return
                }
                resolve(value)
            }.catch { error in
                reject(error)
            }
        }
    }

    @discardableResult
    func analogWrite(_ pin: Analog.Pin, value: UInt16, transitionDuration: UInt32 = 0) -> Promise<Peripheral> {
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

    @discardableResult
    func softwarePWMMode(pin: PWM.Pin, config: PWM.Software.DriveConfig) -> Promise<Peripheral> {
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

    @discardableResult
    func softwarePWMDrive(pin: PWM.Pin, value: PWM.Software.ControlValue, transitionDuration: UInt32 = 0) -> Promise<Peripheral> {
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

    @discardableResult
    func hardwarePWMMode(pin: PWM.Pin, clock: PWM.Hardware.Clock, prescaler: PWM.Hardware.Prescaler, value: UInt16) -> Promise<Peripheral> {
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

    @discardableResult
    func hardwarePWMDrive(pin: PWM.Pin, value: UInt16, transitionDuration: UInt32 = 0) -> Promise<Peripheral> {
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

    @discardableResult
    func serialBegin(baudrate: UInt32, parity: UART.Parity = .none, stopBit: UART.StopBit = ._0_5) -> Promise<Peripheral> {
        return write(
            characteristic: ConfigService.configCommand,
            command: .uart(
                config: UART.Config(
                    value: .enable(
                        parity: parity,
                        stopBit: stopBit,
                        baudrate: baudrate
                    )
                )
            )
        )
    }

    @discardableResult
    func serialWrite(data: [UInt8]) -> Promise<Peripheral> {
        return write(
            characteristic: ControlService.controlCommand,
            command: .uartSend(
                UART.SendControlPayload(data: data)
            )
        )
    }

    @discardableResult
    func spiBegin(bitrate: UInt32, endian: SPI.Endian = .lsbFirst, mode: SPI.Mode = .mode0) -> Promise<Peripheral> {
        return write(
            characteristic: ConfigService.configCommand,
            command: .spi(
                config: SPI.Config(
                    value: .enable(
                        endian: endian,
                        mode: mode,
                        bitrate: bitrate
                    )
                )
            )
        )
    }

    @discardableResult
    func spiTransfer(data: [UInt8]) -> Promise<Peripheral> {
        return write(
            characteristic: ControlService.controlCommand,
            command: .spiTransfer(
                SPI.TransferControlPayload(data: data)
            )
        )
    }

    @discardableResult
    func i2cBegin(_ mode: I2C.Mode) -> Promise<Peripheral> {
        return write(
            characteristic: ConfigService.configCommand,
            command: .i2c(
                config: I2C.Config(value: .enable(mode: mode))
            )
        )
    }

    @discardableResult
    func i2cWrite(address: UInt8, writeData: [UInt8]) -> Promise<Peripheral> {
        return i2cTransfer(address: address, operation: .write, readLength: 0, writeData: writeData)
    }

    @discardableResult
    func i2cRead(address: UInt8, readLength: UInt8) -> Promise<[UInt8]> {
        var cancellable = Set<AnyCancellable>()
        return Promise<[UInt8]> { [weak self] resolve, reject in
            guard let weakSelf = self else {
                return
            }
            weakSelf.controlService.i2cDataInput.value.sink { readValue in
                if readValue.value.address == address {
                    resolve(readValue.value.readBytes)
                }
            }.store(in: &cancellable)
            weakSelf.i2cTransfer(
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

    @discardableResult
    func i2cTransfer(address: UInt8, operation: I2C.Operation, readLength: UInt8, writeData: [UInt8]) -> Promise<Peripheral> {
        return Promise<Peripheral> { [weak self] resolve, reject in
            guard let weakSelf = self else {
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
            weakSelf.write(
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
