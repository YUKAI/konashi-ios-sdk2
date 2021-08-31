//
//  GPIOTest.swift
//  
//
//  Created by Akira Matsuda on 2021/08/31.
//

import XCTest
@testable import Konashi

class GPIOTest: XCTestCase {
    func testEnable() throws {
        // GPIO0: enable, input, notify on input change -> 0x01 0x20
        let gpio0 = GPIO.ConfigPayload(
            pin: .pin0,
            isEnabled: true,
            notifyOnInputChange: true,
            direction: .input,
            wiredFunction: .disabled,
            pullUp: false,
            pullDown: false
        )
        XCTAssertEqual(
            gpio0.compose(),
            [0x01, 0x20]
        )

        // GPIO1: enable, output -> 0x11 0x10
        let gpio1 = GPIO.ConfigPayload(
            pin: .pin1,
            isEnabled: true,
            notifyOnInputChange: false,
            direction: .output,
            wiredFunction: .disabled,
            pullUp: false,
            pullDown: false
        )
        XCTAssertEqual(
            gpio1.compose(),
            [0x11, 0x10]
        )

        // GPIO2: enable, output, pull-up -> 0x21 0x12
        let gpio2 = GPIO.ConfigPayload(
            pin: .pin2,
            isEnabled: true,
            notifyOnInputChange: false,
            direction: .output,
            wiredFunction: .disabled,
            pullUp: true,
            pullDown: false
        )
        XCTAssertEqual(
            gpio2.compose(),
            [0x21, 0x12]
        )

        // GPIO3: enable, output, pull-down -> 0x31 0x11
        let gpio3 = GPIO.ConfigPayload(
            pin: .pin3,
            isEnabled: true,
            notifyOnInputChange: false,
            direction: .output,
            wiredFunction: .disabled,
            pullUp: false,
            pullDown: true
        )
        XCTAssertEqual(
            gpio3.compose(),
            [0x31, 0x11]
        )

        // GPIO4: enable, open source (wired-or function) -> 0x41 0x18
        let gpio4 = GPIO.ConfigPayload(
            pin: .pin4,
            isEnabled: true,
            notifyOnInputChange: false,
            direction: .input,
            wiredFunction: .wiredOr,
            pullUp: false,
            pullDown: false
        )
        XCTAssertEqual(
            gpio4.compose(),
            [0x41, 0x18]
        )

        // GPIO5: enable, open source (wired-or function), pull-down -> 0x51 0x19
        let gpio5 = GPIO.ConfigPayload(
            pin: .pin5,
            isEnabled: true,
            notifyOnInputChange: false,
            direction: .input,
            wiredFunction: .wiredOr,
            pullUp: false,
            pullDown: true
        )
        XCTAssertEqual(
            gpio5.compose(),
            [0x51, 0x19]
        )

        // GPIO6: enable, open drain (wired-and function) -> 0x61 0x14
        let gpio6 = GPIO.ConfigPayload(
            pin: .pin6,
            isEnabled: true,
            notifyOnInputChange: false,
            direction: .input,
            wiredFunction: .wiredAnd,
            pullUp: false,
            pullDown: false
        )
        XCTAssertEqual(
            gpio6.compose(),
            [0x61, 0x14]
        )

        // GPIO7: enable, open drain (wired-and function), pull-up -> 0x71 0x16
        let gpio7 = GPIO.ConfigPayload(
            pin: .pin7,
            isEnabled: true,
            notifyOnInputChange: false,
            direction: .input,
            wiredFunction: .wiredAnd,
            pullUp: true,
            pullDown: false
        )
        XCTAssertEqual(
            gpio7.compose(),
            [0x61, 0x14]
        )

        // Settings Command write:
        // 0x01 0x01 0x20 0x11 0x10 0x21 0x12 0x31 0x11 0x41 0x18 0x51 0x19 0x61 0x14 0x71 0x16
        XCTAssertEqual(
            [UInt8](ConfigService.ConfigCommand.gpio([
                gpio0,
                gpio1,
                gpio2,
                gpio3,
                gpio4,
                gpio5,
                gpio6,
                gpio7
            ]).compose()),
            [0x01, 0x01, 0x20, 0x11, 0x10, 0x21, 0x12, 0x31, 0x11, 0x41, 0x18, 0x51, 0x19, 0x61, 0x14, 0x71, 0x16]
        )
    }
    
    func testDisable() throws {
        // GPIO0: disable -> 0x00 0x00
        let gpio0 = GPIO.ConfigPayload(
            pin: .pin0,
            isEnabled: false
        )
        XCTAssertEqual(
            gpio0.compose(),
            [0x00, 0x00]
        )

        // Settings Command write: 0x01 0x00 0x00
        XCTAssertEqual(
            [UInt8](ConfigService.ConfigCommand.gpio(
                [gpio0]
            ).compose()),
            [0x01, 0x00, 0x00]
        )
    }
    
    func testLevel() throws {
        // GPIO1: high -> 0x11
        let gpio1 = GPIO.ControlPayload(
            pin: .pin1,
            level: .high
        )
        XCTAssertEqual(
            gpio1.compose(),
            [0x11]
        )
        
        // GPIO2: low -> 0x20
        let gpio2 = GPIO.ControlPayload(
            pin: .pin2,
            level: .low
        )
        XCTAssertEqual(
            gpio2.compose(),
            [0x20]
        )

        // GPIO4: toggle -> 0x42
        let gpio4 = GPIO.ControlPayload(
            pin: .pin4,
            level: .toggle
        )
        XCTAssertEqual(
            gpio4.compose(),
            [0x42]
        )

        // Control Command write: 0x01 0x11 0x20 0x42
        XCTAssertEqual(
            [UInt8](ControlService.ControlCommand.gpio(
                [gpio1, gpio2, gpio4]
            ).compose()),
            [0x01, 0x11, 0x20, 0x42]
        )
        
        // GPIO3: high -> 0x31
        let gpio3 = GPIO.ControlPayload(
            pin: .pin3,
            level: .high
        )
        XCTAssertEqual(
            gpio3.compose(),
            [0x31]
        )

        // Control Command write: 0x01 0x31
        XCTAssertEqual(
            [UInt8](ControlService.ControlCommand.gpio(
                [gpio3]
            ).compose()),
            [0x01, 0x31]
        )
    }
}
