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

The fiddly part is the per-locale description columns. There is no machine-readable USDA source for the German names that the production project carries — those were curated by Simon over time, by hand. "On the German names, and what self-hosters get" below has the longer treatment of the options here; the short version is that leaving `description_de` empty is fine, the app falls back gracefully, and you can layer translations on later if you want them.

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

## Keeping the database in sync with USDA releases

USDA publishes Food Data Central updates roughly twice a year — the download page at [https://fdc.nal.usda.gov/download-datasets.html](https://fdc.nal.usda.gov/download-datasets.html) lists every release with a date stamp, and the "Full Download of All Data Types" archive is the one to grab each time. There's no notification system, so the easiest pattern is to subscribe to the RSS feed on that page, or to check it on the same cadence you'd check for any upstream library bump.

The good news is that the Supabase tables are a snapshot of public USDA data, not a system of record. Users' meal logs, weights, activities, and everything else live in the local Hive database on each device — none of it touches the FDC tables. That means re-seeding wholesale is fine. You won't lose anything by truncating the three tables and re-running the seed steps against the new CSV bundle.

If you'd rather do a true diff so you can see what actually changed, the rough shape is:

1. Download the new "Full Download" archive and unzip it next to the previous one.
2. Compare the `fdc_id` columns in the old and new `food.csv` to find added, removed, and modified rows. `comm -1 -3` on sorted `fdc_id` columns gives you the additions; `comm -2 -3` gives you the removals. For modified rows, a `diff` against the description column will surface renames.
3. Decide whether the changes are worth a targeted update or a full reload. For most releases the answer will be "full reload" — it's simpler, the seed runs in a few minutes, and you avoid the risk of orphaned nutrient or portion rows from foods that have been retired upstream.

Either way, when you're done it's worth doing a quick verification pass. Three checks that have caught issues in practice:

- **Row counts.** A USDA release of Foundation Foods plus SR Legacy is in the low tens of thousands of foods today. If you've ended up with far fewer, the `COPY` likely silently dropped malformed rows. If far more, you may have accidentally pulled in the Branded Foods set, which is two orders of magnitude larger.
- **Energy presence.** Every food should have at least one of nutrient IDs `1008`, `957`, or `958`. A quick `select count(*) from fdc_food f where not exists (select 1 from fdc_nutrients n where n.fdc_id = f.fdc_id and n.nutrient_id in (1008, 957, 958))` will tell you how many foods will render with 0 kcal in the app. Ideally that's zero.
- **Spot-check a known item.** Search the seeded database for a food you know well — "apple, raw" or "banana, raw" both reliably exist in Foundation Foods — and confirm the kcal value and one portion size look right. If the kcal is off by a factor of 10 or 100, you've likely got a unit-conversion issue in the seed; if the portion is missing, the foreign key didn't get set up correctly.

If you maintain the `description_de` column (see the next section), you'll need to plan for re-applying those translations on top of each refresh. The simplest pattern is to keep your German names in a separate `description_de_overrides` table keyed by `fdc_id`, then `UPDATE fdc_food SET description_de = o.description_de FROM description_de_overrides o WHERE fdc_food.fdc_id = o.fdc_id` after the reload. Any new foods USDA has added since your last translation pass will appear with `NULL` in `description_de`, which is the correct fallback behaviour anyway.

## On the German names, and what self-hosters get

This is worth being honest about up front, because it's the one part of the production database that doesn't come from anywhere reproducible.

The `description_de` column in the project's hosted Supabase has German names for many foods, and those names are there because Simon — the original maintainer — sat down with the data and curated them by hand over time. Some came from straightforward translations; some required food-specific judgement (USDA descriptions like "Cheese, cheddar" don't translate cleanly without thinking about whether the German reader will recognise the cheese under its English borrowing, its German common name, or its regional variant). That work doesn't live in any exportable file. It lives in the rows themselves.

A self-hoster starting from the public USDA CSVs gets an English-only dataset. There's no shortcut around that, and it's worth saying clearly so you can decide which path you want to take. Three options that all make sense for different situations:

- **Leave `description_de` null.** The `SupportedLanguage` logic in the app handles this — `getLocaleDescription` returns `null` for German users when the column is empty, and the wider meal-entity code path falls back to the English name. German-locale users will see English food names, which is rough on a German UI but everything still works. If you're self-hosting primarily for privacy or for English-speaking use, this is the lowest-effort choice and there's nothing wrong with it.

- **Curate manually for the foods that matter to you.** If you have a specific subset of foods you cook with regularly — a few hundred items, say, rather than tens of thousands — translating those by hand is genuinely tractable in an evening or two. You can prioritise by frequency: start with the most-searched terms in your own use and translate outwards from there. This is the path Simon walked, and it's the one that produces the highest-quality result, but it's slow and it's never finished.

- **Use a machine-translation pipeline.** DeepL, an open-source NMT model, or a local LLM will translate ~10,000 short food descriptions in the low tens of minutes. The quality is good for simple terms ("apple, raw" → "Apfel, roh") and noticeably worse for compound or culturally-specific names. Cheese varieties, fish species, and processed-food descriptions are where you'll see the most errors. If you go this route, plan to spot-check the output and accept that some translations will be wrong in ways that aren't always obvious from the German side. A useful middle path is to machine-translate as a starting point and then hand-correct the categories you care most about.

There's no shame in any of these choices. The thing to know is that the German names in the hosted project are the result of patient, real human effort over time, and they're not something a self-hosted copy gets automatically. If you do build out a translation set you're happy with — particularly if it covers a locale that isn't supported in production today — please consider sharing it back as an issue or a discussion. Other self-hosters would benefit, and the project would be glad to have it.

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

## Appendix: example SQL migrations

The snippets in the "Setting up the Supabase project" section above are deliberately minimal — enough to get the app talking to the database. If you'd rather paste a single block into the Supabase SQL editor and have everything in place, the version below is self-contained. It creates the three tables, sets up the relationships, builds the GIN tsvector indexes for full-text search, and enables RLS with read-only policies for the anon role. Run it on a fresh project; the seed steps from "Seeding from USDA Food Data Central" come next.

```sql
-- =========================================================
-- OpenNutriTracker FDC schema — self-hosting starter
-- =========================================================

-- 1. Tables

create table if not exists fdc_food (
    fdc_id         int  primary key,
    description_en text not null,
    description_de text
);

create table if not exists fdc_nutrients (
    fdc_id      int              not null references fdc_food (fdc_id) on delete cascade,
    nutrient_id int              not null,
    amount      double precision,
    primary key (fdc_id, nutrient_id)
);

create table if not exists fdc_portions (
    id              bigserial        primary key,
    fdc_id          int              not null references fdc_food (fdc_id) on delete cascade,
    measure_unit_id int,
    amount          double precision,
    gram_weight     double precision
);

-- 2. Indexes

-- Foreign-key lookups for relational selects (fdc_nutrients ( ... ), fdc_portions ( ... ))
create index if not exists fdc_nutrients_fdc_id_idx on fdc_nutrients (fdc_id);
create index if not exists fdc_portions_fdc_id_idx  on fdc_portions  (fdc_id);

-- Full-text search indexes — match TextSearchType.websearch in the app
create index if not exists fdc_food_description_en_fts
    on fdc_food using gin (to_tsvector('english', description_en));

create index if not exists fdc_food_description_de_fts
    on fdc_food using gin (to_tsvector('german', coalesce(description_de, '')));

-- 3. Row-level security

alter table fdc_food      enable row level security;
alter table fdc_nutrients enable row level security;
alter table fdc_portions  enable row level security;

create policy "anon read fdc_food"
    on fdc_food
    for select
    to anon
    using (true);

create policy "anon read fdc_nutrients"
    on fdc_nutrients
    for select
    to anon
    using (true);

create policy "anon read fdc_portions"
    on fdc_portions
    for select
    to anon
    using (true);

-- 4. (Optional) authenticated role read access
-- Uncomment if you also expose these tables to logged-in Supabase users.
-- The shipped app only ever authenticates as anon, so this is not required.
--
-- create policy "authenticated read fdc_food"      on fdc_food      for select to authenticated using (true);
-- create policy "authenticated read fdc_nutrients" on fdc_nutrients for select to authenticated using (true);
-- create policy "authenticated read fdc_portions"  on fdc_portions  for select to authenticated using (true);
```

A few notes on the choices in this block, in case you want to adjust them:

- The `description_de` GIN index wraps the column in `coalesce(description_de, '')` so it builds cleanly even when the column is empty across the board (a fresh USDA seed, before any translation pass). An empty tsvector indexes to nothing, so this costs nothing at query time, and it means the index won't need to be rebuilt later when you start populating the column.
- The `id` column on `fdc_portions` is a synthetic surrogate. The USDA `food_portion.csv` can have multiple rows for the same `(fdc_id, measure_unit_id)` pair (different `amount` or `gram_weight` values for the same unit), so a composite primary key on those two columns will fail to load some rows. The synthetic key sidesteps that without changing what the app reads.
- `on delete cascade` on the foreign keys means that if you `delete from fdc_food where fdc_id = ...`, the matching nutrient and portion rows go too. That's the behaviour you want during a re-seed; if you'd rather get an error instead, swap it for `on delete restrict`.
- The full-text language configurations (`'english'`, `'german'`) match Postgres's bundled snowball stemmers. There are no built-in configurations for Polish, Czech, Italian, Turkish, Ukrainian, or Chinese in default Postgres; if you add those description columns later you'll either want to use the `'simple'` configuration (no stemming) or install a language-specific extension.

## What this doesn't cover

A few things are honestly out of scope for what's written here, and worth naming so you're not surprised:

- **Other locales.** Polish, Czech, Italian, Turkish, Ukrainian, and Chinese are routed to `description_en` in the app today, and the columns to override that don't exist in production either. If you add them in your self-hosted copy, you'll also be carrying a small patch to the app's `SpFdcFoodDTO.getLocaleDescription` and `SPConst.getFdcFoodDescriptionColumnName`.
- **Branded foods.** The production project uses Foundation Foods and SR Legacy only. The USDA also publishes a "Branded Foods" dataset that's vastly larger and changes frequently; the schema above will accommodate it if you want to include it, but the app's search experience hasn't been tuned for that volume.
- **Sharing your self-hosted dataset.** If you build something more complete than the production project (translations, brand data, anything else), please consider opening an issue or a discussion — Simon would likely be happy to upstream it, and other self-hosters would benefit too.
