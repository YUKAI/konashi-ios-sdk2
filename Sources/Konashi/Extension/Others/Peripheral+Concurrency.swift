//
//  Peripheral+Concurrency.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/12/12.
//

import CoreBluetooth

public extension Peripheral {
    // MARK: - Connection

    /// Connects to a peripheral.
    @discardableResult
    func connect() async throws -> any Peripheral {
        return try await withCheckedThrowingContinuation { continuation in
            connect().then {
                continuation.resume(returning: $0)
            }.catch { error in
                continuation.resume(throwing: error)
            }
        }
    }

    /// Disconnects from a peripheral.
    func disconnect() async throws {
        try await withCheckedThrowingContinuation { continuation in
            disconnect().then {
                continuation.resume(returning: $0)
            }.catch { error in
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Write/Read Command

    /// Writes command to the characteristic
    /// - Parameters:
    ///   - characteristic: The characteristic containing the value to write.
    ///   - command: The command to write.
    ///   - type: The type of write to execute. For a list of the possible types of writes to a characteristic’s value, see CBCharacteristicWriteType.
    @discardableResult
    func asyncWrite<WriteCommand: Command>(
        characteristic: WriteableCharacteristic<WriteCommand>,
        command: WriteCommand,
        type: CBCharacteristicWriteType = .withResponse
    ) async throws -> any Peripheral {
        return try await withCheckedThrowingContinuation { continuation in
            write(characteristic: characteristic, command: command, type: type).then {
                continuation.resume(returning: $0)
            }.catch { error in
                continuation.resume(throwing: error)
            }
        }
    }

    /// Retrieves the value of a specified characteristic.
    /// - Parameter characteristic: The characteristic whose value you want to read.
    /// - Returns: A promise object of read value.
    @discardableResult
    func asyncRead<Value: CharacteristicValue>(characteristic: ReadableCharacteristic<Value>) async throws -> Value {
        return try await withCheckedThrowingContinuation { continuation in
            read(characteristic: characteristic).then {
                continuation.resume(returning: $0)
            }.catch { error in
                continuation.resume(throwing: error)
            }
        }
    }
}
