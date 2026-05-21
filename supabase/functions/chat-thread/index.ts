import { corsHeaders, json } from "../_shared/cors.ts";
import { requireUser } from "../_shared/auth.ts";
import { loadChatThread } from "../_shared/chat.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const user = await requireUser(req);

    if (req.method === "GET") {
      const contextParam = new URL(req.url).searchParams.get("context");
      const clientContext = contextParam ? JSON.parse(contextParam) : undefined;
      const result = await loadChatThread(user.id, clientContext);
      return json(result);
    }

    if (req.method === "POST") {
      const body = await req.json().catch(() => ({}));
      const clientContext = body?.context as Record<string, unknown> | undefined;
      const result = await loadChatThread(user.id, clientContext);
      return json(result);
    }

    return json({ error: "method_not_allowed" }, 405);
  } catch (error) {
    if (error instanceof Response) return error;
    return json({ error: error instanceof Error ? error.message : "unknown_error" }, 500);
  }
});
