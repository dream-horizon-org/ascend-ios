import Foundation

// MARK: - Experiments Constants

/// Constants for experiments data source
internal struct ExperimentsConstants {
    
    // MARK: - Data Source Constants
    
    /// Fallback values for experiments data source
    struct DataSource {
        static let BOOL_FALLBACK = false
        static let INT_FALLBACK = -1
        static let LONG_FALLBACK = Int64(INT_FALLBACK)
        static let DOUBLE_FALLBACK = -1.0
        static let STRING_FALLBACK = ""
    }
    
    // MARK: - Storage Constants
    
    /// Storage-related constants
    struct Storage {
        static let EXPERIMENTS_FILE_NAME = "ascend_experiments.json"
        static let CACHE_EXPIRATION_DEFAULT = 300 // 5 minutes
    }
    
    // MARK: - API Constants
    
    /// API-related constants
    struct API {
        static let DEFAULT_ENDPOINT = "/v1/users/experiments"
        static let QUERY_PARAM_TYPE = "type"
        static let QUERY_PARAM_TYPE_VALUE = "FE"
        static let HEADER_API_KEY = "api-key"
        static let HEADER_USER_ID = "user-id"
        static let HEADER_GUEST_ID = "guest-id"
        static let HEADER_CONTENT_TYPE = "content-type"
        static let CONTENT_TYPE_JSON = "application/json"
    }
    
    // MARK: - Logging Constants
    
    /// Logging-related constants
    struct Logging {
        static let TAG = "AscendExperiments"
        static let CACHE_TAG = "ExperimentsAccessMap"
        static let API_TAG = "ExperimentsAPI"
        static let DATASOURCE_TAG = "ExperimentsDataSource"
    }
}
