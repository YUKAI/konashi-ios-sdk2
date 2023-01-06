//
//  Array+Safe.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/07.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {
   public subscript(safe index: Index) -> Iterator.Element? {
     return (startIndex <= index && index < endIndex) ? self[index] : nil
   }
}
