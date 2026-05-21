import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser, serviceClient } from "../_shared/auth.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const user = await requireUser(req);
    const body = await req.json();
    const items = Array.isArray(body.items) ? body.items : [];
    const supabase = serviceClient();

    const totals = items.reduce((acc, item) => ({
      calories: acc.calories + Number(item.calories ?? 0),
      protein: acc.protein + Number(item.proteinGr ?? 0),
      carbs: acc.carbs + Number(item.carbsGr ?? 0),
      fat: acc.fat + Number(item.fatGr ?? 0),
    }), { calories: 0, protein: 0, carbs: 0, fat: 0 });

    const { data: meal, error: mealError } = await supabase
      .from("meals")
      .insert({
        user_id: user.id,
        meal_type: body.mealType ?? "snack",
        title: body.title ?? items.map((item) => item.name).join(", "),
        total_calories: totals.calories,
        protein_gr: totals.protein,
        carbs_gr: totals.carbs,
        fat_gr: totals.fat,
      })
      .select("*")
      .single();

    if (mealError) throw mealError;

    const rows = items.map((item) => ({
      meal_id: meal.id,
      food_id: item.foodId ?? null,
      name: item.name,
      quantity: item.quantity ?? 1,
      unit: item.unit ?? "serving",
      calories: item.calories ?? 0,
      protein_gr: item.proteinGr ?? 0,
      carbs_gr: item.carbsGr ?? 0,
      fat_gr: item.fatGr ?? 0,
      confidence: item.confidence ?? null,
      raw_analysis: item,
    }));

    if (rows.length > 0) {
      const { error: itemError } = await supabase.from("meal_items").insert(rows);
      if (itemError) throw itemError;
    }

    return json({ meal });
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
