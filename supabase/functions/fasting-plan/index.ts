import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser, serviceClient } from "../_shared/auth.ts";
import { loadFastingSummary, updateFastingPlan } from "../_shared/fasting.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const user = await requireUser(req);
    const supabase = serviceClient();
    const { data: profile, error } = await supabase
      .from("user_profiles")
      .select("selected_goal,activity_level")
      .eq("id", user.id)
      .maybeSingle();

    if (error) throw error;

    if (req.method === "GET") {
      const summary = await loadFastingSummary(
        user,
        profile ?? { selected_goal: "weight_loss", activity_level: "light" },
      );
      return json({ plan: summary.plan, summary });
    }

    if (req.method === "PATCH" || req.method === "POST") {
      const body = await req.json().catch(() => ({}));
      const plan = await updateFastingPlan(
        user,
        {
          enabled: body?.enabled,
          targetHours: body?.targetHours,
          windowStart: body?.windowStart,
          windowEnd: body?.windowEnd,
          label: body?.label,
          notes: body?.notes,
        },
      );

      const summary = await loadFastingSummary(
        user,
        profile ?? { selected_goal: "weight_loss", activity_level: "light" },
      );
      return json({ plan, summary });
    }

    return json({ error: "method_not_allowed" }, 405);
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
