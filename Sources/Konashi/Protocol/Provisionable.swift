//
//  Provisionable.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/11.
//

import Combine
import Foundation
import nRFMeshProvision

public protocol Provisionable {
    var uuid: UUID { get }
    var state: Published<ProvisioningState?>.Publisher { get }
    var isOpen: Bool { get }

    func open() async throws
    func identify(attractFor: UInt8) async throws
    func provision() async throws
}
