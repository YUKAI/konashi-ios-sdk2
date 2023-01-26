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
    func send(message: nRFMeshProvision.MeshMessage, to model: nRFMeshProvision.Model) async throws -> SendHandler
    @discardableResult
    func send(config: nRFMeshProvision.ConfigMessage) async throws -> SendHandler
    @discardableResult
    func waitForSendMessage() async throws -> SendMessage
    @discardableResult
    func waitForResponse(for messageType: any MeshMessage.Type) async throws -> ReceivedMessage
    func element(with address: nRFMeshProvision.Address) -> nRFMeshProvision.Element?
    func element(for element: NodeElement) -> nRFMeshProvision.Element?
    func model(for model: NodeModel) -> nRFMeshProvision.Model?
    func removeFromNetwork() async throws
    func reset() async throws -> SendHandler

    @discardableResult
    func setGattProxyEnabled(_ enabled: Bool) async throws -> NodeCompatible
    @discardableResult
    func addApplicationKey(_ applicationKey: ApplicationKey) async throws -> NodeCompatible
    @discardableResult
    func bindApplicationKey(_ applicationKey: ApplicationKey, to model: NodeModel) async throws -> NodeCompatible
}
