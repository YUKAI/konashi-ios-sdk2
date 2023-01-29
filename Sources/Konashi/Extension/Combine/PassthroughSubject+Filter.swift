//
//  PassthroughSubject+Filter.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/04.
//

import Combine

public extension PassthroughSubject where Output == ReceivedMessage {
    func filter(for node: NodeCompatible) -> Publishers.Filter<PassthroughSubject> {
        return filter { node.element(with: $0.source) != nil }
    }
}

public extension PassthroughSubject where Output == SendMessage, Failure == MessageTransmissionError {
    func filter(for node: NodeCompatible) -> Publishers.Filter<PassthroughSubject> {
        return filter {
            node.element(with: $0.destination) != nil
        }
    }
}

public extension LogOutput {
    func applyLogLevel(_ logLevel: Int) -> Publishers.Filter<PassthroughSubject> {
        return filter {
            $0.level.priority >= logLevel
        }
    }

    func applyLogLevel(_ logLevel: Log.Level) -> Publishers.Filter<PassthroughSubject> {
        return filter {
            $0.level.priority >= logLevel.priority
        }
    }
}
