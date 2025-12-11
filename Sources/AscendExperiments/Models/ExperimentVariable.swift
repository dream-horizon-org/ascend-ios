import Foundation

// MARK: - AnyCodable Helper

/// Helper type to decode any JSON value
private struct AnyCodable: Codable {
    let boolValue: Bool?
    let intValue: Int?
    let doubleValue: Double?
    let stringValue: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let boolVal = try? container.decode(Bool.self) {
            self.boolValue = boolVal
            self.intValue = nil
            self.doubleValue = nil
            self.stringValue = nil
        } else if let intVal = try? container.decode(Int.self) {
            self.boolValue = nil
            self.intValue = intVal
            self.doubleValue = nil
            self.stringValue = nil
        } else if let doubleVal = try? container.decode(Double.self) {
            self.boolValue = nil
            self.intValue = nil
            self.doubleValue = doubleVal
            self.stringValue = nil
        } else if let stringVal = try? container.decode(String.self) {
            self.boolValue = nil
            self.intValue = nil
            self.doubleValue = nil
            self.stringValue = stringVal
        } else {
            self.boolValue = nil
            self.intValue = nil
            self.doubleValue = nil
            self.stringValue = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let boolVal = boolValue {
            try container.encode(boolVal)
        } else if let intVal = intValue {
            try container.encode(intVal)
        } else if let doubleVal = doubleValue {
            try container.encode(doubleVal)
        } else if let stringVal = stringValue {
            try container.encode(stringVal)
        }
    }
}

// MARK: - Experiment Variable (Following plugger-ios approach)

/// A flexible variable type that can hold various data types for experiments
/// Following modern Swift practices with Codable, Sendable, and proper error handling
public struct ExperimentVariable: Sendable, CustomStringConvertible {
    
    // MARK: - Properties
    
    public let boolValue: Bool?
    public let intValue: Int?
    public let int64Value: Int64?
    public let doubleValue: Double?
    public let stringValue: String?
    public let listValue: [ExperimentVariable]?
    public let dictionaryValue: [String: ExperimentVariable]?
    
    /// Data type from API (preserved for type validation)
    /// This allows us to validate types on retrieval, matching Android behavior
    public let dataType: DataType?
    
    // MARK: - Initializers
    
    /// Main initializer - only one should have a non-nil value
    public init(
        boolValue: Bool? = nil,
        intValue: Int? = nil,
        int64Value: Int64? = nil,
        doubleValue: Double? = nil,
        stringValue: String? = nil,
        listValue: [ExperimentVariable]? = nil,
        dictionaryValue: [String: ExperimentVariable]? = nil,
        dataType: DataType? = nil
    ) {
        self.boolValue = boolValue
        self.intValue = intValue
        self.int64Value = int64Value
        self.doubleValue = doubleValue
        self.stringValue = stringValue
        self.listValue = listValue
        self.dictionaryValue = dictionaryValue
        self.dataType = dataType
    }
    
    // MARK: - Convenience Initializers
    
    public static func bool(_ value: Bool) -> ExperimentVariable {
        return ExperimentVariable(boolValue: value, dataType: .boolean)
    }
    
    public static func int(_ value: Int) -> ExperimentVariable {
        return ExperimentVariable(intValue: value, dataType: .int)
    }
    
    public static func int64(_ value: Int64) -> ExperimentVariable {
        return ExperimentVariable(int64Value: value, dataType: .long)
    }
    
    public static func double(_ value: Double) -> ExperimentVariable {
        return ExperimentVariable(doubleValue: value, dataType: .double)
    }
    
    public static func string(_ value: String) -> ExperimentVariable {
        return ExperimentVariable(stringValue: value, dataType: .string)
    }
    
    public static func list(_ value: [ExperimentVariable]) -> ExperimentVariable {
        return ExperimentVariable(listValue: value, dataType: nil)
    }
    
    public static func dictionary(_ value: [String: ExperimentVariable]) -> ExperimentVariable {
        return ExperimentVariable(dictionaryValue: value, dataType: nil)
    }
    
    // MARK: - API Conversion
    
    /// Convert a value from the new API format based on data_type
    /// - Parameters:
    ///   - value: The string value from the API
    ///   - dataType: The data type (STRING, BOOL, INT, DOUBLE, etc.)
    /// - Returns: ExperimentVariable with the correctly typed value and preserved dataType
    static func fromAPI(value: String, dataType: String) -> ExperimentVariable {
        // Convert API string to DataType enum
        let normalizedType = dataType.uppercased()
        let dataTypeEnum: DataType?

        // Map API types to DataType enum
        switch normalizedType {
        case "BOOL", "BOOLEAN":
            dataTypeEnum = .boolean
        case "INT", "INTEGER", "NUMBER":
            dataTypeEnum = .int
        case "LONG", "INT64":
            dataTypeEnum = .long
        case "DOUBLE", "FLOAT":
            dataTypeEnum = .double
        case "STRING", "TEXT":
            dataTypeEnum = .string
        default:
            // Try to infer from DataType enum
            dataTypeEnum = DataType.fromApiValue(dataType)
        }
        
        // Convert value based on data type and preserve dataType
        switch normalizedType {
        case "BOOL", "BOOLEAN":
            // Convert string "true"/"false" to Bool
            let boolValue = value.lowercased() == "true"
            return ExperimentVariable(boolValue: boolValue, dataType: dataTypeEnum)
            
        case "INT", "INTEGER":
            // Convert string to Int
            if let intValue = Int(value) {
                return ExperimentVariable(intValue: intValue, dataType: dataTypeEnum)
            }
            // Fallback to string if conversion fails
            return ExperimentVariable(stringValue: value, dataType: .string)
            
        case "NUMBER":
            if let intValue = Int(value) {
                return ExperimentVariable(intValue: intValue, dataType: dataTypeEnum)
            } else if let doubleValue = Double(value) {
                return ExperimentVariable(doubleValue: doubleValue, dataType: dataTypeEnum)
            }
            // Fallback to string if conversion fails
            return ExperimentVariable(stringValue: value, dataType: .string)
            
        case "LONG", "INT64":
            // Convert string to Int64
            if let int64Value = Int64(value) {
                return ExperimentVariable(int64Value: int64Value, dataType: dataTypeEnum)
            }
            // Fallback to string if conversion fails
            return ExperimentVariable(stringValue: value, dataType: .string)
            
        case "DOUBLE", "FLOAT":
            // Convert string to Double
            if let doubleValue = Double(value) {
                return ExperimentVariable(doubleValue: doubleValue, dataType: dataTypeEnum)
            }
            // Fallback to string if conversion fails
            return ExperimentVariable(stringValue: value, dataType: .string)
            
        case "STRING", "TEXT":
            // Keep as string
            return ExperimentVariable(stringValue: value, dataType: dataTypeEnum ?? .string)
            
        default:
            // Unknown type - default to string
            return ExperimentVariable(stringValue: value, dataType: .string)
        }
    }
    
    // MARK: - Value Access
    
    /// Get the actual value as Any (for compatibility)
    public var value: Any? {
        if boolValue != nil { return boolValue }
        if intValue != nil { return intValue }
        if int64Value != nil { return int64Value }
        if doubleValue != nil { return doubleValue }
        if stringValue != nil { return stringValue }
        if listValue != nil { return listValue }
        if dictionaryValue != nil { return dictionaryValue }
        return nil
    }
    
    /// Check if the variable has any value
    public var hasValue: Bool {
        return value != nil
    }
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        let typeInfo = dataType != nil ? " [\(dataType?.apiValue ?? "")]" : ""
        if let boolValue = boolValue {
            return "Bool(\(boolValue))\(typeInfo)"
        } else if let intValue = intValue {
            return "Int(\(intValue))\(typeInfo)"
        } else if let int64Value = int64Value {
            return "Int64(\(int64Value))\(typeInfo)"
        } else if let doubleValue = doubleValue {
            return "Double(\(doubleValue))\(typeInfo)"
        } else if let stringValue = stringValue {
            return "String(\(stringValue))\(typeInfo)"
        } else if let listValue = listValue {
            return "List(\(listValue.count) items)\(typeInfo)"
        } else if let dictionaryValue = dictionaryValue {
            return "Dictionary(\(dictionaryValue.count) keys)\(typeInfo)"
        } else {
            return "Empty\(typeInfo)"
        }
    }
}

// MARK: - Codable Implementation

extension ExperimentVariable: Codable {
    
    /// Custom encoding to handle the flexible type system
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let boolValue = boolValue {
            try container.encode(boolValue)
        } else if let intValue = intValue {
            try container.encode(intValue)
        } else if let int64Value = int64Value {
            try container.encode(int64Value)
        } else if let doubleValue = doubleValue {
            try container.encode(doubleValue)
        } else if let stringValue = stringValue {
            try container.encode(stringValue)
        } else if let listValue = listValue {
            try container.encode(listValue)
        } else if let dictionaryValue = dictionaryValue {
            try container.encode(dictionaryValue)
        } else {
            // Encode as null for empty variables
            try container.encodeNil()
        }
    }
    
    /// Custom decoding following plugger-ios approach exactly
    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            
            // Try to decode as each type, following plugger-ios pattern exactly
            if let boolValue = try? container.decode(Bool.self) {
                self.init(boolValue: boolValue)
            } else if let intValue = try? container.decode(Int.self) {
                self.init(intValue: intValue)
            } else if let int64Value = try? container.decode(Int64.self) {
                self.init(int64Value: int64Value)
            } else if let doubleValue = try? container.decode(Double.self) {
                self.init(doubleValue: doubleValue)
            } else if let stringValue = try? container.decode(String.self) {
                self.init(stringValue: stringValue)
            } else if let listValue = try? container.decode([ExperimentVariable].self) {
                self.init(listValue: listValue)
            } else if let dictionaryValue = try? container.decode([String: ExperimentVariable].self) {
                self.init(dictionaryValue: dictionaryValue)
            } else {
                // Handle case where API returns {"color": "red"} - decode as generic dictionary and convert values
                // This is the key fix for the API response format
                do {
                    // Try to decode as a generic dictionary first
                    let genericDict = try container.decode([String: AnyCodable].self)
                    var convertedDict: [String: ExperimentVariable] = [:]
                    
                    for (key, value) in genericDict {
                        if let boolVal = value.boolValue {
                            convertedDict[key] = ExperimentVariable(boolValue: boolVal)
                        } else if let intVal = value.intValue {
                            convertedDict[key] = ExperimentVariable(intValue: intVal)
                        } else if let doubleVal = value.doubleValue {
                            convertedDict[key] = ExperimentVariable(doubleValue: doubleVal)
                        } else if let stringVal = value.stringValue {
                            convertedDict[key] = ExperimentVariable(stringValue: stringVal)
                        }
                    }
                    self.init(dictionaryValue: convertedDict)
                } catch {
                    print("🔍 ExperimentVariable decoding error: \(error)")
                    // If all else fails, create an empty variable (following plugger-ios error handling)
                    self.init()
                }
            }
        } catch {
            print("🔍 ExperimentVariable decoding error: \(error)")
            // If all else fails, create an empty variable (following plugger-ios error handling)
            self.init()
        }
    }
}

// MARK: - Equatable

extension ExperimentVariable: Equatable {
    public static func == (lhs: ExperimentVariable, rhs: ExperimentVariable) -> Bool {
        return lhs.boolValue == rhs.boolValue &&
               lhs.intValue == rhs.intValue &&
               lhs.int64Value == rhs.int64Value &&
               lhs.doubleValue == rhs.doubleValue &&
               lhs.stringValue == rhs.stringValue &&
               lhs.listValue == rhs.listValue &&
               lhs.dictionaryValue == rhs.dictionaryValue &&
               lhs.dataType == rhs.dataType
    }
}
