//
//  MeshBearer.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/06.
//

import nRFMeshProvision

class MeshBearer<T: Bearer> {
    private var currentContinuation: CheckedContinuation<Void, Error>?
    private(set) var originalBearer: T

    init(for bearer: T) {
        originalBearer = bearer
    }

    func open() async throws {
        originalBearer.delegate = self
        return try await withCheckedThrowingContinuation { continuation in
            self.currentContinuation = continuation
            self.originalBearer.open()
        }
    }

    func close() async throws {
        originalBearer.delegate = self
        return try await withCheckedThrowingContinuation { continuation in
            self.currentContinuation = continuation
            self.originalBearer.close()
        }
    }
}

extension MeshBearer: BearerDelegate {
    func bearerDidOpen(_ bearer: Bearer) {
        if let currentContinuation {
            currentContinuation.resume(returning: ())
            self.currentContinuation = nil
        }
    }

    func bearer(_ bearer: Bearer, didClose error: Error?) {
        if let currentContinuation {
            if let error {
                currentContinuation.resume(throwing: error)
            }
            else {
                currentContinuation.resume(returning: ())
            }
        }
    }
}
