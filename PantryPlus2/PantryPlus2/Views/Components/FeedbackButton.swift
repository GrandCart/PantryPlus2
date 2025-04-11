//
// Views/Components/FeedbackButton.swift
import SwiftUI

struct FeedbackButton: View {
    @State private var showingFeedbackSheet = false
    @State private var feedbackType: FeedbackManager.FeedbackType = .general
    @State private var feedbackTitle = ""
    @State private var feedbackDescription = ""
    @State private var includeScreenshot = false
    @State private var includeEmail = false
    @State private var userEmail = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    // Screenshot capture
    @State private var screenshot: UIImage?
    
    var body: some View {
        Button(action: {
            // Capture screenshot before showing sheet
            screenshot = UIApplication.shared.windows.first?.rootViewController?.view.asImage()
            showingFeedbackSheet = true
        }) {
            HStack {
                Image(systemName: "exclamationmark.bubble")
                Text("Send Feedback")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(20)
        }
        .sheet(isPresented: $showingFeedbackSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Feedback Type")) {
                        Picker("Type", selection: $feedbackType) {
                            Text("Bug Report").tag(FeedbackManager.FeedbackType.bug)
                            Text("Feature Request").tag(FeedbackManager.FeedbackType.feature)
                            Text("Improvement").tag(FeedbackManager.FeedbackType.improvement)
                            Text("General Feedback").tag(FeedbackManager.FeedbackType.general)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Section(header: Text("Details")) {
                        TextField("Title", text: $feedbackTitle)
                        
                        ZStack(alignment: .topLeading) {
                            if feedbackDescription.isEmpty {
                                Text("Describe your feedback in detail...")
                                    .foregroundColor(.gray.opacity(0.8))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                            
                            TextEditor(text: $feedbackDescription)
                                .frame(minHeight: 100)
                                .padding(4)
                        }
                    }
                    
                    Section(header: Text("Additional Information")) {
                        Toggle("Include Screenshot", isOn: $includeScreenshot)
                        
                        if includeScreenshot, let screenshot = screenshot {
                            Image(uiImage: screenshot)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(8)
                        }
                        
                        Toggle("Include Email for Follow-up", isOn: $includeEmail)
                        
                        if includeEmail {
                            TextField("Your Email", text: $userEmail)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                    }
                    
                    if let errorMessage = errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Section {
                        Button(action: submitFeedback) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Submit Feedback")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .disabled(feedbackTitle.isEmpty || feedbackDescription.isEmpty || isSubmitting)
                    }
                }
                .navigationTitle("Send Feedback")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingFeedbackSheet = false
                            resetForm()
                        }
                    }
                }
                .alert(isPresented: $showSuccess) {
                    Alert(
                        title: Text("Thank You!"),
                        message: Text("Your feedback has been submitted successfully."),
                        dismissButton: .default(Text("OK")) {
                            showingFeedbackSheet = false
                            resetForm()
                        }
                    )
                }
            }
        }
    }
    
    private func submitFeedback() {
        isSubmitting = true
        errorMessage = nil
        
        FeedbackManager.shared.submitFeedback(
            title: feedbackTitle,
            description: feedbackDescription,
            feedbackType: feedbackType,
            screenshot: includeScreenshot ? screenshot : nil,
            userEmail: includeEmail ? userEmail : nil
        )
        .sink(
            receiveCompletion: { completion in
                isSubmitting = false
                
                if case .failure(let error) = completion {
                    errorMessage = "Failed to submit feedback: \(error.localizedDescription)"
                }
            },
            receiveValue: { _ in
                isSubmitting = false
                showSuccess = true
            }
        )
        .store(in: &FeedbackManager.shared.cancellables)
    }
    
    private func resetForm() {
        feedbackType = .general
        feedbackTitle = ""
        feedbackDescription = ""
        includeScreenshot = false
        includeEmail = false
        userEmail = ""
        errorMessage = nil
        screenshot = nil
    }
}

// Extension to capture screenshot
extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}
