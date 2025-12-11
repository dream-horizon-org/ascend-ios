import Foundation

// MARK: - Default Value Methods

/// Default value retrieval methods for AscendExperiments
internal final class DefaultValueMethods: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let accessMap: ExperimentsAccessMap
    private let logger: ExperimentsLogger
    
    // MARK: - Initialization
    
    internal init(accessMap: ExperimentsAccessMap, logger: ExperimentsLogger) {
        self.accessMap = accessMap
        self.logger = logger
    }
    
    // MARK: - Default Value Methods
    
    /// Gets default boolean value from default experiments configuration
    /// - Parameters:
    ///   - experimentKey: The experiment identifier
    ///   - variable: The variable name
    ///   - dontCache: If true, doesn't cache the result
    ///   - defaultExperiments: The default experiments dictionary
    /// - Returns: Boolean value from defaults or fallback
    internal func getDefaultBoolValue(for experimentKey: String, with variable: String, dontCache: Bool, defaultExperiments: [String: ExperimentVariable]) -> Bool {
        guard let defaultValue = defaultExperiments[experimentKey], 
              let variablesMap = defaultValue.dictionaryValue, 
              let variableToLookFor = variablesMap[variable], 
              let boolValue = variableToLookFor.boolValue else {
            logger.warning("No experiment found for \(experimentKey), \(variable)")
            return ExperimentsConstants.DataSource.BOOL_FALLBACK
        }
        
        accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableToLookFor, dontCache: dontCache)
        
        return boolValue
    }
    
    /// Gets default integer value from default experiments configuration
    /// - Parameters:
    ///   - experimentKey: The experiment identifier
    ///   - variable: The variable name
    ///   - dontCache: If true, doesn't cache the result
    ///   - defaultExperiments: The default experiments dictionary
    /// - Returns: Integer value from defaults or fallback
    internal func getDefaultIntValue(for experimentKey: String, with variable: String, dontCache: Bool, defaultExperiments: [String: ExperimentVariable]) -> Int {
        guard let defaultValue = defaultExperiments[experimentKey], 
              let variablesMap = defaultValue.dictionaryValue, 
              let variableToLookFor = variablesMap[variable], 
              let intValue = variableToLookFor.intValue else {
            logger.warning("No experiment found for \(experimentKey), \(variable)")
            return ExperimentsConstants.DataSource.INT_FALLBACK
        }
        
        accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableToLookFor, dontCache: dontCache)
        
        return intValue
    }
    
    /// Gets default long (Int64) value from default experiments configuration
    /// - Parameters:
    ///   - experimentKey: The experiment identifier
    ///   - variable: The variable name
    ///   - dontCache: If true, doesn't cache the result
    ///   - defaultExperiments: The default experiments dictionary
    /// - Returns: Long value from defaults or fallback
    internal func getDefaultLongValue(for experimentKey: String, with variable: String, dontCache: Bool, defaultExperiments: [String: ExperimentVariable]) -> Int64 {
        guard let defaultValue = defaultExperiments[experimentKey], 
              let variablesMap = defaultValue.dictionaryValue, 
              let variableToLookFor = variablesMap[variable], 
              let longValue = variableToLookFor.int64Value else {
            logger.warning("No experiment found for \(experimentKey), \(variable)")
            return ExperimentsConstants.DataSource.LONG_FALLBACK
        }
        
        accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableToLookFor, dontCache: dontCache)
        
        return longValue
    }
    
    /// Gets default double value from default experiments configuration
    /// - Parameters:
    ///   - experimentKey: The experiment identifier
    ///   - variable: The variable name
    ///   - dontCache: If true, doesn't cache the result
    ///   - defaultExperiments: The default experiments dictionary
    /// - Returns: Double value from defaults or fallback
    internal func getDefaultDoubleValue(for experimentKey: String, with variable: String, dontCache: Bool, defaultExperiments: [String: ExperimentVariable]) -> Double {
        guard let defaultValue = defaultExperiments[experimentKey], 
              let variablesMap = defaultValue.dictionaryValue, 
              let variableToLookFor = variablesMap[variable], 
              let doubleValue = variableToLookFor.doubleValue else {
            logger.warning("No experiment found for \(experimentKey), \(variable)")
            return ExperimentsConstants.DataSource.DOUBLE_FALLBACK
        }
        
        accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableToLookFor, dontCache: dontCache)
        
        return doubleValue
    }
    
    /// Gets default string value from default experiments configuration
    /// - Parameters:
    ///   - experimentKey: The experiment identifier
    ///   - variable: The variable name
    ///   - dontCache: If true, doesn't cache the result
    ///   - defaultExperiments: The default experiments dictionary
    /// - Returns: String value from defaults or fallback
    internal func getDefaultStringValue(for experimentKey: String, with variable: String, dontCache: Bool, defaultExperiments: [String: ExperimentVariable]) -> String {
        guard let defaultValue = defaultExperiments[experimentKey], 
              let variablesMap = defaultValue.dictionaryValue, 
              let variableToLookFor = variablesMap[variable], 
              let stringValue = variableToLookFor.stringValue else {
            logger.warning("No experiment found for \(experimentKey), \(variable)")
            return ExperimentsConstants.DataSource.STRING_FALLBACK
        }
        
        accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableToLookFor, dontCache: dontCache)
        
        return stringValue
    }
}
