import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser, serviceClient } from "../_shared/auth.ts";
import { promptRegistry } from "../_shared/ai/prompts.ts";
import { runStructuredPrompt } from "../_shared/ai/prompt_runner.ts";
import { parseMealImageJson } from "../_shared/ai/schemas.ts";
import {
  matchParsedImageMeal,
  summarizeMealItems,
  wordsFromText,
} from "../_shared/ai/nutrition_matcher.ts";
import type { ParsedMealImage } from "../_shared/ai/types.ts";

function emptyParsedImage(label: string): ParsedMealImage {
  return {
    detected_items: wordsFromText(label).map((word) => ({
      name: word,
      portion_label: null,
      confidence: 0.5,
    })),
    overall_confidence: label.length > 1 ? "medium" : "low",
    notes: ["heuristic_image_label_parse"],
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const user = await requireUser(req);
    const body = await req.json().catch(() => ({}));
    const imageLabel = String(body.imageLabel ?? body.caption ?? body.recognizedText ?? "").trim();
    const mealType = body.mealType ?? "snack";
    const profile = body.profile ?? {};

    if (imageLabel.length < 2) {
      const prompt = promptRegistry.mealImageParser;
      return json({
        analysisId: crypto.randomUUID(),
        mealType,
        sourceType: "photo",
        sourceLabel: imageLabel || "photo",
        confidence: "low",
        totalCalories: 0,
        macros: { proteinGr: 0, carbsGr: 0, fatGr: 0 },
        detectedItems: [],
        warnings: ["Gorsel aciklamasi bulunamadi."],
        meta: {
          model: prompt.model,
          prompt_id: prompt.id,
          prompt_version: prompt.version,
          provider: "heuristic",
          latency_ms: 0,
          confidence: "low",
          fallback_used: true,
        },
      });
    }

    const prompt = promptRegistry.mealImageParser;
    const ai = await runStructuredPrompt({
      prompt,
      variables: { image_label: imageLabel },
      parse: parseMealImageJson,
      confidence: "medium",
    });

    const parsed = ai.data ?? emptyParsedImage(imageLabel);
    const supabase = serviceClient();
    const detectedItems = await matchParsedImageMeal(supabase, parsed, imageLabel);
    const totals = summarizeMealItems(detectedItems);
    const warnings = [...parsed.notes];
    const targetCalories = Number(profile.targetCalories ?? 0);
    const goal = String(profile.selectedGoal ?? "");

    if (goal === "weight_loss" && totals.calories > Math.max(650, targetCalories * 0.35)) {
      warnings.push("Kilo verme hedefin icin bu ogun biraz yuksek olabilir.");
    }

    if (detectedItems.length === 0) {
      warnings.push("Gorsel ipuclari icin yerel besin eslesmesi bulunamadi.");
    } else if (user.email) {
      warnings.push(`Analiz ${user.email.split("@")[0]} icin hazirlandi.`);
    }

    const confidence = detectedItems.length > 0 ? parsed.overall_confidence : "low";

    return json({
      analysisId: crypto.randomUUID(),
      mealType,
      sourceType: "photo",
      sourceLabel: imageLabel,
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
