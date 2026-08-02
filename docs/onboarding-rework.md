# Onboarding rework

Resolved spec for the first-run flow (`lib/features/onboarding/`). Written
before the implementation and kept beside it, so the reasoning behind each
decision survives the PR.

The flow is seven pages driven by `IntroductionScreen` in
`onboarding_screen.dart`: intro → gender/birthday → height/weight → activity
→ goal → other options → overview. It runs on first launch **and** whenever a
profile is added (the route then carries a `cancelToProfileId` argument), so
every change below has to hold for both entries.

## What the original brief got wrong

The brief was written from the running app, and four of its bullets describe
problems that are already solved. Worth recording so nobody re-litigates
them:

| Brief said | Actually |
| ---------- | -------- |
| Birthday should be validated | `ValueValidator.getFirstDate/getLastDate` already bound the picker to 130 years and no future dates. The bug is `initialDate`, which opens the picker on *yesterday*. |
| Goal should not be preselected | It already isn't. What's missing is the suggestion. |
| Database should be preselected for the locale | All five selectable sources already default to on, so BLS is already "preselected" for German users. The bullet only changes behaviour by turning sources *off*. |
| Activity should provide more input | Per-option descriptions already exist as l10n strings, hidden behind a `?` dialog. |

## Decisions

### 1. Blocked actions explain themselves

`HighlightButton` passes `onPressed: null` while a page's input is
incomplete, so "Next" is a dead tap on every page. The demo CTA on the intro
page is dead until the privacy checkbox is ticked, which is the case the brief
noticed.

The button stays visually disabled but remains tappable, and a tap while
blocked shows a snackbar naming the missing input. One change in
`HighlightButton` covers all six pages; the demo button gets the same
treatment with its own message.

### 2. Birthday

- The picker opens on **today − 30 years** in `DatePickerMode.year`. A
  birthday is chosen year-first, so the year grid removes the most scrolling
  for everyone, not only for the median user.
- **Hard floor at 13**, enforced by `lastDate`, matching the digital-consent
  age most apps use.
- Ages **13–17** get a non-blocking notice that the calorie figures come from
  adult reference equations. This is true and worth saying: `age` feeds
  `TDEECalc.getTDEEKcalIOM2005`, and the IOM 2005 equations used here are the
  adult ones. Same soft-warning shape as the existing `LowKcalWarningCard`.

### 3. Units are seeded from the locale, unless the user already chose

Flutter exposes no measurement-system flag, so the signal is the country
segment of `Platform.localeName`, read the way `OffCountry.fromLocale` already
reads it:

| Country | Height | Body weight | Food |
| ------- | ------ | ----------- | ---- |
| US, LR, MM | ft/in | lb | imperial |
| GB | ft/in | st | metric (UK food labelling is metric; bodyweight colloquially is not) |
| everything else | cm | kg | metric |

Seeding happens in `UserDataMaskEntity`, not `ConfigEntity`, so persisted
defaults for existing installs are untouched.

**An existing app config always wins.** Units, theme and food-source toggles
live in the *shared app box*, not the per-profile one (see
`ConfigDataSource._readMerged`: only kcal adjustment, macro percentages, meal
shares and the water goal are per-profile). Without this rule, a user who
deliberately switched to lb/st would be handed kg again when adding a second
profile, and saving that profile would write the reverted units back to the
shared box, changing them for the first profile too. The locale heuristic
therefore applies only when the app config is empty, i.e. a genuine first run.

The same rule governs the food databases in section 7.

### 4. Height and weight

**WHO suggestion.** Once both values parse, a card under the optional
target-weight field shows the healthy range for the entered height, together
with the derivation, e.g. *"Healthy range for 180 cm: 60–81 kg (WHO, BMI
18.5–24.9)"*. `BMICalc` already encodes the WHO cutoffs (18.5 / 25).
A chip fills the target field on tap; when the current weight already sits
inside the range, the chip offers the current weight (maintain) rather than
the midpoint.

The field is **never auto-filled**. Putting a number on someone's body weight
unprompted is a different act from offering one, and a pre-filled value is
easy to accept without reading.

**Validation** becomes two-tier and stops firing mid-typing (today `onChanged`
runs `validate()` on every keystroke, so typing `1` toward `180` paints an
error):

| Band | Behaviour |
| ---- | --------- |
| Outside `Ranges` hard bounds (30–300 cm, 2–640 kg) | Inline error on blur or on Next; blocks progress |
| Inside hard bounds, outside plausibility (≈120–230 cm, 30–300 kg) | Keep / Change dialog on blur; the user can proceed |
| Plausible | No interruption |

The hard bounds are wide enough that `3 cm` currently passes as "valid", which
is why the middle band exists.

### 5. Activity

Four full-width selectable cards, each showing its existing one-line
description permanently. Replaces the chip + `?` + dialog arrangement and the
arbitrary `SizedBox(width: 300/400)` wrappers. You need the description in
order to choose, so it belongs before the tap, not after it. Existing
`onboarding-activity-*` identifiers are preserved.

### 6. Goal

Nothing is preselected. A card names the basis and the suggested option
carries a "Suggested" badge.

The suggestion follows the **target weight when one was entered** (below
current → lose, above → gain, within ~1 kg → maintain), and falls back to the
WHO BMI band otherwise, quoting the number and band. Deriving it from BMI
alone would let the app answer "Maintain" to a BMI-24 user who typed a lower
target on the previous screen.

### 7. Other options

- The section-header + `AppCard` grouping already used by `profile_page.dart`
  is extracted into a shared widget and used for all four sections, so
  onboarding looks like the Settings and Profile screens the user lands on
  next instead of inventing a fourth style.
- Food databases collapse into an `ExpansionTile` whose subtitle reports
  *"n of 5 enabled"*, so the state is readable while closed.
- Locale-based database defaults: **de/at/ch** → BLS plus the FDC generic
  sources (`fdc_foundation`, `fdc_sr_legacy`, `fdc_survey`), with
  `fdc_branded` **off**; everywhere else → the FDC set on, BLS off. Open Food
  Facts is always on regardless and carries branded products, so nobody loses
  real coverage. A German user stops seeing US supermarket items, and an
  Italian user stops seeing German-language BLS entries. FDC generic foods
  stay available to German users because `food_translation` surfaces them
  with German names. A stored choice wins over the guess, as with the units.

### 8. Overview

Under the headline number, a compact chain (TDEE → weight-goal adjustment →
daily goal, plus the macro split) and a button that pushes the existing
`KcalGoalInfoScreen`.

That screen is the app's transparency surface already, but its usecase reads
from repositories and onboarding hasn't persisted anything yet. It is
refactored to accept a pre-computed `KcalGoalBreakdownEntity`, which
onboarding builds from `userSelection.toUserEntity()` via
`KcalGoalBreakdownEntity.compute`. One renderer, so the number shown during
onboarding cannot drift from the one Settings shows afterwards.

## Conventions this work follows

- One commit per increment, each independently green.
- New strings land in all nine ARBs, then `just gen_l10n` regenerates
  `lib/generated/`. See the localization section of
  [AGENTS.md](../AGENTS.md).
- Unit tests for the new pure logic (locale mapping, WHO range, goal
  suggestion, plausibility bands, age floor); widget tests for the new
  interactions.
- Existing `Semantics(identifier:)` values are preserved; where a step in
  `tools/adb/walk-onboarding.sh` genuinely changes (the date-picker year grid,
  the collapsed food-sources tile), the script is updated in the same commit.
