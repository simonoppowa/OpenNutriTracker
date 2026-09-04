# Store-listing experiments: Play and Apple

What Google Play Store Listing Experiments and Apple Product Page
Optimization actually do, what they require, and what traffic each needs
before its answer means anything. Compiled 2026-09-04 for
[#1064](https://github.com/simonoppowa/OpenNutriTracker/issues/1064) and
[#1080](https://github.com/simonoppowa/OpenNutriTracker/issues/1080), under
map [#1062](https://github.com/simonoppowa/OpenNutriTracker/issues/1062).

## Research overview

**Question:** what are the documented mechanics and preconditions of each
platform's store-listing experiment, and what traffic does each need to
produce a usable result rather than noise?

**Sources (primary first):**

| Source | What it gives | Limits |
| :-- | :-- | :-- |
| Play Console Help — *Run A/B tests on your store listing* (`answer/12053285`) | Google's only complete description of the mechanism: experiment types, variant count, audience percentage, target metrics, advanced settings, results vocabulary, autocompletion | Written as a click-path. States that confidence level and minimum detectable effect are adjustable but never publishes their values or defaults. Says nothing about traffic minimums or about releases running concurrently |
| Play Console product page — *Store listing experiments* (`play.google.com/console/about/store-listing-experiments`) | Google's only published duration guidance ("at least a week") and its best-practice list | Marketing page. Contradicts the Help page on testable assets (see *Contradictions*). Case-study figures are customer-supplied |
| Play Console Help — *Control when app changes are reviewed and published* (`answer/9859654`), *Asset Library* (`answer/16386748`) | Confirms experiment changes go through the same review/publishing pipeline; confirms the asset types the experiment surfaces accept | Neither page is about experiments; used only for the mechanics they touch |
| App Store Connect Help — *Overview of product page optimization*, *Create a test*, *Configure test treatments*, *Run a test*, *Apply a test treatment to your product page* | Apple's procedural spec: treatment count, traffic proportion, 90-day cap, localisation, App Review path, icon constraints, apply semantics | Procedures, so constraints appear as steps rather than as stated rules. Nothing about eligibility beyond app status |
| App Store Connect Analytics Help — *Product Page Optimization* (acquisition) | The statistical contract in Apple's own words: Bayesian method, 90% confidence, credible interval, status vocabulary, the five-download reporting floor, plus a troubleshooting FAQ | The FAQ mentions testable elements the configuration page does not (see *Contradictions*), so it is not internally consistent with the ASC Help flow |
| developer.apple.com — *Product page optimization* (marketing) | The clearest plain-English statement of traffic-proportion arithmetic and of the review-independence rule | Marketing page. Says "one test at a time"; the Analytics FAQ says multiple concurrent tests are fine |
| Vendor blogs (App Radar, MobileAction, yellowHEAD, screenshot-tool blogs) | Circulate numeric traffic rules of thumb — "500 daily page views", "15,000–20,000 impressions per variant" | **Not used as evidence.** None of these numbers appears in Apple or Google documentation, and each vendor sells testing services. Noted here only so a later session recognises them as vendor claims, not platform requirements |

**No console access was available.** Everything below is from published
documentation; nothing was checked against OpenNutriTracker's own Play
Console or App Store Connect records. The traffic arithmetic near the end is
**my calculation**, clearly separated from what the platforms publish.

---

## The short answer

- **Neither platform documents a minimum traffic, minimum installs, or
  minimum duration precondition for running an experiment.** Google
  publishes one soft best practice ("test for at least a week"); Apple
  publishes one reporting floor ("five first-time downloads") which gates
  when numbers *appear*, not when they are trustworthy. Everything else on
  both platforms is an in-console estimator that consumes your own traffic
  data. **Confidence: high** — this is an absence verified by reading the
  full text of every relevant page, not a failure to find the right page.
- **Apple publishes far more statistical detail than Google.** Apple names
  its method (Bayesian), its threshold (90% confidence), and publishes a
  90% credible interval on both conversion rate and lift. Google names
  neither a default confidence level nor a default minimum detectable
  effect, and reports a verdict rather than an interval.
- **Play can test description text; Apple cannot.** Play's localized
  experiments cover descriptions. Apple's treatments cover app icon,
  screenshots and app previews only.
- **PPO as an asset-delivery route survives re-verification**, with two
  qualifications the prior research did not carry: the app must be in
  *Ready for Distribution*, and new screenshot metadata still goes through
  App Review, bundled into a submission "reviewed together with your latest
  iOS version".
- **Play has no equivalent asset-delivery use**, because Play never gated
  listing assets on a build in the first place.

---

## Google Play Store Listing Experiments

### What can be varied

Two experiment types, and the asset list differs between them.

> "Using a default graphics experiment, you can experiment with graphics in
> your app's default Store Listing language. You can include variants of
> your app's icon, feature graphic, and screenshots."

> "Using a localized experiment, you can experiment with your app's icon,
> feature graphic, screenshots, and/or your app's descriptions in up to five
> languages."
> — *Run A/B tests on your store listing*

So: **icon, feature graphic, screenshots** anywhere; **descriptions** only in
a localized experiment. Google writes "descriptions" without distinguishing
the 80-character short description from the 4000-character full one, and
does not enumerate the field elsewhere. **Confidence: high** for the asset
list; **low** for which of the two description fields is meant — that needs
a console visit.

**Promo video is not listed as testable** on the Help page, and the Asset
Library page describes the library as holding "screenshots, icons, and
feature graphics" only. Google's own console-about page nonetheless advises
"testing icons, videos, and screenshots". Treat video as **not testable**
until the console says otherwise. **Confidence: medium** — an unresolved
contradiction between two Google pages, resolved here in favour of the more
recently maintained one.

Not testable, by omission from every list: app title, category, contact
details, data-safety content.

### Variants, traffic split, scope

- **Up to 2 experimental variants** against the current listing — "you can
  choose up to 2 variants".
- **Audience percentage** is developer-set: "The percentage of store listing
  visitors that will see an experimental variant instead of the current
  listing. These visitors will be split equally across your experimental
  variants." No documented floor or ceiling on that percentage.
- **Scope:** "You can run experiments for your default and custom Store
  Listings."
- **Concurrency:** "For each app, you can run one default graphics
  experiment or up to five localized experiments at the same time."
- **Localisation cross-talk, and it bites a single-locale app less than it
  looks:** users viewing a language for which you have uploaded a localized
  graphic are excluded from default graphics experiments. With en-US only,
  "Default graphics experiments will be shown to all users."

**Confidence: high** — all four quoted from the Help page.

### How Google decides and reports a winner

Two settings drive the verdict, both adjustable and both undocumented as to
their values:

> "Minimum detectable effect: The minimum difference between variants and
> control required to declare which performs better. If the difference is
> less than this, your experiment will be considered a draw."

> "Confidence level: How often the confidence interval provided by the
> experiment will contain the true performance of the store listing.
> Increasing the confidence level decreases the likelihood of a false
> positive."

The target metric is one of **unique user install clicks**, **unique user
open clicks**, or **unique user pre-registration clicks** — and Google's own
definition of the first is an install count, not a click count: "The number
of users who installed your app, who didn't have it installed on any other
devices at the time."

Results are a verdict plus prose, not an interval:

> "The results tell you which of the options is performing best, or
> performing better than your current Store Listing. You'll also see an
> explanation of this result, based on its confidence interval and minimum
> detectable effect, and a recommended action (if applicable). You may
> receive the result 'More data needed' if not enough data has been
> collected to return a result."

Outcomes are therefore: a recommendation to apply a variant, **"More data
needed"** ("We will advise if you have less than a week before we expect a
result to be ready"), **"Draw"**, or current listing wins.

**Google does not publish its default confidence level, its default minimum
detectable effect, the options available for either, or any interval on the
result.** **Confidence: high** that these are undocumented; the settings are
named and described but never valued.

### Minimum traffic, duration, installs

**Google documents none.** The single sentence that stands in for one:

> "The experiment creation page estimates the time and number of
> acquisition, opens or pre-registrations your experiment will need to show
> a statistically significant result."

The estimator lives in the console and consumes the app's own traffic, so
the answer for this app is only obtainable by opening the create-experiment
page. The nearest thing to a documented duration is a best practice on the
console-about page: "Test for at least a week to account for weekday vs
weekend traffic patterns." At the other end, "Store listing experiments stop
automatically after running for 6 months."

**Confidence: high.** The absence is the finding: there is no install
threshold below which Play refuses to run an experiment, and no published
number to check the app's baseline against. The console estimator is the
gate, and it is a soft one.

### Apply, autocompletion, and staged rollout

On applying, Google is thin: the results section offers "a recommendation to
apply that variant", and if the control wins you "click Keep current
listing". If nothing is applied within six months:

> "Store listing experiments stop automatically after running for 6 months.
> After this time, no new data will be collected, no variants will be
> applied, and traffic will revert to the current listing."

One precondition sits in the click-path rather than in a rules section, and
it matters to a listing that is mid-change:

> "If it's not available, follow the prompt at the top of the Details page
> to fully roll out your store listing and get it ready for experiments,
> then return to this step to set up your experiment."

Reading: a store listing that is itself partially rolled out cannot host an
experiment until it is fully rolled out. **Confidence: medium** — that is my
interpretation of a procedural sentence, not a stated rule.

Experiment assets are ordinary reviewable changes — the setup flow ends at
"go to the publishing overview page to submit your changes for review", and
*Control when app changes are reviewed and published* lists "Updates to your
store listings" among the changes that queue there. Play's published review
window is hours to seven days or longer.

**On running an experiment concurrently with a staged rollout of the app,
Google documents nothing at all** — not a prohibition, not a warning, not an
interaction. **Confidence: high** that it is undocumented; **low** on what
actually happens. Note the asymmetry with Apple, which does warn about this.

---

## Apple Product Page Optimization

### Treatments, duration, traffic allocation

Confirmed, all three:

- **Up to three treatments.** "You can have up to three treatments per test.
  Please note that the more treatments you add to a test, the longer the
  test may take to reach a conclusive result."
- **90 days.** "A test runs for 90 days or until you manually stop it within
  that time." Stopping is terminal: "Once you stop a test, it can't be
  restarted. You'll need to create a new test with the same treatments and
  run it again."
- **Traffic proportion is developer-set**, with the arithmetic spelled out:
  "if a test has three treatments and you choose a 30% traffic proportion,
  each treatment will be shown to 10% of the total traffic." Assignment is
  sticky — "People will see the same treatment whenever they visit the App
  Store throughout the duration of the test." No documented floor or
  ceiling on the proportion.

Also: treatments are shown only on **iOS 15 / iPadOS 15 or later**; tests are
unavailable for custom product pages and for the Apple Watch and iMessage
App Stores; localisations default to all supported and can be narrowed, and
"If the localization shown to a user is excluded from your test, the user
won't be included in the test."

**Confidence: high** — all quoted from App Store Connect Help.

### What can be varied

> "By default, test treatments are copies of your app's original App Store
> product page. You can edit the app icon, screenshots, and previews of each
> treatment."
> — *Configure test treatments*

**Icon, screenshots, app previews. No text fields.** Description, subtitle,
keywords, promotional text and app name are absent from the treatment
editor's tabs, from the overview page, and from the marketing page's
enumeration. **Confidence: high**, with one wrinkle: Apple's Analytics help
page opens by saying PPO tests "screenshots, app previews, descriptions, and
app icons", and its FAQ repeats "screenshots, description, preview video".
Those two mentions are contradicted by every page that describes the
configuration flow. Treat text as **not testable**. **Confidence: medium**
on that resolution — it is worth thirty seconds in the console to confirm,
because a testable description would change what Play-versus-Apple parity
looks like.

The icon carries a hard constraint the other assets do not: any icon used
"must be part of the app binary for the current App Store version, which
should be built with Xcode 13 or later and support alternate icons in asset
catalogs".

### How Apple reports results

Apple publishes the whole statistical contract, and it is more specific than
Google's.

**Method:** Bayesian. "A statistical method where probability expresses a
degree of confidence in an event; used to justify confidence in your
conversion rate lift."

**Metric:** *Estimated Conversion Rate* — "The estimated percentage of
people that downloaded or pre-ordered your app from a certain product page
variant. This estimate incorporates the data observed during the test, as
well as existing data" — alongside unique impressions.

**Effect size:** *Estimated Relative Lift* — "The estimated relative
increase in conversion rate for a variant as compared to the selected
baseline. It requires fewer weeks of data to determine significance on
higher improvement values (e.g. 30%) as opposed to lower improvement values
(e.g. 5%)."

**Threshold:** 90%, and only 90%. "This variant is performing better than
the baseline with at least 90% confidence." Not developer-adjustable, unlike
Play's.

**Interval — yes, Apple publishes one:** *Credible Interval*, "The probable
range of your lift or conversion rate. This represents a 90% interval,
meaning there's a 90% probability that the conversion rate or lift falls
within this range."

**Status vocabulary:** Baseline, Collecting Data, Performing Better,
Performing Worse, and **Likely to be Inconclusive** — "Based on the current
results, there likely won't be enough data after 90 days to determine how
this variant is performing compared to the baseline." That last status is
the one a low-traffic app should expect to meet, and Apple's own remedy list
is telling: "(1) extending your test beyond 90 days if possible, (2) testing
a more dramatic change that may show larger lift, or (3) running the test
again during a period of higher traffic."

The baseline is re-selectable mid-test — "You can change your baseline at
any time to any of your available treatments" — and all comparisons
recalculate.

**Confidence: high** throughout; every sentence above is Apple's.

### Minimum traffic or installs

**Apple documents no minimum either.** What it documents is a *reporting*
floor and an estimator:

> "Test results appear in App Analytics after there are five first-time
> downloads associated with the test."

> "If your app has lower traffic, it may take longer to accumulate
> sufficient data. Once you reach five downloads, results will begin
> appearing and will update daily."

Five downloads is the point at which numbers become visible. It is emphatically
not the point at which they mean anything, and a later session must not
quote it as Apple's traffic requirement. The real gate is the same shape as
Google's — an in-console estimator: "you'll see the estimated test duration
and the number of impressions you'd need to reach an outcome with at least
90% confidence in the results", computed from "your app's existing
performance data, such as daily impressions and new downloads". Apple adds
the honest caveat: "it may not be possible to reach your desired improvement
in conversion rate within 90 days", and suggests "creating fewer treatments
or increasing traffic allocation" if the estimate exceeds 90 days.

**Confidence: high.** No eligibility threshold, no install minimum, no
documented refusal at low volume — the test runs and reports *Likely to be
Inconclusive*.

### Re-verifying the two quotes #1067 leaned on

Both quotes are accurate and current as of 2026-09-04.

> "Before testing, ensure all metadata in your test treatments is approved.
> You can submit this metadata without submitting a new version of your
> app."
> — *Configure test treatments*

> "You can apply any of the treatments to your original product page on the
> App Store, as well as to versions in the Ready for Distribution or Prepare
> for Submission states, at any time. You can apply one treatment per test,
> and the action can't be undone."
> — *Apply a test treatment to your product page*

The marketing page corroborates the first independently: "Product page
optimization tests that don't include any alternate app icons can be
submitted for review independent of a new app version."

**Four qualifications, two of them new.**

1. **New (and the most consequential): "without a new version" is not
   "without App Review".** *Run a test* documents the review path: "If your
   metadata needs to be reviewed, you'll be prompted to add the test for
   review... **Items in the submission will be reviewed together with your
   latest iOS version.** ... The test status will change once the metadata
   is accepted by App Review." So screenshots reach the live page without a
   *build*, but not without a review pass, and the submission is coupled to
   the latest iOS version record. Combined with the two-concurrent-submissions
   ceiling #1067 already found, this is a real scheduling constraint if a
   2.2.x version record is in flight. **Confidence: high** for the quote;
   **low** for what the coupling does in practice when a version sits in
   Prepare for Submission — that is a console question.
   The exemption is narrow and worth having: "If you're simply changing the
   order of screenshots or previews that are already on the App Store, or
   only modifying the app icon, your metadata is already approved and you
   don't need to resubmit."
2. **New: there is an app-state precondition.** "Your app must be in the
   Ready for Distribution state to test its product page." A PPO test is not
   available for an app that has never shipped or whose current record is
   not live. For this app the live record is 2.0.2 and is Ready for
   Distribution, so the precondition is met — but it is a precondition, and
   #1067 did not carry it. **Confidence: high.**
3. **Already carried by #1067, re-confirmed verbatim:** the icon does not
   come along ("only the app previews and screenshots from the treatment
   will be applied. To apply changes to the app icon, set it as the default
   icon in your next app version"); applying is irreversible; applying while
   a test runs stops the test.
4. **New detail in #1080's favour:** the apply flow ends with "Select the app
   versions you want to apply the treatment to" — so a treatment's
   screenshots can be pushed to the live page *and* to a draft version
   record in one action. If a 2.2.1 is cut later, the screenshots do not
   need re-uploading into it.

**"At any time" holds.** Nothing in the apply page conditions the action on
significance, on a minimum number of downloads, or on the test having
finished. Apple's *recommendation* is separate and clearly framed as advice:
"We recommend waiting to apply a treatment or stop a test until at least one
treatment has been declared to be performing better or worse than the
baseline with at least 90% confidence." A recommendation, not a gate.
**Confidence: high.**

### The one interaction Apple documents and Google does not

> "Releasing a new app version while a test is in progress may impact the
> results if your version contains assets or metadata that are currently
> being tested."
> — *Overview of product page optimization*

Narrow, and worth reading precisely: the hazard Apple names is *asset
collision* — the new version's own screenshots overwriting what the test is
varying — not the rollout confound. Randomised concurrent assignment already
handles the rollout confound, because at any moment every arm faces the same
binary. **Confidence: high** for the quote, **medium-high** for the reading.

---

## Side by side

| | Google Play | Apple |
| :-- | :-- | :-- |
| Variants against control | Up to 2 | Up to 3 treatments |
| Max duration | Auto-stops at 6 months | 90 days, hard |
| Traffic split | Developer-set %, equal across variants | Developer-set %, equal across treatments |
| Icon | Testable | Testable, but only icons already in the shipped binary; never applied by "apply" |
| Feature graphic | Testable | n/a (no such asset) |
| Screenshots / previews | Testable | Testable |
| Video | Not on the Help page's list (see *Contradictions*) | App previews testable |
| Description text | Testable, localized experiments only | Not testable |
| Target metric | Install / open / pre-registration clicks, developer-chosen | Conversion rate (downloads per unique impression), fixed |
| Confidence level | Developer-adjustable, values unpublished | Fixed at 90%, published |
| Interval reported | No — verdict plus prose | Yes — 90% credible interval on rate and on lift |
| Method named | No | Yes, Bayesian |
| Documented traffic minimum | **None** | **None** (five downloads is a reporting floor) |
| Documented duration minimum | **None** ("at least a week" is a best practice) | **None** |
| Concurrency | 1 default graphics *or* up to 5 localized | Contradictory: "one test at a time" vs FAQ "yes" |
| Applying a winner | Recommended by the console; unapplied experiments revert at 6 months | Unconditional, irreversible, stops the test |

---

## What volume makes these usable

**This section is reasoning, not documentation. Neither Apple nor Google
publishes a traffic threshold, and nothing below may ever be attributed to
either of them.**

What they *do* publish is enough to bound it. Apple fixes the bar at 90%
confidence and states the direction of the trade — big lifts need less data
than small ones. Google exposes the same trade as two knobs. Both therefore
behave like an ordinary two-proportion test, and the sample size for one is
arithmetic.

Taking a two-sided 90% confidence level and 80% power, and using
`n = (z(α/2) + z(β))² · [p₁(1−p₁) + p₂(1−p₂)] / (p₂−p₁)²`:

| Platform shape | Baseline rate | Relative lift to detect | Needed per arm |
| :-- | :-- | :-- | :-- |
| Play (visitor → install) | 25% | +30% | ~450 visitors |
| Play (visitor → install) | 25% | +20% | ~1,000 visitors |
| Play (visitor → install) | 25% | +10% | ~3,800 visitors |
| Play (visitor → install) | 25% | +5% | ~15,100 visitors |
| Apple (impression → download) | 4% | +30% | ~3,800 impressions |
| Apple (impression → download) | 4% | +20% | ~8,100 impressions |
| Apple (impression → download) | 4% | +10% | ~31,100 impressions |

The baseline rates are **illustrative placeholders**, not this app's
numbers — #1064's own baseline work supplies the real ones, and every figure
in the table moves with them. Apple's engine is Bayesian and borrows
strength from prior data ("This estimate incorporates the data observed
during the test, as well as existing data"), which will generally make it
kinder than this arithmetic; Google's is adjustable, which makes it whatever
you set it to.

Two readings follow, and they point in opposite directions:

**Play is plausibly within reach.** Two arms at ~1,000 visitors each is
~2,000 store-listing visitors for a 20%-relative swing — roughly 70 a day
across a four-week experiment. That is a modest number for an app with a
live Play listing that already ranks #1 for `open source calorie tracker`.
A 10% swing needs about four times that, ~275 visitors a day. **The gating
question for Play is therefore not whether the app has enough traffic in
principle — it is what effect size the listing change plausibly produces.**

**Apple is much harder, for a structural reason.** Its metric divides by
*impressions*, not by page visitors, so the base rate is roughly an order of
magnitude smaller and the required counts an order of magnitude larger:
~16,000 in-test impressions for a 20% swing, ~62,000 for a 10% one, and the
90-day cap is hard. For an app whose App Store record has been stale at
2.0.2 since August and which is absent from Apple search results for every
generic query, expecting tens of thousands of impressions inside 90 days is
optimistic. **The realistic prior is that an Apple PPO test on this app
returns *Likely to be Inconclusive*.**

**Confidence: medium** on the arithmetic being the right model (both
platforms behave like proportion tests, but Apple's Bayesian priors are
undocumented in detail); **low** on the absolute numbers until #1064's
baseline replaces the placeholder rates; **high** on the qualitative
conclusion that Play's metric is far cheaper to power than Apple's.

---

## Using either mechanism purely as an asset-delivery route

### Apple: yes, and it is the only route

Running a PPO test with the measurement ignored is coherent and every step
is documented. Create a test, put the new screenshots in one treatment,
submit for review, apply that treatment to the original product page. The
apply is unconditional. What it costs:

- **An App Review pass**, bundled into a submission "reviewed together with
  your latest iOS version". Not free, and not independent of version
  scheduling.
- **The test object itself.** There is no "apply a treatment" outside a
  test; the treatment is a child of one. Whether the test must actually be
  *started* before a treatment can be applied is not stated — the apply page
  only says applying "while a test is still running" stops it.
  **Confidence: medium**, and this is the specific thing to confirm in the
  console.
- **Irreversibility.** No undo, so the shot list wants to be right first.
- **The icon stays behind.** Icon changes need a version regardless.
- **The measurement opportunity, if the test is killed on day one.** Applying
  stops the test. There is a cheap middle path: run the test properly for a
  few weeks first, then apply whichever treatment regardless of verdict. The
  screenshots land either way, and the read is free.
- **A 90-day clock** on the test, and — per the marketing page — possibly the
  app's only concurrent test slot.

**Confidence: high** that the route works as described; **medium-high**
overall, unchanged from #1067, because Apple still nowhere endorses PPO as
an update mechanism.

### Play: pointless

Play never gated listing assets on a build. Screenshots, icon, feature
graphic and both descriptions are edited directly in the console and
published through the ordinary review queue. An experiment adds a variant
step, a review, and an apply step to reach the same place, and if it is left
unapplied for six months "traffic will revert to the current listing".
**Use an experiment on Play only when the measurement is the point.**
**Confidence: high.**

Consequence for the map: the Play half of the listing change should just be
published, and the live debug-build screenshots
([#1082](https://github.com/simonoppowa/OpenNutriTracker/issues/1082)) fixed
directly, not routed through an experiment.

---

## What this changes for the measurement design (#1064)

1. **The confound has a documented answer on both platforms, and it is the
   randomisation, not the tool.** Both mechanisms assign users concurrently
   and at random, so both arms see the same binary at the same instant.
   2.2.0's rollout cannot differentially affect them. Neither vendor states
   this; it follows from concurrent random assignment. Apple's one stated
   caution is narrower — asset collision if the new version ships assets the
   test is varying. **Confidence: medium-high.**
2. **The metric is chosen for you, differently on each platform.** Apple
   fixes conversion = downloads / unique impressions. Play makes you pick
   one of three click metrics, whose definitions are Google's, not the
   analyst's. A cross-platform metric definition in #1064 must therefore be
   *two* definitions, not one, and Play's "unique user install clicks" is
   worth quoting verbatim in the ticket so a later session cannot silently
   report page-view conversion instead.
3. **The magnitude-of-change question can be answered before the baseline
   lands** — as an effect size the design is powered for, not a raw delta.
   The table above gives the shape; #1064's baseline traffic converts it
   into a yes or a no. Both consoles will also answer it directly: each has
   an estimator on its create page that consumes the app's own data. **That
   estimator reading is the single cheapest piece of evidence this map can
   collect**, and it needs a console session, not more research.
4. **Sequencing is not the only fallback.** If Play's estimator says the
   experiment is viable, Play gets a causal read and Apple gets before/after
   with the confound stated. A split verdict across the two stores is a
   legitimate outcome and better than forcing one design onto both.
5. **Play's "fully roll out your store listing" prompt is a possible
   blocker** on running an experiment at all while the listing is mid-change.
   Worth checking early, since it would sequence the experiment *after* the
   listing update rather than around it.

## Notes for #1080

- Both quotes the ticket rests on are verbatim and current. The route stands.
- Add two preconditions to the ticket's Route B: **app in Ready for
  Distribution** (satisfied — 2.0.2 is live), and **App Review of the
  treatment metadata, bundled with the latest iOS version record**. Route B
  is build-free, not review-free; the ticket's "for free" framing overstates
  it slightly.
- One free upgrade to Route B: applying a treatment can target the live page
  *and* a version in Prepare for Submission in the same action, so choosing
  Route B now does not mean re-uploading screenshots if a 2.2.1 is cut later.
- Route B's second-order benefit is real but weaker than the map hopes. PPO
  is a randomised test, so it does answer the confound — but on Apple's
  numbers this app is a likely *Likely to be Inconclusive*. **Take Route B
  for the delivery; treat the measurement as a bonus, not a plan.**
- Cheapest sequencing if the map wants both: start the test, let it run,
  apply the treatment when the screenshots are needed. The assets land on
  the schedule the map wants and the read costs nothing extra.

---

## Contradictions in primary sources

Four, all between two pages from the same vendor. None is resolved by
documentation alone.

1. **Apple, on testable elements.** ASC Help's *Configure test treatments*
   allows "app icon, screenshots, and previews". Analytics Help says PPO
   tests "screenshots, app previews, descriptions, and app icons" and its
   FAQ repeats "description". Resolved above in favour of the configuration
   flow.
2. **Apple, on concurrency.** The marketing page: "You can create one test
   at a time which will run for up to 90 days." The Analytics FAQ: "Can I
   run multiple tests simultaneously on different elements? Yes." Unresolved;
   assume one, and be pleasantly surprised.
3. **Google, on video.** Console-about: test "icons, videos, and
   screenshots". Help page asset lists and the Asset Library: no video.
   Resolved above in favour of the Help page.
4. **Google, on where the statistics are documented at all.** The Help page
   describes a confidence level and a minimum detectable effect as settings
   without publishing any value; the console-about page offers no statistics
   section. There is no Google page equivalent to Apple's metric definitions.

## Open questions

- **The estimator readings.** Both consoles will state, for this app, the
  duration and volume needed at a chosen effect size. Neither is obtainable
  without console access, and both would settle the viability question
  outright.
- **Which description field** a Play localized experiment varies — short,
  full, or both.
- **Whether a PPO treatment can be applied without ever starting the test.**
  Decides whether the pure asset-delivery route costs a 90-day test slot.
- **What Play does when an experiment overlaps a staged rollout.** Wholly
  undocumented; only observation will answer it.
- **Whether Play's confidence-level setting offers 90% or 95%,** which
  decides whether a Play and an Apple result can be stated on the same terms.
