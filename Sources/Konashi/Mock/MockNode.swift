//
//  MockNode.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/04.
//

import Combine
import Foundation
import nRFMeshProvision

public class MockNode: NodeCompatible, ModelDelegate {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public var isConfigured = false
    public weak var peripheral: (any Peripheral)?

    public private(set) lazy var receivedMessagePublisher: AnyPublisher<
        Result<ReceivedMessage, MessageTransmissionError>, Never
    > = receivedMessageSubject.eraseToAnyPublisher()

    public let uuid = UUID()

    // MARK: -

    public var messageTypes = [UInt32: nRFMeshProvision.MeshMessage.Type]()
    public var isSubscriptionSupported = false
    public var publicationMessageComposer: MessageComposer?

    public var feature: MeshNodeFeature {
        return MeshNodeFeature()
    }

    public var isProvisioner: Bool {
        return false
    }

    public var unicastAddress: nRFMeshProvision.Address? {
        return 0x1001
    }

    public var deviceKey: Data? {
        Data.random128BitKey()
    }

    public var elements: [nRFMeshProvision.Element] {
        return []
    }

    public var name: String? {
        return internalName
    }

    public func updateName(_ name: String?) throws {
        internalName = name
    }

    public func element(for element: Konashi.NodeElement) -> nRFMeshProvision.Element? {
        return Element(models: [])
    }

    public func element(with address: nRFMeshProvision.Address) -> nRFMeshProvision.Element? {
        return Element(models: [])
    }

    public func model(for model: Konashi.NodeModel) -> nRFMeshProvision.Model? {
        return Model(vendorModelId: 0x00, companyId: 0x00, delegate: self)
    }

    public func send(message: nRFMeshProvision.MeshMessage, to model: nRFMeshProvision.Model) async throws -> SendHandler {
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

    public func send(config: nRFMeshProvision.ConfigMessage) async throws -> SendHandler {
        return SendHandler(node: self, handle: MockCancellable())
    }

    public func waitForSendMessage(_ handler: SendHandler) async throws -> SendCompletionHandler {
        return SendCompletionHandler(node: self, message: SendMessage(body: MockMessage(), from: Element(models: []), destination: 0x00))
    }

    public func waitForResponse(for messageType: some Any) async throws -> ReceivedMessage {
        return ReceivedMessage(body: MockMessage(), source: 0x00, destination: 0x00)
    }

    public func removeFromNetwork(_ method: RemoveMethod) throws {
        throw MockNodeError.noOperation
    }

    public func setGattProxyEnabled(_ enabled: Bool) async throws -> SendHandler {
        return SendHandler(node: self, handle: MockCancellable())
    }

    public func addApplicationKey(_ applicationKey: nRFMeshProvision.ApplicationKey) async throws -> SendHandler {
        return SendHandler(node: self, handle: MockCancellable())
    }

    public func bindApplicationKey(_ applicationKey: nRFMeshProvision.ApplicationKey, to model: Konashi.NodeModel) async throws -> SendHandler {
        return SendHandler(node: self, handle: MockCancellable())
    }

    public func reset() async throws -> SendHandler {
        return SendHandler(node: self, handle: MockCancellable())
    }

    public func model(
        _ model: nRFMeshProvision.Model,
        didReceiveAcknowledgedMessage request: nRFMeshProvision.AcknowledgedMeshMessage,
        from source: nRFMeshProvision.Address,
        sentTo destination: nRFMeshProvision.MeshAddress
    ) throws -> nRFMeshProvision.MeshMessage {
        throw MockNodeError.noOperation
    }

    public func model(
        _ model: nRFMeshProvision.Model,
        didReceiveUnacknowledgedMessage message: nRFMeshProvision.MeshMessage,
        from source: nRFMeshProvision.Address,
        sentTo destination: nRFMeshProvision.MeshAddress
    ) {}

    public func model(
        _ model: nRFMeshProvision.Model,
        didReceiveResponse response: nRFMeshProvision.MeshMessage,
        toAcknowledgedMessage request: nRFMeshProvision.AcknowledgedMeshMessage,
        from source: nRFMeshProvision.Address
    ) {}

    // MARK: Internal

    enum MockNodeError: Error {
        case noOperation
    }

    var receivedMessageSubject = PassthroughSubject<Result<ReceivedMessage, MessageTransmissionError>, Never>()

    // MARK: Private

    private var internalName: String? = "knAB05A9"
}
