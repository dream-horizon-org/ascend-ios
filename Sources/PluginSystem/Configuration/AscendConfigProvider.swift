import Foundation

// MARK: - Ascend Configuration Provider

/// Centralized configuration management for all plugins
@available(iOS 13.0, macOS 10.15, *)
public final class AscendConfigProvider: @unchecked Sendable {
    
    // MARK: - Singleton
    
    public static let shared = AscendConfigProvider()
    
    // MARK: - Properties
    
    private let queue = DispatchQueue(label: "com.ascend.configprovider", attributes: .concurrent)
    private var _configurations: [AscendPluginType: any AscendConfiguration] = [:]
    
    // MARK: - Private Initializer
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Set configuration for a plugin
    /// - Parameters:
    ///   - configuration: The configuration to store
    ///   - pluginType: The plugin type
    public func setConfiguration<T: AscendConfiguration>(_ configuration: T, for pluginType: AscendPluginType) {
        queue.async(flags: .barrier) {
            self._configurations[pluginType] = configuration
        }
    }
    
    /// Get configuration for a plugin
    /// - Parameter pluginType: The plugin type
    /// - Returns: The configuration if found, nil otherwise
    public func getConfiguration(for pluginType: AscendPluginType) -> (any AscendConfiguration)? {
        return queue.sync {
            return _configurations[pluginType]
        }
    }
    
    /// Get configuration for a plugin with type safety
    /// - Parameters:
    ///   - type: The configuration type
    ///   - pluginType: The plugin type
    /// - Returns: The configuration if found and of correct type, nil otherwise
    public func getConfiguration<T: AscendConfiguration>(_ type: T.Type, for pluginType: AscendPluginType) -> T? {
        return queue.sync {
            return _configurations[pluginType] as? T
        }
    }
    
    /// Remove configuration for a plugin
    /// - Parameter pluginType: The plugin type
    public func removeConfiguration(for pluginType: AscendPluginType) {
        queue.async(flags: .barrier) {
            self._configurations.removeValue(forKey: pluginType)
        }
    }
    
    /// Clear all configurations
    public func clearAllConfigurations() {
        queue.async(flags: .barrier) {
            self._configurations.removeAll()
        }
    }
    
    /// Get all configuration types
    /// - Returns: Array of plugin types that have configurations
    public func getAllConfigurationTypes() -> [AscendPluginType] {
        return queue.sync {
            return Array(_configurations.keys)
        }
    }
    
    /// Check if a plugin has a configuration
    /// - Parameter pluginType: The plugin type
    /// - Returns: True if configuration exists, false otherwise
    public func hasConfiguration(for pluginType: AscendPluginType) -> Bool {
        return queue.sync {
            return _configurations[pluginType] != nil
        }
    }
    
    /// Get configuration count
    /// - Returns: Number of stored configurations
    public func getConfigurationCount() -> Int {
        return queue.sync {
            return _configurations.count
        }
    }
    
    /// Get debug information about stored configurations
    /// - Returns: Dictionary with configuration details
    public func getDebugInfo() -> [String: Any] {
        return queue.sync {
            var info: [String: Any] = [:]
            
            for (pluginType, config) in _configurations {
                info[pluginType.rawValue] = [
                    "type": String(describing: type(of: config)),
                    "pluginType": pluginType.rawValue,
                    "description": pluginType.description
                ]
            }
            
            return info
        }
    }
}
