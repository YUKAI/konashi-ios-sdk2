//
//  CentralManager+Concurrency.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/13.
//

import CoreBluetooth

public extension CentralManager {
    /// Attempt to scan available peripherals.
    func scan() async {
        return await withCheckedContinuation { continuation in
            scan().then {
                continuation.resume(returning: ())
            }
        }
    }

    /// Attempt to find a peripheral.
    /// - Parameters:
    ///   - name: Peripheral name to find.
    ///   - timeoutInterval: The duration of timeout.
    /// - Returns: A peripheral that is found.
    func find(name: String, timeoutInterval: TimeInterval = 5, target: ScanTarget = .all) async throws -> any Peripheral {
        return try await withCheckedThrowingContinuation { continuation in
            find(name: name, timeoutInterval: timeoutInterval, target: target).then { peripheral in
                continuation.resume(returning: peripheral)
            }.catch { error in
                continuation.resume(throwing: error)
            }
        }
    }
}
