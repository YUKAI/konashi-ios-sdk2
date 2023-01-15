//
//  MeshProvisionQueue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/12.
//

import Combine
import Foundation

public actor MeshProvisionQueue {
    // MARK: Public

    public static var isProvisioning = CurrentValueSubject<Bool, Never>(false)

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
                            .async()
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

    // MARK: Private

    private static var readyToProvisionSubject = PassthroughSubject<any Provisionable, Never>()
    private static var queue = [any Provisionable]()

    private static func provision(_ provisioner: any Provisionable, attractFor: UInt8) async throws {
        isProvisioning.send(true)
        try await provisioner.open()
        _ = try await provisioner.identify(attractFor: attractFor)
        try await provisioner.provision()
    }

    private static func checkNextProvisioner() {
        if !queue.isEmpty {
            isProvisioning.send(true)
            readyToProvisionSubject.send(queue.removeFirst())
        }
        else {
            isProvisioning.send(false)
        }
    }
}
