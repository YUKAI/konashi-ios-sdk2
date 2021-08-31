//
//  CharacteristicValue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/10.
//

import Foundation

public protocol CharacteristicValue {
    static var byteSize: UInt { get }

    static func isValid(bytes: [UInt8], method: ComparisonMethod) -> Bool
    static func parse(data: Data) -> Result<Self, Error>
}

public enum ComparisonMethod {
    case equal
    case lessThan
}

public enum CharacteristicValueParseError: LocalizedError {
    case invalidByteSize
    case invalidPinNumber
    case invalidDirection
    case invalidLevel
    case invalidPHY
    case invalidPHYBitmask
}

public extension CharacteristicValue {
    static func isValid(bytes: [UInt8], method: ComparisonMethod) -> Bool {
        switch method {
        case .equal:
            if bytes.count != byteSize {
                return false
            }
        case .lessThan:
            if bytes.count > byteSize {
                return false
            }
        }
        return true
    }
}
