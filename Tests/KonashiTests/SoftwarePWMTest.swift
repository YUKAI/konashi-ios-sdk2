//
//  SoftwarePWMTest.swift
//  
//
//  Created by Akira Matsuda on 2021/08/28.
//

import XCTest
@testable import Konashi

class SoftwarePWMTest: XCTestCase {
    func testDisable() throws {
        let control = PWM.Software.PinConfig(
            pin: .pin3,
            driveConfig: .disable
        )
        XCTAssertEqual(
            control.compose(),
            [0x30, 0x00, 0x00]
        )
    }

    func testDutyCommand() throws {
        // SoftPWM0のConfigにduty controlと1000ｍｓの固定周期を設定
        // この設定でPWMの周期は1000msに固定されててControlからdutyを制御可能
        let config = PWM.Software.PinConfig(
            pin: .pin0,
            driveConfig: .duty(millisec: 1000)
        )
        XCTAssertEqual(
            [UInt8](ConfigService.ConfigCommand.softwarePWM([config]).compose()),
            [0x02, 0x01, 0xE8, 0x03]
        )

        // この場合SoftPWM0のControlに50%のdutyで制御
        let control = PWM.Software.ControlPayload(
            pin: .pin0,
            value: .duty(ratio: 0.5),
            transitionDuration: 0
        )
        XCTAssertEqual(
            [UInt8](ControlService.ControlCommand.softwarePWM([control]).compose()),
            [0x02, 0x00, 0xF4, 0x01, 0x00, 0x00, 0x00, 0x00]
        )
    }

    func testPeriodCommand() throws {
        // SoftPWM1のConfigにperiod controlと75%の固定dutyを設定
        // この設定でPWMのdutyが75％に固定されててControlから周期を制御可能
        let config = PWM.Software.PinConfig(
            pin: .pin1,
            driveConfig: .period(ratio: 0.75)
        )
        XCTAssertEqual(
            [UInt8](ConfigService.ConfigCommand.softwarePWM([config]).compose()),
            [0x02, 0x12, 0xEE, 0x02]
        )

        // この場合SoftPWM1のControlに2000ｍｓの周期で制御
        let control = PWM.Software.ControlPayload(
            pin: .pin1,
            value: .period(millisec: 2000),
            transitionDuration: 0
        )
        XCTAssertEqual(
            [UInt8](ControlService.ControlCommand.softwarePWM([control]).compose()),
            [0x02, 0x01, 0xD0, 0x07, 0x00, 0x00, 0x00, 0x00]
        )
    }
}
