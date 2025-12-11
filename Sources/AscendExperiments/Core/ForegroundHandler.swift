import Foundation

// MARK: - Foreground Handler Protocol

/// Protocol for handling foreground refresh logic with window time
internal protocol ForegroundHandlerProtocol: Sendable {
    /// Handle successful response headers
    func handleResponseHeader(headers: [String: String])
    
    /// Handle cache response (304 Not Modified)
    func handleCacheResponse(headers: [String: String])
    
    /// Check if refresh should happen and return updated headers if needed
    /// - Parameter shouldRefreshOnForeground: Whether foreground refresh is enabled
    /// - Returns: Updated headers dictionary if refresh should happen, nil otherwise
    func shouldRefreshOnForeground(shouldRefreshOnForeground: Bool, currentHeaders: [String: String]) -> [String: String]?
    
    /// Clear session data (on logout)
    func clearSessionData()
}

// MARK: - Foreground Handler Implementation

/// Handler for managing foreground refresh logic with window time
/// Prevents unnecessary refreshes by tracking last response time and window duration
internal final class ForegroundHandler: ForegroundHandlerProtocol, @unchecked Sendable {
    
    // MARK: - Constants
    
    /// Header key for last successful experiment received timestamp
    public static let successfulExperimentReceivedKey = "Last-Modified"
    
    /// Header key for window time (cache duration)
    public static let windowTimeKey = "Max-Age"
    
    /// HTTP status code for Not Modified response
    public static let cacheResponseStatusCode = 304
    
    // MARK: - Properties
    
    private var lastCachedResponseTime: TimeInterval = 0
    private var lastSuccessfulResponseTime: TimeInterval?
    private var windowTime: TimeInterval = 0
    
    private let threadSafety: ThreadSafety
    private let logger: ExperimentsLogger
    
    // MARK: - Initialization
    
    internal init(threadSafety: ThreadSafety, logger: ExperimentsLogger) {
        self.threadSafety = threadSafety
        self.logger = logger
    }
    
    // MARK: - ForegroundHandlerProtocol Implementation
    
    /// Handle successful response headers
    /// Extracts Last-Modified timestamp and Max-Age window time from response headers
    func handleResponseHeader(headers: [String: String]) {
        threadSafety.safeDispatchOnExperimentsQueue {
            // Extract Last-Modified timestamp
            if let lastModifiedString = headers[ForegroundHandler.successfulExperimentReceivedKey],
               let timestamp = TimeInterval(lastModifiedString) {
                self.lastSuccessfulResponseTime = timestamp
                self.logger.debug("Updated lastSuccessfulResponseTime: \(timestamp)")
            }
            
            // Update last cached response time
            self.lastCachedResponseTime = Date().timeIntervalSince1970 * 1000 // Convert to milliseconds
            
            // Extract Max-Age window time
            if let maxAgeString = headers[ForegroundHandler.windowTimeKey],
               let maxAge = TimeInterval(maxAgeString) {
                self.windowTime = maxAge * 1000 // Convert to milliseconds
                self.logger.debug("Updated windowTime: \(self.windowTime)ms")
            }
        }
    }
    
    /// Handle cache response (304 Not Modified)
    /// Updates cached response time and window time from headers
    func handleCacheResponse(headers: [String: String]) {
        threadSafety.safeDispatchOnExperimentsQueue {
            // Update last cached response time
            self.lastCachedResponseTime = Date().timeIntervalSince1970 * 1000 // Convert to milliseconds
            
            // Extract Max-Age window time
            if let maxAgeString = headers[ForegroundHandler.windowTimeKey],
               let maxAge = TimeInterval(maxAgeString) {
                self.windowTime = maxAge * 1000 // Convert to milliseconds
                self.logger.debug("Updated windowTime from cache response: \(self.windowTime)ms")
            }
        }
    }
    
    /// Check if foreground refresh should happen based on window time
    /// - Parameters:
    ///   - shouldRefreshOnForeground: Whether foreground refresh is enabled in config
    ///   - currentHeaders: Current request headers
    /// - Returns: Updated headers with Last-Modified if refresh should happen, nil otherwise
    func shouldRefreshOnForeground(shouldRefreshOnForeground: Bool, currentHeaders: [String: String]) -> [String: String]? {
        return threadSafety.safeDispatchOnExperimentsQueue {
            // Check if refresh is enabled and window time has passed
            guard self.isForegroundExperimentEnable(shouldRefreshOnForeground: shouldRefreshOnForeground) else {
                self.logger.debug("Foreground refresh skipped: within window time")
                return nil
            }
            
            // Refresh should happen - update headers with Last-Modified if available
            var updatedHeaders = currentHeaders
            
            if let lastSuccessfulResponseTime = self.lastSuccessfulResponseTime {
                updatedHeaders[ForegroundHandler.successfulExperimentReceivedKey] = String(Int(lastSuccessfulResponseTime))
                self.logger.debug("Foreground refresh enabled: adding Last-Modified header")
            } else {
                updatedHeaders.removeValue(forKey: ForegroundHandler.successfulExperimentReceivedKey)
                self.logger.debug("Foreground refresh enabled: no Last-Modified header")
            }
            
            return updatedHeaders
        }
    }
    
    /// Clear session data (called on logout)
    func clearSessionData() {
        threadSafety.safeDispatchOnExperimentsQueue {
            self.lastCachedResponseTime = 0
            self.lastSuccessfulResponseTime = nil
            self.windowTime = 0
            self.logger.debug("Cleared foreground handler session data")
        }
    }
    
    // MARK: - Private Methods
    
    /// Check if foreground experiment refresh is enabled
    /// - Parameter shouldRefreshOnForeground: Whether foreground refresh is enabled in config
    /// - Returns: True if refresh should happen (outside window time), false otherwise
    private func isForegroundExperimentEnable(shouldRefreshOnForeground: Bool) -> Bool {
        guard shouldRefreshOnForeground else {
            return false
        }
        
        // If no window time is set, always refresh
        guard windowTime > 0 else {
            logger.debug("No window time set - allowing refresh")
            return true
        }
        
        // If no last cached time, allow refresh
        guard lastCachedResponseTime > 0 else {
            logger.debug("No last cached time - allowing refresh")
            return true
        }
        
        let currentTime = Date().timeIntervalSince1970 * 1000 // Convert to milliseconds
        let timeSinceLastCache = currentTime - lastCachedResponseTime
        
        let shouldRefresh = timeSinceLastCache > windowTime
        
        if shouldRefresh {
            logger.debug("Foreground refresh enabled: \(timeSinceLastCache)ms > \(windowTime)ms window")
        } else {
            logger.debug("Foreground refresh skipped: \(timeSinceLastCache)ms < \(windowTime)ms window")
        }
        
        return shouldRefresh
    }
}

