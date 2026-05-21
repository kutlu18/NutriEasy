import { corsHeaders, json } from "../_shared/cors.ts";
import { serviceClient } from "../_shared/auth.ts";
import { searchFatSecretFoods } from "../_shared/fatsecret.ts";

type FatSecretFood = {
  food_id: string | number;
  food_name: string;
  brand_name?: string;
  food_type?: string;
  food_url?: string;
  servings?: { serving?: FatSecretServing | FatSecretServing[] };
};

type FatSecretServing = {
  serving_id?: string | number;
  serving_description?: string;
  metric_serving_amount?: string | number;
  metric_serving_unit?: string;
  calories?: string | number;
  protein?: string | number;
  carbohydrate?: string | number;
  fat?: string | number;
  is_default?: string | number;
};

const RUN_TOKEN = "2a9f7f0c62d94b70b5d6b59efc1a71f4";

const defaultQueries = [
  "egg",
  "chicken breast",
  "white rice",
  "oatmeal",
  "plain yogurt",
  "feta cheese",
  "tomato",
  "cucumber",
  "lentil soup",
  "apple",
  "banana",
  "salmon",
];

function normalizeQuery(value: string) {
  return value.trim().toLocaleLowerCase("tr-TR").replace(/\s+/g, " ");
}

function asArray<T>(value: T | T[] | undefined): T[] {
  if (!value) return [];
  return Array.isArray(value) ? value : [value];
}

function toNumber(value: unknown) {
  const parsed = Number(value ?? 0);
  return Number.isFinite(parsed) ? parsed : 0;
}

async function importQuery(query: string, region: string, language: string) {
  const supabase = serviceClient();
  const normalizedQuery = normalizeQuery(query);
  const source = await searchFatSecretFoods(normalizedQuery, region, language);
  const sourceFoods = asArray<FatSecretFood>(source?.foods_search?.results?.food);
  const foodIds: string[] = [];

  for (const sourceFood of sourceFoods) {
    const { data: food, error: foodError } = await supabase
      .from("foods")
      .upsert({
        source: "fatsecret",
        source_food_id: String(sourceFood.food_id),
        name: sourceFood.food_name,
        brand: sourceFood.brand_name ?? null,
        food_type: sourceFood.food_type ?? null,
        region,
        language,
        source_url: sourceFood.food_url ?? null,
        raw_source: sourceFood,
      }, { onConflict: "source,source_food_id" })
      .select("id")
      .single();

    if (foodError || !food) continue;
    foodIds.push(food.id);

    for (const serving of asArray(sourceFood.servings?.serving)) {
      await supabase.from("food_servings").upsert({
        food_id: food.id,
        source_serving_id: serving.serving_id ? String(serving.serving_id) : null,
        serving_description: serving.serving_description ?? "serving",
        metric_amount: toNumber(serving.metric_serving_amount),
        metric_unit: serving.metric_serving_unit ?? null,
        calories: toNumber(serving.calories),
        protein_gr: toNumber(serving.protein),
        carbs_gr: toNumber(serving.carbohydrate),
        fat_gr: toNumber(serving.fat),
        is_default: String(serving.is_default ?? "0") === "1",
        raw_source: serving,
      }, { onConflict: "food_id,source_serving_id" });
    }
  }

  await supabase.from("food_search_cache").upsert({
    query: normalizedQuery,
    normalized_query: normalizedQuery,
    region,
    language,
    result_food_ids: foodIds,
    source: "fatsecret",
    total_results: toNumber(source?.foods_search?.total_results),
  }, { onConflict: "normalized_query,region,language,source_page" });

  await supabase.from("fatsecret_import_log").insert({
    request_kind: "seed",
    query: normalizedQuery,
    status: "success",
    inserted_food_count: foodIds.length,
  });

  return { query: normalizedQuery, insertedFoodCount: foodIds.length };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const providedToken = req.headers.get("x-run-token");
    if (providedToken !== RUN_TOKEN) {
      return json({ error: "unauthorized" }, 401);
    }

    const body = req.method === "POST" ? await req.json().catch(() => ({})) : {};
    const queries = Array.isArray(body.queries) && body.queries.length > 0
      ? body.queries.map(String)
      : defaultQueries;
    const region = body.region ?? "TR";
    const language = body.language ?? "tr";
    const results = [];

    for (const query of queries.slice(0, 50)) {
      results.push(await importQuery(query, region, language));
    }

    return json({ results });
  } catch (error) {
    await serviceClient().from("fatsecret_import_log").insert({
      request_kind: "seed",
      status: "failed",
      error_message: error instanceof Error ? error.message : "unknown_error",
    });

    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
