//
//  Node+Find.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/12/26.
//

import nRFMeshProvision

extension nRFMeshProvision.Node {
    func findElement(of element: NodeElement) throws -> nRFMeshProvision.Element {
        guard let element = self.element(withAddress: element.address) else {
            throw MeshNode.OperationError.elementNotFound(element)
        }
        return element
    }
}
