import Foundation

// MARK: - Experiments Logger

/// Logging utilities for AscendExperiments
internal final class ExperimentsLogger: @unchecked Sendable {
    
    // MARK: - Singleton
    
    internal static let shared = ExperimentsLogger()
    
    // MARK: - Private Initializer
    
    private init() {}
    
    // MARK: - Logging Methods
    
    /// Log debug message
    /// - Parameters:
    ///   - message: The message to log
    ///   - tag: The log tag
    internal func debug(_ message: String, tag: String = ExperimentsConstants.Logging.TAG) {
        print("🔍 [\(tag)] \(message)")
    }
    
    /// Log info message
    /// - Parameters:
    ///   - message: The message to log
    ///   - tag: The log tag
    internal func info(_ message: String, tag: String = ExperimentsConstants.Logging.TAG) {
        print("ℹ️ [\(tag)] \(message)")
    }
    
    /// Log warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - tag: The log tag
    internal func warning(_ message: String, tag: String = ExperimentsConstants.Logging.TAG) {
        print("⚠️ [\(tag)] \(message)")
    }
    
    /// Log error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - tag: The log tag
    internal func error(_ message: String, tag: String = ExperimentsConstants.Logging.TAG) {
        print("❌ [\(tag)] \(message)")
    }
    
    /// Log success message
    /// - Parameters:
    ///   - message: The message to log
    ///   - tag: The log tag
    internal func success(_ message: String, tag: String = ExperimentsConstants.Logging.TAG) {
        print("✅ [\(tag)] \(message)")
    }
    
    // MARK: - Specialized Logging Methods
    
    /// Log cache operation
    /// - Parameters:
    ///   - operation: The cache operation (hit, miss, update, clear)
    ///   - experimentKey: The API path
    ///   - variable: The variable name
    ///   - details: Additional details
    internal func logCacheOperation(_ operation: String, experimentKey: String, variable: String, details: String = "") {
        let message = "Cache \(operation): \(experimentKey).\(variable)\(details.isEmpty ? "" : " - \(details)")"
        debug(message, tag: ExperimentsConstants.Logging.CACHE_TAG)
    }
    
    /// Log API operation
    /// - Parameters:
    ///   - operation: The API operation (request, response, error)
    ///   - details: The details to log
    internal func logAPIOperation(_ operation: String, details: String) {
        let message = "API \(operation): \(details)"
        debug(message, tag: ExperimentsConstants.Logging.API_TAG)
    }
    
    /// Log data source operation
    /// - Parameters:
    ///   - operation: The data source operation
    ///   - experimentKey: The API path
    ///   - variable: The variable name
    ///   - value: The value retrieved
    internal func logDataSourceOperation(_ operation: String, experimentKey: String, variable: String, value: Any) {
        let message = "DataSource \(operation): \(experimentKey).\(variable) = \(value)"
        debug(message, tag: ExperimentsConstants.Logging.DATASOURCE_TAG)
    }
}
