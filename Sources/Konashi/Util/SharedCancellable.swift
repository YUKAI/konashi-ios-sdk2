//
//  SharedCancellable.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/08.
//

import Combine
import Foundation

class SharedCancellable {
    static let shared = SharedCancellable()
    var cancelablle = [UUID: AnyCancellable]()
}
