//
//  MockCancellable.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/11.
//

import nRFMeshProvision

struct MockCancellable: SendCancellable {
    var opCode: UInt32 = 0x00
    var source: Address = 0x00
    var destination: Address = 0x00

    func cancel() {}
}
