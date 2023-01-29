//
//  AnyPublisher+ApplyLogLevel.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/30.
//

import Combine

public extension AnyPublisher<Log, Never> {
    func applyLogLevel(_ logLevel: Log.Level) -> Publishers.Filter<AnyPublisher> {
        return filter {
            $0.level.priority >= logLevel.priority
        }
    }
}
