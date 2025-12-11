import Foundation

// MARK: - Type Safety Utilities

/// Utility class for type-safe value manipulation and validation.
/// Similar to the Android implementation's TypeSafetyUtils.
/// Provides centralized type safety operations matching Android behavior.
internal final class TypeSafetyUtils: @unchecked Sendable {
    
    // MARK: - Default Values
    
    /// Default values for each data type, matching Android's DefaultValues
    internal struct DefaultValues {
        static let string = ""
        static let boolean = false
        static let int = -1
        static let double = -1.0
        static let long: Int64 = -1
    }
    
    // MARK: - Type-Safe Conversion
    
    /// Safely converts a variable value to the expected type based on data_type.
    /// Validates that the variable's data_type matches the expected type.
    /// - Parameters:
    ///   - variable: The variable object containing value and dataType
    ///   - expectedType: The expected data type for this variable
    ///   - defaultValue: The default value to return if conversion fails
    /// - Returns: The converted value of type T, or defaultValue if conversion fails
    internal static func convertValue<T>(
        variable: ExperimentVariable?,
        expectedType: DataType,
        defaultValue: T,
        logger: ExperimentsLogger,
        methodName: String,
        variableKey: String
    ) -> T {
        guard let variable = variable else {
            logger.warning("\(methodName): Variable is null for '\(variableKey)', returning default value")
            return defaultValue
        }
        
        // Type validation: Check if the variable's data_type matches expected type
        if let dataType = variable.dataType {
            if dataType != expectedType {
                logger.warning(
                    "\(methodName): Type mismatch for variable '\(variableKey)': " +
                    "Expected \(expectedType.apiValue), but got \(dataType.apiValue). " +
                    "Using default value."
                )
                return defaultValue
            }
        } else {
            // If data_type is null, try to parse anyway but log a warning
            logger.warning(
                "\(methodName): data_type is null or unrecognized for variable '\(variableKey)'. " +
                "Attempting to parse as \(expectedType.apiValue)."
            )
        }
        
        // Convert based on expected type
        switch expectedType {
        case .boolean:
            if let boolValue = variable.boolValue {
                return boolValue as! T
            }
            // Try to extract from string representation
            if let stringValue = variable.stringValue {
                let parsed = safeBooleanParse(stringValue, defaultValue: DefaultValues.boolean)
                return parsed as! T
            }
            return defaultValue
            
        case .string:
            if let stringValue = variable.stringValue {
                return stringValue as! T
            }
            // Try to convert other types to string
            if let boolValue = variable.boolValue {
                return String(boolValue) as! T
            }
            if let intValue = variable.intValue {
                return String(intValue) as! T
            }
            if let int64Value = variable.int64Value {
                return String(int64Value) as! T
            }
            if let doubleValue = variable.doubleValue {
                return String(doubleValue) as! T
            }
            return defaultValue
            
        case .int:
            if let intValue = variable.intValue {
                return intValue as! T
            }
            // Try to parse from string
            if let stringValue = variable.stringValue {
                let parsed = safeIntParse(stringValue, defaultValue: DefaultValues.int)
                return parsed as! T
            }
            // Try to convert from Int64
            if let int64Value = variable.int64Value {
                return Int(int64Value) as! T
            }
            return defaultValue
            
        case .double:
            if let doubleValue = variable.doubleValue {
                return doubleValue as! T
            }
            // Try to parse from string
            if let stringValue = variable.stringValue {
                let parsed = safeDoubleParse(stringValue, defaultValue: DefaultValues.double)
                return parsed as! T
            }
            // Try to convert from Int
            if let intValue = variable.intValue {
                return Double(intValue) as! T
            }
            if let int64Value = variable.int64Value {
                return Double(int64Value) as! T
            }
            return defaultValue
            
        case .long:
            if let int64Value = variable.int64Value {
                return int64Value as! T
            }
            // Try to parse from string
            if let stringValue = variable.stringValue {
                let parsed = safeLongParse(stringValue, defaultValue: DefaultValues.long)
                return parsed as! T
            }
            // Try to convert from Int
            if let intValue = variable.intValue {
                return Int64(intValue) as! T
            }
            return defaultValue
        }
    }
    
    // MARK: - Safe Parse Functions
    
    /// Safely parses a string value to Boolean.
    /// Similar to Android's safeBooleanParse logic.
    /// - Parameters:
    ///   - value: String value to parse
    ///   - defaultValue: Default value to return if parsing fails
    /// - Returns: Parsed boolean value or default
    internal static func safeBooleanParse(_ value: String?, defaultValue: Bool) -> Bool {
        guard let value = value, !value.isEmpty, value.lowercased() != "null" else {
            return defaultValue
        }
        return value.trimmingCharacters(in: .whitespaces).lowercased() == "true"
    }
    
    /// Safely parses a string value, returning it as-is or default if null/empty.
    /// - Parameters:
    ///   - value: String value
    ///   - defaultValue: Default value to return if value is nil/empty
    /// - Returns: String value or default
    internal static func safeStringParse(_ value: String?, defaultValue: String) -> String {
        guard let value = value, !value.isEmpty, value.lowercased() != "null" else {
            return defaultValue
        }
        return value
    }
    
    /// Safely parses a string value to Int.
    /// Similar to Android's safeIntParse.
    /// - Parameters:
    ///   - value: String value to parse
    ///   - defaultValue: Default value to return if parsing fails
    /// - Returns: Parsed integer value or default
    internal static func safeIntParse(_ value: String?, defaultValue: Int) -> Int {
        guard let value = value, !value.isEmpty, value.lowercased() != "null" else {
            return defaultValue
        }
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return Int(trimmed) ?? defaultValue
    }
    
    /// Safely parses a string value to Double.
    /// Similar to Android's safeDoubleParse.
    /// - Parameters:
    ///   - value: String value to parse
    ///   - defaultValue: Default value to return if parsing fails
    /// - Returns: Parsed double value or default
    internal static func safeDoubleParse(_ value: String?, defaultValue: Double) -> Double {
        guard let value = value, !value.isEmpty, value.lowercased() != "null" else {
            return defaultValue
        }
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return Double(trimmed) ?? defaultValue
    }
    
    /// Safely parses a string value to Long (Int64).
    /// Similar to Android's safeLongParse.
    /// - Parameters:
    ///   - value: String value to parse
    ///   - defaultValue: Default value to return if parsing fails
    /// - Returns: Parsed Int64 value or default
    internal static func safeLongParse(_ value: String?, defaultValue: Int64) -> Int64 {
        guard let value = value, !value.isEmpty, value.lowercased() != "null" else {
            return defaultValue
        }
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return Int64(trimmed) ?? defaultValue
    }
    
    // MARK: - JSON Object Extraction
    
    /// Safely extracts a value from JSON dictionary with type-safe conversion.
    /// Used for defaultMap and backward compatibility with JSON-based variables.
    /// - Parameters:
    ///   - jsonDict: JSON dictionary to extract from
    ///   - key: Key to extract
    ///   - expectedType: Expected data type
    ///   - defaultValue: Default value to return if extraction fails
    /// - Returns: Extracted value of type T, or defaultValue
    internal static func extractFromJsonObject<T>(
        jsonDict: [String: Any]?,
        key: String,
        expectedType: DataType,
        defaultValue: T,
        logger: ExperimentsLogger,
        methodName: String
    ) -> T {
        guard let jsonDict = jsonDict, let element = jsonDict[key] else {
            return defaultValue
        }
        
        // Handle null values
        if element is NSNull {
            return defaultValue
        }
        
        switch expectedType {
        case .boolean:
            if let boolValue = element as? Bool {
                return boolValue as! T
            } else if let stringValue = element as? String {
                let parsed = safeBooleanParse(stringValue, defaultValue: DefaultValues.boolean)
                return parsed as! T
            }
            return defaultValue
            
        case .string:
            if let stringValue = element as? String {
                return stringValue as! T
            } else if let numberValue = element as? NSNumber {
                return String(describing: numberValue) as! T
            }
            return defaultValue
            
        case .int:
            if let intValue = element as? Int {
                return intValue as! T
            } else if let numberValue = element as? NSNumber {
                return numberValue.intValue as! T
            } else if let stringValue = element as? String {
                let parsed = safeIntParse(stringValue, defaultValue: DefaultValues.int)
                return parsed as! T
            }
            return defaultValue
            
        case .double:
            if let doubleValue = element as? Double {
                return doubleValue as! T
            } else if let numberValue = element as? NSNumber {
                return numberValue.doubleValue as! T
            } else if let stringValue = element as? String {
                let parsed = safeDoubleParse(stringValue, defaultValue: DefaultValues.double)
                return parsed as! T
            }
            return defaultValue
            
        case .long:
            if let int64Value = element as? Int64 {
                return int64Value as! T
            } else if let numberValue = element as? NSNumber {
                return numberValue.int64Value as! T
            } else if let stringValue = element as? String {
                let parsed = safeLongParse(stringValue, defaultValue: DefaultValues.long)
                return parsed as! T
            }
            return defaultValue
        }
    }
    
    // MARK: - Cached Value Extraction
    
    /// Extracts a cached value from accessedMap with type safety.
    /// Returns the cached value if found and type matches, nil otherwise.
    /// - Parameters:
    ///   - cachedVariable: Cached variable from access map
    ///   - expectedType: Expected data type
    ///   - defaultValue: Default value
    ///   - logger: Logger instance
    ///   - methodName: Method name for logging
    ///   - variableKey: Variable key for logging
    /// - Returns: Cached value if type matches, nil otherwise
    internal static func getCachedValue<T>(
        cachedVariable: ExperimentVariable?,
        expectedType: DataType,
        defaultValue: T,
        logger: ExperimentsLogger,
        methodName: String,
        variableKey: String
    ) -> T? {
        guard let cachedVariable = cachedVariable else {
            return nil
        }
        
        // Validate type if dataType is available
        if let dataType = cachedVariable.dataType, dataType != expectedType {
            logger.warning("\(methodName): Type mismatch for cached value '\(variableKey)': expected \(expectedType.apiValue), got \(dataType.apiValue)")
            return nil
        }
        
        // Extract value based on expected type
        switch expectedType {
        case .boolean:
            return cachedVariable.boolValue as? T
        case .string:
            return cachedVariable.stringValue as? T
        case .int:
            return cachedVariable.intValue as? T
        case .double:
            return cachedVariable.doubleValue as? T
        case .long:
            return cachedVariable.int64Value as? T
        }
    }
    
    // MARK: - Unified Type-Safe Retrieval
    
    /// Unified type-safe value retrieval following the fallback chain:
    /// 1. experimentMap -> variant.variables (type-safe from Variable objects)
    /// 2. defaultMap (type-safe extraction from JsonObject)
    /// 3. fallback (default value)
    /// 
    /// Note: accessedMap check should be done before calling this function.
    /// This function handles the experimentMap -> defaultMap -> fallback chain.
    /// - Parameters:
    ///   - experiment: Experiment from experimentMap
    ///   - defaultVariable: Default variable from defaultMap
    ///   - variableKey: Variable key to retrieve
    ///   - expectedType: Expected data type
    ///   - defaultValue: Default fallback value
    ///   - logger: Logger instance
    ///   - methodName: Method name for logging
    /// - Returns: Type-safe value following fallback chain
    internal static func getTypeSafeValue<T>(
        experiment: Experiment?,
        defaultVariable: ExperimentVariable?,
        variableKey: String,
        expectedType: DataType,
        defaultValue: T,
        logger: ExperimentsLogger,
        methodName: String
    ) -> T {
        // Step 1: Check experimentMap -> variant.variables (type-safe from Variable objects)
        if let experiment = experiment,
           let variables = experiment.variables,
           let variablesMap = variables.dictionaryValue,
           let variableObj = variablesMap[variableKey] {
            let convertedValue = convertValue(
                variable: variableObj,
                expectedType: expectedType,
                defaultValue: defaultValue,
                logger: logger,
                methodName: methodName,
                variableKey: variableKey
            )
            logger.debug("\(methodName): returning type-safe value from experimentMap for \(variableKey): \(convertedValue) (data_type: \(variableObj.dataType?.apiValue ?? "unknown"))")
            return convertedValue
        }
        
        // Step 2: Check defaultMap (type-safe extraction)
        if let defaultVariable = defaultVariable,
           let variablesMap = defaultVariable.dictionaryValue,
           let variableObj = variablesMap[variableKey] {
            let extractedValue = convertValue(
                variable: variableObj,
                expectedType: expectedType,
                defaultValue: defaultValue,
                logger: logger,
                methodName: methodName,
                variableKey: variableKey
            )
            // Check if we got a different value than default (meaning extraction succeeded)
            if extractedValue as? AnyHashable != defaultValue as? AnyHashable || variablesMap[variableKey] != nil {
                logger.debug("\(methodName): returning type-safe value from defaultMap for \(variableKey): \(extractedValue)")
                return extractedValue
            }
        }
        
        // Step 3: Return fallback value
        logger.debug("\(methodName): returning fallback value for \(variableKey)")
        return defaultValue
    }
}

