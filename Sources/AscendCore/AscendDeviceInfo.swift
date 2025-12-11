import Foundation
import UIKit
import SystemConfiguration
import CoreLocation

// MARK: - Device Information

/// Device information collection and management
@available(iOS 13.0, macOS 10.15, *)
public final class AscendDeviceInfo: @unchecked Sendable {
    
    // MARK: - Singleton
    
    public static let shared = AscendDeviceInfo()
    
    // MARK: - Properties
    
    private let device: UIDevice
    private var networkReachability: SCNetworkReachability?
    
    // MARK: - Private Initializer
    
    private init() {
        self.device = UIDevice.current
        setupNetworkMonitoring()
    }
    
    // MARK: - Public Interface
    
    /// Get device model
    /// - Returns: Device model string
    public func getDeviceModel() -> String {
        return device.model
    }
    
    /// Get device name
    /// - Returns: Device name string
    public func getDeviceName() -> String {
        return device.name
    }
    
    /// Get system name
    /// - Returns: System name (e.g., "iOS")
    public func getSystemName() -> String {
        return device.systemName
    }
    
    /// Get system version
    /// - Returns: System version string
    public func getSystemVersion() -> String {
        return device.systemVersion
    }
    
    /// Get device identifier
    /// - Returns: Unique device identifier
    public func getDeviceIdentifier() -> String {
        return device.identifierForVendor?.uuidString ?? "unknown"
    }
    
    /// Get device orientation
    /// - Returns: Current device orientation
    public func getDeviceOrientation() -> UIDeviceOrientation {
        return device.orientation
    }
    
    /// Get battery level
    /// - Returns: Battery level (0.0 to 1.0) or -1.0 if unknown
    public func getBatteryLevel() -> Float {
        device.isBatteryMonitoringEnabled = true
        return device.batteryLevel
    }
    
    /// Get battery state
    /// - Returns: Current battery state
    public func getBatteryState() -> UIDevice.BatteryState {
        device.isBatteryMonitoringEnabled = true
        return device.batteryState
    }
    
    /// Get network status
    /// - Returns: True if network is available
    public func isNetworkAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return isReachable && !needsConnection
    }
    
    /// Get app version
    /// - Returns: App version string from Info.plist
    public func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
    
    /// Get app build number
    /// - Returns: App build number string from Info.plist
    public func getAppBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    }
    
    /// Get app bundle identifier
    /// - Returns: App bundle identifier
    public func getAppBundleIdentifier() -> String {
        return Bundle.main.bundleIdentifier ?? "unknown"
    }
    
    /// Get device capabilities
    /// - Returns: Dictionary containing device capabilities
    public func getDeviceCapabilities() -> [String: Any] {
        return [
            "supportsCamera": UIImagePickerController.isSourceTypeAvailable(.camera),
            "supportsPhotoLibrary": UIImagePickerController.isSourceTypeAvailable(.photoLibrary),
            "supportsVideoRecording": UIImagePickerController.isSourceTypeAvailable(.camera) && UIImagePickerController.availableMediaTypes(for: .camera)?.contains("public.movie") ?? false,
            "supportsLocationServices": CLLocationManager.locationServicesEnabled(),
            "supportsPushNotifications": UIApplication.shared.isRegisteredForRemoteNotifications,
            "supportsBackgroundAppRefresh": UIApplication.shared.backgroundRefreshStatus == .available,
            "supportsMultitasking": UIDevice.current.userInterfaceIdiom == .phone || UIDevice.current.userInterfaceIdiom == .pad
        ]
    }
    
    /// Get comprehensive device information
    /// - Returns: Dictionary containing all device information
    public func getAllDeviceInfo() -> [String: Any] {
        return [
            "deviceModel": getDeviceModel(),
            "deviceName": getDeviceName(),
            "systemName": getSystemName(),
            "systemVersion": getSystemVersion(),
            "deviceIdentifier": getDeviceIdentifier(),
            "deviceOrientation": getDeviceOrientation().rawValue,
            "batteryLevel": getBatteryLevel(),
            "batteryState": getBatteryState().rawValue,
            "networkAvailable": isNetworkAvailable(),
            "appVersion": getAppVersion(),
            "appBuildNumber": getAppBuildNumber(),
            "appBundleIdentifier": getAppBundleIdentifier(),
            "capabilities": getDeviceCapabilities()
        ]
    }
    
    /// Get debug information
    /// - Returns: Dictionary containing debug information
    public func getDebugInfo() -> [String: Any] {
        return [
            "device": [
                "model": getDeviceModel(),
                "name": getDeviceName(),
                "system": "\(getSystemName()) \(getSystemVersion())",
                "identifier": getDeviceIdentifier()
            ],
            "app": [
                "version": getAppVersion(),
                "build": getAppBuildNumber(),
                "bundleId": getAppBundleIdentifier()
            ],
            "network": [
                "available": isNetworkAvailable()
            ],
            "battery": [
                "level": getBatteryLevel(),
                "state": getBatteryState().rawValue
            ]
        ]
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        // Setup network reachability monitoring
        // For now, we'll use the existing isNetworkAvailable() method
        // Future enhancement: Add real-time network state monitoring
        AscendLogger.shared.debug("Network monitoring setup completed")
    }
}

// MARK: - CLLocationManager Extension
// Note: Removed extension that was causing infinite recursion
// CLLocationManager.locationServicesEnabled() is already available directly
