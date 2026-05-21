import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser } from "../_shared/auth.ts";

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

function correctionMultiplier(note: string) {
  const normalized = normalize(note);

  if (normalized.includes("yarım") || normalized.includes("yarm") || normalized.includes("az")) {
    return 0.75;
  }
  if (normalized.includes("iki kat") || normalized.includes("cift") || normalized.includes("çift") || normalized.includes("daha fazla")) {
    return 1.25;
  }
  if (normalized.includes("daha buyuk") || normalized.includes("daha büyük") || normalized.includes("büyük")) {
    return 1.35;
  }
  if (normalized.includes("daha kucuk") || normalized.includes("daha küçük") || normalized.includes("kucuk")) {
    return 0.85;
  }
  return 1;
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

    const multiplier = correctionMultiplier(note);
    const items = Array.isArray(analysis.detectedItems) ? analysis.detectedItems : [];

    const correctedItems = items.map((item: AnalysisItem) => ({
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
    if (normalize(note).includes("protein")) {
      warnings.push("Protein odakli duzeltme notu alindi.");
    }
    if (normalize(note).includes("pilav") || normalize(note).includes("karbonhidrat")) {
      warnings.push("Karbonhidrat iceren bir duzeltme notu alindi.");
    }

    const sourceLabel = String(analysis.sourceLabel ?? "Öğün");

    return json({
      analysisId: String(analysis.analysisId ?? crypto.randomUUID()),
      mealType: String(analysis.mealType ?? "snack"),
      sourceType: String(analysis.sourceType ?? "text"),
      sourceLabel,
      confidence: "medium",
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
    });
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
