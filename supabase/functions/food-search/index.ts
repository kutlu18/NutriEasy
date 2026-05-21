import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser, serviceClient } from "../_shared/auth.ts";
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

function toFoodResult(food: Record<string, unknown>) {
  return {
    ...food,
    food_servings: Array.isArray(food.food_servings) ? food.food_servings : [],
  };
}

async function queryLocalFoods(supabase: ReturnType<typeof serviceClient>, query: string, region: string, language: string) {
  const { data, error } = await supabase
    .from("foods")
    .select("id,name,brand,source,source_url,food_type,food_servings(*)")
    .or(`name.ilike.%${query}%,brand.ilike.%${query}%,generic_name.ilike.%${query}%`)
    .eq("region", region)
    .eq("language", language)
    .order("updated_at", { ascending: false })
    .limit(15);

  if (error) throw error;
  return (data ?? []).map((food) => toFoodResult(food as Record<string, unknown>));
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    await requireUser(req);
    const url = new URL(req.url);
    const query = normalizeQuery(url.searchParams.get("q") ?? "");
    const region = url.searchParams.get("region") ?? "TR";
    const language = url.searchParams.get("language") ?? "tr";

    if (query.length < 2) {
      return json({ query, results: [] });
    }

    const supabase = serviceClient();
    const { data: cached } = await supabase
      .from("food_search_cache")
      .select("result_food_ids, expires_at, source")
      .eq("normalized_query", query)
      .eq("region", region)
      .eq("language", language)
      .maybeSingle();

    if (cached && new Date(cached.expires_at).getTime() > Date.now()) {
      const { data: foods } = await supabase
        .from("foods")
        .select("id,name,brand,source,source_url,food_type,food_servings(*)")
        .in("id", cached.result_food_ids);
      return json({ query, source: cached.source ?? "cache", results: (foods ?? []).map((food) => toFoodResult(food as Record<string, unknown>)) });
    }

    const localResults = await queryLocalFoods(supabase, query, region, language);
    if (localResults.length > 0) {
      await supabase.from("food_search_cache").upsert({
        query,
        normalized_query: query,
        region,
        language,
        result_food_ids: localResults.map((food) => food.id).filter(Boolean),
        source: "local",
        total_results: localResults.length,
      }, { onConflict: "normalized_query,region,language,source_page" });

      return json({ query, source: "local", results: localResults });
    }

    let sourceFoods: FatSecretFood[] = [];
    try {
      const source = await searchFatSecretFoods(query, region, language);
      sourceFoods = asArray<FatSecretFood>(source?.foods_search?.results?.food);
    } catch (error) {
      console.warn("FatSecret search unavailable", error);
    }

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
      query,
      normalized_query: query,
      region,
      language,
      result_food_ids: foodIds,
      source: "fatsecret",
      total_results: toNumber(source?.foods_search?.total_results),
    }, { onConflict: "normalized_query,region,language,source_page" });

    const { data: foods } = await supabase
      .from("foods")
      .select("id,name,brand,source,source_url,food_type,food_servings(*)")
      .in("id", foodIds);

    return json({ query, source: "fatsecret", results: (foods ?? []).map((food) => toFoodResult(food as Record<string, unknown>)) });
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
