//
//  HardwarePWMTest.swift
//  
//
//  Created by Akira Matsuda on 2021/08/31.
//

import XCTest
@testable import Konashi

class HardwarePWMTest: XCTestCase {
    func testPWM() throws {
        // HardPWM clocking: 38.4MHz clock, 1024 prescale, 37500 top -> 0xff 0x0a 0x7c 0x92
        let clock = PWM.Hardware.ClockConfig(
            clock: ._38_4M,
            prescaler: .div1024,
            timerValue: 37500
        )
        XCTAssertEqual(
            clock.compose(),
            [0xff, 0x0a, 0x7c, 0x92]
        )

        // HardPWM0: disable -> 0x00
        let pwm0 = PWM.Hardware.PinConfig(pin: .pin0, isEnabled: false)
        XCTAssertEqual(
            pwm0.compose(),
            [0x00]
        )
        XCTAssertEqual(
            pwm0,
            try? PWM.Hardware.PinConfig.parse(
                [0x00],
                info: [PWM.Hardware.PinConfig.InfoKey.pin.rawValue : PWM.Pin.pin0]
            ).get()
        )

        // HardPWM1: enable -> 0x11
        let pwm1 = PWM.Hardware.PinConfig(pin: .pin1, isEnabled: true)
        XCTAssertEqual(
            pwm1.compose(),
            [0x11]
        )
        XCTAssertEqual(
            pwm1,
            try? PWM.Hardware.PinConfig.parse(
                [0x11],
                info: [PWM.Hardware.PinConfig.InfoKey.pin.rawValue : PWM.Pin.pin1]
            ).get()
        )

        // HardPWM2: enable -> 0x21
        let pwm2 = PWM.Hardware.PinConfig(pin: .pin2, isEnabled: true)
        XCTAssertEqual(
            pwm2.compose(),
            [0x21]
        )
        XCTAssertEqual(
            pwm2,
            try? PWM.Hardware.PinConfig.parse(
                [0x21],
                info: [PWM.Hardware.PinConfig.InfoKey.pin.rawValue : PWM.Pin.pin2]
            ).get()
        )
        
        // Settings Command write: 0x03 0xff 0x0a 0x7c 0x92 0x00 0x11 0x21
        XCTAssertEqual(
            [UInt8](
                ConfigService.ConfigCommand.hardwarePWM(
                    config: PWM.Hardware.ConfigPayload(
                        pinConfig: [pwm0, pwm1, pwm2],
                        clockConfig: clock
                    )
                ).compose()
            ),
            [0x03, 0xff, 0x0a, 0x7c, 0x92, 0x00, 0x11, 0x21]
        )

        // HardPWM3: enable -> 0x31
        let pwm3 = PWM.Hardware.PinConfig(pin: .pin3, isEnabled: true)
        XCTAssertEqual(
            pwm3.compose(),
            [0x31]
        )
        XCTAssertEqual(
            pwm3,
            try? PWM.Hardware.PinConfig.parse(
                [0x31],
                info: [PWM.Hardware.PinConfig.InfoKey.pin.rawValue : PWM.Pin.pin3]
            ).get()
        )

        // Settings Command write: 0x03 0x31
        XCTAssertEqual(
            [UInt8](
                ConfigService.ConfigCommand.hardwarePWM(
                    config: PWM.Hardware.ConfigPayload(
                        pinConfig: [pwm3]
                    )
                ).compose()
            ),
            [0x03, 0x31]
        )
    }

    func testClockConfig() throws {
        // HardPWM clocking: 20kHz clock, 65535 top -> 0xff 0x10 0xff 0xff
        let clock = PWM.Hardware.ClockConfig(
            clock: ._20k,
            prescaler: .div1,
            timerValue: 65535
        )
        XCTAssertEqual(
            clock.compose(),
            [0xff, 0x10, 0xff, 0xff]
        )

        // Settings Command write: 0x03 0xff 0x10 0xff 0xff
        XCTAssertEqual(
            [UInt8](
                ConfigService.ConfigCommand.hardwarePWM(
                    config: PWM.Hardware.ConfigPayload(
                        clockConfig: clock
                    )
                ).compose()
            ),
            [0x03, 0xff, 0x10, 0xff, 0xff]
        )
    }

    func testTransition() throws {
        // HardPWM1: transition to value 37500 in 0ms -> 0x01 0x7c 0x92 0x00 0x00 0x00 0x00
        let pwm1 = PWM.Hardware.ControlPayload(
            pin: .pin1,
            controlValue: 37500,
            transitionDurationMillisec: 0
        )
        XCTAssertEqual(
            pwm1.compose(),
            [0x01, 0x7c, 0x92, 0x00, 0x00, 0x00, 0x00]
        )

        // HardPWM3: transition to value 100 in 200ms -> 0x03 0x64 0x00 0xc8 0x00 0x00 0x00
        let pwm3 = PWM.Hardware.ControlPayload(
            pin: .pin3,
            controlValue: 100,
            transitionDurationMillisec: 200
        )
        XCTAssertEqual(
            pwm3.compose(),
            [0x03, 0x64, 0x00, 0xc8, 0x00, 0x00, 0x00]
        )

        // Control Command write: 0x03 0x01 0x7c 0x92 0x00 0x00 0x00 0x00 0x03 0x64 0x00 0xc8 0x00 0x00 0x00
        XCTAssertEqual(
            [UInt8](
                ControlService.ControlCommand.hardwarePWM([pwm1, pwm3]).compose()
            ),
            [0x03, 0x01, 0x7c, 0x92, 0x00, 0x00, 0x00, 0x00, 0x03, 0x64, 0x00, 0xc8, 0x00, 0x00, 0x00]
        )
        
        // HardPWM2: transition to value 65535 in 9000ms -> 0x02 0xff 0xff 0x28 0x23 0x00 0x00
        let pwm2 = PWM.Hardware.ControlPayload(
            pin: .pin2,
            controlValue: 65535,
            transitionDurationMillisec: 9000
        )
        XCTAssertEqual(
            pwm2.compose(),
            [0x02, 0xff, 0xff, 0x28, 0x23, 0x00, 0x00]
        )

        // Control Command write: 0x03 0x02 0xff 0xff 0x28 0x23 0x00 0x00
        XCTAssertEqual(
            [UInt8](
                ControlService.ControlCommand.hardwarePWM([pwm2]).compose()
            ),
            [0x03, 0x02, 0xff, 0xff, 0x28, 0x23, 0x00, 0x00]
        )
    }
}
