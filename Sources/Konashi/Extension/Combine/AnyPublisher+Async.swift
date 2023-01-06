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

fileprivate class AnyPublisherCancellable {
    static let shared = AnyPublisherCancellable()
    var cancelablle = [UUID: AnyCancellable]()
}

extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            let uuid = UUID()
            var finishedWithoutValue = true
            AnyPublisherCancellable.shared.cancelablle[uuid] = first()
                .sink { result in
                    switch result {
                    case .finished:
                        if finishedWithoutValue {
                            continuation.resume(throwing: AsyncError.finishedWithoutValue)
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    AnyPublisherCancellable.shared.cancelablle[uuid]?.cancel()
                    AnyPublisherCancellable.shared.cancelablle.removeValue(forKey: uuid)
                } receiveValue: { value in
                    finishedWithoutValue = false
                    continuation.resume(with: .success(value))
                    AnyPublisherCancellable.shared.cancelablle[uuid]?.cancel()
                    AnyPublisherCancellable.shared.cancelablle.removeValue(forKey: uuid)
                }
        }
    }
}
