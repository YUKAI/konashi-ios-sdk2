//
//  SharedCancellable.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/08.
//

import Combine
import Foundation

actor SharedCancellable {
    // MARK: Internal

    static let shared = SharedCancellable()

    func store(_ cancellable: AnyCancellable, for uuid: UUID) {
        self.cancellable[uuid] = cancellable
    }

    func remove(_ uuid: UUID) -> AnyCancellable? {
        return cancellable.removeValue(forKey: uuid)
    }

    // MARK: Private

    private var cancellable = [UUID: AnyCancellable]()
}
