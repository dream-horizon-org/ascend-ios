import Foundation

// MARK: - Ascend Storage (Internal)

/// Internal storage utilities for the Ascend SDK
@available(iOS 13.0, macOS 10.15, *)
internal final class AscendStorage: @unchecked Sendable {
    
    // MARK: - Singleton
    
    internal static let shared = AscendStorage()
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.ascend.storage", attributes: .concurrent)
    
    // MARK: - Private Initializer
    
    private init() {}
    
    // MARK: - Internal Interface
    
    /// Get documents directory URL
    /// - Returns: Documents directory URL
    internal func getDocumentsDirectory() -> URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// Get Ascend-specific directory URL
    /// - Returns: Ascend directory URL
    internal func getAscendDirectory() -> URL {
        let documentsDir = getDocumentsDirectory()
        let ascendDir = documentsDir.appendingPathComponent("Ascend")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: ascendDir.path) {
            try? fileManager.createDirectory(at: ascendDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return ascendDir
    }
    
    /// Save data to file
    /// - Parameters:
    ///   - data: The data to save
    ///   - fileName: The file name
    ///   - completion: Completion handler with result
    internal func saveData(
        _ data: Data,
        fileName: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        queue.async {
            do {
                let url = self.getAscendDirectory().appendingPathComponent(fileName)
                try data.write(to: url)
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            } catch let error as NSError {
                let ascendError: Error
                switch error.code {
                case NSFileWriteNoPermissionError:
                    ascendError = AscendStorageError.permissionDenied
                case NSFileWriteVolumeReadOnlyError:
                    ascendError = AscendStorageError.diskFull
                default:
                    ascendError = AscendStorageError.corruptedData
                }
                DispatchQueue.main.async {
                    completion(.failure(ascendError))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(AscendStorageError.corruptedData))
                }
            }
        }
    }
    
    /// Load data from file
    /// - Parameters:
    ///   - fileName: The file name
    ///   - completion: Completion handler with result
    internal func loadData(
        fileName: String,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        queue.async {
            let url = self.getAscendDirectory().appendingPathComponent(fileName)
            
            guard self.fileManager.fileExists(atPath: url.path) else {
                DispatchQueue.main.async {
                    completion(.failure(AscendStorageError.fileNotFound))
                }
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                DispatchQueue.main.async {
                    completion(.success(data))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Delete file
    /// - Parameters:
    ///   - fileName: The file name
    ///   - completion: Completion handler with result
    internal func deleteFile(
        fileName: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        queue.async {
            let url = self.getAscendDirectory().appendingPathComponent(fileName)
            
            guard self.fileManager.fileExists(atPath: url.path) else {
                DispatchQueue.main.async {
                    completion(.success(true)) // File doesn't exist, consider it deleted
                }
                return
            }
            
            do {
                try self.fileManager.removeItem(at: url)
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Check if file exists
    /// - Parameter fileName: The file name
    /// - Returns: True if file exists, false otherwise
    internal func fileExists(fileName: String) -> Bool {
        let url = getAscendDirectory().appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: url.path)
    }
    
    /// Get file size
    /// - Parameter fileName: The file name
    /// - Returns: File size in bytes, or nil if file doesn't exist
    internal func getFileSize(fileName: String) -> Int64? {
        let url = getAscendDirectory().appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    /// Clear all Ascend data
    /// - Parameter completion: Completion handler with result
    internal func clearAllData(completion: @escaping (Result<Bool, Error>) -> Void) {
        queue.async {
            do {
                let ascendDir = self.getAscendDirectory()
                let contents = try self.fileManager.contentsOfDirectory(at: ascendDir, includingPropertiesForKeys: nil)
                
                for fileURL in contents {
                    try self.fileManager.removeItem(at: fileURL)
                }
                
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Storage Errors

/// Storage-related errors
internal enum AscendStorageError: Error, LocalizedError {
    case fileNotFound
    case directoryNotFound
    case permissionDenied
    case diskFull
    case corruptedData
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .directoryNotFound:
            return "Directory not found"
        case .permissionDenied:
            return "Permission denied"
        case .diskFull:
            return "Disk full"
        case .corruptedData:
            return "Corrupted data"
        }
    }
}
