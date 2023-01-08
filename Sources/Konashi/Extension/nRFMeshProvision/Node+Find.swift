//
//  Node+Find.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/12/26.
//

import nRFMeshProvision

extension nRFMeshProvision.Node {
    func findElement(of element: NodeElement) throws -> nRFMeshProvision.Element {
        guard let element = elements[safe: element.index] else {
            throw NodeOperationError.elementNotFound(element)
        }
        return element
    }
}
