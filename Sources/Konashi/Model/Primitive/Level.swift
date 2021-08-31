//
//  Level.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/13.
//

import Foundation

public enum Level: UInt8 {
    case low = 0x0
    case high = 0x01
    case toggle = 0x02
    case illegalValue = 0x03
}
