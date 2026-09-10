# What the published privacy policy still does not say about what the app does

**Verdict: the policy is in far better shape than a gap audit usually finds —
it names Supabase, Sentry, Open Food Facts, OpenRouter and the gateway log,
and the German translation is in sync. The remaining gaps are almost all of
one kind: the policy describes the code on `develop`, and the code on
`develop` is not what anybody is running.** v2.0.2 shipped on 2 August 2026
and none of the four commits that make the policy's Sentry and Supabase
paragraphs true are in it. Three of the findings below are cases where the
released binary contradicts a sentence the policy states as fact. The AI
feature, which the brief expected to be the large hole, is already described
in more detail than most shipping apps manage — but it never names two of the
four providers it can send a photograph to, one of which is the default.

Audited **2026-08-27** against the policy text served that day
(`Latest update: August 27, 2026`), against `develop` at `eb08e121`, against
tag `v2.0.2` as the released baseline, and against `feat/own-server-settings`
for the unreleased AI paths. This is a code-to-text comparison, not legal
advice, and nothing here is an opinion on liability.

## Bottom line up front

1. **Crash reports from the released app carry the food diary.** The policy
   says the diary, weight and profile *"are never sent"*. In v2.0.2 every
   `log.fine` line becomes a Sentry breadcrumb, and those lines include the
   search term the user typed and the millilitres of water they logged. The
   fix exists and is unreleased. [Finding 1](#1-crash-reports-from-the-released-app-carry-the-diary).
2. **Released search terms land in the Supabase gateway log.** The policy's
   candid paragraph about what the gateway records — address, city, postal
   code, ISP, TLS fingerprint — omits the one field that matters, because
   in v2.0.2 the term is still in the URL. #882's fix is merged, unreleased.
   [Finding 2](#2-in-the-released-app-the-search-term-is-in-the-url-the-gateway-logs).
3. **Sentry is not only crash reporting.** `tracesSampleRate = 1.0` in both
   the released and the current build. The policy's *"a crash sends a
   technical report"* describes half of what the SDK is configured to send.
   [Finding 3](#3-sentry-is-configured-for-performance-tracing-not-only-crashes).
4. **Anthropic and OpenAI are never named**, and Anthropic is the provider a
   fresh install defaults to. The policy names OpenRouter and "your own
   server" and stops. [Finding 8](#8-two-of-the-four-ai-providers-are-never-named-and-one-is-the-default).
5. **Health Connect / Apple Health has no section at all.** Unreleased, so
   not yet a live gap — but it reads special-category data and ships next.
   [Finding 7](#7-health-connect--apple-health-has-no-section).
6. Two smaller undisclosed flows in the released app: product **photographs
   are fetched per logged meal** ([Finding 4](#4-product-images-are-fetched-for-meals-already-in-the-diary)),
   and the Supabase request carries the device locale and the user's
   food-source toggles ([Finding 5](#5-the-supabase-request-carries-more-than-the-search-term)).
7. One thing the policy claims that the **next** release will stop doing: the
   installation identifier in crash reports. Correct today, wrong the moment
   #901 ships. [Finding 12](#12-the-installation-identifier-is-true-today-and-false-after-the-next-release).

## How this was read

The policy was fetched on 2026-08-27 in its full legal view
(`/privacy-policy/53501884/full-legal`), which is what the app links to via
`URLConst.privacyPolicyURLEn`. The German document (`53922100`, linked for
`de` by `URLConst.privacyPolicyFor`) was fetched too and carries the same
`27. August 2026` date, the same sections and the same wording — it is a
faithful translation and inherits every finding below rather than adding one.
No cookie policy or Terms document exists at a sibling iubenda URL.

Released behaviour means tag `v2.0.2` (build 61, 2026-08-02), which is the
latest GitHub release and the version in `pubspec.yaml` on `main`. `main`
carries three commits past the tag and none is released. Every "released"
claim below was checked with `git merge-base --is-ancestor <commit> v2.0.2`
and every quoted line was read out of `git show v2.0.2:<path>`, not out of
the working tree — the two differ substantially in exactly the files that
matter here.

Citations of the form `path:NN` refer to `develop` unless the line is
introduced as `v2.0.2:path:NN` or `feat/own-server-settings:path:NN`.

---

## Released behaviour the policy contradicts

### 1. Crash reports from the released app carry the diary

**Severity: highest. Data leaves the device to a third party, and the policy
states the opposite as a fact.**

> Your food diary, your weight and your profile are never sent, and the app
> does not attach your IP address.
>
> — Sentry section, full legal view

The second half is true. The first half is not true of v2.0.2.

`SentryOptions.enablePrintBreadcrumbs` defaults to `true`, and
`DebugPrintIntegration` is registered unconditionally and bows out only in
debug mode — so it is live in precisely the builds where crash reporting can
run. v2.0.2 sets neither:

```
v2.0.2:lib/main.dart:150-154
    await SentryFlutter.init(
      (options) {
        options.dsn = Env.sentryDns;
        options.tracesSampleRate = 1.0;
      },
```

That is the whole of the released configuration. Meanwhile
`v2.0.2:lib/main.dart:51` calls `LoggerConfig.intiLogger()` before anything
else, and that pipes the entire application log through `debugPrint` with no
level floor:

```
v2.0.2:lib/core/utils/logger_config.dart:6-12
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint(...)
```

So every log record in the app becomes a breadcrumb riding along on the next
event of any kind. What that sweeps up, in the released build:

- `v2.0.2:lib/features/add_meal/data/data_sources/off_data_source.dart:94` —
  `log.fine('Fetching OFF results from: $searchUrl')`. The URL is
  `search.openfoodfacts.org/search?q=<what the user typed>`.
- `lib/core/data/data_source/water_intake_data_source.dart:19` —
  `log.fine('Adding water intake ${entry.amountMl} ml at ${entry.dateTime}')`.
- `lib/core/data/data_source/weight_log_data_source.dart:20` — the date of
  every weight entry.
- Barcode lookups, custom activity names, intake edits, on the same path.

The project already knows this. `lib/core/utils/sentry_config.dart:7-21` on
`develop` documents the mechanism and the exact consent sentence it breaks,
and `:25` fixes it with `options.enablePrintBreadcrumbs = false`. That file
does not exist at `v2.0.2` — `git show v2.0.2:lib/core/utils/sentry_config.dart`
returns *"exists on disk, but not in 'v2.0.2'"*. The fix landed in the
`e53be1bc` / #877 line of work.

> **Update, 2026-09-05.** It has since shipped: `v2.2.0` carries
> `sentry_config.dart` with `options.enablePrintBreadcrumbs = false`. The
> finding above is left as audited against `v2.0.2`, which is what it was
> written about and what the published policy was measured against — but it
> is no longer a live defect, and the sentence below that depended on it has
> been corrected rather than left arguing from a fixed bug.

The app's own in-product consent text is more specific and equally wrong in
the shipped build: `v2.0.2:lib/l10n/intl_en.arb` reads *"Send anonymous crash
reports to help fix bugs. No food log, weight, or personal data is included."*

**What to do:** this is a release problem before it is a policy problem. Ship
the fix. If a release is not imminent, the Sentry section needs a sentence
saying that builds before the next version attach recent application log lines
to a crash report, and that those lines can include food searches, barcodes,
water and weight entries.

### 2. In the released app, the search term is in the URL the gateway logs

**Severity: highest. The policy discloses the gateway log in unusual detail
and omits the single most sensitive field in it.**

> Because the request travels over the internet, the platform's gateway
> records for 24 hours the address the request came from, an approximate
> location derived from that address (country, region, city and postal code),
> the name of your internet access provider, and a fingerprint of the
> encrypted connection.
>
> — Food reference backend (Supabase) section

That list is accurate and better than most policies manage. It is also
incomplete for anyone running v2.0.2, because the released client puts the
search term in the query string, where it is logged in the same record beside
the address, the city and the postal code:

```
v2.0.2:lib/features/add_meal/data/data_sources/sp_food_data_source.dart:95
    var query = client.from(SPConst.foodSummaryTable).select().textSearch(
```

A PostgREST `select().textSearch()` is a `GET` and the term travels as a URL
parameter. `develop` fixed this in #911 by moving every search onto an RPC —
`lib/features/add_meal/data/data_sources/sp_food_data_source.dart:101`,
`client.rpc(fn, params: params)`, with the term as `'term': searchString` at
`:121` — so the URL is a bare `/rest/v1/rpc/search_food_summary`. The backend
records why in its own schema, `sql/schema.sql:387-390`: those URLs *"sit in
the same record as the caller's IP, city, postal code"*. The localized path
was moved for the same reason at `:147`, and even the follow-up id fetch was
made an RPC (`:190`) because the ids are derived from the term and would be a
fingerprint of it in the URL.

`eb08e121` is not an ancestor of `v2.0.2` or of `main`. Released users leak.

**What to do:** same as Finding 1 — ship it. Until then, the Supabase
paragraph should add the search term to the list of what the gateway records
for 24 hours, or the policy should say that this was true of versions up to
2.0.2 and changed in the version that carries the fix.

### 3. Sentry is configured for performance tracing, not only crashes

**Severity: inaccurate description of an active data flow.**

> When it is on, **a crash** sends a technical report […]
>
> — Sentry section (emphasis added)

`tracesSampleRate = 1.0` in the released build (`v2.0.2:lib/main.dart:153`)
and in the current one (`lib/core/utils/sentry_config.dart:24`). A non-null
traces sample rate is what enables transaction sending in `sentry_flutter`,
and `enableAutoPerformanceTracing` is on by default — so app-start and
screen-load transactions are produced for ordinary sessions, at a 100 % sample
rate, with no crash involved.

Two consequences the policy does not carry. First, the reader is told the
network is touched only when something breaks, and it is touched every time
they open the app with the toggle on. Second, the policy's own concession that
*"Sentry's servers may derive an approximate location (country, region and
city) from the connection"* then applies once per session rather than once per
crash, which is a materially different picture of how often a coarse location
is observed.

The consent string is scoped the same narrow way — `"Send crash reports to
help fix bugs"` (`lib/l10n/intl_en.arb`, `dataCollectionLabel`).

**What to do:** either drop the traces sample rate to `0` (there is no
evidence in the repo that anyone reads the performance data), or widen the
policy sentence and the consent string to "crash and performance reports".
The first is cheaper and matches what the toggle promises.

---

## Undisclosed flows in the released app

### 4. Product images are fetched for meals already in the diary

**Severity: undisclosed transfer to a third party. Lower than 1–3 because the
recipient is one the policy already names, but the *occasion* is not
disclosed and it is the more revealing of the two.**

Both third-party sections scope the transfer to a search:

> When you search for a food or scan a barcode, this Application sends the
> search term or the barcode to Open Food Facts […]
>
> A search sends the text you typed.

Neither mentions that the app then downloads the product photograph, and keeps
downloading it long after the search is over. `MealDBO` stores Open Food Facts
entries' thumbnails as remote URLs (`lib/core/data/dbo/meal_dbo.dart:45-50`),
taken straight from the API's `image_url` / `image_front_thumb_url` fields
(`lib/features/add_meal/data/dto/off/off_product_dto.dart:44-48`), and the
diary card renders them over the network:

```
lib/core/presentation/widgets/intake_card.dart:125-128
    } else if (intake.meal.mainImageUrl != null) {
      content = CachedNetworkImage(
        cacheManager: locator<CacheManager>(),
        imageUrl: intake.meal.mainImageUrl ?? "",
```

Seven render sites do this — the diary card above, plus
`meal_detail_screen.dart:327`, `edit_meal_screen.dart:954`,
`meal_item_card.dart:114`, `recipe_list_item.dart:108`,
`food_search_tab_view.dart:306` and `image_full_screen.dart:35`. The cache is
bounded at 30 days and 200 objects
(`lib/core/utils/ont_image_cache_manager.dart:4-5`), so for any user with more
than 200 distinct foods, or any food they return to after a month, the request
goes out again.

The distinction worth drawing for the reader: a search term says what somebody
was *curious about*; an image request for a diary entry, repeated whenever the
card renders past its cache, says what they actually *ate*, at the moment they
looked at it. That is a stronger inference than the disclosed flow and it is
not in the policy.

**What to do:** add a sentence to the Open Food Facts section — a food's
photograph is downloaded from Open Food Facts when it appears in search
results, in the diary or on a meal screen, and is cached for 30 days. The
`Personal Data processed` list for that section should gain "product
identifiers" alongside search terms and barcodes.

### 5. The Supabase request carries more than the search term

**Severity: incomplete `Personal Data processed` list.**

> A search sends the text you typed. No account, profile or device identifier
> is attached, and your food diary is never sent.
>
> Personal Data processed: search terms; IP address; approximate location;
> connection identifiers; Usage Data.

The negative claims are all true — nothing in `SpFoodDataSource` reaches for
an identifier. But two fields travel that are not in the list:

- **The device locale.** `lib/features/add_meal/data/data_sources/sp_food_data_source.dart:42`
  resolves it from `Platform.localeName` and `:147` sends it as `'loc': locale`.
- **The user's food-database toggles.** `:122` and `:190` send
  `'sources': enabledSources` — the list of which of the five catalogues that
  user has left switched on in Settings → Food databases, built at `:79-86`.

Neither identifies anybody on its own. Together, arriving beside an IP address
and a postal code in a 24-hour gateway log, they are a small settings
fingerprint, and the policy has committed to listing what is processed per
service. The Open Food Facts section sets the precedent by listing its own
language parameter (albeit under the wrong name — see Finding 11).

**What to do:** add "app language" and "food-source preferences" to that
section's processed-data list.

### 6. Two Open Food Facts hosts, and an undisclosed User-Agent

**Severity: minor accuracy.**

The policy speaks of Open Food Facts as one destination in France. The app
talks to two hosts run on different infrastructure:
`search.openfoodfacts.org` for text search and `world.openfoodfacts.org` for
barcode lookups and for the fallback when the first is down
(`lib/core/utils/off_const.dart:7, 14, 22`,
`lib/features/add_meal/data/data_sources/off_data_source.dart:61-72`). The
circuit breaker at `off_data_source.dart:23` means the destination for a given search silently
depends on whether the other one 502'd in the last five minutes.

Every one of those requests also carries a User-Agent naming the app, the
platform and the version — `lib/core/utils/app_const.dart:27-31` via
`lib/core/utils/ont_http_client.dart:11`. It is not an identifier and the
README already discloses it, but the policy's processed-data list does not.

**What to do:** low priority. A parenthetical that Open Food Facts serves
search and product lookups from more than one host, and that requests identify
the app and its version, would close it.

---

## Unreleased behaviour that needs disclosure before it ships

None of the following is in v2.0.2, so none is a live gap today. All of it is
on branches heading for release.

### 7. Health Connect / Apple Health has no section

**Severity: highest of the unreleased set. Special-category data under GDPR
Article 9, and no clause of any kind exists.**

`af28c39f` ("opt-in workout import from Health Connect / Apple Health", #651)
is on `develop` and is not an ancestor of `v2.0.2` or `main`. It reads:

```
lib/core/data/data_source/health/health_package_service.dart:19-33
    static const _coreReadTypes = [
      HealthDataType.WORKOUT,
      HealthDataType.BODY_FAT_PERCENTAGE,
    ];
    static const _androidWorkoutDetailTypes = [
      HealthDataType.TOTAL_CALORIES_BURNED,
      HealthDataType.DISTANCE_DELTA,
      HealthDataType.STEPS,
    ];
```

with the matching `android.permission.health.READ_*` grants at
`android/app/src/main/AndroidManifest.xml:8-16` and an
`NSHealthShareUsageDescription` at `ios/Runner/Info.plist:66`.

The implementation is genuinely conservative — read-only, opt-in, nothing
written back, and the data stays on the device. That is a good argument that
the Owner never becomes a controller for it, and therefore that Articles 13
and 14 do not bite. It is *not* an argument for silence, for three reasons:

1. The policy's opening list is presented as complete — *"Among the types of
   Personal Data that this Application collects […]"* — and a reader who
   turns on workout import is entitled to find it there.
2. Google's broader *accesses* standard lands on the **privacy policy**, the
   in-app disclosure and the Health apps declaration — which is this finding —
   and Google is explicit that *"You alone are responsible for making complete
   and accurate declarations"*. Health and fitness is a declarable category
   there.

   *Corrected 2026-09-04:* this point previously said the **Data safety form**
   must cover data the app accesses "regardless of where it ends up". It does
   not, and [#937](https://github.com/simonoppowa/OpenNutriTracker/issues/937)
   settled it the other way: that form is scoped to collection and sharing,
   "collect" means transmitting off device, and *"User data accessed by your app
   that is only processed locally on the user's device and not sent off device
   does not need to be disclosed."* The correction strengthens this finding
   rather than weakening it — the duty the access standard creates is precisely
   the policy text this section is asking for.
3. Finding 1 is the concrete counter-example to "on-device means out of
   scope": on-device values **did** leave, through Sentry, in a released
   build, for as long as `enablePrintBreadcrumbs` kept its default. Fixed and
   shipped in `v2.2.0`, so the assumption is no longer wrong *here* — but it
   was wrong once, quietly, in exactly the place nobody was looking, which is
   the argument for not making it anywhere else.

**What to do:** add a section stating that health data is read only after the
user enables workout import, listing the five types, and stating plainly that
it is never transmitted. A short "what stays on your device" section would
also be the natural home for the encrypted Hive boxes, which the README
describes well and the policy does not mention at all.

### 8. Two of the four AI providers are never named, and one is the default

**Severity: high. GDPR Article 13(1)(e) recipients, and the policy has already
chosen the "name them" style everywhere else.**

The AI section is careful and mostly excellent (see
[what the policy gets right](#where-the-policy-is-fine)). It names exactly one
provider:

> If you choose OpenRouter, your request reaches OpenRouter and the vendor
> serving the model you picked — two recipients, not one […] If you configure
> your own server, the request goes to the address you entered […]

There are four providers, not two, and the other two are compiled-in
endpoints the Owner chose:

- `feat/own-server-settings:lib/features/add_meal/data/anthropic_meal_items_api.dart:16`
  — `https://api.anthropic.com/v1/messages`
- `feat/own-server-settings:lib/features/add_meal/data/openai_meal_items_api.dart:27`
  — `https://api.openai.com/v1/responses`

And Anthropic is what a fresh install resolves to:

```
feat/own-server-settings:lib/core/utils/ai_credential_storage.dart:41-42
    static AiProvider? fromTag(String? value) {
      if (value == null || value.isEmpty) return AiProvider.anthropic;
```

So the single most likely destination for a user's first meal photograph is
the one provider the policy never mentions. Article 13(1)(e) permits
*"recipients or categories of recipients"* — a category would be defensible if
the document used categories throughout. It does not: it names Supabase,
Sentry, Apple Inc., Google Ireland Limited, Google LLC, Open Food Facts,
Cloudflare and Amazon Web Services. Naming six sub-processors and omitting the
default AI recipient is the inconsistency.

Article 13(1)(f) is thinner here too. *"Place of processing: the country of
the provider you choose — see that provider's own privacy policy"* is a
pointer, not a transfer statement, and for the two US-headquartered providers
the app ships endpoints for it says nothing about the safeguard relied on. The
Supabase and Sentry sections both do this properly, which shows the document
knows how.

**What to do:** name all four. One sentence per hosted provider with its
country is enough; the "your own server" paragraph already handles the fourth
correctly by explaining that the Owner cannot know the address.

### 9. The photo fallback path sends the original file, EXIF included

**Severity: high if it fires — undisclosed location data to a third party.
Conditional, so ranked below Finding 8.**

> only the meal description you type — or a photo you deliberately pick — is
> sent to that provider
>
> Personal Data processed: the text or the photo you submit for
> interpretation; your app language.

True of the pixels. Silent about the metadata, and the normal path and the
fallback path differ.

The normal path re-encodes through `FlutterImageCompress.compressWithFile` at
quality 80 and 1024 px
(`feat/own-server-settings:lib/features/add_meal/util/meal_photo_encoder.dart:159-175`).
`keepExif` is never set — `git grep -i exif` over `lib` on that branch returns
nothing — and it defaults to `false`, so re-encoding strips the metadata as a
side effect. Good outcome, incidental cause.

The fallback path does not re-encode:

```
feat/own-server-settings:lib/features/add_meal/util/meal_photo_encoder.dart:136-141
    // The encoder failed. Send the original if the destination takes that
    // format […]
    final mediaType = mediaTypeForPath(sourcePath);
    if (mediaType == null) return null;
    final raw = await _rawBytes(sourcePath);
    if (raw == null) return null;
    return _fitting(raw, mediaType);
```

`_rawBytes` (`:183`) reads the picked file byte for byte, gated only on being
under 3 MB. The comment at `:69` is explicit that this exists for *"a device
whose encoder failed, where the file is the camera's own output"* — which is
the case that carries the fullest EXIF block: GPS coordinates, capture
timestamp, camera make, model and sometimes serial. The accepted extensions at
`:76-82` include `jpg`, `jpeg` and `png`, all of which carry EXIF.

Nothing about this is careless — the encoder authors thought hard about the
fallback and about deleting the picker's cache copy (`:95-113`, verified on a
Pixel 6). EXIF simply was not the question they were asking.

**What to do:** strip metadata explicitly rather than as a side effect, on
both paths — that removes the finding instead of disclosing it, which is the
better outcome and matches how this codebase has handled every other
disclosure question. If the fallback is kept as-is, "location data" has to
join the AI section's processed-data list, and that is a much worse sentence
to have to write.

### 10. A probe request fires as soon as a key is saved

**Severity: wording only.**

> AI meal assistance is switched off until you enter your own API key for a
> provider you have chosen. Nothing is sent anywhere until you do.

Accurate. Worth knowing that the first thing sent is not a meal:
`feat/own-server-settings:lib/features/add_meal/domain/usecase/probe_ai_endpoint_usecase.dart`
sends a canned English line (`aiProbeMealLine`, *"two eggs and a slice of
toast"*) and a bundled demo photograph (`aiProbePhotoAsset`) to establish what
the endpoint can do. No user data is involved, so there is no disclosure
obligation — but a reader parsing "nothing is sent until you enter a key" as
"nothing is sent until you use the feature" would be surprised by a request,
and by a charge, at the moment they hit save.

**What to do:** optional. "…until you enter your own API key, at which point
the app makes one test request to check the provider works."

---

## Things the policy claims that the source does not do

### 11. "a country code derived from your device's language settings"

**Severity: inaccurate description.**

> […] together with a country code derived from your device's language
> settings, which the service uses to rank results.
>
> Personal Data processed: search terms; barcodes; a country code; Usage Data.

There is no country code on any Open Food Facts request. What is sent is a
**language** code, in the `langs` parameter:

```
lib/features/add_meal/data/data_sources/off_data_source.dart:48-52
    String _searchLangs() {
      final lang = SupportedLanguage.fromCode(Platform.localeName).name;
      return lang == 'en' ? 'en' : '$lang,en';
    }
```

passed at `:66` into `OFFConst.getOffWordSearchUrl(searchString, langs: ...)`,
which places it under `_salLangsTag = "langs"`
(`lib/core/utils/off_const.dart:36, 108-117`). The legacy fallback URL
(`:124-136`) sends no locale at all, and neither does the barcode lookup
(`:138-148`).

The two are not interchangeable: a country code would be a coarse location
signal, and a language code is not. The policy currently over-discloses in a
way that makes the app sound worse than it is. The README repeats the same
wrong word — *"a country tag from your device locale"* (`README.md:133`) — so
both inherit one error and both should be corrected together.

### 12. The installation identifier is true today and false after the next release

**Severity: will become an over-disclosure. Flagged so it is not missed.**

> […] together with a randomly generated identifier for your installation.

Correct for v2.0.2, where the native SDKs attach a stable per-installation
UUID as `user.id` and nothing removes it. Incorrect for `develop`, which
strips the whole user block before the event leaves the device:

```
lib/core/utils/sentry_config.dart:50-52
    SentryEvent? _stripUser(SentryEvent event, Hint hint) {
      event.user = null;
      return event;
    }
```

`4214fb5b` (#900/#901) is not an ancestor of `v2.0.2` or `main`. The policy is
therefore right about the app people are running and will need this sentence
removed on the same day that release ships — the same release that fixes
Findings 1, 2 and 12 together.

### 13. The AI boilerplate sentence misdescribes the feature

**Severity: boilerplate, but the misleading kind.**

> This service uses artificial intelligence. Certain features of AI meal
> assistance (your own provider) are powered by automated systems that process
> your data to personalise or improve your experience.

That is iubenda's generic AI clause and it is wrong in both halves for this
feature. Nothing is personalised: `ModelMealTextInterpreter._systemPrompt`
(`feat/own-server-settings:lib/features/add_meal/data/model_meal_text_interpreter.dart:27-45`)
carries no user context beyond the meal line and the app language, and the
schema at `meal_items_api.dart:68-118` forbids nutrition fields by
construction, so the model returns food names and quantities and nothing else.
Nothing is improved either — no output is retained by the app, and `store:
false` is sent to OpenAI explicitly
(`feat/own-server-settings:lib/features/add_meal/data/openai_meal_items_api.dart`).

The clause also gestures at Article 13(2)(f) territory. It should not: there is
no automated decision producing legal or similarly significant effects here —
the user reviews every extracted row before it enters the diary. Leaving
boilerplate that implies otherwise invites a question the feature does not
actually raise.

**What to do:** replace with a sentence saying what it does — a model reads
the description or the photograph and returns a list of food names and
amounts, which the user confirms before anything is saved.

---

## Structural and boilerplate gaps

Ranked last on purpose. None of these describes data moving anywhere
undisclosed.

**14. The opening data-type list has not been kept in step with the detailed
sections.** The top of the document lists *"Usage Data; diagnostics; email
address; app information; device logs; device information; Data communicated
while using the service"*. The detailed sections below add search terms,
barcodes, a photograph, an approximate location and an installation
identifier. iubenda generates the summary list from the service definitions,
so the custom-written sections have outrun it.

**15. No retention period for two of the five processing activities**
(Article 13(2)(a)). Supabase carries 24 hours and Sentry 30 days, both
specific and good. The Open Food Facts and AI sections carry nothing —
defensible, since neither recipient is the Owner's processor, but the honest
version of that is a sentence saying so rather than an absence.

**16. No legal basis stated for the AI section** (Article 13(1)(c)). Open Food
Facts and Supabase both name legitimate interest *and* an objection route, in
the same paragraph, which is genuinely well done. The AI section names
nothing, although the basis is obviously consent — the user has to enter a key
— and the withdrawal route (delete the key) is worth stating alongside the
existing consent-withdrawal clause.

**17. "Reset profile data" deletes less than a reader might infer.**
`DeleteAllUserDataUsecase.deleteAll` clears eight boxes for the *active
profile only* (`lib/core/domain/usecase/delete_all_user_data_usecase.dart:45-54`)
and deliberately leaves the shared custom-meal, recipe and activity-template
libraries, the shared settings box, the 90-day remote-search cache
(`lib/main.dart:79`) and every other profile. This is a defensible design
and the in-app confirmation text says so almost word for word
(`settingsDeleteAllDataConfirmContent` in `lib/l10n/intl_en.arb`). It is not a
policy gap — the Owner holds none of this data, so the Article 17 erasure
right does not attach to it — but it is the answer to Play's "data deletion
request" question and it is the subject of issue #892, so it belongs in the
same review.

---

## Where the policy is fine

Worth stating plainly, because the list above is longer than the document
deserves.

- **The Supabase gateway paragraph is unusually candid.** Naming the 24-hour
  window, the postal code and the TLS fingerprint is more than most policies
  concede, and it matches the backend's own note at `sql/schema.sql:387-390`.
  Sub-processors (Cloudflare, AWS), the Frankfurt location and the SCC basis
  are all named. Only the search term is missing, and only in released builds.
- **The Sentry framing is accurate apart from Findings 3 and 12.** Opt-in,
  release-builds-only, consent as the basis, immediate withdrawal — all match
  `lib/main.dart:131` (`kReleaseMode && hasAcceptedAnonymousData`) and
  `delete_all_user_data_usecase.dart:39` (`Sentry.close()`).
- **"the app does not attach your IP address" is true.** `sendDefaultPii` is
  never set to `true` anywhere in the repo, and the policy separately concedes
  that Sentry derives a coarse location server-side — which is the honest way
  to state it.
- **The OpenRouter paragraph is better than the code strictly required.** Two
  recipients rather than one, the account-level identifier that cannot be
  switched off, and the fact that the Owner receives nothing. The client backs
  it up: `data_collection: 'deny'` and `allow_fallbacks: false` are sent
  (`openai_compatible_meal_items_api.dart`), and the app deliberately omits
  OpenRouter's `HTTP-Referer` / `X-Title` attribution headers so that saving a
  key does not put the user on a public leaderboard.
- **API key handling matches the claim.** *"held in your device's own secure
  credential store"* — `flutter_secure_storage` against the Android Keystore
  and iOS Keychain, with `resetOnError: false`
  (`lib/core/utils/secure_app_storage_provider.dart:22-30`).
- **No ads, no analytics SDK, no advertising ID, no account.** `pubspec.yaml`
  contains no Firebase, Crashlytics, Google Analytics or attribution SDK;
  `AndroidManifest.xml` requests no `AD_ID`; `ios/Runner/PrivacyInfo.xcprivacy`
  declares `NSPrivacyTracking` false with an empty tracking-domains array and
  all three collected types marked not-linked. There is no in-app purchase,
  donation or update-check endpoint anywhere in `lib/`.
- **The German document is a faithful translation and equally current.**
  Same `27. August 2026` date, same sections, same wording. `URLConst
  .privacyPolicyFor` routes only `de` to it and everything else to English,
  which is the right call while only two documents exist.
- **Controller identity, contact, rights, one-month response and complaint
  route** are all present and correct (Article 13(1)(a), 13(2)(b)–(d)).

---

## Not verified

- **Whether Sentry's organisation has a `user.geo` scrubbing rule**, and
  whether its retention is actually set to the 30 days the policy states.
  Neither is visible from this repo; `sentry_config.dart:46-49` explicitly
  notes that `user.geo` is derived server-side and *"has to be dealt with by a
  data-scrubbing rule on the organisation instead"*. Check in the Sentry
  dashboard.
- **Whether an app-start transaction actually reaches Sentry** in this
  configuration. Finding 3 is inferred from `tracesSampleRate` being non-null
  plus `enableAutoPerformanceTracing` defaulting on, not measured on a device.
  Confirm before rewriting the policy sentence.
- **Which ML Kit variant `mobile_scanner` 7.2 pulls on Android** — bundled
  model or the Play-Services-downloaded one. `android/app/build.gradle`
  declares no ML Kit dependency of its own (`dependencies` at `:138` holds
  only `desugar_jdk_libs`), so the plugin's default applies and it was not
  established. If it is the unbundled variant, first use of the scanner
  fetches a model from Google.
- **Whether the Supabase image columns ever resolve to a URL the app
  fetches.** `sql/schema.sql:278-280` builds a *relative*
  `/storage/v1/object/public/food-images/…` path and nothing in `lib/` was
  found that prefixes it with the project URL, so Finding 4 was established
  against Open Food Facts image hosts only. If that path is ever made
  absolute, Finding 4 extends to the Supabase storage bucket.
- **Whether iubenda's short (simplified) view differs materially** from the
  full legal view. Only the full view was parsed in detail.
- **Google Play's Data safety declaration itself.** It lives in the Play
  Console, not in this repo — no declaration file, fastlane metadata entry or
  checked-in copy exists. Findings 4, 5 and 7 are the ones most likely to make
  the current declaration inaccurate.

---

## How to re-check

Re-run this audit whenever a release ships, when a new destination is added,
or when the policy is edited.

**1. Get the policy text.** The full legal view is server-rendered, so `curl`
is enough:

```sh
curl -sL -A "Mozilla/5.0" \
  https://www.iubenda.com/privacy-policy/53501884/full-legal \
  | python3 -c "import re,html,sys; t=sys.stdin.read(); \
t=re.sub(r'(?is)<(script|style).*?</\1>',' ',t); t=html.unescape(re.sub(r'(?s)<[^>]+>','\n',t)); \
print('\n'.join(l.strip() for l in t.split('\n') if l.strip()))"
```

Repeat for `53922100/full-legal` (German) and compare the `Latest update`
dates — a skew between them is itself a finding.

**2. Fix the released baseline before reading any code.** This is the step
that produced most of the findings above:

```sh
gh release list --limit 1                     # what is actually out
git merge-base --is-ancestor <commit> v2.0.2  # is this fix in it?
git show v2.0.2:<path>                        # read the released file
```

Never audit the working tree and call the result "what users experience".

**3. Re-enumerate the destinations.** Anything new here needs a policy
section:

```sh
grep -rn "Uri\.\(parse\|https\)\|http\.\|client\.rpc\|CachedNetworkImage" lib --include=*.dart
grep -rn "SentryFlutter.init\|tracesSampleRate\|enablePrintBreadcrumbs\|sendDefaultPii" lib
git ls-tree -r --name-only feat/own-server-settings | grep -iE "meal_items_api|ai_"
```

**4. Re-check the four claims most likely to drift.** Each maps to a finding:
that the diary never leaves (Finding 1 — is `enablePrintBreadcrumbs = false`
in the released build?); that search terms are not in a URL (Finding 2 — is
every Supabase call still an `rpc`?); that only crashes are sent (Finding 3 —
what is `tracesSampleRate`?); that every AI recipient is named (Finding 8 —
does `AiProvider` have a new value?).

**5. Diff the policy's per-service `Personal Data processed` lists against the
request bodies.** Findings 5, 6 and 11 all came from doing exactly that, and
all three are the kind of drift that reappears the next time a parameter is
added to a request.

---

## Sources

Primary policy documents, read on the live page on 2026-08-27:
[Privacy Policy of OpenNutriTracker — full legal view](https://www.iubenda.com/privacy-policy/53501884/full-legal) ·
[simplified view](https://www.iubenda.com/privacy-policy/53501884) ·
[German document](https://www.iubenda.com/privacy-policy/53922100/full-legal)

Obligations cited:
[GDPR Article 13](https://gdpr-info.eu/art-13-gdpr/) ·
[GDPR Article 9](https://gdpr-info.eu/art-9-gdpr/) ·
[Google Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469)

Related notes in this repo:
[`ai-openai-data-handling.md`](ai-openai-data-handling.md) ·
[`ai-openai-key-transfer.md`](ai-openai-key-transfer.md) ·
[`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) ·
[`ai-cleartext-http-policy.md`](ai-cleartext-http-policy.md) ·
[`ai-play-encryption-declaration.md`](ai-play-encryption-declaration.md) ·
[`fdroid-submission-feasibility.md`](fdroid-submission-feasibility.md)

In-repo files cited:
[`lib/main.dart`](../lib/main.dart) ·
[`lib/core/utils/sentry_config.dart`](../lib/core/utils/sentry_config.dart) ·
[`lib/core/utils/logger_config.dart`](../lib/core/utils/logger_config.dart) ·
[`lib/core/utils/off_const.dart`](../lib/core/utils/off_const.dart) ·
[`lib/core/utils/app_const.dart`](../lib/core/utils/app_const.dart) ·
[`lib/core/utils/ont_http_client.dart`](../lib/core/utils/ont_http_client.dart) ·
[`lib/core/utils/ont_image_cache_manager.dart`](../lib/core/utils/ont_image_cache_manager.dart) ·
[`lib/core/utils/secure_app_storage_provider.dart`](../lib/core/utils/secure_app_storage_provider.dart) ·
[`lib/core/utils/url_const.dart`](../lib/core/utils/url_const.dart) ·
[`lib/core/presentation/widgets/intake_card.dart`](../lib/core/presentation/widgets/intake_card.dart) ·
[`lib/core/domain/usecase/delete_all_user_data_usecase.dart`](../lib/core/domain/usecase/delete_all_user_data_usecase.dart) ·
[`lib/core/data/dbo/meal_dbo.dart`](../lib/core/data/dbo/meal_dbo.dart) ·
[`lib/core/data/data_source/health/health_package_service.dart`](../lib/core/data/data_source/health/health_package_service.dart) ·
[`lib/core/data/data_source/water_intake_data_source.dart`](../lib/core/data/data_source/water_intake_data_source.dart) ·
[`lib/features/add_meal/data/data_sources/off_data_source.dart`](../lib/features/add_meal/data/data_sources/off_data_source.dart) ·
[`lib/features/add_meal/data/data_sources/sp_food_data_source.dart`](../lib/features/add_meal/data/data_sources/sp_food_data_source.dart) ·
[`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml) ·
[`ios/Runner/Info.plist`](../ios/Runner/Info.plist) ·
[`ios/Runner/PrivacyInfo.xcprivacy`](../ios/Runner/PrivacyInfo.xcprivacy)

On `feat/own-server-settings` only:
`lib/core/utils/ai_credential_storage.dart` ·
`lib/features/add_meal/util/meal_photo_encoder.dart` ·
`lib/features/add_meal/data/anthropic_meal_items_api.dart` ·
`lib/features/add_meal/data/openai_meal_items_api.dart` ·
`lib/features/add_meal/data/openai_compatible_meal_items_api.dart` ·
`lib/features/add_meal/domain/usecase/probe_ai_endpoint_usecase.dart`

Backend: `opennutritracker-backend/sql/schema.sql` (RPC rationale at `:387-390`).
