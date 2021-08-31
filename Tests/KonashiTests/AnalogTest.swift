//
//  File.swift
//  
//
//  Created by Akira Matsuda on 2021/08/31.
//

import Foundation
//14.
//
//15.
//AIO1: input, notify -> 0x1a
//AIO2: output -> 0x29
//Settings Command write:
//0x04 0x1a 0x29
//
//16.
//AIO0: transition to step 16 (if range 1.6~4.7uA = 3.2uA) in 300ms -> 0x00 0x10 0x00 0x2c 0x01 0x00 0x00
//AIO2: transition to value 3000 (if ref 1V25 = ~0.9V) in 589ms -> 0x02 0xb8 0x0b 0x4d 0x02 0x00 0x00
//Control Command write:
//0x04 0x00 0x10 0x00 0x2c 0x01 0x00 0x00 0x02 0xb8 0x0b 0x4d 0x02 0x00 0x00

import XCTest
@testable import Konashi

class AnalogTest: XCTestCase {
    func testSetting() throws {
        // ADC update period: 1s -> 0xf0 0x09
        let updatePeriod = Analog.ADCUpdatePeriodConfig(updatePeriodStep: 9)
        XCTAssertEqual(
            updatePeriod.compose(),
            [0xf0, 0x09]
        )

        // ADC voltage reference: 2V5 -> 0xe2
        print(Analog.ADCVoltageReference.allCases.map {
            $0.rawValue
        })
        let adc = Analog.ADCVoltageReferenceConfig(reference: ._2V5)
        XCTAssertEqual(
            adc.compose(),
            [0xe2]
        )

        // VDAC voltage reference: 1V25 low noise -> 0xd1
        let vdac = Analog.VDACVoltageReferenceConfig(reference: ._1V25LowNoise)
        XCTAssertEqual(
            vdac.compose(),
            [0xd1]
        )

        // IDAC current range: 1.6~4.7uA, step 100nA -> 0xc2
        let idac = Analog.IDACCurrentRangeConfig(step: .step100nA)
        XCTAssertEqual(
            idac.compose(),
            [0xc2]
        )

        // AIO0: output -> 0x09
        let aio0 = Analog.PinConfig(
            pin: .pin0,
            isEnabled: true,
            notifyOnInputChange: false,
            direction: .output
        )
        XCTAssertEqual(
            aio0.compose(),
            [0x09]
        )

        // Settings Command write: 0x04 0xf0 0x09 0xe2 0xd1 0xc2 0x09
        XCTAssertEqual(
            [UInt8](
                ConfigService.ConfigCommand.analog(
                        config: Analog.ConfigPayload(
                            pinConfig: [aio0],
                            adcUpdatePeriod: updatePeriod,
                            adcVoltageReferenceConfig: adc,
                            vdacVoltageReferenceConfig: vdac,
                            idacCurrentRangeConfig: idac
                        )).compose()
            ),
            [0x04, 0xf0, 0x09, 0xe2, 0xd1, 0xc2, 0x09]
        )
    }
    
    func testInputOutput() throws {
        // AIO1: input, notify -> 0x1a
        let aio1 = Analog.PinConfig(
            pin: .pin1,
            isEnabled: true,
            notifyOnInputChange: true,
            direction: .input
        )
        XCTAssertEqual(
            aio1.compose(),
            [0x1a]
        )

        // AIO2: output -> 0x29
        let aio2 = Analog.PinConfig(
            pin: .pin2,
            isEnabled: true,
            notifyOnInputChange: false,
            direction: .output
        )
        XCTAssertEqual(
            aio2.compose(),
            [0x29]
        )

        // Settings Command write: 0x04 0x1a 0x29
        XCTAssertEqual(
            [UInt8](
                ConfigService.ConfigCommand.analog(
                    config: Analog.ConfigPayload(pinConfig: [aio1, aio2])).compose()
            ),
            [0x04, 0x1a, 0x29]
        )
    }
    
    func testTransition() throws {
        // AIO0: transition to step 16 (if range 1.6~4.7uA = 3.2uA) in 300ms -> 0x00 0x10 0x00 0x2c 0x01 0x00 0x00
        let aio0 = Analog.ControlPayload(
            pin: .pin0,
            stepValue: 16,
            transitionDurationMillisec: 300
        )
        XCTAssertEqual(
            aio0.compose(),
            [0x00, 0x10, 0x00, 0x2c, 0x01, 0x00, 0x00]
        )

        // AIO2: transition to value 3000 (if ref 1V25 = ~0.9V) in 589ms -> 0x02 0xb8 0x0b 0x4d 0x02 0x00 0x00
        let aio2 = Analog.ControlPayload(
            pin: .pin2,
            stepValue: 3000,
            transitionDurationMillisec: 589
        )
        XCTAssertEqual(
            aio2.compose(),
            [0x02, 0xb8, 0x0b, 0x4d, 0x02, 0x00, 0x00]
        )

        // Control Command write: 0x04 0x00 0x10 0x00 0x2c 0x01 0x00 0x00 0x02 0xb8 0x0b 0x4d 0x02 0x00 0x00
        XCTAssertEqual(
            [UInt8](
                ControlService.ControlCommand.analog([aio0, aio2]).compose()
            ),
            [0x04, 0x00, 0x10, 0x00, 0x2c, 0x01, 0x00, 0x00, 0x02, 0xb8, 0x0b, 0x4d, 0x02, 0x00, 0x00]
        )
    }
}
