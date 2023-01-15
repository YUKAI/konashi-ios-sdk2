//
//  OperationError.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/10.
//

import Foundation

/// An error that a peripheral returns during configure / read / write operation.
public enum PeripheralOperationError: LocalizedError {
    case invalidReadValue
    case couldNotReadValue
    case couldNotFindCharacteristic

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case .invalidReadValue:
            return "Invalid read value."
        case .couldNotReadValue:
            return "Could not read value."
        case .couldNotFindCharacteristic:
            return "Could not find characteristics."
        }
    }
}
