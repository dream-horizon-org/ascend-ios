import Foundation

// MARK: - Ascend SDK Main Entry Point

/// Main entry point for the Ascend iOS SDK
/// Provides unified access to all Ascend functionality through a single import
@available(iOS 13.0, macOS 10.15, *)
public final class Ascend {
    
    // MARK: - Singleton
    
    private static var shared: Ascend?
    
    // MARK: - Public Properties
    
    /// User management instance
    public static var user: AscendUser {
        return AscendUser.shared
    }
    
    /// Device information instance
    public static let deviceInfo: AscendDeviceInfo = AscendDeviceInfo.shared
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer for singleton pattern
    }
    
    /// Initialize the Ascend SDK with configuration
    /// - Parameter config: Configuration containing plugins, HTTP settings, and client settings
    /// - Throws: AscendError if initialization fails
    public static func initialize(with config: AscendConfig) throws {
        guard shared == nil else {
            throw AscendError.alreadyInitialized
        }
        
        do {
            shared = Ascend()
            
            // Initialize core components
            try AscendCore.initialize(with: config.coreConfig)
            
            // Initialize plugin system
            try AscendPluginManager.shared.initialize(with: config)
            
            // Initialize app lifecycle notifier
            AscendLifecycleNotifier.shared.start()
            
            if config.coreConfig.enableDebugLogging {
                print("[Ascend] SDK initialized successfully")
                print("[Ascend] Plugins: \(config.plugins.map { $0.type.rawValue })")
            }
            
        } catch {
            shared = nil
            throw AscendError.initializationFailed(error)
        }
    }
    
    /// Check if the SDK is initialized
    /// - Returns: True if initialized, false otherwise
    public static func isInitialized() -> Bool {
        return shared != nil
    }
    
    // MARK: - Plugin Management
    
    /// Get a plugin instance
    /// - Parameter pluginType: The type of plugin to retrieve
    /// - Returns: The plugin instance
    /// - Throws: AscendError if plugin is not found or not initialized
    public static func getPlugin<T: AscendPluginProtocol>(_ pluginType: T.Type) throws -> T {
        guard isInitialized() else {
            throw AscendError.notInitialized
        }
        
        return try AscendPluginManager.shared.getPlugin(pluginType)
    }
    
    /// Add a plugin dynamically
    /// - Parameter plugin: The plugin to add
    /// - Throws: AscendError if plugin already exists or addition fails
    public static func addPlugin(_ plugin: AscendPlugin) throws {
        guard isInitialized() else {
            throw AscendError.notInitialized
        }
        
        try AscendPluginManager.shared.addPlugin(plugin)
    }
    
    // MARK: - Event Management
    
    /// Notify all plugins of an event
    /// - Parameters:
    ///   - event: The event to broadcast
    ///   - data: Optional data associated with the event
    public static func notifyAllPlugins(event: AscendEvent, data: [String: Any]? = nil) {
        guard isInitialized() else { return }
        
        AscendPluginManager.shared.notifyAllPlugins(event: event, data: data)
    }
    
    // MARK: - Debug Support
    
    /// Get debug information about the SDK state
    /// - Returns: Dictionary containing debug information
    public static func getDebugInfo() -> [String: Any] {
        guard isInitialized() else {
            return ["status": "not_initialized"]
        }
        
        return [
            "status": "initialized",
            "plugins": AscendPluginManager.shared.getRegisteredPlugins(),
            "configurations": AscendConfigProvider.shared.getDebugInfo(),
            "user": [
                "userId": user.getUserId(),
                "guestId": user.getGuestId(),
                "isAuthenticated": user.isUserAuthInfoAvailable()
            ],
            "device": deviceInfo.getDebugInfo()
        ]
    }
    
    // MARK: - Plugin System Information
    
    /// Get list of registered plugins
    /// - Returns: Array of registered plugin names
    public static func getRegisteredPlugins() -> [String] {
        guard isInitialized() else { return [] }
        return AscendPluginManager.shared.getRegisteredPlugins()
    }
    
    /// Get list of initialized plugins
    /// - Returns: Array of initialized plugin names
    public static func getInitializedPlugins() -> [String] {
        guard isInitialized() else { return [] }
        return AscendPluginManager.shared.getInitializedPlugins()
    }
    
    /// Get plugin initialization order
    /// - Returns: Array of plugin names in initialization order
    public static func getPluginInitializationOrder() -> [String] {
        guard isInitialized() else { return [] }
        return AscendPluginManager.shared.getPluginInitializationOrder()
    }
}

// MARK: - Ascend Errors

/// Errors that can occur during SDK operations
public enum AscendError: Error, LocalizedError {
    case notInitialized
    case alreadyInitialized
    case initializationFailed(Error)
    case pluginNotFound(String)
    case pluginAlreadyExists(String)
    case configurationError(String)
    case networkError(String)
    case storageError(String)
    case serializationError(String)
    case invalidData(String)
    case timeoutError
    case authenticationError(String)
    case permissionError(String)
    
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Ascend SDK is not initialized. Call Ascend.initialize(with:) first."
        case .alreadyInitialized:
            return "Ascend SDK is already initialized."
        case .initializationFailed(let error):
            return "Initialization failed: \(error.localizedDescription)"
        case .pluginNotFound(let pluginName):
            return "Plugin '\(pluginName)' not found."
        case .pluginAlreadyExists(let pluginName):
            return "Plugin '\(pluginName)' already exists."
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .serializationError(let message):
            return "Serialization error: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .timeoutError:
            return "Operation timed out"
        case .authenticationError(let message):
            return "Authentication error: \(message)"
        case .permissionError(let message):
            return "Permission error: \(message)"
        }
    }
}
