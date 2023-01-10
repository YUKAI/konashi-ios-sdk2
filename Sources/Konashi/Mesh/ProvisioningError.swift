//
//  ProvisioningError.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/10.
//

import Foundation

extension MeshProvisioner {
    public enum ProvisioningError: Error, LocalizedError {
        case unknown
        case invalidUnicastAddress
        case invalidCapability
        case unsupportedDevice

        public var errorDescription: String? {
            switch self {
            case .unknown:
                return "Unknown error."
            case .invalidUnicastAddress:
                return "The device has invalid unicast address."
            case .invalidCapability:
                return "Provisioning capability should not be nil."
            case .unsupportedDevice:
                return "The device is not able to provision."
            }
        }
    }
}
