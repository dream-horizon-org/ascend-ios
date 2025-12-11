import Foundation

// MARK: - Enhanced User Management

/// Enhanced user management with persistence and session handling
@available(iOS 13.0, macOS 10.15, *)
public final class AscendUser: @unchecked Sendable {
    
    // MARK: - Singleton
    
    public static let shared = AscendUser()
    
    // MARK: - Properties
    
    private var guestId: String = ""
    private var userId: String = ""
    private var userProfile: [String: Any] = [:]
    private var sessionId: String = ""
    private var lastActivity: Date = Date()
    
    // MARK: - Private Initializer
    
    private init() {
        loadUserData()
        generateSessionId()
        ensureGuestIdExists()
    }
    
    // MARK: - Public Interface
    
    /// Get the current guest ID
    /// - Returns: The guest ID if available
    public func getGuestId() -> String {
        return guestId
    }
    
    /// Get the current user ID
    /// - Returns: The user ID if available
    public func getUserId() -> String {
        return userId
    }
    
    /// Get the current session ID
    /// - Returns: The session ID
    public func getSessionId() -> String {
        return sessionId
    }
    
    /// Get user profile data
    /// - Returns: Dictionary containing user profile information
    public func getUserProfile() -> [String: Any] {
        return userProfile
    }
    
    /// Get last activity timestamp
    /// - Returns: The last activity date
    public func getLastActivity() -> Date {
        return lastActivity
    }
    
    /// Set guest user
    /// - Parameter guestId: The guest ID to set
    public func setGuest(guestId: String) {
        self.guestId = guestId
        self.userId = "" // Clear user ID when setting guest
        self.userProfile.removeAll()
        updateLastActivity()
        saveUserData()
        
        // Notify plugins of user state change
        Ascend.notifyAllPlugins(event: .userLoggedOut, data: ["guestId": guestId])
    }
    
    /// Set authenticated user
    /// - Parameter userId: The user ID to set
    public func setUser(userId: String) {
        let previousUserId = self.userId
        self.userId = userId
        updateLastActivity()
        saveUserData()
        
        // Notify plugins of user login
        Ascend.notifyAllPlugins(
            event: .userLoggedIn(userId: userId),
            data: [
                "userId": userId,
                "previousUserId": previousUserId,
                "sessionId": sessionId
            ]
        )
    }
    
    /// Update user profile data
    /// - Parameter profile: Dictionary containing user profile information
    public func updateUserProfile(_ profile: [String: Any]) {
        self.userProfile = profile
        updateLastActivity()
        saveUserData()
        
        // Notify plugins of profile update
        Ascend.notifyAllPlugins(event: .userProfileUpdated, data: ["profile": profile])
    }
    
    /// Check if user authentication info is available
    /// - Returns: True if either guest ID or user ID is available
    public func isUserAuthInfoAvailable() -> Bool {
        return !guestId.isEmpty || !userId.isEmpty
    }
    
    /// Check if user is authenticated (has user ID)
    /// - Returns: True if user ID is available
    public func isAuthenticated() -> Bool {
        return !userId.isEmpty
    }
    
    /// Check if user is guest (has guest ID but no user ID)
    /// - Returns: True if guest ID is available but no user ID
    public func isGuest() -> Bool {
        return !guestId.isEmpty && userId.isEmpty
    }
    
    /// Clear all user data
    public func clearAllUserData() {
        let previousUserId = userId
        let previousGuestId = guestId
        
        userId = ""
        guestId = ""
        userProfile.removeAll()
        generateSessionId()
        updateLastActivity()
        saveUserData()
        
        // Notify plugins of user logout
        if !previousUserId.isEmpty || !previousGuestId.isEmpty {
            Ascend.notifyAllPlugins(
                event: .userLoggedOut,
                data: [
                    "previousUserId": previousUserId,
                    "previousGuestId": previousGuestId
                ]
            )
        }
    }
    
    /// Get debug information about user state
    /// - Returns: Dictionary containing debug information
    public func getDebugInfo() -> [String: Any] {
        return [
            "userId": userId,
            "guestId": guestId,
            "sessionId": sessionId,
            "isAuthenticated": isAuthenticated(),
            "isGuest": isGuest(),
            "lastActivity": lastActivity.timeIntervalSince1970,
            "profileKeys": Array(userProfile.keys)
        ]
    }
    
    // MARK: - Private Methods
    
    private func updateLastActivity() {
        lastActivity = Date()
    }
    
    private func generateSessionId() {
        sessionId = UUID().uuidString
    }

    private func ensureGuestIdExists() {
        if guestId.isEmpty {
            guestId = UUID().uuidString
            saveUserData()
            AscendLogger.shared.debug("Generated new guest ID: \(guestId)")
        }
    }
    
    private func saveUserData() {
        // Save user data to UserDefaults for now
        // Future: Use AscendCommon storage when public API is available
        let userData = [
            "guestId": guestId,
            "userId": userId,
            "userProfile": userProfile,
            "sessionId": sessionId,
            "lastActivity": lastActivity.timeIntervalSince1970
        ] as [String: Any]
        
        UserDefaults.standard.set(userData, forKey: "ascend_user_data")
        AscendLogger.shared.debug("User data saved to UserDefaults")
    }
    
    private func loadUserData() {
        // Load user data from UserDefaults
        if let userData = UserDefaults.standard.dictionary(forKey: "ascend_user_data") {
            guestId = userData["guestId"] as? String ?? ""
            userId = userData["userId"] as? String ?? ""
            userProfile = userData["userProfile"] as? [String: Any] ?? [:]
            sessionId = userData["sessionId"] as? String ?? ""
            
            if let lastActivityTimestamp = userData["lastActivity"] as? TimeInterval {
                lastActivity = Date(timeIntervalSince1970: lastActivityTimestamp)
            }
            
            AscendLogger.shared.debug("User data loaded from UserDefaults")
        }
    }
}
