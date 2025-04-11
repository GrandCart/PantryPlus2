

// Models/InventoryItem.swift
import Foundation

/// InventoryItem: Represents an item in the user's inventory
struct InventoryItem: Identifiable, Equatable {
    // MARK: - Properties
    var id: String?
    var name: String
    var brand: String?
    var category: String
    var quantity: Double
    var unit: String
    var expirationDate: Date?
    var storageLocation: StorageLocation
    var purchaseDate: Date
    var notes: String?
    var usageFrequency: Int = 0
    var imageUrl: String?
    var price: Double?
    var barcode: String?
    var addedToShoppingList: Bool = false
    
    // MARK: - Computed Properties
    
    /// Whether the item is expiring soon (within 3 days)
    var isExpiringSoon: Bool {
        guard let expDate = expirationDate else { return false }
        let daysToExpiration = Calendar.current.dateComponents([.day], from: Date(), to: expDate).day ?? 0
        return daysToExpiration <= 3 && daysToExpiration >= 0
    }
    
    /// Whether the item is expired
    var isExpired: Bool {
        guard let expDate = expirationDate else { return false }
        return Date() > expDate
    }
    
    /// Days until expiration (negative if already expired)
    var daysUntilExpiration: Int? {
        guard let expDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expDate).day
    }
    
    /// Stock status based on quantity and usage patterns
    var stockStatus: StockStatus {
        if quantity <= 0 {
            return .outOfStock
        } else if isExpired {
            return .expired
        } else if isExpiringSoon {
            return .expiringSoon
        } else if usageFrequency > 0 && quantity < Double(usageFrequency) / 7.0 {
            return .runningLow
        } else {
            return .inStock
        }
    }
    
    // MARK: - Enums
    
    /// Stock status options
    enum StockStatus: String {
        case inStock = "In Stock"
        case runningLow = "Running Low"
        case expiringSoon = "Expiring Soon"
        case expired = "Expired"
        case outOfStock = "Out of Stock"
        
        var color: String {
            switch self {
            case .inStock:
                return "green"
            case .runningLow:
                return "yellow"
            case .expiringSoon:
                return "orange"
            case .expired, .outOfStock:
                return "red"
            }
        }
    }
}
