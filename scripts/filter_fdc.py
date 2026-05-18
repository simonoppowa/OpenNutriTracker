#!/usr/bin/env python3
"""
Filter FDC CSV exports to Foundation + SR Legacy data types only.
Run from the directory that contains the unzipped FDC CSV files.

Usage:
    python3 /path/to/filter_fdc.py

Output files (written to ./filtered/):
    fdc_food_filtered.csv
    fdc_food_portion_filtered.csv
    fdc_food_nutrient_filtered.csv
"""

import csv
import os

KEEP_DATA_TYPES = {"foundation_food", "sr_legacy_food"}
OUT_DIR = "filtered"
os.makedirs(OUT_DIR, exist_ok=True)


def filter_food(src="food.csv", dst=f"{OUT_DIR}/fdc_food_filtered.csv"):
    kept_ids = set()
    with open(src, newline="", encoding="utf-8") as f_in, \
         open(dst, "w", newline="", encoding="utf-8") as f_out:
        reader = csv.DictReader(f_in)
        writer = csv.DictWriter(f_out, fieldnames=reader.fieldnames)
        writer.writeheader()
        for row in reader:
            if row.get("data_type") in KEEP_DATA_TYPES:
                writer.writerow(row)
                kept_ids.add(row["fdc_id"])
    print(f"food.csv: kept {len(kept_ids)} rows → {dst}")
    return kept_ids


def filter_related(src, dst, kept_ids, id_col="fdc_id"):
    count = 0
    with open(src, newline="", encoding="utf-8") as f_in, \
         open(dst, "w", newline="", encoding="utf-8") as f_out:
        reader = csv.DictReader(f_in)
        writer = csv.DictWriter(f_out, fieldnames=reader.fieldnames)
        writer.writeheader()
        for row in reader:
            if row.get(id_col) in kept_ids:
                writer.writerow(row)
                count += 1
    print(f"{src}: kept {count} rows → {dst}")


if __name__ == "__main__":
    kept = filter_food()
    filter_related("food_portion.csv", f"{OUT_DIR}/fdc_food_portion_filtered.csv", kept)
    filter_related("food_nutrient.csv", f"{OUT_DIR}/fdc_food_nutrient_filtered.csv", kept)
    print("Done. Import the files from the ./filtered/ directory.")
