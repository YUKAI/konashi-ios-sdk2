//
//  NodeCompatible.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/04.
//

import Foundation
import nRFMeshProvision

public protocol NodeCompatible {
    var unicastAddress: Address? { get }
    var deviceKey: Data? { get }
    var name: String? { get }
}
