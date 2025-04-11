//
// App/AppDelegate.swift
import UIKit
import Firebase
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let logger = Logger(subsystem: "com.grandcart.PantryPlus2", category: "AppDelegate")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase
        configureFirebase()
        
        // Configure notifications
        configureNotifications(application)
        
        // Log app launch
        logger.info("Application did finish launching")
        
        return true
    }
    
    // MARK: - Firebase Configuration
    
    /// Configure Firebase services
    private func configureFirebase() {
        // FirebaseManager initializes Firebase
        _ = FirebaseManager.shared
        
        // Configure Firebase Analytics
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // Configure Firebase Crashlytics
        #if !DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif
        
        logger.info("Firebase configured successfully")
    }
    
    // MARK: - Notification Configuration
    
    /// Configure user notifications
    /// - Parameter application: UIApplication instance
    private func configureNotifications(_ application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        // Request authorization
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.logger.info("Notification permission granted")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                self.logger.warning("Notification permission denied")
            }
            
            if let error = error {
                self.logger.error("Notification permission error: \(error.localizedDescription)")
            }
        }
        
        // Define notification categories for different types of notifications
        let viewAction = UNNotificationAction(identifier: "VIEW_ACTION", title: "View", options: .foreground)
        let dismissAction = UNNotificationAction(identifier: "DISMISS_ACTION", title: "Dismiss", options: .destructive)
        
        // Expiration notification category
        let expirationCategory = UNNotificationCategory(
            identifier: "EXPIRATION_CATEGORY",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Shopping reminder category
        let shoppingCategory = UNNotificationCategory(
            identifier: "SHOPPING_CATEGORY",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        center.setNotificationCategories([expirationCategory, shoppingCategory])
        
        logger.info("Notification categories registered")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
        
        logger.info("Will present notification: \(notification.request.identifier)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier
        
        logger.info("Did receive notification response: \(identifier), action: \(actionIdentifier)")
        
        // Handle different notification actions
        switch actionIdentifier {
        case "VIEW_ACTION":
            // In a real implementation, this would navigate to the relevant screen
            logger.info("User chose to view notification content")
            
        case "DISMISS_ACTION":
            logger.info("User dismissed notification")
            
        default:
            logger.info("Default notification action")
        }
        
        completionHandler()
    }
}
