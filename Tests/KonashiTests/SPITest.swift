//
//  SPITest.swift
//
//
//  Created by Akira Matsuda on 2022/02/23.
//

@testable import Konashi
import XCTest

class SPITest: XCTestCase {
    func testDisable() throws {
        // SPI: disable -> 0x00 0x00 0x00 0x00 0x00
        let disable = SPI.Config.disable
        XCTAssertEqual(
            disable.compose(),
            [0x00, 0x00, 0x00, 0x00, 0x00]
        )
        XCTAssertEqual(
            disable,
            try? SPI.Config.parse(
                [0x00, 0x00, 0x00, 0x00, 0x00]
            ).get()
        )

        // Settings Command write:
        // 0x07 0x00 0x00 0x00 0x00 0x00
        XCTAssertEqual(
            [UInt8](ConfigService.ConfigCommand.spi(
                config: disable
            ).compose()),
            [0x07, 0x00, 0x00, 0x00, 0x00, 0x00]
        )
    }

    func testEnable() throws {
        // SPI: enable, mode 2, MSB first, 1MHz bitrate -> 0x8a 0x40 0x42 0x0f 0x00
        let enable = SPI.Config.enable(bitrate: 1000000, endian: .msbFirst, mode: .mode2)
        XCTAssertEqual(
            enable.compose(),
            [0x8A, 0x40, 0x42, 0x0F, 0x00]
        )
        XCTAssertEqual(
            enable,
            try? SPI.Config.parse(
                [0x8A, 0x40, 0x42, 0x0F, 0x00]
            ).get()
        )

        // Settings Command write:
        // 0x07 0x8a 0x40 0x42 0x0f 0x00
        XCTAssertEqual(
            [UInt8](ConfigService.ConfigCommand.spi(
                config: enable
            ).compose()),
            [0x07, 0x8A, 0x40, 0x42, 0x0F, 0x00]
        )
    }

    func testTransfer() throws {
        // SPI transaction: send 3 bytes (0x15 0xbe 0x00) -> 0x15 0xbe 0x00
        let transfer = SPI.TransferControlPayload(data: [0x15, 0xBE, 0x00])
        XCTAssertEqual(
            transfer.compose(),
            [0x15, 0xBE, 0x00]
        )

        // Control Command write:
        // 0x07 0x15 0xbe 0x00
        XCTAssertEqual(
            [UInt8](ControlService.ControlCommand.spiTransfer(transfer).compose()),
            [0x07, 0x15, 0xBE, 0x00]
        )
    }

    func testTransfer128Bytes() throws {
        // SPI send: 128 bytes (0x2a...0x2a 0x2b) -> 0x2a...0x2a
        // send bytes will be trancated last 1 byte (become 128 byte)
        var data = [UInt8]()
        var correctData = [UInt8]()
        for _ in 0 ..< 127 {
            data.append(0x2A)
            correctData.append(0x2A)
        }
        data.append(0x2B)
        let transfer = SPI.TransferControlPayload(data: data)
        XCTAssertEqual(
            transfer.compose(),
            correctData
        )
    }
}
