import Foundation
import os.log

// MARK: - Ascend Logger (Internal)

/// Internal logging utilities for the Ascend SDK
@available(iOS 13.0, macOS 10.15, *)
internal final class AscendLogger: @unchecked Sendable {
    
    // MARK: - Singleton
    
    internal static let shared = AscendLogger()
    
    // MARK: - Properties
    
    private let logger = OSLog(subsystem: "com.ascend.sdk", category: "AscendSDK")
    private var isDebugEnabled = false
    
    // MARK: - Private Initializer
    
    private init() {}
    
    // MARK: - Internal Interface
    
    /// Enable or disable debug logging
    /// - Parameter enabled: Whether to enable debug logging
    internal func setDebugEnabled(_ enabled: Bool) {
        isDebugEnabled = enabled
    }
    
    /// Log debug message
    /// - Parameter message: The message to log
    internal func debug(_ message: String) {
        guard isDebugEnabled else { return }
        os_log("%@", log: logger, type: .debug, message)
    }
    
    /// Log info message
    /// - Parameter message: The message to log
    internal func info(_ message: String) {
        os_log("%@", log: logger, type: .info, message)
    }
    
    /// Log warning message
    /// - Parameter message: The message to log
    internal func warning(_ message: String) {
        os_log("%@", log: logger, type: .default, message)
    }
    
    /// Log error message
    /// - Parameter message: The message to log
    internal func error(_ message: String) {
        os_log("%@", log: logger, type: .error, message)
    }
    
    /// Log error with associated error
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: The associated error
    internal func error(_ message: String, error: Error) {
        os_log("%@: %@", log: logger, type: .error, message, error.localizedDescription)
    }
}

// MARK: - Logging Extensions

/// Convenience extensions for logging
extension AscendLogger {
    
    /// Log plugin initialization
    /// - Parameter pluginName: Name of the plugin
    internal func logPluginInitialization(_ pluginName: String) {
        info("Plugin initialized: \(pluginName)")
    }
    
    /// Log plugin configuration
    /// - Parameter pluginName: Name of the plugin
    internal func logPluginConfiguration(_ pluginName: String) {
        debug("Plugin configured: \(pluginName)")
    }
    
    /// Log network request
    /// - Parameters:
    ///   - url: The request URL
    ///   - method: The HTTP method
    internal func logNetworkRequest(url: URL, method: String) {
        debug("Network request: \(method) \(url.absoluteString)")
    }
    
    /// Log network response
    /// - Parameters:
    ///   - url: The request URL
    ///   - statusCode: The HTTP status code
    internal func logNetworkResponse(url: URL, statusCode: Int) {
        debug("Network response: \(statusCode) for \(url.absoluteString)")
    }
    
    /// Log user state change
    /// - Parameters:
    ///   - event: The user event
    ///   - userId: The user ID
    internal func logUserStateChange(event: String, userId: String?) {
        info("User state change: \(event) for user: \(userId ?? "none")")
    }
    
    /// Log app lifecycle event
    /// - Parameter event: The lifecycle event
    internal func logAppLifecycleEvent(_ event: String) {
        info("App lifecycle event: \(event)")
    }
}
