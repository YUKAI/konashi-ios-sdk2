//
//  PassthroughSubject+Filter.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/04.
//

import Combine

public extension PassthroughSubject where Output == MeshManager.ReceivedMessage {
    func receiveMessge(for node: MeshNode) -> Publishers.Filter<PassthroughSubject> {
        return filter { response in
            response.source == node.unicastAddress
        }
    }
}
