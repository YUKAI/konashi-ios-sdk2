//
//  MeshProvisioningQueue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/12.
//

import Combine
import Foundation
import nRFMeshProvision

public actor MeshProvisioningQueue {
    private static var readyToProvisionSubject = PassthroughSubject<any Provisionable, Never>()

    private static var queue = [any Provisionable]()

    public static func waitForProvision(_ provisioner: any Provisionable, attractFor: UInt8 = 5) async throws {
        if queue.isEmpty {
            queue.append(provisioner)
            _ = try await provisioner.identify(attractFor: attractFor)
            try await provisioner.provision()
            queue.removeFirst()
            readyToProvisionSubject.send(queue.removeFirst())
        }
        else {
            queue.append(provisioner)
            print("wait for provision: \(provisioner.uuid)")
            return try await withCheckedThrowingContinuation { continuation in
                Task {
                    do {
                        let readyProvisioner = try await readyToProvisionSubject
                            .filter { $0.uuid == provisioner.uuid }
                            .eraseToAnyPublisher()
                            .async()
                        print("start provision: \(readyProvisioner.uuid)")
                        _ = try await readyProvisioner.identify(attractFor: attractFor)
                        try await readyProvisioner.provision()
                        if queue.count > 0 {
                            readyToProvisionSubject.send(queue.removeFirst())
                        }
                        continuation.resume(returning: ())
                    }
                    catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
