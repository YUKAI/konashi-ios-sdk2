//
//  SendHandler.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/11.
//

import nRFMeshProvision

public class SendHandler {
    public let node: NodeCompatible
    let handle: SendCancellable

    public var opCode: UInt32 {
        return handle.opCode
    }

    public var source: Address {
        return handle.source
    }

    public var destination: Address {
        return handle.destination
    }
    
    public init(node: NodeCompatible, handle: SendCancellable) {
        self.node = node
        self.handle = handle
    }

    @discardableResult
    public func waitForResponse<T>(for messageType: T) async throws -> ReceivedMessage {
        return try await node.waitForResponse(for: messageType)
    }
    
    public func cancel() {
        handle.cancel()
    }
}
