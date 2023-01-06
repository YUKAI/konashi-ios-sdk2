//
//  NodeCompatible.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/04.
//

import Combine
import Foundation
import nRFMeshProvision

public protocol NodeCompatible {
    var unicastAddress: Address? { get }
    var deviceKey: Data? { get }
    var name: String? { get }
    var uuid: UUID? { get }
    var isProvisioner: Bool { get }
    var receivedMessageSubject: PassthroughSubject<ReceivedMessage, Never> { get }

    func updateName(_ name: String?) throws
    func element(for element: NodeElement) -> Element?
    func model(for model: NodeModel) -> Model?
    @discardableResult
    func sendConfig(_ message: ConfigMessage) throws -> MessageHandle
    @discardableResult
    func sendMessage(_ message: MeshMessage, to model: Model) throws -> MessageHandle
    func removeFromNetwork() throws
}

public protocol NodeElement {
    var index: Int { get }
}

public protocol NodeModel {
    var element: NodeElement { get }
    var identifier: UInt32 { get }
}

public enum NodeOperationError: Error, LocalizedError {
    case invalidNode
    case invalidParentElement(modelIdentifier: UInt16)
    case elementNotFound(_ address: NodeElement)
    case modelNotFound(_ model: NodeModel)

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
        }
    }
}
