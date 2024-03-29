//
//  SendCompletionHandler.swift
//  Konashi
//
//  Created by Akira Matsuda on 2023/01/29.
//

import Foundation
import nRFMeshProvision

// MARK: - SendCompletionHandler

public struct SendCompletionHandler {
    // MARK: Lifecycle

    public init(node: NodeCompatible, message: SendMessage) {
        self.node = node
        self.message = message
    }

    // MARK: Public

    public let node: NodeCompatible
    public let message: SendMessage
}

public extension SendCompletionHandler {
    @discardableResult
    func waitForResponse(for messageType: any MeshMessage.Type) async throws -> ReceivedMessage {
        return try await node.waitForResponse(for: messageType)
    }
}
