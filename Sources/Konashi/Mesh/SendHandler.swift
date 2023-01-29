//
//  SendHandler.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/11.
//

import nRFMeshProvision

// MARK: - SendHandler

public struct SendHandler {
    // MARK: Lifecycle

    public init(node: NodeCompatible, handle: SendCancellable) {
        self.node = node
        self.handle = handle
    }

    // MARK: Public

    public let node: NodeCompatible

    public var opCode: UInt32 {
        return handle.opCode
    }

    public var source: Address {
        return handle.source
    }

    public var destination: Address {
        return handle.destination
    }

    @discardableResult
    public func waitForSendMessage() async throws -> Result<SendCompletionHandler, MessageTransmissionError> {
        return try await node.waitForSendMessage(self)
    }

    @discardableResult
    public func waitForResponse(for messageType: any MeshMessage.Type) async throws -> ReceivedMessage {
        return try await node.waitForResponse(for: messageType)
    }

    public func cancel() {
        handle.cancel()
    }

    // MARK: Internal

    let handle: SendCancellable
}

extension SendHandler {
    func isEqualTo(_ message: SendMessage) -> Bool {
        return opCode == message.body.opCode && source == message.from.parentNode?.unicastAddress && destination == message.destination
    }
}
