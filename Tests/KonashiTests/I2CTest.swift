//
//  I2CTest.swift
//  
//
//  Created by Akira Matsuda on 2022/02/23.
//

import XCTest
@testable import Konashi

class I2CTest: XCTestCase {
    func testEnable() throws {
        // I2C: enable, fast mode -> 0x03
        let enabled = I2C.Config(value: .enable(mode: .fast))
        XCTAssertEqual(
            enabled.compose(),
            [0x03]
        )
        XCTAssertEqual(
            enabled,
            try? I2C.Config.parse(
                [0x03]
            ).get()
        )

        // Settings Command write:
        // 0x05 0x03
        XCTAssertEqual(
            [UInt8](ConfigService.ConfigCommand.i2c(
                config: enabled
            ).compose()),
            [0x05, 0x03]
        )
    }
    
    func testDisable() throws {
        // I2C: disable -> 0x00
        let disable = I2C.Config.disable
        XCTAssertEqual(
            disable.compose(),
            [0x00]
        )
        XCTAssertEqual(
            disable,
            try? I2C.Config.parse(
                [0x00]
            ).get()
        )

        // Settings Command write:
        // 0x05 0x00
        XCTAssertEqual(
            [UInt8](ConfigService.ConfigCommand.i2c(
                config: disable
            ).compose()),
            [0x05, 0x00]
        )
    }
    
    func testWriteTransaction() throws {
        // I2C transaction: write to slave 0x5a 2 bytes (0x55 0xaa) -> 0x00 0x00 0x5a 0x55 0xaa
        let write = I2C.TransferControlPayload(
            operation: .write,
            readLength: 0,
            address: 0x5a,
            writeData: [0x55, 0xaa]
        )
        XCTAssertEqual(
            write.compose(),
            [0x00, 0x00, 0x5a, 0x55, 0xaa]
        )

        // Control Command write:
        // 0x05 0x00 0x00 0x5a 0x55 0xaa
        XCTAssertEqual(
            [UInt8](ControlService.ControlCommand.i2cTransfer(
                write
            ).compose()),
            [0x05, 0x00, 0x00, 0x5a, 0x55, 0xaa]
        )
    }
    
    func testWrite125Bytes() throws {
        // I2C send: 125 bytes (0x2a...0x2a 0x2b) -> 0x2a...0x2a
        // send bytes will be trancated last 1 byte (become 124 byte)
        var data = [UInt8]()
        var correctData = [UInt8]()
        for _ in 0..<124 {
            data.append(0x2a)
            correctData.append(0x2a)
        }
        data.append(0x2b)
        let write = I2C.TransferControlPayload(
            operation: .write,
            readLength: 0,
            address: 0x5a,
            writeData: data
        )
        XCTAssertEqual(
            write.compose(),
            [0x00, 0x00, 0x5a] + correctData
        )
    }

    func testReadTransaction() throws {
        // I2C transaction: read from slave 0x5a 6 bytes -> 0x01 0x06 0x5a
        let read = I2C.TransferControlPayload(
            operation: .read,
            readLength: 6,
            address: 0x5a,
            writeData: []
        )
        XCTAssertEqual(
            read.compose(),
            [0x01, 0x06, 0x5a]
        )

        // Control Command write:
        // 0x05 0x01 0x06 0x5a
        XCTAssertEqual(
            [UInt8](ControlService.ControlCommand.i2cTransfer(
                read
            ).compose()),
            [0x05, 0x01, 0x06, 0x5a]
        )
    }
    
    func testReadWriteTransaction() throws {
        // I2C transaction: for slave 0x12 write 1 byte (0x5a) and read 9 bytes -> 0x02 0x09 0x12 0x5a
        let readWrite = I2C.TransferControlPayload(
            operation: .readWrite,
            readLength: 9,
            address: 0x12,
            writeData: [0x5a]
        )
        XCTAssertEqual(
            readWrite.compose(),
            [0x02, 0x09, 0x12, 0x5a]
        )

        // Control Command write:
        // 0x05 0x02 0x09 0x12 0x5a
        XCTAssertEqual(
            [UInt8](ControlService.ControlCommand.i2cTransfer(
                readWrite
            ).compose()),
            [0x05, 0x02, 0x09, 0x12, 0x5a]
        )
    }
}
