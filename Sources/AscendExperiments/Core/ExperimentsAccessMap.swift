import Foundation

// MARK: - Experiments Access Map Manager

/// Access map management for AscendExperiments
/// Maintains session-scoped cache of accessed experiment variables
internal final class ExperimentsAccessMap: @unchecked Sendable {
    
    // MARK: - Properties
    
    private var accessMap: [String: [String: ExperimentVariable]] = [:]
    private let threadSafety: ThreadSafety
    private let logger: ExperimentsLogger
    
    // MARK: - Initialization
    
    internal init(threadSafety: ThreadSafety, logger: ExperimentsLogger) {
        self.threadSafety = threadSafety
        self.logger = logger
    }
    
    // MARK: - Access Map Management
    
    /// Updates access map for tracking accessed experiment variables
    /// - Parameters:
    ///   - experimentKey: The experiment identifier
    ///   - variableName: The variable name that was accessed
    ///   - variable: The ExperimentVariable value
    ///   - dontCache: If true, doesn't cache the result
    internal func updateAccessMap(for experimentKey: String, having variableName: String, with variable: ExperimentVariable, dontCache: Bool) {
        guard !dontCache else { 
            logger.logCacheOperation("skip", experimentKey: experimentKey, variable: variableName, details: "dontCache=true")
            return 
        }
        
        threadSafety.safeDispatchOnExperimentsQueue {
            if var accessMapForPath = self.accessMap[experimentKey] {
                let wasCached = accessMapForPath[variableName] != nil
                accessMapForPath.updateValue(variable, forKey: variableName)
                self.accessMap.updateValue(accessMapForPath, forKey: experimentKey)
                
                if wasCached {
                    self.logger.logCacheOperation("update", experimentKey: experimentKey, variable: variableName)
                } else {
                    self.logger.logCacheOperation("cache", experimentKey: experimentKey, variable: variableName)
                }
            } else {
                self.accessMap.updateValue([variableName: variable], forKey: experimentKey)
                self.logger.logCacheOperation("cache", experimentKey: experimentKey, variable: variableName, details: "first variable for API path")
            }
        }
    }
    
    /// Gets access map for a specific API path
    /// - Parameter experimentKey: The experiment identifier
    /// - Returns: Dictionary of variables for the API path, or nil if not cached
    internal func getAccessMap(for experimentKey: String) -> [String: ExperimentVariable]? {
        return threadSafety.safeDispatchOnExperimentsQueue {
            guard let vars = self.accessMap[experimentKey] else { return nil }
            
            // Create a new dictionary to ensure type safety (prevent any bridging issues)
            var result: [String: ExperimentVariable] = [:]
            for (key, value) in vars {
                result[key] = value
            }
            return result
        }
    }
    
    /// Gets all access map data
    /// - Returns: Dictionary of access map by API path
    internal func getAllAccessMap() -> [String: [String: ExperimentVariable]] {
        return threadSafety.safeDispatchOnExperimentsQueue {
            return self.accessMap
        }
    }
    
    /// Checks if a specific variable is cached in access map
    /// - Parameters:
    ///   - experimentKey: The experiment identifier
    ///   - variable: The variable name
    /// - Returns: True if the variable is cached, false otherwise
    internal func isVariableCached(experimentKey: String, variable: String) -> Bool {
        return threadSafety.safeDispatchOnExperimentsQueue {
            return self.accessMap[experimentKey]?[variable] != nil
        }
    }
    
    /// Gets the count of cached variables for debugging
    /// - Returns: Total number of cached variables across all API paths
    internal func getCachedVariablesCount() -> Int {
        return threadSafety.safeDispatchOnExperimentsQueue {
            return self.accessMap.values.reduce(0) { $0 + $1.count }
        }
    }
    
    // MARK: - Access Map Clearing Methods
    
    /// Clears all access map data
    /// Called on app restart, app kill, or user logout
    /// Access map is session-scoped and does not persist across app restarts
    internal func clearSessionData() {
        threadSafety.safeDispatchOnExperimentsQueue {
            self.accessMap.removeAll()
            self.logger.info("Cleared access map")
        }
    }
    
    /// Clears access map for a specific API path
    /// - Parameter experimentKey: The experiment identifier to clear cache for
    internal func clearSessionData(for experimentKey: String) {
        threadSafety.safeDispatchOnExperimentsQueue {
            self.accessMap.removeValue(forKey: experimentKey)
            self.logger.info("Cleared access map for API path: \(experimentKey)")
        }
    }
    
    /// Clears all access map data
    /// Called on logout to ensure clean state
    internal func clearAllCacheData() {
        threadSafety.safeDispatchOnExperimentsQueue {
            self.accessMap.removeAll()
            self.logger.info("Cleared all access map data")
        }
    }
}
