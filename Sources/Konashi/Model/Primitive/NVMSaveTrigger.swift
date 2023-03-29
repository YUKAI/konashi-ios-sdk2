//
//  NVMSaveTrigger.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2021/08/10.
//

import Foundation

public enum NVMSaveTrigger: CaseIterable, CustomStringConvertible {
    /// `automatic` for automatic save,
    case automatic
    /// `manual` for manual save (`SystemSettingPayload.nvmSaveNow` needs to be called to save).
    case manual

    // MARK: Public

    public var description: String {
        switch self {
        case .automatic:
            return "Automatic"
        case .manual:
            return "Manual"
        }
    }
}
