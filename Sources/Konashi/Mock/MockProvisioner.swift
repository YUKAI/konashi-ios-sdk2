//
//  MockProvisioner.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/12/12.
//

import Combine
import CoreBluetooth
import nRFMeshProvision

// MARK: - MockProvisioner

class MockProvisioner: Provisionable {
    // MARK: Lifecycle

    init() {}

    // MARK: Internal

    let uuid = UUID()

    var state: Published<nRFMeshProvision.ProvisioningState?>.Publisher {
        return $internalState
    }

    var isOpen: Bool {
        return true
    }

    static func == (lhs: MockProvisioner, rhs: MockProvisioner) -> Bool {
        return lhs.uuid == rhs.uuid
    }

    func open() async throws {}

    func provision() async throws {
        try await Task.sleep(nanoseconds: 1 * 1000 * 1000 * 1000)
        internalState = .provisioning
        try await Task.sleep(nanoseconds: 1 * 1000 * 1000 * 1000)
        internalState = .requestingCapabilities
        try await Task.sleep(nanoseconds: 1 * 1000 * 1000 * 1000)
        if Bool.random() {
            internalState = .complete
        }
        else {
            internalState = .fail(MockError.someError)
            throw MockError.someError
        }
    }

    func identify(attractFor: UInt8) async throws {}

    // MARK: Private

    @Published private var internalState: nRFMeshProvision.ProvisioningState?
}
