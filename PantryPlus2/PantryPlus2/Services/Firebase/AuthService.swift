

// Services/Firebase/AuthService.swift
import Firebase
import FirebaseAuth
import Combine

/// Possible authentication errors
enum AuthError: Error, LocalizedError {
    case signInFailed
    case signUpFailed(message: String)
    case signOutFailed
    case resetPasswordFailed
    case userNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .signInFailed:
            return "Failed to sign in. Please check your credentials and try again."
        case .signUpFailed(let message):
            return "Failed to create account: \(message)"
        case .signOutFailed:
            return "Failed to sign out. Please try again."
        case .resetPasswordFailed:
            return "Failed to reset password. Please try again."
        case .userNotFound:
            return "User not found. Please check your email or create an account."
        case .networkError:
            return "Network error. Please check your connection and try again."
        }
    }
}

/// AuthService: Handles all authentication operations
class AuthService {
    // MARK: - Properties
    private let auth = FirebaseManager.shared.auth
    private let firestore = FirebaseManager.shared.firestore
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "com.grandcart.PantryPlus2", category: "AuthService")
    
    // MARK: - Current User
    var currentUser: User? {
        return auth.currentUser
    }
    
    var isUserLoggedIn: Bool {
        return currentUser != nil
    }
    
    // MARK: - Sign In Methods
    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    /// - Returns: A publisher that emits the user if successful or an error
    func signIn(email: String, password: String) -> AnyPublisher<User, Error> {
        return Future<User, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(AuthError.signInFailed))
                return
            }
            
            self.auth.signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.logger.error("Sign in failed: \(error.localizedDescription)")
                    promise(.failure(AuthError.signInFailed))
                    return
                }
                
                guard let user = authResult?.user else {
                    self.logger.error("Sign in succeeded but no user was returned")
                    promise(.failure(AuthError.userNotFound))
                    return
                }
                
                self.logger.info("User signed in successfully: \(user.uid)")
                promise(.success(user))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Sign up with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    ///   - name: User's display name
    /// - Returns: A publisher that emits the user if successful or an error
    func signUp(email: String, password: String, name: String) -> AnyPublisher<User, Error> {
        return Future<User, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(AuthError.signUpFailed(message: "Service unavailable")))
                return
            }
            
            self.auth.createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.logger.error("Sign up failed: \(error.localizedDescription)")
                    promise(.failure(AuthError.signUpFailed(message: error.localizedDescription)))
                    return
                }
                
                guard let user = authResult?.user else {
                    self.logger.error("Sign up succeeded but no user was returned")
                    promise(.failure(AuthError.signUpFailed(message: "User creation failed")))
                    return
                }
                
                // Update display name
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = name
                
                changeRequest.commitChanges { error in
                    if let error = error {
                        self.logger.error("Failed to update user display name: \(error.localizedDescription)")
                    }
                    
                    // Create user document in Firestore
                    self.createUserDocument(user: user, name: name)
                    
                    self.logger.info("User created successfully: \(user.uid)")
                    promise(.success(user))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Sign out the current user
    /// - Returns: Result indicating success or failure
    func signOut() -> Result<Void, Error> {
        do {
            try auth.signOut()
            logger.info("User signed out successfully")
            return .success(())
        } catch {
            logger.error("Sign out failed: \(error.localizedDescription)")
            return .failure(AuthError.signOutFailed)
        }
    }
    
    /// Reset password for the given email
    /// - Parameter email: User's email
    /// - Returns: A publisher that emits success or an error
    func resetPassword(for email: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(AuthError.resetPasswordFailed))
                return
            }
            
            self.auth.sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    self.logger.error("Password reset failed: \(error.localizedDescription)")
                    promise(.failure(AuthError.resetPasswordFailed))
                    return
                }
                
                self.logger.info("Password reset email sent to \(email)")
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    /// Create a new user document in Firestore
    /// - Parameters:
    ///   - user: Firebase Auth user
    ///   - name: User's display name
    private func createUserDocument(user: User, name: String) {
        let userDoc = firestore.collection("users").document(user.uid)
        
        // Initialize user profile
        let userData: [String: Any] = [
            "email": user.email ?? "",
            "name": name,
            "createdAt": FieldValue.serverTimestamp(),
            "householdSize": 1,
            "dietaryRestrictions": [],
            "subscriptionStatus": "trial",
            "trialStartDate": FieldValue.serverTimestamp(),
            "settings": [
                "notifications": true,
                "customStorageLocation": "Custom"
            ]
        ]
        
        userDoc.setData(userData) { error in
            if let error = error {
                self.logger.error("Failed to create user document: \(error.localizedDescription)")
            } else {
                self.logger.info("User document created successfully for \(user.uid)")
            }
        }
    }
}
