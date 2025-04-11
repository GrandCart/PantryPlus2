//
//  GitHubIssueService.swift
//  PantryPlus2
//
//  Created by Grandville Carter on 27/03/2025.
//
// Services/GitHubIssueService.swift
import Foundation
import Combine

/// GitHubIssueService: Handles creation of GitHub issues for bug reports and feedback
class GitHubIssueService {
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.grandcart.PantryPlus2", category: "GitHubIssueService")
    private let githubToken: String?
    private let repositoryOwner: String
    private let repositoryName: String
    
    // MARK: - Initialization
    init(repositoryOwner: String = "grandvillecarter", repositoryName: String = "PantryPlus2") {
        self.repositoryOwner = repositoryOwner
        self.repositoryName = repositoryName
        
        // In a real app, this would be securely stored and accessed
        // For demo purposes, we'll check if it's available in the environment
        self.githubToken = ProcessInfo.processInfo.environment["GITHUB_TOKEN"]
    }
    
    // MARK: - Public Methods
    
    /// Create a GitHub issue for a bug report
    /// - Parameters:
    ///   - title: Issue title
    ///   - description: Issue description
    ///   - stackTrace: Optional stack trace
    ///   - deviceInfo: Device information
    ///   - appVersion: App version
    ///   - testFlightBuild: TestFlight build number (if applicable)
    ///   - userEmail: Optional user email for follow-up
    ///   - screenshotUrl: Optional URL to screenshot
    /// - Returns: Publisher that emits the issue URL or an error
    func createIssue(
        title: String,
        description: String,
        stackTrace: String? = nil,
        deviceInfo: String,
        appVersion: String,
        testFlightBuild: String? = nil,
        userEmail: String? = nil,
        screenshotUrl: String? = nil
    ) -> AnyPublisher<URL, Error> {
        guard let token = githubToken else {
            return Fail(error: NSError(domain: "GitHubIssueService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "GitHub token not available"
            ]))
            .eraseToAnyPublisher()
        }
        
        // Build issue body
        var body = """
        ## Description
        \(description)
        
        ## Environment
        - Device: \(deviceInfo)
        - App Version: \(appVersion)
        """
        
        if let testFlightBuild = testFlightBuild {
            body += "\n- TestFlight Build: \(testFlightBuild)"
        }
        
        if let userEmail = userEmail {
            body += "\n\n## Reporter\nEmail: \(userEmail)"
        }
        
        if let stackTrace = stackTrace {
            body += "\n\n## Stack Trace\n```\n\(stackTrace)\n```"
        }
        
        if let screenshotUrl = screenshotUrl {
            body += "\n\n## Screenshot\n![](\(screenshotUrl))"
        }
        
        // Build request payload
        let payload: [String: Any] = [
            "title": title,
            "body": body,
            "labels": ["bug", "testflight-feedback"]
        ]
        
        // Create request
        let endpoint = "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/issues"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        // Make network request
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { data, response -> Data in
                self.logger.info("GitHub issue creation response: \(response)")
                return data
            }
            .decode(type: GitHubIssueResponse.self, decoder: JSONDecoder())
            .map { response -> URL in
                self.logger.info("GitHub issue created: #\(response.number)")
                return URL(string: response.html_url)!
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Models
    
    /// Response from GitHub API when creating an issue
    private struct GitHubIssueResponse: Decodable {
        let number: Int
        let html_url: String
    }
}
