//
//  SendMessage.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/06.
//

import nRFMeshProvision

public struct SendMessage {
    public let body: MeshMessage
    public let from: Element
    public let destination: Address
    
    init(body: MeshMessage, from: Element, destination: Address) {
        self.body = body
        self.from = from
        self.destination = destination
    }
}
