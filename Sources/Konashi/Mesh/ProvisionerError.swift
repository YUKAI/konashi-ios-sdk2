//
//  ProvisionerError.swift
//  Konashi
//
//  Created by Akira Matsuda on 2023/01/13.
//

import Foundation

enum ProvisionerError: Error, LocalizedError {
    case connectionError

    var errorDescription: String? {
        switch self {
        case .connectionError:
            return "Could not connect to node."
        }
    }
}
