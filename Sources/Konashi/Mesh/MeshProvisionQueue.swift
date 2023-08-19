//
//  MeshProvisionQueue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/12.
//

import Combine
import Foundation

public final actor MeshProvisionQueue {
    // MARK: Public

    public static var isProvisioningPublisher = isProvisioningSubject.eraseToAnyPublisher()

    public static var isProvisioning: Bool {
        return isProvisioningSubject.value
    }

    public static func waitForProvision(_ provisioner: any Provisionable, attractFor: UInt8 = 5) async throws {
        if queue.isEmpty {
            queue.append(provisioner)
            do {
                try await provision(provisioner, attractFor: attractFor)
                queue.removeFirst()
                checkNextProvisioner()
            }
            catch {
                queue.removeFirst()
                checkNextProvisioner()
                throw error
            }
        }
        else {
            queue.append(provisioner)
            return try await withCheckedThrowingContinuation { continuation in
                Task {
                    do {
                        let readyProvisioner = try await readyToProvisionSubject
                            .filter { $0.uuid == provisioner.uuid }
                            .eraseToAnyPublisher()
                            .konashi_makeAsync()
                        try await provision(readyProvisioner, attractFor: attractFor)
                        checkNextProvisioner()
                        continuation.resume(returning: ())
                    }
                    catch {
                        checkNextProvisioner()
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: Internal

    static var isProvisioningSubject = CurrentValueSubject<Bool, Never>(false)

    // MARK: Private

    private static var readyToProvisionSubject = PassthroughSubject<any Provisionable, Never>()
    private static var queue = [any Provisionable]()

    private static func provision(_ provisioner: any Provisionable, attractFor: UInt8) async throws {
        isProvisioningSubject.send(true)
        try await provisioner.open()
        _ = try await provisioner.identify(attractFor: attractFor)
        try await provisioner.provision()
    }

    private static func checkNextProvisioner() {
        if !queue.isEmpty {
            isProvisioningSubject.send(true)
            readyToProvisionSubject.send(queue.removeFirst())
        }
        else {
            isProvisioningSubject.send(false)
        }
    }
}
