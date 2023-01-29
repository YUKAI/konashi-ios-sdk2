//
//  NodeCompatible.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/04.
//

import Combine
import Foundation
import nRFMeshProvision

// MARK: - RemoveMethod

public enum RemoveMethod {
    case force
    case strict
}

// MARK: - NodeCompatible

public protocol NodeCompatible {
    var peripheral: (any Peripheral)? { get }
    var unicastAddress: Address? { get }
    var deviceKey: Data? { get }
    var name: String? { get }
    var uuid: UUID { get }
    var isProvisioner: Bool { get }
    var elements: [nRFMeshProvision.Element] { get }
    var receivedMessageSubject: PassthroughSubject<Result<ReceivedMessage, MessageTransmissionError>, Never> { get }
    var isConfigured: Bool { get set }

    func updateName(_ name: String?) async throws
    @discardableResult
    func send(message: nRFMeshProvision.MeshMessage, to model: nRFMeshProvision.Model) async throws -> SendHandler
    @discardableResult
    func send(config: nRFMeshProvision.ConfigMessage) async throws -> SendHandler
    @discardableResult
    func waitForSendMessage(_ handler: SendHandler) async throws -> SendCompletionHandler
    @discardableResult
    func waitForResponse(for messageType: any MeshMessage.Type) async throws -> ReceivedMessage
    func element(with address: nRFMeshProvision.Address) -> nRFMeshProvision.Element?
    func element(for element: NodeElement) -> nRFMeshProvision.Element?
    func model(for model: NodeModel) -> nRFMeshProvision.Model?
    func removeFromNetwork(_ method: RemoveMethod) async throws
    @discardableResult
    func reset() async throws -> SendHandler

    @discardableResult
    func setGattProxyEnabled(_ enabled: Bool) async throws -> SendHandler
    @discardableResult
    func addApplicationKey(_ applicationKey: ApplicationKey) async throws -> SendHandler
    @discardableResult
    func bindApplicationKey(_ applicationKey: ApplicationKey, to model: NodeModel) async throws -> SendHandler
}
