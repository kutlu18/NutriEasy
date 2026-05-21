import csv
import gzip
import io
import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path

DATA_URL = "https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz"
IMPORT_URL = "https://ifjghwsdpujzopppurdr.supabase.co/functions/v1/import-openfoodfacts-products"
SEED_KEY = os.environ.get("NUTRIEASY_SEED_ADMIN_KEY")
BATCH_SIZE = int(os.environ.get("NUTRIEASY_BATCH_SIZE", "1000"))
MAX_SCAN = int(os.environ.get("NUTRIEASY_MAX_SCAN", "0"))
MAX_IMPORT = int(os.environ.get("NUTRIEASY_MAX_IMPORT", "0"))
STATE_PATH = Path(os.environ.get("NUTRIEASY_STATE_PATH", "data/openfoodfacts_full_import_state.json"))
FAILED_PATH = Path(os.environ.get("NUTRIEASY_FAILED_PATH", "data/openfoodfacts_failed_products.jsonl"))

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
    "trans-fat_100g", "monounsaturated-fat_100g", "polyunsaturated-fat_100g",
    "omega-3-fat_100g", "omega-6-fat_100g", "cholesterol_100g",
    "carbohydrates_100g", "sugars_100g", "added-sugars_100g", "sucrose_100g",
    "glucose_100g", "fructose_100g", "lactose_100g", "fiber_100g", "proteins_100g",
    "casein_100g", "salt_100g", "sodium_100g", "alcohol_100g", "vitamin-a_100g",
    "vitamin-c_100g", "vitamin-d_100g", "vitamin-e_100g", "vitamin-k_100g",
    "vitamin-b1_100g", "vitamin-b2_100g", "vitamin-pp_100g", "vitamin-b6_100g",
    "vitamin-b9_100g", "folates_100g", "vitamin-b12_100g", "biotin_100g",
    "pantothenic-acid_100g", "calcium_100g", "chloride_100g", "copper_100g",
    "iron_100g", "magnesium_100g", "manganese_100g", "phosphorus_100g",
    "potassium_100g", "selenium_100g", "zinc_100g", "iodine_100g", "caffeine_100g",
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

    number = as_float(value)
    if number < 0:
        number = 0.0

    max_value = 1000.0
    if column == "energy-kj_100g":
        max_value = 100000.0
    elif column == "energy-kcal_100g":
        max_value = 10000.0
    elif column in {"vitamin-b12_100g", "biotin_100g"}:
        max_value = 10.0
    elif column.startswith("vitamin-") or column in {"calcium_100g", "iron_100g", "magnesium_100g", "zinc_100g", "potassium_100g", "phosphorus_100g", "iodine_100g", "selenium_100g"}:
        max_value = 100.0

    if number > max_value:
        number = max_value
    return f"{number:.10g}"


def has_nutrition(row):
    return any(
        as_float(row.get(column)) != 0
        for column in ["energy-kcal_100g", "proteins_100g", "carbohydrates_100g", "fat_100g"]
    )


def product_payload(row):
    payload = {column: clean(row.get(column, "")) for column in TEXT_COLUMNS}
    payload["serving_quantity"] = safe_number_text("serving_quantity", row.get("serving_quantity", ""))
    payload.update({column: safe_number_text(column, row.get(column, "")) for column in NUTRIENT_COLUMNS})
    payload["nutrients_100g"] = {
        column: as_float(row.get(column))
        for column in NUTRIENT_COLUMNS
        if clean(row.get(column, "")) != ""
    }
    return payload


def load_state():
    if not STATE_PATH.exists():
        return {
            "scanned": 0,
            "last_flushed_scanned": 0,
            "valid": 0,
            "imported": 0,
            "skipped_existing": 0,
            "failed": 0,
            "batches": 0,
            "started_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        }

    return json.loads(STATE_PATH.read_text(encoding="utf-8"))


def save_state(state):
    STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    state["updated_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    STATE_PATH.write_text(json.dumps(state, indent=2, sort_keys=True), encoding="utf-8")


def combine_results(left, right):
    return {
        "insertedFoodCount": int(left.get("insertedFoodCount", 0)) + int(right.get("insertedFoodCount", 0)),
        "insertedServingCount": int(left.get("insertedServingCount", 0)) + int(right.get("insertedServingCount", 0)),
        "skippedExistingCount": int(left.get("skippedExistingCount", 0)) + int(right.get("skippedExistingCount", 0)),
        "failedCount": int(left.get("failedCount", 0)) + int(right.get("failedCount", 0)),
        "queryGroups": int(left.get("queryGroups", 0)) + int(right.get("queryGroups", 0)),
    }


def log_failed_product(product, error):
    FAILED_PATH.parent.mkdir(parents=True, exist_ok=True)
    with FAILED_PATH.open("a", encoding="utf-8") as output:
        output.write(json.dumps({
            "code": product.get("code"),
            "product_name": product.get("product_name"),
            "error": str(error),
        }, ensure_ascii=False) + "\n")


def post_batch(products):
    if not SEED_KEY:
        raise RuntimeError("Set NUTRIEASY_SEED_ADMIN_KEY before importing products.")

    body = json.dumps({
        "products": products,
        "skipExisting": True,
        "updateCache": False,
    }).encode("utf-8")

    request = urllib.request.Request(
        IMPORT_URL,
        data=body,
        method="POST",
        headers={"Content-Type": "application/json", "x-seed-key": SEED_KEY},
    )

    for attempt in range(1, 4):
        try:
            with urllib.request.urlopen(request, timeout=240) as response:
                return json.loads(response.read().decode())
        except urllib.error.HTTPError as error:
            if error.code >= 500 and len(products) > 1:
                midpoint = len(products) // 2
                left = post_batch(products[:midpoint])
                right = post_batch(products[midpoint:])
                return combine_results(left, right)

            if len(products) == 1:
                log_failed_product(products[0], error)
                return {
                    "insertedFoodCount": 0,
                    "insertedServingCount": 0,
                    "skippedExistingCount": 0,
                    "failedCount": 1,
                    "queryGroups": 0,
                }

            if attempt == 3:
                raise
            time.sleep(attempt * 5)
            print(f"retrying batch after http error: {error}", flush=True)
        except (urllib.error.URLError, TimeoutError) as error:
            if attempt == 3:
                raise
            time.sleep(attempt * 5)
            print(f"retrying batch after error: {error}", flush=True)

    raise RuntimeError("unreachable import retry state")


def flush_batch(batch, state, started):
    if not batch:
        return

    result = post_batch(batch)
    state["imported"] += int(result.get("insertedFoodCount", 0))
    state["skipped_existing"] += int(result.get("skippedExistingCount", 0))
    state["failed"] = int(state.get("failed", 0)) + int(result.get("failedCount", 0))
    state["batches"] += 1
    state["last_flushed_scanned"] = state["scanned"]
    state["resume_after_scanned"] = state["last_flushed_scanned"]
    save_state(state)

    elapsed = max(time.time() - started, 1)
    rate = state["scanned"] / elapsed
    print(json.dumps({
        "batch": state["batches"],
        "scanned": state["scanned"],
        "valid": state["valid"],
        "imported": state["imported"],
        "skipped_existing": state["skipped_existing"],
        "last_batch": result,
        "rows_per_second": round(rate, 1),
    }, ensure_ascii=False), flush=True)


def stream_products():
    request = urllib.request.Request(DATA_URL, headers={"User-Agent": "NutriEasy/0.1 (contact@nutrieasy.app)"})
    with urllib.request.urlopen(request, timeout=120) as response:
        gz = gzip.GzipFile(fileobj=response)
        text = io.TextIOWrapper(gz, encoding="utf-8", errors="replace", newline="")
        yield from csv.DictReader(text, delimiter="\t")


def main():
    state = load_state()
    started = time.time()
    batch = []
    resume_after = int(state.get("resume_after_scanned", state.get("scanned", 0)))

    try:
        for row_number, row in enumerate(stream_products(), start=1):
            if row_number <= resume_after:
                continue

            state["scanned"] = row_number

            if MAX_SCAN and state["scanned"] > MAX_SCAN:
                break

            name = clean(row.get("product_name") or row.get("generic_name"))
            if not row.get("code") or not name or not has_nutrition(row):
                continue

            batch.append(product_payload(row))
            state["valid"] += 1

            if len(batch) >= BATCH_SIZE:
                flush_batch(batch, state, started)
                batch = []

            if MAX_IMPORT and state["imported"] >= MAX_IMPORT:
                break

        flush_batch(batch, state, started)
        state["completed"] = MAX_SCAN == 0 and MAX_IMPORT == 0
        state["last_flushed_scanned"] = state["scanned"]
        state["resume_after_scanned"] = state["last_flushed_scanned"]
        save_state(state)
        print(json.dumps({"done": True, **state}, ensure_ascii=False, indent=2), flush=True)
    except KeyboardInterrupt:
        state["resume_after_scanned"] = int(state.get("last_flushed_scanned", 0))
        save_state(state)
        raise
    except Exception:
        state["resume_after_scanned"] = int(state.get("last_flushed_scanned", 0))
        save_state(state)
        raise


if __name__ == "__main__":
    main()
