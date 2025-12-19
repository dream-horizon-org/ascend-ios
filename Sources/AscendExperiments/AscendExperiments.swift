import Foundation

// MARK: - AscendExperiments Main Class (Refactored)

@available(iOS 13.0, macOS 10.15, *)
public final class AscendExperiments: AscendPluginProtocol, @unchecked Sendable {
    
    // MARK: - Plugin Protocol Conformance
    
    public static let pluginType: AscendPluginType = .experiments
    public static let pluginName = "AscendExperiments"
    
    // MARK: - Singleton Instance
    
    public static let shared = AscendExperiments()
    
    // MARK: - Properties
    
    private let threadSafety: ThreadSafety
    private let logger: ExperimentsLogger
    private let accessMap: ExperimentsAccessMap
    private let api: ExperimentsAPI
    private let typeSafeMethods: TypeSafeMethods
    private let defaultMethods: DefaultValueMethods
    private var foregroundHandler: ForegroundHandlerProtocol?
    
    internal var _configuration: AscendExperimentsConfiguration?
    internal var isPluginInitialized = false
    
    // MARK: - Storage and Session Management
    
    private var currentExperiments: [String: Experiment] = [:]
    private var defaultExperiments: [String: ExperimentVariable] = [:]
    
    private var DEFAULT_STORAGE_URL: URL {
        return AscendStorage.shared.getAscendDirectory().appendingPathComponent(ExperimentsConstants.Storage.EXPERIMENTS_FILE_NAME)
    }
    
    // MARK: - Initialization
    
    private init() {
        // Initialize modular components
        self.threadSafety = ThreadSafety()
        self.logger = ExperimentsLogger.shared
        self.accessMap = ExperimentsAccessMap(threadSafety: threadSafety, logger: logger)
        self.api = ExperimentsAPI(threadSafety: threadSafety, logger: logger)
        self.defaultMethods = DefaultValueMethods(accessMap: accessMap, logger: logger)
        self.typeSafeMethods = TypeSafeMethods(accessMap: accessMap, defaultMethods: defaultMethods, threadSafety: threadSafety, logger: logger)
        
        logger.info("AscendExperiments initialized with modular architecture")
    }
    
    // MARK: - Plugin Lifecycle
    
    public func initialize() throws {
        threadSafety.safeDispatchOnExperimentsQueueBarrier {
            self.isPluginInitialized = true
        }
        
            // Clear access map on initialization to ensure clean state
            // Access map is session-scoped and should be empty on app launch/restart
            accessMap.clearSessionData()
        
        // Load experiments from storage synchronously (like plugger-ios)
        // This ensures currentExperiments is populated before any get methods are called
        if let storedExperiments = loadExperimentsFromStorage() {
            threadSafety.safeDispatchOnExperimentsQueueBarrier {
                self.currentExperiments = storedExperiments
            }
        }
        
    }
    
    public var isInitialized: Bool {
        return threadSafety.safeDispatchOnExperimentsQueue {
            return self.isPluginInitialized
        }
    }
    
    public func configure<T: AscendConfiguration>(with configuration: T) throws {
        guard let experimentsConfig = configuration as? AscendExperimentsConfiguration else {
            throw AscendError.configurationError("Invalid configuration type for AscendExperiments")
        }
        
        threadSafety.safeDispatchOnExperimentsQueue {
            self._configuration = experimentsConfig
            
            // Initialize foreground handler if shouldRefreshOnForeground is enabled
            if experimentsConfig.shouldRefreshOnForeground {
                self.foregroundHandler = ForegroundHandler(threadSafety: self.threadSafety, logger: self.logger)
                self.logger.debug("Foreground handler initialized")
            } else {
                self.foregroundHandler = nil
            }
        }
        logger.info("Configuration updated")
        
        // Auto-fetch experiments on init if flag is enabled and defaults are provided
        if shouldFetchOnInit() && !experimentsConfig.defaultValues.isEmpty {
            logger.info("Auto-fetching experiments on init (shouldFetchOnInit: true)")
            
            // Use defaultValues as experimentKeys for automatic fetch
            fetchExperiments(for: experimentsConfig.defaultValues) { [weak self] response, error in
                if let error = error {
                    self?.logger.error("Auto-fetch on init failed: \(error)")
                } else if let response = response {
                    let count = response.data?.count ?? 0
                    self?.logger.success("Auto-fetch on init completed: \(count) experiments loaded")
                } else {
                    self?.logger.info("Auto-fetch on init completed with empty response (user may not be authenticated)")
                }
            }
        } else if shouldFetchOnInit() && experimentsConfig.defaultValues.isEmpty {
            logger.warning("Auto-fetch on init skipped: shouldFetchOnInit is true but defaultValues are empty")
        }
    }
    
    public func onNotify(event: AscendEvent, data: [String: Any]?) {
        switch event {
        case .userLoggedIn(let userId):
            logger.info("User logged in: \(userId)")
            refreshExperimentsForUser(userId: userId)
        case .userLoggedOut:
            logger.info("User logged out")
            threadSafety.safeDispatchOnExperimentsQueue {
                // Check if should fetch on logout (before clearing data)
                if let config = self._configuration, config.shouldFetchOnLogout {
                    self.logger.info("shouldFetchOnLogout is enabled - fetching experiments for guest user")
                    // Fetch experiments for guest user before clearing data
                    self.refreshExperiments { [weak self] response, error in
                        if let error = error {
                            self?.logger.error("Failed to fetch experiments on logout: \(error)")
                        } else {
                            self?.logger.success("Successfully fetched experiments on logout")
                        }
                    }
                } else {
                    // Clear all experiments data if not fetching on logout
                    self.logger.info("Clearing all experiments data")
                    self.clearAllExperimentsData()
                    self.foregroundHandler?.clearSessionData()
                }
            }
        case .appWillEnterForeground:
            logger.info("App will enter foreground")
            // Use foreground handler to check if refresh should happen
            threadSafety.safeDispatchOnExperimentsQueue {
                guard let config = self._configuration,
                      let handler = self.foregroundHandler else {
                    return
                }
                
                // Build current headers
                var headers: [String: String] = [:]
                if let configHeaders = config.headers {
                    headers.merge(configHeaders) { _, new in new }
                }
                
                // Check if refresh should happen
                if handler.shouldRefreshOnForeground(
                    shouldRefreshOnForeground: config.shouldRefreshOnForeground,
                    currentHeaders: headers
                ) != nil {
                    // Refresh should happen
                    self.logger.info("Foreground refresh triggered - refreshing experiments")
                    self.refreshExperiments { _, _ in
                        // Handle refresh completion
                    }
                }
            }
        case .appDidBecomeActive:
            logger.info("App became active")
            // Note: Foreground refresh is handled in appWillEnterForeground
        case .appDidEnterBackground:
            logger.info("App entered background")
            saveExperimentsToCache()
        default:
            break
        }
    }
    
    // MARK: - Configuration
    
    private func shouldFetchOnInit() -> Bool {
        return _configuration?.shouldFetchOnInit ?? false
    }
    
    // MARK: - Storage Methods (Using AscendStorage)
    
    private func saveExperimentsToCache() {
        threadSafety.safeDispatchOnExperimentsQueue {
            // Create snapshot with current timestamp (matching Plugger-iOS behavior)
            let snapshot = ExperimentSnapshot(data: self.currentExperiments)
            
            do {
                let snapshotData = try JSONEncoder().encode(snapshot)
                AscendStorage.shared.saveData(snapshotData, fileName: ExperimentsConstants.Storage.EXPERIMENTS_FILE_NAME) { result in
                    switch result {
                    case .success:
                        self.logger.success("Experiments saved to storage as snapshot (timestamp: \(snapshot.timestamp))")
                    case .failure(let error):
                        self.logger.error("Failed to save experiments: \(error.localizedDescription)")
                    }
                }
            } catch {
                self.logger.error("Failed to encode experiments snapshot: \(error.localizedDescription)")
            }
        }
    }
    
    /// Load experiments from storage asynchronously
    private func loadExperimentsFromStorageAsync() {
        AscendStorage.shared.loadData(fileName: ExperimentsConstants.Storage.EXPERIMENTS_FILE_NAME) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                do {
                    // Try to decode as ExperimentSnapshot first (new format)
                    if let snapshot = try? JSONDecoder().decode(ExperimentSnapshot.self, from: data) {
                        self.threadSafety.safeDispatchOnExperimentsQueueBarrier {
                            self.currentExperiments = snapshot.data
                        }
                        self.logger.success("Loaded \(snapshot.count) experiments from storage snapshot (timestamp: \(snapshot.timestamp))")
                    } else {
                        // Fallback: Try to decode as raw dictionary (backward compatibility)
                        let experiments = try JSONDecoder().decode([String: Experiment].self, from: data)
                        self.threadSafety.safeDispatchOnExperimentsQueueBarrier {
                            self.currentExperiments = experiments
                        }
                        self.logger.info("Loaded \(experiments.count) experiments from storage (legacy format)")
                    }
                } catch {
                    self.logger.error("Failed to decode experiments from storage: \(error.localizedDescription)")
                }
            case .failure(let error):
                if case AscendStorageError.fileNotFound = error {
                    self.logger.info("No cached experiments found - this is normal for first run")
                } else {
                    self.logger.error("Failed to load experiments from storage: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Synchronous method for testing purposes - returns cached experiments
    private func loadExperimentsFromStorageInternal() -> [String: Experiment]? {
        return threadSafety.safeDispatchOnExperimentsQueue {
            return self.currentExperiments
        }
    }
    
    /// Load experiments from disk storage synchronously
    /// - Returns: Dictionary of experiments from disk, or nil if not found
    /// - Note: This method blocks the calling thread until file I/O completes
    /// - Note: Supports both ExperimentSnapshot format (new) and raw dictionary format (legacy)
    public func loadExperimentsFromStorage() -> [String: Experiment]? {
        let url = DEFAULT_STORAGE_URL
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            logger.info("No experiments file found at: \(url.path)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            // Try to decode as ExperimentSnapshot first (new format)
            if let snapshot = try? JSONDecoder().decode(ExperimentSnapshot.self, from: data) {
                logger.info("Loaded \(snapshot.count) experiments from disk storage snapshot (timestamp: \(snapshot.timestamp))")
                return snapshot.data
            }
            
            // Fallback: Try to decode as raw dictionary (backward compatibility)
            let experiments = try JSONDecoder().decode([String: Experiment].self, from: data)
            logger.info("Loaded \(experiments.count) experiments from disk storage (legacy format)")
            return experiments
        } catch {
            logger.error("Failed to load experiments from disk: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Core API Methods
    
    public func fetchExperiments(for experimentKeys: [String: ExperimentVariable], completion: @escaping (ExperimentResponse?, String?) -> Void) {
        // Validate API paths are not empty
        guard !experimentKeys.isEmpty else {
            logger.warning("fetchExperiments called with empty experimentKeys - returning empty response")
            completion(ExperimentResponse(data: [], error: nil), nil)
            return
        }
        
        logger.info("Fetching experiments for API paths: \(experimentKeys.keys.joined(separator: ", "))")
        
        // Update default experiments
        updateDefaultExperiments(with: experimentKeys)
        
        // Check user auth info
        guard Ascend.user.isUserAuthInfoAvailable() else {
            completion(ExperimentResponse(data: [], error: nil), nil)
            return
        }
        
        _ = threadSafety.safeDispatchOnExperimentsQueue {
            // Make API call using modular API component
            Task {
                do {
                    guard let config = self._configuration else {
                        throw AscendError.configurationError("Configuration not set")
                    }
                    
                    // Build initial headers
                    var headers: [String: String] = [:]
                    if let configHeaders = config.headers {
                        headers.merge(configHeaders) { _, new in new }
                    }
                    
                    // Use foreground handler to update headers if refresh should happen
                    if let handler = self.foregroundHandler,
                       let updatedHeaders = handler.shouldRefreshOnForeground(
                        shouldRefreshOnForeground: config.shouldRefreshOnForeground,
                        currentHeaders: headers
                       ) {
                        headers = updatedHeaders
                        self.logger.debug("Foreground handler updated headers for refresh")
                    }
                    
                    let (experiments, responseInfo) = try await self.api.fetchExperimentsAsync(
                        experimentKeys: Array(experimentKeys.keys),
                        config: config,
                        headers: headers
                    )
                    
                    // Handle response headers
                    if responseInfo.statusCode == ForegroundHandler.cacheResponseStatusCode {
                        // 304 Not Modified - handle cache response
                        self.foregroundHandler?.handleCacheResponse(headers: responseInfo.headers)
                        self.logger.info("304 Not Modified - using cached experiments")
                        
                        // Return cached experiments
                        DispatchQueue.main.async {
                            completion(ExperimentResponse(data: Array(self.currentExperiments.values), error: nil), nil)
                        }
                        return
                    }
                    
                    // Handle successful response headers
                    self.foregroundHandler?.handleResponseHeader(headers: responseInfo.headers)
                    
                    // Merge with existing experiments (matching Plugger-iOS behavior)
                    // Start with a copy of current experiments to ensure correct type
                    var mergedExperiments: [String: Experiment] = self.currentExperiments
                    
                    // Add/update fetched experiments
                    for experiment in experiments {
                        mergedExperiments[experiment.experimentKey] = experiment
                    }
                    
                    // Remove experiments not in defaultExperiments (matching Plugger-iOS behavior)
                    for experimentKey in mergedExperiments.keys {
                        if self.defaultExperiments[experimentKey] == nil {
                            mergedExperiments.removeValue(forKey: experimentKey)
                        }
                    }
                    
                    let oldExperiments = self.currentExperiments
                    self.currentExperiments = mergedExperiments
                    
                    // Save to storage
                    self.onUpdateCurrentExperiments(newExperiments: mergedExperiments, oldExperiments: oldExperiments)
                    
                    DispatchQueue.main.async {
                        completion(ExperimentResponse(data: experiments, error: nil), nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func updateDefaultExperiments(with values: [String: ExperimentVariable]) {
        for (experimentKey, defaultValue) in values {
            defaultExperiments[experimentKey] = defaultValue
        }
    }
    
    private func onUpdateCurrentExperiments(newExperiments: [String: Experiment], oldExperiments: [String: Experiment]) {
        guard newExperiments != oldExperiments else {
            logger.debug("Experiments unchanged, skipping save")
            return
        }
        
        logger.info("Experiments updated - \(newExperiments.count) experiments loaded")
        
        // Save to storage asynchronously (now saves as ExperimentSnapshot with timestamp)
        saveExperimentsToCache()
    }
    
    private func refreshExperimentsForUser(userId: String) {
        logger.info("Refreshing experiments for user: \(userId)")
        
        // Refresh experiments for the new user
        refreshExperiments { [weak self] response, error in
            if let error = error {
                self?.logger.error("Failed to refresh experiments for user \(userId): \(error)")
            } else {
                self?.logger.success("Successfully refreshed experiments for user \(userId)")
            }
        }
    }
    
    
    // MARK: - Public API Methods (Type-Safe Flag Methods)
    
    /// Retrieves a boolean value from an experiment with proper fallback handling
    /// - Parameters:
    ///   - experimentKey: The experiment identifier (e.g., "button_exp_test")
    ///   - variable: Variable name within the experiment (required)
    ///   - dontCache: If true, doesn't cache the result in memory (default: false)
    ///   - ignoreCache: If true, bypasses the cache and fetches fresh (default: false)
    /// - Returns: Boolean value with fallback to false
    public func getBoolValue(for experimentKey: String, with variable: String, dontCache: Bool = false, ignoreCache: Bool = false) -> Bool {
        return typeSafeMethods.getBoolValue(for: experimentKey, with: variable, dontCache: dontCache, ignoreCache: ignoreCache, currentExperiments: currentExperiments, defaultExperiments: defaultExperiments)
    }
    
    /// Retrieves an integer value from an experiment with proper fallback handling
    /// - Parameters:
    ///   - experimentKey: The experiment identifier (e.g., "retry_config")
    ///   - variable: Variable name within the experiment (required)
    ///   - dontCache: If true, doesn't cache the result in memory (default: false)
    ///   - ignoreCache: If true, bypasses the cache and fetches fresh (default: false)
    /// - Returns: Integer value with fallback to -1
    public func getIntValue(for experimentKey: String, with variable: String, dontCache: Bool = false, ignoreCache: Bool = false) -> Int {
        return typeSafeMethods.getIntValue(for: experimentKey, with: variable, dontCache: dontCache, ignoreCache: ignoreCache, currentExperiments: currentExperiments, defaultExperiments: defaultExperiments)
    }
    
    /// Retrieves a string value from an experiment with proper fallback handling
    /// - Parameters:
    ///   - experimentKey: The experiment identifier (e.g., "button_exp_test")
    ///   - variable: Variable name within the experiment (required)
    ///   - dontCache: If true, doesn't cache the result in memory (default: false)
    ///   - ignoreCache: If true, bypasses the cache and fetches fresh (default: false)
    /// - Returns: String value with fallback to "" (empty string)
    public func getStringValue(for experimentKey: String, with variable: String, dontCache: Bool = false, ignoreCache: Bool = false) -> String {
        return threadSafety.safeDispatchOnExperimentsQueue {
            return self.typeSafeMethods.getStringValue(for: experimentKey, with: variable, dontCache: dontCache, ignoreCache: ignoreCache, currentExperiments: self.currentExperiments, defaultExperiments: self.defaultExperiments)
        }
    }
    
    /// Retrieves a double value from an experiment with proper fallback handling
    /// - Parameters:
    ///   - experimentKey: The experiment identifier (e.g., "network_config")
    ///   - variable: Variable name within the experiment (required)
    ///   - dontCache: If true, doesn't cache the result in memory (default: false)
    ///   - ignoreCache: If true, bypasses the cache and fetches fresh (default: false)
    /// - Returns: Double value with fallback to -1.0
    public func getDoubleValue(for experimentKey: String, with variable: String, dontCache: Bool = false, ignoreCache: Bool = false) -> Double {
        return typeSafeMethods.getDoubleValue(for: experimentKey, with: variable, dontCache: dontCache, ignoreCache: ignoreCache, currentExperiments: currentExperiments, defaultExperiments: defaultExperiments)
    }
    
    /// Retrieves a long (Int64) value from an experiment with proper fallback handling
    /// - Parameters:
    ///   - experimentKey: The experiment identifier (e.g., "cache_config")
    ///   - variable: Variable name within the experiment (required)
    ///   - dontCache: If true, doesn't cache the result in memory (default: false)
    ///   - ignoreCache: If true, bypasses the cache and fetches fresh (default: false)
    /// - Returns: Long value with fallback to -1L
    public func getLongValue(for experimentKey: String, with variable: String, dontCache: Bool = false, ignoreCache: Bool = false) -> Int64 {
        return typeSafeMethods.getLongValue(for: experimentKey, with: variable, dontCache: dontCache, ignoreCache: ignoreCache, currentExperiments: currentExperiments, defaultExperiments: defaultExperiments)
    }
    
    /// Get all variables for an experiment as JSON string
    /// - Parameter experimentKey: The API path of the experiment
    /// - Returns: JSON string representation of all variables, falls back to default variables if experiment not found
    public func getAllVariablesJSON(for experimentKey: String) -> String? {
        return threadSafety.safeDispatchOnExperimentsQueue {
            // Check current experiments first
            if let experiment = self.currentExperiments[experimentKey] {
                do {
                    let jsonData = try JSONEncoder().encode(experiment.variables)
                    return String(data: jsonData, encoding: .utf8)
                } catch {
                    self.logger.error("Failed to encode experiment variables to JSON: \(error.localizedDescription)")
                    return nil
                }
            }
            
            // Fallback to default variables (matching Plugger-iOS behavior)
            if let defaultVar = self.defaultExperiments[experimentKey],
               let variablesMap = defaultVar.dictionaryValue {
                do {
                    let jsonData = try JSONEncoder().encode(variablesMap)
                    return String(data: jsonData, encoding: .utf8)
                } catch {
                    self.logger.error("Failed to encode default variables to JSON: \(error.localizedDescription)")
                    return nil
                }
            }
            
            return nil
        }
    }
    
    /// Get experiment variants for all experiments
    /// - Returns: Dictionary of experiment variants
    public func getExperimentVariants() -> [String: ExperimentVariant] {
        return threadSafety.safeDispatchOnExperimentsQueue {
            var variants: [String: ExperimentVariant] = [:]
            
            for (experimentKey, experiment) in self.currentExperiments {
                variants[experimentKey] = ExperimentVariant(from: experiment)
            }
            
            return variants
        }
    }
    
    /// Get experiment variants as JSON string
    /// - Returns: JSON string representation of all experiment variants, or nil if encoding fails
    public func getExperimentVariantsJSON() -> String? {
        let variants = getExperimentVariants()
        
        do {
            let jsonData = try JSONEncoder().encode(variants)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            logger.error("Failed to encode experiment variants to JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get experiments from storage synchronously
    /// - Returns: Dictionary of experiments from disk storage, or nil if not found
    /// - Note: This method calls `loadExperimentsFromStorage()` to load from disk, matching Plugger-iOS behavior
    public func getExperimentsFromStorage() -> [String: Experiment]? {
        return loadExperimentsFromStorage()
    }
    
    /// Set experiments to storage
    /// - Parameter experiments: Dictionary of experiments to store
    public func setExperimentsToStorage(_ experiments: [String: Experiment]?) {
        threadSafety.safeDispatchOnExperimentsQueueBarrier {
            if let experiments = experiments {
                self.currentExperiments = experiments
                self.saveExperimentsToCache()
                self.logger.info("Experiments set to storage: \(experiments.count) experiments")
            } else {
                self.currentExperiments.removeAll()
                self.saveExperimentsToCache()
                self.logger.info("All experiments cleared from storage")
            }
        }
    }
    
    /// Clear all experiments data
    /// - Note: Clears currentExperiments, defaultExperiments, access map, and disk storage
    ///   Matching Plugger-iOS behavior which clears access map on logout
    public func clearAllExperimentsData() {
        threadSafety.safeDispatchOnExperimentsQueueBarrier {
            self.currentExperiments.removeAll()
            self.defaultExperiments.removeAll()
            self.accessMap.clearAllCacheData()  // Clear access map (session-scoped, cleared on logout/restart)
            self.saveExperimentsToCache()
            self.logger.info("All experiments data cleared")
        }
    }
    
    /// Refresh experiments using default experiments
    /// - Parameter completion: Completion handler with result
    public func refreshExperiments(completion: @escaping (ExperimentResponse?, String?) -> Void) {
        logger.info("Refreshing experiments")
        
        // Validate default experiments are not empty before fetching
        let defaults = threadSafety.safeDispatchOnExperimentsQueue {
            return self.defaultExperiments
        }
        
        guard !defaults.isEmpty else {
            logger.warning("refreshExperiments called but defaultExperiments is empty - returning empty response")
            completion(ExperimentResponse(data: [], error: nil), nil)
            return
        }
        
        // Use existing default experiments to refresh
        fetchExperiments(for: defaults, completion: completion)
    }
    
    // MARK: - Additional Public Methods (Plugger-iOS Compatibility)
    
    /// Get default experiment values that were configured
    /// - Returns: Dictionary of default experiment values keyed by API path
    public func getDefaultExperimentValues() -> [String: ExperimentVariable] {
        return threadSafety.safeDispatchOnExperimentsQueue {
            return self.defaultExperiments
        }
    }
    
    /// Load experiments data asynchronously from disk storage
    /// - Parameter completion: Completion handler with ExperimentSnapshot and optional error
    /// - Note: Returns ExperimentSnapshot with timestamp, similar to Plugger-iOS behavior
    public func loadExperimentsData(completion: @escaping (ExperimentSnapshot?, Error?) -> Void) {
        threadSafety.safeDispatchOnExperimentsQueue { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(nil, AscendError.configurationError("AscendExperiments instance is nil"))
                }
                return
            }
            
            let url = self.DEFAULT_STORAGE_URL
            
            guard FileManager.default.fileExists(atPath: url.path) else {
                self.logger.info("No experiments file found at: \(url.path)")
                DispatchQueue.main.async {
                    completion(nil, AscendError.storageError("File not found"))
                }
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                
                // Try to decode as ExperimentSnapshot first (new format)
                if let snapshot = try? JSONDecoder().decode(ExperimentSnapshot.self, from: data) {
                    self.logger.info("Loaded snapshot with \(snapshot.count) experiments from disk (timestamp: \(snapshot.timestamp))")
                    DispatchQueue.main.async {
                        completion(snapshot, nil)
                    }
                    return
                }
                
                // Fallback: Try to decode as raw dictionary and create snapshot with file modification date
                let experiments = try JSONDecoder().decode([String: Experiment].self, from: data)
                
                // Get file modification date as timestamp (for legacy format)
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let modificationDate = attributes[.modificationDate] as? Date ?? Date()
                let timestamp = modificationDate.timeIntervalSince1970
                
                let snapshot = ExperimentSnapshot(timestamp: timestamp, data: experiments)
                
                self.logger.info("Loaded snapshot with \(experiments.count) experiments from disk (legacy format, using file mod date)")
                DispatchQueue.main.async {
                    completion(snapshot, nil)
                }
            } catch {
                self.logger.error("Failed to load experiments data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil, AscendError.storageError(error.localizedDescription))
                }
            }
        }
    }
}

