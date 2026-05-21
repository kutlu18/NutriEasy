import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser, serviceClient } from "../_shared/auth.ts";
import { loadFastingSummary, startFastingSession } from "../_shared/fasting.ts";

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

    const session = await startFastingSession(
      user,
      profile ?? { selected_goal: "weight_loss", activity_level: "light" },
    );
    const summary = await loadFastingSummary(
      user,
      profile ?? { selected_goal: "weight_loss", activity_level: "light" },
    );

    return json({ session, summary });
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
