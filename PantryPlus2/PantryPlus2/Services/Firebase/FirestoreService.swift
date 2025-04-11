

// Services/Firebase/FirestoreService.swift
import Firebase
import FirebaseFirestore
import Combine

/// FirestoreService: Handles all Firestore operations
class FirestoreService {
    // MARK: - Properties
    private let firestore = FirebaseManager.shared.firestore
    private let auth = FirebaseManager.shared.auth
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "com.grandcart.PantryPlus2", category: "FirestoreService")
    
    // MARK: - References
    private var usersCollection: CollectionReference {
        return firestore.collection("users")
    }
    
    private func userDocument(userId: String) -> DocumentReference {
        return usersCollection.document(userId)
    }
    
    private func inventoryCollection(userId: String) -> CollectionReference {
        return userDocument(userId: userId).collection("inventory")
    }
    
    private func shoppingListsCollection(userId: String) -> CollectionReference {
        return userDocument(userId: userId).collection("shoppingLists")
    }
    
    // MARK: - User Profile Methods
    /// Get user profile
    /// - Parameter userId: User ID
    /// - Returns: Publisher that emits the user profile or an error
    func getUserProfile(userId: String) -> AnyPublisher<UserProfile, Error> {
        return Future<UserProfile, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            self.userDocument(userId: userId).getDocument { snapshot, error in
                if let error = error {
                    self.logger.error("Failed to get user profile: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                    self.logger.error("User document does not exist for \(userId)")
                    promise(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])))
                    return
                }
                
                do {
                    // Convert Firestore data to UserProfile model
                    let userProfile = try self.decodeUserProfile(from: data, documentId: snapshot.documentID)
                    self.logger.info("User profile retrieved successfully for \(userId)")
                    promise(.success(userProfile))
                } catch {
                    self.logger.error("Failed to decode user profile: \(error.localizedDescription)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Update user profile
    /// - Parameters:
    ///   - userId: User ID
    ///   - profile: Updated profile data
    /// - Returns: Publisher that emits success or an error
    func updateUserProfile(userId: String, profile: UserProfile) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            // Convert UserProfile to dictionary
            let data = self.encodeUserProfile(profile)
            
            self.userDocument(userId: userId).updateData(data) { error in
                if let error = error {
                    self.logger.error("Failed to update user profile: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                self.logger.info("User profile updated successfully for \(userId)")
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Inventory Methods
    /// Get all inventory items
    /// - Parameter userId: User ID
    /// - Returns: Publisher that emits inventory items or an error
    func getInventoryItems(userId: String) -> AnyPublisher<[InventoryItem], Error> {
        return Future<[InventoryItem], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            self.inventoryCollection(userId: userId).getDocuments { snapshot, error in
                if let error = error {
                    self.logger.error("Failed to get inventory items: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.logger.info("No inventory items found for \(userId)")
                    promise(.success([]))
                    return
                }
                
                do {
                    let items = try documents.compactMap { document -> InventoryItem? in
                        guard let data = document.data() as? [String: Any] else { return nil }
                        return try self.decodeInventoryItem(from: data, documentId: document.documentID)
                    }
                    
                    self.logger.info("Retrieved \(items.count) inventory items for \(userId)")
                    promise(.success(items))
                } catch {
                    self.logger.error("Failed to decode inventory items: \(error.localizedDescription)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Add an inventory item
    /// - Parameters:
    ///   - userId: User ID
    ///   - item: Inventory item to add
    /// - Returns: Publisher that emits the added item with server-assigned ID or an error
    func addInventoryItem(userId: String, item: InventoryItem) -> AnyPublisher<InventoryItem, Error> {
        return Future<InventoryItem, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            // Convert InventoryItem to dictionary
            let data = self.encodeInventoryItem(item)
            
            // Add to Firestore
            let docRef = self.inventoryCollection(userId: userId).document()
            
            docRef.setData(data) { error in
                if let error = error {
                    self.logger.error("Failed to add inventory item: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                // Create new item with server-assigned ID
                var newItem = item
                newItem.id = docRef.documentID
                
                self.logger.info("Inventory item added successfully with ID: \(docRef.documentID)")
                promise(.success(newItem))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Update an inventory item
    /// - Parameters:
    ///   - userId: User ID
    ///   - item: Inventory item to update
    /// - Returns: Publisher that emits success or an error
    func updateInventoryItem(userId: String, item: InventoryItem) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            guard let documentId = item.id else {
                self.logger.error("Cannot update inventory item without an ID")
                promise(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Item ID is missing"])))
                return
            }
            
            // Convert InventoryItem to dictionary
            let data = self.encodeInventoryItem(item)
            
            self.inventoryCollection(userId: userId).document(documentId).updateData(data) { error in
                if let error = error {
                    self.logger.error("Failed to update inventory item: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                self.logger.info("Inventory item updated successfully: \(documentId)")
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Delete an inventory item
    /// - Parameters:
    ///   - userId: User ID
    ///   - itemId: ID of the item to delete
    /// - Returns: Publisher that emits success or an error
    func deleteInventoryItem(userId: String, itemId: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"])))
                return
            }
            
            self.inventoryCollection(userId: userId).document(itemId).delete { error in
                if let error = error {
                    self.logger.error("Failed to delete inventory item: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                self.logger.info("Inventory item deleted successfully: \(itemId)")
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Shopping List Methods
    // Similar methods for shopping lists would go here
    
    // MARK: - Helper Methods
    /// Decode user profile from Firestore data
    /// - Parameters:
    ///   - data: Firestore document data
    ///   - documentId: Document ID
    /// - Returns: UserProfile object
    private func decodeUserProfile(from data: [String: Any], documentId: String) throws -> UserProfile {
        // Implementation would convert Firestore data to UserProfile model
        // This is a simplified example
        return UserProfile(
            id: documentId,
            name: data["name"] as? String ?? "",
            email: data["email"] as? String ?? "",
            householdSize: data["householdSize"] as? Int ?? 1,
            dietaryRestrictions: data["dietaryRestrictions"] as? [String] ?? [],
            subscriptionStatus: data["subscriptionStatus"] as? String ?? "trial",
            trialStartDate: (data["trialStartDate"] as? Timestamp)?.dateValue() ?? Date(),
            customStorageLocation: data["settings.customStorageLocation"] as? String ?? "Custom"
        )
    }
    
    /// Encode user profile to Firestore data
    /// - Parameter profile: UserProfile object
    /// - Returns: Dictionary for Firestore
    private func encodeUserProfile(_ profile: UserProfile) -> [String: Any] {
        // Implementation would convert UserProfile model to Firestore data
        var data: [String: Any] = [
            "name": profile.name,
            "email": profile.email,
            "householdSize": profile.householdSize,
            "dietaryRestrictions": profile.dietaryRestrictions,
            "subscriptionStatus": profile.subscriptionStatus
        ]
        
        if let trialStartDate = profile.trialStartDate {
            data["trialStartDate"] = Timestamp(date: trialStartDate)
        }
        
        data["settings.customStorageLocation"] = profile.customStorageLocation
        
        return data
    }
    
    /// Decode inventory item from Firestore data
    /// - Parameters:
    ///   - data: Firestore document data
    ///   - documentId: Document ID
    /// - Returns: InventoryItem object
    private func decodeInventoryItem(from data: [String: Any], documentId: String) throws -> InventoryItem {
        // Implementation would convert Firestore data to InventoryItem model
        return InventoryItem(
            id: documentId,
            name: data["name"] as? String ?? "",
            brand: data["brand"] as? String,
            category: data["category"] as? String ?? "Uncategorized",
            quantity: data["quantity"] as? Double ?? 1.0,
            unit: data["unit"] as? String ?? "item",
            expirationDate: (data["expirationDate"] as? Timestamp)?.dateValue(),
            storageLocation: StorageLocation(rawValue: data["storageLocation"] as? String ?? "pantry") ?? .pantry,
            purchaseDate: (data["purchaseDate"] as? Timestamp)?.dateValue() ?? Date(),
            notes: data["notes"] as? String,
            usageFrequency: data["usageFrequency"] as? Int ?? 0,
            imageUrl: data["imageUrl"] as? String
        )
    }
    
    /// Encode inventory item to Firestore data
    /// - Parameter item: InventoryItem object
    /// - Returns: Dictionary for Firestore
    private func encodeInventoryItem(_ item: InventoryItem) -> [String: Any] {
        // Implementation would convert InventoryItem model to Firestore data
        var data: [String: Any] = [
            "name": item.name,
            "category": item.category,
            "quantity": item.quantity,
            "unit": item.unit,
            "storageLocation": item.storageLocation.rawValue,
            "purchaseDate": Timestamp(date: item.purchaseDate),
            "usageFrequency": item.usageFrequency
        ]
        
        if let brand = item.brand {
            data["brand"] = brand
        }
        
        if let expirationDate = item.expirationDate {
            data["expirationDate"] = Timestamp(date: expirationDate)
        }
        
        if let notes = item.notes {
            data["notes"] = notes
        }
        
        if let imageUrl = item.imageUrl {
            data["imageUrl"] = imageUrl
        }
        
        return data
    }
}
