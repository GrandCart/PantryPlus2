

// Models/UserProfile.swift
import Foundation

/// UserProfile: Represents a user's profile data
struct UserProfile: Identifiable, Equatable {
    // MARK: - Properties
    var id: String
    var name: String
    var email: String
    var householdSize: Int
    var dietaryRestrictions: [String]
    var cuisinePreferences: [String] = []
    var subscriptionStatus: String // "trial", "monthly", "yearly", "expired"
    var trialStartDate: Date?
    var customStorageLocation: String = "Custom"
    var budgetLimit: Double?
    var budgetPeriod: BudgetPeriod = .monthly
    var notificationsEnabled: Bool = true
    var expirationAlertDays: Int = 3
    
    // MARK: - Computed Properties
    
    /// Whether the trial period is active
    var isTrialActive: Bool {
        guard subscriptionStatus == "trial", let startDate = trialStartDate else {
            return false
        }
        
        // Calculate days remaining in trial
        let trialLength = 30 // 30-day trial
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: trialLength, to: startDate)!
        
        return Date() < endDate
    }
    
    /// Days remaining in trial period
    var trialDaysRemaining: Int? {
        guard subscriptionStatus == "trial", let startDate = trialStartDate else {
            return nil
        }
        
        // Calculate days remaining in trial
        let trialLength = 30 // 30-day trial
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: trialLength, to: startDate)!
        
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }
    
    /// Whether user has an active subscription (trial or paid)
    var hasActiveSubscription: Bool {
        return isTrialActive || subscriptionStatus == "monthly" || subscriptionStatus == "yearly"
    }
    
    // MARK: - Enums
    
    /// Budget period options
    enum BudgetPeriod: String, CaseIterable, Identifiable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Static Functions
    
    /// Create a new user profile with default values
    /// - Parameters:
    ///   - id: User ID
    ///   - name: User's name
    ///   - email: User's email
    /// - Returns: New UserProfile instance
    static func createNew(id: String, name: String, email: String) -> UserProfile {
        return UserProfile(
            id: id,
            name: name,
            email: email,
            householdSize: 1,
            dietaryRestrictions: [],
            cuisinePreferences: [],
            subscriptionStatus: "trial",
            trialStartDate: Date(),
            customStorageLocation: "Custom",
            budgetLimit: nil,
            budgetPeriod: .monthly,
            notificationsEnabled: true,
            expirationAlertDays: 3
        )
    }
}
