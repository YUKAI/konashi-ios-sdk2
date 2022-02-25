//
//  UARTDataSendResult.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

/// Receive when UART send data has finished sending.
public struct UARTDataSendResult: CharacteristicValue, Hashable {
    public static var byteSize: UInt {
        return 1
    }

    /// Whether sending data or not.
    public let sendDone: Bool

    public static func parse(data: Data) -> Result<UARTDataSendResult, Error> {
        let bytes = [UInt8](data)
        if isValid(bytes: bytes, method: .equal) {
            return .failure(CharacteristicValueParseError.invalidByteSize)
        }
        return .success(UARTDataSendResult(sendDone: bytes[0] == 1))
    }
}
