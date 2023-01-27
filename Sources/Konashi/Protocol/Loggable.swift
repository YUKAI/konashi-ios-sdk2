//
//  Loggable.swift
//  Konashi
//
//  Created by Akira Matsuda on 2023/01/27.
//

import Foundation

public protocol Loggable {
    static var sharedLogOutput: LogOutput { get }
    var logOutput: LogOutput { get }

    func log(_ message: Log.Message)
}

public extension Loggable {
    func log(_ message: Log.Message) {
        let logMessage = Log(label: String(describing: type(of: self)), message: message)
        Self.sharedLogOutput.send(logMessage)
        logOutput.send(logMessage)
    }
}
