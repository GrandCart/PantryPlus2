

// ViewModels/InventoryViewModel.swift
import Foundation
import Combine
import Firebase

class InventoryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var inventoryItems: [InventoryItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Services
    private let firestoreService = FirestoreService()
    private let storageService = StorageService()
    private let analyticsService = AnalyticsService()
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "com.grandcart.PantryPlus2", category: "InventoryViewModel")
    
    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var expiringItems: [InventoryItem] {
        inventoryItems.filter { $0.isExpiringSoon && !$0.isExpired }
            .sorted { (item1, item2) in
                guard let date1 = item1.expirationDate, let date2 = item2.expirationDate else {
                    return false
                }
                return date1 < date2
            }
    }
    
    var expiredItems: [InventoryItem] {
        inventoryItems.filter { $0.isExpired }
            .sorted { (item1, item2) in
                guard let date1 = item1.expirationDate, let date2 = item2.expirationDate else {
                    return false
                }
                return date1 < date2
            }
    }
    
    // MARK: - Initialization
    init() {
        // Listen for authentication changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let userId = user?.uid {
                self?.loadInventoryItems(userId: userId)
            } else {
                self?.inventoryItems = []
            }
        }
    }
    
    // MARK: - Data Loading
    
    /// Load inventory items for the user
    /// - Parameter userId: User ID
    func loadInventoryItems(userId: String) {
        isLoading = true
        error = nil
        
        firestoreService.getInventoryItems(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.error = error.localizedDescription
                        self.logger.error("Failed to load inventory items: \(error.localizedDescription)")
                        
                        // Track error for debugging
                        ErrorHandler.shared.handle(error, location: "InventoryViewModel.loadInventoryItems")
                    }
                },
                receiveValue: { [weak self] items in
                    guard let self = self else { return }
                    self.inventoryItems = items
                    self.logger.info("Loaded \(items.count) inventory items")
                    
                    // Track analytics
                    self.analyticsService.logUserAction(
                        action: "inventory_loaded",
                        parameters: ["item_count": items.count]
                    )
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Item Management
    
    /// Add a new inventory item
    /// - Parameters:
    ///   - item: Item to add
    ///   - image: Optional image
    func addItem(_ item: InventoryItem, image: UIImage? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.error = "User not authenticated"
            return
        }
        
        isLoading = true
        error = nil
        
        // If there's an image, upload it first
        let imageUploadPublisher: AnyPublisher<String?, Error> = image != nil ?
            storageService.uploadImage(userId: userId, image: image!, path: "inventory")
                .map { url -> String? in
                    return url.absoluteString
                }
                .eraseToAnyPublisher() :
            Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
        
        // Then add the item with the image URL
        imageUploadPublisher
            .flatMap { [weak self] imageUrl -> AnyPublisher<InventoryItem, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "InventoryViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel not available"]))
                        .eraseToAnyPublisher()
                }
                
                var newItem = item
                newItem.imageUrl = imageUrl
                
                return self.firestoreService.addInventoryItem(userId: userId, item: newItem)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.error = error.localizedDescription
                        self.logger.error("Failed to add inventory item: \(error.localizedDescription)")
                        
                        // Track error for debugging
                        ErrorHandler.shared.handle(error, location: "InventoryViewModel.addItem")
                    }
                },
                receiveValue: { [weak self] item in
                    guard let self = self else { return }
                    self.inventoryItems.append(item)
                    self.logger.info("Added inventory item: \(item.name)")
                    
                    // Track analytics
                    self.analyticsService.logItemAdded(itemName: item.name, category: item.category)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Update an existing inventory item
    /// - Parameters:
    ///   - item: Item to update
    ///   - image: Optional new image
    func updateItem(_ item: InventoryItem, image: UIImage? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.error = "User not authenticated"
            return
        }
        
        guard let itemId = item.id else {
            self.error = "Item ID is missing"
            return
        }
        
        isLoading = true
        error = nil
        
        // If there's a new image, upload it
        let imageUploadPublisher: AnyPublisher<String?, Error> = image != nil ?
            storageService.uploadImage(userId: userId, image: image!, path: "inventory")
                .map { url -> String? in
                    return url.absoluteString
                }
                .eraseToAnyPublisher() :
            Just(item.imageUrl).setFailureType(to: Error.self).eraseToAnyPublisher()
        
        // Then update the item with the new image URL
        imageUploadPublisher
            .flatMap { [weak self] imageUrl -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "InventoryViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel not available"]))
                        .eraseToAnyPublisher()
                }
                
                var updatedItem = item
                updatedItem.imageUrl = imageUrl
                
                return self.firestoreService.updateInventoryItem(userId: userId, item: updatedItem)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.error = error.localizedDescription
                        self.logger.error("Failed to update inventory item: \(error.localizedDescription)")
                        
                        // Track error for debugging
                        ErrorHandler.shared.handle(error, location: "InventoryViewModel.updateItem")
                    } else {
                        // Update local cache on success
                        if let index = self.inventoryItems.firstIndex(where: { $0.id == itemId }) {
                            self.inventoryItems[index] = item
                        }
                        self.logger.info("Updated inventory item: \(item.name)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    /// Delete an inventory item
    /// - Parameter item: Item to delete
    func deleteItem(_ item: InventoryItem) {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.error = "User not authenticated"
            return
        }
        
        guard let itemId = item.id else {
            self.error = "Item ID is missing"
            return
        }
        
        isLoading = true
        error = nil
        
        // Delete the item from Firestore
        firestoreService.deleteInventoryItem(userId: userId, itemId: itemId)
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "InventoryViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewModel not available"]))
                        .eraseToAnyPublisher()
                }
                
                // If there's an image, delete it from storage
                if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                    return self.storageService.deleteImage(imageUrl: url)
                } else {
                    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.error = error.localizedDescription
                        self.logger.error("Failed to delete inventory item: \(error.localizedDescription)")
                        
                        // Track error for debugging
                        ErrorHandler.shared.handle(error, location: "InventoryViewModel.deleteItem")
                    } else {
                        // Remove from local cache on success
                        self.inventoryItems.removeAll { $0.id == itemId }
                        self.logger.info("Deleted inventory item: \(item.name)")
                        
                        // Track analytics
                        self.analyticsService.logUserAction(
                            action: "item_deleted",
                            parameters: [
                                "item_name": item.name,
                                "category": item.category
                            ]
                        )
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Filtering and Sorting
    
    /// Filter inventory items by storage location
    /// - Parameter location: Storage location to filter by
    /// - Returns: Filtered items
    func filterByLocation(_ location: StorageLocation?) -> [InventoryItem] {
        guard let location = location else {
            return inventoryItems
        }
        
        return inventoryItems.filter { $0.storageLocation == location }
    }
    
    /// Filter inventory items by search text
    /// - Parameter searchText: Text to search for
    /// - Returns: Filtered items
    func filterBySearchText(_ searchText: String) -> [InventoryItem] {
        if searchText.isEmpty {
            return inventoryItems
        }
        
        let lowercasedText = searchText.lowercased()
        return inventoryItems.filter { item in
            item.name.lowercased().contains(lowercasedText) ||
            (item.brand?.lowercased().contains(lowercasedText) ?? false) ||
            item.category.lowercased().contains(lowercasedText)
        }
    }
    
    /// Filter and sort inventory items
    /// - Parameters:
    ///   - location: Optional storage location filter
    ///   - searchText: Optional search text filter
    ///   - sortOrder: Sort order
    /// - Returns: Filtered and sorted items
    func filteredAndSortedItems(
        by location: StorageLocation? = nil,
        searchText: String = "",
        sortOrder: SortOrder = .expirationAsc
    ) -> [InventoryItem] {
        var filtered = inventoryItems
        
        // Apply location filter
        if let location = location {
            filtered = filtered.filter { $0.storageLocation == location }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            let lowercasedText = searchText.lowercased()
            filtered = filtered.filter { item in
                item.name.lowercased().contains(lowercasedText) ||
                (item.brand?.lowercased().contains(lowercasedText) ?? false) ||
                item.category.lowercased().contains(lowercasedText)
            }
        }
        
        // Apply sorting
        switch sortOrder {
        case .nameAsc:
            filtered.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDesc:
            filtered.sort { $0.name.lowercased() > $1.name.lowercased() }
        case .expirationAsc:
            filtered.sort { item1, item2 in
                guard let date1 = item1.expirationDate else { return false }
                guard let date2 = item2.expirationDate else { return true }
                return date1 < date2
            }
        case .expirationDesc:
            filtered.sort { item1, item2 in
                guard let date1 = item1.expirationDate else { return true }
                guard let date2 = item2.expirationDate else { return false }
                return date1 > date2
            }
        case .recentlyAdded:
            filtered.sort { $0.purchaseDate > $1.purchaseDate }
        }
        
        return filtered
    }
    
    // MARK: - Enums
    
    enum SortOrder {
        case nameAsc
        case nameDesc
        case expirationAsc
        case expirationDesc
        case recentlyAdded
    }
}
