import Foundation

// MARK: - Retry Configuration Models

/// Configuration for retry behavior
public struct RetryConfig: Sendable {
    /// Maximum number of retry attempts
    public let maxAttempts: Int
    
    /// Base delay in seconds before first retry
    public let baseDelay: TimeInterval
    
    /// Maximum delay between retries
    public let maxDelay: TimeInterval
    
    /// Multiplier for exponential backoff
    public let backoffMultiplier: Double
    
    /// Status codes that should not trigger retries
    public let omitRetryForStatusCodes: Set<Int>
    
    /// Whether to use jitter to prevent thundering herd
    public let useJitter: Bool
    
    public init(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        backoffMultiplier: Double = 2.0,
        omitRetryForStatusCodes: Set<Int> = [400, 401, 403, 404],
        useJitter: Bool = true
    ) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
        self.omitRetryForStatusCodes = omitRetryForStatusCodes
        self.useJitter = useJitter
    }
}

/// Configuration for timeout behavior
public struct TimeoutConfig: Sendable {
    /// Request timeout in seconds
    public let requestTimeout: TimeInterval
    
    /// Resource timeout in seconds
    public let resourceTimeout: TimeInterval
    
    public init(
        requestTimeout: TimeInterval = 30.0,
        resourceTimeout: TimeInterval = 60.0
    ) {
        self.requestTimeout = requestTimeout
        self.resourceTimeout = resourceTimeout
    }
}

/// Complete HTTP configuration for networking
public struct NetworkHTTPConfig: Sendable {
    /// Base URL for requests
    public let baseURL: String
    
    /// Additional headers
    public let headers: [String: String]
    
    /// Retry configuration
    public let retryConfig: RetryConfig
    
    /// Timeout configuration
    public let timeoutConfig: TimeoutConfig
    
    /// Whether to enable retries
    public let enableRetries: Bool
    
    public init(
        baseURL: String,
        headers: [String: String] = [:],
        retryConfig: RetryConfig = RetryConfig(),
        timeoutConfig: TimeoutConfig = TimeoutConfig(),
        enableRetries: Bool = true
    ) {
        self.baseURL = baseURL
        self.headers = headers
        self.retryConfig = retryConfig
        self.timeoutConfig = timeoutConfig
        self.enableRetries = enableRetries
    }
}

// MARK: - Network Operation Info

/// Information about a network operation
internal struct NetworkOperationInfo: Sendable {
    let request: URLRequest
    let retryAttempt: Int
    let startTime: Date
    let operationId: UUID
    
    init(request: URLRequest, retryAttempt: Int = 0) {
        self.request = request
        self.retryAttempt = retryAttempt
        self.startTime = Date()
        self.operationId = UUID()
    }
}

// MARK: - Network Response Info

/// Information about a network response
public struct NetworkResponseInfo: Sendable {
    /// HTTP status code
    public let statusCode: Int
    
    /// Response headers
    public let headers: [String: String]
    
    /// Response data
    public let data: Data?
    
    /// Request duration
    public let duration: TimeInterval
    
    /// Whether this was a cached response
    public let isCached: Bool
    
    /// Cache timestamp if applicable
    public let cacheTimestamp: Date?
    
    public init(
        statusCode: Int,
        headers: [String: String] = [:],
        data: Data? = nil,
        duration: TimeInterval,
        isCached: Bool = false,
        cacheTimestamp: Date? = nil
    ) {
        self.statusCode = statusCode
        self.headers = headers
        self.data = data
        self.duration = duration
        self.isCached = isCached
        self.cacheTimestamp = cacheTimestamp
    }
}

/// Internal networking utilities for the Ascend SDK
@available(iOS 13.0, macOS 10.15, *)
internal final class AscendNetworking: @unchecked Sendable {
    
    // MARK: - Singleton
    
    internal static let shared = AscendNetworking()
    
    // MARK: - Properties
    
    private let session: URLSession
    private let operationQueue: OperationQueue
    private let completionQueue: DispatchQueue
    private let cache: NetworkCache
    private let logger: AscendLogger
    
    // MARK: - Private Initializer
    
    private init() {
        self.logger = AscendLogger.shared
        
        // Configure operation queue
        self.operationQueue = OperationQueue()
        self.operationQueue.name = "com.ascend.networking.queue"
        self.operationQueue.maxConcurrentOperationCount = 6
        self.operationQueue.qualityOfService = .userInitiated
        
        // Configure completion queue
        self.completionQueue = DispatchQueue.main
        
        // Configure URL session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpMaximumConnectionsPerHost = 6
        
        self.session = URLSession(configuration: config)
        
        // Initialize cache
        self.cache = NetworkCache()
        
        logger.info("AscendNetworking initialized with operation queue management")
    }
    
    // MARK: - Public Interface
    
    /// Perform HTTP request with retry logic and caching
    /// - Parameters:
    ///   - request: The URL request to perform
    ///   - config: HTTP configuration including retry and timeout settings
    ///   - completion: Completion handler with result
    internal func performRequest(
        _ request: URLRequest,
        config: NetworkHTTPConfig,
        completion: @escaping (Result<NetworkResponseInfo, Error>) -> Void
    ) {
        let operationInfo = NetworkOperationInfo(request: request)
        
        // Check cache first
        if let cachedResponse = cache.getCachedResponse(for: request) {
            let responseInfo = NetworkResponseInfo(
                statusCode: cachedResponse.statusCode,
                headers: cachedResponse.headers,
                data: cachedResponse.data,
                duration: Date().timeIntervalSince(operationInfo.startTime),
                isCached: true,
                cacheTimestamp: cachedResponse.timestamp
            )
            completionQueue.async {
                completion(.success(responseInfo))
            }
            return
        }
        
        // Create network operation
        let operation = NetworkOperation(
            session: session,
            operationInfo: operationInfo,
            config: config,
            cache: cache,
            logger: logger
        ) { [weak self] result in
            guard let self = self else { return }
            self.completionQueue.async {
                completion(result)
            }
        }
        
        // Add to operation queue
        operationQueue.addOperation(operation)
    }
    
    /// Create URL request with configuration
    /// - Parameters:
    ///   - url: The URL to request
    ///   - method: HTTP method
    ///   - headers: Additional headers
    ///   - body: Request body data
    ///   - config: HTTP configuration
    /// - Returns: Configured URL request
    internal func createRequest(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil,
        config: NetworkHTTPConfig
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Apply timeout configuration
        request.timeoutInterval = config.timeoutConfig.requestTimeout
        
        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Ascend-iOS-SDK", forHTTPHeaderField: "User-Agent")
        
        // Add config headers
        for (key, value) in config.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    /// Cancel all pending operations
    internal func cancelAllOperations() {
        operationQueue.cancelAllOperations()
        logger.info("Cancelled all pending network operations")
    }
    
    /// Get current operation count
    internal var operationCount: Int {
        return operationQueue.operationCount
    }
    
    /// Clear cache
    internal func clearCache() {
        cache.clearCache()
        logger.info("Network cache cleared")
    }
}

// MARK: - Network Operation

/// Network operation with retry logic
internal final class NetworkOperation: Operation, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let operationInfo: NetworkOperationInfo
    private let config: NetworkHTTPConfig
    private let cache: NetworkCache
    private let logger: AscendLogger
    private let completion: (Result<NetworkResponseInfo, Error>) -> Void
    
    private var _isExecuting = false
    private var _isFinished = false
    
    // MARK: - Operation State
    
    override var isExecuting: Bool {
        return _isExecuting
    }
    
    override var isFinished: Bool {
        return _isFinished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    // MARK: - Initialization
    
    init(
        session: URLSession,
        operationInfo: NetworkOperationInfo,
        config: NetworkHTTPConfig,
        cache: NetworkCache,
        logger: AscendLogger,
        completion: @escaping (Result<NetworkResponseInfo, Error>) -> Void
    ) {
        self.session = session
        self.operationInfo = operationInfo
        self.config = config
        self.cache = cache
        self.logger = logger
        self.completion = completion
        super.init()
    }
    
    // MARK: - Operation Execution
    
    override func start() {
        guard !isCancelled else {
            finish()
            return
        }
        
        willChangeValue(forKey: "isExecuting")
        _isExecuting = true
        didChangeValue(forKey: "isExecuting")
        
        performRequestWithRetry()
    }
    
    private func performRequestWithRetry() {
        guard !isCancelled else {
            finish()
            return
        }
        
        let task = session.dataTask(with: operationInfo.request) { [weak self] data, response, error in
            guard let self = self else { return }
            self.handleResponse(data: data, response: response, error: error)
        }
        
        task.resume()
    }
    
    private func handleResponse(data: Data?, response: URLResponse?, error: Error?) {
        guard !isCancelled else {
            finish()
            return
        }
        
        let duration = Date().timeIntervalSince(operationInfo.startTime)
        
        // Handle network errors
        if let error = error {
            handleError(error, duration: duration)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            handleError(AscendNetworkingError.invalidResponse, duration: duration)
            return
        }
        
        // Extract headers
        let headers = Dictionary<String, String>(uniqueKeysWithValues: httpResponse.allHeaderFields.compactMap { key, value in
            guard let keyString = key as? String, let valueString = value as? String else { return nil }
            return (keyString, valueString)
        })
        
        // Handle HTTP status codes
        switch httpResponse.statusCode {
        case 200...299:
            // Success - cache response if appropriate
            if shouldCacheResponse(httpResponse) {
                cache.cacheResponse(
                    statusCode: httpResponse.statusCode,
                    headers: headers,
                    data: data,
                    for: operationInfo.request
                )
            }
            
            let responseInfo = NetworkResponseInfo(
                statusCode: httpResponse.statusCode,
                headers: headers,
                data: data,
                duration: duration
            )
            complete(with: .success(responseInfo))
            
        case 304:
            // Not Modified - use cached response
            if let cachedResponse = cache.getCachedResponse(for: operationInfo.request) {
                let responseInfo = NetworkResponseInfo(
                    statusCode: cachedResponse.statusCode,
                    headers: cachedResponse.headers,
                    data: cachedResponse.data,
                    duration: duration,
                    isCached: true,
                    cacheTimestamp: cachedResponse.timestamp
                )
                complete(with: .success(responseInfo))
            } else {
                handleError(AscendNetworkingError.notFound, duration: duration)
            }
            
        default:
            // Check if we should retry
            if shouldRetry(statusCode: httpResponse.statusCode) {
                scheduleRetry()
            } else {
                let networkingError = createNetworkingError(for: httpResponse.statusCode)
                handleError(networkingError, duration: duration)
            }
        }
    }
    
    private func handleError(_ error: Error, duration: TimeInterval) {
        if shouldRetry(error: error) {
            scheduleRetry()
        } else {
            complete(with: .failure(error))
        }
    }
    
    private func scheduleRetry() {
        guard !isCancelled else {
            finish()
            return
        }
        
        let currentAttempt = operationInfo.retryAttempt + 1
        
        guard currentAttempt < config.retryConfig.maxAttempts else {
            complete(with: .failure(AscendNetworkingError.maxRetriesExceeded))
            return
        }
        
        let delay = calculateRetryDelay(attempt: currentAttempt)
        
        logger.info("Retrying request (attempt \(currentAttempt)/\(config.retryConfig.maxAttempts)) after \(delay)s")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self, !self.isCancelled else { return }
            
            let newOperationInfo = NetworkOperationInfo(
                request: self.operationInfo.request,
                retryAttempt: currentAttempt
            )
            
            let newOperation = NetworkOperation(
                session: self.session,
                operationInfo: newOperationInfo,
                config: self.config,
                cache: self.cache,
                logger: self.logger,
                completion: self.completion
            )
            
            // Add to the same operation queue
            OperationQueue.current?.addOperation(newOperation)
        }
        
        finish()
    }
    
    private func calculateRetryDelay(attempt: Int) -> TimeInterval {
        let baseDelay = config.retryConfig.baseDelay
        let multiplier = config.retryConfig.backoffMultiplier
        let maxDelay = config.retryConfig.maxDelay
        
        let exponentialDelay = baseDelay * pow(multiplier, Double(attempt - 1))
        let cappedDelay = min(exponentialDelay, maxDelay)
        
        if config.retryConfig.useJitter {
            // Add jitter to prevent thundering herd
            let jitter = Double.random(in: 0.0...0.1) * cappedDelay
            return cappedDelay + jitter
        }
        
        return cappedDelay
    }
    
    private func shouldRetry(statusCode: Int) -> Bool {
        guard config.enableRetries else { return false }
        return !config.retryConfig.omitRetryForStatusCodes.contains(statusCode) &&
               (500...599).contains(statusCode) || statusCode == 429
    }
    
    private func shouldRetry(error: Error) -> Bool {
        guard config.enableRetries else { return false }
        
        if let nsError = error as NSError? {
            return nsError.code == NSURLErrorTimedOut ||
                   nsError.code == NSURLErrorNotConnectedToInternet ||
                   nsError.code == NSURLErrorNetworkConnectionLost
        }
        
        return false
    }
    
    private func shouldCacheResponse(_ response: HTTPURLResponse) -> Bool {
        // Only cache GET requests with appropriate cache headers
        guard operationInfo.request.httpMethod == "GET" else { return false }
        
        // Check for cache control headers
        if let cacheControl = response.allHeaderFields["Cache-Control"] as? String {
            return !cacheControl.contains("no-cache") && !cacheControl.contains("no-store")
        }
        
        return true
    }
    
    private func createNetworkingError(for statusCode: Int) -> AscendNetworkingError {
        switch statusCode {
        case 401:
            return .authenticationError
        case 403:
            return .permissionError
        case 404:
            return .notFound
        case 429:
            return .rateLimited
        case 500...599:
            return .serverError(statusCode)
        default:
            return .httpError(statusCode)
        }
    }
    
    private func complete(with result: Result<NetworkResponseInfo, Error>) {
        completion(result)
        finish()
    }
    
    private func finish() {
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
        _isExecuting = false
        _isFinished = true
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }
}

// MARK: - Network Cache

/// Simple in-memory cache for network responses
internal final class NetworkCache: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let cache = NSCache<NSString, CachedResponse>()
    private let queue = DispatchQueue(label: "com.ascend.network.cache", attributes: .concurrent)
    
    // MARK: - Initialization
    
    init() {
        cache.countLimit = 100 // Maximum 100 cached responses
        cache.totalCostLimit = 10 * 1024 * 1024 // 10MB limit
    }
    
    // MARK: - Cache Operations
    
    func getCachedResponse(for request: URLRequest) -> CachedResponse? {
        return queue.sync {
            guard let url = request.url?.absoluteString else { return nil }
            return cache.object(forKey: url as NSString)
        }
    }
    
    func cacheResponse(
        statusCode: Int,
        headers: [String: String],
        data: Data?,
        for request: URLRequest
    ) {
        guard let url = request.url?.absoluteString else { return }
        
        queue.async(flags: .barrier) {
            let cachedResponse = CachedResponse(
                statusCode: statusCode,
                headers: headers,
                data: data,
                timestamp: Date()
            )
            
            let cost = data?.count ?? 0
            self.cache.setObject(cachedResponse, forKey: url as NSString, cost: cost)
        }
    }
    
    func clearCache() {
        queue.async(flags: .barrier) {
            self.cache.removeAllObjects()
        }
    }
}

// MARK: - Cached Response

/// Cached network response
internal final class CachedResponse: NSObject {
    let statusCode: Int
    let headers: [String: String]
    let data: Data?
    let timestamp: Date
    
    init(statusCode: Int, headers: [String: String], data: Data?, timestamp: Date) {
        self.statusCode = statusCode
        self.headers = headers
        self.data = data
        self.timestamp = timestamp
        super.init()
    }
}

// MARK: - HTTP Method

/// HTTP method enumeration
internal enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Networking Errors

/// Networking-related errors
internal enum AscendNetworkingError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case noData
    case encodingFailed(Error)
    case decodingFailed(Error)
    case networkError(String)
    case timeout
    case noConnection
    case authenticationError
    case permissionError
    case notFound
    case rateLimited
    case serverError(Int)
    case maxRetriesExceeded
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid HTTP response"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .noData:
            return "No data received"
        case .encodingFailed(let error):
            return "Encoding failed: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .timeout:
            return "Request timed out"
        case .noConnection:
            return "No internet connection"
        case .authenticationError:
            return "Authentication failed"
        case .permissionError:
            return "Permission denied"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Rate limited"
        case .serverError(let code):
            return "Server error: \(code)"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        }
    }
}
