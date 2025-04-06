import SwiftUI
import Firebase
import FirebaseFirestore

class RecipeViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    
    func fetchRecipes() {
        isLoading = true
        db.collection("recipes")
            .getDocuments { [weak self] snapshot, error in
                self?.isLoading = false
                if let error = error {
                    self?.error = error
                    return
                }
                
                self?.recipes = snapshot?.documents.compactMap { document in
                    try? document.data(as: Recipe.self)
                } ?? []
            }
    }
    
    func addRecipe(_ recipe: Recipe) {
        isLoading = true
        do {
            let _ = try db.collection("recipes").addDocument(from: recipe) { [weak self] error in
                self?.isLoading = false
                if let error = error {
                    self?.error = error
                    return
                }
                self?.fetchRecipes()
            }
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func updateRecipe(_ recipe: Recipe) {
        guard let id = recipe.id else { return }
        isLoading = true
        do {
            try db.collection("recipes").document(id).setData(from: recipe) { [weak self] error in
                self?.isLoading = false
                if let error = error {
                    self?.error = error
                    return
                }
                self?.fetchRecipes()
            }
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        guard let id = recipe.id else { return }
        isLoading = true
        db.collection("recipes").document(id).delete { [weak self] error in
            self?.isLoading = false
            if let error = error {
                self?.error = error
                return
            }
            self?.fetchRecipes()
        }
    }
} 