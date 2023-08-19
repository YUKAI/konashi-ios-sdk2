//
//  ReadableCharacteristic.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/16.
//

import Combine
import Foundation

// MARK: - ReadableCharacteristic

/// A characteristic that stores value.
public class ReadableCharacteristic<Value: CharacteristicValue>: Characteristic {
    // MARK: Lifecycle

    init(serviceUUID: UUID, uuid: UUID) {
        self.serviceUUID = serviceUUID
        self.uuid = uuid
    }

    // MARK: Public

    public let serviceUUID: UUID
    public let uuid: UUID
    public private(set) lazy var value = valueSubject.eraseToAnyPublisher()
    public private(set) lazy var parseErrorPublisher = parseErrorSubject.eraseToAnyPublisher()

    public func update(data: Data?) {
        guard let data else {
            return
        }
        switch parse(data: data) {
        case let .success(value):
            valueSubject.send(value)
        case let .failure(error):
            parseErrorSubject.send(completion: .failure(error))
        }
    }

    // MARK: Internal

    var valueSubject = PassthroughSubject<Value, Never>()
    var parseErrorSubject = PassthroughSubject<Never, Error>()
}

public extension ReadableCharacteristic {
    func parse(data: Data) -> Result<Value, Error> {
        return Value.parse(data: data)
    }
}
