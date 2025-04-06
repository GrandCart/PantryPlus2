
// Services/AnalyticsService.swift
import Firebase
import FirebaseAnalytics

/// AnalyticsService: Handles app analytics and user behavior tracking
class AnalyticsService {
    // MARK: - Logger
    private let logger = Logger(subsystem: "com.grandcart.PantryPlus2", category: "AnalyticsService")
    
    // MARK: - Event Tracking
    
    /// Log a screen view
    /// - Parameters:
    ///   - screenName: Name of the screen
    ///   - screenClass: Class of the screen (optional)
    func logScreenView(screenName: String, screenClass: String? = nil) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? "UIViewController"
        ])
        logger.info("Screen view logged: \(screenName)")
    }
    
    /// Log user action
    /// - Parameters:
    ///   - action: Action name
    ///   - parameters: Additional parameters (optional)
    func logUserAction(action: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(action, parameters: parameters)
        logger.info("User action logged: \(action)")
    }
    
    /// Log inventory item added
    /// - Parameters:
    ///   - itemName: Name of the item
    ///   - category: Category of the item
    func logItemAdded(itemName: String, category: String) {
        Analytics.logEvent("item_added", parameters: [
            "item_name": itemName,
            "category": category
        ])
        logger.info("Item added logged: \(itemName) (\(category))")
    }
    
    /// Log shopping list created
    /// - Parameters:
    ///   - listName: Name of the list
    ///   - itemCount: Number of items in the list
    func logShoppingListCreated(listName: String, itemCount: Int) {
        Analytics.logEvent("shopping_list_created", parameters: [
            "list_name": listName,
            "item_count": itemCount
        ])
        logger.info("Shopping list created logged: \(listName) (\(itemCount) items)")
    }
    
    /// Log trial started
    func logTrialStarted() {
        Analytics.logEvent("trial_started", parameters: nil)
        logger.info("Trial started logged")
    }
    
    /// Log subscription purchased
    /// - Parameter plan: Subscription plan (monthly/yearly)
    func logSubscriptionPurchased(plan: String) {
        Analytics.logEvent("subscription_purchased", parameters: [
            "plan": plan
        ])
        logger.info("Subscription purchased logged: \(plan)")
    }
    
    /// Log expired item discarded
    /// - Parameter daysExpired: Number of days the item was expired
    func logExpiredItemDiscarded(daysExpired: Int) {
        Analytics.logEvent("expired_item_discarded", parameters: [
            "days_expired": daysExpired
        ])
        logger.info("Expired item discarded logged: \(daysExpired) days expired")
    }
    
    // MARK: - Error Tracking
    
    /// Log an error for monitoring
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - location: Where the error occurred
    func logError(_ error: Error, location: String) {
        Analytics.logEvent("app_error", parameters: [
            "error_description": error.localizedDescription,
            "error_location": location
        ])
        logger.error("Error logged: \(error.localizedDescription) at \(location)")
    }
    
    // MARK: - User Properties
    
    /// Set user property for segmentation
    /// - Parameters:
    ///   - name: Property name
    ///   - value: Property value
    func setUserProperty(name: String, value: String?) {
        Analytics.setUserProperty(value, forName: name)
        logger.info("User property set: \(name) = \(value ?? "nil")")
    }
}
