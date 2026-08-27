# First-timer backlog

Seed list of **good first issues** for OpenNutriTracker. Each item is roughly
one afternoon, has a concrete file list, and avoids product analytics or
external crash dashboards (this app is privacy-first; Sentry is opt-in only).

## How to use this list

1. Turn each section into a GitHub issue (copy the body).
2. Label: `good first issue` (optional: `help wanted`, plus an area label such
   as `a11y`, `i18n`, `docs`, `test`, `deps`, `ui`).
3. One PR per issue. Target **`develop`** (see [CONTRIBUTING.md](../CONTRIBUTING.md)).
4. Read [AGENTS.md](../AGENTS.md) before coding:
   conventional commits, **no AI `Co-authored-by` trailers**,
   `Semantics(identifier:)` on new interactive widgets, and — when strings
   change — an ARB edit under `lib/l10n/` followed by `just gen_l10n`
   (`lib/generated/` is gitignored output, never hand-edited).
5. Prefer `just ci` (or format + analyze + targeted tests) before opening a PR.

These are **tickets to file**, not an implemented roadmap. Refine titles/IDs
against `main`/`develop` when the issue goes public.

---

## 1. Accessibility — label share / export dialog actions

**Suggested title:** `a11y: add Semantics identifiers to share and export dialogs`

**Category:** accessibility

**Why first-timer safe:** Pattern is already used on main nav and FAB in
`lib/core/presentation/main_screen.dart` (`nav-home`, `nav-diary`, …,
`fab-add-item`). Copy/share buttons in share dialogs need the same treatment for
ADB / UI-driver stability.

**Scope:**

| File | What to label (suggested ids) |
| ---- | ----------------------------- |
| `lib/core/presentation/widgets/share_qr_dialog.dart` | Copy code → `share-qr-copy`; Share → `share-qr-share` (Copy-to-profile already has `share-copy-to-profile`) |
| `lib/features/settings/presentation/widgets/export_import_dialog.dart` | Primary export/import action buttons and format segmented control if interactive |
| `lib/features/settings/presentation/widgets/import_custom_food_data_dialog.dart` | Only if you touch the same flow — primary actions for custom food import |


**Acceptance criteria:**

- [ ] Interactive actions that are in scope use `Semantics(identifier: 'kebab-case')` without redundant role flags.
- [ ] Identifiers stay locale-independent.
- [ ] No behaviour change beyond semantics.
- [ ] After installing a debug build, `adb shell uiautomator dump` can find the new ids (reasonable bounds — use `container: true` if flex layout expands the node).

**Out of scope:** Renaming existing nav ids; labeling every list child row.

---

## 2. Localization — activity duration `'min'` suffix

**Suggested title:** `i18n: localize activity edit duration unit suffix`

**Category:** localization

**Why first-timer safe:** One hardcoded English fragment next to already-localized
kcal/kJ labels.

**Scope:**

- `lib/core/presentation/widgets/edit_activity_dialog.dart` — non-custom branch
  uses the literal `'min'` as the quantity field suffix
  (`suffix = … : 'min'`).
- Wire through the ARBs (add a key such as `minuteShortLabel` / reuse a
  suitable existing string if one already means “min” as a unit). Follow
  CONTRIBUTING: add the key to **every** `lib/l10n/intl_*.arb`, then run
  `just gen_l10n`. Nothing under `lib/generated/` goes into the commit — it is
  gitignored output.
- A locale you miss will not fail the build. The key lands in the (gitignored)
  `l10n_untranslated.json` and the string falls back to English, so check that
  file reads `{}` when you are done.

**Acceptance criteria:**

- [ ] No naked `'min'` user-facing string in that dialog.
- [ ] All supported locales have a translation.
- [ ] `l10n_untranslated.json` reads `{}` after `just gen_l10n`.
- [ ] `just ci` (or analyze + tests) passes.

**Out of scope:** Reworking custom-kcal activity editing; new duration units beyond avoiding the hardcode.

---

## 3. Small UI polish — settings padding consistency

**Suggested title:** `ui: normalize settings screen padding via Dimens`

**Category:** UI polish

**Why first-timer safe:** Visual-only; no domain logic.

**Scope:**

- `lib/features/settings/settings_screen.dart` — prefer shared
  `Dimens.spacing*` / existing helpers instead of ad-hoc
  `EdgeInsets.fromLTRB(...)` copies that redo the same 12/16 values by hand.
- Stay consistent with nearby tiles and dialogs in
  `lib/features/settings/presentation/widgets/`.

**Acceptance criteria:**

- [ ] No unexplained magic spacing where an existing `Dimens` token fits.
- [ ] Settings layout looks unchanged at a glance (screenshot optional but nice).
- [ ] `dart format` on touched paths; no drive-by refactors.

**Out of scope:** Redesigning settings IA; theme/color changes.

---

## 4. Test coverage — `MacroCalc` unit tests

**Suggested title:** `test: unit tests for MacroCalc goal helpers`

**Category:** test coverage

**Why first-timer safe:** Pure static functions, no Hive/Flutter binding required.

**Scope:**

- Implementation: `lib/core/utils/calc/macro_calc.dart`
  - `getTotalCarbsGoal`
  - `getTotalFatsGoal`
  - `getTotalProteinsGoal`
  (and any other pure helpers in that file you can cover cheaply)
- New file: `test/unit_test/macro_calc_test.dart`
- Cover default macro percentages vs explicit overrides; include a non-trivial
  kcal total (e.g. 2000 kcal) and assert expected gram totals.

**Acceptance criteria:**

- [ ] Tests fail if goal math regresses (not snapshot-of-nothing assertions).
- [ ] `flutter test test/unit_test/macro_calc_test.dart` passes.

**Out of scope:** Full TDEE / UI widget tests for macro rings.

**Stretch (separate issue if large):** dedicated `test/unit_test/bmi_calc_test.dart`
for `lib/core/utils/calc/bmi_calc.dart`.

---

## 5. Docs — Getting started beyond Windows + Android

**Suggested title:** `docs: add iOS and non-Windows setup to GettingStarted.md`

**Category:** documentation

**Why first-timer safe:** Markdown only; no app code.

**Scope:**

- `GettingStarted.md` today is detailed for **Windows 11 + Android**.
- Add concise sections:
  - **iOS on macOS** — Xcode, CocoaPods/`pod install` notes for `ios/`, signing
    caveat for device runs, open `ios/Runner.xcworkspace` if relevant.
  - **Android on macOS or Linux** — SDK path tips without assuming `e:\…`,
    emulator or physical device.
- Keep FVM (`.fvmrc`), `cp .env.example .env`, `just install` / `flutter pub get`,
  and `just build` / `build_runner` in the golden path.
- Link [CONTRIBUTING.md](../CONTRIBUTING.md) and env notes (`.env` / `envied`).

**Acceptance criteria:**

- [ ] A new contributor on macOS can follow iOS **or** Android steps without
      guessing from Flutter generic docs alone.
- [ ] Windows section remains valid (edit, don’t delete).

**Out of scope:** Full App Store / Play release cookbook (see `RELEASE.md` if needed).

---

## 6. Dependency hygiene — one low-risk bump

**Suggested title:** `chore(deps): bump archive (or adopt Dependabot PR) and verify CI`

**Category:** dependency hygiene

**Why first-timer safe:** Single dependency; CI is the safety net.

**Scope:**

- Candidate: pinned `archive: 4.0.9` in `pubspec.yaml` (no `^` — intentional
  pin; check changelog before jumping major versions). Prefer the **smallest**
  safe bump that still resolves, or shepherd an existing Dependabot PR for
  `pub` / `bundler` / `github-actions` (see `.github/dependabot.yml`).
- Run `flutter pub get`, then `just ci` or at least analyze + tests.
- Do **not** reintroduce invalid Dependabot ecosystems (e.g. raw `cocoapods`).

**Acceptance criteria:**

- [ ] `pubspec.yaml` / lockfile updated consistently.
- [ ] CI green on the PR.
- [ ] Brief PR note: what changed and what you verified.

**Out of scope:** Mass upgrades; Flutter SDK bumps; Fastlane gem churn unless
that’s the Dependabot PR you chose.

---

## 7. Robustness — barcode / EAN edge-case test

**Suggested title:** `test: harden barcode check-digit coverage for invalid inputs`

**Category:** robustness / tests

**Why first-timer safe:** Extends existing unit tests; no device farm required.

**Scope:**

- Existing tests: `test/unit_test/barcode_check_digit_test.dart`,
  `test/unit_test/ean13_check_digit_test.dart`
- Find the production helpers they exercise (under `lib/`, barcode / scanner
  utilities).
- Add cases for: empty string, wrong length, non-digit characters, known bad
  check digit — matching **actual** validation behaviour (document expected
  reject vs clamp; don’t invent product rules).

**Acceptance criteria:**

- [ ] At least two new meaningful cases beyond “happy path”.
- [ ] `flutter test test/unit_test/barcode_check_digit_test.dart test/unit_test/ean13_check_digit_test.dart` passes.

**Out of scope:** Camera scanner UI; Open Food Facts network mocks.

---

## 8. Accessibility — meal detail share entry point

**Suggested title:** `a11y: Semantics identifier for meal detail share action`

**Category:** accessibility

**Why first-timer safe:** Same Semantics convention; touches a real product path
(share meal / QR) without analytics instrumentation (this app intentionally has
no product analytics events).

**Scope:**

- `lib/features/meal_detail/meal_detail_screen.dart` — share (or equivalent)
  control that opens `ShareQrDialog`; give it a stable id such as
  `meal-detail-share` (edit control already uses `meal-detail-edit`).
- Confirm the opened dialog inherits labels from issue **#1** if both land;
  either PR can land first.

**Acceptance criteria:**

- [ ] Share control findable via semantics identifier.
- [ ] No change to share payload / QR content.

**Out of scope:** Adding telemetry, Sentry breadcrumbs, or marketing events.

---

## Filing checklist (maintainers)

When promoting a seed to a live issue:

- [ ] Re-verify the file/line still matches `develop`.
- [ ] Attach `good first issue` + one area label.
- [ ] Link this doc in the issue body: `See docs/first-timer-backlog.md § N`.
- [ ] Avoid assigning until a newcomer claims it (unless mentoring).

## Intentionally not seeded here

| Generic idea | Why skipped / remapped |
| ------------ | ---------------------- |
| Crash dashboard triage | No public crash-dashboard workflow; Sentry is user-opt-in. Use barcode/tests (#7) instead. |
| Product analytics events | Privacy-first: no event catalogue. Use share a11y (#1 / #8) instead. |
| Food database content fixes | Belong on Open Food Facts / backend repo, not app UI tickets (see issue templates). |
