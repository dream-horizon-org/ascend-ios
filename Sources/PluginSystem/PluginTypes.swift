import Foundation

// MARK: - Plugin System Types

/// Enum-based plugin identification for type safety
public enum AscendPluginType: String, CaseIterable, Sendable {
    case experiments = "AscendExperiments"
    case analytics = "AscendAnalytics"
    case featureFlags = "AscendFeatureFlags"
    case auth = "AscendAuth"
    
    /// Human-readable description of the plugin
    public var description: String {
        switch self {
        case .experiments:
            return "A/B Testing and Experiments"
        case .analytics:
            return "Analytics and Event Tracking"
        case .featureFlags:
            return "Feature Flags and Toggles"
        case .auth:
            return "Authentication and Authorization"
        }
    }
}

/// Plugin definition containing type and configuration
public struct AscendPlugin: Sendable {
    
    // MARK: - Properties
    
    /// The type of plugin
    public let type: AscendPluginType
    
    /// The configuration for this plugin
    public let config: any AscendConfiguration
    
    // MARK: - Initializers
    
    /// Create a plugin with type and configuration
    /// - Parameters:
    ///   - type: The plugin type
    ///   - config: The plugin configuration
    public init<T: AscendConfiguration>(type: AscendPluginType, config: T) {
        self.type = type
        self.config = config
    }
}

// MARK: - Plugin Protocol

/// Protocol that all Ascend plugins must implement
public protocol AscendPluginProtocol: AnyObject {
    
    /// The plugin type identifier
    static var pluginType: AscendPluginType { get }
    
    /// Whether the plugin has been initialized
    var isInitialized: Bool { get }
    
    /// Initialize the plugin with default settings
    func initialize() throws
    
    /// Configure the plugin with specific configuration
    /// - Parameter configuration: Plugin-specific configuration
    func configure<T: AscendConfiguration>(with configuration: T) throws
    
    /// Handle system events and notifications
    /// - Parameters:
    ///   - event: The event that occurred
    ///   - data: Optional data associated with the event
    func onNotify(event: AscendEvent, data: [String: Any]?)
}

// MARK: - Configuration Protocol

/// Protocol that all plugin configurations must implement
public protocol AscendConfiguration: Sendable {
    
    /// The plugin type this configuration belongs to
    var pluginType: AscendPluginType { get }
}

// MARK: - Plugin Events

/// Events that plugins can respond to
public enum AscendEvent: Sendable {
    
    // MARK: - User Events
    
    case userLoggedIn(userId: String)
    case userLoggedOut
    case userProfileUpdated
    
    // MARK: - App Lifecycle Events
    
    case appDidBecomeActive
    case appDidEnterBackground
    case appWillEnterForeground
    case appWillResignActive
    case appWillTerminate
    
    // MARK: - System Events
    
    case networkStatusChanged(isConnected: Bool)
    case pluginInitialized(plugin: String)
    case pluginConfigurationChanged(plugin: String)
    
    // MARK: - Custom Events
    
    case custom(name: String, data: [String: String])
    
    // MARK: - Computed Properties
    
    /// Human-readable description of the event
    public var description: String {
        switch self {
        case .userLoggedIn(let userId):
            return "User logged in: \(userId)"
        case .userLoggedOut:
            return "User logged out"
        case .userProfileUpdated:
            return "User profile updated"
        case .appDidBecomeActive:
            return "App became active"
        case .appDidEnterBackground:
            return "App entered background"
        case .appWillEnterForeground:
            return "App will enter foreground"
        case .appWillResignActive:
            return "App will resign active"
        case .appWillTerminate:
            return "App will terminate"
        case .networkStatusChanged(let isConnected):
            return "Network status changed: \(isConnected ? "connected" : "disconnected")"
        case .pluginInitialized(let plugin):
            return "Plugin initialized: \(plugin)"
        case .pluginConfigurationChanged(let plugin):
            return "Plugin configuration changed: \(plugin)"
        case .custom(let name, _):
            return "Custom event: \(name)"
        }
    }
}
