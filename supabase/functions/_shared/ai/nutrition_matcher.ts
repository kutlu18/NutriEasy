import type { ConfidenceLabel, ParsedMealImage, ParsedMealText } from "./types.ts";

type FoodServingRow = {
  id?: string;
  serving_description?: string | null;
  metric_unit?: string | null;
  metric_amount?: number | string | null;
  calories?: number | string | null;
  protein_gr?: number | string | null;
  carbs_gr?: number | string | null;
  fat_gr?: number | string | null;
};

type FoodRow = {
  id: string;
  name: string;
  food_servings?: FoodServingRow[];
};

type DetectedMealItem = {
  foodId?: string | null;
  name: string;
  quantity: number;
  unit: string;
  calories: number;
  proteinGr: number;
  carbsGr: number;
  fatGr: number;
  confidence: ConfidenceLabel;
};

function num(value: unknown, fallback = 0) {
  const parsed = Number(value ?? fallback);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export function wordsFromText(text: string) {
  return text
    .toLocaleLowerCase("tr-TR")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .split(/\s+/)
    .filter((word) => word.length > 2)
    .slice(0, 10);
}

function confidenceLabel(value: number): ConfidenceLabel {
  if (value >= 0.82) return "high";
  if (value >= 0.55) return "medium";
  return "low";
}

function firstServing(food: FoodRow) {
  return Array.isArray(food.food_servings) && food.food_servings.length > 0
    ? food.food_servings[0]
    : null;
}

async function matchFood(supabase: any, name: string) {
  const { data } = await supabase
    .from("foods")
    .select("id,name,food_servings(*)")
    .ilike("name", `%${name}%`)
    .limit(1)
    .maybeSingle();
  return data;
}

function mealItemFromFood(food: FoodRow, confidence: ConfidenceLabel): DetectedMealItem | null {
  const serving = firstServing(food);
  if (!serving) return null;
  return {
    foodId: food.id,
    name: food.name,
    quantity: 1,
    unit: serving.metric_unit ?? serving.serving_description ?? "serving",
    calories: Math.round(num(serving.calories)),
    proteinGr: Math.round(num(serving.protein_gr)),
    carbsGr: Math.round(num(serving.carbs_gr)),
    fatGr: Math.round(num(serving.fat_gr)),
    confidence,
  };
}

export function summarizeMealItems(items: DetectedMealItem[]) {
  return items.reduce(
    (acc, item) => ({
      calories: acc.calories + item.calories,
      proteinGr: acc.proteinGr + item.proteinGr,
      carbsGr: acc.carbsGr + item.carbsGr,
      fatGr: acc.fatGr + item.fatGr,
    }),
    { calories: 0, proteinGr: 0, carbsGr: 0, fatGr: 0 },
  );
}

export async function matchParsedTextMeal(
  supabase: any,
  parsed: ParsedMealText,
  originalText: string,
) {
  const labels = parsed.meal_items.length > 0
    ? parsed.meal_items.map((item) => item.name)
    : wordsFromText(originalText);
  const detectedItems: DetectedMealItem[] = [];

  for (const label of labels) {
    const food = await matchFood(supabase, label);
    if (!food) continue;
    const parsedItem = parsed.meal_items.find((item) => item.name === label);
    const item = mealItemFromFood(food, confidenceLabel(parsedItem?.confidence ?? parsed.overall_confidence));
    if (item) detectedItems.push(item);
  }

  return detectedItems;
}

export async function matchParsedImageMeal(
  supabase: any,
  parsed: ParsedMealImage,
  fallbackLabel: string,
) {
  const labels = parsed.detected_items.length > 0
    ? parsed.detected_items.map((item) => item.name)
    : wordsFromText(fallbackLabel);
  const detectedItems: DetectedMealItem[] = [];

  for (const label of labels) {
    const food = await matchFood(supabase, label);
    if (!food) continue;
    const parsedItem = parsed.detected_items.find((item) => item.name === label);
    const item = mealItemFromFood(food, confidenceLabel(parsedItem?.confidence ?? 0.5));
    if (item) detectedItems.push(item);
  }

  return detectedItems;
}
