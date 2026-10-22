#!/usr/bin/env python3
"""Fixtures for the 2.5.0 release run (docs/release-tests/2.5.0/script.md).

Stdlib only. Run it on the laptop, never on the phone, with `python3 -I`:

    python3 -I make_fixtures.py OUT_DIR --today YYYY-MM-DD

`--today` is the phone's date on the day the run starts (`adb shell date +%F`).
Only the diary seed depends on it; everything else is fixed.

Writes into OUT_DIR:

  ont-seed-meals.csv     custom-meal library for 2.4.0's "Mahlzeiten importieren (csv)"
  ont-seed-recipes.json  two recipes for 2.4.0's "Rezepte importieren (json)"
  ont-seed-diary.json    six past days of diary for 2.4.0's "Mahlzeiten importieren (json)"
  ont-noid.zip           a CSV backup whose three intakes have no id (#1398)
  meal-codes.txt         shared meal codes A, B and an invalid one (#1329, #1294)
  expected.json          the numbers the script's steps compare against

Every name is ASCII, so `adb shell input text` can type it. Every file the
phone sees starts with `ont-`, the only prefix the run may pick in a file
picker.
"""
import argparse
import base64
import csv
import datetime as dt
import gzip
import io
import json
import os
import sys
import zipfile

# --- the custom-meal library (2.4.0 CSV meal importer) ------------------------
# Header from CsvMealImporter.orderedColumns at v2.4.0. Values per 100 g.
# ONT Riegel carries a barcode, so it is keyed by code; the other three have
# none and are keyed by name, the two identities #1404 and #1420 move.
MEALS_HEADER = [
    "name", "brands", "barcode", "kcal_per_100g", "carbs_per_100g",
    "fat_per_100g", "protein_per_100g", "sugars_per_100g",
    "saturated_fat_per_100g", "fiber_per_100g", "serving_size",
]
MEALS = [
    # name,            brands,     barcode,         kcal, c,   f,   p,  sug, sat, fib, serving
    ("ONT Haferbrei", "", "", 150, 25, 3, 5, 1, 0.5, 4, 250),
    ("ONT Linsensuppe", "", "", 90, 12, 2, 6, 1.5, 0.3, 4, 350),
    ("ONT Joghurt", "", "", 60, 4.5, 1.5, 7, 4, 1, 0, 200),
    ("ONT Riegel", "ONT Test", "2000000000015", 420, 55, 18, 8, 30, 6, 3, 40),
]
PER100 = {m[0]: {"kcal": m[3], "carbs": m[4], "fat": m[5], "protein": m[6]}
          for m in MEALS}

# --- recipes (2.4.0 JSON recipe importer) --------------------------------------
# ONT Bananenbrot has a hand-entered total (450 g against 500 g of
# ingredients), the case #1280 keeps on reopen.
RECIPES = [
    {
        "name": "ONT Gemuesecurry",
        "servings": 2,
        "ingredients": [
            {"name": "ONT Reis", "amount": 150, "unit": "g", "kcalPer100": 130,
             "carbsPer100": 28, "proteinPer100": 2.7, "fatPer100": 0.3},
            {"name": "ONT Gemuese", "amount": 200, "unit": "g", "kcalPer100": 40,
             "carbsPer100": 7, "proteinPer100": 2, "fatPer100": 0.5},
        ],
    },
    {
        "name": "ONT Bananenbrot",
        "totalWeight": 450,
        "ingredients": [
            {"name": "ONT Mehl", "amount": 200, "unit": "g", "kcalPer100": 360,
             "carbsPer100": 76, "proteinPer100": 10, "fatPer100": 1},
            {"name": "ONT Banane", "amount": 300, "unit": "g", "kcalPer100": 89,
             "carbsPer100": 23, "proteinPer100": 1, "fatPer100": 0.3},
        ],
    },
]

# --- diary seed (2.4.0 JSON meal importer) -------------------------------------
# (days before today, mealType, name, grams). The importer takes totals for
# the portion and files the entry at local midnight of `date`. Today itself
# is left to the UI steps, so the newest entries are the ones logged by hand.
DIARY = [
    (6, "breakfast", "ONT Haferbrei", 250),
    (6, "lunch", "ONT Linsensuppe", 350),
    (6, "dinner", "ONT Joghurt", 200),
    (5, "breakfast", "ONT Haferbrei", 200),
    (5, "dinner", "ONT Linsensuppe", 400),
    (4, "breakfast", "ONT Joghurt", 250),
    (4, "lunch", "ONT Linsensuppe", 350),
    (3, "breakfast", "ONT Haferbrei", 250),
    (3, "lunch", "ONT Linsensuppe", 300),
    (3, "dinner", "ONT Joghurt", 150),
    (2, "lunch", "ONT Linsensuppe", 350),
    (2, "snack", "ONT Joghurt", 200),
    (1, "breakfast", "ONT Haferbrei", 300),
    (1, "lunch", "ONT Linsensuppe", 350),
    (1, "dinner", "ONT Joghurt", 200),
]

# --- id-less CSV backup (#1398) ------------------------------------------------
# A fixed past day no earlier run on this phone wrote to. Two identical rows
# (both must survive) and one different row; no id on any of them.
NOID_DAY = "2026-08-15"
NOID_ROWS = [
    ("lunch", 100, "ONT Ohne ID", 200, 20, 10, 5, "12:00:00.000"),
    ("lunch", 100, "ONT Ohne ID", 200, 20, 10, 5, "12:00:00.000"),
    ("dinner", 150, "ONT Ohne ID B", 100, 10, 5, 4, "19:00:00.000"),
]

# --- shared meal codes (#1329, #1294) ------------------------------------------
# Layout from SharedMealPayload / SharedRecipePayload at c293acff4:
#   meal   [version=2, offRefs, items, recipes]
#   item   [name, brands, unit, amount, kcal100, carbs100, fat100, protein100,
#           sugars100, satFat100, fiber100, thumbUrl, imgUrl, source, code]
#   offRef [barcode, amount, unit]
#   recipe item [amount, unit, recipePayload]
#   recipe [version=1, name, description, servings, totalWeightG,
#           [kcal, c, f, p, sugars, satFat, fiber] per 100 g,
#           [ingredients], totalWeightOverridden (1|0)]
#   ingredient [name, brands, amount, unit, convertedG, kcal100, carbs100,
#               fat100, protein100, sugars100, satFat100, fiber100, thumbUrl]
CODE_A_PAYLOAD = [
    2,
    [],
    [
        ["ONT Code Haferbrei", None, "g", 250, 150, 25, 3, 5, 1, 0.5, 4,
         None, None, "custom", None],
        ["ONT Code Apfel", None, "g", 120, 52, 14, 0.2, 0.3, 10, None, 2.4,
         None, None, "custom", None],
    ],
    [
        # 100 g of ingredients cooked down to 80 g, flagged as hand-entered.
        [100, "g", [1, "ONT Code Eintopf", None, 1, 80,
                    [250, 25, 6.25, 12.5, None, None, None],
                    [["ONT Code Zutat", None, 100, "g", 100, 200, 20, 5, 10,
                      None, None, None, None]],
                    1]],
    ],
]
# A barcode with a valid check digit that Open Food Facts should not know.
UNKNOWN_BARCODE = "2999999999991"
CODE_B_PAYLOAD = [
    2,
    [[UNKNOWN_BARCODE, 50, "g"]],
    [["ONT Code Rest", None, "g", 100, 100, 10, 5, 2, None, None, None,
      None, None, "custom", None]],
    [],
]
CODE_INVALID = "keinGueltigerCode"


def encode_code(payload):
    """base64Url(gzip(utf8(json))), as SharedMealPayload.toJsonString."""
    raw = json.dumps(payload, separators=(",", ":"), ensure_ascii=True)
    packed = gzip.compress(raw.encode("utf-8"), mtime=0)
    return base64.urlsafe_b64encode(packed).decode("ascii")


def decode_code(code):
    return json.loads(gzip.decompress(base64.urlsafe_b64decode(code)))


def r1(x):
    return round(x + 0.0, 4)


def write_meals_csv(path):
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(MEALS_HEADER)
        for m in MEALS:
            w.writerow([("" if v == "" else v) for v in m])


def diary_entries(today):
    out = []
    for days_back, meal_type, name, grams in DIARY:
        p = PER100[name]
        f = grams / 100.0
        out.append({
            "name": name,
            "kcal": r1(p["kcal"] * f),
            "carbs": r1(p["carbs"] * f),
            "fat": r1(p["fat"] * f),
            "protein": r1(p["protein"] * f),
            "mealType": meal_type,
            "amount": grams,
            "unit": "g",
            "date": (today - dt.timedelta(days=days_back)).isoformat(),
        })
    return out


def write_noid_zip(path):
    intake_header = [
        "id", "date_time", "type", "amount", "unit", "meal_code", "meal_name",
        "meal_brands", "meal_source", "kcal_per_100g", "carbs_per_100g",
        "fat_per_100g", "protein_per_100g",
    ]
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(intake_header)
    for meal_type, grams, name, kcal, c, fat, p, clock in NOID_ROWS:
        w.writerow(["", f"{NOID_DAY}T{clock}", meal_type, grams, "g", "", name,
                    "", "custom", kcal, c, fat, p])
    activity_header = ("id,date,duration,burned_kcal,activity_code,"
                       "specific_activity,description,mets,tags,type\n")
    tracked_header = ("day,calorie_goal,calories_tracked,carbs_goal,"
                      "carbs_tracked,fat_goal,fat_tracked,protein_goal,"
                      "protein_tracked\n")
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("user_intake.csv", buf.getvalue())
        z.writestr("user_activity.csv", activity_header)
        z.writestr("user_tracked_day.csv", tracked_header)


def expected(today, diary):
    days = {}
    for e in diary:
        d = days.setdefault(e["date"], {"kcal": 0.0, "carbs": 0.0, "fat": 0.0,
                                        "protein": 0.0, "entries": 0})
        for k in ("kcal", "carbs", "fat", "protein"):
            d[k] = r1(d[k] + e[k])
        d["entries"] += 1

    def recipe_totals(r):
        kcal = sum(i["amount"] * i["kcalPer100"] / 100 for i in r["ingredients"])
        grams = sum(i["amount"] for i in r["ingredients"])
        total = r.get("totalWeight", grams)
        return {"kcal_total": r1(kcal), "ingredient_sum_g": grams,
                "total_weight_g": total, "kcal_per_100g": r1(kcal * 100 / total),
                "kcal_per_100g_if_override_lost": r1(kcal * 100 / grams)}

    noid_kcal = sum(g * k / 100 for _, g, _, k, *_ in NOID_ROWS)
    return {
        "today": today.isoformat(),
        "diary_days": days,
        "diary_entries": len(diary),
        "recipes": {r["name"]: recipe_totals(r) for r in RECIPES},
        "custom_meals": [m[0] for m in MEALS],
        "noid": {"day": NOID_DAY, "rows": len(NOID_ROWS),
                 "kcal_total": r1(noid_kcal)},
        "code_a": {
            "preview_title_de": "3 Einträge importieren?",
            "rows": [
                {"name": "ONT Code Haferbrei", "amount": "250 g", "kcal": 375},
                {"name": "ONT Code Apfel", "amount": "120 g", "kcal": 62},
                {"name": "ONT Code Eintopf", "amount": "100 g", "kcal": 250},
            ],
            "total_label": "Total", "total_kcal": 687,
            "logged_kcal_exact": 687.4,
            "recipe_total_weight_g": 80, "recipe_kcal_per_100g": 250,
            "recipe_kcal_if_override_lost": 200,
        },
        "code_b": {
            "preview_title_de": "2 Einträge importieren?",
            "unknown_barcode": UNKNOWN_BARCODE,
            "rows": [
                {"name": "ONT Code Rest", "amount": "100 g", "kcal": 100},
                {"name": UNKNOWN_BARCODE, "amount": "50 g", "kcal": None},
            ],
            "total_label": "Total (incomplete)", "total_kcal": 100,
        },
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out_dir")
    ap.add_argument("--today", required=True, help="phone date, YYYY-MM-DD")
    a = ap.parse_args()
    today = dt.date.fromisoformat(a.today)
    os.makedirs(a.out_dir, exist_ok=True)
    o = lambda name: os.path.join(a.out_dir, name)  # noqa: E731

    write_meals_csv(o("ont-seed-meals.csv"))
    with open(o("ont-seed-recipes.json"), "w", encoding="utf-8") as f:
        json.dump(RECIPES, f, ensure_ascii=True, indent=1)
    diary = diary_entries(today)
    with open(o("ont-seed-diary.json"), "w", encoding="utf-8") as f:
        json.dump(diary, f, ensure_ascii=True, indent=1)
    write_noid_zip(o("ont-noid.zip"))

    codes = {
        "CODE_A": encode_code(CODE_A_PAYLOAD),
        "CODE_B": encode_code(CODE_B_PAYLOAD),
        "CODE_INVALID": CODE_INVALID,
    }
    for name in ("CODE_A", "CODE_B"):
        assert decode_code(codes[name]) == json.loads(json.dumps(
            CODE_A_PAYLOAD if name == "CODE_A" else CODE_B_PAYLOAD))
        assert all(ch.isalnum() or ch in "-_=" for ch in codes[name])
    with open(o("meal-codes.txt"), "w", encoding="ascii") as f:
        for k, v in codes.items():
            f.write(f"{k}={v}\n")
    with open(o("expected.json"), "w", encoding="utf-8") as f:
        json.dump(expected(today, diary), f, ensure_ascii=False, indent=1)
    print("\n".join(sorted(os.listdir(a.out_dir))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
