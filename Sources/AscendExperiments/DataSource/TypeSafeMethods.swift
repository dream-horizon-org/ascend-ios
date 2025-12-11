import Foundation

// MARK: - Type-Safe Methods

/// Type-safe flag retrieval methods for AscendExperiments
internal final class TypeSafeMethods: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let accessMap: ExperimentsAccessMap
    private let defaultMethods: DefaultValueMethods
    private let threadSafety: ThreadSafety
    private let logger: ExperimentsLogger
    
    // MARK: - Initialization
    
    internal init(accessMap: ExperimentsAccessMap, defaultMethods: DefaultValueMethods, threadSafety: ThreadSafety, logger: ExperimentsLogger) {
        self.accessMap = accessMap
        self.defaultMethods = defaultMethods
        self.threadSafety = threadSafety
        self.logger = logger
    }
    
    // MARK: - Type-Safe Flag Methods
    
    /// Retrieves a boolean value from an experiment with proper fallback handling
    /// - Parameters:
    ///   - experimentKey: The experiment identifier (e.g., "button_exp_test")
    ///   - variable: Variable name within the experiment (required)
    ///   - dontCache: If true, doesn't cache the result in memory
    ///   - ignoreCache: If true, bypasses the cache and fetches fresh
    ///   - currentExperiments: Current experiments from API
    ///   - defaultExperiments: Default experiments from configuration
    /// - Returns: Boolean value with fallback to false
    internal func getBoolValue(for experimentKey: String, with variable: String, dontCache: Bool = false, ignoreCache: Bool = false, currentExperiments: [String: Experiment], defaultExperiments: [String: ExperimentVariable]) -> Bool {
        let block: () -> Bool = { [weak self] in
            guard let self = self else { return ExperimentsConstants.DataSource.BOOL_FALLBACK }
            
            let defaultValue = ExperimentsConstants.DataSource.BOOL_FALLBACK
            let expectedType = DataType.boolean
            let methodName = "getBoolValue"
            
            // 1. Check access map (if not ignoring cache) with type validation
            if !ignoreCache, let accessMapForPath = self.accessMap.getAccessMap(for: experimentKey) {
                let cachedVariable = accessMapForPath[variable]
                if let cachedValue = TypeSafetyUtils.getCachedValue(
                    cachedVariable: cachedVariable,
                    expectedType: expectedType,
                    defaultValue: defaultValue,
                    logger: self.logger,
                    methodName: methodName,
                    variableKey: variable
                ) {
                    self.logger.logDataSourceOperation("cache_hit", experimentKey: experimentKey, variable: variable, value: cachedValue)
                    return cachedValue
                }
            }
            
            // 2-4: Check experimentMap -> defaultMap -> fallback using unified type-safe retrieval
            let experiment = currentExperiments[experimentKey]
            let defaultVariable = defaultExperiments[experimentKey]
            
            let finalValue = TypeSafetyUtils.getTypeSafeValue(
                experiment: experiment,
                defaultVariable: defaultVariable,
                variableKey: variable,
                expectedType: expectedType,
                defaultValue: defaultValue,
                logger: self.logger,
                methodName: methodName
            )
            
            // Update access map if value was found
            if let experiment = experiment,
               let variables = experiment.variables,
               let variablesMap = variables.dictionaryValue,
               let variableObj = variablesMap[variable] {
                self.accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableObj, dontCache: dontCache)
            } else if let defaultVariable = defaultVariable,
                      let variablesMap = defaultVariable.dictionaryValue,
                      let variableObj = variablesMap[variable] {
                self.accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableObj, dontCache: dontCache)
            }
            
            return finalValue
        }
        
        return threadSafety.safeDispatchOnExperimentsQueue {
            return block()
        }
    }
    
    /// Retrieves an integer value from an experiment with proper fallback handling
    /// - Parameters:
    ///   - experimentKey: The experiment identifier (e.g., "retry_config")
    ///   - variable: Variable name within the experiment (required)
    ///   - dontCache: If true, doesn't cache the result in memory
    ///   - ignoreCache: If true, bypasses the cache and fetches fresh
    ///   - currentExperiments: Current experiments from API
    ///   - defaultExperiments: Default experiments from configuration
    /// - Returns: Integer value with fallback to -1
    internal func getIntValue(for experimentKey: String, with variable: String, dontCache: Bool = false, ignoreCache: Bool = false, currentExperiments: [String: Experiment], defaultExperiments: [String: ExperimentVariable]) -> Int {
        let block: () -> Int = { [weak self] in
            guard let self = self else { return ExperimentsConstants.DataSource.INT_FALLBACK }
            
            let defaultValue = ExperimentsConstants.DataSource.INT_FALLBACK
            let expectedType = DataType.int
            let methodName = "getIntValue"
            
            // 1. Check access map (if not ignoring cache) with type validation
            if !ignoreCache, let accessMapForPath = self.accessMap.getAccessMap(for: experimentKey) {
                let cachedVariable = accessMapForPath[variable]
                if let cachedValue = TypeSafetyUtils.getCachedValue(
                    cachedVariable: cachedVariable,
                    expectedType: expectedType,
                    defaultValue: defaultValue,
                    logger: self.logger,
                    methodName: methodName,
                    variableKey: variable
                ) {
                    self.logger.logDataSourceOperation("cache_hit", experimentKey: experimentKey, variable: variable, value: cachedValue)
                    return cachedValue
                }
            }
            
            // 2-4: Check experimentMap -> defaultMap -> fallback using unified type-safe retrieval
            let experiment = currentExperiments[experimentKey]
            let defaultVariable = defaultExperiments[experimentKey]
            
            let finalValue = TypeSafetyUtils.getTypeSafeValue(
                experiment: experiment,
                defaultVariable: defaultVariable,
                variableKey: variable,
                expectedType: expectedType,
                defaultValue: defaultValue,
                logger: self.logger,
                methodName: methodName
            )
            
            // Update access map if value was found
            if let experiment = experiment,
               let variables = experiment.variables,
               let variablesMap = variables.dictionaryValue,
               let variableObj = variablesMap[variable] {
                self.accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableObj, dontCache: dontCache)
            } else if let defaultVariable = defaultVariable,
                      let variablesMap = defaultVariable.dictionaryValue,
                      let variableObj = variablesMap[variable] {
                self.accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableObj, dontCache: dontCache)
            }
            
            return finalValue
        }
        
        return threadSafety.safeDispatchOnExperimentsQueue {
            return block()
        }
    }
    
    /// Retrieves a string value from an experiment with proper fallback handling
    /// - Parameters:
    ///   - experimentKey: The experiment identifier (e.g., "button_exp_test")
    ///   - variable: Variable name within the experiment (required)
    ///   - dontCache: If true, doesn't cache the result in memory
    ///   - ignoreCache: If true, bypasses the cache and fetches fresh
    ///   - currentExperiments: Current experiments from API
    ///   - defaultExperiments: Default experiments from configuration
    /// - Returns: String value with fallback to "" (empty string)
    internal func getStringValue(for experimentKey: String, with variable: String, dontCache: Bool = false, ignoreCache: Bool = false, currentExperiments: [String: Experiment], defaultExperiments: [String: ExperimentVariable]) -> String {
        let block: () -> String = { [weak self] in
            guard let self = self else { return ExperimentsConstants.DataSource.STRING_FALLBACK }
            
            let defaultValue = ExperimentsConstants.DataSource.STRING_FALLBACK
            let expectedType = DataType.string
            let methodName = "getStringValue"
            
            // 1. Check access map (if not ignoring cache) with type validation
            if !ignoreCache, let accessMapForPath = self.accessMap.getAccessMap(for: experimentKey) {
                let cachedVariable = accessMapForPath[variable]
                if let cachedValue = TypeSafetyUtils.getCachedValue(
                    cachedVariable: cachedVariable,
                    expectedType: expectedType,
                    defaultValue: defaultValue,
                    logger: self.logger,
                    methodName: methodName,
                    variableKey: variable
                ) {
                    self.logger.logDataSourceOperation("cache_hit", experimentKey: experimentKey, variable: variable, value: cachedValue)
                    return cachedValue
                }
            }
            
            // 2-4: Check experimentMap -> defaultMap -> fallback using unified type-safe retrieval
            let experiment = currentExperiments[experimentKey]
            print("currentExperiments: \(currentExperiments) experimentKey: \(experimentKey)")
            let defaultVariable = defaultExperiments[experimentKey]
            
            let finalValue = TypeSafetyUtils.getTypeSafeValue(
                experiment: experiment,
                defaultVariable: defaultVariable,
                variableKey: variable,
                expectedType: expectedType,
                defaultValue: defaultValue,
                logger: self.logger,
                methodName: methodName
            )
            
            // Update access map if value was found
            if let experiment = experiment,
               let variables = experiment.variables,
               let variablesMap = variables.dictionaryValue,
               let variableObj = variablesMap[variable] {
                self.accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableObj, dontCache: dontCache)
            } else if let defaultVariable = defaultVariable,
                      let variablesMap = defaultVariable.dictionaryValue,
                      let variableObj = variablesMap[variable] {
                self.accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableObj, dontCache: dontCache)
            }

            print("finalValue: \(finalValue)")
            
            return finalValue
        }
        
        return threadSafety.safeDispatchOnExperimentsQueue {
            return block()
        }
    }
    
    /// Retrieves a double value from an experiment with proper fallback handling
    /// - Parameters:
    ///   - experimentKey: The experiment identifier (e.g., "network_config")
    ///   - variable: Variable name within the experiment (required)
    ///   - dontCache: If true, doesn't cache the result in memory
    ///   - ignoreCache: If true, bypasses the cache and fetches fresh
    ///   - currentExperiments: Current experiments from API
    ///   - defaultExperiments: Default experiments from configuration
    /// - Returns: Double value with fallback to -1.0
    internal func getDoubleValue(for experimentKey: String, with variable: String, dontCache: Bool = false, ignoreCache: Bool = false, currentExperiments: [String: Experiment], defaultExperiments: [String: ExperimentVariable]) -> Double {
        let block: () -> Double = { [weak self] in
            guard let self = self else { return ExperimentsConstants.DataSource.DOUBLE_FALLBACK }
            
            let defaultValue = ExperimentsConstants.DataSource.DOUBLE_FALLBACK
            let expectedType = DataType.double
            let methodName = "getDoubleValue"
            
            // 1. Check access map (if not ignoring cache) with type validation
            if !ignoreCache, let accessMapForPath = self.accessMap.getAccessMap(for: experimentKey) {
                let cachedVariable = accessMapForPath[variable]
                if let cachedValue = TypeSafetyUtils.getCachedValue(
                    cachedVariable: cachedVariable,
                    expectedType: expectedType,
                    defaultValue: defaultValue,
                    logger: self.logger,
                    methodName: methodName,
                    variableKey: variable
                ) {
                    self.logger.logDataSourceOperation("cache_hit", experimentKey: experimentKey, variable: variable, value: cachedValue)
                    return cachedValue
                }
            }
            
            // 2-4: Check experimentMap -> defaultMap -> fallback using unified type-safe retrieval
            let experiment = currentExperiments[experimentKey]
            let defaultVariable = defaultExperiments[experimentKey]
            
            let finalValue = TypeSafetyUtils.getTypeSafeValue(
                experiment: experiment,
                defaultVariable: defaultVariable,
                variableKey: variable,
                expectedType: expectedType,
                defaultValue: defaultValue,
                logger: self.logger,
                methodName: methodName
            )
            
            // Update access map if value was found
            if let experiment = experiment,
               let variables = experiment.variables,
               let variablesMap = variables.dictionaryValue,
               let variableObj = variablesMap[variable] {
                self.accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableObj, dontCache: dontCache)
            } else if let defaultVariable = defaultVariable,
                      let variablesMap = defaultVariable.dictionaryValue,
                      let variableObj = variablesMap[variable] {
                self.accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableObj, dontCache: dontCache)
            }
            
            return finalValue
        }
        
        return threadSafety.safeDispatchOnExperimentsQueue {
            return block()
        }
    }
    
    /// Retrieves a long (Int64) value from an experiment with proper fallback handling
    /// - Parameters:
    ///   - experimentKey: The experiment identifier (e.g., "cache_config")
    ///   - variable: Variable name within the experiment (required)
    ///   - dontCache: If true, doesn't cache the result in memory
    ///   - ignoreCache: If true, bypasses the cache and fetches fresh
    ///   - currentExperiments: Current experiments from API
    ///   - defaultExperiments: Default experiments from configuration
    /// - Returns: Long value with fallback to -1L
    internal func getLongValue(for experimentKey: String, with variable: String, dontCache: Bool = false, ignoreCache: Bool = false, currentExperiments: [String: Experiment], defaultExperiments: [String: ExperimentVariable]) -> Int64 {
        let block: () -> Int64 = { [weak self] in
            guard let self = self else { return ExperimentsConstants.DataSource.LONG_FALLBACK }
            
            let defaultValue = ExperimentsConstants.DataSource.LONG_FALLBACK
            let expectedType = DataType.long
            let methodName = "getLongValue"
            
            // 1. Check access map (if not ignoring cache) with type validation
            if !ignoreCache, let accessMapForPath = self.accessMap.getAccessMap(for: experimentKey) {
                let cachedVariable = accessMapForPath[variable]
                if let cachedValue = TypeSafetyUtils.getCachedValue(
                    cachedVariable: cachedVariable,
                    expectedType: expectedType,
                    defaultValue: defaultValue,
                    logger: self.logger,
                    methodName: methodName,
                    variableKey: variable
                ) {
                    self.logger.logDataSourceOperation("cache_hit", experimentKey: experimentKey, variable: variable, value: cachedValue)
                    return cachedValue
                }
            }
            
            // 2-4: Check experimentMap -> defaultMap -> fallback using unified type-safe retrieval
            let experiment = currentExperiments[experimentKey]
            let defaultVariable = defaultExperiments[experimentKey]
            
            let finalValue = TypeSafetyUtils.getTypeSafeValue(
                experiment: experiment,
                defaultVariable: defaultVariable,
                variableKey: variable,
                expectedType: expectedType,
                defaultValue: defaultValue,
                logger: self.logger,
                methodName: methodName
            )
            
            // Update access map if value was found
            if let experiment = experiment,
               let variables = experiment.variables,
               let variablesMap = variables.dictionaryValue,
               let variableObj = variablesMap[variable] {
                self.accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableObj, dontCache: dontCache)
            } else if let defaultVariable = defaultVariable,
                      let variablesMap = defaultVariable.dictionaryValue,
                      let variableObj = variablesMap[variable] {
                self.accessMap.updateAccessMap(for: experimentKey, having: variable, with: variableObj, dontCache: dontCache)
            }
            
            return finalValue
        }
        
        return threadSafety.safeDispatchOnExperimentsQueue {
            return block()
        }
    }
}
