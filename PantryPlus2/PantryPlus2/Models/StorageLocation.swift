

// Models/StorageLocation.swift
import Foundation

/// StorageLocation: Represents a storage location for inventory items
enum StorageLocation: String, CaseIterable, Identifiable {
    case pantry = "Pantry"
    case refrigerator = "Refrigerator"
    case freezer = "Freezer"
    case custom = "Custom" // User-editable
    
    var id: String { self.rawValue }
    
    /// Icon name for each storage location
    var iconName: String {
        switch self {
        case .pantry:
            return "cabinet.fill"
        case .refrigerator:
            return "refrigerator.fill"
        case .freezer:
            return "snowflake"
        case .custom:
            return "square.grid.2x2.fill"
        }
    }
    
    /// Default temperature range for each storage location
    var temperatureRange: String {
        switch self {
        case .pantry:
            return "Room Temp"
        case .refrigerator:
            return "34°F - 40°F"
        case .freezer:
            return "0°F or below"
        case .custom:
            return "Varies"
        }
    }
    
    /// Recommended expiration offset in days
    var recommendedExpirationOffset: Int {
        switch self {
        case .pantry:
            return 365 // 1 year for pantry items
        case .refrigerator:
            return 7 // 1 week for refrigerated items
        case .freezer:
            return 90 // 3 months for frozen items
        case .custom:
            return 30 // Default 1 month for custom
        }
    }
}
