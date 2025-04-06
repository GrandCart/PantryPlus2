
// Utilities/Logging.swift
import Foundation
import os.log

/// Custom logger for PantryPlus2
class Logger {
    // MARK: - Properties
    private let logger: OSLog
    
    // MARK: - Initialization
    init(subsystem: String, category: String) {
        self.logger = OSLog(subsystem: subsystem, category: category)
    }
    
    // MARK: - Logging Methods
    /// Log debug message
    /// - Parameter message: Debug message
    func debug(_ message: String) {
#if DEBUG
        os_log("%{public}@", log: logger, type: .debug, message)
#endif
    }
    
    /// Log info message
    /// - Parameter message: Info message
    func info(_ message: String) {
        os_log("%{public}@", log: logger, type: .info, message)
    }
    
        /// Log warning message
        /// - Parameter message: Warning message
        func warning(_ message: String) {
            os_log("%{public}@", log: logger, type: .default, message)
        }
        
        /// Log error message
        /// - Parameter message: Error message
        func error(_ message: String) {
            os_log("%{public}@", log: logger, type: .error, message)
        }
        
        /// Log critical error message
        /// - Parameter message: Critical error message
        func critical(_ message: String) {
            os_log("%{public}@", log: logger, type: .fault, message)
        }
    }
