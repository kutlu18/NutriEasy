type FatSecretToken = {
  access_token: string;
  expires_in: number;
  token_type: string;
};

let cachedToken: { value: string; expiresAt: number } | null = null;

export async function fatSecretToken() {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60_000) {
    return cachedToken.value;
  }

  const body = new URLSearchParams({
    grant_type: "client_credentials",
    scope: Deno.env.get("FATSECRET_SCOPE") ?? "premier",
  });
  const credentials = btoa(`${Deno.env.get("FATSECRET_CLIENT_ID")!}:${Deno.env.get("FATSECRET_CLIENT_SECRET")!}`);

  const res = await fetch("https://oauth.fatsecret.com/connect/token", {
    method: "POST",
    headers: {
      "Authorization": `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });

  if (!res.ok) {
    const detail = await res.text();
    throw new Error(`FatSecret token failed: ${res.status} ${detail}`);
  }

  const token = await res.json() as FatSecretToken;
  cachedToken = {
    value: token.access_token,
    expiresAt: Date.now() + token.expires_in * 1000,
  };

  return cachedToken.value;
}

export async function searchFatSecretFoods(query: string, region = "TR", language = "tr") {
  const token = await fatSecretToken();
  const url = new URL("https://platform.fatsecret.com/rest/foods/search/v2");
  url.searchParams.set("search_expression", query);
  url.searchParams.set("max_results", "20");
  url.searchParams.set("page_number", "0");
  url.searchParams.set("format", "json");
  url.searchParams.set("region", region);
  url.searchParams.set("language", language);
  url.searchParams.set("flag_default_serving", "true");

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    throw new Error(`FatSecret search failed: ${res.status}`);
  }

  const data = await res.json();
  if (data?.error) {
    throw new Error(`FatSecret API error ${data.error.code}: ${data.error.message}`);
  }
  return data;
}
