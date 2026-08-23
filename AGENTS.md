# AGENTS.md

Guidance for AI coding agents working in this repository. This is the **canonical** agent instruction file. `CLAUDE.md` and `.github/copilot-instructions.md` only point here.

## Project Overview

OpenNutriTracker is a Flutter mobile app (iOS/Android) for nutritional tracking. It uses Open Food Facts and a multi-source Supabase food backend (USDA FoodData Central, German BLS, and more — see the [OpenNutriTracker-Backend](https://github.com/simonoppowa/OpenNutriTracker-Backend) repo) as food databases, with all user data stored locally in an AES-encrypted Hive database.

Flutter version: **3.44.6** (managed via FVM; see `.fvmrc`)

## Commits

- Use [conventional commits](https://www.conventionalcommits.org/) (e.g. `feat:`, `fix:`, `chore:`, `docs:`).
- **Never** add Copilot or any AI assistant as a commit co-author.
- Do **not** include trailers such as:
  - `Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>`
  - any other `Co-authored-by:` line naming Copilot / Copilot CLI / similar agents
- Do not put the assistant's name in the commit subject or body.

## Commands

All common tasks are in the `justfile`:

```sh
just install       # flutter pub get
just build         # dart run build_runner build --delete-conflicting-outputs
just format        # dart format ./lib/core ./lib/features ./lib/l10n ./test
just test          # flutter test
just gen_l10n      # regenerate lib/generated/ from the ARBs (gitignored output)
just ci            # full CI: install, format check, gen_l10n, build, analyze, test
just dev           # fvm flutter run --flavor develop
just dev_seed      # same, but wipes the active profile and seeds a year of demo data — see below
```

### Demo data — the dev seeder and the shipped "try it" onboarding flow

One seeding engine, two callers — a dev-only fixture and a real,
shipped-in-every-build feature:

- **`just dev_seed`** runs a separate entry point, `lib/dev/main_dev.dart`,
  instead of the normal `lib/main.dart`. On every launch it wipes the active
  profile's Hive boxes and reseeds a full year of realistic data — skips
  onboarding entirely, and lands on Home. This is dev-only: `main_dev.dart`
  throws if built in release mode, and it's never referenced from
  `lib/main.dart`, so it can't leak into a shipped build.
- **The onboarding intro screen's "Try it with sample data" link**
  (`lib/features/onboarding/presentation/onboarding_intro_page_body.dart`)
  is a real, shipped feature — a prospective user can seed the same active
  profile with three weeks of always-on-track sample data and jump straight
  to Home, independent of the privacy-policy checkbox. While the active
  profile holds sample data, a persistent banner
  (`lib/core/presentation/widgets/demo_mode_banner.dart`) shows on every tab
  of `MainScreen`; tapping "Set up your profile" wipes it and returns to
  onboarding (mirrors `SettingsScreen._confirmDeleteAllData`'s
  confirm-then-wipe-then-route pattern). Whether the active profile holds
  sample data is tracked by `ConfigEntity.isDemoData`, cleared for free by
  `DeleteAllUserDataUsecase.deleteAll()` (which already wipes the whole
  config box) and defensively re-cleared when real onboarding completes
  (`OnboardingBloc.saveOnboardingData`).

Both callers share [`lib/core/utils/demo/`](lib/core/utils/demo/) — this
is **not** dev-only, since the onboarding flow needs it in every build:

- `demo_seeder.dart` — `seedDemoData(DemoSeedOptions options)`, the
  day-loop/bulk-write engine. `DemoSeedOptions.dev` (365 days, ~10% of days
  deliberately miss the calorie goal, a 15-day guaranteed current streak) vs
  `DemoSeedOptions.onboarding` (21 days, `missedDayProbability: 0.0` so
  every day is on-track by construction — no separate "flattering" content
  needed, just that one dial) is the only thing that differs between the
  exhaustive QA fixture and the public first-impression demo.
- `demo_content.dart` — the food set, activity pool, recipes, and the
  per-day macro-targeting algorithm. Duration-agnostic; reused unchanged by
  both presets.
- `unsplash_attribution.dart` — a small, hand-picked set of Unsplash photo
  ids (not a live search), so seeding needs network access only to fetch
  those fixed URLs (and downloads the profile picture locally); a failed
  lookup just skips that one photo rather than aborting the seed. Also
  carries the photographer-credit lookup and small credit-line widget shown
  on the meal detail screen and the profile editor — see the file's doc
  comment for why hardcoded URLs sidestep Unsplash's stricter API usage
  terms.

Data is generated from a fixed-seed RNG (`demoRng` in `demo_content.dart`),
so re-seeding reproduces the same fixture every time rather than a new
random one.

Run a single test file:

```sh
flutter test test/unit_test/tdee_calc_test.dart
```

Run static analysis:

```sh
flutter analyze
```

## Environment Setup

Copy `.env.example` to `.env` and fill in real values before running:

```sh
cp .env.example .env
```

The template carries placeholders that have no real-world effect — they exist so `envied`'s codegen finds every key on a fresh clone. Replace them:

```
FDC_API_KEY="YOUR_KEY"        # USDA Food Data Central API key (direct FDC source, not actively used in UI)
SENTRY_DNS="DNS_URL"
SUPABASE_PROJECT_URL="PROJECT_URL"
SUPABASE_PROJECT_ANON_KEY="ANON_KEY"
```

`.env` is gitignored (`.gitignore` matches `*.env`), so your real secrets won't be committed accidentally. After editing it, run `just build` to regenerate `lib/core/utils/env.g.dart` (also gitignored). The `envied` package obfuscates all secret values at compile time.

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

**DTO files** live under `lib/features/add_meal/data/dto/` (OFF, FDC, and Supabase `sp` subfolders). Regenerate when you add or change API response fields.

**`lib/core/utils/env.g.dart`** is the only generated file that is gitignored. After a fresh clone, run `just build` with a valid `.env` file before the app will compile.

## Localization

Source strings live in `lib/l10n/intl_en.arb` (and locale ARBs for `de`, `cs`, `it`, `pl`, `sk`, `tr`, `uk`, `zh`). `lib/generated/l10n.dart` plus one `l10n_<locale>.dart` per locale are produced by `flutter gen-l10n`, configured in `l10n.yaml`.

The generated files are **gitignored — never edit them by hand**. Add the key to every ARB (all nine stay at the same key count) and run `just gen_l10n`. Placeholder metadata (`"@key": {"placeholders": ...}`) only needs to be declared in the template `intl_en.arb`.

Note: the `SupportedLanguage` enum maps device locales to `food_translation` locales via `SPConst.translationLocaleOf` (`en` reads `food_summary.name` directly; `de`, `pl`, `zh`, `cs`, `it`, `sk`, `tr`, `uk` query translations, falling back to English).

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
| `walk-onboarding.sh` | Walks the 7-page onboarding flow, lands the app on the main screen. Exports `walk_onboarding()`. Run standalone or source it. |
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

## Row titles must not overflow

Any title or label placed inside a `Row` has to survive a long localized string (German "Frühstück"/"Abendessen" run much wider than the English "Breakfast") and a large system font setting without wrapping to an extra line or triggering the `RenderFlex` overflow stripes. A short label such as a meal-type header quietly wrapping to two lines looks unpolished, so we guard against the whole class rather than fixing it one screenshot at a time.

Three rules cover it:

1. **Flex-constrain the title.** Wrap it in `Expanded` (or `Flexible`) so it can never overflow its `Row`, and don't let it share flex with a competing `Spacer()`. A `Flexible(title)` + `Spacer()` + `Flexible(value)` arrangement splits the width three ways and starves the title — give the title an `Expanded` and place a fixed `SizedBox` before a trailing value instead.
2. **Bound the lines.** Set `maxLines` (usually `1` for a title) and `overflow: TextOverflow.ellipsis` so it can never silently wrap.
3. **Let prominent titles shrink to fit.** For section headers and user-content names, use `AutoSizeText` (already a dependency, `auto_size_text`) with a sensible `minFontSize` rather than a plain `Text`, so a long label scales down to stay on one line and only ellipsizes in the extreme. Plain `Text` with `maxLines` + `ellipsis` is fine for short, secondary numeric labels.

Genuine multi-line body or description copy (disclaimers, helper text) is meant to wrap and is exempt. Like the accessibility-identifier rule above, this is convention rather than lint — reviewers point at it on PRs that add or restructure row-based headers and cards.

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
      demo/       # Shared demo-data engine (seeder + content + Unsplash
                  # attribution) — used by both lib/dev/ and the shipped
                  # onboarding "try it" flow, see "Demo data" above
  features/       # One folder per screen/flow
    home/         # Dashboard with daily kcal/macro summary, water chip, fasting chip
    diary/        # Calendar-based food diary, micronutrient panel, sort controls
    profile/      # User stats, BMI, goals, weight history chart
    add_meal/     # Food search (text + barcode) and meal logging
    meal_detail/  # Nutritional detail view for a food item, with daily kcal banner
    edit_meal/    # Edit a logged intake entry, custom meal create / template
    scanner/      # Barcode camera scanner (with manual entry fallback)
    add_activity/ # Log physical activity, including custom kcal templates
    activity_detail/ # View logged activity
    fasting/      # Intermittent-fasting timer with content-warning gate
    recipes/      # Reusable recipes with photo, brand, ingredient picker
    settings/     # App settings, data export/import, day-start, theme picker
    onboarding/   # First-run user setup flow
  dev/            # Dev-only main_dev.dart entry point (never shipped) — see "Demo data" above
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

**hive_ce** (the actively maintained community fork of Hive) is used for all persistent local storage, AES-256 encrypted. The boxes opened by `HiveDBProvider`:

| Box                            | DBO type / payload          | Purpose                                                              |
| ------------------------------ | --------------------------- | -------------------------------------------------------------------- |
| `ConfigBox`                    | `ConfigDBO`                 | App settings: theme, units, kcal adjustment, per-macro % goals       |
| `IntakeBox`                    | `IntakeDBO`                 | Meal log entries (links to `MealDBO`, typed by `IntakeTypeDBO`)      |
| `UserActivityBox`              | `UserActivityDBO`           | Logged physical activities                                           |
| `UserBox`                      | `UserDBO`                   | User profile: height, weight, birthday, gender, PAL, goal            |
| `TrackedDayBox`                | `TrackedDayDBO`             | Per-day calorie/macro running totals for diary calendar              |
| `CustomMealBox`                | `MealDBO`                   | User-saved custom meals (search index for the food picker)           |
| `RecipeBox`                    | `RecipeDBO`                 | User-saved recipes with photo, brand, ingredients                    |
| `CachedOffMealBox`             | `MealDBO`                   | Open Food Facts response cache for offline / slow-connection use     |
| `CachedOffMealTimestampsBox`   | `int`                       | Cache freshness timestamps for the OFF cache                         |
| `CustomActivityTemplateBox`    | `CustomActivityTemplateDBO` | Reusable templates for custom-kcal activities                        |
| `WeightLogBox`                 | `WeightLogDBO`              | Weight history points for the profile trend chart                    |
| `WaterIntakeBox`               | `WaterIntakeDBO`            | Water log entries powering the home chip                             |
| `FastingBox`                   | `FastingSessionDBO`         | Fasting sessions (current and historical) for the timer              |

When adding a new `@HiveType`, assign a unique `typeId`. Check all existing DBOs to avoid collisions — IDs are currently scattered across 0–30+.

### Food data sources

`ProductsRepository` aggregates three sources via `SearchProductsUseCase`:

| Source           | Class              | Notes                                                                               |
| ---------------- | ------------------ | ----------------------------------------------------------------------------------- |
| Open Food Facts  | `OFFDataSource`    | REST API — text search + barcode lookup                                             |
| Supabase backend | `SpFoodDataSource` | Full-text search on `food_summary` + `food_translation` (multi-source: FDC, BLS, …) |
| USDA FDC direct  | `FDCDataSource`    | Requires `FDC_API_KEY`; not actively surfaced in the UI                             |

`SearchProductsUseCase.searchFDCFoodByString` uses the **Supabase** source, not the direct FDC API. The backend schema and import pipeline live in the [OpenNutriTracker-Backend](https://github.com/simonoppowa/OpenNutriTracker-Backend) repo; users choose which backend sources to search in Settings → Food databases (`SPConst.settingsSelectableFoodSources`).

### Calorie and macro calculations

Calculation utilities live in `lib/core/utils/calc/`:

- **TDEE** — `TDEECalc.getTDEEKcalIOM2005()` (IOM 2005 gender-specific equation). A WHO 2001 formula exists but is unused.
- **Calorie goal** — TDEE + weight-goal adjustment (±500 kcal) + optional user kcal offset + today's burned activity kcal.
- **Macro defaults** — 60% carbs / 25% fat / 15% protein of total kcal goal. Per-macro overrides stored in `ConfigEntity`.
- **MET** — `MetCalc` converts MET × weight × hours to burned kcal for activities.

### Data export / import

Settings screen exports to a `.zip` that bundles intakes, activities, tracked days, and recipes in both JSON (canonical, re-importable) and CSV (flat, for spreadsheets) formats — see [`docs/export-format.md`](docs/export-format.md) for the full schema. Import accepts the same zip and merges its contents into the existing boxes. User profile data (height, weight, birthday, PAL, goal) is intentionally **not** included in the export. Settings → Import also supports a pasted JSON blob for ad-hoc meal imports.

## GitHub issue and PR templates

Issue forms and the PR template live under `.github/`:

| Path | Purpose |
| ---- | ------- |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | Structured bug reports (repro steps, platform, app/OS version, feature area, logs) |
| `.github/ISSUE_TEMPLATE/feature_request.yml` | Feature proposals (problem, solution, alternatives, area/platform) |
| `.github/ISSUE_TEMPLATE/question.yml` | Usage / contributor questions |
| `.github/ISSUE_TEMPLATE/config.yml` | Disables blank issues; contact links (privacy, Open Food Facts, Discussions) |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR checklist: summary, type, test plan, semantics IDs, l10n, codegen, no secrets |

When filing issues or opening PRs, prefer these templates. Product/food-database data errors belong on Open Food Facts (or the backend repo), not app bug reports — the forms call this out in their checklists.

Blank issues are disabled (`blank_issues_enabled: false`). Add or edit YAML forms in `.github/ISSUE_TEMPLATE/`; keep labels (`bug`, `enhancement`, `question`) aligned with any repo label setup.

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
