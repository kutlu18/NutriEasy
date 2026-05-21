import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser } from "../_shared/auth.ts";
import { sendChatMessage } from "../_shared/chat.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const user = await requireUser(req);
    const body = await req.json().catch(() => ({}));
    const message = String(body?.message ?? "").trim();

    if (message.length < 2) {
      return json({ error: "empty_message" }, 422);
    }

    const clientContext = body?.context as Record<string, unknown> | undefined;
    const result = await sendChatMessage(user.id, message, clientContext);
    return json(result);
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
