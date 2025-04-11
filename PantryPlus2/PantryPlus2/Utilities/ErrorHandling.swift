

// Utilities/ErrorHandling.swift
import Foundation

/// AppError: Enum representing all possible errors in the app
enum AppError: Error, LocalizedError {
    // Authentication errors
    case authenticationFailed(reason: String)
    case sessionExpired
    
    // Database errors
    case databaseError(reason: String)
    case itemNotFound
    case updateFailed
    
    // Network errors
    case networkUnavailable
    case requestFailed(reason: String)
    case timeoutError
    
    // Storage errors
    case imageUploadFailed(reason: String)
    case invalidImageData
    
    // Subscription errors
    case subscriptionExpired
    case paymentFailed(reason: String)
    
    // Input validation errors
    case invalidInput(field: String, reason: String)
    case missingRequiredField(field: String)
    
    // General errors
    case unexpectedError(reason: String)
    
    /// Human-readable error description
    var errorDescription: String? {
        switch self {
        // Authentication errors
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
            
        // Database errors
        case .databaseError(let reason):
            return "Database error: \(reason)"
        case .itemNotFound:
            return "The requested item could not be found."
        case .updateFailed:
            return "Failed to update the information."
            
        // Network errors
        case .networkUnavailable:
            return "No internet connection available."
        case .requestFailed(let reason):
            return "Request failed: \(reason)"
        case .timeoutError:
            return "Request timed out. Please try again."
            
        // Storage errors
        case .imageUploadFailed(let reason):
            return "Failed to upload image: \(reason)"
        case .invalidImageData:
            return "The image data is invalid or corrupted."
            
        // Subscription errors
        case .subscriptionExpired:
            return "Your subscription has expired."
        case .paymentFailed(let reason):
            return "Payment failed: \(reason)"
            
        // Input validation errors
        case .invalidInput(let field, let reason):
            return "\(field) is invalid: \(reason)"
        case .missingRequiredField(let field):
            return "\(field) is required."
            
        // General errors
        case .unexpectedError(let reason):
            return "An unexpected error occurred: \(reason)"
        }
    }
    
    /// Recovery suggestion
    var recoverySuggestion: String? {
        switch self {
        // Authentication errors
        case .authenticationFailed:
            return "Please check your credentials and try again."
        case .sessionExpired:
            return "Please sign in again to continue."
            
        // Database errors
        case .databaseError:
            return "Please try again later."
        case .itemNotFound:
            return "Please refresh the page or check if the item exists."
        case .updateFailed:
            return "Please try again or check your connection."
            
        // Network errors
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .requestFailed:
            return "Please try again later."
        case .timeoutError:
            return "Please check your connection and try again."
            
        // Storage errors
        case .imageUploadFailed:
            return "Please try uploading a smaller image or check your connection."
        case .invalidImageData:
            return "Please select a different image."
            
        // Subscription errors
        case .subscriptionExpired:
            return "Please renew your subscription to continue using all features."
        case .paymentFailed:
            return "Please check your payment details and try again."
            
        // Input validation errors
        case .invalidInput, .missingRequiredField:
            return "Please check the form and correct the errors."
            
        // General errors
        case .unexpectedError:
            return "Please try again later or contact support if the problem persists."
        }
    }
    
    /// Help anchor (for implementing in-app help)
    var helpAnchor: String? {
        switch self {
        case .authenticationFailed, .sessionExpired:
            return "auth_issues"
        case .databaseError, .itemNotFound, .updateFailed:
            return "data_issues"
        case .networkUnavailable, .requestFailed, .timeoutError:
            return "network_issues"
        case .imageUploadFailed, .invalidImageData:
            return "image_issues"
        case .subscriptionExpired, .paymentFailed:
            return "subscription_issues"
        case .invalidInput, .missingRequiredField:
            return "input_validation"
        case .unexpectedError:
            return "general_issues"
        }
    }
}

/// ErrorHandler: Handles and reports errors in a centralized way
class ErrorHandler {
    // MARK: - Singleton
    static let shared = ErrorHandler()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.grandcart.PantryPlus2", category: "ErrorHandler")
    private let analyticsService = AnalyticsService()
    
    // MARK: - Error Handling
    
    /// Handle an error and report it if needed
    /// - Parameters:
    ///   - error: The error to handle
    ///   - location: Where the error occurred
    ///   - showUser: Whether to show the error to the user
    /// - Returns: User-friendly error message
    func handle(_ error: Error, location: String, showUser: Bool = true) -> String {
        // Log the error
        logger.error("Error at \(location): \(error.localizedDescription)")
        
        // Report to analytics
        analyticsService.logError(error, location: location)
        
        // For debug purposes in development
        #if DEBUG
        print("🔴 Error at \(location): \(error)")
        #endif
        
        // Convert to AppError if possible
        let appError: AppError
        if let error = error as? AppError {
            appError = error
        } else {
            appError = .unexpectedError(reason: error.localizedDescription)
        }
        
        // Return user-friendly message
        return appError.errorDescription ?? "An unknown error occurred."
    }
    
    /// Track error for GitHub issue creation
    /// - Parameters:
    ///   - error: The error to track
    ///   - context: Additional context about the error
    ///   - screenshotData: Optional screenshot data
    func trackForGitHub(error: Error, context: [String: Any], screenshotData: Data? = nil) {
        // In a real implementation, this would save error data for later GitHub issue creation
        // For now, just log the error with context
        let contextString = context.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        logger.error("GitHub issue candidate: \(error.localizedDescription) - Context: \(contextString)")
        
        // TODO: Implement error tracking for GitHub issue creation
        // This could be done by saving the error data to a file or database
        // and then uploading it to GitHub using the GitHub API
    }
}
