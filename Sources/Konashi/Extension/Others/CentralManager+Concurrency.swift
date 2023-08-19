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
}
