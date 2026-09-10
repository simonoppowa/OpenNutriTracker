# Restrictions the cohort's experience places on our AI plan

Research notes gathered 2026-08-02 against primary sources — the cohort
projects' own `LICENSE` files and source, pub.dev's own licence pages, F-Droid's
own docs and the `fdroiddata` metadata repository, providers' own legal pages,
and the GPLv3 text in this repo's `LICENSE`. Written as the follow-up to
[`ai-in-open-source-nutrition-trackers.md`](ai-in-open-source-nutrition-trackers.md)
and [`ai-legal-constraints.md`](ai-legal-constraints.md), against the design
recorded in [#599](https://github.com/simonoppowa/OpenNutriTracker/issues/599)
as revised on 2026-08-02 and the tier-0 sub-issues
[#600](https://github.com/simonoppowa/OpenNutriTracker/issues/600) /
[#601](https://github.com/simonoppowa/OpenNutriTracker/issues/601) /
[#602](https://github.com/simonoppowa/OpenNutriTracker/issues/602).

The two earlier documents answer *what other projects did* and *what the law
says*. This one answers a narrower question: **what is this project not allowed
to do, or blocked from doing, that our current documents assume it can?**

Every finding is labelled:

- **Restriction** — a rule that forbids something. Compliance is not optional.
- **Risk** — something that might go wrong or might be ruled against us.
- **Cost** — permitted, but it costs time, money or capability.

Design decisions already settled in #599's comments are taken as given and are
not re-litigated. Where a document of ours is simply correct, that is recorded
too — a clean bill of health on a specific point saves the next person the
lookup. Things I could not verify are in [Not verified](#not-verified) rather
than stated.

## Bottom line up front

Three restrictions actually change what gets built.

1. **Google ML Kit is already in the APK, and it blocks F-Droid inclusion
   outright** — not as an anti-feature label but under the Free Software
   Requirement. `ai-legal-constraints.md` treats F-Droid as a labelling question
   that a build flavour could tidy up later; it is a *blocking* question that
   exists today, before any AI work.
2. **Anthropic's Usage Policy prohibits disordered-eating and body-image
   content in its Universal Usage Standards**, not only in the High-Risk
   section. #599's decision table cites that prohibition as an OpenAI-specific
   reason to prefer Anthropic. Both providers have it; Anthropic's is broader.
3. **A local endpoint needs a request timeout in the minutes, and our documents
   specify none.** Revision 2's whole reach argument rests on Ollama and
   LM Studio, and the one cohort project that shipped that path measured 54–100
   second responses and had to raise its client timeout to a 180-second default.

Everything else is either a smaller restriction, an attribution obligation, or —
in several places worth knowing — confirmation that what we wrote is right.

## Restrictions that bind

| # | Restriction | Type | Source | Affects | Consequence |
| :-- | :-- | :-- | :-- | :-- | :-- |
| C1 | Bundled Google ML Kit (via `mobile_scanner`) is proprietary; F-Droid requires every binary dependency to be freely licensed | Restriction | [F-Droid Inclusion Policy](https://f-droid.org/en/docs/Inclusion_Policy/); [ML Kit Terms](https://developers.google.com/ml-kit/terms) | RFP [#2540](https://gitlab.com/fdroid/rfp/-/issues/2540), not an AI issue | An `fdroid` flavour is needed regardless of the AI feature — swap the scanner, as Open Food Facts did |
| D2 | Anthropic AUP forbids facilitating "disordered eating" and promoting "unhealthy or unattainable body image", in Universal Usage Standards | Restriction | [Anthropic Usage Policy](https://www.anthropic.com/legal/aup) | #599 decision #7 rationale; tier-1 prompt design | Never put weight, goal or body metrics in the prompt; never ask the model to comment on an intake pattern |
| E1 | A user-supplied local endpoint needs a client timeout measured in minutes | Restriction | [fud-ai#147](https://github.com/apoorvdarshan/fud-ai/issues/147) | #599 revision 2 (endpoint field) | Configurable timeout, ~180 s default. Without it the Ollama/LM Studio story does not work at all |
| C3 | A build flavour does **not** by itself avoid `NonFreeNet` | Restriction | [fdroiddata `com.inspiredandroid.kai.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/com.inspiredandroid.kai.yml) | `ai-legal-constraints.md` F-Droid section | The flavour must remove the prefilled commercial endpoint, not just proprietary libraries |
| A3–A6 | NutriTrace (AGPL-3.0), Tandoor (AGPL + Commons Clause), MacroShot (FSL-1.1), SparkyFitness (non-commercial) cannot be copied into this repo | Restriction | Their `LICENSE` files; GPLv3 §5(c), §7, §10, §13 in this repo's `LICENSE` | #599 tier-1 checklist items lifted from those projects | Re-implement the ideas; do not lift the code |
| A2 | MIT cohort code (Fud AI, Scranbook, EatWise) may be copied in, but the copyright and permission notice must ship with it | Restriction | Their `LICENSE` files | #599 checklist "Keystore corruption on reinstall" | Carry the notice, or write it fresh (and see E5 — you probably need neither) |
| E2 | Image `media_type` must be sniffed from the bytes, not derived from the `.webp` filename | Restriction | [`user_image_storage.dart:91-108`](../lib/core/utils/user_image_storage.dart); [Anthropic vision docs](https://platform.claude.com/docs/en/build-with-claude/vision) | Tier 2; the plan's "no transcode" claim | Our own fallback path copies source bytes under a `.webp` name — HEIC would be rejected |
| C5 | Bundled Unsplash demo photos are under a licence that restricts selling; F-Droid's `NonFreeAssets` names exactly that | Restriction | [Unsplash License](https://unsplash.com/license); [F-Droid Anti-Features](https://f-droid.org/en/docs/Anti-Features/) | `assets/demo/`, not an AI issue | Expect `NonFreeAssets` on any future F-Droid listing, or replace the 12 images |
| D9 | LM Studio is proprietary software; naming it in the UI is promotion of a non-free app | Restriction | [LM Studio Terms](https://lmstudio.ai/terms); F-Droid `NonFreeAdd` | Tier-1 settings copy | If one local option is named, name Ollama (MIT) |
| D7 | OpenAI prohibits "automation of high-stakes decisions in sensitive areas without human review", medical included | Restriction | OpenAI Usage Policies (stale mirror — see [Not verified](#not-verified)) | #602 | The confirm-before-log screen is a compliance artefact; removing it is not a UX-only change |
| F2 | #600 segments on `,` and also accepts `,` as a decimal separator, with no stated precedence | Restriction (spec) | [#600](https://github.com/simonoppowa/OpenNutriTracker/issues/600) body vs its own test list | #600 | `1,5 l milk` cannot both segment and parse. Decide the order before writing the parser |

---

## A. Licence restrictions on reuse

Our repo is GPL-3.0 (`LICENSE` is the unmodified GPLv3 text). The rules that
govern reuse are in that file, and they are the primary source that actually
binds us:

- **§5(b)–(c)**: "The work must carry prominent notices stating that it is
  released under this License and any conditions added under section 7" and
  "You must license the entire work, as a whole, under this License … This
  License gives no permission to license the work in any other way."
- **§7**: "All other non-permissive additional terms are considered 'further
  restrictions' within the meaning of section 10."
- **§10**: "You may not impose any further restrictions on the exercise of the
  rights granted or affirmed under this License."
- **§13**: "you have permission to link or combine any covered work with a work
  licensed under version 3 of the GNU Affero General Public License into a
  single combined work … but the special requirements of the GNU Affero General
  Public License, section 13, concerning interaction through a network will
  apply to the combination as such."

Read against the cohort:

| Project | Actual licence (read from the repo) | May we copy code in? |
| :-- | :-- | :-- |
| [Train Libre](https://github.com/rfivesix/train-libre/blob/main/LICENSE) | GPL-3.0 (full GPLv3 text) | **Yes**, with §5(a)/(b) notices |
| [Fud AI](https://github.com/apoorvdarshan/fud-ai/blob/main/LICENSE) | MIT — "Copyright (c) 2026 Apoorv Darshan" | **Yes**, notice must ship |
| [Scranbook](https://github.com/taugr/scranbook/blob/main/LICENSE) | MIT — "Copyright (c) 2026-present Tom Auger" | **Yes**, notice must ship |
| [EatWise](https://github.com/zkwi/EatWise/blob/main/LICENSE) | MIT — "Copyright (c) 2026 zkwi" | **Yes**, notice must ship |
| [NutriTrace](https://github.com/TraceApps/nutritrace/blob/main/LICENSE) | AGPL-3.0 | **No** — see A3 |
| [Tandoor](https://github.com/TandoorRecipes/recipes/blob/develop/LICENSE.md) | AGPL-3.0 **plus Commons Clause v1.0** | **No** |
| [MacroShot](https://github.com/anirudhtopiwala/macroshot/blob/main/LICENSE.md) | FSL-1.1-Apache-2.0 | **No** (until each version's Change Date) |
| [SparkyFitness](https://github.com/CodeWithCJ/SparkyFitness/blob/main/LICENSE) | Custom non-commercial | **No** |
| [smooth-app](https://github.com/openfoodfacts/smooth-app/blob/develop/LICENSE) | Apache-2.0 | **Yes**, one-way, with NOTICE preserved |
| [Robotoff](https://github.com/openfoodfacts/robotoff) | AGPL-3.0 (`LICENCE`, British spelling) | **No** — see A3 |
| [NutriTracker (cdz-hy)](https://github.com/cdz-hy/NutriTracker/blob/main/LICENSE) | GPL-3.0 | **Yes** |
| [Waistline](https://github.com/davidhealey/waistline) | GPLv3, at `www/LICENSE.txt` — see A8 | **Yes** |
| [Food You](https://github.com/maksimowiczm/FoodYou/blob/main/LICENSE) | GPL-3.0; fdroiddata records `GPL-3.0-or-later` | **Yes** |

**A1 — "Model on" Train Libre is fine; "mirror" its prompt is copying.
Restriction (mild).** #599's second comment offers "adopting the Train Libre
posture (model names foods, database supplies numbers)" as a way to re-settle
decision #5. Adopting a design posture is not copying — ideas and architectural
approaches are not the subject of the licence. But
[`documentation/features/byok_ai_validation.md`](https://github.com/rfivesix/train-libre/blob/main/documentation/features/byok_ai_validation.md)
is a file in a GPL-3.0 repository, so its system-prompt text, its Jaro-Winkler
thresholds table (0.95 / 0.78 / 0.55) and its plausibility rules are covered
expression. Lifting them verbatim is a copy, and GPLv3 §5(a) then requires
"prominent notices stating that you modified it, and giving a relevant date".
Since we are GPL-3.0 too this is cheap — but it is not nothing, and it should be
done deliberately rather than by paste.

**A2 — MIT does not mean "no strings". Restriction.** All three MIT cohort
projects carry the standard clause: "The above copyright notice and this
permission notice shall be included in all copies or substantial portions of the
Software." #599's tier-1 checklist says the Keystore recovery path "Needs a
catch-wipe-rebuild path", and the survey points at Fud AI's `KeyStore.kt` as the
reference. If that code is transcribed, `Copyright (c) 2026 Apoorv Darshan` plus
the MIT text has to ship in the repo and in any about/licences screen. See **E5**
— the pinned `flutter_secure_storage` version already does this, so the cheapest
answer is to copy nothing.

**A3 — AGPL-3.0 code cannot be absorbed without changing what this app is.
Restriction.** GPLv3 §13 permits *combining*, but the combination then carries
AGPL §13's network-interaction requirement, and §5(c) forbids licensing the whole
work any other way. Practically: for an app that runs no server, AGPL §13 is
close to inert (as `ai-legal-constraints.md` already establishes), but the
combination is no longer a plain GPL-3.0 work, downstream redistributors inherit
the condition, and F-Droid's `License:` field would have to change. This bites on
exactly one #599 checklist item — "Put wire-shape adaptation at the boundary",
whose reference implementation is NutriTrace's
[`server/routes/ai.js`](https://github.com/TraceApps/nutritrace/blob/main/server/routes/ai.js).
Write the OpenAI-shape image normalisation from the wire format, not from their
source.

**A4 — Tandoor is not open source and cannot be copied at all. Restriction.**
`LICENSE.md` opens with the Commons Clause: "the grant of rights under the
License will not include, and the License does not grant to you, the right to
Sell the Software", where "Sell" reaches "a product or service whose value
derives, entirely or substantially, from the functionality of the Software". That
is a non-permissive additional term — a "further restriction" under GPLv3 §7,
which §10 forbids us from imposing on our recipients. The #599 checklist item
"Cap request size and retry count even though the user pays" is modelled on
Tandoor's `AiLog` credit ceiling and NutriTrace's caps; both must be
re-implemented rather than adapted.

**A5 — MacroShot is time-delayed, not open. Restriction.** FSL-1.1-Apache-2.0
grants use "provided that you do not use the Licensed Work for a Competing Use",
with a "Change Date: Two years from the date the Licensed Work is published" and
a Change License of Apache-2.0. A use restriction is a further restriction. The
first versions convert in 2028.

**A6 — SparkyFitness is non-commercial and assigns contributions. Restriction.**
"the Software may not be used, directly or indirectly, in any product, service,
or project primarily intended for or resulting in commercial advantage" and
"By submitting any code … you hereby assign **all** right, title" — both are
incompatible with GPL-3.0 and with F-Droid's Free Software Requirement.

**A7 — Apache-2.0 is safe and one-way. Clean.** smooth-app's
[`main_fdroid.dart`](https://github.com/openfoodfacts/smooth-app/blob/develop/packages/smooth_app/lib/entrypoints/android/main_fdroid.dart)
entry-point pattern — the single most directly useful piece of cohort code for
us, given **C1** — is Apache-2.0 and may be adapted into a GPL-3.0 work provided
Apache §4's notice and NOTICE-file obligations are honoured. The reverse
direction is not available; nothing we write can go back to them under GPL.

**A8 — Do not trust GitHub's licence badge. Risk (process).** `GET
/repos/davidhealey/waistline/license` returns HTTP 404 — GitHub's detector finds
nothing, because the licence lives at `www/LICENSE.txt` (35,149 bytes, the full
GPLv3 text) and the README explains "The full license file is in the www
sub-folder and the license notice is placed at the top of every source file". A
"no licence file means all rights reserved" check run against the API alone would
have got this exactly backwards. Read the tree. Of the fourteen cohort repos
checked, **every one has a licence file**; the four that GitHub reports as
`NOASSERTION` (SparkyFitness, Tandoor, MacroShot, Daily Dozen) are the four where
reading the file actually matters.

**A9 — Our own licence has no version qualifier. Restriction (procedural).**
`LICENSE` is the bare GPLv3 text; there are no per-file headers, and the README
badge says only "GPLv3". GPLv3 §14 governs what that means, and F-Droid metadata
for peers is explicit either way — Food You is `GPL-3.0-or-later`, Daily Dozen
and Translate You are `GPL-3.0-only`. If OpenNutriTracker is ever accepted into
`fdroiddata`, a value has to be chosen. Worth deciding before someone else
decides it for us, and worth deciding before absorbing GPL-3.0-only code from a
peer, which would force the combination to `-only`.

---

## B. Dependency licence restrictions

Checked against pub.dev's own licence page for each package.

| Package | In pubspec today | Licence | GPL-3.0 compatible | F-Droid |
| :-- | :-- | :-- | :-- | :-- |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage/license) | ✅ `^10.0.0` | BSD 3-Clause ("Copyright 2017 German Saprykin") | Yes | Fine |
| [`http`](https://pub.dev/packages/http) | ✅ `^1.6.0` | BSD-3-Clause (Dart team) | Yes | Fine |
| [`flutter_image_compress`](https://pub.dev/packages/flutter_image_compress) | ✅ `^2.4.0` | MIT | Yes | Fine |
| [`image_picker`](https://pub.dev/packages/image_picker) | ✅ `^1.1.2` | BSD-3-Clause (Flutter team) | Yes | Fine |
| [`sentry_flutter`](https://pub.dev/packages/sentry_flutter/license) | ✅ `^9.19.0` | MIT ("Copyright (c) 2019 Sentry") | Yes | Licence fine; **service** is the problem — see C6 |
| [`mobile_scanner`](https://pub.dev/packages/mobile_scanner) | ✅ `^7.2.0` | BSD-3-Clause **package**, proprietary **ML Kit** binary | Package yes | **Blocks inclusion** — see C1 |
| [`openai_dart`](https://pub.dev/packages/openai_dart) | ❌ (candidate) | MIT, v8.0.0, supports a custom `baseUrl` | Yes | Fine |
| [`anthropic_sdk_dart`](https://pub.dev/packages/anthropic_sdk_dart) | ❌ (candidate) | MIT, v7.0.0, publisher `davidmiguel.com` | Yes | Fine |

**B1 — No licence blocker exists in the dependency path tier 1 would need.
Clean.** Every package the design implies is BSD-3, MIT or Apache-2.0, all of
which are one-way compatible with GPL-3.0. There is no equivalent here of the
licence skew the survey found at the project level.

**B2 — And no new dependency is actually required. Clean.** `http ^1.6.0` is
already in `pubspec.yaml`. #599's revision 2 settles on "three fields — endpoint,
API key, model — speaking the OpenAI chat-completions shape", and revision 3
settles on treating every response as untrusted text to be parsed by hand. Both
of those decisions remove the reason to add `openai_dart`: a typed client whose
guarantees you then discard is a dependency for nothing, and a typed client
cannot help with an arbitrary user endpoint. This is worth stating positively
because the plan's Scope-boundary promise of "no new dependency" can hold for
tier 1 as well as tier 0.

**B3 — WebP encoding is slower on iOS. Cost.** pub.dev's platform matrix for
`flutter_image_compress`: WebP on Android "uses the system encoder, which is
fast"; on iOS it is "encoded via SDWebImageWebPCoder. Functional, but noticeably
slower than the other formats"; on macOS "not supported". HEIC is "iOS 11+ only"
and on Android "API 28+ only, and requires a working hardware encoder". This is
already the app's shipped pipeline so it is not new — but it is the mechanism
behind **E2**.

---

## C. F-Droid restrictions

Primary sources: the [Inclusion Policy](https://f-droid.org/en/docs/Inclusion_Policy/),
the [Anti-Features page](https://f-droid.org/en/docs/Anti-Features/), the
canonical definitions in
[`fdroiddata/config/antiFeatures.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/config/antiFeatures.yml),
and the per-app metadata YAML in `fdroiddata`.

The canonical anti-feature strings, verbatim from `antiFeatures.yml`:

| Key | Definition |
| :-- | :-- |
| `NonFreeNet` | "This app promotes or depends entirely on a non-free network service" |
| `NonFreeDep` | "This app depends on other non-free apps" |
| `NonFreeAdd` | "This app promotes non-free add-ons" |
| `NonFreeAssets` | "This app contains non-free assets" |
| `TetheredNet` | "This app depends entirely on a certain instance of a network service" |
| `Tracking` | "This app tracks and reports your activity" |

**C1 — ML Kit blocks inclusion today, and this has nothing to do with AI.
Restriction.** This is the biggest finding in the document and it is
present-tense.

`pubspec.yaml` pins `mobile_scanner: ^7.2.0`, used in five screens. Its own
documentation: "This package uses by default the **bundled version** of MLKit
Barcode-scanning for Android." Google's
[ML Kit Terms](https://developers.google.com/ml-kit/terms) state "you may not
reverse engineer or attempt to extract the source code or any related software"
— i.e. proprietary — and that the APIs "send metrics about the performance and
utilization of the APIs in your app to Google". `android/gradle.properties`
contains no `dev.steenbakker.mobile_scanner.useUnbundled=true`, and switching to
the unbundled variant would only trade a bundled proprietary blob for a runtime
Play Services dependency.

The Inclusion Policy's Free Software Requirement is unambiguous:

> All binary dependencies including JAR files must originate either from source
> compilation or Debian repository downloads. … Applications can download
> prebuilt FLOSS binaries with specific conditions from trusted Maven
> repositories. … **Those binaries must still be freely licensed, simply being
> included in one of those repositories is not enough.**

and

> Upstream developers must implement either a FLOSS alternative or **a build
> flavour that does not require these dependencies** when such features become
> necessary.

`ai-legal-constraints.md` concludes that F-Droid is a labelling question —
"`NonFreeNet` is a label, not a bar" — and offers the build flavour as an
optional nicety "if the project cared to". That is right about the network
service and wrong about the whole picture. The build flavour is required for
[RFP #2540](https://gitlab.com/fdroid/rfp/-/issues/2540) to succeed at all, and
the exemplar is Open Food Facts' `main_fdroid.dart` swapping ML Kit for ZXing.
The good news is that `android/app/build.gradle` already declares
`flavorDimensions "version"` with `develop` and `full`, so a third flavour is
cheap.

**C2 — "Optional and off by default" does not clear `NonFreeNet`. Restriction.**
The definition is disjunctive: "promotes **or** depends entirely on". Our design
comfortably fails the "depends entirely" limb — the app is fully usable with the
feature off — but #599 revision 2 prefills "Anthropic's URL and a sensible model
… as the default", and a prefilled commercial endpoint is promotion.

**C3 — A build flavour does not by itself avoid the flag. Restriction, and this
corrects `ai-legal-constraints.md`.** Kai 9000 is the decisive case:
[`com.inspiredandroid.kai.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/com.inspiredandroid.kai.yml)
selects `gradle: [foss]` in 49 of its 55 build entries **and still carries**
`NonFreeNet: "Rely on Gemini and Groq"`. Compare
[`org.breezyweather.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/org.breezyweather.yml),
which selects `gradle: [freenet]` in 20 of 21 entries and carries no
anti-features at all. The difference is not the existence of a flavour; it is
what the flavour removes. A `foss` flavour that strips Google libraries but
leaves the provider list intact earns the label anyway. The flavour has to remove
the prefilled commercial endpoint.

**C4 — the Translate You precedent in `ai-legal-constraints.md` is stale.
Correction.** That document states Translate You "builds `gradle: [libre]`".
[`com.bnyro.translate.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/com.bnyro.translate.yml)
uses `libre` in only 3 build entries and `yes` in the 15 most recent, and the app
carries **no `AntiFeatures:` block at all** while still supporting DeepL. So
Translate You is not currently an example of the flavour pattern; Breezy Weather
is. This weakens rather than strengthens the "you must have a flavour" reading,
and suggests F-Droid's application of the "promotes" limb is not perfectly
consistent — which is a reason to ask rather than to assume.

**C5 — Bundled Unsplash photos are non-free assets. Restriction.**
`pubspec.yaml` ships `assets/demo/alex_demo_avatar.jpg` and eleven JPEGs in
`assets/demo/meals/`. The [Unsplash License](https://unsplash.com/license)
states images "cannot be **sold** without significant modification" and does not
grant "the right to compile images from Unsplash to replicate a similar or
competing service". F-Droid's `NonFreeAssets` definition names precisely this
shape: "apps using artwork … under a license that restricts commercial usage or
making derivative works". The Inclusion Policy adds that non-functional assets
"must allow redistribution when using non-commercial licenses". The comment in
`unsplash_attribution.dart` correctly reasons about *attribution* — the general
Licence does not require it — but attribution and freeness are different
questions. Unrelated to AI; worth an issue of its own.

**C6 — Sentry is the closest precedent we have, and it went against a peer.
Risk.** The legacy Open Food Facts app's metadata carries `Tracking: "Analytics
are opt-in but the app connects to sentry.io from the start, and connects even if
rejected"` alongside `NonFreeNet` naming sentry.io among its servers. `Tracking`
is the one anti-feature the F-Droid client hides by default. Our Sentry is opt-in
and initialises only in release builds (`main.dart`), which is a materially
better posture than the one that earned the label — but the label was earned on
connection behaviour, not on the toggle, so the posture needs to be demonstrable
rather than asserted.

**C7 — F-Droid can build a Flutter app, in one specific shape. Restriction
(build).** [`com.danemadsen.maid.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/com.danemadsen.maid.yml)
is the working precedent: `submodules: true` with the Flutter SDK vendored into
the repo and invoked as `packages/flutter/bin/flutter`, `flutter config
--no-analytics` in `prebuild`, `scanignore: [packages/flutter/bin/cache]`,
`scandelete: [.pub-cache, packages/flutter]`, `flutter build apk --release
--split-per-abi`, and **one metadata entry per ABI** with a distinct
`versionCode`. The Inclusion Policy separately permits this: "The Android SDK,
Flutter SDK and Hermes have permission to use official prebuilt binaries until
Debian provides alternative solutions." Our current release flow builds an AAB
for Play; F-Droid needs per-ABI APKs from a vendored SDK.

**C8 — F-Droid does permit shipping a client for a proprietary network service.
Clean.** Inclusion Policy: anti-features "serve as warning indicators about user
freedom, privacy or etc. **without necessarily disqualifying applications from
inclusion**", and only `Tracking` is hidden by default. maid, oxproxion and Kai
9000 are all in the main repository. There is no rule against the AI feature as
such.

**C9 — Never ship a project key. Clean, satisfied by construction.** "F-Droid
does not sign up for any API keys. Even if provided by a third party, we include
them in both binary and source code releases." BYO-key satisfies this by design.

**C10 — If a local model is ever bundled or downloaded, it needs an explicit
opt-in. Restriction (future).** "Applications must not download additional
executable binary files (e.g. add-ons, auto-updates, etc.) without explicit user
consent. Consent means it needs to be opt-in … and structured in a way that
clearly explains to users that they're choosing to bypass F-Droid's checks."
Nothing in the current design does this. It would bite immediately if #250's
reopening conditions are ever met and an on-device model lands.

---

## D. Provider terms that bind the developer, not the user

Our design is BYO-key and device-to-endpoint. The question is whether any of
these terms reach *us* anyway.

**D1 — Anthropic's Usage Policy scope clause reaches passthrough clients.
Risk.** The AUP opens: "Our Usage Policy applies to anyone who can submit inputs
to Anthropic's products and/or services, **including via any authorized resellers
or passthrough access**, all of whom we refer to as 'users.'" That is a broader
scope clause than "our customers". It does not obviously make a client-app
developer a "user" — the developer never submits an input; the end user does, on
their own device, with their own key. But the drafting anticipates the
intermediary pattern, so the comfortable position that the AUP is purely the
user's contract is not free. Treat AUP compliance as a design constraint on the
prompt we ship, not as someone else's problem.

**D2 — Anthropic prohibits disordered-eating and body-image content in its
*universal* standards, and #599's provider rationale reads as though it does not.
Restriction.** Under **Universal Usage Standards → "Do Not Create
Psychologically or Emotionally Harmful Content"**:

> Facilitate, promote, or glamorize any form of suicide or self-harm, including
> disordered eating and unhealthy or compulsive exercise

> Engage in behaviors that promote unhealthy or unattainable body image or
> beauty standards, such as using the model to critique anyone's body shape or
> size

#599's decision table rejects OpenAI in part because "the usage policy prohibits
*'disordered eating promotion or facilitation'*", implying a contrast. There is
none: Anthropic has the same prohibition and adds a body-image limb that OpenAI's
universal section does not. This does not unsettle decision #7 — the other three
reasons for Anthropic (the nutrition carve-out from High-Risk, ephemeral image
handling, structured outputs) stand — but it does impose a concrete constraint on
the prompt:

- do not include the user's weight, weight goal, BMI, TDEE or calorie deficit in
  the request; the model does not need them to name a food;
- do not add any feature that asks the model to comment on, summarise or judge
  the user's intake pattern, body or progress. That is the "critique anyone's
  body shape or size" limb, and it is where a "coach" feature would land.

The app already ships a low-kcal warning and an intermittent-fasting content
gate. Those instincts are correct and should extend to the prompt.

**D3 — The High-Risk disclosure and human-review duties do *not* attach to this
feature. Clean.** The AUP's structure is three sections: Universal Usage
Standards, High-Risk Use Case Requirements, Additional Use Case Guidelines. The
per-session disclosure — "If model outputs are presented directly to individuals
or consumers, you must disclose to them that you are using AI to help produce
your advice, decisions, or recommendations. This disclosure must be provided at a
minimum at the beginning of each session" — sits in **High-Risk Use Case
Requirements**, alongside "A qualified professional in that field must review the
content or decision prior to dissemination or finalization." The High-Risk
categories are Legal, Healthcare, Insurance, Finance, Employment and housing,
Academic testing/accreditation/admissions, and Media or professional journalistic
content — and Healthcare expressly excludes us: "Wellness advice (e.g., advice on
sleep, stress, nutrition, exercise, etc.) does not fall under this category."

So Anthropic imposes **no** attribution or per-session AI-disclosure duty on
meal logging. The in-app disclosure `ai-legal-constraints.md` calls for is driven
by Apple 5.1.2(i) and Google Play, not by Anthropic. The caution is the mirror
image of D2: any drift toward advice flips the classification and switches on a
*qualified-professional review* requirement that a solo project cannot satisfy.

**D4 — The Commercial Terms bind the account holder, who is the user. Clean.**
"Subject to these Terms, Anthropic gives Customer permission to use the Services,
including to power products and services Customer makes available to its own
customers and end users"; "Customer is responsible for all activity under its
account"; "Customer and its Users may only use the Services in compliance with
these Terms". Under BYO-key the user is Customer. Two clauses were checked
specifically and do not bite:

- **Resale.** "Customer may not and must not attempt to … resell the Services
  except as expressly approved by Anthropic." The project charges nothing and
  intermediates nothing.
- **Credentials.** No clause was found forbidding a Customer from entering their
  own key into third-party software running on their own device. The
  confidentiality provisions run between the parties, not to the user's own
  tooling.
- **Age.** No minimum-age requirement appears in the Commercial Terms or the
  AUP.

**D5 — Anthropic will not name people in images, and says so in the docs.
Clean.** The vision documentation lists under Limitations: "**People
identification:** Claude [cannot be used](https://www.anthropic.com/legal/aup) to
name people in images and refuses to do so." That matches
`ai-legal-constraints.md`'s advice to never ask the model about people in the
frame, and means the tier-2 photo path cannot accidentally acquire a biometric
character through the model's own behaviour.

**D6 — And it disclaims healthcare use. Clean, reinforcing.** Same page:
"Although Claude can analyze general medical images, it is not designed to
interpret complex diagnostic scans … Claude's outputs should not be considered a
substitute for professional medical advice or diagnosis."

**D7 — OpenAI's human-review clause makes #602 load-bearing. Restriction (source
quality weak — see [Not verified](#not-verified)).** From the Usage Policies:

> automation of high-stakes decisions in sensitive areas without human review …
> medical

> provision of tailored advice that requires a license, such as legal or medical
> advice, without appropriate involvement by a licensed professional

> suicide, self-harm, or disordered eating promotion or facilitation

> promoting unhealthy dieting or exercise behavior to minors

The confirm-before-log review screen in #602 is what keeps an OpenAI endpoint on
the right side of the first clause, exactly as #599's third comment already
argues it may be under AI Act Article 50(4). That is now two independent regimes
resting on the same screen. It should be recorded in #602 that the screen is not
purely a UX affordance.

The "promoting unhealthy dieting … to minors" clause is worth a note because the
app is not age-gated. Nothing in the current design targets minors or generates
diet advice, so it does not attach — but a "coach" feature in an
all-ages-rated app would.

**D8 — Ollama is the only endpoint with no terms at all in the loop. Clean, and
useful.** The Ollama binary is [MIT](https://github.com/ollama/ollama/blob/main/LICENSE)
("Copyright (c) Ollama"). [ollama.com's Terms of Service](https://ollama.com/terms)
govern the hosted service — they require account holders to be at least 18, cover
registration and prohibited activities — and contain no clause about the local
server API or third-party clients, because the local binary needs no account.
Pointing the app at `http://localhost:11434` therefore engages no third-party
terms, no age gate, and no data-handling question. That is a genuine argument for
naming Ollama specifically in the settings copy.

**D9 — LM Studio is proprietary, and that has an F-Droid consequence.
Restriction.** [LM Studio's Terms](https://lmstudio.ai/terms) grant "a
non-exclusive, non-transferable license to use the Software solely for Your
personal and / or internal business purposes" and forbid, among other things:

> (a) modify, adapt, alter, translate, or create derivative works from the
> Software … (b) integrate the Software with other software other than through
> Element Labs published interfaces made available with the Software … (c) use
> any open source products with the Software in a manner that imposes … a
> requirement … that the Software or any part thereof: (i) be disclosed or
> distributed in source code for[m] … (e) reverse engineer, decompile,
> disassemble

Two consequences. First, a client speaking LM Studio's documented
OpenAI-compatible local server *is* going "through Element Labs published
interfaces", so the integration itself is permitted, and clause (c) is not
triggered by an HTTP request — the FSF's socket analysis in
`ai-legal-constraints.md` covers this. Second, and more practically: LM Studio is
**non-free software**, so a settings screen that names it or prefills its port is
promoting a non-free app, which is what F-Droid's `NonFreeAdd` covers ("This app
promotes non-free add-ons") and adjacent to `NonFreeDep` ("This app depends on
other non-free apps"). If the UI names exactly one local option — and it should,
because "run a local server" is meaningless to most users — name Ollama.

---

## E. Technical restrictions the cohort hit that our documents do not account for

The four already recorded in #599 (Keystore `AEADBadTagException`, key-regex
validation, truncation vs malformed output, and the Anthropic image content-part
shape) are not repeated. These are the ones that are not in our documents.

**E1 — There is no timeout in our design, and a local endpoint needs a big one.
Restriction — this is a hard blocker, not a bug.**
[fud-ai#147](https://github.com/apoorvdarshan/fud-ai/issues/147) is the only
cohort report from someone actually running the architecture #599 revision 2
describes: a self-hosted Ollama with `qwen3-vl:4b` on a GTX 1660 Super, reached
through the app's OpenAI-compatible custom-provider field.

> Photo-based food logging consistently fails with a "network error: timeout" in
> the app, even though the server-side request *does* complete successfully —
> confirmed via server logs showing `HTTP 200` after ~54-100 seconds

The maintainer's fix, in the same thread: "Ollama and Custom OpenAI-compatible
request timeouts are now configurable from **30–600 seconds**, with a
**180-second default**", plus downscaling analysis images to 1600 px before
upload.

Revision 2's central argument is that the endpoint field "removes the constraint
that most weakened this feature" by making local inference viable. That argument
does not survive a default HTTP timeout. Neither the plan nor #599 nor #601 nor
#602 mentions a timeout at all. Concretely: whichever issue scopes the tier-1
client must specify a configurable timeout with a default in the low hundreds of
seconds, and the review screen must show progress rather than appearing hung —
a 90-second wait with no feedback reads as a crash.

**E2 — Our `.webp` filenames are not a guarantee, and Anthropic validates
`media_type`. Restriction.** The plan and #599 both assert that "the existing
1024 px q80 pipeline in `user_image_storage.dart` feeds the API with no
transcode". Our own code says otherwise on the fallback path
([`user_image_storage.dart:91-108`](../lib/core/utils/user_image_storage.dart)):

> If the on-device WebP encoder is unavailable for some reason (very old
> hardware, simulator quirks), `FlutterImageCompress` returns `null` and we fall
> back to copying the source bytes verbatim — **the file extension stays
> `.webp` either way** so callers don't have to branch on it.

Anthropic's vision documentation: "Claude supports JPEG, PNG, GIF, and WebP
images (`image/jpeg`, `image/png`, `image/gif`, `image/webp`)." HEIC is not on
that list, and iOS `image_picker` can hand back HEIC. So a stored
`meal_images/<code>.webp` that is actually HEIC bytes, sent with a `media_type`
derived from its extension, is a request Anthropic rejects — and the failure
would be a rare, device-specific, unreproducible bug report. The tier-2 client
must sniff the format from the leading bytes and re-encode or refuse, not read
the extension. This is a small change made much cheaper by knowing about it
first.

**E3 — Anthropic's hard image limits, sourced. Clean, with the numbers now
written down.** From the vision docs, none of which our documents record:

- maximum dimensions **8000×8000 px**;
- maximum size per image **10 MB base64** on the Claude API (5 MB on Bedrock and
  Google Cloud);
- **32 MB request-size limit** for standard endpoints;
- **≤20 image/document blocks per request**, above which "a stricter per-image
  dimension limit applies" and oversize images are rejected with an
  `invalid_request_error` referencing "many-image requests";
- standard-tier models downscale anything with a long edge above **1568 px**
  (high-resolution tier, Claude 4.7+, is 2576 px);
- images cost `⌈width / 28⌉ × ⌈height / 28⌉` visual tokens.

Our 1024 px q80 WebP is comfortably inside every one of these, single-image
requests are far under the block limit, and the plan's arithmetic checks out:
⌈1024/28⌉² = 37² = **1369 visual tokens**, exactly as stated. The lossy-compression
warning the plan flags is verbatim from the same page. This is a clean bill of
health for the tier-2 sizing decisions.

**E4 — The cohort's only measured accuracy datum supports #601's database-first
rule. Confirming.** [fud-ai#157](https://github.com/apoorvdarshan/fud-ai/issues/157),
a feature request asking Fud AI to consult Open Food Facts before trusting the
model:

> I tested the exact same meal 10 times via text input with identical quantities
> and brand names, and the reported calories varied by about 900 ± 300 kcal.
> That's too inconsistent for reliable calorie tracking.

The reporter also asks for "A small icon showing the source (🗄️ Database / 🤖 AI)".
That is #601's database-first policy and #599 revision 1's `estimated` marker,
independently arrived at by a user of the app that did not do it. The survey
notes that no cohort project publishes measured accuracy; this is the closest
thing, and it is a run-to-run *variance* figure rather than an error figure,
which is arguably worse. It is a good argument to keep in #601.

**E5 — The Keystore recovery path is already handled by the version we pin.
Clean; a checklist item can be closed.** #599's tier-1 checklist opens with
"Keystore corruption on reinstall … Needs a catch-wipe-rebuild path". The
[`flutter_secure_storage` 10.0.0 changelog](https://pub.dev/packages/flutter_secure_storage/changelog)
states:

> ResetOnError will now automatically be true, because most errors are
> unrecoverable due to key storage problems

along with `encryptedSharedPreferences` being deprecated "due to Jetpack Crypto
package deprecation", default ciphers moving to
`RSA_ECB_OAEPwithSHA_256andMGF1Padding` and `AES_GCM_NoPadding`, and minimum
Android SDK rising from 19 to 23. `pubspec.yaml` pins `^10.0.0`, so the
catch-wipe-rebuild behaviour Fud AI had to write by hand in Kotlin is now the
library default for us. Two follow-ons: the checklist item should be rewritten as
"verify `resetOnError` is on and that losing the key on reinstall is surfaced to
the user, not silently swallowed", and there is now no reason to transcribe
`KeyStore.kt` (removing the **A2** attribution obligation entirely). minSdk 23 is
below #599's stated floor of 24, so nothing is lost there.

**E6 — One real store-review restriction in the cohort, and it is not about AI.
Cost.** [train-libre#480](https://github.com/rfivesix/train-libre/issues/480) —
"fix(ios): Restrict app deployment to iPhone only to bypass iPad screenshot
requirements". The nearest neighbour project by construction hit an App Store
submission requirement and solved it by narrowing device support. No cohort
project shows an App Store or Play rejection caused by an AI feature; the survey's
finding that "nobody was removed from F-Droid over AI" has a store-side
equivalent. Absence of evidence, but the search was reasonably thorough.

---

## F. What our documents assume away

**F1 — The plan's Scope boundary holds. Clean.** "Deterministic text parser" /
"Any model, local or remote"; "Resolution against existing search" / "Network
calls to any new destination"; "no new dependency". Verified against the repo:
`resolve_parsed_meals_usecase.dart` reuses `SearchProductsUseCase`, which reaches
only Open Food Facts and the Supabase backend — both already in the README's
destination table — and the parser needs nothing that is not already in
`pubspec.yaml`. Tier 0 changes nothing about the privacy table, and no restriction
found in this document attaches to it. #600, #601 and #602 can proceed on the
licence, F-Droid and provider-terms axes without further work.

**F2 — #600 contradicts itself on the comma, and the cohort's own worked example
is the failing case. Restriction (spec).** The issue body says "**Segment** the
input on `,`, `;`, newline, and `+`" and then "Accept `.` or `,` as the decimal
separator". Its own test checklist asks for both "Comma decimal (`1,5 l milk`)"
and "Each separator: `,` `;` newline `+`". These cannot both hold under a
naive left-to-right segmentation: `1,5 l milk` becomes `1` and `5 l milk`.

This is not a nitpick, because it is exactly the case the cohort raised.
[fud-ai#130](https://github.com/apoorvdarshan/fud-ai/issues/130) — the issue #599
cites approvingly as validating #600's locale-independence — proposed a German
quick-parser whose worked example was `1 EL Öl`, and German writes `1,5 l Milch`.
Seven of the nine shipped locales use the comma as the decimal separator
(`cs`, `de`, `it`, `pl`, `sk`, `tr`, `uk`); only `en` and `zh` do not. The
parser needs a stated
precedence rule (the obvious one: a comma flanked by digits on both sides is a
decimal point, everything else is a separator), and #600's acceptance tests need
a case that exercises both in one input, e.g. `1,5 l milk, 2 eggs`.

**F3 — The Anthropic-versus-OpenAI rationale in #599 overstates the difference.
Correction.** Covered at **D2**. The decision stands; the reasoning has one leg
fewer than it appears to.

**F4 — Revision 2's local-endpoint story carries two restrictions the comment
does not.** The timeout (**E1**) and LM Studio's non-free status versus Ollama's
MIT (**D9**). Both belong in whichever issue scopes tier 1.

**F5 — `ai-legal-constraints.md`'s F-Droid section needs two corrections and one
enlargement.** The build-flavour conclusion is too optimistic (**C3**), the
Translate You citation is stale (**C4**), and the framing of F-Droid as a
label-only question is wrong in two places that have nothing to do with AI —
ML Kit (**C1**) and the Unsplash assets (**C5**). The net effect is that
"F-Droid work" is a larger, earlier and more separable piece of work than that
document implies, and it should not be bundled into the AI feature.

**F6 — #602's review screen is now load-bearing under three regimes. Confirming,
and worth recording in the issue.** AI Act Article 50(4)'s human-editorial-review
exception (already noted in #599's third comment, flagged there as a reading
rather than a verified position); OpenAI's prohibition on "automation of
high-stakes decisions in sensitive areas without human review" (**D7**); and
Anthropic's High-Risk human-in-the-loop requirement should the feature ever drift
into advice (**D3**). #602 currently describes the screen purely as UX. A one-line
note that removing or auto-confirming it has consequences beyond usability would
be cheap insurance against a future "just log it automatically" optimisation.

**F7 — A small drift worth fixing while nearby.** The plan and #599 both quote
the README as promising *"these four destinations, nothing else"*. `README.md`
line 131 says "**Three** destinations, nothing else" and lists Open Food Facts,
the Supabase backend and Sentry. Not a restriction, but the sentence is the one
the plan says "is the product", so it is worth quoting accurately.

---

## Not verified

- **OpenAI's Services Agreement / Business Terms §2.2 and §3.3(g)** — the
  clauses #599 cites as explicitly blessing BYO-key. `openai.com` returned
  HTTP 403 to every attempt (WebFetch and `curl` with a browser user-agent, on
  `/policies/services-agreement/`, `/policies/business-terms/` and the `en-GB`
  variants). The BYO-key blessing remains unverified.
- **OpenAI's current Usage Policies.** The text quoted at **D7** comes from a
  Microsoft-hosted PDF copy
  (`learn.microsoft.com/.../usage-policies-openai.pdf`) printed 2025-11-07 and
  marked "Effective: October 29, 2025" — a mirror, and roughly nine months stale
  as of today. The quotes are verbatim from that copy; they should be re-checked
  against openai.com before being relied on.
- **gnu.org's licence list and GPL FAQ.** Repeated HTTP 429 and a connection
  reset; `curl` was served a 199-byte stub. Every GPL-compatibility conclusion in
  section A is therefore drawn from the GPLv3 text in this repo's own `LICENSE`
  (§5, §7, §10, §13, §14) rather than from the FSF's commentary. That is arguably
  the better source for our purposes, but it means the FSF's own characterisation
  of AGPLv3-versus-GPLv3 compatibility is not quoted here.
- **What Kai 9000's `foss` flavour actually removes.** `fdroiddata` selects
  `gradle: [foss]`, which is a fact from the metadata. I could not find a
  `productFlavors` block in `composeApp/build.gradle.kts` on `main`, so the
  inference at **C3** — that the flavour strips Google libraries but not the
  provider list — is reasoning from the outcome, not from the build file.
- **Whether F-Droid would in fact apply `NonFreeAssets` to the Unsplash demo
  photos.** The definition fits the Unsplash Licence's no-sale clause, but no
  ruling on Unsplash-licensed assets specifically was found in `fdroiddata` or
  the F-Droid docs.
- **Whether `ollama.com`'s Terms reach a locally-run `ollama serve`.** The Terms
  describe an account-based hosted service and are silent on the local binary,
  which is MIT and needs no account. Silence is not the same as an exclusion.
- **Whether the ML Kit dependency can be swapped without losing barcode
  formats.** `mobile_scanner` offers bundled and unbundled ML Kit; it does not
  offer a free-software backend on Android. Open Food Facts used ZXing. Whether
  ZXing covers every symbology the app relies on was not checked.
- **Our current Play content rating and App Store age rating.** Neither is in the
  repo — both live in the consoles — so the interaction between an all-ages
  rating and OpenAI's "promoting unhealthy dieting … to minors" clause could not
  be assessed.
- **Whether `flutter.minSdkVersion` currently resolves to 24.**
  `android/app/build.gradle` defers to the Flutter default rather than pinning a
  number, so #599's "runs down to minSdk 24" claim was taken at face value.
  `flutter_secure_storage` 10 requires 23, so the conclusion at **E5** holds
  either way.
- **Any App Store or Play rejection caused by an AI feature.** None found across
  the cohort's issue trackers. That is an absence of evidence from a
  keyword-driven search, not evidence of absence.

## Sources

Cohort licences, read from the repositories:
[Train Libre](https://github.com/rfivesix/train-libre/blob/main/LICENSE) ·
[Fud AI](https://github.com/apoorvdarshan/fud-ai/blob/main/LICENSE) ·
[Scranbook](https://github.com/taugr/scranbook/blob/main/LICENSE) ·
[EatWise](https://github.com/zkwi/EatWise/blob/main/LICENSE) ·
[NutriTrace](https://github.com/TraceApps/nutritrace/blob/main/LICENSE) ·
[Tandoor](https://github.com/TandoorRecipes/recipes/blob/develop/LICENSE.md) ·
[MacroShot](https://github.com/anirudhtopiwala/macroshot/blob/main/LICENSE.md) ·
[SparkyFitness](https://github.com/CodeWithCJ/SparkyFitness/blob/main/LICENSE) ·
[smooth-app](https://github.com/openfoodfacts/smooth-app/blob/develop/LICENSE) ·
[Waistline `www/LICENSE.txt`](https://github.com/davidhealey/waistline/tree/master/www) ·
[Food You](https://github.com/maksimowiczm/FoodYou/blob/main/LICENSE) ·
[NutriTracker (cdz-hy)](https://github.com/cdz-hy/NutriTracker/blob/main/LICENSE)

Our own licence text: [`LICENSE`](../LICENSE) (GPLv3 §5, §7, §10, §13, §14).

Package licences, from pub.dev's own licence pages:
[flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage/license) ·
[sentry_flutter](https://pub.dev/packages/sentry_flutter/license) ·
[flutter_image_compress](https://pub.dev/packages/flutter_image_compress) ·
[mobile_scanner](https://pub.dev/packages/mobile_scanner) ·
[openai_dart](https://pub.dev/packages/openai_dart) ·
[anthropic_sdk_dart](https://pub.dev/packages/anthropic_sdk_dart) ·
[flutter_secure_storage changelog](https://pub.dev/packages/flutter_secure_storage/changelog)

F-Droid:
[Inclusion Policy](https://f-droid.org/en/docs/Inclusion_Policy/) ·
[Anti-Features](https://f-droid.org/en/docs/Anti-Features/) ·
[`config/antiFeatures.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/config/antiFeatures.yml) ·
[`com.inspiredandroid.kai.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/com.inspiredandroid.kai.yml) ·
[`io.github.stardomains3.oxproxion.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/io.github.stardomains3.oxproxion.yml) ·
[`com.danemadsen.maid.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/com.danemadsen.maid.yml) ·
[`org.breezyweather.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/org.breezyweather.yml) ·
[`com.bnyro.translate.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/com.bnyro.translate.yml) ·
[`com.maksimowiczm.foodyou.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/com.maksimowiczm.foodyou.yml) ·
[`openfoodfacts.github.scrachx.openfood.yml`](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/openfoodfacts.github.scrachx.openfood.yml) ·
[RFP #2540](https://gitlab.com/fdroid/rfp/-/issues/2540)

Provider terms:
[Anthropic Usage Policy](https://www.anthropic.com/legal/aup) ·
[Anthropic Commercial Terms of Service](https://www.anthropic.com/legal/commercial-terms) ·
[Anthropic Service Specific Terms](https://www.anthropic.com/legal/service-specific-terms) ·
[Anthropic vision documentation](https://platform.claude.com/docs/en/build-with-claude/vision) ·
OpenAI Usage Policies (mirror, see [Not verified](#not-verified)) ·
[Ollama Terms of Service](https://ollama.com/terms) ·
[Ollama LICENSE](https://github.com/ollama/ollama/blob/main/LICENSE) ·
[LM Studio Terms](https://lmstudio.ai/terms) ·
[Google ML Kit Terms](https://developers.google.com/ml-kit/terms) ·
[Unsplash License](https://unsplash.com/license)

Cohort issue threads:
[fud-ai#147](https://github.com/apoorvdarshan/fud-ai/issues/147) ·
[fud-ai#157](https://github.com/apoorvdarshan/fud-ai/issues/157) ·
[fud-ai#130](https://github.com/apoorvdarshan/fud-ai/issues/130) ·
[train-libre#480](https://github.com/rfivesix/train-libre/issues/480)

In-repo files cited:
[`LICENSE`](../LICENSE) ·
[`pubspec.yaml`](../pubspec.yaml) ·
[`android/app/build.gradle`](../android/app/build.gradle) ·
[`android/gradle.properties`](../android/gradle.properties) ·
[`lib/core/utils/user_image_storage.dart`](../lib/core/utils/user_image_storage.dart) ·
[`lib/core/utils/demo/unsplash_attribution.dart`](../lib/core/utils/demo/unsplash_attribution.dart) ·
[`README.md`](../README.md)
