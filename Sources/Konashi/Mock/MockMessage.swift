//
//  MockMessage.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/08.
//

import Foundation
import nRFMeshProvision

struct MockMessage: StaticMeshMessage {
    // MARK: Lifecycle

    init() {}
    init?(parameters: Data) {}

    // MARK: Internal

    static var opCode: UInt32 = 0

    var parameters: Data?
}
