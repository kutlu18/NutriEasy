// food domain models — split from core/models.dart.
// Do not import directly; use the 'package:nutri_easy_flutter/core/models.dart' barrel.
import 'meal.dart';

class FoodSearchResult {
  FoodSearchResult({
    this.id,
    this.brand,
    this.sourceUrl,
    this.source,
    this.servings = const [],
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String? id;
  final String? brand;
  final String? sourceUrl;
  final String? source;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<FoodServingOption> servings;

  FoodServingOption? get primaryServing {
    if (servings.isEmpty) return null;
    return servings.firstWhere(
      (serving) => serving.isDefault,
      orElse: () => servings.first,
    );
  }

  FoodSearchResult copyWith({
    String? id,
    String? name,
    String? brand,
    String? sourceUrl,
    String? source,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    List<FoodServingOption>? servings,
  }) {
    return FoodSearchResult(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      source: source ?? this.source,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      servings: servings ?? this.servings,
    );
  }

  factory FoodSearchResult.fromSupabase(Map<String, dynamic> data) {
    final servings = (data['food_servings'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(FoodServingOption.fromSupabase)
        .toList();
    final primaryServing = servings.isNotEmpty
        ? servings.firstWhere(
            (serving) => serving.isDefault,
            orElse: () => servings.first,
          )
        : null;

    return FoodSearchResult(
      id: data['id']?.toString(),
      name: data['name']?.toString() ?? 'Food',
      brand: data['brand']?.toString(),
      sourceUrl: data['source_url']?.toString(),
      source: data['source']?.toString(),
      calories: primaryServing?.calories ?? 0,
      protein: primaryServing?.proteinGr ?? 0,
      carbs: primaryServing?.carbsGr ?? 0,
      fat: primaryServing?.fatGr ?? 0,
      servings: servings,
    );
  }

  factory FoodSearchResult.fromMealItem(MealItem item) {
    return FoodSearchResult(
      id: item.foodId,
      name: item.name,
      calories: item.calories,
      protein: item.proteinGr,
      carbs: item.carbsGr,
      fat: item.fatGr,
      servings: [
        FoodServingOption(
          id: item.id,
          description: item.unit,
          metricAmount: item.quantity,
          metricUnit: item.unit,
          calories: item.calories,
          proteinGr: item.proteinGr,
          carbsGr: item.carbsGr,
          fatGr: item.fatGr,
          isDefault: true,
        ),
      ],
    );
  }

  Map<String, dynamic> toMealItemPayload({
    required double quantity,
    FoodServingOption? serving,
  }) {
    final selectedServing = serving ?? primaryServing;
    final baseCalories = selectedServing?.calories ?? calories;
    final baseProtein = selectedServing?.proteinGr ?? protein;
    final baseCarbs = selectedServing?.carbsGr ?? carbs;
    final baseFat = selectedServing?.fatGr ?? fat;

    return {
      'foodId': id,
      'name': name,
      'quantity': quantity,
      'unit': selectedServing?.metricUnit ?? selectedServing?.description ?? 'serving',
      'calories': (baseCalories * quantity).round(),
      'proteinGr': (baseProtein * quantity).round(),
      'carbsGr': (baseCarbs * quantity).round(),
      'fatGr': (baseFat * quantity).round(),
    };
  }
}


class FoodServingOption {
  FoodServingOption({
    this.id,
    required this.description,
    required this.metricAmount,
    required this.metricUnit,
    required this.calories,
    required this.proteinGr,
    required this.carbsGr,
    required this.fatGr,
    required this.isDefault,
  });

  final String? id;
  final String description;
  final double metricAmount;
  final String metricUnit;
  final int calories;
  final int proteinGr;
  final int carbsGr;
  final int fatGr;
  final bool isDefault;

  String get label {
    final amount = metricAmount == metricAmount.roundToDouble()
        ? metricAmount.round().toString()
        : metricAmount.toStringAsFixed(1);
    if (metricUnit.isEmpty) {
      return description;
    }
    return '$amount $metricUnit · $description';
  }

  FoodServingOption copyWith({
    String? id,
    String? description,
    double? metricAmount,
    String? metricUnit,
    int? calories,
    int? proteinGr,
    int? carbsGr,
    int? fatGr,
    bool? isDefault,
  }) {
    return FoodServingOption(
      id: id ?? this.id,
      description: description ?? this.description,
      metricAmount: metricAmount ?? this.metricAmount,
      metricUnit: metricUnit ?? this.metricUnit,
      calories: calories ?? this.calories,
      proteinGr: proteinGr ?? this.proteinGr,
      carbsGr: carbsGr ?? this.carbsGr,
      fatGr: fatGr ?? this.fatGr,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory FoodServingOption.fromSupabase(Map<String, dynamic> data) {
    return FoodServingOption(
      id: data['id']?.toString(),
      description: data['serving_description']?.toString() ?? 'serving',
      metricAmount: (data['metric_amount'] as num?)?.toDouble() ?? 1,
      metricUnit: data['metric_unit']?.toString() ?? 'serving',
      calories: (data['calories'] as num?)?.round() ?? 0,
      proteinGr: (data['protein_gr'] as num?)?.round() ?? 0,
      carbsGr: (data['carbs_gr'] as num?)?.round() ?? 0,
      fatGr: (data['fat_gr'] as num?)?.round() ?? 0,
      isDefault: data['is_default'] as bool? ?? false,
    );
  }
}

