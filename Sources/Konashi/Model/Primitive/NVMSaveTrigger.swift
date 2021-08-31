//
//  NVMSaveTrigger.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/10.
//

import Foundation

public enum NVMSaveTrigger: CaseIterable, CustomStringConvertible {
    public var description: String {
        switch self {
        case .automatic:
            return "Automatic"
        case .manual:
            return "Manual"
        }
    }

    case automatic
    case manual
}
