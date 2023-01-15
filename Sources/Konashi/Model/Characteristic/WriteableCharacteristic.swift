//
//  WriteableCharacteristic.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Foundation

/// A characteristic that can be written a value.
public class WriteableCharacteristic<Value: Command>: Characteristic {
    // MARK: Lifecycle

    init(serviceUUID: UUID, uuid: UUID) {
        self.serviceUUID = serviceUUID
        self.uuid = uuid
    }

    // MARK: Public

    public let serviceUUID: UUID
    public let uuid: UUID

    public func update(data: Data?) {}
}
