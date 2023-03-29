//
//  NetworkError.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/10.
//

import Foundation

public extension MeshManager {
    enum NetworkError: Error, LocalizedError {
        case invalidMeshNetwork
        case noNetworkConnection
        case bearerIsClosed
        case timeout

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .invalidMeshNetwork:
                return "Mesh network should not be nil."
            case .noNetworkConnection:
                return "No network connection."
            case .bearerIsClosed:
                return "Network connection is closed."
            case .timeout:
                return "Operation timeout."
            }
        }
    }
}
