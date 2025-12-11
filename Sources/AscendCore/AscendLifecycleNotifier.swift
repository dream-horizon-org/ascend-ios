import Foundation
import UIKit

// MARK: - Ascend Lifecycle Notifier

/// App lifecycle event notifier for the Ascend SDK
@available(iOS 13.0, macOS 10.15, *)
public final class AscendLifecycleNotifier: @unchecked Sendable {
    
    // MARK: - Singleton
    
    public static let shared = AscendLifecycleNotifier()
    
    // MARK: - Properties
    
    private var isStarted = false
    private let queue = DispatchQueue(label: "com.ascend.lifecycle", attributes: .concurrent)
    
    // MARK: - Private Initializer
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Start monitoring app lifecycle events
    public func start() {
        queue.async(flags: .barrier) {
            guard !self.isStarted else { return }
            
            // Register for app lifecycle notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.appDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.appDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.appWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.appWillResignActive),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.appWillTerminate),
                name: UIApplication.willTerminateNotification,
                object: nil
            )
            
            self.isStarted = true
            
            if let coreConfig = AscendCore.configuration, coreConfig.enableDebugLogging {
                AscendLogger.shared.info("Started monitoring app lifecycle events")
            }
        }
    }
    
    /// Stop monitoring app lifecycle events
    public func stop() {
        queue.async(flags: .barrier) {
            guard self.isStarted else { return }
            
            // Remove all observers
            NotificationCenter.default.removeObserver(self)
            
            self.isStarted = false
            
            if let coreConfig = AscendCore.configuration, coreConfig.enableDebugLogging {
                AscendLogger.shared.info("Stopped monitoring app lifecycle events")
            }
        }
    }
    
    /// Check if lifecycle monitoring is started
    /// - Returns: True if started, false otherwise
    public func isMonitoringStarted() -> Bool {
        return queue.sync { isStarted }
    }
    
    // MARK: - Private Methods
    
    @objc private func appDidBecomeActive() {
        notifyPlugins(event: .appDidBecomeActive)
    }
    
    @objc private func appDidEnterBackground() {
        notifyPlugins(event: .appDidEnterBackground)
    }
    
    @objc private func appWillEnterForeground() {
        notifyPlugins(event: .appWillEnterForeground)
    }
    
    @objc private func appWillResignActive() {
        notifyPlugins(event: .appWillResignActive)
    }
    
    @objc private func appWillTerminate() {
        notifyPlugins(event: .appWillTerminate)
    }
    
    private func notifyPlugins(event: AscendEvent) {
        // Only notify if Ascend is initialized
        guard Ascend.isInitialized() else { return }
        
        Ascend.notifyAllPlugins(event: event)
        
        if let coreConfig = AscendCore.configuration, coreConfig.enableDebugLogging {
            AscendLogger.shared.debug("Notified plugins of event: \(event.description)")
        }
    }
    
    deinit {
        stop()
    }
}
