import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser } from "../_shared/auth.ts";
import { promptRegistry } from "../_shared/ai/prompts.ts";
import { runStructuredPrompt } from "../_shared/ai/prompt_runner.ts";
import { parseCorrectionJson } from "../_shared/ai/schemas.ts";
import type { MealCorrectionPatch } from "../_shared/ai/types.ts";

type AnalysisItem = {
  foodId?: string | null;
  name?: string;
  quantity?: number;
  unit?: string;
  calories?: number;
  proteinGr?: number;
  carbsGr?: number;
  fatGr?: number;
  confidence?: string | null;
};

function toNumber(value: unknown) {
  const parsed = Number(value ?? 0);
  return Number.isFinite(parsed) ? parsed : 0;
}

function normalize(text: string) {
  return text
    .toLocaleLowerCase("tr-TR")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function correctionMultiplier(note: string, patch: MealCorrectionPatch | null) {
  if (patch?.actions.some((action) => action.type === "update_item" && action.new_portion?.includes("small"))) {
    return 0.85;
  }
  if (patch?.actions.some((action) => action.type === "update_item" && action.new_portion?.includes("large"))) {
    return 1.25;
  }

  const normalized = normalize(note);
  if (normalized.includes("yar") || normalized.includes("az")) return 0.75;
  if (normalized.includes("iki kat") || normalized.includes("cift") || normalized.includes("daha fazla")) return 1.25;
  if (normalized.includes("buyuk")) return 1.35;
  if (normalized.includes("kucuk")) return 0.85;
  return 1;
}

function applyPatch(items: AnalysisItem[], patch: MealCorrectionPatch | null) {
  if (!patch || patch.actions.length === 0) return items;
  let next = [...items];

  for (const action of patch.actions) {
    const target = normalize(action.target ?? action.item?.name ?? "");
    if (action.type === "remove_item" && target) {
      next = next.filter((item) => !normalize(item.name ?? "").includes(target));
    }
    if (action.type === "add_item" && action.item?.name) {
      next.push({
        name: action.item.name,
        quantity: 1,
        unit: action.item.portion ?? "serving",
        calories: 0,
        proteinGr: 0,
        carbsGr: 0,
        fatGr: 0,
        confidence: "low",
      });
    }
  }

  return next;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const user = await requireUser(req);
    const body = await req.json();
    const analysis = body.analysis ?? {};
    const note = String(body.note ?? "").trim();

    if (note.length < 2) {
      return json({ error: "empty_note" }, 422);
    }

    const prompt = promptRegistry.mealCorrection;
    const ai = await runStructuredPrompt({
      prompt,
      variables: {
        current_analysis_json: JSON.stringify(analysis),
        user_note: note,
      },
      parse: parseCorrectionJson,
    });

    const patch = ai.data;
    const multiplier = correctionMultiplier(note, patch);
    const items = Array.isArray(analysis.detectedItems) ? analysis.detectedItems : [];
    const patchedItems = applyPatch(items, patch);

    const correctedItems = patchedItems.map((item: AnalysisItem) => ({
      ...item,
      quantity: Math.max(0.1, Math.round(toNumber(item.quantity) * multiplier * 10) / 10),
      calories: Math.round(toNumber(item.calories) * multiplier),
      proteinGr: Math.round(toNumber(item.proteinGr) * multiplier),
      carbsGr: Math.round(toNumber(item.carbsGr) * multiplier),
      fatGr: Math.round(toNumber(item.fatGr) * multiplier),
    }));

    const totals = correctedItems.reduce((acc, item) => ({
      calories: acc.calories + toNumber(item.calories),
      proteinGr: acc.proteinGr + toNumber(item.proteinGr),
      carbsGr: acc.carbsGr + toNumber(item.carbsGr),
      fatGr: acc.fatGr + toNumber(item.fatGr),
    }), { calories: 0, proteinGr: 0, carbsGr: 0, fatGr: 0 });

    const warnings = Array.isArray(analysis.warnings) ? analysis.warnings.map(String) : [];
    warnings.push(`Duzeltme uygulandi: ${note}`);
    if (patch?.actions.length) {
      warnings.push(`AI patch actions: ${patch.actions.map((action) => action.type).join(", ")}`);
    }

    return json({
      analysisId: String(analysis.analysisId ?? crypto.randomUUID()),
      mealType: String(analysis.mealType ?? "snack"),
      sourceType: String(analysis.sourceType ?? "text"),
      sourceLabel: String(analysis.sourceLabel ?? "Ogun"),
      confidence: ai.meta.fallback_used ? "medium" : "high",
      totalCalories: totals.calories,
      macros: {
        proteinGr: totals.proteinGr,
        carbsGr: totals.carbsGr,
        fatGr: totals.fatGr,
      },
      detectedItems: correctedItems,
      warnings,
      correctionNote: note,
      portionMultiplier: multiplier,
      correctedBy: user.id,
      patch,
      meta: {
        ...ai.meta,
        confidence: ai.meta.fallback_used ? "medium" : "high",
      },
    });
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
