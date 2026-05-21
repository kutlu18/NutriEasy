import { corsHeaders, json } from "../_shared/cors.ts";
import { serviceClient } from "../_shared/auth.ts";

type ImportProduct = {
  code: string;
  url?: string;
  product_name?: string;
  generic_name?: string;
  quantity?: string;
  brands?: string;
  categories?: string;
  categories_tags?: string;
  countries?: string;
  countries_tags?: string;
  ingredients_text?: string;
  ingredients_tags?: string;
  allergens?: string;
  allergens_en?: string;
  additives_tags?: string;
  nutriscore_score?: string | number;
  nutriscore_grade?: string;
  nova_group?: string | number;
  nutrient_levels_tags?: string;
  serving_size?: string;
  serving_quantity?: string | number;
  image_url?: string;
  image_small_url?: string;
  image_front_url?: string;
  image_ingredients_url?: string;
  image_nutrition_url?: string;
  completeness?: string | number;
  "energy-kcal_100g"?: string | number;
  "energy-kj_100g"?: string | number;
  proteins_100g?: string | number;
  carbohydrates_100g?: string | number;
  fat_100g?: string | number;
  "saturated-fat_100g"?: string | number;
  "trans-fat_100g"?: string | number;
  cholesterol_100g?: string | number;
  sugars_100g?: string | number;
  "added-sugars_100g"?: string | number;
  fiber_100g?: string | number;
  salt_100g?: string | number;
  sodium_100g?: string | number;
  alcohol_100g?: string | number;
  "vitamin-a_100g"?: string | number;
  "vitamin-c_100g"?: string | number;
  "vitamin-d_100g"?: string | number;
  "vitamin-e_100g"?: string | number;
  "vitamin-b1_100g"?: string | number;
  "vitamin-b2_100g"?: string | number;
  "vitamin-b6_100g"?: string | number;
  "vitamin-b9_100g"?: string | number;
  "vitamin-b12_100g"?: string | number;
  calcium_100g?: string | number;
  iron_100g?: string | number;
  magnesium_100g?: string | number;
  zinc_100g?: string | number;
  potassium_100g?: string | number;
  phosphorus_100g?: string | number;
  caffeine_100g?: string | number;
  nutrients_100g?: Record<string, number>;
  matched_query?: string;
  labels?: string;
  labels_tags?: string;
  traces?: string;
  traces_tags?: string;
  origins?: string;
  origins_tags?: string;
  manufacturing_places?: string;
  stores?: string;
  creator?: string;
  created_t?: string | number;
  last_modified_t?: string | number;
  ecoscore_score?: string | number;
  ecoscore_grade?: string;
  food_groups?: string;
  food_groups_tags?: string;
  pnns_groups_1?: string;
  pnns_groups_2?: string;
};

function toNumber(value: unknown) {
  const parsed = Number(value ?? 0);
  return Number.isFinite(parsed) ? parsed : 0;
}

function servingQuantity(product: ImportProduct) {
  const direct = toNumber(product.serving_quantity);
  if (direct > 0) return direct;

  const match = product.serving_size?.match(/(\d+(?:[.,]\d+)?)\s*(g|ml)\b/i);
  if (!match) return 100;

  const parsed = Number(match[1].replace(",", "."));
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 100;
}

function servingUnit(product: ImportProduct) {
  return /\bml\b/i.test(product.serving_size ?? "") ? "ml" : "g";
}

function perServing(product: ImportProduct, value: unknown) {
  return toNumber(value) * (servingQuantity(product) / 100);
}

function firstTag(value?: string) {
  return value?.split(",").map((item) => item.trim()).find(Boolean) ?? null;
}

function tags(value?: string) {
  return value?.split(",").map((item) => item.trim()).filter(Boolean) ?? [];
}

function normalizeQuery(value: string) {
  return value.trim().toLocaleLowerCase("en-US").replace(/\s+/g, " ");
}

function importableProducts(products: ImportProduct[]) {
  return products.slice(0, 1000).filter((product) => {
    if (!product.code) return false;

    const name = (product.product_name || product.generic_name || "").trim();
    if (!name) return false;

    const calories = toNumber(product["energy-kcal_100g"]);
    const protein = toNumber(product.proteins_100g);
    const carbs = toNumber(product.carbohydrates_100g);
    const fat = toNumber(product.fat_100g);
    return calories !== 0 || protein !== 0 || carbs !== 0 || fat !== 0;
  });
}

async function withoutExistingProducts(
  supabase: ReturnType<typeof serviceClient>,
  products: ImportProduct[],
) {
  const codes = [...new Set(products.map((product) => product.code))];
  const foodIdByCode = new Map<string, string>();

  for (let index = 0; index < codes.length; index += 200) {
    const { data, error } = await supabase
      .from("foods")
      .select("id,source_food_id")
      .eq("source", "openfoodfacts")
      .in("source_food_id", codes.slice(index, index + 200));

    if (error) {
      throw new Error(error.message);
    }

    for (const food of data ?? []) {
      if (food.source_food_id) foodIdByCode.set(food.source_food_id, food.id);
    }
  }

  const foodIds = [...foodIdByCode.values()];
  const foodIdsWithServings = new Set<string>();
  for (let index = 0; index < foodIds.length; index += 200) {
    const { data, error } = await supabase
      .from("food_servings")
      .select("food_id")
      .in("food_id", foodIds.slice(index, index + 200));

    if (error) {
      throw new Error(error.message);
    }

    for (const serving of data ?? []) {
      if (serving.food_id) foodIdsWithServings.add(serving.food_id);
    }
  }

  const existingCodes = new Set(
    [...foodIdByCode.entries()]
      .filter(([, foodId]) => foodIdsWithServings.has(foodId))
      .map(([code]) => code),
  );

  return {
    products: products.filter((product) => !existingCodes.has(product.code)),
    skippedExistingCount: existingCodes.size,
  };
}

function foodRow(product: ImportProduct) {
  return {
    source: "openfoodfacts",
    source_food_id: product.code,
    name: (product.product_name || product.generic_name || "").trim(),
    generic_name: product.generic_name || null,
    quantity: product.quantity || null,
    brand: product.brands || null,
    food_type: firstTag(product.categories_tags),
    categories: product.categories || null,
    categories_tags: tags(product.categories_tags),
    countries: product.countries || null,
    countries_tags: tags(product.countries_tags),
    ingredients_text: product.ingredients_text || null,
    ingredients_tags: tags(product.ingredients_tags),
    allergens: product.allergens || product.allergens_en || null,
    allergens_tags: tags(product.allergens),
    additives_tags: tags(product.additives_tags),
    nutriscore_score: product.nutriscore_score === "" || product.nutriscore_score == null ? null : Math.round(toNumber(product.nutriscore_score)),
    nutriscore_grade: product.nutriscore_grade || null,
    nova_group: product.nova_group === "" || product.nova_group == null ? null : Math.round(toNumber(product.nova_group)),
    nutrient_levels_tags: tags(product.nutrient_levels_tags),
    region: "US",
    language: "en",
    image_url: product.image_front_url || product.image_url || null,
    image_small_url: product.image_small_url || null,
    image_ingredients_url: product.image_ingredients_url || null,
    image_nutrition_url: product.image_nutrition_url || null,
    completeness: product.completeness === "" || product.completeness == null ? null : toNumber(product.completeness),
    labels: product.labels || null,
    labels_tags: tags(product.labels_tags),
    traces: product.traces || null,
    traces_tags: tags(product.traces_tags),
    origins: product.origins || null,
    origins_tags: tags(product.origins_tags),
    manufacturing_places: product.manufacturing_places || null,
    stores: product.stores || null,
    source_creator: product.creator || null,
    source_created_t: product.created_t === "" || product.created_t == null ? null : Math.round(toNumber(product.created_t)),
    source_last_modified_t: product.last_modified_t === "" || product.last_modified_t == null ? null : Math.round(toNumber(product.last_modified_t)),
    ecoscore_score: product.ecoscore_score === "" || product.ecoscore_score == null ? null : Math.round(toNumber(product.ecoscore_score)),
    ecoscore_grade: product.ecoscore_grade || null,
    food_groups: product.food_groups || null,
    food_groups_tags: tags(product.food_groups_tags),
    pnns_groups_1: product.pnns_groups_1 || null,
    pnns_groups_2: product.pnns_groups_2 || null,
    source_url: product.url || `https://world.openfoodfacts.org/product/${product.code}`,
    raw_source: null,
  };
}

function servingRow(product: ImportProduct, foodId: string) {
  const calories = toNumber(product["energy-kcal_100g"]);
  const protein = toNumber(product.proteins_100g);
  const carbs = toNumber(product.carbohydrates_100g);
  const fat = toNumber(product.fat_100g);

  return {
    food_id: foodId,
    source_serving_id: `${product.code}:100g`,
    serving_description: product.serving_size || "100 g",
    metric_amount: servingQuantity(product),
    metric_unit: servingUnit(product),
    energy_kj: perServing(product, product["energy-kj_100g"]),
    calories: perServing(product, calories),
    protein_gr: perServing(product, protein),
    carbs_gr: perServing(product, carbs),
    fat_gr: perServing(product, fat),
    saturated_fat_gr: perServing(product, product["saturated-fat_100g"]),
    trans_fat_gr: perServing(product, product["trans-fat_100g"]),
    cholesterol_gr: perServing(product, product.cholesterol_100g),
    sugars_gr: perServing(product, product.sugars_100g),
    added_sugars_gr: perServing(product, product["added-sugars_100g"]),
    fiber_gr: perServing(product, product.fiber_100g),
    salt_gr: perServing(product, product.salt_100g),
    sodium_gr: perServing(product, product.sodium_100g),
    alcohol_gr: perServing(product, product.alcohol_100g),
    vitamin_a_gr: perServing(product, product["vitamin-a_100g"]),
    vitamin_c_gr: perServing(product, product["vitamin-c_100g"]),
    vitamin_d_gr: perServing(product, product["vitamin-d_100g"]),
    vitamin_e_gr: perServing(product, product["vitamin-e_100g"]),
    vitamin_b1_gr: perServing(product, product["vitamin-b1_100g"]),
    vitamin_b2_gr: perServing(product, product["vitamin-b2_100g"]),
    vitamin_b6_gr: perServing(product, product["vitamin-b6_100g"]),
    vitamin_b9_gr: perServing(product, product["vitamin-b9_100g"]),
    vitamin_b12_gr: perServing(product, product["vitamin-b12_100g"]),
    calcium_gr: perServing(product, product.calcium_100g),
    iron_gr: perServing(product, product.iron_100g),
    magnesium_gr: perServing(product, product.magnesium_100g),
    zinc_gr: perServing(product, product.zinc_100g),
    potassium_gr: perServing(product, product.potassium_100g),
    phosphorus_gr: perServing(product, product.phosphorus_100g),
    caffeine_gr: perServing(product, product.caffeine_100g),
    nutrients_100g: product.nutrients_100g ?? {},
    is_default: true,
    raw_source: null,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const expectedKey = Deno.env.get("SEED_ADMIN_KEY");
    const providedKey = req.headers.get("x-seed-key");
    if (!expectedKey || providedKey !== expectedKey) {
      return json({ error: "unauthorized" }, 401);
    }

    const body = await req.json();
    const inputProducts = importableProducts(Array.isArray(body.products) ? body.products : []);
    const shouldUpdateCache = body.updateCache !== false;
    const shouldSkipExisting = body.skipExisting === true;
    const supabase = serviceClient();
    const foodIdsByQuery = new Map<string, string[]>();
    const { products, skippedExistingCount } = shouldSkipExisting
      ? await withoutExistingProducts(supabase, inputProducts)
      : { products: inputProducts, skippedExistingCount: 0 };

    if (products.length === 0) {
      return json({
        insertedFoodCount: 0,
        insertedServingCount: 0,
        skippedExistingCount,
        queryGroups: 0,
      });
    }

    const { data: foods, error: foodError } = await supabase
      .from("foods")
      .upsert(products.map(foodRow), { onConflict: "source,source_food_id" })
      .select("id,source_food_id");

    if (foodError || !foods) {
      throw new Error(foodError?.message ?? "food_upsert_failed");
    }

    const foodIdByCode = new Map(foods.map((food) => [food.source_food_id, food.id]));
    const servingRows = products
      .map((product) => {
        const foodId = foodIdByCode.get(product.code);
        return foodId ? servingRow(product, foodId) : null;
      })
      .filter((row): row is ReturnType<typeof servingRow> => row !== null);

    const { error: servingError } = await supabase
      .from("food_servings")
      .upsert(servingRows, { onConflict: "food_id,source_serving_id" });

    if (servingError) {
      throw new Error(servingError.message);
    }

    if (shouldUpdateCache) {
      for (const product of products) {
        if (!product.matched_query) continue;

        const foodId = foodIdByCode.get(product.code);
        if (!foodId) continue;

        const query = normalizeQuery(product.matched_query);
        const list = foodIdsByQuery.get(query) ?? [];
        list.push(foodId);
        foodIdsByQuery.set(query, list);
      }
    }

    for (const [query, foodIds] of foodIdsByQuery.entries()) {
      await supabase.from("food_search_cache").upsert({
        query,
        normalized_query: query,
        region: "US",
        language: "en",
        result_food_ids: foodIds,
        source: "openfoodfacts",
        total_results: foodIds.length,
      }, { onConflict: "normalized_query,region,language,source_page" });
    }

    await supabase.from("fatsecret_import_log").insert({
      request_kind: "openfoodfacts_local_import",
      query: `${foodIdsByQuery.size} query groups`,
      status: "success",
      inserted_food_count: foods.length,
    });

    return json({
      insertedFoodCount: foods.length,
      insertedServingCount: servingRows.length,
      skippedExistingCount,
      queryGroups: foodIdsByQuery.size,
    });
  } catch (error) {
    await serviceClient().from("fatsecret_import_log").insert({
      request_kind: "openfoodfacts_local_import",
      status: "failed",
      error_message: error instanceof Error ? error.message : "unknown_error",
    });

    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
