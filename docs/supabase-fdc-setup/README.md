# Supabase FDC Database Setup

This guide explains how to populate the `fdc_food`, `fdc_portions`, and
`fdc_nutrients` tables in your Supabase project using freely available
USDA FoodData Central (FDC) data.

## Prerequisites

- A Supabase project (Free tier is sufficient)
- `psql` installed locally **or** access to the Supabase SQL editor
- ~500 MB of free disk space for the downloaded data
- Python 3 (for the optional filter script) **or** any CSV tool

---

## Step 1 – Download the FDC data

Go to the official USDA FoodData Central download page:

```
https://fdc.nal.usda.gov/download-datasets
```

Download **"Full Download of All Data Types – CSV"** (latest release, ~460 MB zipped).

Unzip the archive. You will find many CSV files; you only need three:

| File | Description |
|---|---|
| `food.csv` | Food items with names |
| `food_portion.csv` | Serving size / portion data |
| `food_nutrient.csv` | Nutrient values per food |

---

## Step 2 – Filter to Foundation & SR Legacy only (recommended for Free tier)

The full dataset includes hundreds of thousands of branded products that
would exceed Supabase's 500 MB free limit. Filter `food.csv` to keep
only **Foundation** and **SR Legacy** rows (~9 000 items total).

### Option A – Python script

Save the following as `scripts/filter_fdc.py` and run it from the
directory that contains the unzipped CSV files:

```python
#!/usr/bin/env python3
"""
Filter FDC CSV exports to Foundation + SR Legacy data types only.
Run from the directory that contains the unzipped FDC CSV files.

Usage:
    python3 filter_fdc.py

Output files (written to ./filtered/):
    fdc_food_filtered.csv
    fdc_food_portion_filtered.csv
    fdc_food_nutrient_filtered.csv
"""

import csv
import os

KEEP_DATA_TYPES = {"Foundation", "SR Legacy"}
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
    filter_related(
        "food_portion.csv",
        f"{OUT_DIR}/fdc_food_portion_filtered.csv",
        kept,
    )
    filter_related(
        "food_nutrient.csv",
        f"{OUT_DIR}/fdc_food_nutrient_filtered.csv",
        kept,
    )
    print("Done. Import the files from the ./filtered/ directory.")
```

Run it:

```bash
cd /path/to/unzipped-fdc-data
python3 /path/to/repo/scripts/filter_fdc.py
```

### Option B – Manual filter in any spreadsheet tool

Open `food.csv`, filter the `data_type` column to keep only rows where
the value is `Foundation` or `SR Legacy`, and delete everything else.
Repeat for the other two files using the remaining `fdc_id` values.

---

## Step 3 – Create the tables in Supabase

Open the **Supabase SQL Editor** (or connect via `psql`) and run:

```sql
-- ============================================================
-- fdc_food
-- ============================================================
CREATE TABLE IF NOT EXISTS fdc_food (
    fdc_id          INTEGER PRIMARY KEY,
    description_en  TEXT NOT NULL,
    description_de  TEXT          -- optional: add translated names later
);

-- Full-text search index (used by the app)
CREATE INDEX IF NOT EXISTS fdc_food_fts_en
    ON fdc_food
    USING GIN (to_tsvector('english', description_en));

CREATE INDEX IF NOT EXISTS fdc_food_fts_de
    ON fdc_food
    USING GIN (to_tsvector('german', COALESCE(description_de, description_en)));

-- ============================================================
-- fdc_portions
-- ============================================================
CREATE TABLE IF NOT EXISTS fdc_portions (
    id              SERIAL PRIMARY KEY,
    fdc_id          INTEGER NOT NULL REFERENCES fdc_food(fdc_id) ON DELETE CASCADE,
    measure_unit_id INTEGER,
    amount          NUMERIC,
    gram_weight     NUMERIC
);

CREATE INDEX IF NOT EXISTS fdc_portions_fdc_id_idx ON fdc_portions (fdc_id);

-- ============================================================
-- fdc_nutrients
-- ============================================================
CREATE TABLE IF NOT EXISTS fdc_nutrients (
    id          SERIAL PRIMARY KEY,
    fdc_id      INTEGER NOT NULL REFERENCES fdc_food(fdc_id) ON DELETE CASCADE,
    nutrient_id INTEGER NOT NULL,
    amount      NUMERIC
);

CREATE INDEX IF NOT EXISTS fdc_nutrients_fdc_id_idx ON fdc_nutrients (fdc_id);
```

---

## Step 4 – Import the CSV data

### Via Supabase SQL Editor (easiest)

Use the **Table Editor → Import CSV** button for each table, selecting
the filtered files from `Step 2`:

| Table | File |
|---|---|
| `fdc_food` | `fdc_food_filtered.csv` – map `fdc_id` → `fdc_id`, `description` → `description_en` |
| `fdc_portions` | `fdc_food_portion_filtered.csv` – map `fdc_id`, `measure_unit_id`, `amount`, `gram_weight` |
| `fdc_nutrients` | `fdc_food_nutrient_filtered.csv` – map `fdc_id`, `nutrient_id`, `amount` |

> **Note:** `description_de` can be left empty for now. The app falls
> back to `description_en` when `description_de` is `NULL`.

### Via psql (alternative)

```bash
# Connect to your Supabase Postgres instance
# (find the connection string in Supabase → Settings → Database)
psql "postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres"

\COPY fdc_food (fdc_id, description_en)
  FROM 'filtered/fdc_food_filtered.csv'
  CSV HEADER;

\COPY fdc_portions (fdc_id, measure_unit_id, amount, gram_weight)
  FROM 'filtered/fdc_food_portion_filtered.csv'
  CSV HEADER;

\COPY fdc_nutrients (fdc_id, nutrient_id, amount)
  FROM 'filtered/fdc_food_nutrient_filtered.csv'
  CSV HEADER;
```

---

## Step 5 – Verify

Run this in the Supabase SQL Editor to confirm data was loaded:

```sql
SELECT
    (SELECT COUNT(*) FROM fdc_food)      AS foods,
    (SELECT COUNT(*) FROM fdc_portions)  AS portions,
    (SELECT COUNT(*) FROM fdc_nutrients) AS nutrients;
```

Expected output (Foundation + SR Legacy):

| foods | portions | nutrients |
|---|---|---|
| ~9 000 | ~30 000 | ~650 000 |

Test the full-text search the app uses:

```sql
SELECT fdc_id, description_en
FROM fdc_food
WHERE to_tsvector('english', description_en)
      @@ websearch_to_tsquery('english', 'chicken breast')
LIMIT 5;
```

---

## Notes

- **Branded foods / barcodes:** The FDC Branded dataset contains
  `gtin_upc` barcode values but is ~3 GB and exceeds the Supabase Free
  tier limit. For barcode lookup, consider using the
  [Open Food Facts](https://world.openfoodfacts.org/data) dataset as a
  complement.
- **German translations:** `description_de` is not provided by FDC.
  You can populate it later via the FDC API
  (`https://api.nal.usda.gov/fdc/v1/food/{fdc_id}`) or a translation
  service.
- **Updating data:** FDC releases updates twice a year. Re-run
  `filter_fdc.py` and re-import to refresh.

---

## File structure added by this guide

```
docs/
  supabase-fdc/
    README.md          ← this file
scripts/
  filter_fdc.py        ← CSV filter script
```