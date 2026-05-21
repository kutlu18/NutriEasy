import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var shellState: AppShellState = .splash
    @Published var isAuthenticated = false
    @Published var user = UserProfile()
    @Published var meals = MockData.meals
    @Published var selectedAnalysis: MealAnalysis?
    @Published var isAnalyzingMeal = false
    @Published var isSavingMeal = false
    @Published var mealFlowError: String?
    @Published var chatMessages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "Merhaba, ben Nuri. Bugünkü hedeflerine göre öğün kararlarında yardımcı olabilirim.")
    ]

    private var apiClient = APIClient()

    var dashboard: TodayDashboard {
        let calories = meals.reduce(0) { $0 + $1.totalCalories }
        let macros = meals.reduce(MacroTargets(proteinGr: 0, carbsGr: 0, fatGr: 0)) { partial, meal in
            MacroTargets(
                proteinGr: partial.proteinGr + meal.macros.proteinGr,
                carbsGr: partial.carbsGr + meal.macros.carbsGr,
                fatGr: partial.fatGr + meal.macros.fatGr
            )
        }

        return TodayDashboard(
            calorieTarget: 1900,
            consumedCalories: calories,
            macroTargets: MacroTargets(proteinGr: 125, carbsGr: 190, fatGr: 65),
            consumedMacros: macros,
            meals: meals,
            hydration: HydrationStatus(current: 4, target: 8, unit: "bardak")
        )
    }

    func completeOnboarding() {
        user.onboardingCompleted = true
        shellState = isAuthenticated ? .main : .auth
    }

    func setAccessToken(_ token: String?) {
        apiClient.accessToken = token
        isAuthenticated = token?.isEmpty == false
        if isAuthenticated, user.onboardingCompleted {
            shellState = .main
        }
    }

    func bootstrapApp() async {
        shellState = .splash
        try? await Task.sleep(nanoseconds: 700_000_000)
        shellState = isAuthenticated ? (user.onboardingCompleted ? .main : .onboarding) : .auth
    }

    func signInMock() {
        isAuthenticated = true
        mealFlowError = nil
        shellState = user.onboardingCompleted ? .main : .onboarding
    }

    func signOut() {
        isAuthenticated = false
        apiClient.accessToken = nil
        selectedAnalysis = nil
        mealFlowError = nil
        shellState = .auth
    }

    func analyzeMeal(from source: String, mealType: MealType) async {
        let text = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            mealFlowError = "Analiz için kısa bir öğün açıklaması yazmalısın."
            return
        }

        isAnalyzingMeal = true
        mealFlowError = nil

        do {
            let response: AnalyzeTextResponse = try await apiClient.send(
                .analyzeText,
                body: AnalyzeTextRequest(text: text, mealType: mealType.rawValue)
            )
            selectedAnalysis = response.toMealAnalysis()
        } catch {
            var fallback = MockData.analysis
            fallback.mealType = mealType
            selectedAnalysis = fallback
            mealFlowError = "Canlı analiz henüz kullanılamıyor; şimdilik mock analiz gösteriliyor. \(error.localizedDescription)"
        }

        isAnalyzingMeal = false
    }

    func saveAnalysis() async {
        guard let analysis = selectedAnalysis else { return }

        isSavingMeal = true

        if apiClient.isAuthenticated {
            do {
                let _: SubmitMealLogResponse = try await apiClient.send(
                    .submitMealLog,
                    body: SubmitMealLogRequest(analysis: analysis)
                )
                mealFlowError = nil
            } catch {
                mealFlowError = "Backend kaydı başarısız oldu; öğün cihazda geçici olarak tutuldu. \(error.localizedDescription)"
            }
        } else {
            mealFlowError = "Supabase Auth bağlanana kadar öğün cihazda geçici olarak tutuluyor."
        }

        meals.insert(
            Meal(
                mealType: analysis.mealType,
                title: analysis.detectedItems.map(\.name).joined(separator: ", "),
                totalCalories: analysis.totalCalories,
                macros: analysis.macros,
                items: analysis.detectedItems
            ),
            at: 0
        )
        selectedAnalysis = nil
        isSavingMeal = false
    }

    func sendChat(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        chatMessages.append(ChatMessage(role: .user, text: trimmed))
        chatMessages.append(ChatMessage(role: .assistant, text: "Bugünkü protein hedefin için akşam öğününde yoğurt veya ızgara tavuk iyi gider. İstersen bunu plana ekleyebilirim."))
    }
}
