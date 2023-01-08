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
    var elements: [nRFMeshProvision.Element] { get }
    var receivedMessageSubject: PassthroughSubject<ReceivedMessage, Never> { get }

    func updateName(_ name: String?) throws
    @discardableResult
    func send(message: nRFMeshProvision.MeshMessage, to model: nRFMeshProvision.Model) async throws -> NodeCompatible
    @discardableResult
    func send(config: nRFMeshProvision.ConfigMessage) async throws -> NodeCompatible
    @discardableResult
    func waitForSendMessage() async throws -> SendMessage
    @discardableResult
    func waitForResponse<T>(for messageType: T) async throws -> ReceivedMessage
    func element(with address: nRFMeshProvision.Address) -> nRFMeshProvision.Element?
    func element(for element: NodeElement) -> nRFMeshProvision.Element?
    func model(for model: NodeModel) -> nRFMeshProvision.Model?
    func removeFromNetwork() throws

    @discardableResult
    func setGattProxyEnabled(_ enabled: Bool) async throws -> NodeCompatible
    @discardableResult
    func addApplicationKey(_ applicationKey: ApplicationKey) async throws -> NodeCompatible
    @discardableResult
    func bindApplicationKey(_ applicationKey: ApplicationKey, to model: NodeModel) async throws -> NodeCompatible
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
    case noCompositionData

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
