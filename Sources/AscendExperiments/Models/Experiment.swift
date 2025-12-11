import Foundation

// MARK: - Experiment Model (Modern Swift Implementation)

/// Represents a single experiment with all its metadata and variables
/// Following modern Swift practices with Codable, Sendable, and proper error handling
public struct Experiment: Codable, Sendable, CustomStringConvertible, Identifiable {
    
    // MARK: - Properties
    
    /// Unique identifier for the experiment
    public let experimentId: String
    
    /// Type of user identifier used for the experiment
    public let userIdentifierType: String
    
    /// Current status of the experiment (e.g., "active", "inactive", "completed")
    public let status: String
    
    /// Variables associated with this experiment
    public let variables: ExperimentVariable?
    
    /// API path for this experiment
    public let experimentKey: String
    
    /// Name of the variant for this experiment
    public let variantName: String
    
    // MARK: - Identifiable Conformance
    
    public var id: String { experimentId }
    
    // MARK: - Initializers
    
    public init(
        experimentId: String,
        userIdentifierType: String,
        status: String,
        variables: ExperimentVariable? = nil,
        experimentKey: String,
        variantName: String
    ) {
        self.experimentId = experimentId
        self.userIdentifierType = userIdentifierType
        self.status = status
        self.variables = variables
        self.experimentKey = experimentKey
        self.variantName = variantName
    }
    
    // MARK: - Convenience Properties
    
    /// Check if the experiment is active
    public var isActive: Bool {
        return status.lowercased() == "active"
    }
    
    /// Check if the experiment has variables
    public var hasVariables: Bool {
        return variables?.hasValue ?? false
    }
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        return """
        Experiment(
            id: \(experimentId),
            status: \(status),
            variant: \(variantName),
            experimentKey: \(experimentKey),
            hasVariables: \(hasVariables)
        )
        """
    }
}


// MARK: - Experiment Variant

/// Represents a simplified view of an experiment variant
public struct ExperimentVariant: Codable, Sendable, CustomStringConvertible, Identifiable {
    
    // MARK: - Properties
    
    public let experimentId: String
    public let variantName: String
    
    // MARK: - Identifiable Conformance
    
    public var id: String { "\(experimentId)-\(variantName)" }
    
    // MARK: - Initializers
    
    public init(experimentId: String, variantName: String) {
        self.experimentId = experimentId
        self.variantName = variantName
    }
    
    /// Create a variant from an experiment
    public init(from experiment: Experiment) {
        self.init(experimentId: experiment.experimentId, variantName: experiment.variantName)
    }
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        return "ExperimentVariant(id: \(experimentId), variant: \(variantName))"
    }
}

// MARK: - Experiment Response Models

/// Response from the experiments API
public struct ExperimentResponse: Codable, Sendable, CustomStringConvertible {
    
    // MARK: - Properties
    
    /// Array of experiments returned from the API
    public let data: [Experiment]?
    
    /// Error information if the request failed
    public let error: ExperimentResponseError?
    
    // MARK: - Initializers
    
    public init(data: [Experiment]? = nil, error: ExperimentResponseError? = nil) {
        self.data = data
        self.error = error
    }
    
    // MARK: - Convenience Properties
    
    /// Check if the response has data
    public var hasData: Bool {
        return data?.isEmpty == false
    }
    
    /// Check if the response has an error
    public var hasError: Bool {
        return error != nil
    }
    
    /// Get the first experiment if available
    public var firstExperiment: Experiment? {
        return data?.first
    }
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        if let error = error {
            return "ExperimentResponse(error: \(error.message ?? "Unknown error"))"
        } else if let data = data {
            return "ExperimentResponse(data: \(data.count) experiments)"
        } else {
            return "ExperimentResponse(empty)"
        }
    }
}

/// Error information from the experiments API
public struct ExperimentResponseError: Codable, Sendable, CustomStringConvertible {
    
    // MARK: - Properties
    
    /// Error message from the API
    public let message: String?
    
    // MARK: - Initializers
    
    public init(message: String?) {
        self.message = message
    }
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        return "ExperimentResponseError(message: \(message ?? "No message"))"
    }
}

// MARK: - Experiment Snapshot

/// Snapshot of experiments at a specific point in time
public struct ExperimentSnapshot: Codable, Sendable, CustomStringConvertible {
    
    // MARK: - Properties
    
    /// Timestamp when the snapshot was taken
    public let timestamp: Double
    
    /// Dictionary of experiments keyed by their API path
    public let data: [String: Experiment]
    
    // MARK: - Initializers
    
    public init(timestamp: Double, data: [String: Experiment]) {
        self.timestamp = timestamp
        self.data = data
    }
    
    /// Create a snapshot from current time
    public init(data: [String: Experiment]) {
        self.init(timestamp: Date().timeIntervalSince1970, data: data)
    }
    
    // MARK: - Convenience Properties
    
    /// Check if the snapshot has data
    public var hasData: Bool {
        return !data.isEmpty
    }
    
    /// Get all experiments as an array
    public var experiments: [Experiment] {
        return Array(data.values)
    }
    
    /// Get experiment count
    public var count: Int {
        return data.count
    }
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return "ExperimentSnapshot(timestamp: \(formatter.string(from: date)), count: \(count))"
    }
}

// MARK: - Equatable Conformance

extension Experiment: Equatable {
    public static func == (lhs: Experiment, rhs: Experiment) -> Bool {
        return lhs.experimentId == rhs.experimentId &&
               lhs.userIdentifierType == rhs.userIdentifierType &&
               lhs.status == rhs.status &&
               lhs.variables == rhs.variables &&
               lhs.experimentKey == rhs.experimentKey &&
               lhs.variantName == rhs.variantName
    }
}

extension ExperimentVariant: Equatable {
    public static func == (lhs: ExperimentVariant, rhs: ExperimentVariant) -> Bool {
        return lhs.experimentId == rhs.experimentId && lhs.variantName == rhs.variantName
    }
}

extension ExperimentResponse: Equatable {
    public static func == (lhs: ExperimentResponse, rhs: ExperimentResponse) -> Bool {
        return lhs.data == rhs.data && lhs.error == rhs.error
    }
}

extension ExperimentResponseError: Equatable {
    public static func == (lhs: ExperimentResponseError, rhs: ExperimentResponseError) -> Bool {
        return lhs.message == rhs.message
    }
}

extension ExperimentSnapshot: Equatable {
    public static func == (lhs: ExperimentSnapshot, rhs: ExperimentSnapshot) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.data == rhs.data
    }
}

// MARK: - Experiment Request Payload

/// Payload for experiments API request
/// Matches PluggerExperiments ExperimentPayload structure
public struct ExperimentPayload: Codable, Sendable {
    public let experimentKeys: [String]
    
    public init(experimentKeys: [String]) {
        self.experimentKeys = experimentKeys
    }
}

// MARK: - API Response Format Models

/// Variable object from the new API format
/// Contains value, key, and data_type
internal struct APIExperimentVariable: Codable, Sendable {
    let value: String
    let key: String
    let dataType: String
    
    enum CodingKeys: String, CodingKey {
        case value
        case key
        case dataType = "data_type"
    }
}

// MARK: - Experiment Codable Implementation

extension Experiment {
    enum CodingKeys: String, CodingKey {
        case experimentId = "experiment_id"
        case userIdentifierType = "user_identifier_type"
        case status
        case variables
        case experimentKey = "experiment_key"
        case variantName = "variant_name"
    }
    
    /// Custom decoder to handle both old (dictionary) and new (array) variable formats
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        experimentId = try container.decode(String.self, forKey: .experimentId)
        userIdentifierType = try container.decode(String.self, forKey: .userIdentifierType)
        status = try container.decode(String.self, forKey: .status)
        experimentKey = try container.decode(String.self, forKey: .experimentKey)
        variantName = try container.decode(String.self, forKey: .variantName)
        
        // Handle variables - try new format first (array), then fallback to old format (dictionary)
        if let variablesArray = try? container.decode([APIExperimentVariable].self, forKey: .variables) {
            // NEW FORMAT: Array of variable objects with data_type
            var variablesDict: [String: ExperimentVariable] = [:]
            
            for apiVar in variablesArray {
                // Convert value based on data_type
                let experimentVar = ExperimentVariable.fromAPI(
                    value: apiVar.value,
                    dataType: apiVar.dataType
                )
                variablesDict[apiVar.key] = experimentVar
            }
            
            self.variables = variablesDict.isEmpty ? nil : ExperimentVariable(dictionaryValue: variablesDict)
        } else {
            // OLD FORMAT: Dictionary (existing behavior)
            // Try to decode as ExperimentVariable which handles dictionary format
            self.variables = try? container.decode(ExperimentVariable.self, forKey: .variables)
        }
    }
    
    /// Custom encoder
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(experimentId, forKey: .experimentId)
        try container.encode(userIdentifierType, forKey: .userIdentifierType)
        try container.encode(status, forKey: .status)
        try container.encode(experimentKey, forKey: .experimentKey)
        try container.encode(variantName, forKey: .variantName)
        
        if let variables = variables {
            try container.encode(variables, forKey: .variables)
        }
    }
}

// MARK: - Allocations API Response Models

/// Payload for allocations API request
internal struct AllocationsPayload: Codable, Sendable {
    let experimentKeys: [String]
    let stableId: String
    let userId: String?
    let attributes: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case experimentKeys = "experiment_keys"
        case stableId = "stable_id"
        case userId = "user_id"
        case attributes
    }
}

/// Response structure from allocations API
internal struct AllocationsAPIResponse: Codable, Sendable {
    let data: AllocationsResponseData?
    let error: ExperimentResponseError?
}

internal struct AllocationsResponseData: Codable, Sendable {
    let experimentMap: [AllocationsExperiment]?
    
    enum CodingKeys: String, CodingKey {
        case experimentMap = "experiment_map"
    }
}

/// Experiment structure from allocations API
internal struct AllocationsExperiment: Codable, Sendable {
    let experimentId: String?
    let experimentKey: String?
    let experimentName: String?
    let status: String
    let variant: AllocationsVariant?
    let variantName: String?
    let assignedAt: Int64?
    
    enum CodingKeys: String, CodingKey {
        case experimentId = "experiment_id"
        case experimentKey = "experiment_key"
        case experimentName = "experiment_name"
        case status
        case variant
        case variantName = "variant_name"
        case assignedAt = "assigned_at"
    }
}

/// Variant structure from allocations API
internal struct AllocationsVariant: Codable, Sendable {
    let displayName: String?
    let variantName: String?
    let variables: [AllocationsVariable]?
    
    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case variantName = "variant_name"
        case variables
    }
}

/// Variable structure from allocations API
internal struct AllocationsVariable: Codable, Sendable {
    let value: String
    let key: String
    let dataType: String
    
    enum CodingKeys: String, CodingKey {
        case value
        case key
        case dataType = "data_type"
    }
}
