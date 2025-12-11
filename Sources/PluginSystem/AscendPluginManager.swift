import Foundation

// MARK: - Ascend Plugin Manager

/// Central plugin management system for the Ascend SDK
@available(iOS 13.0, macOS 10.15, *)
public final class AscendPluginManager: @unchecked Sendable {
    
    // MARK: - Singleton
    
    public static let shared = AscendPluginManager()
    
    // MARK: - Properties
    
    private let queue = DispatchQueue(label: "com.ascend.pluginmanager", attributes: .concurrent)
    private var _isInitialized = false
    private var _pluginInstances: [String: any AscendPluginProtocol] = [:]
    private var _pluginFactories: [String: () -> any AscendPluginProtocol] = [:]
    private var _pluginInitializationOrder: [String] = []
    
    // MARK: - Private Initializer
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Whether the plugin system is initialized
    public var isInitialized: Bool {
        return queue.sync { _isInitialized }
    }
    
    /// Initialize the plugin system with configuration
    /// - Parameter config: Ascend configuration containing plugins
    /// - Throws: AscendError if initialization fails
    public func initialize(with config: AscendConfig) throws {
        try queue.sync {
            guard !_isInitialized else {
                throw AscendError.alreadyInitialized
            }
            
            // Register all plugins from configuration
            for plugin in config.plugins {
                registerPlugin(plugin)
            }
            
            _isInitialized = true
            
            if config.coreConfig.enableDebugLogging {
                print("[AscendPluginManager] Initialized with \(config.plugins.count) plugins")
            }
        }
    }
    
    /// Register a plugin
    /// - Parameter plugin: The plugin to register
    private func registerPlugin(_ plugin: AscendPlugin) {
        let pluginName = plugin.type.rawValue
        
        // Store configuration
        AscendConfigProvider.shared.setConfiguration(plugin.config, for: plugin.type)
        
        // Register factory based on plugin type
        _pluginFactories[pluginName] = {
            switch plugin.type {
            case .experiments:
                return AscendExperiments.shared
            default:
                fatalError("Plugin factory not implemented for \(pluginName)")
            }
        }
    }
    
    /// Get a plugin instance
    /// - Parameter pluginType: The plugin type to retrieve
    /// - Returns: The plugin instance
    /// - Throws: AscendError if plugin is not found or initialization fails
    public func getPlugin<T: AscendPluginProtocol>(_ pluginType: T.Type) throws -> T {
        return try queue.sync {
            let pluginName = pluginType.pluginType.rawValue
            
            // Check if system is initialized
            guard _isInitialized else {
                throw AscendError.notInitialized
            }
            
            // Return existing instance if available
            if let existing = _pluginInstances[pluginName] as? T {
                return existing
            }
            
            // Create new instance if factory is available
            guard let factory = _pluginFactories[pluginName] else {
                throw AscendError.pluginNotFound(pluginName)
            }
            
            do {
                // Create plugin instance
                let instance = factory()
                _pluginInstances[pluginName] = instance
                
                // Initialize the plugin
                try instance.initialize()
                
                // Configure the plugin if configuration exists
                if let config = AscendConfigProvider.shared.getConfiguration(for: pluginType.pluginType) {
                    try instance.configure(with: config)
                }
                
                // Track initialization order
                _pluginInitializationOrder.append(pluginName)
                
                // Notify other plugins of new plugin initialization
                notifyAllPlugins(event: .pluginInitialized(plugin: pluginName))
                
                if let coreConfig = AscendCore.configuration, coreConfig.enableDebugLogging {
                    print("[AscendPluginManager] Initialized plugin: \(pluginName)")
                }
                
                return instance as! T
                
            } catch {
                // Clean up failed instance
                _pluginInstances.removeValue(forKey: pluginName)
                throw AscendError.pluginNotFound(pluginName)
            }
        }
    }
    
    /// Add a plugin dynamically
    /// - Parameter plugin: The plugin to add
    /// - Throws: AscendError if plugin already exists or addition fails
    public func addPlugin(_ plugin: AscendPlugin) throws {
        try queue.sync(flags: .barrier) {
            let pluginName = plugin.type.rawValue
            
            guard _pluginInstances[pluginName] == nil else {
                throw AscendError.pluginAlreadyExists(pluginName)
            }
            
            registerPlugin(plugin)
        }
    }
    
    /// Notify all plugins of an event
    /// - Parameters:
    ///   - event: The event to broadcast
    ///   - data: Optional data associated with the event
    public func notifyAllPlugins(event: AscendEvent, data: [String: Any]? = nil) {
        queue.async {
            let instances = self._pluginInstances.values
            
            for instance in instances {
                instance.onNotify(event: event, data: data)
            }
        }
    }
    
    /// Get list of registered plugins
    /// - Returns: Array of registered plugin names
    public func getRegisteredPlugins() -> [String] {
        return queue.sync {
            return Array(_pluginFactories.keys)
        }
    }
    
    /// Get list of initialized plugins
    /// - Returns: Array of initialized plugin names
    public func getInitializedPlugins() -> [String] {
        return queue.sync {
            return Array(_pluginInstances.keys)
        }
    }
    
    /// Get plugin initialization order
    /// - Returns: Array of plugin names in initialization order
    public func getPluginInitializationOrder() -> [String] {
        return queue.sync {
            return _pluginInitializationOrder
        }
    }
}
