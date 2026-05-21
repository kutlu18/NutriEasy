import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser, serviceClient } from "../_shared/auth.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const user = await requireUser(req);
    const supabase = serviceClient();
    const url = new URL(req.url);
    const mealId = url.searchParams.get("id") ?? "";

    if (req.method === "GET") {
      const baseQuery = supabase
        .from("meals")
        .select("id,meal_type,title,total_calories,protein_gr,carbs_gr,fat_gr,logged_at,created_at,meal_items(id,meal_id,food_id,name,quantity,unit,calories,protein_gr,carbs_gr,fat_gr,confidence,raw_analysis)")
        .eq("user_id", user.id)
        .order("logged_at", { ascending: false });

      if (mealId) {
        const { data, error } = await baseQuery.eq("id", mealId).maybeSingle();
        if (error) throw error;
        return json({ meal: data ?? null });
      }

      const { data, error } = await baseQuery;
      if (error) throw error;
      return json({ meals: data ?? [] });
    }

    if (req.method === "DELETE") {
      if (!mealId) {
        return json({ error: "missing_meal_id" }, 400);
      }

      const { error: itemError } = await supabase
        .from("meal_items")
        .delete()
        .eq("meal_id", mealId);
      if (itemError) throw itemError;

      const { error: mealError } = await supabase
        .from("meals")
        .delete()
        .eq("id", mealId)
        .eq("user_id", user.id);
      if (mealError) throw mealError;

      return json({ success: true, id: mealId });
    }

    return json({ error: "method_not_allowed" }, 405);
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
