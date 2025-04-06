
// Services/Firebase/FirebaseManager.swift
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

/// FirebaseManager: Central manager for Firebase services
/// Handles initialization and provides access to Firebase services
class FirebaseManager {
    // MARK: - Singleton
    static let shared = FirebaseManager()
    
    // MARK: - Properties
    let auth: Auth
    let firestore: Firestore
    let storage: Storage
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "com.grandcart.PantryPlus2", category: "FirebaseManager")
    
    // MARK: - Initialization
    private init() {
        // Configure Firebase if it hasn't been configured yet
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            logger.info("Firebase configured successfully")
        }
        
        // Initialize Firebase services
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        self.storage = Storage.storage()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        self.firestore.settings = settings
        
        logger.info("FirebaseManager initialized successfully")
    }
}
