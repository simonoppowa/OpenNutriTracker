# Competitive feature gaps

Where OpenNutriTracker sits against mainstream calorie trackers, ranked by
importance. Compiled 2026-08-08.

## Research overview

**Question:** which features do competing calorie trackers ship that
OpenNutriTracker does not, and which of those actually matter?

**Sources (triangulated):**

| Source | What it gives | Limits |
| :-- | :-- | :-- |
| GitHub issue tracker — 49 open, ~300 closed, ranked by reaction count | Revealed demand from users who cared enough to file or vote | Skews technical; a reaction is a weak signal; silent users invisible |
| The codebase itself (`lib/features/`, `pubspec.yaml`, `lib/core/utils/calc/`) | Ground truth on what exists | — |
| Published 2026 feature/pricing comparisons of MyFitnessPal, Cronometer, MacroFactor, Yazio, Lose It!, and FOSS peers (Waistline, FoodYou) | Competitive parity baseline | Much of this genre is SEO content from rival apps; treated as directional, not authoritative |

**No product analytics exist and that is deliberate** — there are no
advertising or analytics SDKs in `pubspec.yaml`, and Sentry is opt-in. So
there is no funnel data, no feature-usage data, and no churn data. Every
frequency figure below is *issue-tracker frequency*, which is a proxy for
demand, not a measurement of it. Findings are labelled with confidence
accordingly.

**Verified as already shipped** (candidate gaps that turned out not to be
gaps — checked in code, not assumed):

- Serving-size units rather than grams-only — `UnitDropdownItem.serving`,
  `lib/features/meal_detail/presentation/bloc/meal_detail_bloc.dart:71`
  (#34, merged in #391)
- Copy an entry to another day, defaulting to the matching meal type —
  `lib/features/diary/presentation/widgets/day_info_widget.dart:273`
  (#67, #227)
- Multi-profile with per-profile data — `switch_profile_usecase.dart`
- Recent-intake ranking in search — `search_products_usecase.dart:147`
- Micronutrients free (10 nutrients), which most competitors paywall

---

## Findings, ranked

### 1. No health-platform integration (Apple Health / Health Connect)

**Frequency:** highest signal in the tracker by a wide margin — 3 issues,
~56 reactions combined. #103 (30 reactions, open since 2024-07-15) is the
single most-reacted open issue in the repository. #147 (21) and #295 (5,
closed) are duplicates of it.

**Evidence:**

> "the ability to import and export to and from a health app … This should
> sync both ways, telling Apple Health what nutrients I am eating, and
> receiving fitness information for workouts." — #103

**State:** absent. No `health`, `pedometer`, or equivalent dependency in
`pubspec.yaml`; no Health Connect permissions in the Android manifest.

**Competitive position:** table stakes. MyFitnessPal, Cronometer, Yazio and
Lose It! all sync bidirectionally with Apple Health / Health Connect, and
several comparison pieces now treat wearable sync as a filter criterion
before features are even compared.

**Impact:** high, and structural rather than cosmetic. It blocks three
things at once — (a) nutrition flowing out to the platform the user's other
apps read, (b) active calories and steps flowing in, which is what powers
the "you earned 300 kcal back" loop competitors have, and (c) weight and
workouts arriving without double entry. Today a user with a watch logs
their workout twice.

**Tension to resolve deliberately:** this is the one high-demand feature
that touches the privacy story. It is defensible — the data moves
device-local to device-local, no server involved, and the permission is
opt-in — but the Privacy section of the README currently promises "no
health-data access", and that sentence would have to change.

**Confidence:** high.

---

### 2. No F-Droid listing

**Frequency:** second-highest signal — #126 (21 reactions, open since
2024-11-10), #159 (14, closed), #575 (3, open). ~38 reactions.

**State:** open. `docs/fdroid-submission-feasibility.md` exists, so the
groundwork is underway.

**Competitive position:** the FOSS peers this app competes with for the
privacy-first audience — Waistline, FoodYou — are on F-Droid. Note that at
least one third-party comparison already *claims* OpenNutriTracker is on
F-Droid; the audience assumes it, which means the absence reads as a defect
rather than a choice.

**Impact:** high for the segment that is the app's core constituency. A
user who avoids Google Play on principle currently cannot install this
without side-loading a GitHub release. It is distribution, not a feature,
but it gates reach for exactly the users most likely to stay.

**Confidence:** high. Note this is reach, not retention — it will not
change the experience of anyone already using the app.

---

### 3. No automatic backup or multi-device continuity

**Frequency:** 5 distinct issues, low individual reaction counts — #79 (6),
#166 (1), #86, #286, #585.

**State:** manual only. Export produces a JSON zip (with CSV companions)
that the user must remember to trigger and store somewhere. Import is a
paste-a-blob flow. No scheduled export, no destination integration.

**Competitive position:** every mainstream competitor syncs by account, so
a lost or replaced phone is a non-event. Here it is total data loss unless
the user exported recently.

**Impact:** high severity, low frequency — it matters once, catastrophically.
The user segment most likely to hit it (multi-year loggers with deep history)
is also the most invested.

**Design note:** the account-based answer is off the table by design, but
the gap does not require an account. A scheduled encrypted export to a
user-chosen destination (SAF / Files, iCloud Drive, WebDAV) closes most of
the severity while keeping the "no account, no server" promise intact. #585
asks for exactly this.

**Confidence:** medium-high on the need, high on the severity.

---

### 4. No home-screen widgets, no watch app, no voice entry

**Frequency:** 5 issues, minimal reactions — #192 (1), #579, #532, #533,
#500. Low vote counts, but the cluster is consistent.

**State:** absent. No widget targets in `android/` or `ios/`, no
`home_widget` dependency.

**Competitive position:** widgets and Apple Watch complications are
standard across MyFitnessPal, Cronometer, Lose It! and Yazio, and are a
scored category in 2026 comparison round-ups.

**Impact:** medium-high, and it compounds. Logging friction is paid several
times a day, every day, and abandonment in this category is usually death
by friction rather than a single missing feature. A calories-left widget
and a one-tap water widget are the two highest-leverage pieces.

**Confidence:** medium — strong on competitive parity, weak on measured
demand. This is the finding where the absence of usage analytics hurts most.

---

### 5. Calorie targets are static, not adaptive

**Frequency:** zero user requests. This gap comes entirely from competitive
analysis.

**State:** `lib/core/utils/calc/tdee_calc.dart` computes a target from the
IOM 2005 equations and profile inputs. It changes when the profile changes,
plus an optional taper as goal weight approaches. It does not learn.

**Competitive position:** this is MacroFactor's entire pitch, and its main
claim over both MyFitnessPal and Cronometer, which are also static. An
adaptive model reconciles logged intake against the observed weight trend
and corrects the target weekly, which fixes the standard failure mode: the
formula says 2,100 kcal, the user stalls for six weeks, and nothing in the
app notices.

**Impact:** high on outcomes, and it is the difference between an app that
records and an app that works. Strategically it is unusually well suited
here — it needs *only* data the app already holds locally (weight history
and logged intake), costs nothing in privacy, requires no network, and is
pure computation over existing Hive boxes.

**Confidence:** medium. Strong reasoning, no direct user demand — nobody
requests a feature they have not seen. Worth validating before building.

---

### 6. AI-assisted logging — a deliberate non-adoption, not an oversight

**Frequency:** #250 (10 reactions, closed *researched-not-shipping*
2026-05-15) plus #599–#602 open.

**State:** decided against, with documented reasoning across
`docs/ai-in-open-source-nutrition-trackers.md`,
`docs/ai-legal-constraints.md` and `docs/ai-cohort-restrictions.md`. The
closing argument: a model-estimated figure is "a model estimated this for
you", not "this is from a database", which collides with the cited-sources
guarantee — and #250 flags it as an App Store review risk for health apps,
not merely an internal consistency question. #599–#602 pursue a
*deterministic* text parser instead, which keeps provenance intact.

**Competitive position:** MyFitnessPal (Meal Scan), Yazio (now branded "AI
Calorie Tracker") and the Cal AI cohort all ship photo and natural-language
logging. Independent benchmarking puts MyFitnessPal's photo recognition at
71.2% identification accuracy with ±18% portion error — roughly one in four
photos needing correction, which is a useful number to cite when explaining
the choice.

**Impact:** high on perceived modernity, low on actual utility at current
accuracy. Listed here not as a recommendation to build but because it is
the most visible feature difference a prospective user will notice, and the
reasoning deserves to be public rather than buried in a closed issue.

**Confidence:** high — the decision is documented and recent.

---

### 7. Micronutrient depth trails the specialist

**Frequency:** no open requests. #237 (5) closed — the panel shipped.

**State:** 10 nutrients (fibre, sodium, saturated fat, sugar, calcium,
iron, potassium, vitamin D, B12, magnesium) with DRI reference bars.

**Competitive position:** Cronometer tracks ~84 and is chosen specifically
for that. OpenNutriTracker's 10 are free where competitors paywall theirs,
which is the stronger card to play.

**Impact:** medium, and confined to one segment. Broadening depends on
source-data coverage more than UI work — USDA FoodData Central carries far
more than 10 nutrients, Open Food Facts often does not.

**Confidence:** medium.

---

### 8. Long tail — genuine but narrow

| Gap | Evidence | Note |
| :-- | :-- | :-- |
| Recipe import from a URL | #503 (1) | Yazio and Lose It! paste-a-recipe-URL; needs parsing infrastructure |
| Meal planning / forward scheduling | none filed | Yazio and EatThisMuch build plans; a different product posture — the app records the past, planning projects forward |
| Favourites / pinned foods | none filed | No favourite mechanism in code; recent-intake ranking covers much of it |
| Quick serving chips | #577 | Serving units shipped; this is the ergonomic follow-up |
| Regional food databases | #263 (India), #105 (Brazil/TBCA) | Schema exists, data not loaded |

---

## Segments

Three distinct users show up in the evidence, and they want different
things — several findings above only matter to one of them.

**The privacy refugee** — arrived from MyFitnessPal specifically to escape
subscriptions and data collection. Dominant in the App Store and Play
reviews quoted in the README ("Finally I don't have to sell my soul to
MyFitnessPal"). Wants F-Droid (#2) and trustworthy backup (#3). Tolerates
missing features; does not tolerate a privacy regression. **This segment is
the reason to be careful with finding #1.**

**The everyday logger** — wants the weight to move and does not care about
the licence. Feels findings #1, #4 and #5 daily. Churns quietly to a
competitor without filing an issue, which is precisely why this segment is
under-represented in the reaction counts above.

**The nutrition nerd** — here for micronutrients and citations. Best served
today of the three; finding #7 is theirs.

---

## Recommendations, in order

1. **Health Connect / Apple Health, read-write, opt-in.** The clearest
   priority — highest demand by a wide margin, and it unblocks the
   activity-adjustment loop rather than being a one-off. Ship it behind an
   explicit toggle, default off, and update the README privacy table in the
   same change. Start with Health Connect: #295 was already labelled
   `backlog:high`, and the Android surface is the larger one.

2. **Finish the F-Droid submission** (#575, #126). Feasibility work is
   already written down. Highest reach-per-unit-effort item on the list,
   and the audience already assumes it exists.

3. **Scheduled encrypted backup to a user-chosen destination** (#585).
   Closes the catastrophic-loss scenario without an account, a server, or a
   change to the privacy story.

4. **A calories-left home-screen widget, then a water widget** (#533, #532,
   #579). Bounded work, daily payoff, and the two most-used numbers in the
   app.

5. **Prototype adaptive calorie targets** before committing. All required
   data is already local. Validate against real weight-history data that
   the correction is stable enough not to whipsaw a user's target
   week-to-week — that is the failure mode, and it is worth a
   `lib/core/utils/calc/` spike against seeded demo data first.

6. **Publish the AI reasoning where prospective users will see it**, not
   only in a closed issue. "We looked at this, here is the accuracy data,
   here is why cited numbers matter more" is a stronger position than
   silence, and it converts a perceived gap into a stated principle. The
   71.2%/±18% benchmark is the concrete number to lead with.

---

## Open questions

The honest limits of this analysis:

- **No churn data.** Everything above ranks *stated* demand from people who
  stayed long enough to file an issue. The users who installed, hit a
  missing feature, and left are invisible. The single most valuable
  follow-up would be a lightweight, opt-in exit survey on the store
  listings — or reading the 1–3★ reviews systematically, which is the only
  channel where dissatisfied non-filers speak.
- **Is finding #4 real demand or my inference from competitor round-ups?**
  Reaction counts are near zero. Worth asking directly in an issue before
  investing.
- **Would health sync cost trust with the privacy segment?** Findings #1
  and #2 serve partly opposing audiences. This is answerable cheaply — ask
  in #103, where 30 interested people are already subscribed.
- **How much of the retention gap is missing features versus logging
  friction?** These need different responses, and nothing in the current
  evidence separates them.
- **Micronutrient coverage per source is unmeasured.** Before expanding
  finding #7, check what fraction of typical logged foods actually carry
  values beyond the current 10.
