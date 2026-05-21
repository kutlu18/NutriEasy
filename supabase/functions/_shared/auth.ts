import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export function serviceClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

export async function requireUser(req: Request) {
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabase = serviceClient();
  const token = authHeader.replace("Bearer ", "");

  if (!token) {
    throw new Response(JSON.stringify({ error: "missing_authorization" }), { status: 401 });
  }

  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    throw new Response(JSON.stringify({ error: "invalid_session" }), { status: 401 });
  }

  return data.user;
}
