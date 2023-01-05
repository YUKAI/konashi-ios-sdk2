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
    var uuid: UUID? { get }
    var isProvisioner: Bool { get }
    
    func element(for element: NodeElement) -> Element?
    func model(for model: NodeModel) -> Model?
}

public protocol NodeElement {
    var address: Address { get }
}

public protocol NodeModel {
    var element: NodeElement { get }
    var identifier: UInt32 { get }
}
