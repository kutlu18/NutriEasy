// meal domain models — split from core/models.dart.
// Do not import directly; use the 'package:nutri_easy_flutter/core/models.dart' barrel.

enum MealSourceType { text, photo, voice }

extension MealSourceTypeTitle on MealSourceType {
  String get title => switch (this) {
        MealSourceType.text => 'YazÄ±',
        MealSourceType.photo => 'FotoÄŸraf',
        MealSourceType.voice => 'Ses',
      };
}


enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeTitle on MealType {
  String get title => switch (this) {
        MealType.breakfast => 'Kahvaltı',
        MealType.lunch => 'Öğle',
        MealType.dinner => 'Akşam',
        MealType.snack => 'Ara öğün',
      };
}


MealType mealTypeFromDb(Object? value) => switch (value?.toString()) {
      'breakfast' => MealType.breakfast,
      'lunch' => MealType.lunch,
      'dinner' => MealType.dinner,
      'snack' => MealType.snack,
      _ => MealType.snack,
    };


String mealTypeDbValue(MealType value) => switch (value) {
      MealType.breakfast => 'breakfast',
      MealType.lunch => 'lunch',
      MealType.dinner => 'dinner',
      MealType.snack => 'snack',
    };


class MacroTargets {
  MacroTargets({required this.proteinGr, required this.carbsGr, required this.fatGr});
  final int proteinGr;
  final int carbsGr;
  final int fatGr;
}


class MealItem {
  MealItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.proteinGr,
    required this.carbsGr,
    required this.fatGr,
    this.foodId,
    this.confidence,
  });

  final String? id;
  final String? foodId;
  final String name;
  final double quantity;
  final String unit;
  final int calories;
  final int proteinGr;
  final int carbsGr;
  final int fatGr;
  final Confidence? confidence;

  MealItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    int? calories,
    int? proteinGr,
    int? carbsGr,
    int? fatGr,
    String? foodId,
    Confidence? confidence,
  }) {
    return MealItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      proteinGr: proteinGr ?? this.proteinGr,
      carbsGr: carbsGr ?? this.carbsGr,
      fatGr: fatGr ?? this.fatGr,
      foodId: foodId ?? this.foodId,
      confidence: confidence ?? this.confidence,
    );
  }
}


class Meal {
  Meal({
    this.id,
    required this.mealType,
    required this.title,
    required this.totalCalories,
    required this.macros,
    required this.items,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String? id;
  final MealType mealType;
  final String title;
  final int totalCalories;
  final MacroTargets macros;
  final List<MealItem> items;
  final DateTime createdAt;

  Meal copyWith({
    String? id,
    MealType? mealType,
    String? title,
    int? totalCalories,
    MacroTargets? macros,
    List<MealItem>? items,
    DateTime? createdAt,
  }) {
    return Meal(
      id: id ?? this.id,
      mealType: mealType ?? this.mealType,
      title: title ?? this.title,
      totalCalories: totalCalories ?? this.totalCalories,
      macros: macros ?? this.macros,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Meal.fromSupabase(Map<String, dynamic> data) {
    final rawItems = (data['meal_items'] as List<dynamic>? ?? const []);
    return Meal(
      id: data['id']?.toString(),
      mealType: mealTypeFromDb(data['meal_type']),
      title: data['title']?.toString() ?? 'Meal',
      totalCalories: (data['total_calories'] as num?)?.round() ?? 0,
      macros: MacroTargets(
        proteinGr: (data['protein_gr'] as num?)?.round() ?? 0,
        carbsGr: (data['carbs_gr'] as num?)?.round() ?? 0,
        fatGr: (data['fat_gr'] as num?)?.round() ?? 0,
      ),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => MealItem(
              id: item['id']?.toString(),
              foodId: item['food_id']?.toString(),
              name: item['name']?.toString() ?? 'Food',
              quantity: (item['quantity'] as num?)?.toDouble() ?? 1,
              unit: item['unit']?.toString() ?? 'serving',
              calories: (item['calories'] as num?)?.round() ?? 0,
              proteinGr: (item['protein_gr'] as num?)?.round() ?? 0,
              carbsGr: (item['carbs_gr'] as num?)?.round() ?? 0,
              fatGr: (item['fat_gr'] as num?)?.round() ?? 0,
              confidence: confidenceFromDb(item['confidence']),
            ),
          )
          .toList(),
      createdAt: DateTime.tryParse(data['logged_at']?.toString() ?? '') ??
          DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}


class MealAnalysis {
  MealAnalysis({
    this.analysisId,
    required this.mealType,
    required this.confidence,
    required this.totalCalories,
    required this.macros,
    required this.detectedItems,
    this.sourceType = MealSourceType.text,
    this.sourceLabel,
    this.portionMultiplier = 1,
    this.correctionNote,
    this.warnings = const [],
  });

  final String? analysisId;
  final MealType mealType;
  final Confidence confidence;
  final int totalCalories;
  final MacroTargets macros;
  final List<MealItem> detectedItems;
  final MealSourceType sourceType;
  final String? sourceLabel;
  final double portionMultiplier;
  final String? correctionNote;
  final List<String> warnings;

  MealAnalysis copyWith({
    String? analysisId,
    MealType? mealType,
    Confidence? confidence,
    int? totalCalories,
    MacroTargets? macros,
    List<MealItem>? detectedItems,
    MealSourceType? sourceType,
    String? sourceLabel,
    double? portionMultiplier,
    String? correctionNote,
    List<String>? warnings,
  }) {
    return MealAnalysis(
      analysisId: analysisId ?? this.analysisId,
      mealType: mealType ?? this.mealType,
      confidence: confidence ?? this.confidence,
      totalCalories: totalCalories ?? this.totalCalories,
      macros: macros ?? this.macros,
      detectedItems: detectedItems ?? this.detectedItems,
      sourceType: sourceType ?? this.sourceType,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      portionMultiplier: portionMultiplier ?? this.portionMultiplier,
      correctionNote: correctionNote ?? this.correctionNote,
      warnings: warnings ?? this.warnings,
    );
  }

  MealAnalysis scalePortions(double multiplier) {
    final scaledItems = detectedItems
        .map(
          (item) => item.copyWith(
            quantity: (item.quantity * multiplier * 10).roundToDouble() / 10,
            calories: (item.calories * multiplier).round(),
            proteinGr: (item.proteinGr * multiplier).round(),
            carbsGr: (item.carbsGr * multiplier).round(),
            fatGr: (item.fatGr * multiplier).round(),
          ),
        )
        .toList();

    return copyWith(
      totalCalories: (totalCalories * multiplier).round(),
      macros: MacroTargets(
        proteinGr: (macros.proteinGr * multiplier).round(),
        carbsGr: (macros.carbsGr * multiplier).round(),
        fatGr: (macros.fatGr * multiplier).round(),
      ),
      detectedItems: scaledItems,
      portionMultiplier: multiplier,
    );
  }

  Meal toMeal() {
    return Meal(
      mealType: mealType,
      title: detectedItems.map((item) => item.name).join(', '),
      totalCalories: totalCalories,
      macros: macros,
      items: detectedItems,
    );
  }
}


enum Confidence { low, medium, high }

extension ConfidenceTitle on Confidence {
  String get title => switch (this) {
        Confidence.low => 'Düşük',
        Confidence.medium => 'Orta',
        Confidence.high => 'Yüksek',
      };
}


Confidence? confidenceFromDb(Object? value) => switch (value?.toString()) {
      'low' => Confidence.low,
      'medium' => Confidence.medium,
      'high' => Confidence.high,
      _ => null,
    };


class TodayDashboard {
  TodayDashboard({
    required this.calorieTarget,
    required this.consumedCalories,
    required this.macroTargets,
    required this.consumedMacros,
    required this.meals,
    required this.hydrationCurrent,
    required this.hydrationTarget,
  });

  final int calorieTarget;
  final int consumedCalories;
  final MacroTargets macroTargets;
  final MacroTargets consumedMacros;
  final List<Meal> meals;
  final int hydrationCurrent;
  final int hydrationTarget;

  int get remainingCalories => (calorieTarget - consumedCalories).clamp(0, calorieTarget);
}


