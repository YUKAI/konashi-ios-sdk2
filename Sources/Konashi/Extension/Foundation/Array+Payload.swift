//
//  Array+Payload.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/31.
//

import Foundation

extension Array where Element: Payload {
    func compose() -> [UInt8] {
        var bytes = [UInt8]()
        for element in self {
            bytes.append(contentsOf: element.compose())
        }
        return bytes
    }
}
