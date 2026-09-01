# What is still unknown before the AI work starts

A gap analysis, written 2026-08-02 as the fourth and last of the AI research
documents, after
[`ai-in-open-source-nutrition-trackers.md`](ai-in-open-source-nutrition-trackers.md)
(the cohort survey),
[`ai-legal-constraints.md`](ai-legal-constraints.md) (the legal survey) and
[`ai-cohort-restrictions.md`](ai-cohort-restrictions.md) (the restrictions
analysis), against the design in
[#599](https://github.com/simonoppowa/OpenNutriTracker/issues/599) as revised in
its three comments, the tier-0 sub-issues
[#600](https://github.com/simonoppowa/OpenNutriTracker/issues/600) /
[#601](https://github.com/simonoppowa/OpenNutriTracker/issues/601) /
[#602](https://github.com/simonoppowa/OpenNutriTracker/issues/602), and the
approved implementation plan.

The three earlier documents each end with a "Not verified" / "Still open" list.
Those lists were the starting inventory, not the answer: several items on them
had already been closed by a later document, several were never research
questions at all, and the items that actually threaten the build were on none of
them. This document sorts every open question by **what it blocks**, closes the
ones that were cheap and decisive to close, and says plainly where a route
failed.

Every item is labelled:

- **Research** — an answer exists somewhere; we had not found it.
- **Decision** — no external answer exists. The maintainer has to choose.
- **Legal** — needs a lawyer, not more reading.

## Bottom line up front

**Tier-0 coding can start today.** Nothing in the legal, licensing, F-Droid or
provider-terms surface touches #600/#601/#602, and
[`ai-cohort-restrictions.md`](ai-cohort-restrictions.md) F1 already established
that. What it did not establish, because nobody read the code the issues depend
on, is that **three of the tier-0 issues contain spec errors that will produce
wrong numbers or unusable instructions if they are implemented as written.**
None of them is a blocker in the sense of "stop"; all three are twenty-minute
edits to the issue bodies that should happen before a first-time contributor
picks one up.

The three:

1. **#600 tells the parser to emit `kg` and `l`. The app has no such units.**
   `UnitDropdownItem` has exactly six members and neither of those is one of
   them, and its `fromString` falls through to `g/ml`. #600's own headline test
   case, `1,5 l milk`, therefore logs **1.5 grams of milk instead of 1500 ml** —
   a 1000× understatement, silently.
2. **The relevance ranker scores morphological variants at exactly 0.0.** There
   is no stemming anywhere in the search stack, so the query `eggs` scores
   `0.0` against a database record named `Egg` while scoring `0.29` against
   *Cadbury Creme Eggs*. #601 auto-selects the top candidate. The failure mode
   the plan tells you to test for — a query that matches nothing — is not the
   dangerous one; the dangerous one is a query that matches the wrong thing
   confidently.
3. **The plan's and #602's localization instructions describe a repository that
   no longer exists.** They say to hand-edit `lib/generated/intl/` and verify
   with `just check_intl`. That directory does not exist, that recipe is not in
   the justfile, and the current `AGENTS.md` says the exact opposite. The
   instructions are copied from a pre-`gen-l10n` AGENTS.md that survives only in
   a stale worktree.

Beyond tier 0: **five of the six named research gaps closed today**, including
the one everything else was dated against. The F-Droid blocker
([RFP #2540](https://gitlab.com/fdroid/rfp/-/issues/2540)) now has a concrete,
current, working exemplar with the exact build recipe — and it is
*cheaper* than `ai-cohort-restrictions.md` C7 estimated, and does not use a
Gradle build flavour at all.

## The table

| # | Gap | Blocks | Kind | Cost to close | Status |
| :-- | :-- | :-- | :-- | :-- | :-- |
| **T1** | #600 emits `kg` / `l`; the app's unit vocabulary has neither, and the fallback is a silent 1000× error | **Tier 0 (#600, #602)** | Decision | 20 min issue edit | **Closed today** — diagnosed; the choice remains |
| **T2** | #600 segments on `,` and accepts `,` as a decimal separator, with no precedence rule | **Tier 0 (#600)** | Decision | 10 min issue edit | Open (found by `ai-cohort-restrictions.md` F2) |
| **T3** | No stemming anywhere in the search stack; plural queries score 0.0 and sink below noise | **Tier 0 (#601 contract, #602 acceptance)** | Research → Decision | Closed by code reading; one fixture test to size | **Closed today** |
| **T4** | `addIntake` does an unguarded `double.parse`; a batched "Log all" has no validation, no atomicity, and bypasses the #212 duplicate guard | **Tier 0 (#602)** | Decision | 30 min issue edit | **Closed today** — diagnosed |
| **T5** | Plan §5 / #602 l10n instructions target a directory and a `just` recipe that do not exist | **Tier 0 (#602)** | Research | Closed by reading the repo | **Closed today** |
| **T6** | `just ci` cannot pass locally; the plan makes it the verification gate | **Tier 0 (both)** | Research | Closed by reading the repo | **Closed today** |
| **T7** | Parser emits unbounded decimals; the review field's formatter caps at 2 dp | Tier 0 (#600) | Decision | 5 min | **Closed today** — diagnosed |
| **S1** | Digital Omnibus deferral, Reg. (EU) 2026/1744 — the timeline everything is dated against | Tier 1 scoping | Research | Closed via EUR-Lex | **Closed today** |
| **S2** | Anthropic: image content-part + `output_config.format` in one request | Tier 2 build (not tier-1 scoping) | Research | Docs read; one live call (~$0.003) for certainty | **Partially closed today** |
| **S3** | Decision #5 — Train Libre posture vs. accepting the 1.4.1 risk | Tier 1 scoping | **Decision** | Free; the evidence is already gathered | Open — and no research will close it |
| **S4** | No request timeout anywhere in the design; a local endpoint needs minutes | Tier 1 scoping | Decision | 10 min | Open (found by `ai-cohort-restrictions.md` E1) |
| **S5** | OpenAI Services Agreement §2.2 / §3.3(g) — the BYO-key blessing #599 cites | Tier 1 scoping (weakly) | Research | Blocked; route failed | **Open — route failed** |
| **S6** | OpenAI Usage Policies currency (quoted from a 9-month-old Microsoft mirror) | Tier 1 scoping (weakly) | Research | Blocked by the same 403 | Open |
| **S7** | Is the project an AI Act "provider" at all? | Tier 1 scoping | **Legal** | Paid consultation | Open |
| **S8** | Does the Art. 111(4) four-month transitional reach a feature released after 2 Aug 2026? | Release | **Legal** | Same consultation | Open — EUR-Lex truncates |
| **S9** | Does Art. 50(2)'s "does not substantially alter … the semantics" exception cover tier 1? | Tier 1 scoping | **Legal** | Same consultation | Open |
| **R1** | Play in-app reporting/flagging requirement for AI-generated content | Release (tiers 1–2) | Research | Closed via Google's support site | **Closed today** |
| **R2** | Apple 5.1.2(i) and the "third-party AI" clause | Release (tiers 1–2) | Research | Closed via developer.apple.com | **Closed today** |
| **R3** | MDCG 2019-11 wellness/fitness exclusion | Release | Research | Closed via the Commission's health domain | **Closed today** |
| **R4** | Play Health disclaimer absent from the store listing | Release — **live today, unrelated to AI** | Decision | One paragraph | Open (found by `ai-legal-constraints.md`) |
| **R5** | Current Play content rating, Apple age rating, Health apps declaration, Impressum reachability | Release | **Decision, misfiled as research** | 5 min in the consoles | Open |
| **N1** | The F-Droid ML Kit escape route — what Open Food Facts actually ships | Nothing (but blocks RFP #2540) | Research | Closed via fdroiddata | **Closed today** |
| **N2** | Whether a free-software scanner covers every symbology the app needs | Nothing | Research | Closed by code reading | **Closed today** |
| **N3** | Does #602's bloc need a new dev dependency (`bloc_test`)? | Nothing | Research | Closed by reading `test/` | **Closed today** — no |
| **N4** | `GPL-3.0-only` vs `-or-later`; Unsplash demo assets; `minSdkVersion` resolution | Nothing | Decision ×2, Research ×1 | Cheap | Open |

Twenty-four gaps. **Thirteen closed today**, two of them partially. Of the eleven
still open, **three need a lawyer, four are decisions with no external answer,
two are blocked by a 403, and two are cheap lookups the maintainer can do faster
than any researcher.**

---

## A. What blocks tier 0

Tier 0 is a deterministic parser plus a resolver plus a review screen. No model,
no key, no network destination that is not already in the README's table, no new
dependency. `ai-cohort-restrictions.md` F1 verified that no licence, F-Droid or
provider-terms restriction attaches to any of it, and nothing found today
changes that.

**So the answer to "can coding start today" is yes.** What follows are not
reasons to wait. They are errors in the issue text that will cost a contributor
a wasted PR if they are not fixed first — and one of them ships a wrong number
to the user.

### T1 — #600's unit set does not exist in this app. Decision.

`UnitDropdownItem`
([`meal_detail_bloc.dart:248-288`](../lib/features/meal_detail/presentation/bloc/meal_detail_bloc.dart))
has exactly six members, and its `toString()` — which is what is persisted as
`IntakeEntity.unit` — yields exactly six strings:

```
'g'   'ml'   'g/ml'   'oz'   'fl.oz'   'serving'
```

There is **no `kg` and no `l`**. And `fromString` ends:

```dart
default:
  return UnitDropdownItem.gml;
```

The conversion in `UpdateKcalEvent` (same file, lines 69-80) scales only
`serving`, `oz` and `flOz`; anything else passes through **unscaled**.

#600 says, twice:

> Key off digits and unit **symbols** (`g`, `kg`, `ml`, `l`, `oz`) …

and its test checklist asks for:

> - [ ] Comma decimal (`1,5 l milk`) and period decimal (`1.5 l milk`)

Put together: `1,5 l milk` parses to `quantity: 1.5, unit: 'l'`. The review row
cannot render `'l'` in the dropdown (it is not among the items), and whatever
reaches `addIntake` resolves through `fromString`'s `default` branch to `g/ml`,
unscaled. **1.5 g of milk is logged where 1500 ml was meant.** Because the
number is plausible-looking and the unit is not shown prominently on the diary
row, this is exactly the class of bug that does not get reported.

This is a **decision**, and there are two clean answers:

- **(a) Normalise in the parser.** `kg` → `g` × 1000, `l` → `ml` × 1000, and
  never emit a unit string the app cannot represent. Roughly five lines, and it
  keeps `1,5 l milk` working as the test intends. This is the right answer.
- **(b) Drop `kg` and `l`** from the accepted symbol set and reject those
  segments with an indexed error.

Either way the choice has to be written into #600 **before** the parser is
coded, because the acceptance test list currently encodes the broken
expectation. Add a test asserting the emitted unit is always a member of the
six-string set — that is the invariant, and it is the one the issue is missing.

Note that `oz` needs no work (`UnitDropdownItem.oz.toString()` is `'oz'`), and
`fl.oz` is not in #600's symbol list at all, which is fine.

### T2 — The comma still has no precedence rule. Decision.

Already found and correctly characterised at `ai-cohort-restrictions.md` **F2**;
recorded here only because it is a tier-0 blocker of exactly the same shape as
T1 and should be fixed in the same edit. The obvious rule — *a comma flanked by
a digit on both sides is a decimal point; every other comma is a separator* —
costs one regex and one test (`1,5 l milk, 2 eggs`). Seven of the nine shipped
locales use the comma decimal, so this is not an edge case.

### T3 — The search stack has no stemming, and the ranker scores plurals at zero. Research, now closed.

**Nobody has looked at this.** #601 assumes `searchOFFProductsByString` +
`searchFDCFoodByString` + `mergeAndRankMeals` return usable candidates for
inputs like `toast`, `eggs`, `black coffee`. Reading the code, they do — for
one of those three, and not for the other two, for a reason that is arithmetic
rather than empirical.

**The mechanism.** `_textScore`
([`meal_relevance_ranker.dart:155-177`](../lib/features/add_meal/util/meal_relevance_ranker.dart)):
exact normalised equality returns `1.0`; otherwise the score is a Dice
coefficient over token **sets**, plus `0.2` if the text contains the query as a
substring, plus `0.15` if it starts with it, clamped to `0.9`. `_tokenize`
splits on `[^\p{L}\p{N}]+`. There is **no stemming, no lemmatisation and no
singular/plural folding anywhere in the file.**

**The zero case.** Query `eggs` against a record named `Egg`:

- token sets `{eggs}` ∩ `{egg}` = ∅ → Dice `0.0`
- `'egg'.contains('eggs')` → false → no contains-bonus
- `'egg'.startsWith('eggs')` → false → no prefix-bonus
- **score `0.0`**

Meanwhile `Cadbury Creme Eggs` (3 tokens) scores `2·1/(3+1) + 0.2 = 0.45`.
`rankMealsByRelevance` uses a **stable `mergeSort` and filters nothing**, so the
correct answer is retained but sinks below the noise. #601's `ResolvedMealItem`
carries a `selectedIndex`, and the review screen prefills from it. **The plural
form of a common food auto-selects the wrong food.**

**It compounds in three places.**

1. **Local sources.** `SearchProductsUseCase._buildResult`
   ([`search_products_usecase.dart:218-222`](../lib/features/add_meal/domain/usecase/search_products_usecase.dart))
   filters custom meals, recipes, intake history and the 90-day cache with
   `_mealMatchesSearch`, a plain `String.contains`. Same failure, upstream of
   the ranker: a user's own custom meal named `Egg` is **invisible** to the
   query `eggs`. This matters more than the remote case, because own content is
   the tier `mergeAndRankMeals` deliberately ranks above everything else.
2. **The remote asymmetry.** [`sp_const.dart:51-52`](../lib/features/add_meal/data/dto/sp/sp_const.dart):

   ```dart
   static const foodNameFtsConfig = 'english';
   static const translationFtsConfig = 'simple';
   ```

   Postgres' `english` text-search configuration **does** stem, so the Supabase
   name search finds `egg` for the query `eggs` server-side — and the client
   ranker then scores that row `0.0` and buries it. That is the worst possible
   shape: the backend does the right thing and the client undoes it. The
   `simple` configuration used for the eight non-English locales does **not**
   stem, so those locales lose the match at both ends.
3. **The score is discarded.** `mergeAndRankMeals` returns a bare
   `List<MealEntity>`; `scoreMealRelevance` is public but the merge path throws
   its output away. So #601 as specified **cannot** expose a confidence signal
   to the review screen even if it wanted to. That is a scoping consequence
   worth writing into the issue.

**The multi-token degradation, worked from the code.** Query `black coffee`:

| Candidate name | Tokens | Dice | contains | Total |
| :-- | --: | --: | --: | --: |
| `Black Coffee` | 2 | — | — | **1.00** (exact) |
| `Nescafé Black Coffee Instant Refill 200g` | 6 | 2·2/(6+2) = 0.50 | +0.20 | **0.70** |
| `Coffee` | 1 | 2·1/(1+2) = 0.667 | — | **0.667** |

The six-token branded product **outranks the generic entry**, because the
contains-bonus rewards names that embed the whole query phrase and the generic
one-word entry cannot earn it. For a bulk-logging feature whose whole point is
generic foods, that is backwards.

**But the prompt's hypothesis is only half right.** Dice does *not* degrade for
short queries in general. For a single-token query it behaves well, because
`2·1/(n+1)` monotonically penalises long names — which is exactly the
"shortest matching name wins" heuristic you want:

| Query `toast` vs | Tokens | Score |
| :-- | --: | --: |
| `Toast` | 1 | **1.00** (exact) |
| `Toast bread` | 2 | 0.667 + 0.2 + 0.15 → capped **0.90** |
| `Nutella Toast Spread Hazelnut 400g` | 5 | 0.333 + 0.2 = **0.53** |

So `toast` is fine. The failure is specific and nameable: **(a) morphological
variants, where the score collapses to exactly zero, and (b) multi-token generic
queries, where the contains-bonus rewards long branded names.** `2 eggs` — the
plan's own worked example, and the first token of the outcome sentence
*"Type `2 eggs, 100g toast, black coffee`"* — hits both.

**What this blocks.** Not #600, and not #601's *contract* — the resolver is a
thin wrapper and its signature is unaffected. It blocks **#602 being accepted**,
and it changes what "done" means for #601. Concretely, the plan's verification
step 4 says:

> **Check the negative case explicitly** — a query that matches nothing must
> produce a flagged row with a working fallback, not a silent drop and not a
> crash.

That is the *safe* negative case. The unsafe one is a query that matches the
wrong thing with no visible signal that it did. #602 should require a
candidate-picker affordance on every row (it already does) **and** a rule for
when not to auto-select.

**The test that would settle it — and it is not a network test.** Build a
`List<MealEntity>` fixture of ~30 realistic product names (hand-written, or
captured once from a real search and checked in under `test/fixture/`), then
assert `mergeAndRankMeals(off, sp, q).first` for `q ∈ {toast, eggs, egg,
black coffee, coffee, milk, chicken breast}`. Pure unit test, no network, no
device, and it belongs in #601 as an acceptance criterion. Sizing *recall* —
whether the OFF and Supabase APIs return the generic entry for `toast` at all —
does need one live query, but that can be done once by hand and recorded; the
test suite must not depend on it.

**Cheapest mitigation, no further research required:** singularise the query in
the parser (strip a trailing `s` when the stem is ≥3 characters and re-query on
zero results), *or* add the same normalisation inside `_tokenize`. The second is
better — it fixes the local `_mealMatchesSearch` path too — but it changes the
ranker's behaviour for every existing search screen, which makes it a bigger
change than tier 0 wants. This is a **decision**, and it should be taken in
#601 rather than discovered in review.

### T4 — Batched logging has no validation, no atomicity, and skips the duplicate guard. Decision.

[`meal_detail_bloc.dart:164`](../lib/features/meal_detail/presentation/bloc/meal_detail_bloc.dart):

```dart
final quantity = double.parse(amountText.replaceAll(',', '.'));
```

Unguarded `double.parse`, not `tryParse`. In the existing single-item flow this
is safe because `MealDetailBottomSheet.onAddButtonPressed` validates first
(lines 255-284: `double.tryParse`, then `<= 0`, then `> 10000`, each with its
own snackbar). The bloc method itself trusts its caller.

#602 says to call `addIntake` in a loop and explicitly **not** to reach for
`AddIntakeUsecase`. Three consequences it does not mention:

1. **One malformed row throws mid-batch.** Rows already processed have been
   written; there is no rollback and no transaction. The user sees a partial log
   and an exception.
2. **The `> 10000` and `> 0` bounds live in the widget, not in a reusable
   validator.** #600 and #602 both say to "lift" them. There is nothing to lift
   — they are inline `if` statements with `ScaffoldMessenger` calls. The bulk
   screen has to re-implement the check (or, better, extract it once and have
   the bottom sheet use it too).
3. **`_checkForDuplicate` / `_showDuplicateDialog` are bypassed entirely.** That
   guard exists because of issue #212. A "Log all" button that calls `addIntake`
   directly silently drops it. Whether a bulk flow *should* prompt per duplicate
   is a real UX decision — prompting three times in a row is worse than not
   prompting — but it should be taken deliberately and recorded in #602, not
   inherited by omission.

The fix is small: validate every row **before** the loop, refuse to start if any
row fails, and state the duplicate-guard policy in the issue.

### T5 — The localization instructions describe a repository that no longer exists. Research, closed.

Plan §5 and #602's Localization section both say:

> Then edit `lib/generated/intl/` **by hand** — AGENTS.md is explicit that
> regenerating breaks the 120-char formatting — and confirm with
> `just check_intl`.

Every clause of that is false today:

| Claim | Reality |
| :-- | :-- |
| `lib/generated/intl/` | **Does not exist.** `lib/generated/` contains `l10n.dart` plus nine `l10n_<locale>.dart` files and no subdirectories. |
| Edit by hand | [`AGENTS.md:150`](../AGENTS.md): "The generated files are **gitignored — never edit them by hand**. Add the key to every ARB (all nine stay at the same key count) and run `just gen_l10n`." |
| AGENTS.md says regenerating breaks formatting | It says the opposite. The quoted sentence exists only in `.claude/worktrees/agent-a19e62d780bb333aa/AGENTS.md:150`, a stale pre-migration copy. |
| `just check_intl` | **Not a recipe in the justfile.** The recipes are `install build format gen_l10n test ci create_emulator start_emulator dev dev_seed`. |

The repository migrated from `flutter_intl` (which generated
`lib/generated/intl/messages_*.dart` and needed hand-maintenance) to
`flutter gen-l10n` (configured in [`l10n.yaml`](../l10n.yaml), output
gitignored at [`.gitignore:42`](../.gitignore)). The plan and #602 were written
against the pre-migration instructions.

**Correct instruction for #602:** add the key to all nine ARBs — verified today
at **921 keys each, zero drift** — then run `just gen_l10n`. Nothing under
`lib/generated/` is committed.

**This is also a live repo bug outside this feature.**
[`CONTRIBUTING.md:58`](../CONTRIBUTING.md) still tells contributors:

> **Verify with `just check_intl`** — this is what CI runs and will fail the PR
> if any of the above is missing or out of sync.

and [`docs/first-timer-backlog.md:73,79`](first-timer-backlog.md) repeats it
twice. Both statements are false, and #600 / #602 are explicitly labelled
first-timer issues, so a new contributor will hit this before they hit anything
in the plan.

### T6 — `just ci` cannot pass locally. Research, closed.

The plan's Verification step 2:

> **Full gate** — `just ci` (install, format check, intl check, build_runner,
> analyze, test). Note CI itself skips the format check but runs
> `flutter analyze` and `flutter test`.

The justfile:

```
ci: install (format "--set-exit-if-changed") gen_l10n build && test
  flutter analyze
```

The format check is *inside* `just ci`, and
[`.github/workflows/default_workflow.yml`](../.github/workflows/default_workflow.yml)
explains why CI does not use the recipe:

> `just ci` would also run `dart format --set-exit-if-changed`, but the codebase
> currently has accumulated pre-existing format drift from the period when CI
> was disabled. We run the rest of `just ci` (l10n generation, build_runner,
> analyze, test) and leave the format pass for a dedicated follow-up PR.

CI therefore calls `just install`, `just gen_l10n`, `just build`,
`flutter analyze` and `just test` individually. A contributor following the plan
will run `just ci`, watch it fail at step two on files they never touched, and
have no way to tell that the failure is pre-existing. Both #600 and #602 should
say: run the individual recipes, matching CI. There is also no "intl check"
step in `just ci` at all — `gen_l10n` regenerates rather than verifying.

### T7 — Decimal precision round-trip. Decision.

[`meal_detail_bottom_sheet.dart:126-130`](../lib/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart)
applies `FilteringTextInputFormatter.allow(RegExp(r'^\d+([.,]\d{0,2})?$'))` —
**at most two decimal places, no leading `.`, no sign**. #600 and #602 both say
to lift it. #600 states no precision cap on the parser's `double?`, so
`1.333 kg` parses and then cannot be typed or corrected in the field it lands
in.

Separately and pre-existing: `UpdateKcalEvent` emits
`totalQuantityConverted: convertedQuantity.toString()`, an unrounded Dart double
(1 oz becomes `28.349523125`), which the same formatter would reject. #602
inherits this the moment it copies the bottom sheet's `addIntake` call shape.
Cheapest fix: have the parser round to two decimals and say so in #600.

---

## B. What blocks tier 1 being scoped

### S1 — The Digital Omnibus deferral. **Closed today.**

This was flagged in #599's third comment as the one to confirm first:

> The Digital Omnibus deferral (Reg. (EU) 2026/1744) said to push Annex III
> high-risk obligations to Dec 2027. **This is the timeline claim everything
> else is dated against — confirm it first.**

**Confirmed against EUR-Lex.** The ELI record
[`eli/reg/2026/1744/oj/eng`](https://eur-lex.europa.eu/eli/reg/2026/1744/oj/eng)
resolves to:

> Regulation (EU) 2026/1744 of the European Parliament and of the Council of
> 8 July 2026 amending Regulations (EU) 2024/1689, (EU) 2018/1139 and
> (EU) 2023/1230 as regards the simplification of the implementation of
> harmonised rules on artificial intelligence (Digital Omnibus on AI)

and the deferral dates are as `ai-legal-constraints.md` states:

- Chapter III Sections 1–3 for **Annex III** high-risk systems → **2 December 2027**
- Chapter III Sections 1–3 for **Annex I** high-risk systems → **2 August 2028**

with the stated rationale, verbatim from recital 40 of the OJ text:

> the delayed availability of standards, common specifications, and alternative
> guidance and the delayed establishment of national competent authorities lead
> to challenges that jeopardise the effective entry into application

**And the load-bearing point holds: Article 50 was not deferred.** The only
change to Article 50 in the Omnibus is to **Article 50(7)** — the Commission's
implementing-act empowerment over codes of practice, replaced with "The
Commission shall encourage and facilitate the drawing up of codes of
practice…". Article 50(1)–(5) are untouched, and the general date of
application, 2 August 2026, stands. So the marking duty in Article 50(2) is
**in force as of today** and is not covered by the high-risk deferral.

That is the whole of what the timeline claim needed. `ai-legal-constraints.md`'s
application-timeline table can be treated as verified on this point.

**What could not be retrieved, and why:** the *operative* amended text of
Article 113, and the Article 111(4) transitional that
`ai-legal-constraints.md` quotes. EUR-Lex's HTML rendering truncates
mid-sentence in Article 63 on every route tried —
`legal-content/EN/TXT/HTML/?uri=OJ%3AL_202601744` and
`?uri=CELEX:32026R1744` both stop at the same place ("…without affecting the
level of protection or the need for compl"). This is the same truncation
behaviour #599's third comment already recorded for the consolidated AI Act
text. The confirmation above therefore rests on the ELI record and recital 40,
both on `eur-lex.europa.eu` and both primary; the Article 111(4) quote in
`ai-legal-constraints.md` remains **unverified**, and it is a lawyer question
anyway (see S8).

### S2 — Anthropic: image + `output_config.format` in one request. **Partially closed today.**

The plan calls this "documented only by inference" and "the load-bearing
assumption of the photo path", and #599 makes it one of two spikes that "must
land before either tier is scoped". Documentation only was checked today; no
API call was made and no key was used.

What the three relevant pages say:

- **[Structured outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)**
  — does not mention images, vision, or content blocks **at all**. Its
  limitations section is entirely about JSON Schema features (no recursive
  schemas, no numerical or string constraints, `additionalProperties` must be
  `false`, `minItems` only 0 or 1, no external `$ref`), and ends "If you use an
  unsupported feature, you'll receive a 400 error with details." **No content-type
  restriction is stated.**
- **[Vision](https://platform.claude.com/docs/en/build-with-claude/vision)** —
  does not mention structured outputs, `output_config`, or JSON schemas at all.
  Its Limitations section lists people identification, accuracy, spatial
  reasoning, counting, AI-generated-image detection, inappropriate content and
  healthcare. **No request-parameter restriction is stated.**
- **[Messages API reference](https://platform.claude.com/docs/en/api/messages/create)**
  — this is the most useful of the three and neither earlier document consulted
  it. The endpoint description is:

  > Send a structured list of input messages **with text and/or image content**,
  > and the model will generate the next message in the conversation.

  and `output_config` is documented as a **top-level body parameter**, sibling to
  `messages`:

  > `output_config: optional OutputConfig` — Configuration options for the
  > model's output, such as the output format.
  > … `format: optional JSONOutputFormat` — A schema to specify Claude's output
  > format in responses.

**Conclusion.** The two things are orthogonal in the documented request schema:
`output_config` constrains the *response*, image blocks are *request* content,
and no page in the documentation states or implies an incompatibility. That is
materially stronger than "documented only by inference" — but it is still not a
positive statement that the combination is supported, and Anthropic's docs do
not enumerate valid combinations, so silence is not a guarantee.

**Re-scoping this gap:** it no longer blocks tier 1 being **scoped**, only
tier 2 being **built**. #599 lists it as a blocker on scoping *either* tier;
that is now over-cautious. One live call at roughly $0.003 settles it, and it
should be the first thing the tier-2 branch does, not a prerequisite for
writing the tier-1 issue.

Two related corrections while on this page, both to `ai-cohort-restrictions.md`
**E3**, which is otherwise accurate:

- The per-request image cap is **100 for models with a 200k-token context window
  and 600 for all others**, not 20. The 20 is the threshold *above which* a
  stricter per-image dimension limit applies ("either resize each image so that
  neither dimension exceeds 2000 px, or keep the request to 20 or fewer image
  and document blocks"). Immaterial for single-image requests.
- The high-resolution tier is described as "Claude 4.7 and later models" at
  2576 px / 4784 visual tokens; standard is 1568 px / 1568 tokens. The plan's
  arithmetic for a 1024×1024 WebP still checks out at ⌈1024/28⌉² = 37² = **1369
  visual tokens**.

The second #599 spike — **WebP q80 vs q90 on nutrition labels** — remains open
and is not a research question. Anthropic's warning is already quoted verbatim
in `ai-cohort-restrictions.md` E3 and on the vision page ("this can introduce
artifacts that are detrimental to model performance… heavy JPEG compression can
make text difficult to read… Confirm your compression settings are appropriate
for the task by inspecting the actual images sent to the API"). No amount of
reading will produce the answer for *our* pipeline; it is an experiment, and it
belongs to tier 2.

### S3 — Decision #5 is a decision, not a research gap. Open, and no research will close it.

#599's first comment says tier 1 "should not be scoped until decision #5 is
re-settled — either by adopting the Train Libre posture (model names foods,
database supplies numbers), or by explicitly accepting the store-review risk
with a rationale recorded here."

That is stated correctly. It is worth restating here because it is the single
thing actually blocking tier-1 scoping and it is **not waiting on information**.
The evidence is complete: the cohort survey established what every comparator
does (Train Libre bans model-emitted numbers outright, Scranbook computes
locally from bundled composition data, EatWise ships only ranges); #250's spike
supplied the measured accuracy argument; `ai-cohort-restrictions.md` E4 supplied
the only external accuracy datum (fud-ai#157: "the reported calories varied by
about 900 ± 300 kcal" across ten identical prompts); and #599's second comment
already narrowed the exposure to database-miss rows. Nobody needs to read
anything else. **Someone needs to choose.**

### S4 — The timeout. Decision.

`ai-cohort-restrictions.md` **E1** established this and characterised it
correctly as a hard blocker for the local-endpoint story rather than a bug.
Recorded here only to keep the tier-1 checklist in one place: the one measured
cohort datum is 54–100 s server-side, fixed by making the client timeout
configurable 30–600 s with a **180 s default**. Nothing in the plan, #599, #601
or #602 mentions a timeout. This needs a number chosen, not a source found.

### S5 / S6 — OpenAI. **Route failed.**

Two items remain unverified because `openai.com` returns HTTP 403 to every
route. Per the brief this was not re-attempted today, and no first-party path
outside `openai.com` exists for either document — OpenAI publishes its terms
nowhere else.

- **Services Agreement §2.2 / §3.3(g)**, which #599's decision table cites as
  "explicitly blesses the BYO-key architecture". **Unverified.** This matters
  less than it looks: #599 revision 2 already moved off a hardcoded provider to
  a generic endpoint field, so OpenAI is no longer a named default, and the
  clause was cited as a *point in OpenAI's favour* in a comparison OpenAI lost.
  Nothing in the current design depends on it.
- **Current Usage Policies.** `ai-cohort-restrictions.md` **D7** quotes them
  from a Microsoft-hosted PDF marked "Effective: October 29, 2025", printed
  2025-11-07 — a mirror, now roughly nine months stale. The clause that matters
  ("automation of high-stakes decisions in sensitive areas without human review
  … medical") is one of two independent regimes resting on #602's review screen,
  so it should be re-checked before that argument is relied on in writing. It
  does not block anything from being built, because the screen is being built
  regardless.

### S7 / S8 / S9 — The three genuine legal questions. Open.

These need a lawyer, and both `ai-legal-constraints.md` and #599's third comment
already say so. Restated compactly because they are the only items on this list
that money rather than time will close:

1. **Is the project a "provider" of an AI system under Article 3(3) at all**,
   given the inference component arrives at runtime from an address the user
   typed, and the software is free and open-source? Nearly every downstream
   conclusion moves on the answer. Highest leverage.
2. **Does the Article 111(4) four-month transitional reach a feature released
   after 2 August 2026?** On its face it is scoped to systems already on the
   market on that date, which would mean no grace period. The operative text
   could not be retrieved today (see S1).
3. **Does Article 50(2)'s "do not substantially alter the input data … or the
   semantics thereof" exception cover the tier-1 text path?** If tier 1 is
   inside it and tier 2 is not, the tier split becomes a compliance boundary as
   well as a technical one — which is a better reason for the split than the one
   it was chosen for.

One point worth adding: **the AI Act questions are dated, not open-ended.**
Article 50 is in force *today*; the high-risk chapters that were deferred to
December 2027 were never in play for this app. So there is no schedule pressure
from the deferral — the pressure, such as it is, is that tiers 1–2 would be
placed on the market after the Article 50 application date with no transitional.

---

## C. What blocks a release, not development

### R1 — Google Play's in-app reporting requirement. **Closed today.**

Confirmed verbatim from Google's own support site,
[AI-Generated Content policy](https://support.google.com/googleplay/android-developer/answer/13985936).
Definition:

> AI-generated content is content that is created by generative AI models based
> on user prompts.

Operative requirement:

> Apps that generate content using AI must contain in-app user reporting or
> flagging features that allow users to report or flag offensive content to
> developers without needing to exit the app.

`ai-legal-constraints.md`'s quotation is accurate and its reasoning stands: the
operative sentence is **not** scoped to the two listed examples (chatbots,
image/video generation), so arguing the scope is not worth it — a "Report this
result" affordance on the review screen settles it. The page carries no
last-updated date; the only date shown is a "©2026 Google" footer.

**Does not touch tier 0.** Tier 0 generates nothing; it retrieves.

### R2 — Apple Guideline 5.1.2(i). **Closed today.**

Confirmed verbatim from
[developer.apple.com](https://developer.apple.com/app-store/review/guidelines/):

> Unless otherwise permitted by law, you may not use, transmit, or share
> someone's personal data without first obtaining their permission. You must
> provide access to information about how and where the data will be used. You
> must clearly disclose where personal data will be shared with third parties,
> **including with third-party AI**, and obtain explicit permission before doing
> so.

Three further confirmations that matter more than the quote:

- **"third-party AI" appears exactly once in the whole document**, here.
- **There is no separate AI-specific guideline number.**
- **There is no requirement anywhere to label AI-generated output.**

So `ai-legal-constraints.md` is right that Apple's entire AI-specific
requirement for this feature is one sentence: disclose, and get explicit
permission, before sharing personal data with third-party AI. Every on-screen
"estimated" marker is driven by UWG § 5 and by the README's own citation claim,
not by Apple.

### R3 — MDCG 2019-11 rev.1. **Closed today.**

Confirmed verbatim from the European Commission's own health domain
([`mdcg_2019_11_en.pdf`](https://health.ec.europa.eu/document/download/b45335c5-1679-4c71-a91c-fc7a4d37f12b_en?filename=mdcg_2019_11_en.pdf)).
Both sentences `ai-legal-constraints.md` relies on are accurate:

> In addition, software only intended for non-medical purposes (excluding MDR
> Annex XVI devices), such as invoicing, staff planning, e-mailing, web or voice
> messaging, data parsing, word processing, and back-up, **wellness or fitness
> apps, do not qualify as MDSW**.

and, in the same section:

> It must be highlighted that the risk of harm to patients, users of the
> software, or any other person, related to the use of the software within
> healthcare, including a possible malfunction **is not a criterion on whether
> the software qualifies as a medical device**.

The second sentence is the important one and it cuts both ways, exactly as
`ai-legal-constraints.md` argues: an `estimated` flag cannot make a
medical-purpose product non-medical, and a model's inaccuracy cannot make a
wellness app medical. **Qualification is decided by the stated intended purpose
and by nothing else** — which means the store listing and in-app copy are the
whole game.

### R4 — The Play health disclaimer is missing today. Decision, not research.

Found by `ai-legal-constraints.md`, repeated in #599's third comment, verified by
inspection: `fastlane/metadata/android/en-US/full_description.txt` contains no
"not a medical device and does not diagnose, treat, cure, or prevent any medical
condition" language, and the in-app `disclaimerText` says "not a medical
**application**", which is a different phrase in a different place from the one
the policy names. This is live in production, unrelated to AI, and costs one
paragraph. It should have its own issue.

### R5 — Four items misfiled as "could not verify" that are just lookups. Decision.

`ai-legal-constraints.md`'s "What I could not verify" section lists these as
research failures. They are not — they are things nobody outside the project
*can* answer, and things the maintainer can answer in five minutes:

- the app's current **Play content rating** and **App Store age rating**;
- whether the **Play Console Health apps declaration** is currently accurate;
- whether an **Impressum** with name, postal address and email is reachable from
  the app and the project site (DDG § 5).

Listing them under "unverified" implies a researcher could close them. None can.
They belong on a maintainer checklist.

---

## D. What blocks nothing, but is worth knowing

### N1 — The F-Droid ML Kit escape route. **Closed today, and it is cheaper than we thought.**

`ai-cohort-restrictions.md` **C1** is the biggest finding in the four documents
and the only present-tense blocker anyone has identified: bundled Google ML Kit
via `mobile_scanner ^7.2.0` fails F-Droid's Free Software Requirement, so
[RFP #2540](https://gitlab.com/fdroid/rfp/-/issues/2540) cannot succeed today.
It says "swap the scanner, as Open Food Facts did" but does not say what the
replacement actually is. Here it is.

**Open Food Facts' Flutter app is in the F-Droid main repository right now**, at
version 4.23.0, under the package id `openfoodfacts.github.scrachx.openfood`
(reused from the legacy native app), licence `Apache-2.0`. The metadata is
[`openfoodfacts.github.scrachx.openfood.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/openfoodfacts.github.scrachx.openfood.yml).
The mechanism, verbatim from the most recent build entry:

```yaml
subdir: packages/smooth_app
srclibs:
  - flutter@stable
rm:
  - packages/smooth_app/ios
  - packages/scanner/ml_kit
  - packages/app_store/google_play
  - packages/app_store/apple_app_store
prebuild:
  - git -C $$flutter$$ checkout -f $(cat ../../flutter-version.txt)
  - sed -i -e '/ml_kit/d' -e '/apple_/d' -e '/google_play/d' -e 's/version:.*/version: $$VERSION$$+$$VERCODE$$/' pubspec.yaml
  - export PUB_CACHE=$(pwd)/.pub-cache
  - $$flutter$$/bin/flutter config --no-analytics
  - $$flutter$$/bin/flutter pub get
scanignore:
  - packages/scanner/shared/pubspec.yaml
  - packages/scanner/zxing/pubspec.yaml
scandelete:
  - packages/smooth_app/.pub-cache
build:
  - export PUB_CACHE=$(pwd)/.pub-cache
  - export PATH=$$flutter$$/bin:$$flutter$$/bin/cache/dart-sdk/bin/:$PATH
  - $$flutter$$/bin/flutter build apk -t lib/entrypoints/android/main_fdroid.dart
output: build/app/outputs/apk/release/app-release-unsigned.apk
ndk: r28c
```

And the replacement scanner is
[`packages/scanner/zxing`](https://github.com/openfoodfacts/smooth-app/blob/develop/packages/scanner/zxing/pubspec.yaml),
whose only scanning dependency is:

```yaml
qr_code_scanner: 1.0.1
```

**Four corrections to `ai-cohort-restrictions.md` follow from this.**

1. **It is not a Gradle build flavour.** C3, C4 and the "build flavour"
   framing throughout section C assume the lever is
   `android/app/build.gradle`'s `productFlavors`. Open Food Facts does not use
   one for this. The lever is a **second Dart entry point**
   (`lib/entrypoints/android/main_fdroid.dart`) selected with
   `flutter build apk -t <entrypoint>`, plus fdroiddata-side `rm` and `sed`
   surgery that physically deletes the ML Kit package and strips its line from
   `pubspec.yaml` before the build. Our existing `flavorDimensions "version"`
   with `develop` / `full` is therefore **not** the thing to extend. The work is
   (a) put the scanner behind an interface, (b) add a second `main_*.dart`, and
   (c) write the fdroiddata recipe. That is a different, smaller and more
   self-contained piece of work than "add a third flavour".
2. **The Flutter SDK does not need vendoring.** C7 describes the maid recipe —
   `submodules: true`, the SDK checked into the repo as `packages/flutter`,
   `scanignore: [packages/flutter/bin/cache]`, `--split-per-abi`, and **one
   metadata entry per ABI with a distinct versionCode**. Open Food Facts uses
   `srclibs: [flutter@stable]` — F-Droid's own Flutter srclib, pinned per-build
   by `git -C $$flutter$$ checkout -f $(cat ../../flutter-version.txt)` — and
   ships a **single universal unsigned APK** with no per-ABI split and no
   submodules. That is substantially less work, and it comes from a peer Flutter
   *food* app rather than an LLM client.
3. **Anti-features survive the swap, and inclusion survives the anti-features.**
   OFF still carries `NonFreeNet` ("openfoodfacts.net/.org, openproductfacts.org,
   openstreetmap.org and sentry.io servers") **and** `Tracking` ("Analytics are
   opt-in but the app connects to sentry.io from the start, and connects even if
   rejected") — with ML Kit removed — and is in the main repository. This is a
   direct precedent for our own Sentry posture (**C6**): a peer app with opt-in
   Sentry earned `Tracking` and stayed listed. It is also the cleanest possible
   confirmation of **C8**.
4. **The replacement is licence-clean but stale.**
   [`qr_code_scanner`](https://pub.dev/packages/qr_code_scanner/license) is
   **BSD-2-Clause, "Copyright 2018 Julius Canute", version 1.0.1, last published
   about three years ago.** It is GPL-3.0-compatible and F-Droid-acceptable, but
   it is not maintained. A better candidate for a fresh integration is
   [`flutter_zxing`](https://pub.dev/packages/flutter_zxing) — **MIT, v2.3.0,
   published about three months ago**, ZXing C++ via Dart FFI, Android API 21+,
   with no Google or otherwise proprietary dependency. Both are viable; neither
   is `mobile_scanner`, whose unbundled variant only trades a bundled
   proprietary blob for a runtime Play Services dependency.

**This has nothing to do with AI** and should be its own issue, as C1 already
argues. It is now costed rather than hypothetical.

### N2 — Does a free-software scanner cover every symbology we need? **Closed today, from the code.**

`ai-cohort-restrictions.md` lists this as unverified. It is answerable without
any network call. The required set is:

- **EAN-8, UPC-A, EAN-13, GTIN-14** — enumerated explicitly in
  [`barcode_check_digit.dart`](../lib/features/scanner/util/barcode_check_digit.dart),
  which accepts exactly lengths `{8, 12, 13, 14}` and validates the shared
  Modulo-10 check digit. These are the only linear formats the app acts on.
- **QR Code** — three import screens scan QR
  (`import_meal_scanner_screen.dart`, `import_recipe_scanner_screen.dart`,
  `import_activity_scanner_screen.dart`) and `qr_flutter: ^4.1.0` generates it.

`scanner_screen.dart:57` constructs a bare `MobileScannerController()` with no
`formats:` argument, so nothing narrower is configured. Every format in that set
— EAN-8, EAN-13, UPC-A, ITF (for GTIN-14) and QR — is core ZXing. **No
symbology is lost by the swap.** Worth re-confirming against the chosen
package's own format list at integration time, but there is no reason to expect
a gap.

### N3 — Does #602 need a new dev dependency? **Closed today: no.**

`mockito: ^5.6.4` is already in `dev_dependencies` (as #601 says).
`bloc_test` is **not** — but the repo already tests blocs without it
(`test/features/recipes/presentation/bloc/recipes_bloc_test.dart`,
`recipe_builder_bloc_test.dart`, `test/unit_test/products_bloc_search_test.dart`
and others). So the plan's "no new dependency" promise holds for the test tree
as well as for `lib/`, and #602 should follow the existing hand-rolled pattern
rather than reaching for `bloc_test`.

### N4 — Three small open items, all decisions or cheap lookups.

- **`GPL-3.0-only` vs `GPL-3.0-or-later`** (`ai-cohort-restrictions.md` A9). A
  decision, forced whenever the F-Droid metadata is written, and forced earlier
  if any GPL-3.0-only peer code is absorbed.
- **The bundled Unsplash demo photos** (C5). A decision: replace the twelve
  images or accept `NonFreeAssets`. No external ruling exists to find; asking
  F-Droid is the only way to know in advance, and asking is itself a decision.
- **`minSdkVersion`**. [`android/app/build.gradle:63`](../android/app/build.gradle)
  is still `minSdkVersion flutter.minSdkVersion` — unpinned, deferring to
  whatever the Flutter SDK default is, with Flutter pinned to **3.44.6** in
  [`.fvmrc`](../.fvmrc). #599's "runs down to minSdk 24" claim is therefore
  still taken on trust. Irrelevant to tier 0, and `flutter_secure_storage` 10's
  floor of 23 means E5's conclusion holds either way.

---

## E. Open items that are misfiled

The most useful thing to say about the three existing "Not verified" lists is
that several entries on them are not research questions at all. Leaving them
there implies someone could close them by reading harder. Nobody can.

| Item, as filed | Where | What it actually is |
| :-- | :-- | :-- |
| "Whether Google would read a structured meal list as AI-generated content" | `ai-legal-constraints.md` | **Already decided.** The same document says "Building the report control moots the question", and #599 accepted that. Not open. |
| "Whether F-Droid would apply `NonFreeAssets` to the Unsplash demo photos" | `ai-cohort-restrictions.md` | **Decision.** No ruling exists to find. Either replace the images or accept the label. |
| "Whether `ollama.com`'s Terms reach a locally-run `ollama serve`" | `ai-cohort-restrictions.md` | **Decision** (or legal, if it ever mattered). The Terms are silent; silence will not become an answer by re-reading it. |
| Play content rating / Apple age rating / Health apps declaration / Impressum | `ai-legal-constraints.md` | **Four maintainer lookups**, five minutes total. Not researchable from outside. |
| "Whether the app's Play Console Health apps declaration is currently accurate" | `ai-legal-constraints.md` | Same. |
| "Whether the Article 111(4) transitional reaches a post-2 Aug 2026 feature" | `ai-legal-constraints.md` | **Legal**, correctly identified elsewhere in the same document but listed under "could not verify", which understates it. |
| Decision #5 re-settlement | #599 comment 1 | **Decision.** Framed as blocking tier-1 scoping, which is right — but it reads as though more evidence is pending. It is not. |
| "What Kai 9000's `foss` flavour actually removes" | `ai-cohort-restrictions.md` | Genuinely research, but **now moot**: N1 supplies a better, closer and current exemplar from a peer Flutter food app. |

---

## What I could not reach, and why

- **The operative amended text of Article 113, and Article 111(4), of Regulation
  (EU) 2026/1744.** EUR-Lex's HTML rendering truncates mid-sentence in
  Article 63 on both
  [`?uri=OJ%3AL_202601744`](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=OJ%3AL_202601744)
  and [`?uri=CELEX:32026R1744`](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:32026R1744),
  stopping at the identical point ("…without affecting the level of protection
  or the need for compl"). The same behaviour was already recorded for the
  consolidated AI Act text in #599's third comment. The deferral dates and the
  Article 50 position were confirmed from the
  [ELI record](https://eur-lex.europa.eu/eli/reg/2026/1744/oj/eng) and recital
  40 instead — both primary, both on `eur-lex.europa.eu` — so no mirror was
  needed for the claim that mattered. **The Article 111(4) quote in
  `ai-legal-constraints.md` remains unverified.**
- **OpenAI's Services Agreement §2.2 / §3.3(g) and current Usage Policies.**
  Not attempted today: `openai.com` returned HTTP 403 to every route on the
  previous pass, and OpenAI publishes these documents on no other first-party
  host. **The route failed and remains failed.** The Usage Policies text quoted
  at `ai-cohort-restrictions.md` D7 is still a nine-month-old Microsoft-hosted
  mirror.
- **A positive statement that `output_config.format` and an image content-part
  are supported together.** Three Anthropic documentation pages were read; none
  states an incompatibility and none states compatibility. Documentation cannot
  close this. One live API call can, and none was made.
- **Whether `flutter.minSdkVersion` resolves to 24 under Flutter 3.44.6.** The
  Flutter SDK is not on this machine's `PATH` (the repo uses FVM), so the
  default could not be read out of `flutter.groovy`.
- **Empirical search recall.** No live query was made against Open Food Facts or
  the Supabase backend, per the brief. Everything in T3 is derived from the
  source of `meal_relevance_ranker.dart`, `search_products_usecase.dart` and
  `sp_food_data_source.dart`, and the arithmetic is reproducible by hand. What
  the APIs actually *return* for `toast` is still unmeasured; the test that
  would settle it is described in T3 and does not require the network.

## Sources

Primary, fetched today:

[Regulation (EU) 2026/1744 — ELI record](https://eur-lex.europa.eu/eli/reg/2026/1744/oj/eng) ·
[Regulation (EU) 2026/1744 — OJ HTML (truncates)](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=OJ%3AL_202601744) ·
[Anthropic structured outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs) ·
[Anthropic vision](https://platform.claude.com/docs/en/build-with-claude/vision) ·
[Anthropic Messages API reference](https://platform.claude.com/docs/en/api/messages/create) ·
[Google Play AI-Generated Content policy](https://support.google.com/googleplay/android-developer/answer/13985936) ·
[Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) ·
[MDCG 2019-11 rev.1](https://health.ec.europa.eu/document/download/b45335c5-1679-4c71-a91c-fc7a4d37f12b_en?filename=mdcg_2019_11_en.pdf) ·
[fdroiddata `openfoodfacts.github.scrachx.openfood.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/openfoodfacts.github.scrachx.openfood.yml) ·
[smooth-app `packages/smooth_app/pubspec.yaml`](https://github.com/openfoodfacts/smooth-app/blob/develop/packages/smooth_app/pubspec.yaml) ·
[smooth-app `packages/scanner/zxing/pubspec.yaml`](https://github.com/openfoodfacts/smooth-app/blob/develop/packages/scanner/zxing/pubspec.yaml) ·
[`qr_code_scanner` licence](https://pub.dev/packages/qr_code_scanner/license) ·
[`flutter_zxing`](https://pub.dev/packages/flutter_zxing) ·
[F-Droid RFP #2540](https://gitlab.com/fdroid/rfp/-/issues/2540)

In-repo files read for sections A and D:

[`AGENTS.md`](../AGENTS.md) ·
[`CONTRIBUTING.md`](../CONTRIBUTING.md) ·
[`justfile`](../justfile) ·
[`l10n.yaml`](../l10n.yaml) ·
[`.gitignore`](../.gitignore) ·
[`.fvmrc`](../.fvmrc) ·
[`pubspec.yaml`](../pubspec.yaml) ·
[`.github/workflows/default_workflow.yml`](../.github/workflows/default_workflow.yml) ·
[`android/app/build.gradle`](../android/app/build.gradle) ·
[`lib/features/add_meal/util/meal_relevance_ranker.dart`](../lib/features/add_meal/util/meal_relevance_ranker.dart) ·
[`lib/features/add_meal/domain/usecase/search_products_usecase.dart`](../lib/features/add_meal/domain/usecase/search_products_usecase.dart) ·
[`lib/features/add_meal/data/data_sources/sp_food_data_source.dart`](../lib/features/add_meal/data/data_sources/sp_food_data_source.dart) ·
[`lib/features/add_meal/data/dto/sp/sp_const.dart`](../lib/features/add_meal/data/dto/sp/sp_const.dart) ·
[`lib/features/meal_detail/presentation/bloc/meal_detail_bloc.dart`](../lib/features/meal_detail/presentation/bloc/meal_detail_bloc.dart) ·
[`lib/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart`](../lib/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart) ·
[`lib/features/meal_detail/meal_detail_screen.dart`](../lib/features/meal_detail/meal_detail_screen.dart) ·
[`lib/features/scanner/scanner_screen.dart`](../lib/features/scanner/scanner_screen.dart) ·
[`lib/features/scanner/util/barcode_check_digit.dart`](../lib/features/scanner/util/barcode_check_digit.dart) ·
[`lib/core/utils/food_name_validator.dart`](../lib/core/utils/food_name_validator.dart) ·
[`lib/core/utils/json_meal_importer.dart`](../lib/core/utils/json_meal_importer.dart) ·
[`lib/l10n/*.arb`](../lib/l10n/) (nine files, 921 keys each, zero drift)

Issues and the plan:
[#599](https://github.com/simonoppowa/OpenNutriTracker/issues/599) (body plus its three comments, the comments controlling) ·
[#600](https://github.com/simonoppowa/OpenNutriTracker/issues/600) ·
[#601](https://github.com/simonoppowa/OpenNutriTracker/issues/601) ·
[#602](https://github.com/simonoppowa/OpenNutriTracker/issues/602) ·
[#250](https://github.com/simonoppowa/OpenNutriTracker/issues/250)
