import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser, serviceClient } from "../_shared/auth.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const user = await requireUser(req);
    const supabase = serviceClient();
    const body = await req.json().catch(() => ({}));
    const profileInput = body?.profile ?? body ?? {};

    const name = profileInput.name ?? user.email?.split("@")[0] ?? "Umut";

    const payload = {
      id: user.id,
      name,
      gender: profileInput.gender ?? "prefer_not_to_say",
      age: profileInput.age ?? 30,
      height_cm: profileInput.heightCm ?? profileInput.height_cm ?? 175,
      weight_kg: profileInput.weightKg ?? profileInput.weight_kg ?? 78,
      target_weight_kg: profileInput.targetWeightKg ?? profileInput.target_weight_kg ?? 72,
      selected_goal: profileInput.selectedGoal ?? profileInput.selected_goal ?? "weight_loss",
      activity_level: profileInput.activityLevel ?? profileInput.activity_level ?? "light",
      preferred_logging_method:
        profileInput.preferredLoggingMethod ?? profileInput.preferred_logging_method ?? "mixed",
      onboarding_completed:
        profileInput.onboardingCompleted ?? profileInput.onboarding_completed ?? false,
    };

    const { data, error } = await supabase
      .from("user_profiles")
      .upsert(payload, { onConflict: "id" })
      .select("*")
      .single();

    if (error) throw error;

    return json({ profile: data });
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
