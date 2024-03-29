//
//  ProvisioningError.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/10.
//

import Foundation

public enum ProvisioningError: Error, LocalizedError {
    case unknown
    case invalidUnicastAddress
    case invalidCapability
    case unsupportedDevice

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error."
        case .invalidUnicastAddress:
            return "The device has an invalid unicast address."
        case .invalidCapability:
            return "Provisioning capability should not be nil."
        case .unsupportedDevice:
            return "The device is not supported."
        }
    }
}
