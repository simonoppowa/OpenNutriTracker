# Store listing policy limits

The fence the 2.2.0 listing copy and screenshots must be drafted inside,
for a health-and-fitness app with an experimental bring-your-own-key AI
feature. Compiled 2026-09-04 for [#1068](https://github.com/simonoppowa/OpenNutriTracker/issues/1068),
a child of map [#1062](https://github.com/simonoppowa/OpenNutriTracker/issues/1062).

## Research overview

**Question:** what may and may not be said in the Google Play and App
Store listings — the text and the images, not the declarations — given a
health app that ships an experimental, off-by-default, bring-your-own-key
AI feature?

**Sources (primary unless labelled):**

| Source | What it gives | Limits |
| :-- | :-- | :-- |
| Google Play — [Health Content and Services](https://support.google.com/googleplay/android-developer/answer/12261419) | The two sentences Play requires *in the app description*; health-misinformation ban; sensor and external-hardware disclosure duties | Written around medical devices and oximetry. Silent on nutrition estimation, and silent on AI |
| Google Play — [Metadata](https://support.google.com/googleplay/android-developer/answer/9898842) | The honest/relevant/all-audiences standard covering description, title, icon, screenshots and promo images | The standard is qualitative; every worked example is an egregious case, so the margin is unmapped |
| Google Play — [Deceptive Behavior → Misleading Claims](https://support.google.com/googleplay/android-developer/answer/9888077) | The binding prohibition on false or misleading claims in description, title, icon and screenshots | No example anywhere near "feature exists but needs a key you supply" |
| Google Play — [AI-Generated Content](https://support.google.com/googleplay/android-developer/answer/13985936) | Scope definition of AI-generated content; the in-app reporting requirement | Scope examples are chatbots and generated images/video. A structured meal parser is outside them — but only as long as the listing says so |
| Google Play — [Declaring AI-generated content in Play Console](https://support.google.com/googleplay/android-developer/answer/17262077) | Per-asset AI self-declaration; declared assets get an AI label on the store | Undated. "Certain circumstances" is never defined. Asset-level only — says nothing about listing prose |
| Google Play — [Add preview assets](https://support.google.com/googleplay/android-developer/answer/9866151) | Screenshot, feature-graphic and video rules, split into "Requirements" and "Highly recommended" | The split is the whole story here and is easy to misread; most screenshot content rules are recommendations |
| Apple — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) | 1.4.1 (medical), 2.3.1–2.3.12 (accurate metadata), 4.7 (chatbots), 5.1.2(i) (third-party AI), 5.1.3 (health data) | No standalone generative-AI section exists. "AI" appears exactly once, in 5.1.2(i); "chatbots" once, in 4.7 |
| Apple — [Guidelines update, 13 Nov 2025](https://developer.apple.com/news/?id=ey6d8onl) | Provenance and wording of the 5.1.2(i) third-party-AI clause, and of new 4.1(c) | A news post summarising the change; the live guidelines are authoritative |
| Apple — [Regulated medical device apps, 26 Mar 2026](https://developer.apple.com/news/?id=nyqbfz1y) | New App Store product-page medical-device status for Health & Fitness apps; deadlines | A declaration, adjacent to this ticket. Included because it gates App Store submission, not because it is listing text |
| Apple — [App Store Connect: screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/) | Required display sizes, counts, formats, scaling behaviour | Purely mechanical. Silent on composites and frames — that rule lives in guideline 2.3.3 |
| Apple — [App Store Connect: platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/) | Field limits, and the keyword rule that names of other apps or companies aren't allowed | — |
| Developer-forum threads on 1.4.1 rejections, and vendor write-ups of the March 2026 medical-device change (**corroboration only**) | That App Review does in practice ask for the doctor reminder in the *description*, and that disclaimers alone do not settle a 1.4.1 question | Anecdote and SEO content. Used only to set confidence on one claim; never as the basis for one |

**What was read in the repo:** `fastlane/metadata/android/en-US/full_description.txt`
as it stands on `origin/develop` (the 2.2.0 rewrite from
[#1049](https://github.com/simonoppowa/OpenNutriTracker/issues/1049) — it is
not on `main`), plus `short_description.txt` and `title.txt`.

**Deliberately not re-derived:** the store *declarations* — Play's Data
safety form, Play's Health apps declaration, App Store Connect's App
Privacy record. Map [#935](https://github.com/simonoppowa/OpenNutriTracker/issues/935)
settled those. They appear below only where a listing sentence could
contradict one.

---

## 1. What must be present

### M1. Play: two sentences, in the app description, verbatim on the operative words

The Health Content and Services policy, under "Health and Medical
Functionalities":

> Other health and medical apps must include a clear disclaimer in their
> app description indicating that the app is "not a medical device and
> does not diagnose, treat, cure, or prevent any medical condition."

> Apps must also remind users to consult a healthcare professional for
> medical advice, diagnosis, or treatment.

Both are positive obligations, both name the *app description*, and the
first quotes its own required phrasing. The current last line of
`full_description.txt` satisfies both, reproducing the quoted phrase
word for word and the reminder near-verbatim:

> ⚕️ Not a medical device: OpenNutriTracker is not a medical device and
> does not diagnose, treat, cure, or prevent any medical condition.
> Figures are estimates from public databases and published equations.
> Always consult a healthcare professional for medical advice,
> diagnosis, or treatment.

**Do not paraphrase this line.** The policy quotes a fixed string;
rewriting it for tone is the one edit in the whole listing that converts
a compliant page into a non-compliant one.

**Confidence:** high. Directly quoted from the policy, and the current
copy matches.

### M2. Apple: no equivalently worded obligation — but the line should be inherited anyway

Apple has nothing that mandates a phrase in the description. The nearest
rule is guideline 1.4.1, and it is scoped to the app, not the listing:

> Apps should remind users to check with a doctor in addition to using
> the app and before making medical decisions.

Note "should", and note that it says *using the app*. So the App Store
description does not strictly inherit Play's line by rule. It should
inherit it by choice: guideline 2.3 requires metadata to reflect the
app's core experience, 1.4.1 is a review-time judgement call that a
visible reminder pre-empts, and the cost is one sentence.

**Confidence:** high that Apple imposes no *worded* description mandate.
Medium that App Review would ask for it in the description if it were
absent — that rests on forum reports, corroboration only.

### M3. Apple: the App Store submission is gated on a medical-device status declaration

Since 26 March 2026, an app whose primary or secondary category is Health
& Fitness or Medical, distributed in the EEA, UK or US, must provide a
regulated medical device status in App Store Connect with regulatory
contact and safety information. New apps are gated immediately; existing
apps have until early 2027, after which updates cannot be submitted. The
App Store then displays the status on the product page.

This is a declaration, so it belongs to #935's family rather than this
ticket — but #935 closed before the requirement existed, and it blocks
the App Store half of map #1062 outright. Flagging it, not solving it.

**Confidence:** high. Apple's own announcement, with dates.

### M4. Apple: third-party AI data sharing must be disclosed and consented

Guideline 5.1.2(i), as amended 13 November 2025:

> You must clearly disclose where personal data will be shared with third
> parties, including with third-party AI, and obtain explicit permission
> before doing so.

The obligation is in-app, and the app already meets it (`ai_consent_screen.dart`).
Its listing consequence is negative rather than positive: under 2.3 the
description must not contradict the in-app disclosure. The current AI
bullet — naming which providers, and stating that only the typed line or
the photo leaves the device, never the diary — is the strongest possible
answer to a 5.1.2(i) query, and is worth keeping in the App Store
description for that reason alone.

**Confidence:** high on the guideline text; medium that a reviewer reads
the listing rather than the app when assessing it.

### M5. Effectively mandatory: the AI precondition travels with every mention of AI

Neither store has a rule reading "state that a feature is off by default
or requires a user-supplied key". The obligation is constructed:

- Play, Misleading Claims: *"We don't allow apps that contain false or
  misleading information or claims, including in the description, title,
  icon, and screenshots"*, with *"Apps that misrepresent or do not
  accurately and clearly describe their functionality"* as the first
  listed violation.
- Apple 2.3.1: *"marketing your app in a misleading way, such as by
  promoting content or services that it does not actually offer … is
  grounds for removal"*.
- Apple 2.3.2, the closest explicit analogue, requires the description,
  screenshots and previews to *"clearly indicate whether any featured
  items, levels, subscriptions, etc. require additional purchases"*. An
  API key the user buys from a third party is not an in-app purchase, but
  it is the same shape of gate.

So: any listing surface that advertises AI must carry the precondition on
that same surface. Not once in the long description while a screenshot
caption implies it works out of the box. The current bullet does this
correctly in its first four words — "(experimental, off by default)" —
and then again with "Needs your own API key".

**Confidence:** medium-high. The rules are quoted; the synthesis is mine.

### M6. Play: sensor-based health functions must state device compatibility

> Apps that use device sensors (e.g., camera) for health functions must
> clearly state device compatibility information in the app description.

The worked example is oximetry. The meal-photo path uses the camera in a
health-adjacent flow, but the sensor measures nothing — the photo is
input to a language model, and the numbers come from the food databases.
The existing clause "The model reads language, not nutrition: every
calorie still comes from the food databases" is what keeps this rule from
attaching, so treat that clause as load-bearing rather than decorative.

**Confidence:** medium. The rule's text is broad enough to reach a camera
in a health app; its intent and every example are about measurement.

---

## 2. What is forbidden

### Google Play

- **False or misleading claims in the description, title, icon or
  screenshots.** The operative sentence, quoted in M5. Covers
  misrepresented functionality and functionality that is impossible.
- **Unattributed or anonymous user testimonials in the description.**
  Explicit in the Metadata policy, and listed first among its common
  violations. The README quotes five-star App Store reviews; those must
  not migrate into the Play listing, attributed or not.
- **Data comparison of apps or brands.** Also a listed violation. No
  "unlike MyFitnessPal", no feature-versus-competitor table.
- **Ranking, award, price and promotional signals** in text or images:
  *"'App of the year,' '#1,' 'Best of Play 20XX,' 'Popular,' award
  icons"*; *"'10% off,' '$50 cash back,' 'free for limited time only'"*;
  Play-programme words like *"Editor's choice"* or *"New"*. Note that
  "free" is on the feature-graphic prohibition list — the existing
  short description's "A free and open source calorie tracker" is prose
  about the licence, not a promotional offer, and reads as safe, but
  "Free!" as a screenshot tagline would not be.
- **Emojis, emoticons, repeated special characters and non-brand ALL
  CAPS — in the title, icon and developer name.** This ban does *not*
  extend to the long description; the emoji bullet list is fine. It does
  extend to the short description under the "highly recommended"
  guidance.
- **Misleading health claims that contradict medical consensus**, and
  *"False or misleading health claims"* generally. Practically: no
  outcome promises ("lose 10 lbs in a month"), no "clinically proven",
  no therapeutic framing.

### Apple

- **Unverifiable product claims in the subtitle.** 2.3.7: subtitles
  *"should not include inappropriate content, reference other apps, or
  make unverifiable product claims"*.
- **Names of other apps or companies in the keyword field.** ASC:
  *"Names of other apps or companies aren't allowed."* So no "ChatGPT",
  no "OpenAI", no competitor names in keywords — even though naming the
  providers in the description body is fine (4.1(c) is scoped to the
  app's *icon or name*, not its description).
- **Names, icons or imagery of other mobile platforms or alternative app
  marketplaces, anywhere in the metadata** (2.3.10). This answers one of
  map #1062's open questions ahead of time: the App Store listing may not
  mention F-Droid or point at GitHub Releases. Play has no equivalent
  clause, so the two listings diverge here.
- **Health-measurement accuracy claims without disclosed methodology**
  (1.4.1): *"Apps must clearly disclose data and methodology to support
  accuracy claims relating to health measurements, and if the level of
  accuracy or methodology cannot be validated, we will reject your app."*
  This is the rule that would bite an accuracy percentage for the AI
  parser. Do not put one in either listing.
- **Hidden, dormant or undocumented features** (2.3.1(a)), and marketing
  services the app does not offer.
- **Real people's data in screenshots** (2.3.9): *"you should display
  fictional account information instead of data from a real person"*.

**Confidence:** high throughout — every item is a direct quote.

---

## 3. What is merely risky

### R1. Calling the AI feature a chatbot or an assistant that generates things

This is the sharpest self-inflicted risk available, and it is purely a
wording choice.

Play's AI-Generated Content policy defines its scope as *"Text–to-text
conversational generative AI chatbots, in which interacting with the
chatbot is a central feature of the app"* and AI-generated images or
video. Anything inside that scope *"must contain in-app user reporting or
flagging features that allow users to report or flag offensive content to
developers without needing to exit the app."* No such affordance exists
in the AI flow on `develop` — nothing user-facing in
`lib/features/add_meal/` reports or flags model output.

Apple's 4.7 lists "chatbots" among non-embedded software, dragging in
4.7.1's filtering, reporting and blocking duties, plus 4.7.4's index and
4.7.5's age gating.

The shipped feature is neither: one line of text or one photo in,
structured items resolved against the food databases out, no conversation
and no generated media. The current bullet describes exactly that —
"Describe a meal in one line, or photograph it, and have several items
resolved at once." Copy that reframes it as "chat with AI about your
meals" or "AI generates your log" would self-declare the app into two
policies it does not currently satisfy.

**Confidence:** medium-high on the mechanism (policy scope quoted, absence
of the affordance checked in code); medium that a reviewer would actually
apply either policy on listing wording alone.

### R2. AI-made listing assets carry a store-visible label

Play's Console declaration covers *"any submitted assets … Images and
videos used in your Store listings"*, per asset, and *"Declared assets
will be AI-labeled on the Google Play Store and other surfaces where
used."* If the shot list uses generated food imagery, AI-upscaled
captures or AI-composited backgrounds, that checkbox must be ticked and
the listing wears an AI label. Straight device captures need no
declaration. Worth deciding deliberately rather than at upload time.

**Confidence:** medium-high. Page is undated and "certain circumstances"
is undefined, so the conservative read is the safe one.

### R3. "No analytics" beside an opt-in crash reporter

See §4.

### R4. The description is at 3,952 of Play's 4,000 characters

Not a policy risk, a drafting one: every compliance clause added below
must be paid for by a deletion. Any copy ticket that treats the fence as
"add a sentence" has 48 characters to work with.

**Confidence:** high — counted.

---

## 4. Claim substantiation

Neither store operates a substantiation process. There is no form, no
evidence upload, and no security-claim review. Both instead rely on a
general truthfulness standard, enforced reactively. So the exposure for
each of the description's four assertions is different from what it looks
like:

**"AES-256 encrypted databases".** No store rule addresses encryption
claims specifically. The real exposure is contradiction with Play's Data
safety declaration, which Play does enforce under the User Data policy —
and which map #935 already settled. The current copy is careful in the
right place: it scopes AES-256 to the databases and immediately concedes
*"photos you attach are ordinary image files beside them"*. That
concession, added by #1049, is what makes the sentence defensible. Keep
it adjacent to the claim; a copy edit that moves it to another bullet
re-opens the problem.
**Confidence:** high that no substantiation mechanism exists;
medium-high that declaration mismatch is the actual enforcement path.

**"No analytics, no ads".** The most mechanically checkable claim in the
listing — Play indexes bundled SDKs, and App Privacy asks the same
question. The claim is true of advertising and analytics SDKs, and the
copy already qualifies it with "Crash reporting is opt-in". The soft spot
is that a crash reporter with performance tracing enabled is arguably
analytics; the repo has an open thread on exactly that
(`fix/sentry-traces-off-by-consent`). Safer phrasing keeps the mechanism
visible — "no advertising or analytics SDKs; crash reporting is opt-in" —
rather than a bare "no analytics".
**Confidence:** medium. The rule side is clear; the factual side depends
on the Sentry configuration that ships in 2.2.0.

**"No subscriptions, purchases or ads".** Verifiable from the binary. No
policy risk. Note it must stay consistent with the AI bullet, which
tells users to bring a key they pay a third party for — the current
wording keeps these apart cleanly, and merging them would create the
misleading impression 2.3.2 is about.
**Confidence:** high.

**"Every calorie still comes from the food databases".** The most
valuable sentence in the listing and the only one that is also a
health-accuracy statement. It survives Apple 1.4.1 precisely because it
is architectural rather than statistical: it claims the model does not
emit numbers, not that the numbers are accurate to some percentage. The
moment a figure is attached — an accuracy rate, a benchmark, a "95%
correct" — 1.4.1's disclose-your-methodology-or-be-rejected clause
attaches with it. Note that this claim also encodes the settled repo
position that a model may never emit nutrition values, so it is
substantiable from the code if ever queried.
**Confidence:** medium-high.

---

## 5. The fence for the shot list

### Play — genuinely mandatory

- Minimum two screenshots across device types to publish.
- JPEG or 24-bit PNG, no alpha. Minimum dimension 320px, maximum 3840px,
  and *"the maximum dimension of your screenshot can't be more than twice
  as long as the minimum dimension"*.
- Up to eight per device type.
- Everything in the Metadata and Misleading Claims policies applies to
  screenshots as text-bearing surfaces: no ranking or price wording, no
  testimonials, no misrepresented functionality.

### Play — "highly recommended", i.e. it costs promo placement, not the listing

Play states the consequence explicitly: failing these *"will not impact
your store listing page, but may result in changes to how your preview
assets appear on Google Play or limit promotional opportunities."*

- *"Screenshots must demonstrate the actual in-app or in-game experience
  … Use captured footage of the app or game itself."*
- To be eligible for Play's large-format recommendation surfaces, four or
  more screenshots at minimum 1080px, *"9:16 for portrait screenshots
  (minimum 1080x1920px)"*. The existing store set is 1080x2205 per map
  #1062 — above the pixel floor but a 1:2.04 ratio, not 9:16 (1:1.78).
  Worth re-shooting to a true 9:16 pair of sizes if those surfaces
  matter.
- *"Add taglines only if necessary … Taglines should not take up more
  than 20% of the image."* No call-to-action ("Download now", "Try now").
- *"Stylized screenshots that break UI across multiple uploaded images
  are allowed, but prioritize UI in the first three screenshots as much
  as possible."* So composited marketing layouts are permitted, provided
  real UI dominates.
- *"Edit excess elements in the notification bar before submitting. Do
  not show service providers or notifications. The battery, WiFi, and
  cell service logos should be full."* Directly actionable for the ADB
  re-shoot on the Pixel.
- Device frames: **the outright ban is Wear OS and watch faces only.**
  The phone and tablet guidance is softer — *"Avoid inappropriate or
  repetitive image elements, such as … Device imagery (as this can become
  obsolete quickly or alienate some users)"* — and *"Do not include
  people interacting with the device"*. Misreading the Wear OS bullet as
  a phone rule is the easiest mistake to make on this page.

### Play — tablets

Minimum four screenshots, 1,080–7,680px, 16:9 landscape or 9:16 portrait,
and — the sharpest constraint on the whole shot list — *"Exclude
additional text that is not part of your core app experience, as this can
get cut off on Play homepages on certain screen sizes."* Captions are
allowed on phone shots and excluded from tablet shots. A single captioned
set cannot serve both slots.

### Apple

- 2.3.3: *"Screenshots should show the app in use, and not merely the
  title art, login page, or splash screen. They may also include text and
  image overlays (e.g. to demonstrate input mechanisms…)."* Apple
  therefore permits captions, overlays and device frames outright, where
  Play merely tolerates them. The two stores want different assets.
- 2.3.9: fictional account data only. The demo-data seeder is the right
  source for both stores' captures, not a real diary.
- Sizes, from App Store Connect: 6.9" iPhone is required if the app runs
  on iPhone — 1320x2868, 1290x2796 or 1260x2736 portrait. Because
  `TARGETED_DEVICE_FAMILY` is "1,2", 13" iPad is also required —
  2064x2752 or 2048x2732 portrait. One to ten per display size, JPEG or
  PNG, no alpha or transparency.
- App previews, if ever added, *"may only use video screen captures of
  the app itself"* (2.3.4) — a stricter rule than the screenshot one.

### May a screenshot show a feature that is off by default?

Yes, in both stores, subject to two conditions that follow from M5 and
from Apple 2.3.1: the shot must be real UI from the shipping build, and
the precondition must be legible on the same asset. Concretely: if an AI
screen appears in the set, its caption says the feature is experimental
and needs your own API key. On the tablet set, where captions are
excluded, that argues for leaving the AI screen out of the tablet slots
entirely rather than shipping an uncaptioned one.

The rule against showing content the app does not produce is firm on both
sides — Play requires the actual in-app experience, Apple requires
metadata to reflect the core experience. No mocked nutrition numbers, no
fabricated AI output, no screen that composes a feature from two
different builds.

**Confidence:** high on the quoted rules; medium-high on the off-by-
default synthesis, which no store states in those words.

---

## 6. Verdict on the current Play copy

Checked against everything above, `full_description.txt` on `origin/develop`:

1. **Compliant on the mandatory pair.** The last line reproduces Play's
   required phrase verbatim and the healthcare reminder near-verbatim.
   Nothing to fix. Protect it from paraphrase.
2. **Nothing forbidden found.** No ranking, price or programme wording;
   no testimonials; no brand comparison; title is 16 characters with no
   emoji; the emoji bullets are in the long description, where they are
   permitted.
3. **The AI bullet is already drafted inside the fence** — precondition
   first, providers named, no accuracy figure, no chatbot framing, and an
   explicit statement that the model does not produce numbers. It is the
   model for how the App Store version should read.
4. **Two soft spots, neither a violation today.** The bare "no analytics"
   in the privacy bullet (§4), and the camera-in-a-health-app question
   under M6, which the "reads language, not nutrition" clause currently
   answers by accident rather than by design.
5. **3,952 of 4,000 characters.** No budget for additions without cuts.
6. **The App Store description inherits none of this automatically.** It
   does not exist in the repo or, as far as anyone here knows, in a
   reviewed form in the console. The medical-device line, the AI
   precondition and the 5.1.2(i)-answering disclosure must all be
   authored into it deliberately — and it must additionally drop any
   mention of F-Droid or GitHub Releases that the Play copy could carry.

---

## Open questions

The honest limits of this analysis:

- **Does Play consider a meal photo a "device sensor used for a health
  function"?** The rule's text reaches it; its intent and every example
  are about measurement. No enforcement precedent found either way. The
  mitigation is one clause, so the asymmetry favours keeping it.
- **Does App Review want the doctor reminder in the App Store
  description, or only in the app?** Guideline 1.4.1 says the app. Forum
  reports say descriptions get flagged. Only corroboration supports the
  stricter reading, and the cost of complying is a sentence.
- **Are 1080x2205 screenshots accepted into Play's large-format
  surfaces?** They clear the stated pixel floor but not the stated
  aspect ratio, and Play does not say which it enforces. Answerable only
  by uploading and observing.
- **Does the March 2026 medical-device status push anything into the App
  Store description?** The announcement describes a product-page status
  and regulatory contact fields, not description text — but a "not a
  medical device" status displayed beside a description that never
  mentions it is an inconsistency worth pre-empting.
- **How stable is Play's AI-generated-asset declaration?** The Console
  page is undated, defines "certain circumstances" nowhere, and cites
  regulation rather than policy. Re-check before the assets are uploaded
  rather than trusting this snapshot.
- **Whether any of this differs in the eight non-en-US locales.** Out of
  scope for map #1062, but Play's health disclaimer is a per-locale
  description string, so localisation will inherit a compliance
  obligation, not just a translation task.
