import { corsHeaders, json } from "../_shared/cors.ts";
import { serviceClient } from "../_shared/auth.ts";
import {
  normalizeQuery,
  OpenFoodFactsProduct,
  productName,
  searchOpenFoodFacts,
  toNumber,
} from "../_shared/openfoodfacts.ts";

const defaultQueries = [
  "egg",
  "chicken breast",
  "plain yogurt",
  "white rice",
  "oatmeal",
  "banana",
  "apple",
  "tomato",
  "cucumber",
  "feta cheese",
  "salmon",
  "milk",
];

function servingFor(product: OpenFoodFactsProduct) {
  const nutriments = product.nutriments ?? {};
  return {
    serving_description: "100 g",
    metric_amount: 100,
    metric_unit: "g",
    calories: toNumber(nutriments["energy-kcal_100g"]),
    protein_gr: toNumber(nutriments.proteins_100g),
    carbs_gr: toNumber(nutriments.carbohydrates_100g),
    fat_gr: toNumber(nutriments.fat_100g),
  };
}

async function importQuery(query: string, pageSize: number) {
  const supabase = serviceClient();
  const normalizedQuery = normalizeQuery(query);
  const source = await searchOpenFoodFacts(normalizedQuery, pageSize);
  const foodIds: string[] = [];

  for (const product of source.products) {
    if (!product.code) continue;
    const name = productName(product);
    if (name === "Unnamed product") continue;

    const serving = servingFor(product);
    if (serving.calories === 0 && serving.protein_gr === 0 && serving.carbs_gr === 0 && serving.fat_gr === 0) {
      continue;
    }

    const { data: food, error: foodError } = await supabase
      .from("foods")
      .upsert({
        source: "openfoodfacts",
        source_food_id: product.code,
        name,
        brand: product.brands ?? null,
        food_type: product.categories_tags?.[0] ?? null,
        region: "US",
        language: product.lang ?? "en",
        image_url: product.image_front_url ?? null,
        source_url: product.url ?? `https://world.openfoodfacts.org/product/${product.code}`,
        raw_source: product,
      }, { onConflict: "source,source_food_id" })
      .select("id")
      .single();

    if (foodError || !food) continue;
    foodIds.push(food.id);

    await supabase.from("food_servings").upsert({
      food_id: food.id,
      source_serving_id: `${product.code}:100g`,
      ...serving,
      is_default: true,
      raw_source: product.nutriments ?? {},
    }, { onConflict: "food_id,source_serving_id" });
  }

  await supabase.from("food_search_cache").upsert({
    query: normalizedQuery,
    normalized_query: normalizedQuery,
    region: "US",
    language: "en",
    result_food_ids: foodIds,
    source: "openfoodfacts",
    total_results: source.total,
  }, { onConflict: "normalized_query,region,language,source_page" });

  await supabase.from("fatsecret_import_log").insert({
    request_kind: "openfoodfacts_seed",
    query: normalizedQuery,
    status: "success",
    inserted_food_count: foodIds.length,
  });

  return { query: normalizedQuery, insertedFoodCount: foodIds.length, totalResults: source.total };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const expectedKey = Deno.env.get("SEED_ADMIN_KEY");
    const providedKey = req.headers.get("x-seed-key");

    if (!expectedKey || providedKey !== expectedKey) {
      return json({ error: "unauthorized" }, 401);
    }

    const body = req.method === "POST" ? await req.json().catch(() => ({})) : {};
    const queries = Array.isArray(body.queries) && body.queries.length > 0
      ? body.queries.map(String)
      : defaultQueries;
    const pageSize = Math.min(Number(body.pageSize ?? 20), 50);
    const results = [];

    for (const query of queries.slice(0, 50)) {
      results.push(await importQuery(query, pageSize));
    }

    return json({ source: "openfoodfacts", results });
  } catch (error) {
    await serviceClient().from("fatsecret_import_log").insert({
      request_kind: "openfoodfacts_seed",
      status: "failed",
      error_message: error instanceof Error ? error.message : "unknown_error",
    });

    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
