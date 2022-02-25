//
//  ReadableCharacteristic.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Combine
import Foundation

/// A characteristic that stores value.
public class ReadableCharacteristic<Value: CharacteristicValue>: Characteristic {
    public let serviceUUID: UUID
    public let uuid: UUID
    public var value = PassthroughSubject<Value, Never>()
    public var parseErrorSubject = PassthroughSubject<Never, Error>()

    init(serviceUUID: UUID, uuid: UUID) {
        self.serviceUUID = serviceUUID
        self.uuid = uuid
    }

    public func update(data: Data?) {
        guard let data = data else {
            return
        }
        switch parse(data: data) {
        case let .success(value):
            self.value.send(value)
        case let .failure(error):
            parseErrorSubject.send(completion: .failure(error))
        }
    }
}

public extension ReadableCharacteristic {
    func parse(data: Data) -> Result<Value, Error> {
        print(">>> read \(uuid) \n \(Value.parse(data: data)) \n \([UInt8](data).toHexString())")
        return Value.parse(data: data)
    }
}
