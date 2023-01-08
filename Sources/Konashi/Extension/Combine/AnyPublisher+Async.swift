//
//  AnyPublisher+Async.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/12/26.
//

import Combine
import Foundation

// https://medium.com/geekculture/from-combine-to-async-await-c08bf1d15b77
enum AsyncError: Error {
    case finishedWithoutValue
}

extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            let uuid = UUID()
            var finishedWithoutValue = true
            SharedCancellable.shared.cancelablle[uuid] = first()
                .sink { result in
                    switch result {
                    case .finished:
                        if finishedWithoutValue {
                            continuation.resume(throwing: AsyncError.finishedWithoutValue)
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    SharedCancellable.shared.cancelablle[uuid]?.cancel()
                    SharedCancellable.shared.cancelablle.removeValue(forKey: uuid)
                } receiveValue: { value in
                    finishedWithoutValue = false
                    continuation.resume(with: .success(value))
                    SharedCancellable.shared.cancelablle[uuid]?.cancel()
                    SharedCancellable.shared.cancelablle.removeValue(forKey: uuid)
                }
        }
    }
}
