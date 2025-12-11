import Foundation

// MARK: - Ascend Core Initialization

/// Core initialization and management for the Ascend SDK
@available(iOS 13.0, macOS 10.15, *)
public enum AscendCore {
    
    // MARK: - Properties
    
    private static var _configuration: AscendCoreConfig?
    private static var _isInitialized = false
    
    // MARK: - Public Interface
    
    /// Current core configuration
    public static var configuration: AscendCoreConfig? {
        return _configuration
    }
    
    /// Whether the core is initialized
    public static var isInitialized: Bool {
        return _isInitialized
    }
    
    /// Initialize the core with configuration
    /// - Parameter config: Core configuration
    /// - Throws: AscendError if initialization fails
    public static func initialize(with config: AscendCoreConfig) throws {
        guard !_isInitialized else {
            throw AscendError.alreadyInitialized
        }
        
        _configuration = config
        _isInitialized = true
        
        if config.enableDebugLogging {
            AscendLogger.shared.info("Initialized with environment: \(config.environment)")
        }
    }
    
    /// Reset the core (for testing purposes)
    internal static func reset() {
        _configuration = nil
        _isInitialized = false
    }
}
