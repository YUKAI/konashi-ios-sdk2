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

    func element(for element: NodeElement) -> Element?
    func model(for model: NodeModel) -> Model?
    func sendConfig(_ message: ConfigMessage) throws -> MessageHandle
    func sendMessage(_ message: MeshMessage, to model: Model) throws -> MessageHandle
}

public protocol NodeElement {
    var address: Address { get }
}

public protocol NodeModel {
    var element: NodeElement { get }
    var identifier: UInt32 { get }
}

public enum NodeOperationError: Error {
    case invalidNode
    case invalidParentElement
    case elementNotFound(_ address: NodeElement)
    case modelNotFound(_ model: NodeModel)
}
