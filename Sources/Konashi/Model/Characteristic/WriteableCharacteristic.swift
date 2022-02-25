//
//  WriteableCharacteristic.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

/// A characteristic that can be written a value.
public class WriteableCharacteristic<Value: Command>: Characteristic {
    public let serviceUUID: UUID
    public let uuid: UUID

    init(serviceUUID: UUID, uuid: UUID) {
        self.serviceUUID = serviceUUID
        self.uuid = uuid
    }

    public func update(data: Data?) {}
}
