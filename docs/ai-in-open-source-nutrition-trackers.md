# AI features in other open-source nutrition trackers

Research notes gathered 2026-08-02 against primary sources — repositories,
source files, dependency manifests, project docs, and issue threads. Written to
inform issue [#599](https://github.com/simonoppowa/OpenNutriTracker/issues/599),
which scoped AI-assisted meal logging for this app as a deterministic local
parser for everyone plus an opt-in bring-your-own-key tier using Anthropic.

Every factual claim below links to the file or issue it came from. Star counts
and "last pushed" dates are as of 2026-08-02. Things I could not confirm are
listed at the end rather than guessed at.

> **Read alongside [`ai-cohort-restrictions.md`](ai-cohort-restrictions.md).**
> This document answers *what other projects did*. That one answers *what we
> are allowed to copy* — several of the projects surveyed here are under
> licences (AGPL-3.0, FSL-1.1, Commons Clause, non-commercial) that this
> repo's GPL-3.0 cannot take code from. Treat everything below as
> read-for-ideas unless that document says otherwise.

## Summary

The landscape splits cleanly along a line that is not the one you would expect.
The strictly-free, F-Droid-distributed calorie trackers with real user
bases — [Waistline](https://github.com/davidhealey/waistline),
[Food You](https://github.com/maksimowiczm/FoodYou),
[FitBook](https://github.com/brandonp2412/FitBook) — have **no AI code at all**,
not behind a flag and not in a branch; their dependency manifests contain no
model runtime and no provider SDK. Everything that does ship AI is either
self-hosted server software under a source-available or non-commercial licence
([Tandoor](https://github.com/TandoorRecipes/recipes),
[SparkyFitness](https://github.com/CodeWithCJ/SparkyFitness),
[MacroShot](https://github.com/anirudhtopiwala/macroshot)), or a small
mobile app that ships **bring-your-own-key and nothing else** — no bundled
credential, no project-operated proxy
([Fud AI](https://github.com/apoorvdarshan/fud-ai),
[Train Libre](https://github.com/rfivesix/train-libre),
[EatWise](https://github.com/zkwi/EatWise),
[Scranbook](https://github.com/taugr/scranbook)). BYO-key is therefore the
conventional choice, not a novel one; the two design decisions where
OpenNutriTracker's plan is genuinely unusual are hardcoding a *single* provider
(everyone else is multi-provider or OpenAI-compatible from day one) and letting
the model emit macros at all (the closest comparator forbids it outright).
Open Food Facts is the outlier in the other direction: it runs its ML
server-side on self-hosted fine-tuned open weights and deliberately disables the
one on-device ML dependency it has in its F-Droid build.

## Comparison table

| Project | Licence | AI feature | Where inference runs | Provider(s) | BYO key? | Shipped? |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| [Fud AI](https://github.com/apoorvdarshan/fud-ai) | MIT | Photo→meal (up to 10 images), text, voice, coach chat, nutrient-goal estimation | Device → provider, direct. Apple Intelligence on-device as last fallback | 13, incl. Anthropic, OpenAI, Gemini, Ollama, custom OpenAI-compatible | Yes, only | Yes — App Store + Play |
| [Train Libre](https://github.com/rfivesix/train-libre) | GPL-3.0 | Photo + text meal capture; LLM forbidden from emitting numbers | Device → provider, direct; no intermediate server | OpenAI, Gemini, Anthropic, Mistral, xAI | Yes, only | Yes (beta) — App Store, Obtainium, own F-Droid repo |
| [NutriTrace](https://github.com/TraceApps/nutritrace) | AGPL-3.0 | Conversational assistant with 16 tools, Smart Log text/voice, photo `propose_food`, Scan Label OCR | Self-hosted server (proxy mode) or browser → provider | Claude, OpenAI, Gemini, any OpenAI-compatible incl. Ollama | Yes (per-instance or admin env) | Yes |
| [SparkyFitness](https://github.com/CodeWithCJ/SparkyFitness) | Non-commercial (custom) | "SparkyAI" chat logging, food-image logging | Self-hosted server | Anthropic, OpenAI, Gemini, Ollama, OpenAI-compatible | Yes (admin-configured) | Yes (beta) |
| [Tandoor Recipes](https://github.com/TandoorRecipes/recipes) | AGPL + Commons Clause | Recipe import from image/PDF/text, step sorting, food + recipe property (nutrition) extraction | Self-hosted server, via LiteLLM | Anything LiteLLM routes | Yes, per space | Yes, since Tandoor 2 |
| [Open Food Facts](https://github.com/openfoodfacts/robotoff) (Robotoff) | AGPL-3.0 | Category/brand/label prediction, nutrition-table extraction, ingredient spellcheck, logo ANN | Project's own servers (Triton) | Self-hosted fine-tuned Mistral-7B + custom models | No | Yes |
| [Open Food Facts](https://github.com/openfoodfacts/smooth-app) (Smoothie app) | Apache-2.0 | On-device OCR/classification via ML Kit; on-device LLM exploratory only | On-device (non-F-Droid builds only) | Google ML Kit | No | Partly — **disabled in the F-Droid build** |
| [MacroShot](https://github.com/anirudhtopiwala/macroshot) | FSL-1.1-Apache-2.0 (source-available) | Photo/text/barcode logging, MCP coach with 23 tools | Self-hosted server or author's hosted instance | Gemini (single, required env var) | No — operator supplies | Yes (open beta) |
| [Scranbook](https://github.com/taugr/scranbook) | MIT | Photo→dish + label transcription; **macros computed locally** from bundled composition data | Browser → user's OpenAI-compatible endpoint | LM Studio default, any OpenAI-compatible | Yes, only | Yes (small) |
| [EatWise](https://github.com/zkwi/EatWise) | MIT | Photo meal analysis, ranges only | Device → user's endpoint | OpenRouter default, any OpenAI-compatible | Yes, only | Yes (GitHub releases) |
| [NutriTracker (cdz-hy)](https://github.com/cdz-hy/NutriTracker) | GPL-3.0 | Photo food recognition, weight + nutrient estimation | Device → user's endpoint | Any OpenAI-compatible multimodal | Yes, only | Yes (GitHub releases) |

Projects with a comparable user base and **no AI**: Waistline (728★),
Food You (515★), FitBook (157★), kcal (350★),
[PANTS](https://github.com/dylanleigh/PriceAndNutritionTrackingSystem) (131★),
[Daily Dozen](https://github.com/nutritionfactsorg/daily-dozen-android) (294★).

## Fud AI — the closest shipped comparator

[`apoorvdarshan/fud-ai`](https://github.com/apoorvdarshan/fud-ai), MIT, Kotlin
(Compose) + Swift (SwiftUI), 299★, last pushed 2026-07-25. Ships on the
[App Store](https://apps.apple.com/us/app/fud-ai-calorie-tracker/id6758935726)
and [Google Play](https://play.google.com/store/apps/details?id=com.apoorvdarshan.calorietracker).
The README contains no F-Droid reference.

This is the app OpenNutriTracker's tier 1 + tier 2 would resemble if both
shipped, and it is worth reading in full because it has already absorbed a
year of BYO-key support load.

**Provider surface.** Thirteen providers, enumerated in
[`android/app/src/main/java/com/apoorvdarshan/calorietracker/models/AIProvider.kt`](https://github.com/apoorvdarshan/fud-ai/blob/main/android/app/src/main/java/com/apoorvdarshan/calorietracker/models/AIProvider.kt)
as a Kotlin enum carrying a `baseUrl` and a curated `models` list per provider,
mirrored by `ios/calorietracker/Models/AIProvider.swift`. Nine of the thirteen
are just "OpenAI-compatible with a different base URL"; only Gemini and
Anthropic need bespoke wire formats. Ollama and a free-form "Custom
(OpenAI-compatible)" entry give local inference for free. There is a fallback
provider setting: if the primary returns 429/503, the app silently retries
against a second configured provider.

**Key storage.**
[`data/KeyStore.kt`](https://github.com/apoorvdarshan/fud-ai/blob/main/android/app/src/main/java/com/apoorvdarshan/calorietracker/data/KeyStore.kt)
uses `EncryptedSharedPreferences` (AES-256, AndroidKeystore-backed), one entry
per provider under an `apikey_` prefix; iOS uses `KeychainHelper`. This is the
same substrate `flutter_secure_storage` sits on. That file also carries a
comment worth reading before we write ours:

> On Android 14/15 (and occasionally older), the AndroidKeystore master-key
> alias survives `pm uninstall` but the encrypted prefs file does not — so a
> reinstall […] hits an `AEADBadTagException` on the first read […] Without
> this, the app crashes on `Application.onCreate` before showing any UI.

Their recovery path catches the failure, deletes both the prefs file and the
Keystore alias, and rebuilds.

**No bundled key, and a hosted proxy they killed.** The README states plainly
that requests "go directly from your device to the provider you configure", and
that "The optional Fud AI Premium proxy from earlier iOS versions has been
discontinued." A project of this size tried operating a paid proxy and stopped.
[`SECURITY.md`](https://github.com/apoorvdarshan/fud-ai/blob/main/SECURITY.md)
puts "Denial-of-service against the user's own AI provider via API quota
exhaustion" explicitly out of scope as "a user-controlled cost, not a security
boundary".

**What BYO-key actually costs in support.** The issue tracker is the most
valuable artefact here:

- [#139](https://github.com/apoorvdarshan/fud-ai/issues/139) — Claude Sonnet
  returns responses the app cannot parse ("Could not understand the AI
  response"), while the Anthropic dashboard confirms the requests landed. The
  community workaround was to tell users to add `Response Format: **1024
  tokens**` to their custom instructions.
- [#145](https://github.com/apoorvdarshan/fud-ai/issues/145) — the user raises
  "Max response tokens" to 2048 to work around #139 and the app becomes
  unstable and crashes. Fixed by handling "truncated and reasoning-only
  responses safely".
- [#105](https://github.com/apoorvdarshan/fud-ai/issues/105) — `unexpected char
  0x0a at 15 in Authorization value`: the pasted key carried a trailing
  newline.
- [#140](https://github.com/apoorvdarshan/fud-ai/issues/140) — Google's new
  `AQ.`-prefixed Gemini keys were rejected by the app's own key validation even
  though they worked against Google's curl example.
- [#106](https://github.com/apoorvdarshan/fud-ai/issues/106) — "What does it
  mean api limit it reached?" drew a several-hundred-word maintainer reply
  walking the user through three different free tiers.
- [#63](https://github.com/apoorvdarshan/fud-ai/issues/63),
  [#170](https://github.com/apoorvdarshan/fud-ai/issues/170) — keys that "don't
  work", and a key entered during onboarding not showing up in settings.

**Two declines worth noting.**
[#36](https://github.com/apoorvdarshan/fud-ai/issues/36) asked for on-device
Gemma via Google AI Edge Gallery; the maintainer kept it open as research but
said current phone models are "weaker and slower" for "accurate structured
nutrition JSON, image/label understanding, and serving estimates".
[#130](https://github.com/apoorvdarshan/fud-ai/issues/130) proposed exactly the
kind of deterministic local work OpenNutriTracker's tier 0 describes — a local
correction-memory table and a German quick-parser for `1 EL Öl` — and was
**closed as not planned**, on the grounds that a language-specific parser "would
add language-specific behavior that would need to be maintained across all
supported languages".

## Train Libre — the same stack, the opposite call on estimates

[`rfivesix/train-libre`](https://github.com/rfivesix/train-libre), GPL-3.0,
Flutter/Dart, 5★, in beta since 2026-07-22 (currently `v1.0.0-beta.7`).
Distributed via the Apple App Store, Obtainium, and **its own F-Droid
repository**, not the main F-Droid catalogue.

Technically this is the nearest neighbour we have: same language, same licence,
same offline-first pitch, same `flutter_secure_storage`. Its design document
[`documentation/features/byok_ai_validation.md`](https://github.com/rfivesix/train-libre/blob/main/documentation/features/byok_ai_validation.md)
is the single most useful file found in this survey.

**Key storage** is per-provider under `ai_api_key_openai`, `ai_api_key_gemini`,
`ai_api_key_anthropic`, `ai_api_key_mistral`, `ai_api_key_xai`, via
`FlutterSecureStorage`. "Train Libre does not deploy intermediate servers to
handle AI requests."

**The model is banned from producing numbers.** From the system-prompt rules:

> **Macro/Calorie Ban**: The AI is strictly prohibited from estimating,
> guessing, or returning any nutritional numbers (calories, protein, carbs,
> fat). Nutritional calculations are resolved deterministically by Train Libre
> using its local database.

Instead the model is required to decompose a meal into atomic, generically-named
ingredients ("Spaghetti Bolognese" → spaghetti, beef mince, tomatoes, onions,
garlic, olive oil, parmesan), consolidate duplicates, and return grams plus a
`mealContext` block containing an `expectedKcalRange`, a `cookingState`, and an
`expectedMacroProfile`. Those anchors exist purely so a local engine can
cross-check the database matches it produced.

**The local validation engine** then fuzzy-matches each ingredient against the
app's SQLite food database (Jaro-Winkler, thresholds at 0.95 / 0.78 / 0.55),
applies plausibility rules (`grams > 3000` is a hard error, `< 5g` a warning),
and runs four cross-checks against the anchors: total kcal deviation >25% warns
and >50% errors; macro-profile deviation >15% warns; raw-vs-cooked state
mismatch errors if caloric density differs by >30%; portion density outside
0.5–2× the database default warns.

**When validation fails, the model is demoted to a selector.** The engine pulls
the top 5–10 fuzzy candidates from the local database, re-ranks them by cooking
state, injects them into the repair prompt as a `CANDIDATES` block, and asks the
LLM to pick — "The LLM acts as a semantic selector rather than an estimator."
The loop runs at most three passes; a candidate passes only at score ≥70 with
zero critical errors.

This is the same problem OpenNutriTracker faces, solved by never letting the
provenance chain break in the first place.

## NutriTrace — self-hosted, and the only one with a documented proxy mode

[`TraceApps/nutritrace`](https://github.com/TraceApps/nutritrace), AGPL-3.0,
Svelte + Node, 162★, actively developed. Single Docker container, PWA plus a
Capacitor Android build.

"Trace AI" is a tool-using assistant (16 tools) that can read the diary,
wellness data and fasting state, and propose foods and diary entries for
confirmation. Providers are `claude | openai | gemini | oai-compat`, set via
[`.env.example`](https://github.com/TraceApps/nutritrace/blob/main/.env.example)
or the Settings UI.

Two implementation details are relevant to us:

- **Env vars lock the UI.** [`server/ai.js`](https://github.com/TraceApps/nutritrace/blob/main/server/ai.js)
  seeds `ai_provider`, `ai_api_key`, `ai_model`, `ai_base_url` into an
  `app_config` table and sets `ai_env_locked`; when locked, calls are proxied
  server-side so "The API key never leaves the server". The key is stored as a
  plain row in SQLite.
- **The proxy is hardened against its own users.**
  [`server/routes/ai.js`](https://github.com/TraceApps/nutritrace/blob/main/server/routes/ai.js)
  caps requests at `AI_MAX_MESSAGES = 60` and `AI_MAX_BYTES = 8_000_000`, and
  rate-limits to 30/minute, with the stated reason of bounding "a misbehaving
  client (or compromised account) from burning through the admin's AI API
  budget with one giant request".

It also documents a wire-format bug worth knowing: the proxy normalises every
image part to the OpenAI `{type:'image_url', image_url:{url:'data:...'}}` shape
because an OpenAI-compatible gateway "would reject Anthropic-shaped image parts
with `invalid content type=image`" (fixes their #114). Anthropic's native
`{type:'image', source:{type:'base64', ...}}` shape is not portable.

On privacy, the docs state that for voice logging "only the transcript reaches
your configured LLM; the audio stays on-device", and the README carries a long
medical disclaimer naming eating disorders, diabetes and pregnancy explicitly,
ending "Trace AI answers can be incorrect or incomplete".

## Tandoor Recipes — the largest shipped AI feature, and the Anthropic bug

[`TandoorRecipes/recipes`](https://github.com/TandoorRecipes/recipes), 8501★,
AGPL plus a Commons Clause rider (so not OSI-free). Recipe parsing is the close
cousin of our text parsing, and Tandoor 2 shipped it.

[`docs/features/ai.md`](https://github.com/TandoorRecipes/recipes/blob/develop/docs/features/ai.md)
documents the design: everything routes through **LiteLLM**, so any provider it
supports works; AI providers are configured per space (or globally by a
superuser) with name, model, API key and optional base URL; and there is a
**default spending limit of roughly 1 USD per month per space**, enforced by
[`cookbook/helper/ai_helper.py`](https://github.com/TandoorRecipes/recipes/blob/develop/cookbook/helper/ai_helper.py)
via an `AiLog` table that records input/output tokens and credit cost on both
success and failure. `AI_RATELIMIT` defaults to `60/hour`.

The API key is stored unencrypted: `api_key = models.CharField(max_length=2048)`
on the `AiProvider` model in `cookbook/models.py`.

Their documented troubleshooting list reads like a checklist of BYO-key failure
modes: JSON mode is required and models that ignore `response_format` will
error; vision support is required for image/PDF import; AI calls are synchronous
so slow models hit reverse-proxy timeouts; cost tracking silently degrades if
the provider does not return usage data. There is also an explicit warning that
"AI import sends the entire file as base64 inside the request. Large files can
exceed provider limits or reverse proxy limits."

**The Anthropic-specific bug** is
[#4659](https://github.com/TandoorRecipes/recipes/issues/4659), still open. The
`aiproperties` endpoint 500s with `JSONDecodeError: Expecting value: line 1
column 1 (char 0)` for any Claude model, because:

> Although `response_format={"type": "json_object"}` is passed to LiteLLM, the
> Anthropic backend in LiteLLM does *not* enforce JSON mode the way OpenAI does
> — Claude is free to return JSON wrapped in a Markdown code fence.

The reporter's own recommendation is to stop relying on the OpenAI-shaped
`response_format` and "switch to Anthropic's structured outputs / tool-use
schema enforcement". This is worth reading as a validation of #599's choice of
constrained decoding rather than as a warning against Anthropic — but it also
shows how easy it is to end up on the fence-stripping path by accident when you
go through an abstraction layer.

## Open Food Facts — server-side by design, and F-Droid-aware

We already consume their API, so their posture matters.

**Robotoff** ([`openfoodfacts/robotoff`](https://github.com/openfoodfacts/robotoff),
AGPL-3.0, 113★) is a batch and real-time prediction service that turns product
data into "insights" — category, brand and label prediction, nutrition-table
extraction, logo ANN, image quality. Inference runs on their infrastructure
behind a Triton inference server; high-confidence insights are auto-applied,
lower-confidence ones go to human validation.

Their [ingredients spellcheck](https://openfoodfacts.github.io/robotoff/references/ingredients-spellcheck/)
is the clearest statement of philosophy: the production model is a **self-hosted
fine-tune of Mistral-7B-Base**, benchmarked against GPT-4o, Gemini-1.5-flash and
Claude 3 Sonnet and beating them on correction precision. A closed model
(GPT-3.5-Turbo) was used only to *generate synthetic training data*, which was
then reviewed in Argilla. Third-party APIs are a tool for building the model,
not a runtime dependency.

**On-device is treated as speculative and F-Droid-hostile.** The app-side
tracker [smooth-app#4027](https://github.com/openfoodfacts/smooth-app/issues/4027)
contains the line that matters most for us:

> Add optional offline ingredient extraction using MLKIT (**disabled on the
> F-Droid build**)

and the same for packaging extraction. The mechanism is visible in the source:
[`packages/smooth_app/lib/entrypoints/android/main_fdroid.dart`](https://github.com/openfoodfacts/smooth-app/blob/develop/packages/smooth_app/lib/entrypoints/android/main_fdroid.dart)
is a separate entry point that swaps Google ML Kit for ZXing, tagged
`ScannerLabel.ZXing` and `StoreLabel.FDroid`.
[smooth-app#5009](https://github.com/openfoodfacts/smooth-app/issues/5009),
"Explore using the on-device LLM for various tasks", has been open since January
2024 and opens with "this is highly speculative"; food-intake journaling is
listed under *speculative* use cases, and the caveats are battery drain and
device availability.

Their one concrete multimodal-LLM proposal,
[openfoodfacts-ai#341](https://github.com/openfoodfacts/openfoodfacts-ai/issues/341),
extracts a product name and brand from a photo — and gates it on
"the user requests it (with a button?)".

## Smaller projects, and one structural variant

**Scranbook** ([`taugr/scranbook`](https://github.com/taugr/scranbook), MIT) is
a local-first PWA whose README describes a split we should consider: the vision
model identifies the dish and ingredients, but "Editable calorie and macro
estimates calculated locally from bundled official food-composition data" —
the model never produces the numbers. It also states "No external nutrition API
and no medical, allergy, or food-safety claims", defaults to LM Studio with
`google/gemma-4-e4b`, and requires "Response mode: Strict JSON schema".

**EatWise** ([`zkwi/EatWise`](https://github.com/zkwi/EatWise), MIT, Kotlin)
takes the presentation route instead: it ships model estimates, but the README
says calories, macros and fibre are shown **only as wide ranges**, vegetable
quantity is qualitative, and the result explicitly "does not count as a weighed
record". Base URL defaults to OpenRouter; key, base URL, model and dietary goal
are all user-supplied.

**NutriTracker** ([`cdz-hy/NutriTracker`](https://github.com/cdz-hy/NutriTracker),
GPL-3.0, Kotlin) is directly downstream of us — its README credits
OpenNutriTracker as the origin of "灵感和部分程序思路" (inspiration and part of the
program design), and it reproduces our IOM 2005 TDEE, WHO BMI and MET
calculations. It adds photo recognition and states "应用不内置 AI 服务" — the app
bundles no AI service; the user configures API key, base URL and model, and the
settings screen offers a connection test that verifies multimodal capability.

**A structural variant: expose the tracker, don't embed the model.** A visible
cluster of projects skips in-app AI entirely and ships an MCP server so the
user's own agent does the logging —
[`akutishevsky/nutrition-mcp`](https://github.com/akutishevsky/nutrition-mcp)
(30★), [`rockitdev/macro-engine`](https://github.com/rockitdev/macro-engine),
[`neonwatty/food-tracker-mcp`](https://github.com/neonwatty/food-tracker-mcp),
[`RenierM26/calorie-tracker`](https://github.com/RenierM26/calorie-tracker).
Fud AI was asked for exactly this in
[#110](https://github.com/apoorvdarshan/fud-ai/issues/110) and declined it —
"there's no backend, no account, and no cloud sync, so there's no server for an
external tool like Claude to connect to" — offering JSON/CSV/Markdown export
instead. That answer applies verbatim to us.

## Projects that considered AI and declined

**Grocy** ([`grocy/grocy`](https://github.com/grocy/grocy), 9337★) has declined
every AI request it has received. On
[#917 "AI vision"](https://github.com/grocy/grocy/issues/917), asking for ML Kit
object detection, the maintainer closed with: "This is more something for native
companion apps or other external add-ons."
[#2486](https://github.com/grocy/grocy/issues/2486) (fridge camera with object
recognition) and [#2927](https://github.com/grocy/grocy/issues/2927) (AI
recipes) were both closed as duplicates without engagement. The consistent
position is that AI belongs outside the core.

**Food You** ([`maksimowiczm/FoodYou`](https://github.com/maksimowiczm/FoodYou),
515★, GPL-3.0, on F-Droid with no anti-features) has an open request that is
almost exactly #599's tier 1:
[#419 "Natural Language AI Food Logging"](https://github.com/maksimowiczm/FoodYou/issues/419),
opened 2026-05-25. The reporter even anticipates the architecture — "to maintain
the app's open-source nature and avoid server costs for the developer, this
could be implemented by allowing users to simply input their own API key (e.g.
OpenAI, Gemini, Anthropic, or even a local AI endpoint)". Nine months on there
is **no maintainer response**, and one community comment suggesting LiteRT /
Google AI Edge for on-device Gemma. `gradle/libs.versions.toml` contains no AI,
ML Kit, TFLite or LiteRT dependency. This is a decline by silence rather than by
argument, but the outcome is the same.

**Waistline** ([`davidhealey/waistline`](https://github.com/davidhealey/waistline),
728★, GPL-3.0-only, on F-Droid with no anti-features) has no AI code and no AI
discussion beyond [#923 "Pantry Wizard"](https://github.com/davidhealey/waistline/issues/923),
an unanswered request for LLM-generated recipes. Its `package.json` lists only
Cordova plugins — camera, barcode, TTS — no model runtime.

**FitBook** ([`brandonp2412/FitBook`](https://github.com/brandonp2412/FitBook),
157★, MIT, Flutter, on F-Droid) is the other Dart tracker; its `pubspec.yaml`
contains `openfoodfacts`, `barcode_scan2` and nothing model-related. Its
description is "Track your calories - Completely offline!".

**kcal** ([`kcal-app/kcal`](https://github.com/kcal-app/kcal), 350★, MPL-2.0)
declines even *food database APIs*, on the grounds that large community datasets
are "daunting" to search and "can be inaccurate and counter-productive for users
with calorie and/or macro goals".

**OpenNutriTracker itself.** Issue
[#250](https://github.com/simonoppowa/OpenNutriTracker/issues/250), "Ask AI to
fill out custom dish information", was closed on 2026-05-15 as
"researched, not shipping for now" after a documented spike: twelve small
models, eight reference foods plus three multi-food prompts, run on a Pixel 8.
The write-up rejects the on-device path on accuracy (the best phone-viable
model, Qwen 2.5 1.5B, landed 25–45% high on an unseen freeform prompt) — and
then **rejects the BYO-key path separately**, on four grounds: maintenance
surface (key entry, secure storage, billing communication, model-deprecation
drift), single-digit adoption, the privacy regression of dish descriptions
leaving the device, and store-review provenance expectations for health apps.
Its central claim is that "wrapping it in confidence flags doesn't add
provenance, it adds a warning". Issue #599 reaches the opposite conclusion on
the BYO-key question and does not reference #250.

## Licensing and F-Droid consequences

**Adding AI has skewed projects away from free licences.** Of the shipped
server-side AI trackers, SparkyFitness is non-commercial-only, Tandoor carries a
Commons Clause, and MacroShot uses FSL-1.1-Apache-2.0. None of the three would
be accepted by F-Droid or be GPL-compatible. The AI-shipping projects that *are*
OSI-free are all small mobile BYO-key apps (Fud AI MIT, Train Libre GPL-3.0,
NutriTrace AGPL-3.0, EatWise/Scranbook MIT, cdz-hy GPL-3.0).

**F-Droid's anti-features.** The catalogue currently defines ten
([docs](https://f-droid.org/docs/Anti-Features/)); the relevant ones are
*Non-Free Network Services* ("promotes or depends entirely on a proprietary
network service"), *Non-Free Dependencies* ("requires things that are not Free
Software in order to run"), and *Tethered Network Services*. NonFreeNet was
narrowed in July 2024 when Tethered was split out of it
([TWIF, 2024-07-25](https://f-droid.org/2024/07/25/twif.html)); 819 apps
currently carry NonFreeNet.

**Precedent for a BYO-key LLM app.** Two are directly on point:

- [Kai 9000](https://f-droid.org/packages/com.inspiredandroid.kai/) (Apache-2.0),
  a multi-provider LLM chat app, carries **Non-Free Network Services** —
  "This app promotes or depends entirely on a non-free network service.
  Specifically, the app relies on Gemini and Groq services."
- [oxproxion](https://f-droid.org/packages/io.github.stardomains3.oxproxion/)
  (Apache-2.0) supports Ollama, LM Studio, llama.cpp and MLX LM alongside
  OpenRouter, and still carries **Non-Free Network Services** — "Depends on
  OpenRouter API servers."

So the presence of a local-inference option did not spare oxproxion. Both apps
are *primarily* LLM clients, which is not our case; I could not find an app
where AI is an optional secondary feature and F-Droid ruled on it either way.

**What the food apps carry today.** Food You and Waistline have no anti-features
listed. The legacy Open Food Facts Android app carries **Non-Free Network
Services** ("depends on openfoodfacts.net/.org, openproductfacts.org,
openstreetmap.org and sentry.io servers") and **Tracking** ("Analytics are
opt-in but the app connects to sentry.io from the start, and connects even if
rejected"). That second one is worth staring at: OpenNutriTracker also ships
opt-in Sentry.

**Nobody was removed from F-Droid over AI.** I found no case of an app being
delisted for adding an AI feature. The observed responses are (a) build a
separate F-Droid flavour with the proprietary bit removed — Open Food Facts
swapping ML Kit for ZXing in `main_fdroid.dart`; or (b) skip the main catalogue
and self-host a repo — Train Libre publishes its own
[F-Droid repo](https://rfivesix.github.io/train-libre/fdroid/repo).

**Our own status.** OpenNutriTracker is not in the main F-Droid catalogue;
[RFP #2540](https://gitlab.com/fdroid/rfp/-/issues/2540) is outstanding and the
README says "from F-Droid once the app is published there". Any AI work lands
before that listing is decided, not after.

## Privacy posture — what these projects tell users

- **Fud AI**: "Requests go directly from your device to the provider you
  configure." Marketing site carries a privacy page; the security policy scopes
  API-key handling and names the exact storage mechanism per platform.
- **Train Libre**: "User-Controlled AI: Optional AI features require your own
  API key; no data is sent to providers without opt-in", plus "Train Libre does
  not deploy intermediate servers to handle AI requests." It ships a clinical
  disclaimer naming diabetes.
- **NutriTrace**: per-feature statements ("only the transcript reaches your
  configured LLM; the audio stays on-device"; label photos go to the provider as
  base64 under a 12 MB body limit) and a long medical disclaimer.
- **Scranbook**: "There are no Scranbook accounts, analytics, Worker code, or
  server-side diary APIs", and the photo goes to the user's endpoint only "when
  the user explicitly chooses to analyse a photo".
- **EatWise**: privacy-first framing, and screenshots deliberately generated
  from synthetic records so no real photo, key or dietary goal appears.
- **Open Food Facts**: nothing runs on-device that isn't disabled in the F-Droid
  build; server-side inference is documented publicly per model.

The pattern: the credible ones make a *mechanical* claim ("no intermediate
server", "audio stays on-device") rather than a values claim. That is the same
move as our README's destination table.

## What this means for OpenNutriTracker

**Where our design is conventional.**

- BYO-key with no bundled credential is the norm, not a novelty. Every shipped
  free-licence mobile tracker with AI does this, and the one project that tried
  operating its own proxy (Fud AI Premium) discontinued it.
- Secure-storage choice matches exactly. Train Libre uses
  `flutter_secure_storage` with one key per provider; Fud AI uses the native
  equivalents directly.
- Resolving model output against the existing food database rather than trusting
  it is what the two most careful projects do (Train Libre, Scranbook).
- Refusing to call the local tier "AI" is unusual but defensible; nobody else
  ships a deterministic parser to compare against.

**Where our design is unusual, and worth re-examining.**

1. **One hardcoded provider.** Every shipped comparator is multi-provider from
   v1, and most get there cheaply because nine of Fud AI's thirteen providers
   are just a base-URL swap. Anthropic-only means no Ollama/LM Studio story at
   all — which is the first thing the privacy-focused audience asks for
   (Food You #419 asks for "even a local AI endpoint"; Fud AI #36 asks for
   on-device Gemma). A single `baseUrl` text field behind the provider
   interface would buy local inference and OpenRouter for near-zero cost.
2. **Letting the model emit macros at all.** Decision #5 in #599 is the loosest
   posture in the entire cohort. Train Libre bans it outright; Scranbook
   computes macros locally from bundled composition data; EatWise ships only
   wide ranges and qualitative portions. Our "every number is cited" claim is
   stronger than any of theirs, and #599's answer — a new `MealSourceEntity`
   value plus an "estimated" marker — is the *warning* approach that our own
   #250 spike argued does not substitute for provenance.
3. **Text first, photo deferred.** The cohort is the other way round: photo is
   the headline feature and text is secondary. That is not obviously wrong (it
   is the cheaper, more testable path) but it means tier 1 alone will not read
   as competitive with Fud AI or Train Libre.
4. **No free tier to fall back on.** #599 already notes this. Fud AI's #106 is
   what it looks like in practice, and Fud AI could at least redirect users to
   free Gemini, Groq and OpenRouter tiers. Anthropic-only removes that valve
   and makes every support thread about billing end in "add a card".

**Concrete pitfalls other projects hit that #599 does not cover.**

- **Keystore corruption on reinstall.** Fud AI's `KeyStore.kt` documents an
  `AEADBadTagException` on Android 14/15 where the Keystore master-key alias
  outlives the encrypted prefs file, crashing in `Application.onCreate` before
  any UI. `flutter_secure_storage` sits on the same substrate. We need the
  equivalent catch-wipe-rebuild path, and losing the key on reinstall is the
  correct behaviour.
- **Never validate the shape of a pasted key.** Fud AI #140 rejected valid
  Gemini keys because Google changed the prefix from `AIza` to `AQ.`, and #105
  was a trailing newline in a paste. Trim aggressively, validate with a live
  ping, never with a regex.
- **Truncation is a distinct failure from malformed output.** Constrained
  decoding solves the Tandoor #4659 problem (Claude fencing its JSON), but not
  Fud AI #139/#145, where the response was cut off by the token budget and
  raising the budget destabilised the app. Handle `stop_reason: "max_tokens"`
  explicitly and cap the retry loop.
- **Anthropic's image content-part shape is not portable.** NutriTrace had to
  normalise `{type:'image', source:{...}}` to the OpenAI `image_url` shape
  because gateways reject the Anthropic form. If the provider interface is meant
  to admit more providers later, put the wire-shape adaptation at the boundary
  now rather than leaking Anthropic's shape through it.
- **Cap request size and retries even when the user pays.** Tandoor enforces a
  ~$1/month per-space credit ceiling and logs every call; NutriTrace caps at 60
  messages / 8 MB and rate-limits to 30/min. BYO-key moves the cost to the user
  but does not make a runaway loop harmless.
- **Base64 payload limits are a real failure mode.** Tandoor's docs warn that
  base64-in-request "can exceed provider limits or reverse proxy limits".
  Relevant to tier 2's WebP path.
- **A per-locale parser is a maintenance argument, not just a code one.**
  Fud AI closed #130 — which proposed exactly a local quick-parser — because
  language-specific parsing "would need to be maintained across all supported
  languages". We ship 9 locales. Tier 0 needs an explicit answer: either
  language-neutral heuristics, or a stated English-first scope.
- **#250 and #599 disagree and both are live.** Our own tracker now contains a
  closed issue arguing the BYO-key path is not worth maintaining, and an open
  umbrella issue adopting it. Whoever picks up tier 1 will find #250 first.
  Reconciling them — particularly the store-review provenance argument, which
  is independent of who runs the model — should happen before tier 1 is scoped.

## What I could not verify

- Whether Fud AI is distributed on F-Droid. Its README links only App Store,
  Play and its own site, and contains no F-Droid reference; I did not search the
  `fdroiddata` metadata repository directly.
- The date, terms, or reason for the discontinuation of the "Fud AI Premium
  proxy". The only source is one sentence in the current README.
- Whether Kai 9000 ships a bundled free tier (which would explain its NonFreeNet
  label more simply than BYO-key access does). That claim came from a search
  result summary, not the repository.
- Whether F-Droid has ever ruled on an app where AI is an *optional secondary*
  feature. Both precedents found are apps whose primary purpose is LLM chat.
- Whether Tandoor encrypts the provider API key anywhere outside the
  `AiProvider.api_key` `CharField`; I read the model definition only.
- Whether NutriTrace's AI configuration is genuinely per-user. The docs say
  "per-user in Settings → AI Assistant", but `server/ai.js` stores it in an
  instance-wide `app_config` table.
- SparkyFitness's AI key scoping and whether its licence has changed; GitHub
  reports no recognised licence and `LICENSE` reads as a custom
  non-commercial grant.
- Detail beyond metadata and one config file for MacroShot,
  [Luma](https://github.com/d3mocide/Luma) and
  [OpenFoodJournal](https://github.com/kvn8888/OpenFoodJournal); all three claim
  AI features but were not read in depth.
- Whether any project has published measured accuracy for cloud-model nutrition
  estimation. None of the shipped projects publish evaluation numbers; the only
  measured data found is our own #250 spike, and that covers on-device models.
- Download or install counts for any of these apps. GitHub stars are a proxy
  only.
