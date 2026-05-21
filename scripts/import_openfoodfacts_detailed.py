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
csv.field_size_limit(10_000_000)

QUERIES = [
    "egg",
    "chicken breast",
    "plain yogurt",
    "white rice",
    "oatmeal",
    "banana",
    "apple",
    "tomato",
    "cucumber",
    "feta cheese",
    "salmon",
    "milk",
]

TEXT_COLUMNS = [
    "code",
    "url",
    "product_name",
    "generic_name",
    "quantity",
    "brands",
    "categories",
    "categories_tags",
    "countries",
    "countries_tags",
    "ingredients_text",
    "ingredients_tags",
    "allergens",
    "allergens_en",
    "additives_tags",
    "nutriscore_score",
    "nutriscore_grade",
    "nova_group",
    "nutrient_levels_tags",
    "serving_size",
    "serving_quantity",
    "image_url",
    "image_small_url",
    "image_ingredients_url",
    "image_nutrition_url",
    "completeness",
]

NUTRIENT_COLUMNS = [
    "energy-kj_100g",
    "energy-kcal_100g",
    "fat_100g",
    "saturated-fat_100g",
    "trans-fat_100g",
    "cholesterol_100g",
    "carbohydrates_100g",
    "sugars_100g",
    "added-sugars_100g",
    "fiber_100g",
    "proteins_100g",
    "salt_100g",
    "sodium_100g",
    "alcohol_100g",
    "vitamin-a_100g",
    "vitamin-c_100g",
    "vitamin-d_100g",
    "vitamin-e_100g",
    "vitamin-b1_100g",
    "vitamin-b2_100g",
    "vitamin-b6_100g",
    "vitamin-b9_100g",
    "vitamin-b12_100g",
    "calcium_100g",
    "iron_100g",
    "magnesium_100g",
    "zinc_100g",
    "potassium_100g",
    "phosphorus_100g",
    "caffeine_100g",
]


def as_float(value):
    try:
        return float(value) if value not in ("", None) else 0.0
    except ValueError:
        return 0.0


def clean(value):
    return (value or "").strip()


def score_row(row, query):
    name = clean(row.get("product_name") or row.get("generic_name")).lower()
    if not name:
        return -1

    score = 0
    if name == query:
        score += 100
    if name.startswith(query):
        score += 50
    if query in name:
        score += 25
    if f" {query} " in f" {name} ":
        score += 20
    if clean(row.get("countries_tags")) and "en:united-states" in row.get("countries_tags", ""):
        score += 10
    if clean(row.get("image_url")) or clean(row.get("image_small_url")):
        score += 5
    if clean(row.get("brands")):
        score += 3
    if as_float(row.get("completeness")):
        score += min(as_float(row.get("completeness")) * 10, 10)

    # Penalize obvious prepared meals for generic terms.
    prepared_terms = ["sandwich", "wrap", "soup", "sauce", "cookie", "bar", "donut", "with"]
    if query in {"egg", "banana", "apple", "tomato", "cucumber", "salmon", "milk"}:
        score -= sum(15 for term in prepared_terms if term in name)

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


def select_products(per_query=10, max_scan=900_000):
    candidates = {query: [] for query in QUERIES}
    scanned = 0
    request = urllib.request.Request(DATA_URL, headers={"User-Agent": "NutriEasy/0.1 (contact@nutrieasy.app)"})

    with urllib.request.urlopen(request, timeout=60) as response:
        gz = gzip.GzipFile(fileobj=response)
        text = io.TextIOWrapper(gz, encoding="utf-8", errors="replace", newline="")
        reader = csv.DictReader(text, delimiter="\t")
        for row in reader:
            scanned += 1
            name = clean(row.get("product_name") or row.get("generic_name"))
            if not name or not row.get("code"):
                continue
            if (
                as_float(row.get("energy-kcal_100g")) == 0
                and as_float(row.get("proteins_100g")) == 0
                and as_float(row.get("carbohydrates_100g")) == 0
                and as_float(row.get("fat_100g")) == 0
            ):
                continue

            low_name = name.lower()
            for query in QUERIES:
                if query not in low_name:
                    continue
                scored = score_row(row, query)
                if scored <= 0:
                    continue
                candidates[query].append((scored, product_payload(row, query)))

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


def import_products(products):
    if not SEED_KEY:
        raise RuntimeError("Set NUTRIEASY_SEED_ADMIN_KEY before importing products.")

    body = json.dumps({"products": products}).encode("utf-8")
    request = urllib.request.Request(
        IMPORT_URL,
        data=body,
        method="POST",
        headers={"Content-Type": "application/json", "x-seed-key": SEED_KEY},
    )
    with urllib.request.urlopen(request, timeout=180) as response:
        return json.loads(response.read().decode())


if __name__ == "__main__":
    started = time.time()
    scanned, counts, products = select_products()
    result = import_products(products)
    print(json.dumps({
        "scanned": scanned,
        "selected": len(products),
        "counts": counts,
        "import": result,
        "seconds": round(time.time() - started, 1),
    }, ensure_ascii=False, indent=2))
