# Self-hosting the Supabase FDC database

OpenNutriTracker pulls USDA Food Data Central results through a small Supabase project that the maintainer (Simon) hosts on behalf of everyone who runs the published app. That works well for the common case, and it means the app itself doesn't need a USDA API key to surface FDC foods.

There are two situations where you might want to stand up your own copy instead. The first is a privacy-conscious build where you would rather not have search terms touch a third-party Supabase instance. The second is contributor work — if you're testing changes to the FDC search path locally, having your own Supabase project to point at means you can iterate without depending on the shared backend and without worrying about rate limits or schema drift.

This document describes the schema the app expects, where the seed data comes from, and how to wire a fresh Supabase project into a local build. It's written from the perspective of someone who has already read the relevant code in `lib/features/add_meal/data/data_sources/sp_fdc_data_source.dart` and the DTOs under `lib/features/add_meal/data/dto/fdc_sp/`, and now wants to set up the database side.

A note on completeness up front: the per-locale name columns in the production Supabase project were curated by Simon over time. A fresh self-hosted seed will be English-only out of the gate, and the German column will be empty unless you also bring your own translation pass. That's fine — the app falls back gracefully — but it's worth knowing before you start.

## What's in the database

The app talks to a single Supabase project and reads from three related tables. All names are taken directly from `SPConst` (`lib/features/add_meal/data/dto/fdc_sp/sp_const.dart`); if you change them, the app won't find the data.

### `fdc_food` — one row per food item

This is the table the app searches against. Every column here corresponds to a `@JsonKey` on `SpFdcFoodDTO`.

| Column | SQL type | Purpose |
| ------ | -------- | ------- |
| `fdc_id` | `int` (primary key) | The USDA-assigned FDC identifier. Used as the row key and as `MealEntity.code` inside the app. |
| `description_en` | `text` | English food name. This is the column the app searches against for English-locale users and the fallback for every other locale. |
| `description_de` | `text` (nullable) | German food name. Read only when the device locale is `de`; otherwise unused. |

The app's `SpFdcDataSource.fetchSearchWordResults` issues a Postgres full-text-search query against whichever description column matches the device locale — see "Indexing for full-text search" below for the matching index definition. The `SupportedLanguage` enum in `lib/core/utils/supported_language.dart` is what decides which column gets queried; today it routes `en` to `description_en` and `de` to `description_de`, with every other locale falling back to `description_en`.

If you later want to add Polish, Czech, Italian, Turkish, Ukrainian, or Chinese names, the path is to add `description_pl`, `description_cs`, `description_it`, `description_tr`, `description_uk`, `description_zh` columns, then update both `SPConst.getFdcFoodDescriptionColumnName` and `SpFdcFoodDTO.getLocaleDescription` to point at them. There's a `TODO(@simonoppowa)` comment at each call site marking exactly where the switch statement opens up.

### `fdc_nutrients` — many-to-one with `fdc_food`

One row per (food, nutrient) pair. The app fetches this as a Supabase relational select (`fdc_nutrients ( nutrient_id, amount )`), so the foreign key needs to be wired up on the Supabase side as a relationship.

| Column | SQL type | Purpose |
| ------ | -------- | ------- |
| `fdc_id` | `int` (foreign key → `fdc_food.fdc_id`) | Links the nutrient row back to its food. |
| `nutrient_id` | `int` | USDA nutrient identifier. The app cares about a specific subset listed below. |
| `amount` | `double precision` | Amount of the nutrient per 100 g of food. |

The nutrient IDs the app reads come from `FDCConst` in `lib/features/add_meal/data/dto/fdc/fdc_const.dart`. The full list as of today is:

- Energy: `1008` (total), `957` (Atwater general), `958` (Atwater specific) — the app prefers Atwater-specific, falls back to general, then to total.
- Macros: `1005` (carbohydrates), `1004` (fat), `1003` (protein), `1063` (sugar), `1258` (saturated fat), `1079` (fiber).
- Extended lipids: `645` (monounsaturated), `646` (polyunsaturated), `605` (trans), `601` (cholesterol).
- Minerals: `307` (sodium), `306` (potassium), `304` (magnesium), `301` (calcium), `303` (iron), `309` (zinc), `305` (phosphorus).
- Vitamins: `318` (vitamin A, µg RAE), `401` (vitamin C, mg), `328` (vitamin D, µg), `415` (vitamin B6, mg), `418` (vitamin B12, µg), `406` (niacin, mg).

A row in `fdc_nutrients` with any other `nutrient_id` is harmless — the app just won't read it. But missing the energy row will leave the food showing 0 kcal in the UI, so it's worth verifying after seeding that every food has at least one of `1008` / `957` / `958`.

### `fdc_portions` — many-to-one with `fdc_food`

One row per (food, portion) pair, fetched the same way as nutrients via a relational select. Maps to `SpFdcPortionDTO`.

| Column | SQL type | Purpose |
| ------ | -------- | ------- |
| `fdc_id` | `int` (foreign key → `fdc_food.fdc_id`) | Links the portion row back to its food. |
| `measure_unit_id` | `int` | USDA measure-unit code. The full mapping (1000 = cup, 1049 = serving, 9999 = unknown, etc.) lives in `FDCConst.measureUnits`. |
| `amount` | `double precision` | How many of that unit make up the portion (e.g. `1` for "one cup"). |
| `gram_weight` | `double precision` | The weight of the portion in grams. This is the value the app actually uses to compute calories per portion. |

The app picks the portion with `measure_unit_id` equal to `1049` ("serving") or, failing that, `9999` ("undetermined"). If neither is present, the food will fall back to its 100 g default in the UI.

## Seeding from USDA Food Data Central

The USDA publishes the entire FDC database as a set of CSV files at [https://fdc.nal.usda.gov/download-datasets.html](https://fdc.nal.usda.gov/download-datasets.html). You want the "Full Download of All Data Types" archive, which includes Foundation Foods and SR Legacy — those are the two data types the production project carries (the direct FDC API code in `FDCConst._dataTypeParams` confirms it).

The mapping from USDA CSVs to the three Supabase tables looks like this:

- `food.csv` → `fdc_food`. The `fdc_id` and `description` columns come from this file directly. Copy `description` into `description_en`; leave `description_de` `NULL` for now.
- `food_nutrient.csv` → `fdc_nutrients`. Pull `fdc_id`, `nutrient_id`, and `amount`. The file is large (hundreds of millions of rows); a `COPY` into a staging table followed by `INSERT … WHERE nutrient_id IN (…)` with the list above will trim it to the nutrients the app reads. You can keep the rest if storage isn't a concern, but the trimmed version makes queries noticeably faster.
- `food_portion.csv` → `fdc_portions`. Pull `fdc_id`, `measure_unit_id`, `amount`, and `gram_weight`. No filtering needed.

The fiddly part is the per-locale description columns. The production Supabase project has German names for many foods because Simon ran translation passes against `description_en` over time and edited the results by hand. There is no machine-readable USDA source for those translations. If you want German names in your own copy, the honest options are:

- Leave `description_de` empty and let German-locale users see English names. The app handles `NULL` here — it just shows nothing for the German description and `getLocaleDescription` returns null, at which point the wider meal-entity code path falls back to the English name.
- Run your own translation pass against `description_en`. A local LLM is fine for this if you accept that the results will need review for food-specific terminology. Bulk-translating ~10,000 short food descriptions runs in the low tens of minutes on a modest setup.
- Wait for a future contribution that publishes the production translations as a separate downloadable file. There's nothing concrete planned today, but the schema columns are in place for it.

The same applies to any of the other locales (Polish, Czech, Italian, Turkish, Ukrainian, Chinese): the columns don't exist in production today, so you'd be paving new ground if you added them.

## Setting up the Supabase project

These steps assume you've signed up for a free Supabase project at [supabase.com](https://supabase.com). The free tier is more than enough for personal use; the production project fits comfortably inside it.

1. Create a new project. Pick a region near you for lower search latency. Save the project URL and the anon key from "Project Settings → API" — you'll need both later.

2. Apply the schema. In the SQL editor, create the three tables described above. A starting point looks like this:

   ```sql
   create table fdc_food (
       fdc_id          int  primary key,
       description_en  text not null,
       description_de  text
   );

   create table fdc_nutrients (
       fdc_id       int  references fdc_food (fdc_id) on delete cascade,
       nutrient_id  int  not null,
       amount       double precision,
       primary key (fdc_id, nutrient_id)
   );

   create table fdc_portions (
       id              bigserial primary key,
       fdc_id          int  references fdc_food (fdc_id) on delete cascade,
       measure_unit_id int,
       amount          double precision,
       gram_weight     double precision
   );
   ```

   The synthetic `id` on `fdc_portions` is there because a food can have several portions with the same `measure_unit_id` in the USDA data. If yours doesn't, a composite key is fine — the app doesn't read this column.

3. Load the CSVs. The Supabase SQL editor has a `COPY` capability for small files; for the full USDA dataset you'll want the Supabase CLI or `psql` against the project's connection string. The order matters: `fdc_food` first, then `fdc_nutrients` and `fdc_portions` (because of the foreign keys).

4. Index for full-text search. The app uses `TextSearchType.websearch` against the description columns, which Postgres treats as `websearch_to_tsquery`. The matching index is a GIN index on a `tsvector`:

   ```sql
   create index fdc_food_description_en_fts
       on fdc_food using gin (to_tsvector('english', description_en));

   create index fdc_food_description_de_fts
       on fdc_food using gin (to_tsvector('german', description_de));
   ```

   Without these the search will still work, but each query will scan the full table — fine for testing, painful in practice once you have the full USDA dataset loaded.

5. Configure row-level security. The app authenticates as the anon role, and it only ever reads from these tables. Enable RLS on all three and grant `select` to `anon`:

   ```sql
   alter table fdc_food      enable row level security;
   alter table fdc_nutrients enable row level security;
   alter table fdc_portions  enable row level security;

   create policy "anon read fdc_food"      on fdc_food      for select to anon using (true);
   create policy "anon read fdc_nutrients" on fdc_nutrients for select to anon using (true);
   create policy "anon read fdc_portions"  on fdc_portions  for select to anon using (true);
   ```

   The anon key is bundled into the compiled app, so it's effectively public. RLS makes sure that even with the key in hand, nobody can write to your tables.

## Pointing the app at your own Supabase

The two values you saved in step 1 above go into your local `.env` file:

```
SUPABASE_PROJECT_URL="https://your-project-ref.supabase.co"
SUPABASE_PROJECT_ANON_KEY="your-anon-key"
```

Both values are obfuscated at compile time by the `envied` package, so a rebuild is required after changing them. From the repository root:

```sh
just build
```

That regenerates `lib/core/utils/env.g.dart` (which is gitignored) with the new values baked in. After that, a normal `flutter run` will pick them up. The app's `Supabase.initialize` call in `lib/core/utils/locator.dart` reads from `Env.supabaseProjectUrl` and `Env.supabaseProjectAnonKey`, so as long as the regenerated env file is in place you don't need to touch any other code.

To sanity-check the wiring, search for a common English food name (something like "apple raw") in the Add Meal screen. If you get FDC results back, the database and the app are talking to each other. If you don't, the most common causes are: the RLS policies aren't in place (the anon role can't see the rows), the foreign-key relationships aren't set up on the Supabase side (the relational select returns nothing), or the full-text-search index is missing on the column matching your device locale.

## What this doesn't cover

A few things are honestly out of scope for what's written here, and worth naming so you're not surprised:

- **German translations.** As above — the production `description_de` column was curated by Simon over time and there's no exportable source for it. A self-hosted copy starts English-only.
- **Other locales.** Polish, Czech, Italian, Turkish, Ukrainian, and Chinese are routed to `description_en` in the app today, and the columns to override that don't exist in production either. If you add them in your self-hosted copy, you'll also be carrying a small patch to the app's `SpFdcFoodDTO.getLocaleDescription` and `SPConst.getFdcFoodDescriptionColumnName`.
- **Branded foods.** The production project uses Foundation Foods and SR Legacy only. The USDA also publishes a "Branded Foods" dataset that's vastly larger and changes frequently; the schema above will accommodate it if you want to include it, but the app's search experience hasn't been tuned for that volume.
- **Updating against newer USDA releases.** USDA publishes refreshes roughly twice a year. The seed steps work for any release, but they assume a from-scratch reload rather than an incremental update — diffing two FDC dumps is its own small project.
- **Sharing your self-hosted dataset.** If you build something more complete than the production project (translations, brand data, anything else), please consider opening an issue or a discussion — Simon would likely be happy to upstream it, and other self-hosters would benefit too.
