# /// script
# requires-python = ">=3.10"
# ///
"""Builds the app's local FoodData Central asset from the official downloads.

Usage (from the repo root)::

    uv run tool/fdc/fdc_to_asset.py \
        path/to/FoodData_Central_foundation_food_json_2026-04-30.json \
        path/to/FoodData_Central_sr_legacy_food_json_2018-04.json \
        assets/fdc/fdc.json.gz

Reads the Foundation Foods and SR Legacy datasets of USDA FoodData Central
(public domain, CC0 1.0) and writes a gzip-compressed JSON file::

    {"version": 1, "source": "...", "license": "...",
     "fields": ["energyKcal100", ...],
     "foods": [[171688, "s", "Apples, raw, with skin", [52, ...]], ...]}

Each food row holds its FDC id, its dataset ("f" Foundation, "s" SR
Legacy), its English description (without the note on the USDA Food
Distribution Program, which says nothing about the food) and one value per entry of ``fields``,
per 100 g in the unit the app stores (see MAPPING); a nutrient FDC does
not give for that food is ``null``, never 0. Foods without an energy value
are left out.
"""

import gzip
import json
import sys
from pathlib import Path

ASSET_VERSION = 1
SOURCE = "USDA FoodData Central: Foundation Foods and SR Legacy"
LICENSE = "CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/"
PROGRAM_NOTE = " (Includes foods for USDA's Food Distribution Program)"

# App field -> FDC nutrient numbers in priority order. FDC already uses the
# app's units (g, mg, µg per 100 g). Foundation Foods often lack 208 and
# give Atwater energy, carbohydrate by summation and "Sugars, Total" instead.
MAPPING = [
    ("energyKcal100", ["208", "958", "957"]),
    ("carbohydrates100", ["205", "205.2"]),
    ("fat100", ["204"]),
    ("proteins100", ["203"]),
    ("sugars100", ["269", "269.3"]),
    ("saturatedFat100", ["606"]),
    ("fiber100", ["291"]),
    ("monounsaturatedFat100", ["645"]),
    ("polyunsaturatedFat100", ["646"]),
    ("transFat100", ["605"]),
    ("cholesterol100", ["601"]),
    ("sodium100", ["307"]),
    ("potassium100", ["306"]),
    ("magnesium100", ["304"]),
    ("calcium100", ["301"]),
    ("iron100", ["303"]),
    ("zinc100", ["309"]),
    ("phosphorus100", ["305"]),
    ("vitaminA100", ["320"]),
    ("vitaminC100", ["401"]),
    ("vitaminD100", ["328"]),
    ("vitaminB6100", ["415"]),
    ("vitaminB12100", ["418"]),
    ("niacin100", ["406"]),
    ("vitaminE100", ["323"]),
    ("vitaminK100", ["430"]),
    ("thiamin100", ["404"]),
    ("riboflavin100", ["405"]),
    ("pantothenicAcid100", ["410"]),
    ("biotin100", ["416"]),
    ("folate100", ["435", "417"]),
    ("iodine100", ["314"]),
    ("selenium100", ["317"]),
    ("copper100", ["312"]),
    ("manganese100", ["315"]),
]


def amounts_by_number(food):
    """The food's nutrient amounts keyed by FDC nutrient number."""
    amounts = {}
    for entry in food.get("foodNutrients") or []:
        number = ((entry or {}).get("nutrient") or {}).get("number")
        amount = (entry or {}).get("amount")
        if number is not None and isinstance(amount, (int, float)):
            amounts[str(number)] = float(amount)
    return amounts


def convert_food(food, dataset):
    """The asset row of one FDC food, or None when it has no energy value."""
    amounts = amounts_by_number(food)
    values = []
    for _, numbers in MAPPING:
        amount = next((amounts[n] for n in numbers if n in amounts), None)
        values.append(None if amount is None else round(amount, 6))
    if values[0] is None:
        return None
    name = food["description"].replace(PROGRAM_NOTE, "").strip()
    return [int(food["fdcId"]), dataset, name, values]


def convert_foods(foundation, sr_legacy):
    """The asset dict for the food lists of both datasets."""
    foods = []
    for dataset, items in (("f", foundation), ("s", sr_legacy)):
        for food in items:
            if not food:
                continue
            row = convert_food(food, dataset)
            if row is not None:
                foods.append(row)
    return {
        "version": ASSET_VERSION,
        "source": SOURCE,
        "license": LICENSE,
        "fields": [field for field, _ in MAPPING],
        "foods": foods,
    }


def main(foundation_path, sr_legacy_path, target):
    with open(foundation_path, encoding="utf-8") as f:
        foundation = json.load(f)["FoundationFoods"]
    with open(sr_legacy_path, encoding="utf-8") as f:
        sr_legacy = json.load(f)["SRLegacyFoods"]
    asset = convert_foods(foundation, sr_legacy)
    data = json.dumps(asset, ensure_ascii=False, separators=(",", ":"))
    Path(target).parent.mkdir(parents=True, exist_ok=True)
    with open(target, "wb") as raw, gzip.GzipFile(
        fileobj=raw, mode="wb", compresslevel=9, mtime=0
    ) as out:
        out.write(data.encode("utf-8"))
    print(f"{len(asset['foods'])} foods, {len(data) // 1024} KiB JSON -> {target}")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2], sys.argv[3])
