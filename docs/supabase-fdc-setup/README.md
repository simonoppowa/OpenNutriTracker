# Supabase FDC Database Setup

This guide explains how to populate the `fdc_food`, `fdc_portions`, and
`fdc_nutrients` tables in your Supabase project using freely available
USDA FoodData Central (FDC) data — including optional German translations
via Google Translate.

## Prerequisites

- A Supabase project (Free tier is sufficient)
- Access to the Supabase SQL editor
- ~500 MB of free disk space for the downloaded data
- Python 3 with `deep-translator` (`pip install deep-translator`)

---

## Quickstart – use pre-built CSV files

If you want to skip Steps 1–4, pre-built CSV files (Foundation & SR Legacy,
snapshot 2026-04-30, with German translations) are available at:

[h4rib0/OpenNutriTracker – data/supabase-fdc/](https://github.com/h4rib0/OpenNutriTracker/tree/docs/supabase-fdc-setup-scripts/data/supabase-fdc)

| File | Rows |
|---|---|
| `fdc_food_20260430_de.csv` | ~8 200 |
| `fdc_portions_20260430.csv` | ~14 600 |
| `fdc_nutrients_20260430.csv` | ~665 000 |

Download the files and jump straight to **Step 5**.
Use them as-is for the `fdc_food` and `fdc_portions` import in Step 6
(set `base` to the folder containing the downloaded files and use the
filenames above instead of `fdc_food.csv` / `fdc_portions.csv`).
For `fdc_nutrients`, import `fdc_nutrients_20260430.csv` via the
Supabase Table Editor CSV import.

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
only **Foundation** and **SR Legacy** rows (~8 000–9 000 items total).

Run the script from the directory containing the unzipped CSV files:

```bash
cd /path/to/unzipped-fdc-data
python3 /path/to/repo/scripts/filter_fdc.py
```

Output files are written to `./filtered/`:

| File | Rows |
|---|---|
| `filtered/fdc_food_filtered.csv` | ~8 200 |
| `filtered/fdc_food_portion_filtered.csv` | ~14 000 |
| `filtered/fdc_food_nutrient_filtered.csv` | ~665 000 |

---

## Step 3 – Translate food names to German (optional but recommended)

The FDC data only contains English names. The app shows German names when
the device locale is German. To populate `description_de`, run the
translation script using Google Translate (no API key required):

```bash
pip install deep-translator

python3 /path/to/repo/scripts/translate_fdc_de.py \
    --input  filtered/fdc_food_filtered.csv \
    --output filtered/fdc_food_translated.csv
```

The script translates ~8 200 names in batches. Progress is saved after
each batch — if interrupted, re-run the same command to continue where
it left off.

**Note:** Translation takes approximately 20–30 minutes. Google Translate
may rate-limit after ~6 000 requests; the script will pause and resume
automatically on re-run.

---

## Step 4 – Prepare import CSVs

The filtered CSVs have different column names than the Supabase tables.
Run the following Python snippet to create import-ready files in
`filtered/import/`:

```python
import csv, os

base = '/path/to/unzipped-fdc-data/filtered'
out  = f'{base}/import'
os.makedirs(out, exist_ok=True)

def esc(s): return s.replace("'", "''") if s else ''
def to_num(s): return float(s) if s and s.strip() else None
def to_int(s): return int(s) if s and s.strip() else None

# fdc_food
with open(f'{base}/fdc_food_translated.csv', newline='', encoding='utf-8') as f_in, \
     open(f'{out}/fdc_food.csv', 'w', newline='', encoding='utf-8') as f_out:
    reader = csv.DictReader(f_in)
    writer = csv.DictWriter(f_out, fieldnames=['fdc_id','description_en','description_de'])
    writer.writeheader()
    for r in reader:
        writer.writerow({'fdc_id': r['fdc_id'], 'description_en': r['description'], 'description_de': r['description_de']})

# fdc_portions
with open(f'{base}/fdc_food_portion_filtered.csv', newline='', encoding='utf-8') as f_in, \
     open(f'{out}/fdc_portions.csv', 'w', newline='', encoding='utf-8') as f_out:
    reader = csv.DictReader(f_in)
    writer = csv.DictWriter(f_out, fieldnames=['fdc_id','measure_unit_id','amount','gram_weight'])
    writer.writeheader()
    for r in reader:
        writer.writerow({'fdc_id': r['fdc_id'], 'measure_unit_id': r['measure_unit_id'] or None,
                         'amount': r['amount'] or None, 'gram_weight': r['gram_weight'] or None})

# fdc_nutrients (only rows with a value)
with open(f'{base}/fdc_food_nutrient_filtered.csv', newline='', encoding='utf-8') as f_in, \
     open(f'{out}/fdc_nutrients.csv', 'w', newline='', encoding='utf-8') as f_out:
    reader = csv.DictReader(f_in)
    writer = csv.DictWriter(f_out, fieldnames=['fdc_id','nutrient_id','amount'])
    writer.writeheader()
    for r in reader:
        if r['amount']:
            writer.writerow({'fdc_id': r['fdc_id'], 'nutrient_id': r['nutrient_id'], 'amount': r['amount']})
```

---

## Step 5 – Create the tables in Supabase

Open the **Supabase SQL Editor** and run:

```sql
-- fdc_food
CREATE TABLE IF NOT EXISTS fdc_food (
    fdc_id          INTEGER PRIMARY KEY,
    description_en  TEXT NOT NULL,
    description_de  TEXT
);

CREATE INDEX IF NOT EXISTS fdc_food_fts_en
    ON fdc_food USING GIN (to_tsvector('english', description_en));

CREATE INDEX IF NOT EXISTS fdc_food_fts_de
    ON fdc_food USING GIN (to_tsvector('german', COALESCE(description_de, description_en)));

-- fdc_portions
CREATE TABLE IF NOT EXISTS fdc_portions (
    id              SERIAL PRIMARY KEY,
    fdc_id          INTEGER NOT NULL REFERENCES fdc_food(fdc_id) ON DELETE CASCADE,
    measure_unit_id INTEGER,
    amount          NUMERIC,
    gram_weight     NUMERIC
);

CREATE INDEX IF NOT EXISTS fdc_portions_fdc_id_idx ON fdc_portions (fdc_id);

-- fdc_nutrients
CREATE TABLE IF NOT EXISTS fdc_nutrients (
    id          SERIAL PRIMARY KEY,
    fdc_id      INTEGER NOT NULL REFERENCES fdc_food(fdc_id) ON DELETE CASCADE,
    nutrient_id INTEGER NOT NULL,
    amount      NUMERIC
);

CREATE INDEX IF NOT EXISTS fdc_nutrients_fdc_id_idx ON fdc_nutrients (fdc_id);

-- Disable RLS so the import script can write without policies
ALTER TABLE fdc_food     DISABLE ROW LEVEL SECURITY;
ALTER TABLE fdc_portions DISABLE ROW LEVEL SECURITY;
ALTER TABLE fdc_nutrients DISABLE ROW LEVEL SECURITY;
```

---

## Step 6 – Import the data via Python

Use the Supabase Python client to import `fdc_food` and `fdc_portions`.
For `fdc_nutrients` (665 000 rows) use the Supabase **Table Editor →
Import CSV** button instead.

```bash
pip install supabase
```

```python
import csv, time
from supabase import create_client

url = "https://<your-project-ref>.supabase.co"
key = "<your-anon-key>"
sb  = create_client(url, key)

base  = '/path/to/filtered/import'
CHUNK = 200

def import_table(table, csv_file, row_fn):
    with open(f'{base}/{csv_file}', newline='', encoding='utf-8') as f:
        rows = list(csv.DictReader(f))
    total = len(rows)
    for i in range(0, total, CHUNK):
        batch = [row_fn(r) for r in rows[i:i+CHUNK]]
        sb.table(table).upsert(batch).execute()
        print(f'{table}: {min(i+CHUNK, total)}/{total}')
        time.sleep(0.2)

import_table('fdc_food', 'fdc_food.csv',
    lambda r: {'fdc_id': int(r['fdc_id']),
               'description_en': r['description_en'],
               'description_de': r['description_de'] or None})

import_table('fdc_portions', 'fdc_portions.csv',
    lambda r: {'fdc_id': int(r['fdc_id']),
               'measure_unit_id': int(r['measure_unit_id']) if r['measure_unit_id'] else None,
               'amount': float(r['amount']) if r['amount'] else None,
               'gram_weight': float(r['gram_weight']) if r['gram_weight'] else None})
```

For `fdc_nutrients`: Supabase **Table Editor → fdc_nutrients → Insert → Import data from CSV** → select `fdc_nutrients.csv`.

---

## Step 7 – Verify

Run in the Supabase SQL Editor:

```sql
SELECT
    (SELECT COUNT(*) FROM fdc_food)      AS foods,
    (SELECT COUNT(*) FROM fdc_portions)  AS portions,
    (SELECT COUNT(*) FROM fdc_nutrients) AS nutrients;
```

Expected:

| foods | portions | nutrients |
|---|---|---|
| ~8 200 | ~14 000 | ~665 000 |

---

## Step 8 – Configure the app

Add your Supabase credentials to `.env` in the project root
(this file is gitignored — never commit it):

```
SUPABASE_PROJECT_URL="https://<your-project-ref>.supabase.co"
SUPABASE_PROJECT_ANON_KEY="eyJ..."
FDC_API_KEY="DEMO_KEY"
SENTRY_DNS=""
```

Then regenerate the obfuscated env file:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Notes

- **German translations:** Generated with Google Translate via `scripts/translate_fdc_de.py`. Quality is good for most food names but may be imperfect for highly specific scientific terms.
- **Updating data:** FDC releases updates twice a year. Re-run `filter_fdc.py`, `translate_fdc_de.py`, and re-import to refresh.
- **Branded foods / barcodes:** Not included. The app uses OpenFoodFacts for the Products tab and barcode scanning.
