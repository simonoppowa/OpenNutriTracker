# Competitor store-listing teardown

What the competing calorie trackers actually put on their store pages, which
of those conventions are load-bearing, and what a free, no-account,
open-source tracker can say that none of them can. Compiled 2026-09-04.

## Research overview

**Question:** what do the competing listings actually do, and what does that
tell us about the slots OpenNutriTracker has?

This is a listing teardown, not a feature comparison.
[`docs/competitive-feature-gaps.md`](competitive-feature-gaps.md)
(2026-08-08) covers features and is not repeated here.

**Sources (all fetched 2026-09-04):**

| Source | What it gives | Limits |
| :-- | :-- | :-- |
| `play.google.com` product pages, HTML fetched directly for 9 packages | Title, short description, full description, badge row (ads/IAP/Editors' Choice), Data safety summary, rating, install tier, update date, screenshot assets | Server-rendered en-US/US storefront only; ranking and search placement are invisible; Play A/B-tests listings, so one fetch is one variant |
| `apps.apple.com` product pages for 8 apps | Name, subtitle, description, In-App Purchase list with prices, price line | Subtitle and promotional text are not separately labelled in the page, so the split between them is inferred |
| iTunes Lookup API (`itunes.apple.com/lookup`) | Exact app name, version, release date, full description text, screenshot URLs at original resolution, rating counts | Does not expose the subtitle or promotional-text fields at all |
| The screenshot image files themselves, downloaded at original resolution and viewed | What the first two screenshots actually show — captions, framing, bleed, resolution | Only the first two per app were examined; the rest are unread |
| `f-droid.org` package pages for Waistline and Food You | Summary, description, licence, anti-feature labels | F-Droid is a third storefront with different conventions; not directly comparable to Play/App Store slots |
| This repo: `fastlane/metadata/android/en-US/`, `origin/develop` | What the repo believes the Play listing says | Repo state, not console state — the gap between them is itself a finding below |

**Method note on honesty.** Every title, subtitle, description opening and
price below was read off a live page or the Lookup API today. Screenshot
descriptions come from opening the image files and looking at them, not from
alt text — Play and the App Store ship no meaningful alt text on screenshot
assets, so anything not visible in the pixels is marked as unknown rather
than guessed.

**What could not be established:**

- **Play in-app-purchase price ranges.** The `$X - $Y per item` strings are
  present in the page payload but not reliably attributable to the subject
  app versus the "similar apps" carousel. App Store IAP prices *are*
  page-visible and are used instead.
- **Which listing variant is live.** Play runs store-listing experiments;
  a single fetch cannot tell a permanent listing from an active arm.
- **Food You has no Play or App Store listing** (`com.maksimowiczm.foodyou`
  returns 404 on Play; no App Store match). It is F-Droid-only, so it
  contributes only to the FOSS section.
- **Open Food Facts' current app is not on f-droid.org.**
  `org.openfoodfacts.scanner` 404s there; the F-Droid entry is the legacy
  native app, `openfoodfacts.github.scrachx.openfood`. Noted where used.
- **Keyword fields.** Apple's 100-character keyword field is console-only
  and invisible from outside. Nothing here says anything about it.

---

## The name slots

Play title: 30 characters. Play short description: 80. App Store name: 30.
App Store subtitle: 30.

| App | Play title | n | App Store name | n | App Store subtitle | n |
| :-- | :-- | --: | :-- | --: | :-- | --: |
| MyFitnessPal | `MyFitnessPal: Calorie Counter` | 29 | `MyFitnessPal: Calorie Counter` | 29 | `Workout & AI Nutrition Tracker` | 30 |
| Cronometer | `Cronometer: Calorie Counter` | 27 | `Cronometer: Calorie Counter` | 27 | `Nutrition, macro, diet tracker` | 30 |
| Lose It! | `Calorie Counter by Lose It!` | 27 | `Lose It! – Calorie Counter` | 26 | `Food Tracker for Weight Loss` | 28 |
| Yazio | `Yazio: AI Calorie Tracker` | 25 | `AI Calorie Tracker by Yazio` | 27 | `Food scanner for weight loss` | 28 |
| MacroFactor | `MacroFactor - Macro Tracker` | 27 | `MacroFactor - Macro Tracker` | 27 | `Calorie Counter & Food Log` | 26 |
| FatSecret | `Calorie Counter by fatsecret` | 28 | `Calorie Counter by fatsecret` | 28 | `Diet & Weight Loss Tracker` | 26 |
| Open Food Facts | `Open Food Facts` | 15 | `Open Food Facts - Product Scan` | 30 | `Food, Cosmetics & much more` | 27 |
| Waistline | `Waistline Calorie Counter` | 25 | — not on App Store — | | | |
| **OpenNutriTracker** | `OpenNutriTracker` | **16** | `OpenNutriTracker` | **16** | `Calorie & Nutrition Tracker` | 27 |

Play short descriptions, verbatim:

| App | Short description | n |
| :-- | :-- | --: |
| MyFitnessPal | `Track calories, macros & nutrition with AI. Log Fitness, workouts & meals daily` | 79 |
| Cronometer | `Macro and micronutrient tracker for accurate food, diet and nutrition analysis.` | 79 |
| Lose It! | `Lose weight & reach your health goals with Lose It! diet app and food tracker!` | 78 |
| Yazio | `Weight Loss w/o Dieting: Food, Diet & Keto Tracker to Plan Meals & Lose Weight` | 78 |
| FatSecret | `Diet and Weight Loss Tracker with Meal Planning and Food Nutrition Calculator` | 77 |
| Open Food Facts | `Scan barcodes to get Nutri-Score v2, Ultra-Processed (NOVA) & Carbon impact` | 75 |
| MacroFactor | `Reach your diet goals with the smartest macro tracker and nutrition coach` | 73 |
| Waistline | `A free as in speech and beer calorie counter and weight tracker.` | 64 |
| **OpenNutriTracker (live)** | `Simple and Open-Source Calorie and Nutrient Tracker` | **51** |
| OpenNutriTracker (repo, unpublished) | `A free and open source calorie tracker with focus on simplicity and privacy.` | 76 |

**Observations.**

- **Nobody in the mainstream group ships a brand-only name.** Six of six
  pair the brand with a category phrase, in both stores, and land at 25–29
  of 30 characters. Only the two open-source listings — Open Food Facts on
  Play (15) and OpenNutriTracker (16) — leave the field half empty.
  *Confidence: high; measured directly.*
- **Brand takes roughly a third of the field, no more.** MyFitnessPal
  spends 12 of 29 on the brand, Cronometer 10 of 27, MacroFactor 11 of 27.
  Three of the six put the keyword phrase *first* and the brand last
  (`Calorie Counter by Lose It!`, `Calorie Counter by fatsecret`,
  `AI Calorie Tracker by Yazio`). *Confidence: high.*
- **The two fields are not treated as one.** Every app that ships both a
  Play title and an App Store subtitle uses them for different phrases —
  MacroFactor's Play title says "Macro Tracker" while its App Store
  subtitle says "Calorie Counter & Food Log"; Yazio flips brand-first on
  Play to keyword-first on iOS. The coverage is deliberate, not copy-paste.
  *Confidence: high.*
- **Short descriptions run to the wall.** Seven of eight are 73–79 of the
  80 available. OpenNutriTracker's live 51 is the outlier by 22 characters,
  and its unpublished repo version (76) is already better on this measure.
  *Confidence: high.*
- **"Free" almost never appears in a name slot.** Not once in six
  mainstream titles, short descriptions or subtitles — because for them it
  is not true past the trial. Waistline is the only listing in the set that
  spends its short description on the licence rather than on keywords.
  *Confidence: high.*

---

## The first two screenshots

Read by opening the image files. "Framed" means a drawn phone bezel inside
the image; "full-bleed" means the app UI runs to the edges of the asset.

**MyFitnessPal** (Play and App Store use the same creative, re-shot per
device). Shot 1: flat blue field, wordmark top-left, headline **"The #1 Food
& Nutrition Tracking App"** over two overlapping tilted device frames. Shot
2: caption **"Scan Your Food"** over one upright device frame showing a meal
photo and three logged items with a "Log breakfast" button. Captioned,
framed, brand-coloured. Play listing carries a promo video ("Trailer").

**Cronometer** (same creative both stores). Shots 1 and 2 are **a single
continuous spread** — a dark overhead food photograph and one tilted device
that starts in frame 1 and finishes in frame 2. Shot 1 headline
**"Science-backed nutrition tracker."**, plus a 4.5-star row and **"Loved by
15+ million people."** Shot 2 is the wordmark and the rest of the device.
Play listing carries a promo video.

**Lose It!** Play shot 1: orange field, wordmark, headline **"Track Your
Calories & Nutrition"**, two tilted frames, cut-out food photography, and a
press-logo row — **"AS SEEN ON"** CNN, TODAY, People, Good Morning America,
Women's Health. Shot 2: **"Lose Weight"** over a weight-trend chart. The
App Store set uses a different headline on a navy field — **"The #1 Weight
Loss Tracker"** with the subhead "EASILY TRACK YOUR CALORIES & NUTRITION" —
and repeats the press row. Store-specific creative.

**Yazio** Play shot 1: pale-green field, tick-list **"Fasting / Calories /
Weight loss"**, a cartoon mascot, food photography, one device. Shot 2: a
laurel-wreath badge reading **"4.6 ★★★★ Play Store"** over a plate with AI
scan brackets. The App Store set swaps the badge to **"4,6 ★★★★ App
Store"** and shot 2 to the fasting timer plus a "Connect with" row of Apple
Health, Fitbit, Garmin and Polar logos. The rating badge is store-specific,
which means it is maintained by hand.

**MacroFactor** (same creative both stores). Shot 1 contains **no app UI at
all** — a studio photograph of tomatoes, the wordmark, and **"SMART MACRO
TRACKER"**. Shot 2: black field, **"LOG FOODS FASTER"**, one device frame
showing the food-search screen. The most confident set in the group: it
spends its most valuable slot on a mood image and a five-word claim.

**FatSecret** Shot 1: pale-green, **"Reach your weight loss goals"** with
subhead "with a better understanding of what you eat", over tilted
*fragments* of UI presented as floating cards rather than a device frame.
Shot 2: the community feed over the caption **"supported by a local
community of 12.9 million users worldwide that want you to reach your
goal"**. Same creative both stores.

**Open Food Facts** (same creative both stores). Shot 1 contains **no app UI
at all** — a flat illustration of a balance scale weighing a smiling face
against a globe, under **"Choose products that are good for YOU and the
PLANET"**, with the Nutri-Score and Eco-Score marks. Shot 2: **"Scan the
FOOD from your everyday LIFE"** over a photograph of a hand holding a
barcode. Illustration-led, no device frames.

**Waistline** (Play only, 5 assets, 413x733). Shot 1 and 2 are **raw,
uncaptioned, unframed, full-bleed app captures** — the Foods list and the
Diary. No headline, no brand, no colour field. The Diary screenshot is dated
**27 March 2021**.

**OpenNutriTracker, live today.**

- *Play:* **4 assets at 424x900** — below Play's recommended 1080px and just
  above its 320px floor. Each is a raw capture composited into a drawn
  Android bezel, with no caption and no colour field. Screenshot 1 shows the
  app bar reading **"OpenNutriTracker [Alpha]"** and a **red diagonal DEBUG
  ribbon in the top-right corner** — Flutter's debug banner, live on the
  store page. *Confidence: high; verified by cropping the asset.*
- *App Store:* 5 iPhone assets at **1242x2208** — the legacy 5.5" slot, not
  the 6.9" (1290x2796) that MyFitnessPal and Cronometer ship. Shots 1 and 2
  are a captioned continuous spread on a teal gradient. Shot 1 carries the
  logo, the name, and the bullets **"– Simple nutrition tracking / – Privacy
  Focused / – No Subscription, In-App Purchases or Ads / & more…"**. The
  device frame overlaps and clips the end of "In-App Purchases".
- *iPad:* 3 assets at 2064x2752 (correct 13" size), raw and uncaptioned —
  a mostly-empty Home screen with three logged items.

**Conventions that hold across all eight competing sets:**

1. **Screenshot 1 sells a claim, not a feature.** Six of eight open with a
   headline over a colour field. Two of those (MacroFactor, Open Food Facts)
   show no interface whatsoever in the first slot. Waistline is the only
   listing that opens with a raw capture, and it is also the weakest-looking
   listing in the set. *Confidence: high.*
2. **Screenshot 2 is the proof.** In every captioned set, slot 2 shows the
   single action the app is for — scanning a meal (MyFitnessPal, Yazio,
   Open Food Facts), searching a food (MacroFactor), the diary (Lose It!,
   Cronometer). *Confidence: high.*
3. **Text is large enough to read at carousel size.** Every caption in the
   set is a headline of three to seven words. OpenNutriTracker's iOS shot 1
   is the exception: four bullet lines at body size, which at thumbnail
   scale is a grey block. *Confidence: medium — thumbnail legibility is
   judgement, not measurement.*
4. **A device frame is optional; a caption is not.** Three of eight use no
   bezel at all. Eight of eight caption the first slot.
5. **The 1–2 pair is often one continuous image** (Cronometer,
   OpenNutriTracker on iOS). Cheap to do, and it makes the carousel read as
   designed rather than assembled.

**Cargo cult, on this evidence.** Star-rating badges baked into the
screenshot (Yazio, Cronometer) and press-logo rows (Lose It!) are the two
conventions most tied to scale — a "4.6 ★" badge over 856K reviews reads
differently from one over 225, and "AS SEEN ON CNN" is unavailable to an
app that has not been. Copying either at this size would look borrowed.
Promo videos are similarly optional: only the two largest listings have one.
*Confidence: medium; this is a judgement about how signals scale, not a
measurement.*

---

## The first line, before the fold

Play shows roughly the first three lines; the App Store shows about three
lines plus promotional text.

| App | First line of the store description |
| :-- | :-- |
| MyFitnessPal | "Achieve your nutrition, calorie, macro & fitness goals with MyFitnessPal – the AI-powered food & fitness tracker with everything you need." |
| Cronometer | "Cronometer is a powerful calorie counter, nutrition tracker, and food diary designed for accuracy." |
| Lose It! | "Lose It! Is your personal calorie counter, diet planner, nutrition-focused food tracker and weight loss progress tracking app…" |
| Yazio | "Welcome to Yazio, the #1 AI calorie counter and food tracker app for healthy eating and lasting weight loss without dieting!" (Play; the next three lines are ⭐ rows for rating, user count and an Android Excellence award) |
| MacroFactor | "MacroFactor combines innovative coaching algorithms with proven nutrition and behavioral science to help you reach your diet goals…" |
| FatSecret | "Welcome to fatsecret, the easiest to use calorie counter and most effective weight loss and dieting app on the market. Best of all, fatsecret is free." |
| Open Food Facts | "🔍 Scan, Discover & Compare Over 4 Million Food Products" (Play) |
| Waistline | "Waistline is a calorie counter and weight tracker that allows you to keep a diary of the food you eat and track variations in your weight." |
| **OpenNutriTracker** | "OpenNutriTracker is an open-source mobile application designed to simplify nutritional tracking and management." |

**Observations.**

- **Every mainstream first line is a value claim aimed at the reader.** They
  contain "your", "you", "achieve", "reach your goals". Three of the nine
  are self-definitions in the third person — Cronometer, Waistline and
  OpenNutriTracker — and of those, only Cronometer's carries a
  differentiator ("designed for accuracy"). *Confidence: high.*
- **"open-source mobile application" is spent describing the artefact, not
  the benefit.** It is the one line most readers see and it says what kind
  of software this is, not what it will do for them or what it will not do
  to them. *Confidence: high; this is the observation, the fix is a
  decision for the copy ticket.*
- **Two apps use App Store promotional text** — a separate 170-character
  field rendered above the description, which can be changed without a
  review. MacroFactor's is its Play short description verbatim ("Reach your
  diet goals with the smartest macro tracker and nutrition coach"); Open
  Food Facts' is "Decode Ultra-Processed Foods (UPF) instantly. Powered by
  the official NOVA classification—100% independent, ad-free, and trusted
  worldwide for years." The other six, and OpenNutriTracker, leave it empty.
  *Confidence: medium — inferred from the page showing text that is absent
  from the Lookup API's description field, which is how that field behaves.*

---

## The free/paid boundary

**Play badge row, directly under the title:**

| App | Developer shown | Ads | IAP | Rating / reviews | Installs |
| :-- | :-- | :-- | :-- | :-- | :-- |
| MyFitnessPal | MyFitnessPal, Inc. | yes | yes | 4.4 / 2.91M | 100M+ |
| Yazio | Yazio | yes | yes | 4.4 / 856K | 50M+ |
| FatSecret | fatsecret | — | yes | 4.5 / 546K | 50M+ |
| Lose It! | FitNow, Inc. | yes | yes | 4.6 / 183K | 10M+ |
| Cronometer | Cronometer Software Inc. | yes | yes | 4.6 / 57.8K | 5M+ |
| MacroFactor | Stronger By Science Technologies LLC | — | yes | 4.7 / 16.5K | 1M+ |
| Open Food Facts | Open Food Facts | — | — | 4.1 / 7.59K | 1M+ |
| Waistline | David Healey | — | — | 4.0 / 194 | 10K+ |
| **OpenNutriTracker** | **simonO** | — | — | **3.4 / 225** | 10K+ |

**App Store subscription prices** as listed in each page's In-App Purchase
block, which shows several regional and legacy tiers per app rather than one
price: MyFitnessPal Yearly Premium $79.99; MacroFactor annual $71.99 (its
description states $11.99/month, $47.99/half-year, $71.99/year); Cronometer
Gold Annual $59.99; FatSecret Annual $59.99; Lose It! Premium tiers from
$9.99 to $79.99 plus a $49.99–$59.99 lifetime; Yazio 12 Months $23.90–$47.90.
All six carry `Free · In-App Purchases` in the price line. Open Food Facts
and OpenNutriTracker show `Free` with no IAP block at all.

**Where the paywall first appears in the App Store description**, as a
percentage of the way through:

| App | First paywall word | Position |
| :-- | :-- | --: |
| MacroFactor | "7-day trial … this premium, ad-free macro tracker app" | 8% |
| MyFitnessPal | "start your free Premium trial today" | 16% |
| Lose It! | "PREMIUM PLAN FEATURES" | 51% |
| FatSecret | "Premium subscriptions are available…" | 63% |
| Yazio | "Go Pro for faster results." | 68% |
| Cronometer | "Upgrade to Cronometer Gold" | 78% |
| Open Food Facts | none in 3,851 characters | — |
| **OpenNutriTracker** | "No Subscription, In-App Purchases, or Ads" | **86%** |

**Observations.**

- **The boundary is never in the top slots.** Not in a single title,
  subtitle, short description or first-two-screenshot caption across six
  paid apps. Where it appears early, it appears as an *offer* — a free trial
  (MacroFactor at 8%, MyFitnessPal at 16%) — never as a price. The
  auto-renewal terms sit in the last quarter of the description in all six,
  which is the minimum both stores require and the maximum distance from
  the fold. *Confidence: high; measured.*
- **The badge row does the disclosing instead.** "In-app purchases" under
  the title is the only thing on a Play page that reliably tells a browsing
  user the app is not free, and it is six words of grey text the developer
  does not control. **Its absence is equally uncontrolled — and equally
  visible.** OpenNutriTracker, Waistline and Open Food Facts are the only
  three listings in the set with a clean badge row. *Confidence: high.*
- **OpenNutriTracker currently buries its own strongest sentence in the
  same place its competitors bury the thing they want hidden.** "No
  Subscription, In-App Purchases, or Ads" sits at 86% of a 1,128-character
  description — below the fold, next to where MacroFactor prints its
  auto-renewal terms. It appears in the iOS screenshot-1 bullet list, at
  body size, partly clipped by a phone bezel. It does not appear in either
  title, either subtitle, either short description, or anywhere on the Play
  screenshots. *Confidence: high; this is the single clearest finding in
  this document.*
- **The App Store description is 1,128 characters of the 4,000 available**
  (28%); the live Play description is ~1,179 of 4,000. Every mainstream
  competitor runs 3,366–3,991. *Confidence: high.*

---

## How the FOSS peers present privacy and openness

**Waistline** (Play + F-Droid) is the only listing in the whole set that
spends a *name slot* on the licence: the 64-character Play short description
reads `A free as in speech and beer calorie counter and weight tracker.` The
second sentence of its description is the privacy claim, above the fold:

> "All data is kept on your device, it's never shared with a server or
> uploaded to the 'cloud' … but it can be exported or imported easily when
> needed."

Its Play **Data safety** card reads **"No data shared with third parties"**
and **"No data collected"** — the strongest possible version of that card,
and it renders on the product page itself, immediately under the
description. F-Droid summary: "Libre calorie counter and weight tracker";
licence GPL-3.0-only; no anti-features.

The execution is the opposite of the claim's strength: 5 raw uncaptioned
screenshots, one dated 2021, no colour field, no headline. Waistline
demonstrates that the claim can be made in the top slots — and, separately,
that making it there does not by itself produce a good listing.

**Food You** is F-Droid-only. Name `Food You - Calorie Tracker & Food Diary`
(39 chars — F-Droid has no 30-char ceiling), summary `Track your calories
with Material You aesthetic`, licence GPL-3.0-or-later, no anti-features.
Its description opens "Food You is a powerful, open-source nutrition tracker
built with a modern Material You aesthetic." **It leads on design, not on
privacy or licence** — the only FOSS peer here that does.

**Open Food Facts** (Play + App Store) does not sell openness as a privacy
promise; it sells it as a **mission and a data asset**. The Play description
opens on scale ("Over 4 Million Food Products") and reaches for "we're kind
of 'the Wikipedia of food'". The word that carries the values load is
"independent", in the App Store promotional text: "100% independent, ad-free,
and trusted worldwide for years." Its Play Data safety card says "No data
shared with third parties" but does declare collection of "Personal info,
App activity, and App info and performance". Its first screenshot is an
illustration about food and the planet, with no app in it.

**F-Droid gives openness a structural slot that neither store has** — a
licence field and machine-checked anti-feature labels. The legacy Open Food
Facts entry there carries two: "This app promotes or depends entirely on a
non-free network service" and "This app tracks and reports your activity".
On Play and the App Store there is no such field, so openness has to be paid
for out of the same characters as the keywords. That is the trade the copy
decision has to make consciously. *Confidence: high.*

**The uncomfortable adjacency.** OpenNutriTracker's Play Data safety card
currently reads: *"This app may share these data types with third parties:
App activity"*, *"This app may collect these data types: Location and App
info and performance"*, and *"Data can't be deleted."* Waistline's, two
search results away, reads "No data collected". Whatever the declaration's
accuracy, that card sits directly under a description whose selling point is
privacy, and every mainstream competitor's card at least says "You can
request that data be deleted". Changing the declaration is explicitly out of
scope for map #1062 (closed by map #935) — this is recorded here only
because it is part of what a reader of the listing sees.
*Confidence: high on what the card says; no claim made about whether it is
correct.*

---

## Where OpenNutriTracker's listings actually stand

Four things fell out of fetching the live pages that bear directly on
map #1062 and were not visible from inside the repo.

1. **The repo metadata has never reached Play.** Live Play short description
   is `Simple and Open-Source Calorie and Nutrient Tracker` (51 chars); the
   repo's is `A free and open source calorie tracker with focus on
   simplicity and privacy.` (76). Live Play description is ~1,179
   characters; `origin/develop`'s `full_description.txt` is 3,952. The
   listing is not a stale copy of the repo file — it is a different text
   entirely. Confirms the map's premise from the outside.
   *Confidence: high.*
2. **The App Store listing is on v2.0.2, released 2026-08-05**, while v2.2.0
   was tagged 2026-09-01. The Play listing shows "Updated on Aug 8, 2026".
   Every mainstream competitor's Play listing updated between Aug 26 and
   Sep 4. The version string in App Store Connect is also `v2.0.2` — with a
   leading `v`, which no competitor has. *Confidence: high.*
3. **A debug build is on the store page.** Play screenshot 1 carries
   Flutter's red DEBUG ribbon and an app bar reading "OpenNutriTracker
   [Alpha]". Both Play screenshot 1 and 2 do. *Confidence: high; verified
   by cropping the live asset.*
4. **Play has 4 screenshots at 424x900; iOS has 5 at the legacy 5.5"
   1242x2208 size and 3 iPad assets.** Competitors ship 8–20 assets per Play
   listing and 8–10 per iPhone listing at 6.9". *Confidence: high for
   OpenNutriTracker's own numbers; the competitor Play counts combine phone
   and tablet sets and are therefore upper bounds.*

---

## What this says about the slots we have

**Load-bearing** — do these:

1. **Fill the title field.** 14 unspent Play characters and 14 unspent App
   Store name characters, in a category where all six mainstream apps run
   25–29. This is the single highest-leverage unspent asset on either page.
2. **Fill the short description.** 29 unspent Play characters, and the
   repo's replacement already recovers 25 of them.
3. **Caption screenshot 1 with a claim, and screenshot 2 with the action.**
   Eight of eight competitors do; the two strongest-looking sets show no UI
   at all in slot 1.
4. **Make screenshot text headline-sized.** Everything else in the carousel
   is three to seven words at display weight.
5. **Ship at the current device sizes** — 1080px+ on Play, 6.9" (1290x2796)
   on iPhone — and ship a release build.

**Cargo cult** — skip these:

- Baked-in star-rating badges and press-logo rows. Both are scale signals;
  at 225 reviews and 10K+ installs they invert.
- "#1" and "most effective" superlatives. Five of six competitors use one.
  They are unverifiable here and cost the one thing this listing has.
- Promo videos. Only the two largest listings carry one.
- A 4,000-character description. Length is not the win; the first line and
  the first two screenshots are. Fill them before filling the rest.

**The opening none of them can take.** Every mainstream competitor's page is
built to *defer* the money conversation: never in the name, never in the
subtitle, never in the first two screenshots, and the auto-renewal terms in
the last quarter. That means the top of every competitor page is a place
where the word "free" cannot be used honestly — and Play's own badge row
says so, in grey, under every one of their titles.

OpenNutriTracker is one of three listings in this set with a clean badge
row, and the only one of those three that is a general-purpose calorie
tracker with an App Store presence. Today it says so at 86% of the way down
the description, in body text, partly hidden by a phone bezel. Saying it in
the title, the subtitle, the short description and the first screenshot
caption is the one move on this page that no competitor can answer without
changing their business.

The second, narrower opening: **no account**. Every mainstream competitor
gates the first screen behind a sign-up; none of them mentions it, because
none of them can. It is not currently claimed anywhere in either listing.
*Confidence: medium — the account requirement is inferred from the
competitors' own descriptions and Data safety declarations of personal-info
collection, not from installing and running each app.*

---

## Open questions

- **Which of the two claims converts better — "free forever" or "no
  account"?** Both are true, both are unavailable to competitors, and the
  title has room for one. This is exactly what Play's Store Listing
  Experiments answer, and the map already has an open question about whether
  traffic supports them.
- **Does naming the licence help or hurt outside F-Droid?** Waistline's
  "free as in speech and beer" is the boldest short description in the set
  and its listing performs no better than OpenNutriTracker's on rating.
  One data point, confounded by everything else about that listing.
- **Is the 3.4 rating a listing problem or a product problem?** 3.4 across
  225 reviews sits 1.0–1.3 below every competitor here and is the most
  visible number on the Play page — more visible than any copy this map
  will change. Reading the 1–3★ reviews is the cheap next step, and
  `docs/competitive-feature-gaps.md` already flagged that channel as the
  only place dissatisfied non-filers speak.
- **What does the live feature graphic look like?** Not fetchable from the
  product page in a form that distinguishes it from the icon; the repo's is
  512x250 against Play's required 1024x500.
- **Is the App Store subtitle being wasted on a synonym?** `Calorie &
  Nutrition Tracker` repeats what the name already implies once the name is
  fixed. Competitors use the subtitle for a *second* keyword cluster, not a
  restatement.
