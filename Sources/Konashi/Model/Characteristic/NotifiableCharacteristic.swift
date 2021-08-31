//
//  NotifiableCharacteristic.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Combine
import Foundation

public class NotifiableCharacteristic<Value: CharacteristicValue>: Characteristic {
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

public extension NotifiableCharacteristic {
    func parse(data: Data) -> Result<Value, Error> {
        print(">>> notify \(uuid) \n \(Value.parse(data: data)) \n \([UInt8](data).toHexString())")
        return Value.parse(data: data)
    }
}
