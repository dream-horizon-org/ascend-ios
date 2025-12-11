import Foundation

// MARK: - Data Type Enum

/// Enum representing the data types supported for experiment variables.
/// Maps to the data_type field in the API response.
/// Matches Android's DataType enum implementation.
public enum DataType: String, Sendable, Codable {
    case boolean = "BOOLEAN"
    case string = "STRING"
    case int = "INT"
    case double = "DOUBLE"
    case long = "LONG"
    
    /// API value string representation
    public var apiValue: String {
        return rawValue
    }
    
    /// Converts API data_type string to DataType enum.
    /// Returns nil if the type is not recognized.
    /// Case-insensitive matching.
    public static func fromApiValue(_ apiValue: String?) -> DataType? {
        guard let apiValue = apiValue else { return nil }
        return DataType(rawValue: apiValue.uppercased())
    }
    
    /// Get default fallback value for this data type
    public var defaultValue: Any {
        switch self {
        case .boolean:
            return ExperimentsConstants.DataSource.BOOL_FALLBACK
        case .string:
            return ExperimentsConstants.DataSource.STRING_FALLBACK
        case .int:
            return ExperimentsConstants.DataSource.INT_FALLBACK
        case .double:
            return ExperimentsConstants.DataSource.DOUBLE_FALLBACK
        case .long:
            return ExperimentsConstants.DataSource.LONG_FALLBACK
        }
    }
}

