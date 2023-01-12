//
//  SendCancellable.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/11.
//

import nRFMeshProvision

public protocol SendCancellable {
    var opCode: UInt32 { get }
    var source: Address { get }
    var destination: Address { get }

    func cancel()
}
