# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenNutriTracker is a Flutter mobile app (iOS/Android) for nutritional tracking. It uses Open Food Facts and USDA Food Data Central (via Supabase) as food databases, with all user data stored locally in an AES-encrypted Hive database.

Flutter version: **3.41.7** (managed via FVM; see `.fvmrc`)

## Commands

All common tasks are in the `justfile`:

```sh
just install       # flutter pub get
just build         # dart run build_runner build --delete-conflicting-outputs
just format        # dart format ./lib/core ./lib/features ./lib/l10n ./test
just test          # flutter test
just check_intl    # verify generated intl files are up to date (used in CI)
just ci            # full CI: install, format check, intl check, build, analyze, test
```

Run a single test file:

```sh
flutter test test/unit_test/tdee_calc_test.dart
```

Run static analysis:

```sh
flutter analyze
```

## Environment Setup

Copy `.env` and fill in real values before running:

```
FDC_API_KEY="YOUR_KEY"        # USDA Food Data Central API key (direct FDC source, not actively used in UI)
SENTRY_DNS="DNS_URL"
SUPABASE_PROJECT_URL="PROJECT_URL"
SUPABASE_PROJECT_ANON_KEY="ANON_KEY"
```

After editing `.env`, run `just build` to regenerate `lib/core/utils/env.g.dart` (gitignored). The `envied` package obfuscates all secret values at compile time.

## Code Generation

Run `just build` (i.e. `dart run build_runner build`) whenever you add or modify any of the source files listed below. Every generated file starts with `// GENERATED CODE - DO NOT MODIFY BY HAND` or an equivalent header — never edit them directly.

If `build_runner` fails with `PackageNotFoundException: hive` after pulling from an older checkout, the build cache is stale from the pre-`hive_ce` days. Fix it with:

```sh
rm -rf .dart_tool/build
dart run build_runner build
```

### What gets generated and when

| Trigger                            | Generated file(s)                                                                                         | Tool                |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------- |
| Any `@HiveType` / `@HiveField` DBO | `<dbo_file>.g.dart` alongside the source                                                                  | `hive_ce_generator` |
| Any new DBO added anywhere         | `lib/hive_registrar.g.dart` — the `HiveRegistrar` extension that calls `registerAdapter()` for every type | `hive_ce_generator` |
| Any `@JsonSerializable` DTO        | `<dto_file>.g.dart` alongside the source                                                                  | `json_serializable` |
| `.env` file edited                 | `lib/core/utils/env.g.dart` (**gitignored** — must regenerate after every clone)                          | `envied_generator`  |

**DBO files** live in `lib/core/data/dbo/` and `lib/core/data/data_source/` (one `.g.dart` per file). Whenever you add a `@HiveField` or change a field's type, regenerate — otherwise the binary reader/writer will be out of sync.

**`lib/hive_registrar.g.dart`** is checked in to version control (it has no machine-specific content). Regenerate it any time you add or remove a DBO type. The `HiveDBProvider` registers adapters by calling `Hive.registerAdapters()` which delegates to this file.

**DTO files** live under `lib/features/add_meal/data/dto/` (OFF, FDC, and Supabase FDC subfolders). Regenerate when you add or change API response fields.

**`lib/core/utils/env.g.dart`** is the only generated file that is gitignored. After a fresh clone, run `just build` with a valid `.env` file before the app will compile.

## Localization

Source strings live in `lib/l10n/intl_en.arb` (and locale ARBs for `de`, `cs`, `it`, `pl`, `tr`, `uk`, `zh`). Generated Dart files live in `lib/generated/intl/` and `lib/generated/l10n.dart`.

The generated files in `lib/generated/` are **manually maintained** — do not regenerate them with `intl_translation:generate_from_arb`, as the generator output conflicts with the project's 120-char formatting. Edit them directly when adding strings, then run `just check_intl` to verify CI passes.

Note: `SupportedLanguage` enum (used internally for Supabase FDC column selection) only handles `en` and `de`; all other locales fall back to English.

## Code Style

The project uses a **120-character line width** (configured in `analysis_options.yaml`). The `just format` command targets only `./lib/core ./lib/features ./lib/l10n ./test` — it deliberately excludes `lib/generated/`. Do not run `dart format` on `lib/generated/` files.

## Accessibility identifiers for interactive widgets

Every new interactive widget gets a `Semantics(identifier: 'kebab-case-id')` wrapper so that automated UI drivers (ADB uiautomator on Android, Appium / XCUITest on iOS) can find it by a stable handle and tap by coordinate. The `identifier` parameter is never spoken by TalkBack or VoiceOver — it carries no user-facing label, only a test handle — and on iOS it maps to `accessibilityIdentifier`, so this works cross-platform.

The minimal pattern:

```dart
Semantics(
  identifier: 'feature-action',
  child: <interactive widget>,
)
```

### What's in scope

| In scope (must label) | Out of scope (don't bother) |
|---|---|
| `ListTile` / `InkWell` / `GestureDetector` with an `onTap` | Pure display — `Text`, `Icon`, `Image`, `Divider`, charts |
| Buttons — `ElevatedButton`, `TextButton`, `IconButton`, `FloatingActionButton`, `FilledButton` (when they have `onPressed`) | Layout — `Container` without `onTap`, `Padding`, `SizedBox`, `Row`, `Column` |
| Input — `TextField`, `TextFormField`, `Slider`, `Switch`, `SwitchListTile`, `Checkbox` (the actual checkbox, not its label) | Generated code (`*.g.dart`, `messages_*.dart`, `l10n.dart`) |
| Selection — `ChoiceChip`, `FilterChip`, `RadioListTile`, `SegmentedButton`, `DropdownButton` | Theming, transitions, decorative wrappers |
| Bottom sheets, dialog action buttons (Save/Cancel/OK) | Items inside `ListView.builder` / `GridView.builder` (see below) |

### Naming convention

- `<surface>-<element>` for static screen widgets — `profile-weight`, `nav-home`, `settings-units`, `onboarding-button`.
- `<feature>-<action>` for feature-specific actions — `weight-history-add`, `paste-json-submit`, `recipe-builder-save`.
- `<surface>-<element>-<variant>` for variants — `onboarding-gender-female`, `onboarding-activity-active`, `onboarding-goal-maintain`.

Keep the identifier locale-independent — never include translatable strings in the id.

### Dynamic lists

For widgets built inside a `ListView.builder` / `GridView.builder` (intake cards, meal results, weight log entries, etc.), label the **parent surface** (e.g. `home-meals-breakfast-list`) — not every child. Verifiers scope into the list via the parent identifier, then find the specific item by visible text or `content-desc` via the `_tap_text` helper. This avoids identifier churn when item counts change.

### Dialog action buttons inside system dialogs

Material's `DatePicker`, `AlertDialog`, etc. expose their OK / Cancel buttons via the platform's own accessibility tree — those buttons do not need `Semantics(identifier:)` wrappers. Find them with the existing `_tap_text` helper which checks both `text` and `content-desc` attributes.

### Don't double-up roles

Skip `button: true`, `textField: true`, etc. when the child widget already publishes that role. `ChoiceChip`, `FloatingActionButton`, `TextFormField`, `ElevatedButton`, and `SegmentedButton` all provide their own role semantics — stacking the flag risks TalkBack announcing the role twice ("button, button"). The rule is: `Semantics(identifier: '...', child: widget)` and nothing else, unless one specific gotcha applies (see below).

### The `container: true` gotcha

When the immediate parent of `Semantics(identifier:)` is `Expanded`, a flexible `Container` filling its parent, or any other layout-greedy widget, the Semantics node inherits the parent's bounds rather than the child's render box. `adb shell uiautomator dump` will then report the widget at the entire parent area, and coordinate-based taps land mid-screen instead of on the button.

Symptom: a button you can clearly see at the bottom of the screen reports `bounds=[0,145][1440,3036]` (full screen) in uiautomator. Tapping its computed centre lands in the body of the screen.

Fix:

```dart
Semantics(
  identifier: 'foo',
  container: true,  // <- creates a separate semantic node with tight bounds
  child: widget,
),
```

Or — if `container: true` causes other TalkBack issues — restructure the layout so the Semantics descendant has tight constraints (e.g. wrap the child in `Align(alignment: ...)`).

Always verify with `adb shell uiautomator dump /sdcard/d.xml && adb pull /sdcard/d.xml /tmp/d.xml && grep your-id /tmp/d.xml` after adding a label inside a flex container. Reasonable bounds are tens to a few hundred pixels on each side, not screen-sized.

### Flutter widgets on Android use `content-desc`, not `text`

When inspecting the uiautomator dump, the visible text of Flutter widgets is reported under `content-desc`, not `text`. System dialogs (DatePicker, AlertDialog) use `text`. Test drivers that find widgets by visible label must check both.

### Form fields drift between taps

Flutter `TextField` / `TextFormField` widgets all report screen-wide `bounds` in the uiautomator dump (the `container: true` gotcha applied to every form input). Tapping a field by hard-coded coordinates from an earlier dump only works once — the moment the keyboard pops up, every layout in the form shifts, and the next tap lands on the wrong row.

The `adb-driver.sh` helpers `tap_field_by_hint`, `enter_text_in_field`, and `fill_fields_by_hint` re-dump the UI before every tap and locate the field by its placeholder `hint` attribute (uiautomator dumps the TextField's placeholder there even when there's no `Semantics(identifier:)` on the field). They also hide the keyboard between fields so the next field's hit target is calculated against the post-IME layout, not the pre-IME one.

Use them for any custom-meal / recipe / onboarding flow that fills more than one input:

```bash
source tools/adb/adb-driver.sh
fill_fields_by_hint \
  'Meal name'     'Greek%syoghurt' \
  'Energy (kcal)' '100' \
  'Carbohydrates' '4' \
  'Fat'           '5' \
  'Protein'       '10'
```

Pass `clear` as a third argument to `enter_text_in_field` when overwriting an existing value:

```bash
enter_text_in_field 'Protein' '10' clear
```

### ADB test tooling

Reusable ADB scripts live in `tools/adb/`:

| Script | Purpose |
|--------|---------|
| `adb-driver.sh` | Core driver library: `tap_id`, `wait_for_id`, `enter_text_at`, `_tap_text`, `screenshot`, `list_ids`, plus form-field helpers `tap_field_by_hint`, `enter_text_in_field`, `fill_fields_by_hint`, `clear_focused_field`, `hide_keyboard`. Source from any test script. |
| `walk-onboarding.sh` | Walks the 6-page onboarding flow, lands the app on the main screen. Exports `walk_onboarding()`. Run standalone or source it. |
| `run-branch-tests.sh` | Sequential smoke-test runner for all triage branches: builds a debug APK, installs it, walks onboarding, and runs a branch-specific probe. Produces a pass/fail summary and per-branch screenshots. |

Usage:

```bash
# Source the driver in a one-off script
source tools/adb/adb-driver.sh
wait_for_id 'nav-home' 15 && echo "on main screen"

# Walk onboarding standalone (clears app data first)
DEVICE=1C151FDEE003YJ bash tools/adb/walk-onboarding.sh

# Run the full branch test pass (unattended, ~90 min)
DEVICE=1C151FDEE003YJ bash tools/adb/run-branch-tests.sh
```

`DEVICE` defaults to the first device returned by `adb devices` when not set.

### Enforcement

Convention, not lint. Reviewers call it out on PRs that touch interactive widgets. New widgets without identifiers aren't a merge blocker — but the per-branch feature verifier that lives alongside each branch's work won't be able to drive them, so the forcing function is downstream rather than upstream.

## Architecture

The project follows **Clean Architecture** with a feature-based module structure.

### App startup sequence

`main()` → `initLocator()` → Hive DB init (AES key from `flutter_secure_storage`) → Supabase init → check `UserDataSource.hasUserData()` → route to `onboarding` (first run) or `main` (returning user). Sentry is only enabled in **release mode** and only if the user consented to anonymous data collection during onboarding.

### Directory structure

```
lib/
  core/           # Shared across all features
    data/
      data_source/  # Hive box wrappers (local DB access)
      dbo/          # Hive-annotated database objects (suffixed DBO)
      repository/   # Core repositories (user, intake, config, etc.)
    domain/
      entity/       # Plain domain models (suffixed Entity)
      usecase/      # Business logic operations
    presentation/
      main_screen.dart  # Bottom nav shell (Home / Diary / Profile)
      widgets/          # Shared UI components
    styles/       # Color schemes, typography
    utils/        # locator.dart (DI), hive_db_provider.dart, env.dart, calc/, etc.
  features/       # One folder per screen/flow
    home/         # Dashboard with daily kcal/macro summary
    diary/        # Calendar-based food diary
    profile/      # User stats, BMI, goals
    add_meal/     # Food search (text + barcode) and meal logging
    meal_detail/  # Nutritional detail view for a food item
    edit_meal/    # Edit a logged intake entry
    scanner/      # Barcode camera scanner
    add_activity/ # Log physical activity
    activity_detail/ # View logged activity
    settings/     # App settings, data export/import
    onboarding/   # First-run user setup flow
  generated/      # Intl files — maintained manually (see Localization above)
  l10n/           # Source ARB translation files
```

Each feature follows the same three-layer structure:

- `data/` — DTOs and remote/local data sources
- `domain/` — feature-specific entities and use cases
- `presentation/` — BLoC + screen widgets

### Navigation

Named routes are defined in `NavigationOptions` and registered in `main.dart`. The three main tabs (Home / Diary / Profile) share a single `MainScreen` shell with `NavigationBar`; all other screens are pushed onto the route stack.

### State management

**flutter_bloc** is used throughout. Every screen has a corresponding `*Bloc` with `*Event` and `*State` files.

### Dependency injection

**GetIt** is the service locator. All registrations happen in `lib/core/utils/locator.dart` (`initLocator()`), called once at startup. Registration order matters — data sources first, then repositories, then use cases, then BLoCs.

- **`registerLazySingleton`** — screen-persistent BLoCs (Home, Diary, CalendarDay, Profile, Settings, Onboarding). `HomeBloc` and `DiaryBloc` cross-reference each other via the locator at runtime.
- **`registerFactory`** — per-navigation BLoCs (MealDetail, Scanner, EditMeal, AddMeal, Products, Food, Activities, ActivityDetail, ExportImport). A fresh instance is created each navigation.

### Local database

**hive_ce** (the actively maintained community fork of Hive) is used for all persistent local storage, AES-256 encrypted. The five boxes opened by `HiveDBProvider`:

| Box               | DBO type          | Purpose                                                         |
| ----------------- | ----------------- | --------------------------------------------------------------- |
| `ConfigBox`       | `ConfigDBO`       | App settings: theme, units, kcal adjustment, per-macro % goals  |
| `IntakeBox`       | `IntakeDBO`       | Meal log entries (links to `MealDBO`, typed by `IntakeTypeDBO`) |
| `UserActivityBox` | `UserActivityDBO` | Logged physical activities                                      |
| `UserBox`         | `UserDBO`         | User profile: height, weight, birthday, gender, PAL, goal       |
| `TrackedDayBox`   | `TrackedDayDBO`   | Per-day calorie/macro running totals for diary calendar         |

When adding a new `@HiveType`, assign a unique `typeId`. Check all existing DBOs to avoid collisions — IDs are currently scattered across 0–15+.

### Food data sources

`ProductsRepository` aggregates three sources via `SearchProductsUseCase`:

| Source          | Class             | Notes                                                            |
| --------------- | ----------------- | ---------------------------------------------------------------- |
| Open Food Facts | `OFFDataSource`   | REST API — text search + barcode lookup                          |
| Supabase FDC    | `SpFdcDataSource` | Full-text search on `fdc_food` table; `en`/`de` column selection |
| USDA FDC direct | `FDCDataSource`   | Requires `FDC_API_KEY`; not actively surfaced in the UI          |

`SearchProductsUseCase.searchFDCFoodByString` uses the **Supabase** source, not the direct FDC API.

### Calorie and macro calculations

Calculation utilities live in `lib/core/utils/calc/`:

- **TDEE** — `TDEECalc.getTDEEKcalIOM2005()` (IOM 2005 gender-specific equation). A WHO 2001 formula exists but is unused.
- **Calorie goal** — TDEE + weight-goal adjustment (±500 kcal) + optional user kcal offset + today's burned activity kcal.
- **Macro defaults** — 60% carbs / 25% fat / 15% protein of total kcal goal. Per-macro overrides stored in `ConfigEntity`.
- **MET** — `MetCalc` converts MET × weight × hours to burned kcal for activities.

### Data export / import

Settings screen exports to a `.zip` containing three JSON files (user activities, intakes, tracked days). Import merges from a user-selected zip. User profile data is **not** included in the export.

## Naming Conventions

| Suffix                     | Meaning                                                       |
| -------------------------- | ------------------------------------------------------------- |
| `DBO`                      | Database Object — Hive-annotated local storage model          |
| `DTO`                      | Data Transfer Object — JSON-deserialized API response model   |
| `Entity`                   | Domain model — plain Dart class used in business logic and UI |
| `Bloc` / `Event` / `State` | BLoC pattern state management files                           |
| `Usecase`                  | Single-responsibility business logic class                    |
| `Repository`               | Mediates between data sources and use cases                   |
| `DataSource`               | Direct access to one data store (Hive box or HTTP API)        |
