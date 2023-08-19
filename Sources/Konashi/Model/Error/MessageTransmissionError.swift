//
//  MessageTransmissionError.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/06.
//

import Foundation

public struct MessageTransmissionError: LocalizedError {
    public let error: Error
    public let message: SendMessage

    public var errorDescription: String? {
        return "Failed to send the message. Reason: \(error.localizedDescription). Message: \(message.body), to \(message.destination)"
    }
}
