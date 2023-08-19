//
//  Peripheral.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/12/12.
//

import Combine
import CombineExt
import CoreBluetooth
import nRFMeshProvision
import Promises

extension Peripheral {
    static func == (lhs: any Peripheral, rhs: any Peripheral) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// MARK: - Peripheral

public protocol Peripheral: Hashable, AnyObject, Loggable {
    /// A name of a peripheral.
    var name: String? { get }

    var identifier: UUID { get }

    /// A collection of services of a peripheral.
    var services: [Service] { get }

    /// A connection status of a peripheral.
    var statePublisher: Published<ConnectionState>.Publisher { get }
    var rssiPublisher: Published<NSNumber>.Publisher { get }
    var provisioningStatePublisher: Published<ProvisioningState?>.Publisher { get }
    var operationErrorPublisher: AnyPublisher<Error, Never> { get }
    var state: ConnectionState { get }
    var provisioningState: ProvisioningState? { get }
    var isOutdated: Bool { get }
    var isProvisionable: Bool { get }

    // TODO: Add document
    var meshNode: (any NodeCompatible)? { get }

    // MARK: - Connection

    func recordError(_ error: Error)

    // TODO: Make async function
    /// Connects to a peripheral.
    @discardableResult
    func connect() -> Promise<any Peripheral>

    // TODO: Make async function
    /// Disconnects from a peripheral.
    @discardableResult
    func disconnect() -> Promise<Void>

    // MARK: - Write/Read Command

    // TODO: Make async function
    /// Writes command to the characteristic
    /// - Parameters:
    ///   - characteristic: The characteristic containing the value to write.
    ///   - command: The command to write.
    ///   - type: The type of write to execute. For a list of the possible types of writes to a characteristic’s value, see CBCharacteristicWriteType.
    @discardableResult
    func write<WriteCommand: Command>(characteristic: WriteableCharacteristic<WriteCommand>, command: WriteCommand, type writeType: CBCharacteristicWriteType) -> Promise<any Peripheral>

    // TODO: Make async function
    /// Retrieves the value of a specified characteristic.
    /// - Parameter characteristic: The characteristic whose value you want to read.
    /// - Returns: A promise object of read value.
    @discardableResult
    func read<Value: CharacteristicValue>(characteristic: ReadableCharacteristic<Value>) -> Promise<Value>

    // TODO: Add document
    func setMeshEnabled(_ enabled: Bool) async throws

    @discardableResult
    func provision(for manager: MeshManager) async throws -> NodeCompatible

    func setRSSI(_ RSSI: NSNumber)
    func setAdvertisementData(_ advertisementData: [String: Any])
}

public extension Peripheral {
    var completeName: String {
        return "\(name ?? "Unknown"): \(identifier)"
    }
}
