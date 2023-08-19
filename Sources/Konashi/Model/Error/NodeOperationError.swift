//
//  NodeOperationError.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/10.
//

import Foundation
import nRFMeshProvision

public enum NodeOperationError: LocalizedError {
    case invalidNode
    case invalidParentElement(modelIdentifier: UInt16)
    case elementNotFound(_ address: NodeElement)
    case modelNotFound(_ model: NodeModel)
    case noCompositionData

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case .invalidNode:
            return "Node should not be nil."
        case let .invalidParentElement(modelIdentifier):
            return "A parent element of the model (identifier: \(modelIdentifier)) should not be nil."
        case let .elementNotFound(address):
            return "Failed to find the element (address: \(address))."
        case let .modelNotFound(model):
            return "Faild to find the model (identifier: \(model.identifier))."
        case .noCompositionData:
            return "Node needs to receive composition data before the operation."
        }
    }
}
