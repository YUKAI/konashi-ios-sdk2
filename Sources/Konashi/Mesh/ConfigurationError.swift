//
//  ConfigurationError.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/10.
//

import Foundation

extension MeshManager {
    public enum ConfigurationError: Error, LocalizedError {
        case invalidUnprovisionedDevice
        case invalidNetworkKey
        case invalidApplicationKey

        public var errorDescription: String? {
            switch self {
            case .invalidUnprovisionedDevice:
                return "Failed to convert advertisement data."
            case .invalidNetworkKey:
                return "Network key shoud not be nil."
            case .invalidApplicationKey:
                return "Application key shoud not be nil."
            }
        }
    }
}
