//
//  AnyPublisher+Async.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2022/12/26.
//

import Combine
import Foundation

// MARK: - AsyncError

// https://medium.com/geekculture/from-combine-to-async-await-c08bf1d15b77
enum AsyncError: Error {
    case finishedWithoutValue
}

extension AnyPublisher {
    func konashi_makeAsync() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                let uuid = UUID()
                var finishedWithoutValue = true
                await SharedCancellable.shared.store(
                    first()
                        .sink { result in
                            switch result {
                            case .finished:
                                if finishedWithoutValue {
                                    continuation.resume(throwing: AsyncError.finishedWithoutValue)
                                }
                            case let .failure(error):
                                continuation.resume(throwing: error)
                            }

                            Task { await SharedCancellable.shared.remove(uuid)?.cancel() }
                        } receiveValue: { value in
                            finishedWithoutValue = false
                            continuation.resume(with: .success(value))
                            Task { await SharedCancellable.shared.remove(uuid)?.cancel() }
                        },
                    for: uuid
                )
            }
        }
    }
}
