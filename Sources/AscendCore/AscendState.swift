import Foundation

// MARK: - Ascend State Management

/// Global state management for the Ascend SDK
@available(iOS 13.0, macOS 10.15, *)
public final class AscendState: @unchecked Sendable {
    
    // MARK: - Singleton
    
    public static let shared = AscendState()
    
    // MARK: - Properties
    
    private let queue = DispatchQueue(label: "com.ascend.state", attributes: .concurrent)
    private var _isInitialized = false
    private var _currentUser: String?
    private var _sessionId: String?
    private var _appState: AppState = .background
    private var _networkState: NetworkState = .unknown
    
    // MARK: - Private Initializer
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Whether the SDK is initialized
    public var isInitialized: Bool {
        return queue.sync { _isInitialized }
    }
    
    /// Current user ID
    public var currentUser: String? {
        return queue.sync { _currentUser }
    }
    
    /// Current session ID
    public var sessionId: String? {
        return queue.sync { _sessionId }
    }
    
    /// Current app state
    public var appState: AppState {
        return queue.sync { _appState }
    }
    
    /// Current network state
    public var networkState: NetworkState {
        return queue.sync { _networkState }
    }
    
    /// Set initialization state
    /// - Parameter initialized: Whether the SDK is initialized
    internal func setInitialized(_ initialized: Bool) {
        queue.async(flags: .barrier) {
            self._isInitialized = initialized
        }
    }
    
    /// Set current user
    /// - Parameter userId: The user ID to set
    internal func setCurrentUser(_ userId: String?) {
        queue.async(flags: .barrier) {
            self._currentUser = userId
        }
    }
    
    /// Set session ID
    /// - Parameter sessionId: The session ID to set
    internal func setSessionId(_ sessionId: String?) {
        queue.async(flags: .barrier) {
            self._sessionId = sessionId
        }
    }
    
    /// Set app state
    /// - Parameter state: The app state to set
    internal func setAppState(_ state: AppState) {
        queue.async(flags: .barrier) {
            self._appState = state
        }
    }
    
    /// Set network state
    /// - Parameter state: The network state to set
    internal func setNetworkState(_ state: NetworkState) {
        queue.async(flags: .barrier) {
            self._networkState = state
        }
    }
    
    /// Get debug information about current state
    /// - Returns: Dictionary containing debug information
    public func getDebugInfo() -> [String: Any] {
        return queue.sync {
            return [
                "isInitialized": _isInitialized,
                "currentUser": _currentUser ?? "none",
                "sessionId": _sessionId ?? "none",
                "appState": _appState.rawValue,
                "networkState": _networkState.rawValue
            ]
        }
    }
}

// MARK: - App State

/// App state enumeration
public enum AppState: String, Sendable {
    case foreground = "foreground"
    case background = "background"
    case inactive = "inactive"
    case terminated = "terminated"
}

// MARK: - Network State

/// Network state enumeration
public enum NetworkState: String, Sendable {
    case connected = "connected"
    case disconnected = "disconnected"
    case unknown = "unknown"
}
