type CatalogIngredient = {
  name: string;
  amount: string;
  unit: string;
  note?: string;
};

type CatalogRecipe = {
  id: string;
  slug: string;
  title: string;
  subtitle: string;
  meal_type: "breakfast" | "lunch" | "dinner" | "snack";
  description: string;
  servings: number;
  prep_minutes: number;
  cook_minutes: number;
  calories: number;
  protein_gr: number;
  carbs_gr: number;
  fat_gr: number;
  ingredients: CatalogIngredient[];
  steps: string[];
  tips: string[];
  tags: string[];
};

type CatalogPlanItem = CatalogRecipe & {
  plan_item_id: string;
  is_applied: boolean;
  note?: string;
  alternatives: CatalogRecipe[];
};

const recipes: CatalogRecipe[] = [
  {
    id: "recipe-protein-breakfast",
    slug: "protein-breakfast",
    title: "Proteinli kahvaltı",
    subtitle: "Güne güçlü başlangıç",
    meal_type: "breakfast",
    description: "Yumurta, peynir ve tam tahıllı ekmek ile dengeli bir başlangıç.",
    servings: 1,
    prep_minutes: 12,
    cook_minutes: 8,
    calories: 430,
    protein_gr: 31,
    carbs_gr: 24,
    fat_gr: 21,
    ingredients: [
      { name: "Yumurta", amount: "2", unit: "adet" },
      { name: "Beyaz peynir", amount: "60", unit: "g" },
      { name: "Domates", amount: "1", unit: "adet" },
      { name: "Tam tahıllı ekmek", amount: "2", unit: "dilim" },
    ],
    steps: [
      "Yumurtaları hafif yağda pişir.",
      "Peynir ve domatesi tabağa al.",
      "Ekmek ile birlikte servis et.",
    ],
    tips: ["Yumurtayı fazla kurutmadan pişir."],
    tags: ["balanced", "high-protein"],
  },
  {
    id: "recipe-balanced-lunch",
    slug: "balanced-lunch",
    title: "Dengeli öğle",
    subtitle: "Sürdürülebilir enerji",
    meal_type: "lunch",
    description: "Tavuk, bulgur, yoğurt ve salata ile dengeli öğle yemeği.",
    servings: 1,
    prep_minutes: 18,
    cook_minutes: 20,
    calories: 620,
    protein_gr: 46,
    carbs_gr: 48,
    fat_gr: 22,
    ingredients: [
      { name: "Tavuk göğsü", amount: "160", unit: "g" },
      { name: "Bulgur", amount: "120", unit: "g" },
      { name: "Yoğurt", amount: "1", unit: "kase" },
      { name: "Salata", amount: "1", unit: "tabak" },
    ],
    steps: [
      "Tavuğu ızgarada pişir.",
      "Bulguru haşla ve dinlendir.",
      "Yanına yoğurt ve salata ile servis et.",
    ],
    tips: ["Bulguru önceden hazırlarsan öğle çok hızlı çıkar."],
    tags: ["balanced", "meal-prep"],
  },
  {
    id: "recipe-light-dinner",
    slug: "light-dinner",
    title: "Hafif akşam",
    subtitle: "Gün kapanışını yormayan tabak",
    meal_type: "dinner",
    description: "Sebze yemeği, yoğurt ve çorba ile rahat bir akşam.",
    servings: 1,
    prep_minutes: 15,
    cook_minutes: 25,
    calories: 520,
    protein_gr: 26,
    carbs_gr: 50,
    fat_gr: 18,
    ingredients: [
      { name: "Sebze yemeği", amount: "1", unit: "porsiyon" },
      { name: "Yoğurt", amount: "1", unit: "kase" },
      { name: "Çorba", amount: "1", unit: "kase" },
    ],
    steps: [
      "Sebze yemeğini ısıt.",
      "Yoğurt ve çorbayı yanında hazırla.",
      "Ağır olmadan servis et.",
    ],
    tips: ["Gece açlığı yaşıyorsan yanında ekstra salata eklenebilir."],
    tags: ["light", "evening"],
  },
  {
    id: "recipe-simple-snack",
    slug: "simple-snack",
    title: "Ara öğün",
    subtitle: "Küçük ama yeterli",
    meal_type: "snack",
    description: "Meyve ve badem ile kısa bir ara öğün.",
    servings: 1,
    prep_minutes: 3,
    cook_minutes: 0,
    calories: 180,
    protein_gr: 5,
    carbs_gr: 18,
    fat_gr: 10,
    ingredients: [
      { name: "Meyve", amount: "1", unit: "adet" },
      { name: "Badem", amount: "15", unit: "g" },
    ],
    steps: [
      "Meyveyi hazırla.",
      "Badem ile birlikte servis et.",
    ],
    tips: ["Yürüyüş öncesi iyi bir ara öğün olabilir."],
    tags: ["snack", "quick"],
  },
];

export function getRecipeById(id: string) {
  return recipes.find((recipe) => recipe.id === id || recipe.slug === id) ?? null;
}

export function getAlternatives(mealType: CatalogRecipe["meal_type"], currentId: string) {
  return recipes
    .filter((recipe) => recipe.meal_type === mealType && recipe.id !== currentId)
    .slice(0, 2);
}

export function createDailyPlan() {
  const breakfast = getRecipeById("recipe-protein-breakfast")!;
  const lunch = getRecipeById("recipe-balanced-lunch")!;
  const dinner = getRecipeById("recipe-light-dinner")!;
  const snack = getRecipeById("recipe-simple-snack")!;

  const buildItem = (recipe: CatalogRecipe, planItemId: string, alternatives: CatalogRecipe[]): CatalogPlanItem => ({
    ...recipe,
    plan_item_id: planItemId,
    is_applied: false,
    alternatives,
  });

  return {
    date: new Date().toISOString().split("T")[0],
    title: "Bugünün rehberi",
    total_calories: breakfast.calories + lunch.calories + dinner.calories + snack.calories,
    items: [
      buildItem(breakfast, "plan-breakfast-1", getAlternatives("breakfast", breakfast.id)),
      buildItem(lunch, "plan-lunch-1", getAlternatives("lunch", lunch.id)),
      buildItem(dinner, "plan-dinner-1", getAlternatives("dinner", dinner.id)),
      buildItem(snack, "plan-snack-1", getAlternatives("snack", snack.id)),
    ],
  };
}

export function recipeToMealPayload(recipeId: string) {
  const recipe = getRecipeById(recipeId);
  if (!recipe) return null;

  return {
    recipeId: recipe.id,
    title: recipe.title,
    mealType: recipe.meal_type,
    calories: recipe.calories,
    macros: {
      proteinGr: recipe.protein_gr,
      carbsGr: recipe.carbs_gr,
      fatGr: recipe.fat_gr,
    },
    items: recipe.ingredients.map((ingredient) => ({
      name: ingredient.name,
      quantity: 1,
      unit: ingredient.unit,
      calories: Math.round(recipe.calories / recipe.ingredients.length),
      proteinGr: Math.round(recipe.protein_gr / recipe.ingredients.length),
      carbsGr: Math.round(recipe.carbs_gr / recipe.ingredients.length),
      fatGr: Math.round(recipe.fat_gr / recipe.ingredients.length),
    })),
  };
}

export type { CatalogPlanItem, CatalogRecipe };
