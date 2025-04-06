
// Services/Firebase/StorageService.swift
import Firebase
import FirebaseStorage
import Combine
import UIKit

/// StorageService: Handles all Firebase Storage operations
class StorageService {
    // MARK: - Properties
    private let storage = FirebaseManager.shared.storage
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "com.grandcart.PantryPlus2", category: "StorageService")
    
    // MARK: - References
    private func userImagesRef(userId: String) -> StorageReference {
        return storage.reference().child("users/\(userId)/images")
    }
    
    // MARK: - Upload Methods
    /// Upload an image to Firebase Storage
    /// - Parameters:
    ///   - userId: User ID
    ///   - image: UIImage to upload
    ///   - path: Optional path within user's storage
    /// - Returns: Publisher that emits the download URL or an error
    func uploadImage(userId: String, image: UIImage, path: String = "inventory") -> AnyPublisher<URL, Error> {
        return Future<URL, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            // Compress image to reduce storage usage and improve upload speed
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                self.logger.error("Failed to compress image")
                promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
                return
            }
            
            // Generate a unique filename
            let filename = "\(path)_\(UUID().uuidString).jpg"
            let storageRef = self.userImagesRef(userId: userId).child(filename)
            
            // Create metadata
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            // Upload the image
            let uploadTask = storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    self.logger.error("Failed to upload image: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                // Get download URL
                storageRef.downloadURL { url, error in
                    if let error = error {
                        self.logger.error("Failed to get download URL: \(error.localizedDescription)")
                        promise(.failure(error))
                        return
                    }
                    
                    guard let downloadURL = url else {
                        self.logger.error("Download URL is nil")
                        promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                        return
                    }
                    
                    self.logger.info("Image uploaded successfully: \(downloadURL.absoluteString)")
                    promise(.success(downloadURL))
                }
            }
            
            // Log upload progress
            uploadTask.observe(.progress) { snapshot in
                let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
                self.logger.info("Upload is \(percentComplete)% complete")
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Delete an image from Firebase Storage
    /// - Parameters:
    ///   - imageUrl: URL of the image to delete
    /// - Returns: Publisher that emits success or an error
    func deleteImage(imageUrl: URL) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            // Extract the path from the URL
            guard let path = self.getPathFromUrl(imageUrl) else {
                self.logger.error("Invalid image URL: \(imageUrl)")
                promise(.failure(NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image URL"])))
                return
            }
            
            let storageRef = self.storage.reference(forURL: imageUrl.absoluteString)
            
            storageRef.delete { error in
                if let error = error {
                    self.logger.error("Failed to delete image: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                self.logger.info("Image deleted successfully: \(path)")
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    /// Extract the storage path from a Firebase Storage URL
    /// - Parameter url: Firebase Storage URL
    /// - Returns: Storage path or nil if invalid
    private func getPathFromUrl(_ url: URL) -> String? {
        let urlString = url.absoluteString
        
        // Firebase Storage URLs have the format:
        // https://firebasestorage.googleapis.com/v0/b/[PROJECT_ID].appspot.com/o/[PATH]?token=[TOKEN]
        
        guard urlString.contains("/o/") else { return nil }
        
        let components = urlString.components(separatedBy: "/o/")
        guard components.count >= 2 else { return nil }
        
        let pathWithQuery = components[1]
        
        // Remove query parameters
        if let queryStartIndex = pathWithQuery.firstIndex(of: "?") {
            let path = String(pathWithQuery[..<queryStartIndex])
            
            // Firebase encodes paths, so decode it
            return path.removingPercentEncoding
        }
        
        return pathWithQuery.removingPercentEncoding
    }
}
