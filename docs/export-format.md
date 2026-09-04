# Export bundle format

This document describes the structure of the data export that **Settings →
Export / Import App Data → Export** produces. It exists for the same reason
issue #40 asked for it: people who want to keep their nutrition history in a
plaintext format they can sync via Syncthing, open in a spreadsheet, or feed
into other tooling deserve a stable schema they can read against. Issue #132
asked specifically for CSV export so the import / export round trip would be
symmetric. CSV is a second bundle format rather than an addition to the JSON one.

## Zip layout

The export is a single `.zip` file (default filename
`opennutritracker-export.zip`).

**You pick one format, and the bundle carries only that one.** Settings → Export
offers a JSON / CSV toggle, and the bundle contains either the JSON files or the
CSV files — never both side by side. A tool that unzips expecting a JSON file
next to its CSV counterpart will not find one.

**JSON bundle**

| File                             | Notes                                                    |
| -------------------------------- | -------------------------------------------------------- |
| `user_intake.json`               | Canonical format the app re-imports from.                |
| `user_activity.json`             | Canonical format the app re-imports from.                |
| `user_tracked_day.json`          | Canonical format the app re-imports from.                |
| `user_recipes.json`              | Recipes only. Nested-ingredient shape, no CSV counterpart. |
| `weight_log.json`                | Weight history.                                          |
| `custom_activity_templates.json` | Saved custom activities — name and typical kcal.         |

**CSV bundle**

| File                    | Notes                                                        |
| ----------------------- | ------------------------------------------------------------ |
| `user_intake.csv`       | Same rows as the JSON, with the meal and its nutriments flattened. |
| `user_activity.csv`     | Flat activities.                                             |
| `user_tracked_day.csv`  | Flat tracked days — **lossy, see [Round-trip guarantee](#round-trip-guarantee)**. |

**Photos travel with the JSON bundle only.** Any user-attached recipe and custom-meal images are
added under `recipe_images/` and `meal_images/` when you export as JSON. A CSV export carries
none, and the CSV importer does not restore them — another reason to use JSON for anything you
intend to restore from.

The **profile box** — height, birthday, PAL, goal — is intentionally not
included; see `lib/core/data/data_source/user_data_source.dart`. Note this is the
profile only: your logged **weight history** *is* exported, as `weight_log.json`.

The user can re-import the same zip via **Settings → Import**, in either format.
The CSV files also exist so a spreadsheet, a Syncthing-style backup, or external
tooling can read the same data without going through Hive.

## JSON schema

The JSON files are direct serializations of the Hive DBO classes via
`json_serializable`, so the source of truth lives in
`lib/core/data/dbo/`. The shapes below are summaries — fields may be added in
future versions, and unknown fields are ignored on import.

### `user_intake.json`

Array of intake records:

```jsonc
[
  {
    "id": "uuid-string",
    "unit": "g",                     // or "ml", "serving", ...
    "amount": 120.0,                 // numeric amount in `unit`
    "type": "breakfast",             // breakfast | lunch | dinner | snack
    "dateTime": "2026-05-13T08:15:00.000",
    "meal": {
      "code": "1234567890123",       // barcode or null
      "name": "Whole Milk",
      "brands": "Acme Dairy",
      "thumbnailImageUrl": null,
      "mainImageUrl": null,
      "url": null,
      "mealQuantity": "100",
      "mealUnit": "g",
      "servingQuantity": 250.0,
      "servingUnit": "ml",
      "servingSize": "250 ml",
      "source": "off",               // unknown | custom | off | fdc | recipe
      "nutriments": {
        "energyKcal100": 61.0,
        "carbohydrates100": 4.8,
        "fat100": 3.3,
        "proteins100": 3.2,
        "sugars100": 5.1,
        "saturatedFat100": 1.9,
        "fiber100": 0.0,
        // Optional extended fields (#237):
        "monounsaturatedFat100": null,
        "polyunsaturatedFat100": null,
        "transFat100": null,
        "cholesterol100": null,
        "sodium100": null,
        "potassium100": null,
        "magnesium100": null,
        "calcium100": null,
        "iron100": null,
        "zinc100": null,
        "phosphorus100": null,
        "vitaminA100": null,
        "vitaminC100": null,
        "vitaminD100": null,
        "vitaminB6100": null,
        "vitaminB12100": null,
        "niacin100": null
      }
    }
  }
]
```

### `user_activity.json`

Array of logged physical-activity records:

```jsonc
[
  {
    "id": "uuid-string",
    "duration": 45.0,                // minutes
    "burnedKcal": 320.0,
    "date": "2026-05-13T18:00:00.000",
    "physicalActivityDBO": {
      "code": "01010",               // 2024 Adult Compendium code
      "specificActivity": "Running, 8 km/h",
      "description": "Running, 8 km/h (7.5 min/km)",
      "mets": 8.3,
      "tags": ["cardio", "outdoor"],
      "type": "running"              // bicycling | conditioningExercise | dancing | running | sport | waterActivities | winterActivities
    }
  }
]
```

Records also carry the optional `userKcal` (set once the user edits an
activity's calories, `null` before that), plus `externalId` (the health-store
record an imported workout came from, which is what stops a re-import
duplicating it) and `sourceReportedKcal` (the energy the device reported before
the workout calorie credit); the latter two are `null` on manually logged
activities, and all three round-trip on import/export.

### `user_tracked_day.json`

Array of per-day calorie/macro totals:

```jsonc
[
  {
    "day": "2026-05-13T00:00:00.000",
    "calorieGoal": 2200.0,
    "caloriesTracked": 1850.0,
    "carbsGoal": 330.0,
    "carbsTracked": 270.0,
    "fatGoal": 61.0,
    "fatTracked": 55.0,
    "proteinGoal": 110.0,
    "proteinTracked": 95.0
  }
]
```

### `user_recipes.json`

Array of recipe records, each holding an `ingredients` list referencing
external food items by code. The nested-ingredient shape makes CSV a poor fit
here, so recipes ship as JSON only. See `lib/core/data/dbo/recipe_dbo.dart`
for the precise field list.

## CSV schema

All CSV files use UTF-8, comma as the field separator, `\n` as the line
terminator, and the same minimal quoting rules as the existing CSV importer
(`lib/core/utils/csv_row_parser.dart`):

- A cell is wrapped in double quotes when it contains `,`, `"`, `\n`, or `\r`.
- Embedded double quotes inside a quoted cell are escaped by doubling: `""`.
- Empty cells represent `null` for nullable columns.
- Numeric cells accept `.` or `,` as the decimal mark; the exporter always
  writes `.`.
- Date/time cells are ISO-8601 strings (`DateTime.toIso8601String()`).

Column **order** in the exported CSV matches the table below, but the parser
is **header-driven**, so external tooling can re-order columns freely.
Header lookup is case-insensitive.

### `user_intake.csv`

| Column                          | Type   | Required | Notes                                          |
| ------------------------------- | ------ | -------- | ---------------------------------------------- |
| `id`                            | string | yes      | Intake UUID.                                   |
| `date_time`                     | string | yes      | ISO-8601 timestamp.                            |
| `type`                          | enum   | yes      | `breakfast` / `lunch` / `dinner` / `snack`.    |
| `amount`                        | number | yes      | Quantity logged.                               |
| `unit`                          | string | yes      | e.g. `g`, `ml`, `serving`.                     |
| `meal_code`                     | string | no       | Barcode / FDC ID; empty for custom foods.      |
| `meal_name`                     | string | no       |                                                |
| `meal_brands`                   | string | no       |                                                |
| `meal_source`                   | enum   | no       | `unknown` / `custom` / `off` / `fdc` / `recipe`. |
| `meal_quantity`                 | string | no       | e.g. `100`.                                    |
| `meal_unit`                     | string | no       | e.g. `g`.                                      |
| `meal_serving_quantity`         | number | no       |                                                |
| `meal_serving_unit`             | string | no       |                                                |
| `meal_serving_size`             | string | no       | Human-readable size.                           |
| `meal_thumbnail_url`            | string | no       |                                                |
| `meal_main_image_url`           | string | no       |                                                |
| `meal_url`                      | string | no       |                                                |
| `kcal_per_100g`                 | number | no       | All `*_per_100g` columns are nutriment values per 100 g of the food, not per logged portion. |
| `carbs_per_100g`                | number | no       |                                                |
| `fat_per_100g`                  | number | no       |                                                |
| `protein_per_100g`              | number | no       |                                                |
| `sugars_per_100g`               | number | no       |                                                |
| `saturated_fat_per_100g`        | number | no       |                                                |
| `fiber_per_100g`                | number | no       |                                                |
| `monounsaturated_fat_per_100g`  | number | no       | Extended lipid profile (#237).                 |
| `polyunsaturated_fat_per_100g`  | number | no       |                                                |
| `trans_fat_per_100g`            | number | no       |                                                |
| `cholesterol_per_100g`          | number | no       | mg.                                            |
| `sodium_per_100g`               | number | no       | mg.                                            |
| `potassium_per_100g`            | number | no       | mg.                                            |
| `magnesium_per_100g`            | number | no       | mg.                                            |
| `calcium_per_100g`              | number | no       | mg.                                            |
| `iron_per_100g`                 | number | no       | mg.                                            |
| `zinc_per_100g`                 | number | no       | mg.                                            |
| `phosphorus_per_100g`           | number | no       | mg.                                            |
| `vitamin_a_per_100g`            | number | no       | µg RAE.                                        |
| `vitamin_c_per_100g`            | number | no       | mg.                                            |
| `vitamin_d_per_100g`            | number | no       | µg.                                            |
| `vitamin_b6_per_100g`           | number | no       | mg.                                            |
| `vitamin_b12_per_100g`          | number | no       | µg.                                            |
| `niacin_per_100g`               | number | no       | mg (B3).                                       |

### `user_activity.csv`

| Column              | Type   | Required | Notes                                                                  |
| ------------------- | ------ | -------- | ---------------------------------------------------------------------- |
| `id`                | string | yes      | UUID.                                                                  |
| `date`              | string | yes      | ISO-8601 timestamp.                                                    |
| `duration`          | number | yes      | Minutes.                                                               |
| `burned_kcal`       | number | yes      |                                                                        |
| `activity_code`     | string | yes      | 2024 Adult Compendium code.                                            |
| `specific_activity` | string | yes      | Human-readable activity name.                                          |
| `description`       | string | yes      |                                                                        |
| `mets`              | number | yes      | MET value.                                                             |
| `tags`              | string | no       | Pipe-separated (`outdoor|cardio`) so the cell stays single-field.      |
| `type`              | enum   | yes      | `bicycling` / `conditioningExercise` / `dancing` / `running` / `sport` / `waterActivities` / `winterActivities`. |
| `user_kcal`            | number | no       | Set when the kcal figure is the user's own or a device's rather than the MET formula's. |
| `external_id`          | string | no       | Health Connect / Apple Health record id for an imported workout; empty for a manually logged one. |
| `source_reported_kcal` | number | no       | What the device reported for an imported workout, before the calorie-credit multiplier. |

### `user_tracked_day.csv`

| Column              | Type   | Required | Notes                                |
| ------------------- | ------ | -------- | ------------------------------------ |
| `day`               | string | yes      | ISO-8601 date (start of day).        |
| `calorie_goal`      | number | yes      |                                      |
| `calories_tracked`  | number | yes      |                                      |
| `carbs_goal`        | number | no       | g.                                   |
| `carbs_tracked`     | number | no       | g.                                   |
| `fat_goal`          | number | no       | g.                                   |
| `fat_tracked`       | number | no       | g.                                   |
| `protein_goal`      | number | no       | g.                                   |
| `protein_tracked`   | number | no       | g.                                   |

## Round-trip guarantee

Intakes and activities round-trip cleanly through
`lib/core/utils/csv_data_exporter.dart` — exporting a list of DBOs and parsing
the resulting CSV yields structurally equal DBOs (modulo
empty-string-vs-null normalisation on nullable fields). The unit test
`test/unit_test/csv_data_exporter_test.dart` pins this behaviour.

**Tracked days do not round-trip.** `trackedDayColumns` carries nine columns
while `TrackedDayDBO` has nineteen fields: the ten per-nutrient goals — fibre,
saturated fat, sugars, sodium, calcium, iron, potassium, magnesium, vitamin B12
and vitamin D — have no column and are lost on a CSV export. The JSON bundle
keeps them. Use JSON if you intend to restore from the bundle rather than read
it in a spreadsheet.

**CSV import works.** `ImportDataUsecase.importDataCsv` reads `user_intake.csv`,
`user_activity.csv` and `user_tracked_day.csv`, and Settings → Import uses the
same format toggle as the export. External tooling can therefore write either
shape — subject to the tracked-day loss above.

## Syncthing-friendly notes

The export is deliberately plain UTF-8 inside a normal zip — no binary
encoding, no app-specific framing — so it is safe to leave a copy in a
Syncthing folder and let the same bundle move between devices. The JSON
files re-import losslessly; the CSV files are stable across versions
(columns can be added at the end, never reordered or removed without a
schema bump).
