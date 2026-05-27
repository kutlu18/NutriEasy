// home_greeting.dart — context-aware greeting line on the Home screen.
//
// Reads the user's daily meal/macro state plus the current time of day,
// and returns a single Turkish sentence that goes into _Greeting's
// tagline slot.
//
// Designed to:
//   - Surface useful observations (calorie remaining, macro balance,
//     missing meal slots given time of day).
//   - Lightly guide ("öğle için protein ağırlıklı bir seçim iyi olur")
//     without prescribing specific foods or quantities.
//   - Never claim clinical authority. A disclaimer line in the Profile
//     surface clarifies that NutriEasy guidance is general, not medical.
//
// Rules are deterministic and ordered by priority. The first matching
// branch wins; later branches are fallbacks.

import '../models/meal.dart';
import '../models/user.dart';

/// Public entry point. All inputs are pure state, no DateTime.now() call
/// inside — caller supplies `now` so tests and previews can pin time.
String buildHomeGreeting({
  required List<Meal> meals,
  required int calorieTarget,
  required MacroTargets macroTargets,
  required DateTime now,
}) {
  final hour = now.hour;
  final timeOfDay = _timeOfDay(hour);

  // 1. Empty day — no meals logged yet.
  if (meals.isEmpty) {
    return switch (timeOfDay) {
      _TimeOfDay.morning => 'Günaydın. Hadi kahvaltıyı ekleyelim.',
      _TimeOfDay.midday => 'Sabahki kalorin hâlâ giriliyor mu?',
      _TimeOfDay.afternoon => 'Bugün için boş — günü kapatmadan ilk öğününü ekle.',
      _TimeOfDay.evening => 'Akşam oluyor. Bugün hiç öğün eklemediysen kısa bir özet bile yardımcı olur.',
      _TimeOfDay.night => 'Bugün için boş — yarın yine başlarız.',
    };
  }

  // 2. Calorie target exceeded.
  final consumedCalories =
      meals.fold<int>(0, (sum, m) => sum + m.totalCalories);
  if (consumedCalories > calorieTarget) {
    return 'Bugün için yeterli. Yarın yeni bir başlangıç.';
  }

  // 3. Very close to target (under 200 kcal left).
  final remainingCalories = calorieTarget - consumedCalories;
  if (remainingCalories < 200) {
    return 'Hedefe çok yakınsın — sadece $remainingCalories kcal kaldı.';
  }

  // 4. Macro-balance observations on which slots have been logged.
  final consumedMacros = _sumMacros(meals);
  final proteinRatio = _safeRatio(consumedMacros.proteinGr, macroTargets.proteinGr);
  final carbsRatio = _safeRatio(consumedMacros.carbsGr, macroTargets.carbsGr);
  final fatRatio = _safeRatio(consumedMacros.fatGr, macroTargets.fatGr);

  final breakfastLogged = meals.any((m) => m.mealType == MealType.breakfast);
  final lunchLogged = meals.any((m) => m.mealType == MealType.lunch);
  final dinnerLogged = meals.any((m) => m.mealType == MealType.dinner);

  // 4a. Breakfast done, protein low overall — guide lunch.
  if (breakfastLogged && !lunchLogged && proteinRatio < 0.25) {
    return 'Kahvaltıda protein hafif kaldı. Öğle için protein ağırlıklı bir seçim yardımcı olur.';
  }

  // 4b. Breakfast done, carbs already a large share — guide dinner.
  if (breakfastLogged && !dinnerLogged && carbsRatio > 0.5 && proteinRatio < 0.45) {
    return 'Karbonhidrat hızlı doluyor. Akşam için protein ve sebze ağırlıklı bir tercih iyi olur.';
  }

  // 4c. Lunch done, protein still open — guide dinner.
  if (lunchLogged && !dinnerLogged && proteinRatio < 0.55) {
    final percent = (proteinRatio * 100).round();
    return 'Bugün protein hedefin %$percent. Akşam yemeği için protein ağırlıklı düşünebilirsin.';
  }

  // 4d. Lunch done, fat already at or above target — guide dinner light.
  if (lunchLogged && !dinnerLogged && fatRatio >= 1.0) {
    return 'Yağ alımın bugün için yeterli. Akşam hafif bir tercih iyi olur.';
  }

  // 5. Missed-meal nudges based on time of day.
  // 5a. Past noon and breakfast still missing.
  if (hour >= 11 && !breakfastLogged) {
    return 'Kahvaltıyı atladıysan, ilk öğünü eklemen takip için önemli.';
  }

  // 5b. Past 15:00 and lunch still missing.
  if (hour >= 15 && !lunchLogged) {
    return 'Öğle yemeği eklemediysen, hatırlatıyorum.';
  }

  // 5c. Past 21:00 and dinner still missing.
  if (hour >= 21 && !dinnerLogged) {
    return 'Akşam yemeği eklemeyi unutma.';
  }

  // 6. Generic fallback: just surface the remaining calorie budget.
  return 'Bugün için $remainingCalories kcal daha hakkın var.';
}

enum _TimeOfDay { morning, midday, afternoon, evening, night }

_TimeOfDay _timeOfDay(int hour) {
  if (hour >= 5 && hour < 11) return _TimeOfDay.morning;
  if (hour >= 11 && hour < 15) return _TimeOfDay.midday;
  if (hour >= 15 && hour < 17) return _TimeOfDay.afternoon;
  if (hour >= 17 && hour < 21) return _TimeOfDay.evening;
  return _TimeOfDay.night;
}

MacroTargets _sumMacros(List<Meal> meals) {
  return meals.fold<MacroTargets>(
    MacroTargets(proteinGr: 0, carbsGr: 0, fatGr: 0),
    (acc, meal) => MacroTargets(
      proteinGr: acc.proteinGr + meal.macros.proteinGr,
      carbsGr: acc.carbsGr + meal.macros.carbsGr,
      fatGr: acc.fatGr + meal.macros.fatGr,
    ),
  );
}

double _safeRatio(int consumed, int target) {
  if (target == 0) return 0;
  return consumed / target;
}
