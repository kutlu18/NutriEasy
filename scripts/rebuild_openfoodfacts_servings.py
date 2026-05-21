import csv
import gzip
import io
import json
import os
import time
import urllib.parse
import urllib.request
from pathlib import Path

DATA_URL = "https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz"
PROJECT_URL = "https://ifjghwsdpujzopppurdr.supabase.co"
IMPORT_URL = f"{PROJECT_URL}/functions/v1/import-openfoodfacts-products"
PUBLISHABLE_KEY = os.environ.get("NUTRIEASY_SUPABASE_PUBLISHABLE_KEY")
SEED_KEY = os.environ.get("NUTRIEASY_SEED_ADMIN_KEY")
BATCH_SIZE = int(os.environ.get("NUTRIEASY_BATCH_SIZE", "1000"))
STATE_PATH = Path(os.environ.get("NUTRIEASY_REBUILD_STATE_PATH", "data/openfoodfacts_rebuild_servings_state.json"))

csv.field_size_limit(10_000_000)

TEXT_COLUMNS = [
    "code", "url", "product_name", "generic_name", "quantity", "brands", "categories",
    "categories_tags", "countries", "countries_tags", "ingredients_text", "ingredients_tags",
    "allergens", "allergens_en", "additives_tags", "nutriscore_score", "nutriscore_grade",
    "nova_group", "nutrient_levels_tags", "serving_size", "serving_quantity", "image_url",
    "image_small_url", "image_front_url", "image_ingredients_url", "image_nutrition_url",
    "completeness", "labels", "labels_tags", "traces", "traces_tags", "origins",
    "origins_tags", "manufacturing_places", "stores", "creator", "created_t",
    "last_modified_t", "ecoscore_score", "ecoscore_grade", "food_groups",
    "food_groups_tags", "pnns_groups_1", "pnns_groups_2",
]

NUTRIENT_COLUMNS = [
    "energy-kj_100g", "energy-kcal_100g", "fat_100g", "saturated-fat_100g",
    "trans-fat_100g", "cholesterol_100g", "carbohydrates_100g", "sugars_100g",
    "added-sugars_100g", "fiber_100g", "proteins_100g", "salt_100g", "sodium_100g",
    "alcohol_100g", "vitamin-a_100g", "vitamin-c_100g", "vitamin-d_100g",
    "vitamin-e_100g", "vitamin-b1_100g", "vitamin-b2_100g", "vitamin-b6_100g",
    "vitamin-b9_100g", "vitamin-b12_100g", "calcium_100g", "iron_100g",
    "magnesium_100g", "zinc_100g", "potassium_100g", "phosphorus_100g", "caffeine_100g",
]


def clean(value):
    return (value or "").strip()


def as_float(value):
    try:
        return float(value) if value not in ("", None) else 0.0
    except ValueError:
        return 0.0


def safe_number_text(column, value):
    if clean(value) == "":
        return ""

    number = max(as_float(value), 0.0)
    max_value = 1000.0
    if column == "energy-kj_100g":
        max_value = 100000.0
    elif column == "energy-kcal_100g":
        max_value = 10000.0
    elif column == "vitamin-b12_100g":
        max_value = 10.0
    elif column.startswith("vitamin-") or column in {
        "calcium_100g", "iron_100g", "magnesium_100g", "zinc_100g",
        "potassium_100g", "phosphorus_100g",
    }:
        max_value = 100.0

    return f"{min(number, max_value):.10g}"


def has_nutrition(row):
    return any(as_float(row.get(column)) != 0 for column in [
        "energy-kcal_100g", "proteins_100g", "carbohydrates_100g", "fat_100g",
    ])


def product_payload(row):
    payload = {column: clean(row.get(column, "")) for column in TEXT_COLUMNS}
    payload["serving_quantity"] = safe_number_text("serving_quantity", row.get("serving_quantity", ""))
    payload.update({column: safe_number_text(column, row.get(column, "")) for column in NUTRIENT_COLUMNS})
    payload["nutrients_100g"] = {
        column: as_float(payload[column])
        for column in NUTRIENT_COLUMNS
        if payload[column] != ""
    }
    return payload


def api_headers():
    if not PUBLISHABLE_KEY:
        raise RuntimeError("Set NUTRIEASY_SUPABASE_PUBLISHABLE_KEY.")

    return {
        "apikey": PUBLISHABLE_KEY,
        "Authorization": f"Bearer {PUBLISHABLE_KEY}",
    }


def fetch_codes():
    codes = set()
    offset = 0
    page_size = 10000
    encoded_source = urllib.parse.quote("eq.openfoodfacts")

    while True:
        url = f"{PROJECT_URL}/rest/v1/foods?select=source_food_id&source={encoded_source}&source_food_id=not.is.null&offset={offset}&limit={page_size}"
        request = urllib.request.Request(url, headers=api_headers())
        with urllib.request.urlopen(request, timeout=120) as response:
            rows = json.loads(response.read().decode())

        if not rows:
            break

        codes.update(row["source_food_id"] for row in rows if row.get("source_food_id"))
        offset += len(rows)
        print(json.dumps({"fetched_codes": len(codes)}, ensure_ascii=False), flush=True)

        if len(rows) < page_size:
            break

    return codes


def load_state():
    if STATE_PATH.exists():
        state = json.loads(STATE_PATH.read_text(encoding="utf-8"))
        return set(state["remaining_codes"]), state

    codes = fetch_codes()
    state = {
        "remaining_codes": sorted(codes),
        "rebuilt": 0,
        "scanned": 0,
        "started_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    }
    save_state(state)
    return codes, state


def save_state(state):
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    state["updated_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    STATE_PATH.write_text(json.dumps(state, indent=2, sort_keys=True), encoding="utf-8")


def import_batch(products):
    if not SEED_KEY:
        raise RuntimeError("Set NUTRIEASY_SEED_ADMIN_KEY.")

    body = json.dumps({
        "products": products,
        "skipExisting": False,
        "updateCache": False,
    }).encode("utf-8")
    request = urllib.request.Request(
        IMPORT_URL,
        data=body,
        method="POST",
        headers={"Content-Type": "application/json", "x-seed-key": SEED_KEY},
    )
    with urllib.request.urlopen(request, timeout=240) as response:
        return json.loads(response.read().decode())


def stream_rows():
    request = urllib.request.Request(DATA_URL, headers={"User-Agent": "NutriEasy/0.1 (contact@nutrieasy.app)"})
    with urllib.request.urlopen(request, timeout=120) as response:
        gz = gzip.GzipFile(fileobj=response)
        text = io.TextIOWrapper(gz, encoding="utf-8", errors="replace", newline="")
        yield from csv.DictReader(text, delimiter="\t")


def main():
    remaining, state = load_state()
    batch = []

    for row_number, row in enumerate(stream_rows(), start=1):
        state["scanned"] = row_number
        code = row.get("code")
        if code not in remaining or not has_nutrition(row):
            continue

        batch.append(product_payload(row))
        remaining.remove(code)

        if len(batch) >= BATCH_SIZE:
            result = import_batch(batch)
            state["rebuilt"] += int(result.get("insertedServingCount", 0))
            state["remaining_codes"] = sorted(remaining)
            save_state(state)
            print(json.dumps({"rebuilt": state["rebuilt"], "remaining": len(remaining), "last": result}, ensure_ascii=False), flush=True)
            batch = []

        if not remaining:
            break

    if batch:
        result = import_batch(batch)
        state["rebuilt"] += int(result.get("insertedServingCount", 0))

    state["remaining_codes"] = sorted(remaining)
    state["completed"] = len(remaining) == 0
    save_state(state)
    print(json.dumps({"done": True, "rebuilt": state["rebuilt"], "remaining": len(remaining)}, ensure_ascii=False, indent=2), flush=True)


if __name__ == "__main__":
    main()
