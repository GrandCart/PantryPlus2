import Foundation

public enum InventoryFilter {
    case all
    case expiringSoon
    case lowStock
    case byLocation(StorageLocation)
} 