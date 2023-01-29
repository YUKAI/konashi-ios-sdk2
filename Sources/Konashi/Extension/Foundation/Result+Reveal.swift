//
//  Result+Reveal.swift
//  Konashi
//
//  Created by Akira Matsuda on 2023/01/29.
//

import Foundation

public extension Result {
    func onSuccess() throws -> Success {
        switch self {
        case let .success(result):
            return result
        case let .failure(error):
            throw error
        }
    }

    func onSuccess() -> Success? {
        switch self {
        case let .success(result):
            return result
        case .failure:
            return nil
        }
    }
    
    func onFailure() -> Failure? {
        switch self {
        case .success:
            return nil
        case let .failure(error):
            return error
        }
    }
}
