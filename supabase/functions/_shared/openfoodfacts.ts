const userAgent = "NutriEasy/0.1 (contact@nutrieasy.app)";

export type OpenFoodFactsProduct = {
  code?: string;
  product_name?: string;
  product_name_en?: string;
  generic_name?: string;
  generic_name_en?: string;
  brands?: string;
  categories_tags?: string[];
  countries_tags?: string[];
  serving_size?: string;
  quantity?: string;
  image_front_url?: string;
  url?: string;
  lang?: string;
  nutriments?: Record<string, number | string | undefined>;
};

export function normalizeQuery(value: string) {
  return value.trim().toLocaleLowerCase("en-US").replace(/\s+/g, " ");
}

export function toNumber(value: unknown) {
  const parsed = Number(value ?? 0);
  return Number.isFinite(parsed) ? parsed : 0;
}

export function productName(product: OpenFoodFactsProduct) {
  return product.product_name_en || product.product_name || product.generic_name_en || product.generic_name || "Unnamed product";
}

export async function searchOpenFoodFacts(query: string, pageSize = 20) {
  const url = new URL("https://world.openfoodfacts.org/api/v2/search");
  url.searchParams.set("search_terms", query);
  url.searchParams.set("page_size", String(pageSize));
  url.searchParams.set(
    "fields",
    [
      "code",
      "product_name",
      "product_name_en",
      "generic_name",
      "generic_name_en",
      "brands",
      "categories_tags",
      "countries_tags",
      "nutriments",
      "serving_size",
      "quantity",
      "image_front_url",
      "url",
      "lang",
    ].join(","),
  );

  const res = await fetch(url, {
    headers: {
      "Accept": "application/json",
      "User-Agent": userAgent,
    },
  });

  if (!res.ok) {
    throw new Error(`Open Food Facts search failed: ${res.status} ${await res.text()}`);
  }

  const data = await res.json();
  if (data?.error) {
    throw new Error(`Open Food Facts API error: ${JSON.stringify(data.error)}`);
  }

  return {
    total: toNumber(data.count),
    products: Array.isArray(data.products) ? data.products as OpenFoodFactsProduct[] : [],
  };
}
