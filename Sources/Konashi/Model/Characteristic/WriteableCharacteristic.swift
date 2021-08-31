//
//  WriteableCharacteristic.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

public struct WriteableCharacteristic<Value: Command>: Characteristic {
    public let serviceUUID: UUID
    public let uuid: UUID

    public func update(data: Data?) {}
}
