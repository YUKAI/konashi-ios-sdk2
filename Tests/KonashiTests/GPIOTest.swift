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
            mode: .input,
            registerState: .none,
            notifyOnInputChange: true
        )
        XCTAssertEqual(
            gpio0.compose(),
            [0x01, 0x20]
        )

        // GPIO1: enable, output -> 0x11 0x10
        let gpio1 = GPIO.ConfigPayload(
            pin: .pin1,
            mode: .output
        )
        XCTAssertEqual(
            gpio1.compose(),
            [0x11, 0x10]
        )

        // GPIO2: enable, output, pull-up -> 0x21 0x12
        let gpio2 = GPIO.ConfigPayload(
            pin: .pin2,
            mode: .output,
            registerState: .pullUp
        )
        XCTAssertEqual(
            gpio2.compose(),
            [0x21, 0x12]
        )

        // GPIO3: enable, output, pull-down -> 0x31 0x11
        let gpio3 = GPIO.ConfigPayload(
            pin: .pin3,
            mode: .output,
            registerState: .pullDown
        )
        XCTAssertEqual(
            gpio3.compose(),
            [0x31, 0x11]
        )

        // GPIO4: enable, open source (wired-or function) -> 0x41 0x18
        let gpio4 = GPIO.ConfigPayload(
            pin: .pin4,
            mode: .openSource
        )
        XCTAssertEqual(
            gpio4.compose(),
            [0x41, 0x08]
        )

        // GPIO5: enable, open source (wired-or function), pull-down -> 0x51 0x19
        let gpio5 = GPIO.ConfigPayload(
            pin: .pin5,
            mode: .openSource,
            registerState: .pullDown
        )
        XCTAssertEqual(
            gpio5.compose(),
            [0x51, 0x09]
        )

        // GPIO6: enable, open drain (wired-and function) -> 0x61 0x14
        let gpio6 = GPIO.ConfigPayload(
            pin: .pin6,
            mode: .openDrain
        )
        XCTAssertEqual(
            gpio6.compose(),
            [0x61, 0x04]
        )

        // GPIO7: enable, open drain (wired-and function), pull-up -> 0x71 0x16
        let gpio7 = GPIO.ConfigPayload(
            pin: .pin7,
            mode: .openDrain,
            registerState: .pullUp
        )
        XCTAssertEqual(
            gpio7.compose(),
            [0x71, 0x06]
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
            [0x01, 0x01, 0x20, 0x11, 0x10, 0x21, 0x12, 0x31, 0x11, 0x41, 0x08, 0x51, 0x09, 0x61, 0x04, 0x71, 0x06]
        )
    }
    
    func testDisable() throws {
        // GPIO0: disable -> 0x00 0x00
        let gpio0 = GPIO.ConfigPayload(
            pin: .pin0,
            mode: .disable
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
