//
//  StorageError.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/10.
//

import Foundation

public extension MeshManager {
    enum StorageError: LocalizedError {
        case failedToSaveNetworkSettings
        case failedToCreateMeshNetwork

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .failedToSaveNetworkSettings:
                return "Failed to save network settings to the local storage."
            case .failedToCreateMeshNetwork:
                return "Failed to create mesh network to the local storage."
            }
        }
    }
}
