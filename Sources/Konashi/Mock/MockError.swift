//
//  MockError.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/05.
//

import Foundation

enum MockError: Error, LocalizedError {
    case someError

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .someError:
            return "something wrong"
        }
    }
}
