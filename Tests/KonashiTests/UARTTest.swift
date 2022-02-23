//
//  UARTTest.swift
//  
//
//  Created by Akira Matsuda on 2022/02/23.
//

import XCTest
@testable import Konashi

class UARTTest: XCTestCase {
    func testEnable() throws {
        // UART: enable, 115200, no parity, 1 stop bit -> 0x81 0x00 0xc2 0x01 0x00
        let enabled = UART.Config(
            value: .enable(
                parity: .none,
                stopBit: ._1,
                baudrate: 115200
            )
        )
        XCTAssertEqual(
            enabled.compose(),
            [0x81, 0x00, 0xc2, 0x01, 0x00]
        )
        XCTAssertEqual(
            enabled,
            try? UART.Config.parse(
                [0x81, 0x00, 0xc2, 0x01, 0x00]
            ).get()
        )

        // Settings Command write:
        // 0x06 0x81 0x00 0xc2 0x01 0x00
        XCTAssertEqual(
            [UInt8](ConfigService.ConfigCommand.uart(
                config: enabled
            ).compose()),
            [0x06, 0x81, 0x00, 0xc2, 0x01, 0x00]
        )
    }
    
    func testDisable() throws {
        // UART: disable -> 0x00 0x00 0x00 0x00 0x00
        let disable = UART.Config.disable
        XCTAssertEqual(
            disable.compose(),
            [0x00, 0x00, 0x00, 0x00, 0x00]
        )
        XCTAssertEqual(
            disable,
            try? UART.Config.parse(
                [0x00, 0x00, 0x00, 0x00, 0x00]
            ).get()
        )

        // Settings Command write:
        // 0x06 0x00 0x00 0x00 0x00 0x00
        XCTAssertEqual(
            [UInt8](ConfigService.ConfigCommand.uart(
                config: disable
            ).compose()),
            [0x06, 0x00, 0x00, 0x00, 0x00, 0x00]
        )
    }
    
    func testWrite() throws {
        // UART send: 4 bytes (0x2a 0x83 0xb4 0xda) -> 0x2a 0x83 0xb4 0xda
        let send = UART.SendControlPayload(data: [0x2a, 0x83, 0xb4, 0xda])
        XCTAssertEqual(
            send.compose(),
            [0x2a, 0x83, 0xb4, 0xda]
        )
        
        // Control Command write:
        // 0x06 0x2a 0x83 0xb4 0xda
        XCTAssertEqual(
            [UInt8](ControlService.ControlCommand.uartSend(
                send
            ).compose()),
            [0x06, 0x2a, 0x83, 0xb4, 0xda]
        )
    }
    
    func testWrite128Bytes() throws {
        // UART send: 128 bytes (0x2a...0x2a 0x2b) -> 0x2a...0x2a
        // send bytes will be trancated last 1 byte (become 127 byte)
        var data = [UInt8]()
        var correctData = [UInt8]()
        for _ in 0..<127 {
            data.append(0x2a)
            correctData.append(0x2a)
        }
        data.append(0x2b)
        let send = UART.SendControlPayload(data: data)
        XCTAssertEqual(
            send.compose(),
            correctData
        )
    }
}
