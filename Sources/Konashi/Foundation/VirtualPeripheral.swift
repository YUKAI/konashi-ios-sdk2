//
//  VirtualPeripheral.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/08/20.
//

import Combine
import CoreBluetooth
import Foundation
import nRFMeshProvision

public class VirtualPeripheral: Peripheral {
    // MARK: Lifecycle

    init() {
        currentRSSI = -10
    }

    // MARK: Public

    public static var sharedLogOutput = LogOutput()

    public let identifier = UUID()
    public let services: [Service] = []

    @Published public private(set) var currentConnectionState: ConnectionState = .disconnected
    @Published public internal(set) var currentRSSI: NSNumber
    @Published public private(set) var currentProvisioningState: ProvisioningState?
    public lazy var operationErrorPublisher: AnyPublisher<Error, Never> = operationErrorSubject.eraseToAnyPublisher()
    public private(set) var meshNode: NodeCompatible?

    public var logOutput = LogOutput()

    public var name: String? {
        return "VirtualPeripheral-\(identifier.uuidString)"
    }

    public var statePublisher: Published<ConnectionState>.Publisher {
        return $currentConnectionState
    }

    public var rssiPublisher: Published<NSNumber>.Publisher {
        return $currentRSSI
    }

    public var provisioningStatePublisher: Published<nRFMeshProvision.ProvisioningState?>.Publisher {
        return $currentProvisioningState
    }

    public var state: ConnectionState {
        return currentConnectionState
    }

    public var provisioningState: nRFMeshProvision.ProvisioningState? {
        return currentProvisioningState
    }

    public var isOutdated: Bool {
        return false
    }

    public var isProvisionable: Bool {
        return false
    }

    public static func == (lhs: VirtualPeripheral, rhs: VirtualPeripheral) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(identifier)
    }

    public func connect(timeoutInterval: TimeInterval) async throws {
        currentConnectionState = .connecting
        currentConnectionState = .connected
    }

    public func disconnect(timeoutInterval: TimeInterval) async throws {
        currentConnectionState = .disconnecting
        currentConnectionState = .disconnected
    }

    public func recordError(_ error: Error) {
        operationErrorSubject.send(error)
    }

    public func write<WriteCommand>(characteristic: WriteableCharacteristic<WriteCommand>, command: WriteCommand, type writeType: CBCharacteristicWriteType, timeoutInterval: TimeInterval) async throws where WriteCommand: Command {}

    public func read<Value>(characteristic: ReadableCharacteristic<Value>, timeoutInterval: TimeInterval) async throws -> Value where Value: CharacteristicValue {
        throw MockError.someError
    }

    public func setMeshEnabled(_ enabled: Bool) async throws {}
    public func provision(for manager: MeshManager) async throws -> NodeCompatible {
        return MockNode()
    }

    public func readRSSI(repeats: Bool = false, interval: TimeInterval = 1) {
        setRSSI(NSNumber(value: Int.random(in: -100 ... -20)))
    }

    public func setRSSI(_ RSSI: NSNumber) {
        currentRSSI = RSSI
    }

    public func setAdvertisementData(_ advertisementData: [String: Any]) {}

    // MARK: Internal

    let operationErrorSubject = PassthroughSubject<Error, Never>()
}
