//
//  Element+Find.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/12/26.
//

import nRFMeshProvision

extension nRFMeshProvision.Element {
    func findModel(of model: MeshNode.Element.Model) throws -> nRFMeshProvision.Model {
        guard let meshModel = self.model(withModelId: UInt32(model.identifier)) else {
            throw MeshNode.OperationError.modelNotFound(model)
        }
        return meshModel
    }
}