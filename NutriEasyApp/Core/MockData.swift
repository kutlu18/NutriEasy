import Foundation

enum MockData {
    static let meals: [Meal] = [
        Meal(
            mealType: .breakfast,
            title: "Yumurta, beyaz peynir ve domates",
            totalCalories: 420,
            macros: MacroTargets(proteinGr: 28, carbsGr: 18, fatGr: 24),
            items: [
                MealItem(name: "Yumurta", quantity: 2, unit: "adet", calories: 156, proteinGr: 13, carbsGr: 1, fatGr: 11),
                MealItem(name: "Beyaz peynir", quantity: 60, unit: "g", calories: 180, proteinGr: 12, carbsGr: 2, fatGr: 14),
                MealItem(name: "Domates", quantity: 1, unit: "adet", calories: 24, proteinGr: 1, carbsGr: 5, fatGr: 0)
            ]
        ),
        Meal(
            mealType: .lunch,
            title: "Tavuklu salata",
            totalCalories: 510,
            macros: MacroTargets(proteinGr: 46, carbsGr: 32, fatGr: 18),
            items: [
                MealItem(name: "Izgara tavuk", quantity: 160, unit: "g", calories: 265, proteinGr: 42, carbsGr: 0, fatGr: 8),
                MealItem(name: "Salata", quantity: 1, unit: "kase", calories: 120, proteinGr: 3, carbsGr: 18, fatGr: 4)
            ]
        )
    ]

    static let analysis = MealAnalysis(
        confidence: .medium,
        totalCalories: 610,
        macros: MacroTargets(proteinGr: 39, carbsGr: 58, fatGr: 24),
        detectedItems: [
            MealItem(name: "Izgara tavuk", quantity: 140, unit: "g", calories: 235, proteinGr: 36, carbsGr: 0, fatGr: 7),
            MealItem(name: "Pirinç pilavı", quantity: 160, unit: "g", calories: 210, proteinGr: 4, carbsGr: 45, fatGr: 3),
            MealItem(name: "Yoğurt", quantity: 120, unit: "g", calories: 75, proteinGr: 5, carbsGr: 6, fatGr: 3)
        ],
        warnings: ["Porsiyon tahmini orta güvenle hesaplandı."]
    )

    static let plannedMeals: [PlannedMeal] = [
        PlannedMeal(mealType: .breakfast, title: "Proteinli kahvaltı", description: "Yumurta, peynir, domates, tam tahıllı ekmek", calories: 430),
        PlannedMeal(mealType: .lunch, title: "Dengeli öğle", description: "Tavuk, bulgur, yoğurt ve salata", calories: 620),
        PlannedMeal(mealType: .dinner, title: "Hafif akşam", description: "Sebze yemeği, yoğurt ve çorba", calories: 520),
        PlannedMeal(mealType: .snack, title: "Ara öğün", description: "Meyve ve badem", calories: 180)
    ]
}
