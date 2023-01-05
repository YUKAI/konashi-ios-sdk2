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
}
