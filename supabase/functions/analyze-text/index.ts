import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser, serviceClient } from "../_shared/auth.ts";
import { promptRegistry } from "../_shared/ai/prompts.ts";
import { runStructuredPrompt } from "../_shared/ai/prompt_runner.ts";
import { parseMealTextJson } from "../_shared/ai/schemas.ts";
import {
  matchParsedTextMeal,
  summarizeMealItems,
  wordsFromText,
} from "../_shared/ai/nutrition_matcher.ts";
import type { ParsedMealText } from "../_shared/ai/types.ts";

function emptyParsedMeal(text: string): ParsedMealText {
  return {
    meal_items: wordsFromText(text).map((word) => ({
      name: word,
      portion_text: null,
      portion_estimate: null,
      confidence: 0.55,
    })),
    overall_confidence: 0.55,
    notes: ["heuristic_parse"],
  };
}

function confidenceFromScore(score: number) {
  if (score >= 0.82) return "high";
  if (score >= 0.55) return "medium";
  return "low";
}

function profileWarnings(profile: Record<string, unknown>, totals: ReturnType<typeof summarizeMealItems>) {
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
  return warnings;
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

    const prompt = promptRegistry.mealTextParser;
    const ai = await runStructuredPrompt({
      prompt,
      variables: { user_meal_text: text },
      parse: parseMealTextJson,
    });

    const parsed = ai.data ?? emptyParsedMeal(text);
    const supabase = serviceClient();
    const detectedItems = await matchParsedTextMeal(supabase, parsed, text);
    const totals = summarizeMealItems(detectedItems);
    const warnings = [
      ...profileWarnings(profile, totals),
      ...parsed.notes,
    ];

    if (detectedItems.length === 0) {
      warnings.push("Bu metin icin yerel besin eslesmesi bulunamadi.");
    } else if (user.email) {
      warnings.push(`Analiz ${user.email.split("@")[0]} icin hazirlandi.`);
    }

    const confidence = detectedItems.length > 0
      ? confidenceFromScore(parsed.overall_confidence)
      : "low";

    return json({
      analysisId: crypto.randomUUID(),
      mealType,
      sourceType: "text",
      sourceLabel: text,
      confidence,
      totalCalories: totals.calories,
      macros: {
        proteinGr: totals.proteinGr,
        carbsGr: totals.carbsGr,
        fatGr: totals.fatGr,
      },
      detectedItems,
      warnings,
      meta: {
        ...ai.meta,
        confidence,
      },
    });
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
