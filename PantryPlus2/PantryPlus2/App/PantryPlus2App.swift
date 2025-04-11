//
// App/PantryPlus2App.swift
import SwiftUI
import Firebase

@main
struct PantryPlus2App: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Environment objects for data sharing
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var userProfileViewModel = UserProfileViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(userProfileViewModel)
                .onAppear {
                    // Log app open event
                    Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
                }
        }
    }
}
