//
//  FeedbackManager.swift
//  PantryPlus2
//
//  Created by Grandville Carter on 27/03/2025.
//
// Utilities/FeedbackManager.swift
import Foundation
import UIKit
import Combine

/// FeedbackManager: Manages user feedback and bug reporting
class FeedbackManager {
    // MARK: - Singleton
    static let shared = FeedbackManager()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.grandcart.PantryPlus2", category: "FeedbackManager")
    private let githubService = GitHubIssueService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Submit user feedback or bug report
    /// - Parameters:
    ///   - title: Feedback title
    ///   - description: Feedback description
    ///   - feedbackType: Type of feedback
    ///   - screenshot: Optional screenshot
    ///   - userEmail: Optional user email
    /// - Returns: Publisher that emits success or an error
    func submitFeedback(
        title: String,
        description: String,
        feedbackType: FeedbackType,
        screenshot: UIImage? = nil,
        userEmail: String? = nil
    ) -> AnyPublisher<URL, Error> {
                // First, upload screenshot if available
                var screenshotUrlPublisher: AnyPublisher<String?, Error> =
                    Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                
                if let screenshot = screenshot {
                    // In a real implementation, this would upload to a storage service
                    // For demo purposes, we'll just log that we would upload it
                    self.logger.info("Would upload screenshot")
                    screenshotUrlPublisher = Just(nil)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
                // Then create GitHub issue with the screenshot URL
                return screenshotUrlPublisher
                    .flatMap { [weak self] screenshotUrl -> AnyPublisher<URL, Error> in
                        guard let self = self else {
                            return Fail(error: NSError(domain: "FeedbackManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "FeedbackManager not available"]))
                                .eraseToAnyPublisher()
                        }
                        
                        // Get device and app info
                        let deviceInfo = self.getDeviceInfo()
                        let appVersion = self.getAppVersion()
                        let testFlightBuild = self.getTestFlightBuild()
                        
                        // Include stack trace for bug reports
                        let stackTrace: String? = feedbackType == .bug ? Thread.callStackSymbols.joined(separator: "\n") : nil
                        
                        return self.githubService.createIssue(
                            title: "\(feedbackType.rawValue): \(title)",
                            description: description,
                            stackTrace: stackTrace,
                            deviceInfo: deviceInfo,
                            appVersion: appVersion,
                            testFlightBuild: testFlightBuild,
                            userEmail: userEmail,
                            screenshotUrl: screenshotUrl
                        )
                    }
                    .receive(on: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
            
            /// Report an error with automatic context collection
            /// - Parameters:
            ///   - error: The error that occurred
            ///   - description: Additional description
            ///   - screenshot: Optional screenshot
            ///   - userEmail: Optional user email
            /// - Returns: Publisher that emits success or an error
            func reportError(
                error: Error,
                description: String,
                screenshot: UIImage? = nil,
                userEmail: String? = nil
            ) -> AnyPublisher<URL, Error> {
                return self.submitFeedback(
                    title: "Error: \(error.localizedDescription)",
                    description: description,
                    feedbackType: .bug,
                    screenshot: screenshot,
                    userEmail: userEmail
                )
            }
            
            // MARK: - Helper Methods
            
            /// Get device information
            /// - Returns: String with device details
            private func getDeviceInfo() -> String {
                let device = UIDevice.current
                let screenSize = UIScreen.main.bounds.size
                
                return """
                \(device.name)
                \(device.systemName) \(device.systemVersion)
                \(device.model)
                Screen: \(Int(screenSize.width))x\(Int(screenSize.height))
                """
            }
            
            /// Get app version
            /// - Returns: App version string
            private func getAppVersion() -> String {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
                let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
                return "\(version) (\(build))"
            }
            
            /// Get TestFlight build number if available
            /// - Returns: TestFlight build number or nil
            private func getTestFlightBuild() -> String? {
                #if DEBUG
                return nil
                #else
                // In a real TestFlight build, we would access the TestFlight info
                return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" ? "TestFlight Build" : nil
                #endif
            }
            
            // MARK: - Enums
            
            /// Types of feedback
            enum FeedbackType: String {
                case bug = "Bug"
                case feature = "Feature Request"
                case improvement = "Improvement"
                case general = "General Feedback"
            }
        }
