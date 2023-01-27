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
    func find(name: String, timeoutInterval: TimeInterval = 5) async throws -> any Peripheral {
        return try await withCheckedThrowingContinuation { continuation in
            find(name: name, timeoutInterval: timeoutInterval).then { peripheral in
                continuation.resume(returning: peripheral)
            }.catch { error in
                continuation.resume(throwing: error)
            }
        }
    }

    /// Stop scanning peripherals.
    func stopScan() async {
        return await withCheckedContinuation { continuation in
            stopScan().then {
                continuation.resume(returning: ())
            }
        }
    }
}
