//
// Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // User is authenticated, check subscription status
                if userProfileViewModel.hasLoadedProfile {
                    if userProfileViewModel.userProfile?.hasActiveSubscription ?? false {
                        // User has active subscription, show main content
                        MainTabView()
                    } else {
                        // User needs to subscribe
                        SubscriptionView()
                    }
                } else {
                    // Profile is loading
                    LoadingView(message: "Loading your profile...")
                        .onAppear {
                            if let userId = authViewModel.user?.uid {
                                userProfileViewModel.loadUserProfile(userId: userId)
                            }
                        }
                }
            } else {
                // User is not authenticated, show authentication flow
                AuthenticationView()
            }
        }
        .accentColor(.blue)
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var inventoryViewModel = InventoryViewModel()
    @StateObject private var shoppingListViewModel = ShoppingListViewModel()
    @StateObject private var recipeViewModel = RecipeViewModel()
    
    var body: some View {
        TabView {
            InventoryView()
                .environmentObject(inventoryViewModel)
                .tabItem {
                    Label("Inventory", systemImage: "cabinet")
                }
            
            ShoppingListView()
                .environmentObject(shoppingListViewModel)
                .tabItem {
                    Label("Shopping", systemImage: "cart")
                }
            
            RecipeView()
                .environmentObject(recipeViewModel)
                .tabItem {
                    Label("Recipes", systemImage: "book")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

#Preview {
    ContentView()
}
