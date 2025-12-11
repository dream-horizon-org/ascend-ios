import Foundation

// MARK: - Ascend Serialization (Internal)

/// Internal serialization utilities for the Ascend SDK
@available(iOS 13.0, macOS 10.15, *)
internal final class AscendSerialization: @unchecked Sendable {
    
    // MARK: - Singleton
    
    internal static let shared = AscendSerialization()
    
    // MARK: - Properties
    
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    // MARK: - Private Initializer
    
    private init() {
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        
        // Configure encoder
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        // Configure decoder
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - Internal Interface
    
    /// Encode object to JSON data
    /// - Parameter object: The object to encode
    /// - Returns: Encoded JSON data
    /// - Throws: Encoding error
    internal func encode<T: Encodable>(_ object: T) throws -> Data {
        return try encoder.encode(object)
    }
    
    /// Decode JSON data to object
    /// - Parameters:
    ///   - data: The JSON data to decode
    ///   - type: The type to decode to
    /// - Returns: Decoded object
    /// - Throws: Decoding error
    internal func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        return try decoder.decode(type, from: data)
    }
    
    /// Encode object to JSON string
    /// - Parameter object: The object to encode
    /// - Returns: Encoded JSON string
    /// - Throws: Encoding error
    internal func encodeToString<T: Encodable>(_ object: T) throws -> String {
        let data = try encode(object)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    /// Decode JSON string to object
    /// - Parameters:
    ///   - jsonString: The JSON string to decode
    ///   - type: The type to decode to
    /// - Returns: Decoded object
    /// - Throws: Decoding error
    internal func decodeFromString<T: Decodable>(_ jsonString: String, as type: T.Type) throws -> T {
        guard let data = jsonString.data(using: .utf8) else {
            throw AscendSerializationError.invalidJSONString
        }
        return try decode(data, as: type)
    }
    
    /// Convert dictionary to JSON data
    /// - Parameter dictionary: The dictionary to convert
    /// - Returns: JSON data
    /// - Throws: Encoding error
    internal func dictionaryToJSON(_ dictionary: [String: Any]) throws -> Data {
        return try JSONSerialization.data(withJSONObject: dictionary, options: [])
    }
    
    /// Convert JSON data to dictionary
    /// - Parameter data: The JSON data to convert
    /// - Returns: Dictionary
    /// - Throws: Decoding error
    internal func jsonToDictionary(_ data: Data) throws -> [String: Any] {
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw AscendSerializationError.invalidJSONFormat
        }
        return dictionary
    }
    
    /// Convert JSON string to dictionary
    /// - Parameter jsonString: The JSON string to convert
    /// - Returns: Dictionary
    /// - Throws: Decoding error
    internal func jsonStringToDictionary(_ jsonString: String) throws -> [String: Any] {
        guard let data = jsonString.data(using: .utf8) else {
            throw AscendSerializationError.invalidJSONString
        }
        return try jsonToDictionary(data)
    }
    
    /// Convert dictionary to JSON string
    /// - Parameter dictionary: The dictionary to convert
    /// - Returns: JSON string
    /// - Throws: Encoding error
    internal func dictionaryToJSONString(_ dictionary: [String: Any]) throws -> String {
        let data = try dictionaryToJSON(dictionary)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

// MARK: - Serialization Errors

/// Serialization-related errors
internal enum AscendSerializationError: Error, LocalizedError {
    case invalidJSONString
    case invalidJSONFormat
    case encodingFailed(Error)
    case decodingFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidJSONString:
            return "Invalid JSON string"
        case .invalidJSONFormat:
            return "Invalid JSON format"
        case .encodingFailed(let error):
            return "Encoding failed: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        }
    }
}
