import Foundation

// MARK: - Experiments API Manager

/// API management for AscendExperiments
internal final class ExperimentsAPI: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let threadSafety: ThreadSafety
    private let logger: ExperimentsLogger
    
    // MARK: - Initialization
    
    internal init(threadSafety: ThreadSafety, logger: ExperimentsLogger) {
        self.threadSafety = threadSafety
        self.logger = logger
    }
    
    // MARK: - API Methods
    
    /// Fetch experiments from API asynchronously
    /// - Parameters:
    ///   - experimentKeys: Array of API paths to fetch
    ///   - config: Experiments configuration
    ///   - headers: Request headers (may be updated by foreground handler)
    /// - Returns: Tuple of experiments array and response info
    /// - Throws: Network or parsing errors
    internal func fetchExperimentsAsync(experimentKeys: [String], config: AscendExperimentsConfiguration, headers: [String: String]) async throws -> ([Experiment], NetworkResponseInfo) {
        // Build URL - use /v1/allocations endpoint
        let endpoint = config.apiEndpoint;
        let urlComponents = URLComponents(string: config.apiBaseUrl + endpoint)
        guard let apiURL = urlComponents?.url else {
            throw AscendError.configurationError("Invalid API URL")
        }
        
        // Get user ID or guest ID for stable_id
        let userId = Ascend.user.getUserId()
        let guestId = Ascend.user.getGuestId()

        
        
        // Get attributes from config, or use device info as defaults
        var attributes: [String: String] = config.attributes ?? [:]
        
        // If config doesn't provide attributes, use device info defaults
        if config.attributes == nil {
            let deviceInfo = Ascend.deviceInfo
            attributes = [
                "platform": deviceInfo.getSystemName().lowercased(),
                "app_version": deviceInfo.getAppVersion(),
                "device_model": deviceInfo.getDeviceModel(),
                "system_version": deviceInfo.getSystemVersion(),
                "build_number": deviceInfo.getAppBuildNumber(),
            ]
        }
        
        // Create allocations payload
        let payload = AllocationsPayload(
            experimentKeys: experimentKeys,
            stableId: guestId,
            userId: userId,
            attributes: attributes
        )

        let payloadData = try JSONEncoder().encode(payload)
        
        // Build headers in layers (like plugger-ios)
        var requestHeaders = headers
        
        // 1. Add API key header
        requestHeaders[ExperimentsConstants.API.HEADER_API_KEY] = getAPIKey(from: config)
        
        // 2. Add auth headers
        let authHeaders = makeAuthHeaders()
        requestHeaders.merge(authHeaders) { _, new in new }
        
        // 3. Add custom headers from config
        if let customHeaders = config.headers {
            requestHeaders.merge(customHeaders) { _, new in new }
        }
        
        requestHeaders[ExperimentsConstants.API.HEADER_CONTENT_TYPE] = ExperimentsConstants.API.CONTENT_TYPE_JSON
        
        // Log request details for debugging
        logger.logAPIOperation("Request", details: "URL: \(apiURL), Method: POST, Headers: \(requestHeaders)")
        if let payloadString = String(data: payloadData, encoding: .utf8) {
            logger.logAPIOperation("Request", details: "Body: \(payloadString)")
        }
        
        // Create HTTP configuration with retry and timeout settings
        let httpConfig = NetworkHTTPConfig(
            baseURL: config.apiBaseUrl,
            headers: requestHeaders,
            retryConfig: RetryConfig(
                maxAttempts: 3,
                baseDelay: 1.0,
                maxDelay: 10.0,
                backoffMultiplier: 2.0,
                omitRetryForStatusCodes: [400, 401, 403, 404],
                useJitter: true
            ),
            timeoutConfig: TimeoutConfig(
                requestTimeout: 30.0,
                resourceTimeout: 60.0
            ),
            enableRetries: true
        )
        
        // Create request using enhanced networking
        let request = AscendNetworking.shared.createRequest(
            url: apiURL,
            method: .POST,
            headers: requestHeaders,
            body: payloadData,
            config: httpConfig
        )
        
        // Perform request with retry logic and caching
        let responseInfo = try await withCheckedThrowingContinuation { continuation in
            AscendNetworking.shared.performRequest(request, config: httpConfig) { result in
                continuation.resume(with: result)
            }
        }
        
        // Log response details for debugging
        logger.logAPIOperation("Response", details: "Status: \(responseInfo.statusCode), Duration: \(responseInfo.duration)s, Cached: \(responseInfo.isCached)")
        
        // Handle 304 Not Modified response
        if responseInfo.statusCode == ForegroundHandler.cacheResponseStatusCode {
            logger.info("Received 304 Not Modified - using cached experiments")
            // Return empty array for 304 - caller should use cached data
            return ([], responseInfo)
        }
        
        guard let data = responseInfo.data else {
            throw AscendNetworkingError.noData
        }
        
        // Log raw response for debugging
        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        logger.logAPIOperation("Response", details: "Raw: \(responseString)")
        
        let allocationsResponse = try JSONDecoder().decode(AllocationsAPIResponse.self, from: data)
        
        if let error = allocationsResponse.error {
            throw AscendError.configurationError(error.message ?? "Unknown API error")
        }

        // Convert allocations response to Experiment array
        let experiments = convertAllocationsToExperiments(allocationsResponse.data)
        
        return (experiments, responseInfo)
    }
    
    // MARK: - Helper Methods
    
    /// Get API key from configuration
    /// - Parameter config: Experiments configuration
    /// - Returns: API key string
    private func getAPIKey(from config: AscendExperimentsConfiguration) -> String {
        // Try to get API key from HTTP config headers first
        if let headers = config.headers,
           let apiKey = headers[ExperimentsConstants.API.HEADER_API_KEY] {
            return apiKey
        }
        
        // Fallback: return empty string (should be configured properly)
        logger.warning("API key not found in configuration headers")
        return ""
    }
    
    /// - Returns: Dictionary of auth headers
    private func makeAuthHeaders() -> [String: String] {
        var headers: [String: String] = [:]
        
        let userId = Ascend.user.getUserId()
        let guestId = Ascend.user.getGuestId()
        
        if !userId.isEmpty {
            headers[ExperimentsConstants.API.HEADER_USER_ID] = userId
        } 
        
        if !guestId.isEmpty {
            headers[ExperimentsConstants.API.HEADER_GUEST_ID] = guestId
        }
        
        logger.debug("Auth headers: \(headers)")
        return headers
    }
    
    private func convertAllocationsToExperiments(_ allocationsData: AllocationsResponseData?) -> [Experiment] {
        guard let allocationsData = allocationsData,
              let allocationsExperiments = allocationsData.experimentMap else {
            logger.warning("No experiment_map found in allocations response")
            return []
        }
        
        var experiments: [Experiment] = []
        
        for allocExp in allocationsExperiments {
            var variablesDict: [String: ExperimentVariable] = [:]
            
            if let variant = allocExp.variant,
               let variables = variant.variables {
                for variable in variables {
                    let experimentVar = ExperimentVariable.fromAPI(
                        value: variable.value,
                        dataType: variable.dataType
                    )
                    variablesDict[variable.key] = experimentVar
                }
            }
            
            let experimentKey = allocExp.experimentKey ?? "";
            let variantName = allocExp.variantName ?? "";
            
            let experiment = Experiment(
                experimentId: allocExp.experimentId ?? UUID().uuidString,
                userIdentifierType: "user_id",
                status: allocExp.status,
                variables: variablesDict.isEmpty ? nil : ExperimentVariable.dictionary(variablesDict),
                experimentKey: experimentKey,
                variantName: variantName
            )

            experiments.append(experiment)
        }

        
        return experiments
    }
}
