//
//  Annalist.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 31.01.2024.
//

import os.log

/// The various log levels that the unified logging system provides.
public enum AnnalistLogLevel {
    
    /// The debug log level.
    case debug
    
    /// The informational log level.
    case info
    
    /// The warning log level.
    case warning
    
    /// The error log level.
    case error
    
    /// The fault log level.
    case fatal
    
}

/// An object for writing string messages to the unified logging system.
///
/// For any object get annalist instance using ``InjectAnnalist`` property wrapper:
/// ```swift
/// class Foo {
///     @InjectAnnalist(for: Foo.self) private var annalist
///
///     func bar() {
///         annalist.log(.info, "Hello World!")
///     }
/// }
/// ```
/// Text will be printed with tag generated from `Foo.self`
public protocol Annalist: AnyObject {
    
    /// Writes a message to the log or optionally adds log to error tracking service.
    /// - Parameters:
    ///   - level: The message’s log level, which determines the severity of the message and whether the system
    ///   persists it to disk. For possible values, see ``AnnalistLogLevel``.
    ///   - message: The interpolated string that the logger writes to the log.
    func log(_ level: AnnalistLogLevel, _ message: String)
    
    /// Captures an error event and sends it to error tracker.
    /// - Parameter error: An actual error.
    func capture(error: Error)
    
    /// Captures an error event and sends it to error tracker. Also captures string message for error.
    /// - Parameters:
    ///   - error: An actual error.
    ///   - message: A message for error
    func capture(error: Error, withMessage message: String)
    
    /// Captures a message event and sends it to error tracker.
    func capture(message: String)
    
}

extension AnnalistLogLevel {
    
    var asOSLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .error
        case .error: return .error
        case .fatal: return .fault
        }
    }
    
}

final class OnlyLogAnnalist: Annalist {
    
    private let tag: String
    private let logger: Logger
    
    init(withTag tag: String) {
        self.tag = tag
        self.logger = Logger(
            subsystem: "ru.medsenger.patient.shareExtension",
            category: tag
        )
    }
    
    func log(_ level: AnnalistLogLevel, _ message: String) {
        logger.log(level: level.asOSLogType, "\(message)")
    }
    
    func capture(error: Error) {
        assertionFailure("CAPTURED ERROR: \(error.localizedDescription)")
        logger.error("CAPTURED ERROR: \(error.localizedDescription)")
    }
    
    func capture(error: Error, withMessage message: String) {
        assertionFailure("CAPTURED ERROR: \(error.localizedDescription)")
        log(.error, message)
        logger.error("CAPTURED ERROR: \(error.localizedDescription)")
    }
    
    func capture(message: String) {
        assertionFailure("CAPTURED MESSAGE: \(message)")
        logger.error("CAPTURED MESSAGE: \(message)")
    }
    
}
