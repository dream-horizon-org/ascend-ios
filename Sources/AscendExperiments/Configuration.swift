import Foundation

// MARK: - Basic Experiments Configuration

/// Basic configuration for the AscendExperiments plugin
public struct AscendExperimentsConfiguration: AscendConfiguration, Sendable {
    public let pluginType: AscendPluginType = .experiments
    public let pluginName = "AscendExperiments"
    
    // MARK: - Core Configuration
    
    /// Whether to fetch experiments on plugin initialization
    public let shouldFetchOnInit: Bool
    
    /// Whether to fetch experiments when user logs out (defaults to false)
    public let shouldFetchOnLogout: Bool
    
    /// Whether to refresh experiments when app becomes active
    public let shouldRefreshOnForeground: Bool
    
    /// Default experiment values to use when API is unavailable
    public let defaultValues: [String: ExperimentVariable]
    
    // MARK: - API Configuration
    
    /// Base URL for experiments API
    public let apiBaseUrl: String
    
    /// Custom headers to include in API requests
    public let headers: [String: String]?
    
    /// API endpoint path (defaults to "/v1/users/experiments")
    public let apiEndpoint: String
    
    /// Custom attributes to include in API requests (e.g., platform, app_version, device_model)
    public let attributes: [String: String]?
    
    // MARK: - Networking Configuration
    
    /// Whether to retry failed requests
    public let shouldRetry: Bool
    
    /// Maximum number of retry attempts
    public let maxRetries: Int
    
    /// Request timeout in seconds
    public let timeout: TimeInterval
    
    // MARK: - Storage Configuration
    
    /// Whether to enable local caching
    public let enableCaching: Bool
    
    /// Cache expiration time in seconds
    public let cacheExpiration: TimeInterval
    
    // MARK: - Debug Configuration
    
    /// Whether to enable debug logging
    public let enableDebugLogging: Bool
    
    // MARK: - Initializers
    
    /// Default configuration
    public init(
        shouldFetchOnInit: Bool = true,
        shouldFetchOnLogout: Bool = false,
        shouldRefreshOnForeground: Bool = true,
        defaultValues: [String: ExperimentVariable] = [:],
        apiBaseUrl: String = "https://api.ascend.com",
        apiEndpoint: String = "/v1/users/experiments",
        headers: [String: String]? = nil,
        attributes: [String: String]? = nil,
        shouldRetry: Bool = true,
        maxRetries: Int = 3,
        timeout: TimeInterval = 30.0,
        enableCaching: Bool = true,
        cacheExpiration: TimeInterval = 3600, // 1 hour
        enableDebugLogging: Bool = false
    ) {
        self.shouldFetchOnInit = shouldFetchOnInit
        self.shouldFetchOnLogout = shouldFetchOnLogout
        self.shouldRefreshOnForeground = shouldRefreshOnForeground
        self.defaultValues = defaultValues
        self.apiBaseUrl = apiBaseUrl
        self.apiEndpoint = apiEndpoint
        self.headers = headers
        self.attributes = attributes
        self.shouldRetry = shouldRetry
        self.maxRetries = maxRetries
        self.timeout = timeout
        self.enableCaching = enableCaching
        self.cacheExpiration = cacheExpiration
        self.enableDebugLogging = enableDebugLogging
    }
    
    /// Development configuration with debug logging enabled
    public static func development(
        apiBaseUrl: String = "https://api.ascend.com",
        apiEndpoint: String = "/v1/allocations",
        defaultValues: [String: ExperimentVariable] = [:],
        headers: [String: String]? = nil,
        attributes: [String: String]? = nil,
        shouldFetchOnLogout: Bool = false
    ) -> AscendExperimentsConfiguration {
        return AscendExperimentsConfiguration(
            shouldFetchOnInit: true,
            shouldFetchOnLogout: shouldFetchOnLogout,
            shouldRefreshOnForeground: true,
            defaultValues: defaultValues,
            apiBaseUrl: apiBaseUrl,
            apiEndpoint: apiEndpoint,
            headers: headers,
            attributes: attributes,
            enableCaching: true,
            cacheExpiration: 300, // 5 minutes for development
            enableDebugLogging: true
        )
    }
    
    /// Production configuration optimized for performance
    public static func production(
        apiBaseUrl: String,
        defaultValues: [String: ExperimentVariable] = [:],
        shouldFetchOnLogout: Bool = false
    ) -> AscendExperimentsConfiguration {
        return AscendExperimentsConfiguration(
            shouldFetchOnInit: true,
            shouldFetchOnLogout: shouldFetchOnLogout,
            shouldRefreshOnForeground: true,
            defaultValues: defaultValues,
            apiBaseUrl: apiBaseUrl,
            shouldRetry: true,
            maxRetries: 3,
            timeout: 15.0, // Shorter timeout for production
            enableCaching: true,
            cacheExpiration: 3600, // 1 hour
            enableDebugLogging: false
        )
    }
    
    /// Testing configuration with minimal features
    public static func testing(
        apiBaseUrl: String = "https://test-api.ascend.com",
        defaultValues: [String: ExperimentVariable] = [:],
        shouldFetchOnLogout: Bool = false
    ) -> AscendExperimentsConfiguration {
        return AscendExperimentsConfiguration(
            shouldFetchOnInit: false,
            shouldFetchOnLogout: shouldFetchOnLogout,
            shouldRefreshOnForeground: false,
            defaultValues: defaultValues,
            apiBaseUrl: apiBaseUrl,
            shouldRetry: false,
            enableCaching: false,
            enableDebugLogging: true
        )
    }
}