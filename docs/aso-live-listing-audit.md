# Live store listing audit

What the Google Play and App Store listings actually say and show, captured
2026-09-04 from outside either console. The baseline the store-listing
effort diffs against.

## Research overview

**Question:** what is live on each store right now — every text field,
every image, at what character count and what pixel size — and where does
that differ from what the repository holds?

**Sources (triangulated):**

| Source | What it gives | Limits |
| :-- | :-- | :-- |
| Apple iTunes Lookup API (`itunes.apple.com/lookup?id=6451490901`) | Version, release date, categories, description, release notes, screenshot URLs, minimum OS, supported devices | Exposes no subtitle, no keyword field, no promotional text, no support or marketing URL. Storefront-specific (US read here) |
| Apple web product page, rendered DOM (`apps.apple.com/us/app/.../id6451490901`) | Subtitle, the single developer link, privacy-policy URL, rendered age rating | Server-rendered Svelte; the raw HTML needs the embedded JSON parsed, not regex over markup. Shows what Apple chooses to render, which is not the same as what the console holds |
| Google Play web listing, rendered DOM and embedded page data | Title, short description, full description, screenshot and graphic URLs with declared dimensions, What's new, last-updated date | Obfuscated positional JSON — field meaning is inferred from shape, not names. Serves the phone listing; a tablet listing is not necessarily rendered here |
| The image binaries themselves, downloaded at source resolution (`=s0` for Play, `9999x9999bb` for Apple) | Native pixel dimensions and actual visible content | Apple re-encodes uploads; dimensions are the stored asset, not necessarily the uploaded file |
| `fastlane/metadata/android/en-US/` on `origin/develop` | The repository's Play metadata | Lives on `develop`, not `main`. Never pushed to Play — see below |

**Every field below was read, not inferred.** Where a field could not be
read it is named in *What still needs a console visit* rather than guessed.
Character counts are of the rendered text; where a trailing newline changes
the number, that is stated.

**Two things this audit corrects** in what map #1062 and ticket #1063
recorded before it:

- **Apple's subtitle is publicly readable.** It is rendered on the web
  product page in a `<p class="subtitle">` element under the app name, and
  appears again in the page's embedded lockup JSON for adamId
  `6451490901`. It is not console-only. The keyword field genuinely is.
- **Play's live debug-capture defect is larger than filed.** #1082 reports
  the first two screenshots. All four are debug builds, and four is the
  entire live set.

---

## Google Play

App id `com.opennutritracker.ont.opennutritracker`. Listing last updated
**2026-08-08**. Developer shown as **simonO**. Category Health & Fitness.
3.4 stars, 225 reviews, 10K+ downloads.

### Title — identical to the repo

Live: `OpenNutriTracker` — **16 characters of 30**.
Repo `title.txt`: `OpenNutriTracker` — identical.

**No diff.** Both leave 14 characters unspent, which is the gap #1065 and
#1066 independently landed on.

### Short description — the repo text was never pushed

Live, verbatim:

> Simple and Open-Source Calorie and Nutrient Tracker

**51 characters of 80.**

Repo `short_description.txt`, verbatim:

> A free and open source calorie tracker with focus on simplicity and privacy.

**76 characters** (77 bytes with the trailing newline — map #1062's "77"
counts the newline).

**Diff: two entirely different sentences.** Neither is a revision of the
other. 29 characters of the field go unused live.

### Full description — the live text is the pre-2.0 copy

Live, verbatim (`<br><br>` after the opening paragraph, single `<br>`
between bullets):

> OpenNutriTracker is an open-source mobile application designed to
> simplify nutritional tracking and management. Whether you are looking to
> improve your health, lose weight, or simply maintain a balanced diet,
> OpenNutriTracker provides a minimalistic interface to easily track and
> analyze your daily nutrition.
>
> - Nutritional Tracking: Easily log your meals and snacks, and access a
>   vast database of food items and ingredients to get detailed
>   nutritional information.
> - Food Diary: Maintain a comprehensive food diary to keep track of your
>   daily food consumption, habits, and progress.
> - Custom Meals: Plan your meals in advance, create personalized meal
>   plans, and optimize them according to your dietary goals.
> - Barcode Scanner: Scan barcodes on packaged food items to instantly
>   retrieve their nutritional information.
> - Privacy Focused: OpenNutriTracker prioritizes the privacy its users.
>   It does not collect or share any personal data without your consent.
> - No Subscription, In-App Purchases, or Ads: OpenNutriTracker is
>   completely free to use, without any subscription fees, in-app
>   purchases, or intrusive advertisements.

**1,127 characters of 4,000** as rendered. (Map #1062's "roughly 1,179" was
a close estimate; the measured figure is 1,127.)

Repo `full_description.txt`: **3,952 characters**, 16 emoji-led bullets,
rewritten for 2.2.0 on 2026-09-04 in commit `808dcfef` (#1049).

**Diff: a complete replacement, never applied.** Six plain bullets against
sixteen emoji bullets. The live copy mentions none of Trends, the
micronutrient panel, recipes, quick add, AI meal assistance, workout
import, water, fasting, weight history, themes, kJ, or export/import. It
carries no "not a medical device" disclaimer. `- Privacy Focused:
OpenNutriTracker prioritizes the privacy its users` contains a live
grammatical error ("the privacy its users").

**The same text is live on the App Store**, to within one newline. Whatever
was pasted was pasted into both stores at once and never revisited.

**Confidence:** high. Read from the rendered DOM and cross-checked against
the embedded page data.

### What's new — a 2.0 note, matching no file in the repository

Live, verbatim:

> Version 2.0 is the biggest update yet — a redesigned app from the home
> screen up.
> • New look across every screen, with settings gathered into the You tab
> • Trends tab: streaks, calories against your goal, macro averages, water
>   and weight
> • Multiple profiles on one device
> • Bigger food database: Open Food Facts, USDA and BLS
> • Quick add for meals and activities
> • Separate units for food, height and weight
> • Reworked onboarding with a demo mode

The repository holds two changelogs: `changelogs/12.txt` ("Initial Fdroid
release") and `changelogs/63.txt` (build 63 = 2.2.0, the TDEE correction).
**The live text matches neither.** It is a hand-written 2.0 note, and it is
also *not* the App Store's 2.0 note, which is a much longer sectioned
document. Three different release notes exist for the same release.

The listing's last-updated date of **2026-08-08 predates the v2.2.0 tag of
2026-09-01**, so 2.2.0's store listing has not been touched on Play either.
Play does not publish a version number on the product page; the `2.0.2`
string in the page data belongs to a *reviewer's* app version, not the
listing. **The live Play build version cannot be read publicly.**

### Screenshots — four, all debug builds, all 424x900

There are **four** phone screenshots. Every one is 424 x 900 native, and
every one carries Flutter's red `DEBUG` ribbon in the top-right corner.

| # | Native | Shows | Artifacts |
| :-- | :-- | :-- | :-- |
| 1 | 424x900 | Pre-2.0 dark home screen: 2349 kcal left ring, 1016 supplied / 770 burned, macro rings, Activity row (bicycling, bowling), Breakfast strip. Home/Diary/Profile nav | `DEBUG` ribbon; app bar reads **OpenNutriTracker [Alpha]**; a stray **"Added new intake"** snackbar caught mid-animation covering the bottom of the screen |
| 2 | 424x900 | Meal detail for Crownfield Corn flakes, 379 kcal/100 g, quantity 100 g, green Add button | `DEBUG` ribbon |
| 3 | 424x900 | Activity picker: search field, All/Recently tabs, list of bicycling, mountain, unicycling, stationary, calisthenics, resistance training | `DEBUG` ribbon |
| 4 | 424x900 | Profile: 22.9 BMI, Normal Weight, Activity/Goal/Weight/Height/Age rows. Home/Diary/Profile nav | `DEBUG` ribbon |

Repo `images/phoneScreenshots/` holds **six** PNGs at **1080 x 2205**,
clean release builds of the post-2.0 UI (light theme, Home/Diary/Trends/You
nav, fasting chip, water chip).

**Diff: four low-resolution debug captures of a pre-2.0 build live, against
six clean 2.6x-larger post-2.0 captures sitting unused in the
repository.** The live set is 21% of the repo set's pixel area.

Play's minimum is 320 px on the shorter side, so 424x900 is not a policy
violation — it is merely the smallest thing that would upload.

**#1082 needs widening from two screenshots to four.** The `[Alpha]` app-bar
title appears on shot 1 only, but that is because shots 2–4 are not on the
home screen; the ribbon is on all four.

**Confidence:** high. Every asset downloaded at source resolution and
viewed.

### Feature graphic — live is correct, the repo copy is half-size

Live feature graphic: **1024 x 500**. A white field, the green concentric
spoon mark centred, the wordmark "OpenNutriTracker" beneath in black.

Repo `images/featureGraphic.png`: **512 x 250** — the same artwork at
exactly half the linear dimension.

**Diff, and it runs the other way from every other field.** Play requires
1024x500 and the live asset meets it. The repository holds the
non-compliant copy. Anything that ever pushes repo metadata to Play would
*downgrade* the live feature graphic below Play's own requirement. Map
#1062's open question — "either the live asset differs from the repo copy,
or it predates the requirement" — resolves to **the live asset differs**.

Live icon is 512 x 512, matching `images/icon.png`.

### Tablet screenshots — none

The listing's embedded image data contains exactly three groups: the four
phone screenshots, the 512x512 icon, and the 1024x500 feature graphic. No
7-inch or 10-inch screenshot array is present, and the page renders no
tablet carousel.

**Confidence:** medium-high. This is the phone listing as served to a
desktop browser; the absence of a tablet array in the same payload that
carries every other asset is strong evidence, but the console is the only
place that shows an empty slot as distinct from an unrendered one.

---

## App Store

App id `6451490901`, bundle `com.opennutritracker.ont.opennutritracker`.
Live record **v2.0.2, released 2026-08-05**; first release 2025-05-12.
Health & Fitness (primary) / Food & Drink (secondary). Minimum iOS 15.5.
4.2 stars, 14 ratings. English only (`languageCodesISO2A: ["EN"]`).

### Name and subtitle

| Field | Live value | Spend |
| :-- | :-- | :-- |
| Name | `OpenNutriTracker` | 16 of 30 |
| Subtitle | `Calorie & Nutrition Tracker` | 27 of 30 |

**The subtitle is publicly readable and was previously believed not to be.**
It renders in a `<p class="subtitle">` under the app name and appears in the
page's embedded lockup JSON as both `subtitle` and `developerTagline`, keyed
to adamId `6451490901`.

Worth noting against #1069: the App Store subtitle already carries the
descriptive keyword phrase the Play listing lacks entirely. The two stores
are not in the same position on this.

### Description — the same pre-2.0 copy as Play

**1,128 characters of 4,000.** Byte-for-byte the Play full description
above, except Apple's copy has one additional newline after the opening
paragraph (three, against Play's two). Same six bullets, same "the privacy
its users" error.

### What's New — 2,792 characters, still announcing 2.0

Opens "Version 2.0 is the biggest update OpenNutriTracker has had — a
redesign that touches every screen, plus a much larger food database and a
proper Trends tab." Sectioned into A new look / Trends / Food database /
Faster logging / Profiles and units / Onboarding / Accessibility / Fixes,
closing with a contributor thank-you naming five people.

This is a substantially different document from Play's seven-bullet 2.0
note. Neither 2.1.0 nor 2.2.0 has reached the App Store.

### Screenshots — 5 iPhone in a legacy slot, 3 iPad that do meet the 13" rule

**iPhone: 5 shots, all 1242 x 2208.** That is the **5.5-inch (iPhone 8
Plus)** display class, and Apple's stored filenames confirm it —
`..._Apple_iPhone_8_Plus_Screenshot_0.png` through `_4.png`.

| # | Shows | Artifacts |
| :-- | :-- | :-- |
| 1 | Green-to-blue gradient panel, logo, "OpenNutriTracker" and the bullets "Simple nutrition tracking / Privacy Focused / No Subscription, In-App Purchases or Ads / & more…", with an angled device showing the pre-2.0 dark home screen | Clean |
| 2 | Angled device, pre-2.0 dark home screen, 2935 kcal left, 825 burned, fat and protein rings | App bar reads **"…NutriTracker [Alpha]"** |
| 3 | Caption **ADD MEALS** over a straight-on bezel; meal detail for Crownfield Corn flakes, 379 kcal/100 g | Simulator `Carrier` placeholder in the status bar |
| 4 | Bottom-anchored device, Profile screen, 24.5 BMI, Normal Weight, Activity/Goal/Weight/Height. Caption **CHECK PROGRESS** beneath | Clean |
| 5 | Caption **Scan Products**; barcode scanner live camera view over a juice carton with a Nutri-Score label | Simulator `Carrier` placeholder |

**A second debug artifact, on the App Store this time.** iPhone shot 2
carries the same `[Alpha]` app-bar title as Play's shot 1. #1082 is filed
against Play only; the artifact class spans both stores.

All five show the pre-2.0 UI — three-tab Home/Diary/Profile nav, no Trends
tab.

**iPad: 3 shots, all 2064 x 2752.** Apple's stored filenames read
`Simulator_Screenshot_-_iPad_Pro_13-inch_(M4)_-_2025-05-11_at_20.11.48.png`
and two siblings a minute later.

| # | Shows | Notes |
| :-- | :-- | :-- |
| 1 | Full pre-2.0 home screen: 2689 kcal left, Activity, Breakfast with three items, empty Lunch/Dinner/Snack | Raw capture, no caption, no bezel |
| 2 | Meal detail for Kellogg's Corn Flakes with the full Nutrition Information table and the Open Food Facts disclaimer | Bottom ~35% of the screen is empty black |
| 3 | Profile: 21.9 BMI, Activity/Goal/Weight/Height/Age/Gender | Bottom ~55% of the screen is empty black |

**2064 x 2752 is exactly Apple's 13-inch iPad display size**, so the live
iPad set does satisfy the current 13" requirement. Map #1062's assumption
that a 13" set would need creating from scratch is wrong on the dimension —
what it needs is *replacing*, for content reasons: raw uncaptioned
simulator captures of a pre-2.0 build, two of the three more than half
empty because the phone layout does not fill a tablet width.

Neither device class has its slots full (Apple allows 10 per class).

**Confidence:** high. All eight assets downloaded at source resolution and
viewed.

### Links

The page carries exactly **one** developer link, labelled **Support**,
pointing at `https://github.com/simonoppowa/OpenNutriTracker`. Privacy
Policy points at `https://www.iubenda.com/privacy-policy/53501884`.

There is **no Developer Website row**. Apple renders one when a marketing
URL is set, so the marketing URL is probably empty — but "probably" is the
honest word, and it is listed below as needing confirmation.

### One discrepancy worth someone's attention, outside this map

The web product page renders **Age Rating 9+**. The Lookup API returns
`contentAdvisoryRating: "4+"` and `trackContentRating: "4+"` for the same
record on the same day. That is a listing-metadata inconsistency, not an
ASO copy question, and it is not this map's territory — but nobody has
recorded it anywhere, so it is recorded here.

---

## The diff in one table

| Field | Live | Repo (`origin/develop`) | Verdict |
| :-- | :-- | :-- | :-- |
| Play title | `OpenNutriTracker`, 16/30 | identical | no diff |
| Play short description | 51 chars | 76 chars, different sentence | never pushed |
| Play full description | 1,127 chars, pre-2.0, 6 bullets | 3,952 chars, 2.2.0, 16 bullets | never pushed |
| Play What's new | 2.0 note, 7 bullets | `63.txt` is the TDEE fix; `12.txt` is the F-Droid note | matches neither |
| Play phone screenshots | 4 x 424x900, **all DEBUG** | 6 x 1080x2205, clean, post-2.0 | never pushed; live set defective |
| Play tablet screenshots | none | none | no diff |
| Play feature graphic | **1024x500**, compliant | **512x250**, half-size | repo is the worse copy |
| Play icon | 512x512 | 512x512 | no diff |
| App Store name | `OpenNutriTracker`, 16/30 | not in repo | — |
| App Store subtitle | `Calorie & Nutrition Tracker`, 27/30 | not in repo | — |
| App Store description | 1,128 chars, same pre-2.0 copy as Play | not in repo | — |
| App Store What's New | 2,792 chars, 2.0 | not in repo | — |
| App Store iPhone shots | 5 x 1242x2208 (5.5" legacy), one `[Alpha]` | not in repo | — |
| App Store iPad shots | 3 x 2064x2752 (13", compliant), uncaptioned | not in repo | — |

---

## Debug and capture artifacts found

1. **All four live Play screenshots carry the red `DEBUG` ribbon**, not the
   two recorded in #1082. Since the live set *is* four, the whole listing
   is debug captures.
2. **Play shot 1 additionally shows `OpenNutriTracker [Alpha]`** in the app
   bar and a stray **"Added new intake"** snackbar caught mid-animation,
   obscuring the bottom of the screen.
3. **App Store iPhone shot 2 shows `[Alpha]`** in the app bar. The same
   defect class, on the store #1082 does not cover.
4. **App Store iPhone shots 3 and 5 show the simulator's `Carrier`
   placeholder** in the status bar — cosmetic, but it marks them as
   unpolished simulator output.
5. **App Store iPad shots 2 and 3 are 35% and 55% empty black** — the phone
   layout stretched to a tablet width with nothing filling it.

---

## What still needs a console visit

Confirmed unreadable from outside, having tried both the Lookup API and the
rendered web page:

**App Store Connect**

- **The 100-character keyword field.** Not in the Lookup API response, not
  in the product page DOM, and not in its embedded JSON. The page's only
  `keywords` key is schema.org markup whose value is the two genre names
  (`["Health & Fitness", "Food & Drink"]`) — not the ASO field. **Verified
  absent, not assumed.**
- **Promotional text.** No `promotionalText` key anywhere in the page. The
  rendered description is character-identical to the Lookup API's
  `description`, which excludes promotional text — so it is *probably*
  unset rather than hidden. The console distinguishes those two; nothing
  public does.
- **The marketing URL.** Only a Support link renders. Probably unset;
  cannot be proven from outside.
- **Where 2.2.0 sits** — never submitted, or submitted and pending. The
  live record showing 2.0.2 does not separate those, and #1080's
  build-or-no-build fork turns on it.

**Play Console**

- **Store listing experiment state.** Whether any experiment is running,
  has run, or is possible at this install volume. Nothing about experiments
  surfaces on the public listing.
- **Whether tablet screenshot slots are empty or merely unrendered.** The
  public payload shows no tablet array; the console shows the slot.
- **The live build version.** Play publishes no version number on the
  product page.
- **Custom store listings**, if any exist.

Not console-only, contrary to what #1063 and #1062 recorded:
**Apple's subtitle**, which reads `Calorie & Nutrition Tracker` and is
rendered on the public product page.

---

## Open questions

- **Is the App Store description a separate paste or the same one?** The
  two stores' copy differs by exactly one newline, which suggests one
  source pasted twice — but the *release notes* differ substantially
  between the stores, which suggests they are maintained separately. Which
  it is changes whether one drafting surface can serve both.
- **Why is the live feature graphic compliant when the repo copy is not?**
  Someone uploaded a 1024x500 asset that was never committed. If the
  source file still exists it is worth committing over the 512x250 copy
  before any automation can push the smaller one.
- **When were the live Play screenshots taken?** They show a pre-2.0 build
  with the `[Alpha]` title, which predates the App Store's 2025-05-11
  simulator captures. Nothing dates them from outside.
- **Does the 9+ / 4+ age-rating split matter?** It is inconsistent today.
  Not this map's problem, but it is nobody else's either yet.

Prior competitive work is in `docs/competitive-feature-gaps.md`, which
compares features rather than listings and lives on `develop`.
