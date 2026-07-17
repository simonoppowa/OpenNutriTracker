# Self-hosting the Supabase food database

OpenNutriTracker's backend food search runs against a Supabase project that the maintainer (Simon) manages on Supabase's managed cloud platform on behalf of everyone who runs the published app — it is not self-hosted infrastructure. Since version 2.0 that project is no longer an FDC-only mirror: it is a **multi-source food reference database** built and maintained from its own repository:

**[github.com/simonoppowa/OpenNutriTracker-Backend](https://github.com/simonoppowa/OpenNutriTracker-Backend)**

The backend repo owns the schema, the import pipeline, and the translation tooling. This document covers the app side: what the app actually reads, and how to point a local build at your own Supabase project.

There are two situations where you might want to stand up your own copy. The first is a privacy-conscious build where you would rather not have search terms touch a third-party Supabase instance. The second is contributor work — if you're testing changes to the backend search path locally, having your own project to point at means you can iterate without depending on the shared backend and without worrying about rate limits or schema drift.

## The data sources

The backend aggregates several national food databases into one canonical schema (~27.7k foods by default, ~2M with the opt-in FDC Branded set):

| Source code | Dataset | License |
| --- | --- | --- |
| `fdc_foundation`, `fdc_sr_legacy`, `fdc_survey` | [USDA FoodData Central](https://fdc.nal.usda.gov/download-datasets) | CC0 |
| `fdc_branded` *(opt-in)* | USDA FDC Branded Foods (brand + barcode) | CC0 (label data © manufacturers) |
| `bls` | Bundeslebensmittelschlüssel 4.0 | CC BY 4.0 (attribute Max Rubner-Institut) |
| `indb` | [Anuvaad INDB](https://anuvaad.org.in) | CC BY 4.0 |
| `tbca` | [TBCA Brazil](https://www.tbca.net.br) | free with attribution (USP/FoRC) |

Users pick which sources they want to search in **Settings → Food databases**. The source list the app offers is `SPConst.settingsSelectableFoodSources` in `lib/features/add_meal/data/dto/sp/sp_const.dart` — INDB and TBCA exist in the schema but are not selectable until their imports carry data.

## What the app reads

The app reads exactly two relations from the backend schema; everything else in the backend repo (the per-source raw tables, the nutrient mapping, the import staging) is invisible to it. All names come from `SPConst` (`lib/features/add_meal/data/dto/sp/sp_const.dart`); the query code lives in `lib/features/add_meal/data/data_sources/sp_food_data_source.dart`.

### `food_summary` — one flat row per food

A materialized view with everything the app needs to render and log a food:

- **Identity** — `food_id`, `source` (one of the source codes above), `source_code` (the id in the original database, e.g. the FDC id or BLS code).
- **Display** — `name`, `short_title`, `brands`, `barcode`, `category`, `tags`, `thumbnail_url`, `main_image_url`.
- **Default serving** — `serving_quantity`, `serving_unit`, `serving_size`, `serving_gram_weight`.
- **Nutrients** — 24 canonical per-100g nutrient columns mirroring the app's `MealNutrimentsDBO` (energy, macros, extended lipids, minerals, vitamins).

English names in `food_summary.name` are searched with Postgres full-text search using the `english` configuration.

### `food_translation` — per-locale food names

One row per (food, locale) pair: `food_id`, `locale`, `description`, `source`. The app both **searches** this table for non-English locales and uses it to **label** foods in the UI. The `source` column records how the translation was produced — `native` (the original database carries the name, e.g. BLS German), `community`, `verified`, or `machine`. Machine translations (DeepL/LLM, produced by the backend repo's `translate_all.py`) are shown with a small disclosure hint in the app; human-sourced ones are not.

Supported locales are mapped in `SPConst.translationLocaleOf` — currently `de`, `pl`, `zh`, `cs`, `it`, `sk`, `tr`, and `uk`, with English reading `food_summary.name` directly. Translation search uses the `simple` text-search configuration, since the table holds many languages.

## Setting up your own backend

Everything below the app — schema DDL, downloaders, converters, the bulk importer, and the DeepL translation pipeline — lives in the backend repo. Follow its README; the short version is:

```bash
git clone https://github.com/simonoppowa/OpenNutriTracker-Backend.git
cd OpenNutriTracker-Backend

python3 -m pip install psycopg2-binary openpyxl requests
export SUPABASE_DB_URL='postgresql://postgres.<ref>:<password>@aws-0-<region>.pooler.supabase.com:5432/postgres'

cd scripts
python3 run_pipeline.py --source fdc bls --action all --db "$SUPABASE_DB_URL"
```

That downloads the raw datasets, converts them to the shared CSV set, creates the schema (`sql/schema.sql` — tables, indexes, RLS, the `food_summary` view, and the image storage bucket), and imports. The free Supabase tier is enough for the default sources; only the opt-in `--branded` set (~2M foods) outgrows it.

Machine-translating food names into another locale is one more step (requires a DeepL API key):

```bash
export DEEPL_API_KEY="your-key:fx"
python3 shared/translate_all.py --target de
```

The backend repo's `test_against_source.py` can then validate random foods in your Supabase against the raw source files.

## Pointing the app at your own Supabase

Put your project's URL and anon key (Supabase dashboard → Project Settings → API) into your local `.env`:

```
SUPABASE_PROJECT_URL="https://your-project-ref.supabase.co"
SUPABASE_PROJECT_ANON_KEY="your-anon-key"
```

Both values are obfuscated at compile time by the `envied` package, so a rebuild is required after changing them. From the repository root:

```sh
just build
```

That regenerates `lib/core/utils/env.g.dart` (which is gitignored) with the new values baked in. After that, a normal `flutter run` will pick them up. The app's `Supabase.initialize` call in `lib/core/utils/locator.dart` reads from `Env.supabaseProjectUrl` and `Env.supabaseProjectAnonKey`, so as long as the regenerated env file is in place you don't need to touch any other code.

To sanity-check the wiring, search for a common English food name (something like "apple raw") in the Add Meal screen. If you get backend results (rows with an FDC or BLS source chip), the database and the app are talking to each other. If you don't, the most common causes are: the RLS policies aren't in place (the anon role can't see the rows — `schema.sql` sets up public read, service_role write), the `food_summary` materialized view hasn't been refreshed after import (`import_fdc.py` does this automatically at the end of every run), or the full-text-search indexes are missing.

## Attribution

All the bundled sources permit reuse, but the attribution requirements differ — CC0 for FDC, CC BY 4.0 for BLS (Max Rubner-Institut) and INDB, attribution to USP/FoRC for TBCA. If you serve the data to anyone beyond yourself, attribute each source per the table above, as the app's own Acknowledgments do.
