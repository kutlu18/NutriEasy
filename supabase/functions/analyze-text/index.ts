import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser, serviceClient } from "../_shared/auth.ts";

function toWords(text: string) {
  return text
    .toLocaleLowerCase("tr-TR")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .split(/\s+/)
    .filter((word) => word.length > 2)
    .slice(0, 8);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const user = await requireUser(req);
    const body = await req.json();
    const text = String(body.text ?? "").trim();
    const mealType = body.mealType ?? "snack";
    const profile = body.profile ?? {};

    if (text.length < 2) {
      return json({ error: "empty_text" }, 422);
    }

    const supabase = serviceClient();
    const words = toWords(text);
    const detectedItems = [];

    for (const word of words) {
      const { data } = await supabase
        .from("foods")
        .select("id,name,food_servings(*)")
        .ilike("name", `%${word}%`)
        .limit(1)
        .maybeSingle();

      const serving = data?.food_servings?.[0];
      if (data && serving) {
        detectedItems.push({
          foodId: data.id,
          name: data.name,
          quantity: 1,
          unit: serving.metric_unit ?? serving.serving_description ?? "serving",
          calories: Number(serving.calories ?? 0),
          proteinGr: Number(serving.protein_gr ?? 0),
          carbsGr: Number(serving.carbs_gr ?? 0),
          fatGr: Number(serving.fat_gr ?? 0),
          confidence: "medium",
        });
      }
    }

    const totals = detectedItems.reduce((acc, item) => ({
      calories: acc.calories + item.calories,
      proteinGr: acc.proteinGr + item.proteinGr,
      carbsGr: acc.carbsGr + item.carbsGr,
      fatGr: acc.fatGr + item.fatGr,
    }), { calories: 0, proteinGr: 0, carbsGr: 0, fatGr: 0 });

    const warnings: string[] = [];
    const targetCalories = Number(profile.targetCalories ?? 0);
    const proteinTarget = Number(profile.proteinTarget ?? 0);
    const goal = String(profile.selectedGoal ?? "");
    const activityLevel = String(profile.activityLevel ?? "");

    if (goal === "weight_loss" && totals.calories > Math.max(650, targetCalories * 0.35)) {
      warnings.push("Kilo verme hedefin icin bu ogun biraz yuksek olabilir.");
    }

    if (goal === "gain_muscle" && totals.proteinGr < Math.max(25, proteinTarget * 0.2)) {
      warnings.push("Kas kazanma hedefi icin protein biraz dusuk kalabilir.");
    }

    if (activityLevel === "active" && totals.calories < 300) {
      warnings.push("Aktif bir gun icin bu ogun biraz hafif gorunuyor.");
    }

    if (detectedItems.length === 0) {
      warnings.push("Bu metin icin yerel besin eslesmesi bulunamadi.");
    } else if (user.email) {
      warnings.push(`Analiz ${user.email.split("@")[0]} icin hazirlandi.`);
    }

    return json({
      analysisId: crypto.randomUUID(),
      mealType,
      confidence: detectedItems.length > 0 ? "medium" : "low",
      totalCalories: totals.calories,
      macros: {
        proteinGr: totals.proteinGr,
        carbsGr: totals.carbsGr,
        fatGr: totals.fatGr,
      },
      detectedItems,
      warnings,
    });
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
