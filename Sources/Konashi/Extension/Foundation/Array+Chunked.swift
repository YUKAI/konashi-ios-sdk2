//
//  Array+Chunked.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/12.
//

import Foundation

// https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
extension Array {
    func chunked(by chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: chunkSize).map {
            Array(self[$0 ..< Swift.min($0 + chunkSize, self.count)])
        }
    }
}
