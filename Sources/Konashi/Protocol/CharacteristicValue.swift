//
//  CharacteristicValue.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/10.
//

import Foundation

// MARK: - CharacteristicValue

/// An interface for value of characteristics.
public protocol CharacteristicValue {
    static var byteSize: UInt { get }

    static func isValid(bytes: [UInt8], method: ComparisonMethod) -> Bool
    static func parse(data: Data) -> Result<Self, Error>
}

// MARK: - ComparisonMethod

/// An enum that represents a method for comparing characteristic value.
public enum ComparisonMethod {
    case equal
    case lessThan
}

// MARK: - CharacteristicValueParseError

/// An enum that represents a reason of why a characteristic value could not be parsed correctly.
public enum CharacteristicValueParseError: LocalizedError {
    case invalidByteSize
    case invalidPinNumber
    case invalidLevel
    case invalidPHY
    case invalidPHYBitmask
}

public extension CharacteristicValue {
    /// Chacks a value is valid.
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
