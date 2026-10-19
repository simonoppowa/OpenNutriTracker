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
| `goal_settings.json`             | The profile's goal settings. See [below](#goal_settingsjson). |
| `water_intake.json`              | Water log (fork addition). See [below](#water_intakejson). |

**CSV bundle**

| File                    | Notes                                                        |
| ----------------------- | ------------------------------------------------------------ |
| `user_intake.csv`       | Same rows as the JSON, with the meal and its nutriments flattened. |
| `user_activity.csv`     | Flat activities.                                             |
| `user_tracked_day.csv`  | Flat tracked days — **lossy, see [Round-trip guarantee](#round-trip-guarantee)**. |

**Photos travel with the JSON bundle only.** User-attached photos are added under
`recipe_images/` and `meal_images/` when you export as JSON, gathered from three places: recipes,
saved custom meals, and **the diary entries themselves**. That third source is not redundant — a
custom meal logged with *Save for next time* off keeps its photo on the entry without leaving a
saved meal behind, so gathering only from the first two put the filename in the JSON and left the
bytes out of the zip ([#1061](https://github.com/simonoppowa/OpenNutriTracker/issues/1061)). A
photo reachable from any of the three is in the bundle exactly once.

A CSV export carries none, and the CSV importer does not restore them — another reason to use
JSON for anything you intend to restore from.

The **profile box** — height, birthday, PAL, goal — is intentionally not
included; see `lib/core/data/data_source/user_data_source.dart`. Note this is the
profile only: your logged **weight history** *is* exported, as `weight_log.json`,
and so are the **goal settings** you set under Settings → Calculations, as
`goal_settings.json` ([#1363](https://github.com/simonoppowa/OpenNutriTracker/issues/1363)).

The user can re-import the same zip via **Settings → Import**, in either format.
Import merges into what is on the device: an intake, activity or recipe whose
`id` is already stored is replaced by the imported row, as is a Custom activity
template with the same name, and tracked days and weight-log points replace by
day. Entries the zip does not carry are kept, and importing the same zip twice
changes nothing. Where the zip holds one `id` (or template name) more than
once — an install hit by #1357 exports two copies — the copy edited before
the fix wins: the first row for intakes, the last row for activities and
templates, matching where those older builds wrote an edit. An edit on a
current build rewrites every copy, so the copies agree. A row with a blank
(empty or whitespace-only) `id` is given one derived from a fixed set of its
fields — for an intake its time, meal slot, amount, unit and the food's
source, code, name and brands; for an activity its date, activity code and
name, duration and kcal — so importing the same zip twice still changes
nothing, on this build or a later one, and two identical rows both stay. Those
fields are compared trimmed, with an empty one the same as a missing one, so a
row's JSON and CSV copies get the same id; and a derived id never repeats an
`id` another row in the same file already has. The
goal settings in `goal_settings.json`, when the zip has one, replace the active
profile's. After
any import, today's kcal and macro goals are worked out again from the
profile and goal settings now on the device, as Home shows them. This applies
to today's row whether it was already on the device or came in the zip. Past
days keep the goals they were logged with. A zip missing a required file, or
with any file that does not parse, is rejected before anything on the device
changes; in a CSV file, a number written as `Infinity` or `NaN` counts as not
parsing.
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
      },
      "dataVersion": 1                // see "Micronutrient units" below
    }
  }
]
```

#### Micronutrient units on Open Food Facts rows

The `*100` micronutrient fields are stored in the app's units: milligrams
for cholesterol, the minerals and vitamins C, B6 and niacin, micrograms for
vitamins A, D and B12. Builds up to 2.3.0 wrote Open Food Facts rows with
those fields in the raw grams the API sends — a thousand times too small for
the milligram fields, a million for the microgram ones
([#775](https://github.com/simonoppowa/OpenNutriTracker/pull/775)).

`dataVersion` on the meal (and the `meal_data_version` column in the CSV) is
how the importer tells the two apart
([#1152](https://github.com/simonoppowa/OpenNutriTracker/issues/1152)): a
row whose `source` is `off` and whose version is absent or below `1` is
scaled into app units on import; a row at `1` or above is taken as-is. Rows
from every other source are never scaled. Tooling that writes `off` rows in
app units should set the version to `1`, or the importer will scale them a
second time. The same repair runs once over the on-device data on the first
launch after the upgrade — the diary, the Open Food Facts cache, the saved
custom meals and the recipe library. Saved custom meals are not part of the
bundle, so they are repaired on the device only (the app itself never saves
an `off` product for reuse, so that box is covered for completeness rather
than for a known row).

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

### `goal_settings.json`

A single object holding the active profile's goal settings. Zips from builds
that predate it have no such file and import as they always did: the device
keeps its own goals. Those older builds ignore the file when they meet it.

```jsonc
{
  "version": 1,                     // format version, see below
  "kcalAdjustment": -300.0,         // kcal added to the daily goal, -1000..1000
  "carbGoalPct": 0.4,               // macro split as fractions of the kcal goal:
  "proteinGoalPct": 0.3,            //   all three set and adding up to 1
  "fatGoalPct": 0.3,                //   (± 0.05), or all three null
  "mealKcalSharesPct": {            // per-meal share of the kcal goal in percent:
    "breakfast": 25,                //   all four meals, adding up to 100 (± 2)
    "lunch": 35,
    "dinner": 30,
    "snack": 10
  },
  "dailyWaterGoalMl": 2600          // 100..10000
}
```

`null`, or a missing key, means the app default — no kcal adjustment, the
60 / 15 / 25 carbs / protein / fat split, the 30 / 40 / 20 / 10 meal shares,
the water goal seeded from the profile — and importing it puts that goal back
to the default. A file with a value outside the ranges above, or a number
that is not finite, is rejected, and
the whole zip with it, before anything on the device changes. The tolerances
allow for rounding in older builds. `version` goes up only for a change an
older build would misread; a build that meets a newer version skips this file
and imports the rest. Unknown keys are ignored.

Only goals that belong to a profile are in the file:

- **Per-nutrient goals** (fibre, sodium, the vitamins …) are not settings
  today but columns of each day in `user_tracked_day.json`, and travel there.
  They belong in this file once they apply beyond the day they were set on
  ([#1316](https://github.com/simonoppowa/OpenNutriTracker/issues/1316)).
- **Device-wide preferences** — theme, accent colour, language, units, kJ /
  kcal, reminders, the diary day boundary, view toggles, food sources — are
  shared by every profile on the device, so a restore into one profile should
  not change them for the others. Reminders also need the system's permission
  on the new device, and the privacy consents must be given there, not
  carried over in a file. They survive a profile reset; after a reinstall they
  are set once by hand.
- **Workout import** settings from Health Connect / Apple Health are left out:
  switching it on needs the system's permission on the new device, and the
  multiplier is suggested again when it is.

### `user_recipes.json`

Array of recipe records, each holding an `ingredients` list referencing
external food items by code. The nested-ingredient shape makes CSV a poor fit
here, so recipes ship as JSON only. See `lib/core/data/dbo/recipe_dbo.dart`
for the precise field list.

### `water_intake.json`

Added by this fork (`PersonalBackupExtras`). One row per logged amount, keyed by
`id`; importing the same bundle twice replaces the rows instead of adding them
again. Missing in bundles from upstream or older builds, which then import
without touching the water log.

```jsonc
[
  {
    "id": "8c5a…",                       // uuid, the box key
    "dateTime": "2026-10-01T08:15:00.000",
    "amountMl": 250
  }
]
```

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
| `meal_data_version`             | number | no       | See [Micronutrient units](#micronutrient-units-on-open-food-facts-rows). |

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
