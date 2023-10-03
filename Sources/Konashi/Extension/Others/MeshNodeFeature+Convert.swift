//
//  MeshNodeFeature+Convert.swift
//
//
//  Created by Akira Matsuda on 2023/10/03.
//

import nRFMeshProvision

extension MeshNodeFeature {
    static func convert(_ features: NodeFeaturesState) -> MeshNodeFeature {
        return MeshNodeFeature(
            relay: State(rawValue: features.relay?.rawValue ?? 0) ?? .unknown,
            proxy: State(rawValue: features.proxy?.rawValue ?? 0) ?? .unknown,
            friend: State(rawValue: features.friend?.rawValue ?? 0) ?? .unknown,
            lowPower: State(rawValue: features.lowPower?.rawValue ?? 0) ?? .unknown
        )
    }
}
