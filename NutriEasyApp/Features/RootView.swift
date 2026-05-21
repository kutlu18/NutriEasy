import SwiftUI

enum AppRoute: Hashable {
    case photoCapture
    case textMeal
    case mealAnalysis
    case mealDetail(Meal.ID)
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            switch appState.shellState {
            case .splash:
                SplashView()
            case .auth:
                AuthFlowView()
            case .onboarding:
                OnboardingFlowView()
            case .main:
                MainShellView()
            }
        }
        .background(NutriColor.background)
    }
}

struct MainShellView: View {
    var body: some View {
        TabView {
            HomeStackView()
                .tabItem { Label("Bugün", systemImage: "house") }

            FoodHubView()
                .tabItem { Label("Yemek", systemImage: "fork.knife") }

            DailyPlanView()
                .tabItem { Label("Plan", systemImage: "calendar") }

            ProgressDashboardView()
                .tabItem { Label("Takip", systemImage: "chart.line.uptrend.xyaxis") }

            ProfileView()
                .tabItem { Label("Profil", systemImage: "person") }
        }
        .tint(NutriColor.leaf)
    }
}

struct HomeStackView: View {
    var body: some View {
        NavigationStack {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .photoCapture:
                        PhotoCaptureView()
                    case .textMeal:
                        TextMealInputView()
                    case .mealAnalysis:
                        MealAnalysisView()
                    case .mealDetail(let id):
                        MealDetailView(mealID: id)
                    }
                }
        }
    }
}
