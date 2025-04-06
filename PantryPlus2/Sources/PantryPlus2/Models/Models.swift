import Foundation
import FirebaseFirestore

public enum StorageLocation: String, Codable, CaseIterable {
    case pantry
    case refrigerator
    case freezer
    case other
}

public enum UsageFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case rarely
    case never
}

public enum InventoryFilter {
    case all
    case expiringSoon
    case lowStock
    case byLocation(StorageLocation)
}

public struct InventoryItem: Identifiable, Codable {
    public let id: String
    public let name: String
    public let brand: String?
    public let category: String
    public let quantity: Int
    public let unit: String
    public let price: Double?
    public let notes: String?
    public let expirationDate: Date?
    public let storageLocation: StorageLocation
    public let purchaseDate: Date
    public let minimumQuantity: Int
    public let imageUrl: String?
    public let barcode: String?
    public let usageFrequency: UsageFrequency
    public let createdAt: Date
    public let updatedAt: Date
    
    public var daysUntilExpiration: Int? {
        guard let expirationDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
    }
    
    public init(id: String, name: String, brand: String?, category: String, quantity: Int, unit: String, price: Double?, notes: String?, expirationDate: Date?, storageLocation: StorageLocation, purchaseDate: Date, minimumQuantity: Int, imageUrl: String?, barcode: String?, usageFrequency: UsageFrequency, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.price = price
        self.notes = notes
        self.expirationDate = expirationDate
        self.storageLocation = storageLocation
        self.purchaseDate = purchaseDate
        self.minimumQuantity = minimumQuantity
        self.imageUrl = imageUrl
        self.barcode = barcode
        self.usageFrequency = usageFrequency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 