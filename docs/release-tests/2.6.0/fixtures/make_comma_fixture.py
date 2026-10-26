#!/usr/bin/env python3
"""The one phone fixture of the 2.6.0 run: a CSV backup with a comma decimal.

  python3 -I make_comma_fixture.py OUT_DIR --today YYYY-MM-DD

Writes OUT_DIR/ont-comma.zip, pushed as /sdcard/Download/ont-r26-comma.zip.

It holds one intake on day 0 - 2 whose meal_quantity is "137,0" (a quantity
stored from a decimal-comma locale) and whose meal_url is not a web address.
2.5.0's CSV import stores both as they are, and 2.5.0's MealItemCard then
throws a FormatException on the add-food Recent list. 2.6.0 (#1456)
normalises the quantity on import, parses stored commas leniently on display
and drops the bad URL. The script imports it on 2.5.0, so the record that
reaches the upgrade is the broken kind.
"""
import argparse
import csv
import datetime as dt
import io
import os
import zipfile

INTAKE_HEADER = [
    "id", "date_time", "type", "amount", "unit", "meal_code", "meal_name",
    "meal_brands", "meal_source", "meal_quantity", "meal_unit",
    "meal_serving_quantity", "meal_serving_unit", "meal_serving_size",
    "meal_thumbnail_url", "meal_main_image_url", "meal_url",
    "kcal_per_100g", "carbs_per_100g", "fat_per_100g", "protein_per_100g",
]
ROW = {
    "id": "ont-r26-comma-1",
    "type": "lunch",
    "amount": "137",
    "unit": "g",
    "meal_code": "ont-r26-comma",
    "meal_name": "ONT Komma",
    "meal_source": "custom",
    "meal_quantity": "137,0",
    "meal_unit": "g",
    "meal_url": "javascript:alert(1)",
    "kcal_per_100g": "200",
    "carbs_per_100g": "20",
    "fat_per_100g": "10",
    "protein_per_100g": "5",
}
DAYS_BACK = 2
CLOCK = "12:30:00.000"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--today", required=True)
    a = ap.parse_args()
    day = dt.date.fromisoformat(a.today) - dt.timedelta(days=DAYS_BACK)
    row = dict(ROW, date_time=f"{day.isoformat()}T{CLOCK}")

    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(INTAKE_HEADER)
    w.writerow([row.get(c, "") for c in INTAKE_HEADER])
    activity = ("id,date,duration,burned_kcal,activity_code,"
                "specific_activity,description,mets,tags,type\n")
    tracked = ("day,calorie_goal,calories_tracked,carbs_goal,carbs_tracked,"
               "fat_goal,fat_tracked,protein_goal,protein_tracked\n")

    def entry(name):  # a fixed timestamp, so a re-run writes the same bytes
        return zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))

    os.makedirs(a.out, exist_ok=True)
    path = os.path.join(a.out, "ont-comma.zip")
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr(entry("user_intake.csv"), buf.getvalue(), zipfile.ZIP_DEFLATED)
        z.writestr(entry("user_activity.csv"), activity, zipfile.ZIP_DEFLATED)
        z.writestr(entry("user_tracked_day.csv"), tracked, zipfile.ZIP_DEFLATED)
    print(f"{path}  day {day.isoformat()}  ONT Komma 137 g = 274 kcal")


if __name__ == "__main__":
    main()
