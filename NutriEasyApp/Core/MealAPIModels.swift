import Foundation

struct AnalyzeTextRequest: Encodable {
    var text: String
    var mealType: String
}

struct AnalyzeTextResponse: Decodable {
    var analysisId: String
    var mealType: MealType
    var confidence: MealAnalysis.Confidence
    var totalCalories: Double
    var macros: APIMacros
    var detectedItems: [APIMealItem]
    var warnings: [String]

    func toMealAnalysis() -> MealAnalysis {
        MealAnalysis(
            id: analysisId,
            mealType: mealType,
            confidence: confidence,
            totalCalories: totalCalories.roundedInt,
            macros: macros.toMacroTargets(),
            detectedItems: detectedItems.map { $0.toMealItem() },
            warnings: warnings
        )
    }
}

struct APIMacros: Codable {
    var proteinGr: Double
    var carbsGr: Double
    var fatGr: Double

    func toMacroTargets() -> MacroTargets {
        MacroTargets(
            proteinGr: proteinGr.roundedInt,
            carbsGr: carbsGr.roundedInt,
            fatGr: fatGr.roundedInt
        )
    }
}

struct APIMealItem: Codable {
    var foodId: String?
    var name: String
    var quantity: Double
    var unit: String
    var calories: Double
    var proteinGr: Double
    var carbsGr: Double
    var fatGr: Double
    var confidence: MealAnalysis.Confidence?

    func toMealItem() -> MealItem {
        MealItem(
            foodId: foodId,
            name: name,
            quantity: quantity,
            unit: unit,
            calories: calories.roundedInt,
            proteinGr: proteinGr.roundedInt,
            carbsGr: carbsGr.roundedInt,
            fatGr: fatGr.roundedInt,
            confidence: confidence
        )
    }

    init(from mealItem: MealItem) {
        foodId = mealItem.foodId
        name = mealItem.name
        quantity = mealItem.quantity
        unit = mealItem.unit
        calories = Double(mealItem.calories)
        proteinGr = Double(mealItem.proteinGr)
        carbsGr = Double(mealItem.carbsGr)
        fatGr = Double(mealItem.fatGr)
        confidence = mealItem.confidence
    }
}

struct SubmitMealLogRequest: Encodable {
    var title: String
    var mealType: String
    var items: [APIMealItem]

    init(analysis: MealAnalysis) {
        title = analysis.detectedItems.map(\.name).joined(separator: ", ")
        mealType = analysis.mealType.rawValue
        items = analysis.detectedItems.map(APIMealItem.init(from:))
    }
}

struct SubmitMealLogResponse: Decodable {
    var meal: SubmittedMeal
}

struct SubmittedMeal: Decodable {
    var id: String
}

private extension Double {
    var roundedInt: Int {
        Int(self.rounded())
    }
}
