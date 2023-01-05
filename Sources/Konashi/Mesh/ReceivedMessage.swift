//
//  ReceivedMessage.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/05.
//

import nRFMeshProvision

public struct ReceivedMessage {
    public let body: MeshMessage
    public let source: Address
    public let destination: Address

    public init(body: MeshMessage, source: Address, destination: Address) {
        self.body = body
        self.source = source
        self.destination = destination
    }
}
