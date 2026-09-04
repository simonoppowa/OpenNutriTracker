# Demo data — the dev seeder and the shipped "try it" onboarding flow

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
  to Home, but only with the privacy-policy checkbox ticked, the same bar as
  Start — tapping it unchecked just explains itself in a snackbar and seeds
  nothing, so no path into the app skips policy acceptance. The checkbox
  that is independent is the data-collection one: crash reporting stays off
  (and locked) while demo data is active.
  While the active profile holds sample data, a persistent banner
  (`lib/core/presentation/widgets/demo_mode_banner.dart`) shows on every tab
  of `MainScreen`; tapping "Set up your profile" wipes it and returns to
  onboarding (mirrors `SettingsScreen._confirmDeleteAllData`'s
  confirm-then-wipe-then-route pattern). Whether the active profile holds
  sample data is tracked by `ConfigEntity.isDemoData`, cleared for free by
  `DeleteAllUserDataUsecase.deleteAll()` (which already wipes the whole
  config box) and defensively re-cleared when real onboarding completes
  (`OnboardingBloc.saveOnboardingData`).

Both callers share [`lib/core/utils/demo/`](../lib/core/utils/demo/) — this
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
