//
//  MeshNodeFeature.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/10/03.
//

import Foundation
import nRFMeshProvision

public struct MeshNodeFeature {
    public enum State: UInt8 {
        /// Could not determine the feature is available.
        case unknown
        /// The feature is disabled.
        case notEnabled
        /// The feature is enabled.
        case enabled
        /// The feature is not supported by the Node.
        case notSupported
    }

    /// The state of Relay feature
    public internal(set) var relay: State = .unknown
    /// The state of Proxy feature
    public internal(set) var proxy: State = .unknown
    /// The state of Friend feature
    public internal(set) var friend: State = .unknown
    /// The state of Low Power feature
    public internal(set) var lowPower: State = .unknown

    public static func makeUnknownFeature() -> MeshNodeFeature {
        return MeshNodeFeature()
    }
}
