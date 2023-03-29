//
//  NodeModel.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/10.
//

import Foundation

public protocol NodeModel {
    var element: NodeElement { get }
    var identifier: UInt32 { get }
}
