import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser, serviceClient } from "../_shared/auth.ts";
import {
  normalizeQuery,
  OpenFoodFactsProduct,
  productName,
  searchOpenFoodFacts,
  toNumber,
} from "../_shared/openfoodfacts.ts";

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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    await requireUser(req);
    const url = new URL(req.url);
    const query = normalizeQuery(url.searchParams.get("q") ?? "");

    if (query.length < 2) return json({ query, results: [] });

    const supabase = serviceClient();
    const source = await searchOpenFoodFacts(query, 20);
    const foodIds: string[] = [];

    for (const product of source.products) {
      if (!product.code) continue;
      const name = productName(product);
      const serving = servingFor(product);
      if (name === "Unnamed product") continue;

      const { data: food } = await supabase
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

      if (!food) continue;
      foodIds.push(food.id);

      await supabase.from("food_servings").upsert({
        food_id: food.id,
        source_serving_id: `${product.code}:100g`,
        ...serving,
        is_default: true,
        raw_source: product.nutriments ?? {},
      }, { onConflict: "food_id,source_serving_id" });
    }

    const { data: foods } = await supabase
      .from("foods")
      .select("id,name,brand,image_url,source_url,food_servings(*)")
      .in("id", foodIds);

    return json({ query, source: "openfoodfacts", results: foods ?? [] });
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
