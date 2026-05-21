import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser, serviceClient } from "../_shared/auth.ts";

function toNumber(value: unknown) {
  const parsed = Number(value ?? 0);
  return Number.isFinite(parsed) ? parsed : 0;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const user = await requireUser(req);
    const supabase = serviceClient();

    if (req.method !== "PATCH") {
      return json({ error: "method_not_allowed" }, 405);
    }

    const body = await req.json().catch(() => ({}));
    const itemId = String(body.id ?? body.itemId ?? "").trim();
    if (!itemId) {
      return json({ error: "missing_item_id" }, 400);
    }

    const { data: existingItem, error: itemLookupError } = await supabase
      .from("meal_items")
      .select("*")
      .eq("id", itemId)
      .maybeSingle();

    if (itemLookupError) throw itemLookupError;
    if (!existingItem) {
      return json({ error: "meal_item_not_found" }, 404);
    }

    const { data: parentMeal, error: mealLookupError } = await supabase
      .from("meals")
      .select("id,user_id")
      .eq("id", existingItem.meal_id)
      .eq("user_id", user.id)
      .maybeSingle();

    if (mealLookupError) throw mealLookupError;
    if (!parentMeal) {
      return json({ error: "meal_not_found" }, 404);
    }

    const nextQuantity = body.quantity != null ? toNumber(body.quantity) : toNumber(existingItem.quantity);
    const ratio = toNumber(existingItem.quantity) === 0 ? 1 : nextQuantity / toNumber(existingItem.quantity);

    const nextPayload = {
      quantity: nextQuantity,
      unit: body.unit ?? existingItem.unit,
      calories: body.calories != null ? toNumber(body.calories) : Math.round(toNumber(existingItem.calories) * ratio),
      protein_gr: body.proteinGr != null ? toNumber(body.proteinGr) : Math.round(toNumber(existingItem.protein_gr) * ratio),
      carbs_gr: body.carbsGr != null ? toNumber(body.carbsGr) : Math.round(toNumber(existingItem.carbs_gr) * ratio),
      fat_gr: body.fatGr != null ? toNumber(body.fatGr) : Math.round(toNumber(existingItem.fat_gr) * ratio),
      confidence: body.confidence ?? existingItem.confidence ?? null,
      raw_analysis: body.rawAnalysis ?? existingItem.raw_analysis ?? null,
    };

    const { data: updatedItem, error: updateError } = await supabase
      .from("meal_items")
      .update(nextPayload)
      .eq("id", itemId)
      .select("*")
      .single();

    if (updateError) throw updateError;

    const { data: mealItems, error: mealItemsError } = await supabase
      .from("meal_items")
      .select("calories,protein_gr,carbs_gr,fat_gr")
      .eq("meal_id", existingItem.meal_id);

    if (mealItemsError) throw mealItemsError;

    const totals = (mealItems ?? []).reduce((acc, item) => ({
      calories: acc.calories + toNumber(item.calories),
      proteinGr: acc.proteinGr + toNumber(item.protein_gr),
      carbsGr: acc.carbsGr + toNumber(item.carbs_gr),
      fatGr: acc.fatGr + toNumber(item.fat_gr),
    }), { calories: 0, proteinGr: 0, carbsGr: 0, fatGr: 0 });

    const { data: updatedMeal, error: mealUpdateError } = await supabase
      .from("meals")
      .update({
        total_calories: totals.calories,
        protein_gr: totals.proteinGr,
        carbs_gr: totals.carbsGr,
        fat_gr: totals.fatGr,
      })
      .eq("id", parentMeal.id)
      .eq("user_id", user.id)
      .select("*")
      .single();

    if (mealUpdateError) throw mealUpdateError;

    return json({
      item: updatedItem,
      meal: updatedMeal,
    });
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
