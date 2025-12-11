import Foundation

// MARK: - Thread Safety Utilities

/// Thread safety utilities for AscendExperiments
internal final class ThreadSafety: @unchecked Sendable {
    
    // MARK: - Properties
    
    private let experimentsQueue: DispatchQueue
    private let experimentsQueueKey = DispatchSpecificKey<Void>()
    
    // MARK: - Initialization
    
    internal init() {
        self.experimentsQueue = DispatchQueue(label: "com.ascend.experiments", attributes: .concurrent)
        experimentsQueue.setSpecific(key: experimentsQueueKey, value: ())
    }
    
    // MARK: - Thread Safety Methods
    
    /// Check if currently on experiments queue
    /// - Returns: True if on experiments queue, false otherwise
    internal func isOnExperimentsQueue() -> Bool {
        return DispatchQueue.getSpecific(key: experimentsQueueKey) != nil
    }
    
    /// Safely dispatch async operation on experiments queue
    /// - Parameter block: The block to execute
    internal func safeDispatchOnExperimentsQueue(_ block: @escaping () -> Void) {
        experimentsQueue.async(execute: block)
    }
    
    /// Safely dispatch sync operation on experiments queue with return value
    /// - Parameter block: The block to execute
    /// - Returns: The result of the block execution
    internal func safeDispatchOnExperimentsQueue<T>(_ block: @escaping () -> T) -> T {
        return experimentsQueue.sync(execute: block)
    }
    
    /// Safely dispatch async operation on experiments queue with barrier
    /// - Parameter block: The block to execute
    internal func safeDispatchOnExperimentsQueueBarrier(_ block: @escaping () -> Void) {
        experimentsQueue.async(flags: .barrier, execute: block)
    }
    
    /// Safely dispatch sync operation on experiments queue with barrier
    /// - Parameter block: The block to execute
    /// - Returns: The result of the block execution
    internal func safeDispatchOnExperimentsQueueBarrier<T>(_ block: @escaping () -> T) -> T {
        return experimentsQueue.sync(flags: .barrier, execute: block)
    }
}
