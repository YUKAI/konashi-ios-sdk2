//
//  MockNode.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/04.
//

import Combine
import Foundation
import nRFMeshProvision

class MockNode: NodeCompatible, ModelDelegate {
    // MARK: Internal

    enum MockNodeError: Error {
        case noOperation
    }

    var isConfigured = false

    weak var peripheral: (any Peripheral)?

    var receivedMessageSubject = PassthroughSubject<Result<ReceivedMessage, MessageTransmissionError>, Never>()
    private(set) lazy var receivedMessagePublisher: AnyPublisher<
        Result<ReceivedMessage, MessageTransmissionError>, Never
    > = receivedMessageSubject.eraseToAnyPublisher()

    let uuid = UUID()

    // MARK: -

    var messageTypes = [UInt32: nRFMeshProvision.MeshMessage.Type]()
    var isSubscriptionSupported = false
    var publicationMessageComposer: MessageComposer?

    var isProvisioner: Bool {
        return false
    }

    var unicastAddress: nRFMeshProvision.Address? {
        return 0x1001
    }

    var deviceKey: Data? {
        Data.random128BitKey()
    }

    var elements: [nRFMeshProvision.Element] {
        return []
    }

    var name: String? {
        return internalName
    }

    func updateName(_ name: String?) throws {
        internalName = name
    }

    func element(for element: Konashi.NodeElement) -> nRFMeshProvision.Element? {
        return Element(models: [])
    }

    func element(with address: nRFMeshProvision.Address) -> nRFMeshProvision.Element? {
        return Element(models: [])
    }

    func model(for model: Konashi.NodeModel) -> nRFMeshProvision.Model? {
        return Model(vendorModelId: 0x00, companyId: 0x00, delegate: self)
    }

    func send(message: nRFMeshProvision.MeshMessage, to model: nRFMeshProvision.Model) async throws -> SendHandler {
        if message is SensorGet {
            let message = ReceivedMessage(
                body: SensorStatus(MockValue.sensorValues()),
                source: unicastAddress!,
                destination: 0x0000
            )
            receivedMessageSubject.send(.success(message))
        }
        return SendHandler(node: self, handle: MockCancellable())
    }

    func send(config: nRFMeshProvision.ConfigMessage) async throws -> SendHandler {
        return SendHandler(node: self, handle: MockCancellable())
    }

    func waitForSendMessage(_ handler: SendHandler) async throws -> SendCompletionHandler {
        return SendCompletionHandler(node: self, message: SendMessage(body: MockMessage(), from: Element(models: []), destination: 0x00))
    }

    func waitForResponse(for messageType: some Any) async throws -> ReceivedMessage {
        return ReceivedMessage(body: MockMessage(), source: 0x00, destination: 0x00)
    }

    func removeFromNetwork(_ method: RemoveMethod) throws {
        throw MockNodeError.noOperation
    }

    func setGattProxyEnabled(_ enabled: Bool) async throws -> SendHandler {
        return SendHandler(node: self, handle: MockCancellable())
    }

    func addApplicationKey(_ applicationKey: nRFMeshProvision.ApplicationKey) async throws -> SendHandler {
        return SendHandler(node: self, handle: MockCancellable())
    }

    func bindApplicationKey(_ applicationKey: nRFMeshProvision.ApplicationKey, to model: Konashi.NodeModel) async throws -> SendHandler {
        return SendHandler(node: self, handle: MockCancellable())
    }

    func reset() async throws -> SendHandler {
        return SendHandler(node: self, handle: MockCancellable())
    }

    func model(
        _ model: nRFMeshProvision.Model,
        didReceiveAcknowledgedMessage request: nRFMeshProvision.AcknowledgedMeshMessage,
        from source: nRFMeshProvision.Address,
        sentTo destination: nRFMeshProvision.MeshAddress
    ) throws -> nRFMeshProvision.MeshMessage {
        throw MockNodeError.noOperation
    }

    func model(
        _ model: nRFMeshProvision.Model,
        didReceiveUnacknowledgedMessage message: nRFMeshProvision.MeshMessage,
        from source: nRFMeshProvision.Address,
        sentTo destination: nRFMeshProvision.MeshAddress
    ) {}

    func model(
        _ model: nRFMeshProvision.Model,
        didReceiveResponse response: nRFMeshProvision.MeshMessage,
        toAcknowledgedMessage request: nRFMeshProvision.AcknowledgedMeshMessage,
        from source: nRFMeshProvision.Address
    ) {}

    // MARK: Private

    private var internalName: String? = "knAB05A9"
}
