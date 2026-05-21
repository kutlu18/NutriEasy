import Foundation

enum Goal: String, CaseIterable, Identifiable {
    case weightLoss = "weight_loss"
    case gainMuscle = "gain_muscle"
    case maintain
    case fasting

    var id: String { rawValue }
    var title: String {
        switch self {
        case .weightLoss: "Kilo vermek"
        case .gainMuscle: "Kas kazanmak"
        case .maintain: "Formumu korumak"
        case .fasting: "Aralıklı oruç"
        }
    }
}

enum Gender: String, CaseIterable, Identifiable {
    case female, male, preferNotToSay
    var id: String { rawValue }
    var title: String {
        switch self {
        case .female: "Kadın"
        case .male: "Erkek"
        case .preferNotToSay: "Belirtmek istemiyorum"
        }
    }
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary, light, moderate, active
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sedentary: "Çoğunlukla oturuyorum"
        case .light: "Biraz hareketliyim"
        case .moderate: "Orta düzey hareketliyim"
        case .active: "Oldukça aktifim"
        }
    }
}

enum LoggingMethod: String, CaseIterable, Identifiable {
    case photo, text, mixed
    var id: String { rawValue }
    var title: String {
        switch self {
        case .photo: "Fotoğraf"
        case .text: "Yazı"
        case .mixed: "Hepsi"
        }
    }
}

enum MealType: String, CaseIterable, Identifiable, Codable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
    var title: String {
        switch self {
        case .breakfast: "Kahvaltı"
        case .lunch: "Öğle"
        case .dinner: "Akşam"
        case .snack: "Ara öğün"
        }
    }
}

struct UserProfile: Identifiable {
    var id = UUID().uuidString
    var name = "Umut"
    var email = "umut@example.com"
    var gender: Gender = .preferNotToSay
    var age = 30
    var heightCm = 175
    var weightKg = 78
    var targetWeightKg: Int? = 72
    var selectedGoal: Goal = .weightLoss
    var activityLevel: ActivityLevel = .light
    var preferredLoggingMethod: LoggingMethod = .mixed
    var onboardingCompleted = false
}

struct MacroTargets: Codable, Equatable {
    var proteinGr: Int
    var carbsGr: Int
    var fatGr: Int
}

struct MealItem: Identifiable, Codable, Equatable {
    var id = UUID().uuidString
    var foodId: String?
    var name: String
    var quantity: Double
    var unit: String
    var calories: Int
    var proteinGr: Int
    var carbsGr: Int
    var fatGr: Int
    var confidence: MealAnalysis.Confidence?

    init(
        id: String = UUID().uuidString,
        foodId: String? = nil,
        name: String,
        quantity: Double,
        unit: String,
        calories: Int,
        proteinGr: Int,
        carbsGr: Int,
        fatGr: Int,
        confidence: MealAnalysis.Confidence? = nil
    ) {
        self.id = id
        self.foodId = foodId
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.calories = calories
        self.proteinGr = proteinGr
        self.carbsGr = carbsGr
        self.fatGr = fatGr
        self.confidence = confidence
    }
}

struct Meal: Identifiable, Codable, Equatable {
    var id = UUID().uuidString
    var mealType: MealType
    var title: String
    var totalCalories: Int
    var macros: MacroTargets
    var items: [MealItem]
    var createdAt = Date()
}

struct MealAnalysis: Identifiable, Equatable {
    var id = UUID().uuidString
    var mealType: MealType = .snack
    var confidence: Confidence
    var totalCalories: Int
    var macros: MacroTargets
    var detectedItems: [MealItem]
    var warnings: [String] = []

    enum Confidence: String, Codable {
        case low, medium, high
        var title: String {
            switch self {
            case .low: "Düşük"
            case .medium: "Orta"
            case .high: "Yüksek"
            }
        }
    }
}

struct HydrationStatus {
    var current: Int
    var target: Int
    var unit: String
}

struct TodayDashboard {
    var date = Date()
    var calorieTarget: Int
    var consumedCalories: Int
    var remainingCalories: Int { max(calorieTarget - consumedCalories, 0) }
    var macroTargets: MacroTargets
    var consumedMacros: MacroTargets
    var meals: [Meal]
    var hydration: HydrationStatus
}

struct PlannedMeal: Identifiable {
    var id = UUID().uuidString
    var mealType: MealType
    var title: String
    var description: String
    var calories: Int
}

struct ChatMessage: Identifiable {
    var id = UUID().uuidString
    var role: Role
    var text: String
    var createdAt = Date()

    enum Role {
        case user, assistant
    }
}
