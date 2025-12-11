import Foundation

// MARK: - Ascend Configuration System

/// Main configuration for the Ascend SDK
/// Contains all necessary settings for plugins, HTTP, and client configuration
public struct AscendConfig: Sendable {
    
    // MARK: - Properties
    
    /// List of plugins to initialize
    public let plugins: [AscendPlugin]
    
    /// HTTP configuration for network requests
    public let httpConfig: HTTPConfig
    
    /// Core configuration for the SDK
    public let coreConfig: AscendCoreConfig
    
    // MARK: - Initializers
    
    /// Create Ascend configuration
    /// - Parameters:
    ///   - plugins: List of plugins to initialize
    ///   - httpConfig: HTTP configuration
    ///   - coreConfig: Core SDK configuration
    public init(
        plugins: [AscendPlugin],
        httpConfig: HTTPConfig,
        coreConfig: AscendCoreConfig
    ) {
        self.plugins = plugins
        self.httpConfig = httpConfig
        self.coreConfig = coreConfig
    }
    
    /// Convenience initializer with default HTTP config
    /// - Parameters:
    ///   - plugins: List of plugins to initialize
    ///   - coreConfig: Core SDK configuration
    public init(
        plugins: [AscendPlugin],
        coreConfig: AscendCoreConfig
    ) {
        self.plugins = plugins
        self.httpConfig = HTTPConfig()
        self.coreConfig = coreConfig
    }
}

// MARK: - HTTP Configuration

/// HTTP configuration for network requests
public struct HTTPConfig: Sendable {
    
    // MARK: - Properties
    
    /// Base URL for API requests
    public let apiBaseUrl: String
    
    /// Request timeout in seconds
    public let timeout: TimeInterval
    
    /// Whether to retry failed requests
    public let shouldRetry: Bool
    
    /// Delay between retry attempts in seconds
    public let retryDelay: TimeInterval
    
    /// Maximum number of retry attempts
    public let maxRetries: Int
    
    /// Default headers to include in all requests
    public let defaultHeaders: [String: String]
    
    // MARK: - Initializers
    
    /// Create HTTP configuration
    /// - Parameters:
    ///   - apiBaseUrl: Base URL for API requests
    ///   - timeout: Request timeout in seconds (default: 30)
    ///   - shouldRetry: Whether to retry failed requests (default: true)
    ///   - retryDelay: Delay between retry attempts (default: 1.0)
    ///   - maxRetries: Maximum number of retry attempts (default: 3)
    ///   - defaultHeaders: Default headers for all requests
    public init(
        apiBaseUrl: String = "https://api.ascend.com",
        timeout: TimeInterval = 30.0,
        shouldRetry: Bool = true,
        retryDelay: TimeInterval = 1.0,
        maxRetries: Int = 3,
        defaultHeaders: [String: String] = [:]
    ) {
        self.apiBaseUrl = apiBaseUrl
        self.timeout = timeout
        self.shouldRetry = shouldRetry
        self.retryDelay = retryDelay
        self.maxRetries = maxRetries
        self.defaultHeaders = defaultHeaders
    }
}

// MARK: - Core Configuration

/// Core configuration for the Ascend SDK
public struct AscendCoreConfig: Sendable {
    
    // MARK: - Properties
    
    /// API key for authentication
    public let apiKey: String
    
    /// Environment (development, staging, production)
    public let environment: String
    
    /// Whether to enable debug logging
    public let enableDebugLogging: Bool
    
    /// Whether to enable performance monitoring
    public let enablePerformanceMonitoring: Bool
    
    /// Whether to enable crash reporting
    public let enableCrashReporting: Bool
    
    // MARK: - Initializers
    
    /// Create core configuration
    /// - Parameters:
    ///   - apiKey: API key for authentication
    ///   - environment: Environment (development, staging, production)
    ///   - enableDebugLogging: Whether to enable debug logging (default: false)
    ///   - enablePerformanceMonitoring: Whether to enable performance monitoring (default: true)
    ///   - enableCrashReporting: Whether to enable crash reporting (default: true)
    public init(
        apiKey: String,
        environment: String,
        enableDebugLogging: Bool = false,
        enablePerformanceMonitoring: Bool = true,
        enableCrashReporting: Bool = true
    ) {
        self.apiKey = apiKey
        self.environment = environment
        self.enableDebugLogging = enableDebugLogging
        self.enablePerformanceMonitoring = enablePerformanceMonitoring
        self.enableCrashReporting = enableCrashReporting
    }
}
