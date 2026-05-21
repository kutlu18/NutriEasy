import 'models.dart';

class MockData {
  static final meals = <Meal>[
    Meal(
      mealType: MealType.breakfast,
      title: 'Yumurta, beyaz peynir ve domates',
      totalCalories: 420,
      macros: MacroTargets(proteinGr: 28, carbsGr: 18, fatGr: 24),
      items: [
        MealItem(name: 'Yumurta', quantity: 2, unit: 'adet', calories: 156, proteinGr: 13, carbsGr: 1, fatGr: 11),
        MealItem(name: 'Beyaz peynir', quantity: 60, unit: 'g', calories: 180, proteinGr: 12, carbsGr: 2, fatGr: 14),
        MealItem(name: 'Domates', quantity: 1, unit: 'adet', calories: 24, proteinGr: 1, carbsGr: 5, fatGr: 0),
      ],
    ),
    Meal(
      mealType: MealType.lunch,
      title: 'Tavuklu salata',
      totalCalories: 510,
      macros: MacroTargets(proteinGr: 46, carbsGr: 32, fatGr: 18),
      items: [
        MealItem(name: 'Izgara tavuk', quantity: 160, unit: 'g', calories: 265, proteinGr: 42, carbsGr: 0, fatGr: 8),
        MealItem(name: 'Salata', quantity: 1, unit: 'kase', calories: 120, proteinGr: 3, carbsGr: 18, fatGr: 4),
      ],
    ),
  ];

  static final analysis = MealAnalysis(
    mealType: MealType.lunch,
    confidence: Confidence.medium,
    totalCalories: 610,
    macros: MacroTargets(proteinGr: 39, carbsGr: 58, fatGr: 24),
    detectedItems: [
      MealItem(name: 'Izgara tavuk', quantity: 140, unit: 'g', calories: 235, proteinGr: 36, carbsGr: 0, fatGr: 7),
      MealItem(name: 'Pirinç pilavı', quantity: 160, unit: 'g', calories: 210, proteinGr: 4, carbsGr: 45, fatGr: 3),
      MealItem(name: 'Yoğurt', quantity: 120, unit: 'g', calories: 75, proteinGr: 5, carbsGr: 6, fatGr: 3),
    ],
    warnings: ['Porsiyon tahmini orta güvenle hesaplandı.'],
  );

  static final plannedMeals = <PlannedMeal>[
    PlannedMeal(
      id: 'plan-breakfast-1',
      recipeId: 'recipe-protein-breakfast',
      mealType: MealType.breakfast,
      title: 'Proteinli kahvaltı',
      description: 'Yumurta, peynir, domates, tam tahıllı ekmek',
      calories: 430,
      proteinGr: 31,
      carbsGr: 24,
      fatGr: 21,
      prepMinutes: 12,
      cookMinutes: 8,
      servings: 1,
      ingredients: [
        RecipeIngredient(name: 'Yumurta', amount: '2', unit: 'adet'),
        RecipeIngredient(name: 'Beyaz peynir', amount: '60', unit: 'g'),
        RecipeIngredient(name: 'Domates', amount: '1', unit: 'adet'),
        RecipeIngredient(name: 'Tam tahıllı ekmek', amount: '2', unit: 'dilim'),
      ],
      steps: [
        'Yumurtaları hafif yağda pişir.',
        'Peynir ve domatesi tabağa al.',
        'Ekmek ile birlikte servis et.',
      ],
      alternatives: [
        PlannedMeal(
          mealType: MealType.breakfast,
          title: 'Avokadolu kahvaltı',
          description: 'Yumurta, avokado, roka ve tam tahıllı ekmek',
          calories: 410,
          proteinGr: 24,
          carbsGr: 22,
          fatGr: 24,
        ),
        PlannedMeal(
          mealType: MealType.breakfast,
          title: 'Yoğurt kasesi',
          description: 'Yoğurt, yulaf, meyve ve ceviz',
          calories: 380,
          proteinGr: 20,
          carbsGr: 34,
          fatGr: 16,
        ),
      ],
    ),
    PlannedMeal(
      id: 'plan-lunch-1',
      recipeId: 'recipe-balanced-lunch',
      mealType: MealType.lunch,
      title: 'Dengeli öğle',
      description: 'Tavuk, bulgur, yoğurt ve salata',
      calories: 620,
      proteinGr: 46,
      carbsGr: 48,
      fatGr: 22,
      prepMinutes: 18,
      cookMinutes: 20,
      ingredients: [
        RecipeIngredient(name: 'Tavuk göğsü', amount: '160', unit: 'g'),
        RecipeIngredient(name: 'Bulgur', amount: '120', unit: 'g'),
        RecipeIngredient(name: 'Yoğurt', amount: '1', unit: 'kase'),
        RecipeIngredient(name: 'Salata', amount: '1', unit: 'tabak'),
      ],
      steps: [
        'Tavuğu ızgarada pişir.',
        'Bulguru haşla ve dinlendir.',
        'Yanına yoğurt ve salata ile servis et.',
      ],
      alternatives: [
        PlannedMeal(
          mealType: MealType.lunch,
          title: 'Ton balıklı bowl',
          description: 'Ton balığı, mısır, yeşillik ve haşlanmış tahıl',
          calories: 570,
          proteinGr: 39,
          carbsGr: 44,
          fatGr: 18,
        ),
        PlannedMeal(
          mealType: MealType.lunch,
          title: 'Hindi wrap',
          description: 'Hindi eti, lavaş, yeşillik ve yoğurt sos',
          calories: 540,
          proteinGr: 38,
          carbsGr: 41,
          fatGr: 16,
        ),
      ],
    ),
    PlannedMeal(
      id: 'plan-dinner-1',
      recipeId: 'recipe-light-dinner',
      mealType: MealType.dinner,
      title: 'Hafif akşam',
      description: 'Sebze yemeği, yoğurt ve çorba',
      calories: 520,
      proteinGr: 26,
      carbsGr: 50,
      fatGr: 18,
      prepMinutes: 15,
      cookMinutes: 25,
      ingredients: [
        RecipeIngredient(name: 'Sebze yemeği', amount: '1', unit: 'porsiyon'),
        RecipeIngredient(name: 'Yoğurt', amount: '1', unit: 'kase'),
        RecipeIngredient(name: 'Çorba', amount: '1', unit: 'kase'),
      ],
      steps: [
        'Sebze yemeğini ısıt.',
        'Yoğurt ve çorbayı yanında hazırla.',
        'Ağır olmadan servis et.',
      ],
      alternatives: [
        PlannedMeal(
          mealType: MealType.dinner,
          title: 'Izgara somon',
          description: 'Somon, roka ve fırın sebzeler',
          calories: 560,
          proteinGr: 35,
          carbsGr: 24,
          fatGr: 29,
        ),
        PlannedMeal(
          mealType: MealType.dinner,
          title: 'Mercimek tabağı',
          description: 'Mercimek, yoğurt ve yeşillik',
          calories: 470,
          proteinGr: 28,
          carbsGr: 42,
          fatGr: 12,
        ),
      ],
    ),
    PlannedMeal(
      id: 'plan-snack-1',
      recipeId: 'recipe-snack',
      mealType: MealType.snack,
      title: 'Ara öğün',
      description: 'Meyve ve badem',
      calories: 180,
      proteinGr: 5,
      carbsGr: 18,
      fatGr: 10,
      prepMinutes: 3,
      cookMinutes: 0,
      ingredients: [
        RecipeIngredient(name: 'Meyve', amount: '1', unit: 'adet'),
        RecipeIngredient(name: 'Badem', amount: '15', unit: 'g'),
      ],
      steps: [
        'Meyveyi hazırla.',
        'Badem ile birlikte servis et.',
      ],
      alternatives: [
        PlannedMeal(
          mealType: MealType.snack,
          title: 'Yoğurt + tarçın',
          description: 'Yoğurt, tarçın ve birkaç fındık',
          calories: 160,
          proteinGr: 10,
          carbsGr: 12,
          fatGr: 7,
        ),
        PlannedMeal(
          mealType: MealType.snack,
          title: 'Protein bar',
          description: 'Pratik yüksek proteinli atıştırmalık',
          calories: 200,
          proteinGr: 16,
          carbsGr: 18,
          fatGr: 8,
        ),
      ],
    ),
  ];

  static final foodSuggestions = <FoodSearchResult>[
    FoodSearchResult(name: 'Greek yogurt', calories: 97, protein: 10, carbs: 4, fat: 5),
    FoodSearchResult(name: 'Grilled chicken breast', calories: 165, protein: 31, carbs: 0, fat: 4),
    FoodSearchResult(name: 'Brown rice', calories: 111, protein: 3, carbs: 23, fat: 1),
    FoodSearchResult(name: 'Oatmeal', calories: 68, protein: 2, carbs: 12, fat: 1),
  ];

  static final quickAdd = <FoodSearchResult>[
    FoodSearchResult(name: 'Yumurta + peynir', calories: 290, protein: 21, carbs: 4, fat: 21),
    FoodSearchResult(name: 'Tavuk salata', calories: 340, protein: 31, carbs: 12, fat: 16),
    FoodSearchResult(name: 'Yoğurt + yulaf', calories: 220, protein: 14, carbs: 28, fat: 6),
    FoodSearchResult(name: 'Meyve + badem', calories: 180, protein: 4, carbs: 18, fat: 10),
  ];
}
