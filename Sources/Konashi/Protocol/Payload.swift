//
//  Payload.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/03.
//

import Foundation

protocol Payload {
    func compose() -> [UInt8]
}
