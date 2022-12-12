//
//  Peripheral.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/12/12.
//

import Combine
import CombineExt
import CoreBluetooth
import Promises

/// A confition of a peripheral.
public enum ConnectionStatus: Hashable {
    public static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .error(error):
            hasher.combine(error.localizedDescription)
        case .disconnected:
            hasher.combine("disconnected")
        case .connecting:
            hasher.combine("connecting")
        case .connected:
            hasher.combine("connected")
        case .readyToUse:
            hasher.combine("readyToUse")
        }
    }

    case error(Error)
    case disconnected
    case connecting
    case connected
    case readyToUse
}

extension Peripheral {
    static func == (lhs: any Peripheral, rhs: any Peripheral) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

public protocol Peripheral: Hashable {
    /// A name of a peripheral.
    var name: String? { get }

    /// A collection of services of a peripheral.
    var services: [Service] { get }

    /// A connection status of a peripheral.
    var status: ConnectionStatus { get }

    // MARK: - Connection

    /// Connects to a peripheral.
    @discardableResult
    func connect() -> Promise<any Peripheral>

    /// Disconnects from a peripheral.
    @discardableResult
    func disconnect() -> Promise<Void>

    // MARK: - Write/Read Command

    /// Writes command to the characteristic
    /// - Parameters:
    ///   - characteristic: The characteristic containing the value to write.
    ///   - command: The command to write.
    ///   - type: The type of write to execute. For a list of the possible types of writes to a characteristic’s value, see CBCharacteristicWriteType.
    @discardableResult
    func write<WriteCommand: Command>(characteristic: WriteableCharacteristic<WriteCommand>, command: WriteCommand, type: CBCharacteristicWriteType) -> Promise<any Peripheral>

    /// Retrieves the value of a specified characteristic.
    /// - Parameter characteristic: The characteristic whose value you want to read.
    /// - Returns: A promise object of read value.
    @discardableResult
    func read<Value: CharacteristicValue>(characteristic: ReadableCharacteristic<Value>) -> Promise<Value>
}
