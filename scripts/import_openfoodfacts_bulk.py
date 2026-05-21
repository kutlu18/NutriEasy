import csv
import gzip
import io
import json
import os
import time
import urllib.request

DATA_URL = "https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz"
IMPORT_URL = "https://ifjghwsdpujzopppurdr.supabase.co/functions/v1/import-openfoodfacts-products"
SEED_KEY = os.environ.get("NUTRIEASY_SEED_ADMIN_KEY")
PER_QUERY = int(os.environ.get("NUTRIEASY_PER_QUERY", "8"))
MAX_SCAN = int(os.environ.get("NUTRIEASY_MAX_SCAN", "1500000"))
csv.field_size_limit(10_000_000)

QUERY_GROUPS = [
    "egg", "boiled egg", "chicken breast", "chicken", "turkey breast", "beef", "tuna", "salmon",
    "shrimp", "cod", "ham", "tofu", "lentils", "chickpeas", "black beans", "kidney beans",
    "white rice", "brown rice", "basmati rice", "pasta", "spaghetti", "bread", "whole wheat bread",
    "tortilla", "oatmeal", "oats", "granola", "corn flakes", "muesli", "quinoa",
    "plain yogurt", "greek yogurt", "milk", "skim milk", "almond milk", "cheese", "feta cheese",
    "mozzarella", "cheddar", "cottage cheese", "butter", "cream cheese",
    "banana", "apple", "orange", "strawberry", "blueberry", "grape", "pineapple", "mango",
    "avocado", "tomato", "cucumber", "lettuce", "spinach", "broccoli", "carrot", "potato",
    "sweet potato", "onion", "pepper", "mushroom", "corn", "peas",
    "almonds", "walnuts", "peanut butter", "hummus", "olive oil",
    "protein bar", "protein shake", "whey protein", "energy bar",
    "soup", "tomato soup", "lentil soup", "chicken soup", "salad", "caesar salad",
    "pizza", "burger", "sandwich", "wrap", "sushi", "noodles",
    "dark chocolate", "chocolate", "ice cream", "cookie", "crackers", "chips",
    "orange juice", "apple juice", "cola", "sparkling water", "coffee", "tea",
]

TEXT_COLUMNS = [
    "code", "url", "product_name", "generic_name", "quantity", "brands", "categories",
    "categories_tags", "countries", "countries_tags", "ingredients_text", "ingredients_tags",
    "allergens", "allergens_en", "additives_tags", "nutriscore_score", "nutriscore_grade",
    "nova_group", "nutrient_levels_tags", "serving_size", "serving_quantity", "image_url",
    "image_small_url", "image_ingredients_url", "image_nutrition_url", "completeness",
]

NUTRIENT_COLUMNS = [
    "energy-kj_100g", "energy-kcal_100g", "fat_100g", "saturated-fat_100g", "trans-fat_100g",
    "cholesterol_100g", "carbohydrates_100g", "sugars_100g", "added-sugars_100g", "fiber_100g",
    "proteins_100g", "salt_100g", "sodium_100g", "alcohol_100g", "vitamin-a_100g",
    "vitamin-c_100g", "vitamin-d_100g", "vitamin-e_100g", "vitamin-b1_100g", "vitamin-b2_100g",
    "vitamin-b6_100g", "vitamin-b9_100g", "vitamin-b12_100g", "calcium_100g", "iron_100g",
    "magnesium_100g", "zinc_100g", "potassium_100g", "phosphorus_100g", "caffeine_100g",
]


def as_float(value):
    try:
        return float(value) if value not in ("", None) else 0.0
    except ValueError:
        return 0.0


def clean(value):
    return (value or "").strip()


def has_nutrition(row):
    return any(as_float(row.get(col)) != 0 for col in ["energy-kcal_100g", "proteins_100g", "carbohydrates_100g", "fat_100g"])


def score_row(row, query):
    name = clean(row.get("product_name") or row.get("generic_name")).lower()
    if not name:
        return -1

    score = 0
    if name == query:
        score += 100
    if name.startswith(query):
        score += 45
    if f" {query} " in f" {name} ":
        score += 25
    if query in name:
        score += 15
    if "en:united-states" in row.get("countries_tags", ""):
        score += 10
    if clean(row.get("image_url")) or clean(row.get("image_small_url")):
        score += 6
    if clean(row.get("ingredients_text")):
        score += 6
    if clean(row.get("brands")):
        score += 3
    score += min(as_float(row.get("completeness")) * 10, 10)

    # Prefer simpler products for one-word natural foods.
    simple_queries = {
        "egg", "chicken", "beef", "salmon", "tuna", "banana", "apple", "orange", "tomato",
        "cucumber", "lettuce", "spinach", "broccoli", "carrot", "potato", "onion", "milk",
        "cheese", "bread", "rice", "oats",
    }
    if query in simple_queries:
        prepared_terms = ["sandwich", "wrap", "soup", "sauce", "cookie", "bar", "pizza", "burger", "with"]
        score -= sum(12 for term in prepared_terms if term in name)

    return score


def product_payload(row, query):
    payload = {column: clean(row.get(column, "")) for column in TEXT_COLUMNS}
    payload.update({column: clean(row.get(column, "")) for column in NUTRIENT_COLUMNS})
    payload["matched_query"] = query
    payload["nutrients_100g"] = {
        column: as_float(row.get(column))
        for column in NUTRIENT_COLUMNS
        if clean(row.get(column, "")) != ""
    }
    return payload


def collect_candidates(per_query=PER_QUERY, max_scan=MAX_SCAN):
    candidates = {query: [] for query in QUERY_GROUPS}
    scanned = 0
    request = urllib.request.Request(DATA_URL, headers={"User-Agent": "NutriEasy/0.1 (contact@nutrieasy.app)"})

    with urllib.request.urlopen(request, timeout=90) as response:
        gz = gzip.GzipFile(fileobj=response)
        text = io.TextIOWrapper(gz, encoding="utf-8", errors="replace", newline="")
        reader = csv.DictReader(text, delimiter="\t")
        for row in reader:
            scanned += 1
            name = clean(row.get("product_name") or row.get("generic_name"))
            if not name or not row.get("code") or not has_nutrition(row):
                continue

            low_name = name.lower()
            for query in QUERY_GROUPS:
                if len(candidates[query]) >= per_query * 5:
                    continue
                if query not in low_name:
                    continue
                score = score_row(row, query)
                if score > 0:
                    candidates[query].append((score, product_payload(row, query)))

            if scanned >= max_scan:
                break

    selected = []
    counts = {}
    seen_codes = set()
    for query, rows in candidates.items():
        rows.sort(key=lambda item: item[0], reverse=True)
        picked = []
        for _, payload in rows:
            if payload["code"] in seen_codes:
                continue
            seen_codes.add(payload["code"])
            picked.append(payload)
            if len(picked) >= per_query:
                break
        counts[query] = len(picked)
        selected.extend(picked)

    return scanned, counts, selected


def import_batch(products):
    if not SEED_KEY:
        raise RuntimeError("Set NUTRIEASY_SEED_ADMIN_KEY before importing products.")

    body = json.dumps({"products": products}).encode("utf-8")
    request = urllib.request.Request(
        IMPORT_URL,
        data=body,
        method="POST",
        headers={"Content-Type": "application/json", "x-seed-key": SEED_KEY},
    )
    with urllib.request.urlopen(request, timeout=240) as response:
        return json.loads(response.read().decode())


if __name__ == "__main__":
    started = time.time()
    scanned, counts, selected = collect_candidates()
    imports = []
    for index in range(0, len(selected), 450):
        imports.append(import_batch(selected[index:index + 450]))

    print(json.dumps({
        "scanned": scanned,
        "selected": len(selected),
        "query_count": len(QUERY_GROUPS),
        "counts": counts,
        "imports": imports,
        "seconds": round(time.time() - started, 1),
    }, ensure_ascii=False, indent=2))
