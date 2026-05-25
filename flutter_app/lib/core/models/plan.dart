// plan domain models — split from core/models.dart.
// Do not import directly; use the 'package:nutri_easy_flutter/core/models.dart' barrel.
import 'meal.dart';

class RecipeIngredient {
  RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.note,
  });

  final String name;
  final String amount;
  final String unit;
  final String? note;

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
        'unit': unit,
        if (note != null) 'note': note,
      };

  factory RecipeIngredient.fromMap(Map<String, dynamic> data) {
    return RecipeIngredient(
      name: data['name']?.toString() ?? 'Ingredient',
      amount: data['amount']?.toString() ?? '1',
      unit: data['unit']?.toString() ?? 'serving',
      note: data['note']?.toString(),
    );
  }
}


class PlannedMeal {
  PlannedMeal({
    this.id,
    this.recipeId,
    required this.mealType,
    required this.title,
    required this.description,
    required this.calories,
    this.proteinGr = 0,
    this.carbsGr = 0,
    this.fatGr = 0,
    this.prepMinutes = 0,
    this.cookMinutes = 0,
    this.servings = 1,
    this.ingredients = const [],
    this.steps = const [],
    this.alternatives = const [],
    this.isApplied = false,
    this.note,
  });

  final String? id;
  final String? recipeId;
  final MealType mealType;
  final String title;
  final String description;
  final int calories;
  final int proteinGr;
  final int carbsGr;
  final int fatGr;
  final int prepMinutes;
  final int cookMinutes;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final List<PlannedMeal> alternatives;
  final bool isApplied;
  final String? note;

  PlannedMeal copyWith({
    String? id,
    String? recipeId,
    MealType? mealType,
    String? title,
    String? description,
    int? calories,
    int? proteinGr,
    int? carbsGr,
    int? fatGr,
    int? prepMinutes,
    int? cookMinutes,
    int? servings,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    List<PlannedMeal>? alternatives,
    bool? isApplied,
    String? note,
  }) {
    return PlannedMeal(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      mealType: mealType ?? this.mealType,
      title: title ?? this.title,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      proteinGr: proteinGr ?? this.proteinGr,
      carbsGr: carbsGr ?? this.carbsGr,
      fatGr: fatGr ?? this.fatGr,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      cookMinutes: cookMinutes ?? this.cookMinutes,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      alternatives: alternatives ?? this.alternatives,
      isApplied: isApplied ?? this.isApplied,
      note: note ?? this.note,
    );
  }

  int get totalMinutes => prepMinutes + cookMinutes;
}


