//
//  AuthViewModel.swift
//  PantryPlus2
//
//  Created by Grandville Carter on 27/03/2025.
//
// ViewModels/AuthViewModel.swift
import Foundation
import Combine
import FirebaseAuth

/// AuthViewModel: Manages authentication state and operations
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Services
    private let authService = AuthService()
    private let firestoreService = FirestoreService()
    private let analytics = AnalyticsService()
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "com.grandcart.PantryPlus2", category: "AuthViewModel")
    
    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        // Check if user is already signed in
        self.user = authService.currentUser
        self.isAuthenticated = self.user != nil
        
        // Listen to authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.user = user
            self.isAuthenticated = user != nil
            
            if let user = user {
                self.logger.info("User authenticated: \(user.uid)")
                self.analytics.setUserProperty(name: "user_id", value: user.uid)
            } else {
                self.logger.info("User signed out")
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    func signIn(email: String, password: String) {
        self.isLoading = true
        self.error = nil
        
        authService.signIn(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.error = error.localizedDescription
                        self.logger.error("Sign in failed: \(error.localizedDescription)")
                        
                        // Track error for debugging
                        ErrorHandler.shared.handle(error, location: "AuthViewModel.signIn")
                    }
                },
                receiveValue: { [weak self] user in
                    guard let self = self else { return }
                    self.user = user
                    self.isAuthenticated = true
                    self.logger.info("User signed in successfully: \(user.uid)")
                    
                    // Log sign in event
                    self.analytics.logUserAction(action: "user_login")
                }
            )
            .store(in: &cancellables)
    }
    
    /// Sign up with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    ///   - name: User's display name
    func signUp(email: String, password: String, name: String) {
        self.isLoading = true
        self.error = nil
        
        authService.signUp(email: email, password: password, name: name)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.error = error.localizedDescription
                        self.logger.error("Sign up failed: \(error.localizedDescription)")
                        
                        // Track error for debugging
                        ErrorHandler.shared.handle(error, location: "AuthViewModel.signUp")
                    }
                },
                receiveValue: { [weak self] user in
                    guard let self = self else { return }
                    self.user = user
                    self.isAuthenticated = true
                    self.logger.info("User signed up successfully: \(user.uid)")
                    
                    // Log sign up event
                    self.analytics.logUserAction(action: "user_signup")
                    
                    // Start trial
                    self.analytics.logTrialStarted()
                }
            )
            .store(in: &cancellables)
    }
    
    /// Sign out the current user
    func signOut() {
        let result = authService.signOut()
        
        switch result {
        case .success:
            self.user = nil
            self.isAuthenticated = false
            self.logger.info("User signed out successfully")
        case .failure(let error):
            self.error = error.localizedDescription
            self.logger.error("Sign out failed: \(error.localizedDescription)")
            
            // Track error for debugging
            ErrorHandler.shared.handle(error, location: "AuthViewModel.signOut")
        }
    }
    
    /// Reset password for the given email
    /// - Parameter email: User's email
    func resetPassword(for email: String) {
        self.isLoading = true
        self.error = nil
        
        authService.resetPassword(for: email)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.error = error.localizedDescription
                        self.logger.error("Password reset failed: \(error.localizedDescription)")
                        
                        // Track error for debugging
                        ErrorHandler.shared.handle(error, location: "AuthViewModel.resetPassword")
                    }
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    self.logger.info("Password reset email sent to \(email)")
                    
                    // Log password reset event
                    self.analytics.logUserAction(action: "password_reset_requested")
                }
            )
            .store(in: &cancellables)
    }
}
