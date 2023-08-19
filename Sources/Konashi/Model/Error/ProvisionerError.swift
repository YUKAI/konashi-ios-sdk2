//
//  ProvisionerError.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/13.
//

import Foundation

enum ProvisionerError: LocalizedError {
    case connectionError

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .connectionError:
            return "Failed to connect for provision. Bearer is not open."
        }
    }
}
