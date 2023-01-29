//
//  Log.swift
//  konashi-ios-sdk2
//
//  Created by Akira Matsuda on 2023/01/17.
//

import Combine
import Foundation
import os.log

public typealias LogOutput = PassthroughSubject<Log, Never>

// MARK: - LogMessage

public struct Log: CustomStringConvertible {
    public enum Level: String {
        /// Appropriate for messages that contain information normally of use only when
        /// tracing the execution of a program.
        case trace

        /// Appropriate for messages that contain information normally of use only when
        /// debugging a program.
        case debug

        /// Appropriate for informational messages.
        case info

        /// Appropriate for conditions that are not error conditions, but that may require
        /// special handling.
        case notice

        /// Appropriate for messages that are not error conditions, but more severe than
        /// `.notice`.
        case warning

        /// Appropriate for error conditions.
        case error

        /// Appropriate for critical error conditions that usually require immediate
        /// attention.
        case critical

        var priority: Int {
            switch self {
            case .trace:
                return 0
            case .debug:
                return 1
            case .info:
                return 2
            case .notice:
                return 3
            case .warning:
                return 4
            case .error:
                return 5
            case .critical:
                return 6
            }
        }
    }

    public enum Message: CustomStringConvertible {
        case trace(String)
        case debug(String)
        case info(String)
        case notice(String)
        case warning(String)
        case error(String)
        case critical(String)

        public var level: Level {
            switch self {
            case .trace:
                return .trace
            case .debug:
                return .debug
            case .info:
                return .info
            case .notice:
                return .notice
            case .warning:
                return .warning
            case .error:
                return .error
            case .critical:
                return .critical
            }
        }

        public var description: String {
            switch self {
            case let .trace(string):
                return string
            case let .debug(string):
                return string
            case let .info(string):
                return string
            case let .notice(string):
                return string
            case let .warning(string):
                return string
            case let .error(string):
                return string
            case let .critical(string):
                return string
            }
        }
    }

    public let label: String
    public var level: Level {
        return message.level
    }
    public let message: Message

    public var description: String {
        return "[\(message.level)] \(message.description)"
    }
}

public extension Log {
    var osLogType: OSLogType {
        switch level {
        case .trace:
            return .debug
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .info
        case .warning:
            return .info
        case .error:
            return .error
        case .critical:
            return .error
        }
    }
}

public extension Log {
    var osLog: OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: label)
    }
}
