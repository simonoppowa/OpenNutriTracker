# #939 — What the crash-data answers owe now that the per-install id and geo are gone

Research for map [#935](https://github.com/simonoppowa/OpenNutriTracker/issues/935). Every store claim below is
cited to first-party documentation. Repo claims are cited to `origin/develop` as read on 2026-08-28.

---

## 0. What the code actually does

Read from `origin/develop`, not from the ticket summary.

`lib/core/utils/sentry_config.dart` — the whole of `configureSentryOptions`:

```dart
options.dsn = dsn;
options.tracesSampleRate = _tracesSampleRate;   // const double? _tracesSampleRate = null;
options.enablePrintBreadcrumbs = false;
options.beforeSend = _stripUser;                // event.user = null; return event;
```

`test/unit_test/sentry_config_test.dart` pins four things: `enablePrintBreadcrumbs` is false, `beforeSend`
is non-null and nulls `event.user` (the test event carries both `SentryUser.id` and `SentryGeo(city:)`),
`tracesSampleRate` is null and `isTracingEnabled()` is false, and `sendDefaultPii` is false (pinning the
SDK default, not a set value).

`lib/main.dart` lines 130–152: `SentryFlutter.init` runs only under `if (kReleaseMode &&
hasAcceptedAnonymousData)`. `lib/features/settings/settings_screen.dart:1217` calls `Sentry.close()` the
moment the switch goes off. So reporting is **opt-in, off by default, per user, withdrawable in-session**.

Landed on develop 2026-08-27: `4214fb5b` (#901, strip user) and `223be963` (#917, tracing off).

**Two things `configureSentryOptions` does *not* set**, both live at their SDK defaults
(`~/.pub-cache/hosted/pub.dev/sentry_flutter-9.26.0/lib/src/sentry_flutter_options.dart`):

- `bool anrEnabled = true;` (line 71) — Android ANR detection, forwarded to
  `androidOptions.setAnrEnabled(options.anrEnabled)` in `native/java/sentry_native_java_init.dart:186`.
- `bool enableAppHangTracking = true;` (line 286), `appHangTimeoutInterval = 2s` (line 294) — iOS app hangs.

Both emit **error events, not transactions**. Turning `tracesSampleRate` to null does not touch them. This
is load-bearing for question 4 and is the one place where the ticket's premise ("performance tracing is off
entirely") is narrower than it sounds: transactions stopped; hang/ANR reporting did not.

`android/app/src/main/AndroidManifest.xml` declares no location permission of any kind. The only
location-shaped signal anywhere in the app is Sentry's server-derived `user.geo`, so question 2 is
answerable in isolation — nothing else in the app would keep a location entry alive.

Measured evidence carried forward from [#889](https://github.com/simonoppowa/OpenNutriTracker/issues/889)
via [#900](https://github.com/simonoppowa/OpenNutriTracker/issues/900), on a live event *before* #901:
`user.id` a stable 36-char UUID, `user.geo` = `{country_code, city, region}`, `user.ip_address` null.

---

## 1. Do crash reports move from "linked to identity" to "not linked" on Apple?

### What Apple means by linked, precisely

Apple's [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) defines collection
first:

> "Collect" refers to transmitting data off the device in a way that allows you and/or your third-party
> partners to access it for a period longer than what is necessary to service the transmitted request in
> real time.

and then linkage:

> You'll need to identify whether each data type is linked to the user's identity (via their account,
> device, or other details) by you and/or your third-party partners. Data collected from an app is often
> linked to the user's identity, unless specific privacy protections are put in place **before collection**
> to de-identify or anonymize it, such as:
> - Stripping data of any direct identifiers, such as user ID or name, before collection.
> - Manipulating data to break the linkage and prevent re-linkage to real-world identities.
>
> Additionally, in order for data not to be linked to a particular user's identity, you must avoid certain
> activities after collection:
> - You must not attempt to link the data back to the user's identity.
> - You must not tie the data to other datasets that enable it to be linked to a particular user's identity.

So Apple's test has three limbs: (a) a de-identification step that happens **before the data leaves the
device**, (b) no attempt to re-link afterwards, (c) no tying to other datasets.

### Verdict — yes, subject to one measurement

`beforeSend` runs in the SDK on the device, before the envelope is transmitted. Under Apple's own
definition, transmission *is* collection, so `event.user = null` is literally the first bullet: stripping a
direct identifier (a user ID) before collection. This is not an analogy to Apple's example; it is Apple's
example.

Limb (b): the code comment records the cost deliberately — `user.id` is what powers Sentry's
*users affected* count, and losing it means an issue can no longer distinguish one installation
crash-looping from many. That is the concrete form of "not attempting to re-link": the capability is gone,
not merely unused. Limb (c): there is no other dataset — the app has one Sentry org and no identity store to
join against.

**Crash Data therefore moves to "Not Linked to You".** Coarse Location, *if* it has to stay (see question
2), would also be "not linked", for the same reason: with no identifier in the payload there is nothing for
a city to be linked to.

**This conclusion does not depend on the geo scrub.** A country/region/city is not a direct identifier and
does not by itself make a data type linked to identity; it is a separate data type with its own answers.
Question 1 and question 2 are independent.

### The one thing that must be measured before this is safe

Apple's answer is "not linked" only if **no other stable identifier survives** in the payload. Two facts
bear on this and they point in opposite directions:

- Sentry's device context spec
  ([develop.sentry.dev](https://develop.sentry.dev/sdk/data-model/event-payloads/contexts/)) lists
  `device_unique_identifier` and marks it: "This value might only be used if `sendDefaultPii` is enabled."
  `sendDefaultPii` is false and pinned by a test, so on the documentation this is not sent.
- But Sentry's own [Android](https://docs.sentry.io/platforms/android/data-management/data-collected/) and
  [Flutter](https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/)
  "Data Collected" pages already state that the SDK "doesn't send any information about the logged-in user"
  by default — and #889 measured a `user.id` UUID present anyway. **Sentry's documentation has already been
  wrong about exactly this question in exactly this project.** It is not a safe basis for a store
  declaration.

→ **Contingency A (not the geo one): a fresh event captured after #901 must be inspected and confirmed to
carry no stable per-install or per-device identifier anywhere** — not just an absent `user` block. Same
method that found the problem in the first place.

---

## 2. Does any location entry attributable to Sentry fall away?

### Both stores say IP-derived location is declarable

Google, [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469):

> As with other data types, you should disclose your collection, use and sharing of IP addresses based on
> their particular usage and practices. For example, where developers use IP addresses as a means to
> determine location, then that data type should be declared.

and the type itself:

> **Approximate location**: User or device physical location to an area greater than or equal to 3 square
> kilometers, such as the city a user is in.

Sentry's `user.geo` is `country_code`, `region`, `city` — Google's own example of the boundary.

Apple, [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/):

> You collect and store IP address from your users. Declare the relevant data types based on how you use IP
> address, such as precise location, coarse location, device ID, or diagnostics.

and, on derivation:

> If you derive anything from that data and send it off device, the resulting data should be considered
> separately.

Apple's **Coarse Location** is "Information that describes the location of a user or device with lower
resolution than a latitude and longitude with three or more decimal places" — a city qualifies.

### Verdict — it falls away *if and only if* the rule is verified, and even then not instantly

While `user.geo` is stored and visible in the org, **Play "Approximate location" and Apple "Coarse
Location" are both declarable, and both are attributable to Sentry alone** (no location permission in the
manifest; nothing else in the app touches location). Once the `$user.geo.**` Remove rule genuinely takes
effect, nothing location-shaped is retained and both entries can be removed.

**This is the conclusion that rests entirely on the unverified scrub.** Three specific failure modes, each
a reason verification is not a formality:

1. **`$user.geo.**` is not in Sentry's documented selector list.** The
   [Advanced Data Scrubbing](https://docs.sentry.io/security-legal-pii/scrubbing/advanced-datascrubbing/)
   docs enumerate the known-schema selectors — `$error`, `$stack`, `$frame`, `$http`, `$user`, `$message`,
   `$logentry`, `$thread`, `$breadcrumb`, `$span`, `$sdk` — and describe `$user` only as "Matches the user
   context of an event". No `geo` sub-path is documented. Nested paths do work in general (the docs'
   own examples include `$http.headers.x-custom-token` and `contexts.device.timezone`), and `$user.geo.**`
   is the form Sentry staff give in
   [getsentry/sentry#92201](https://github.com/getsentry/sentry/issues/92201) — but that is an issue
   thread, not documentation. A rule can be saved and simply match nothing.
2. **"Remove" is not specified to delete.** The docs state that the Remove method means Sentry "may choose
   to either set it to null, remove it entirely, or replace it with an empty string depending on technical
   constraints." Any of the three satisfies the declaration, but only inspection shows which happened —
   and shows that it happened at all.
3. **Timing.** Scrubbing runs server-side "just before it is saved in Sentry", and "Data scrubbing settings
   always apply to all new events within a project/organization (going forward)" — existing events are not
   retroactively scrubbed.

### The 30-day tail — a consequence nobody has named yet

Point 3 has a follow-on the synthesis ticket needs. `docs/privacy-policy/en.txt` states Sentry reports are
kept for 30 days. Events ingested **before** the rule was added still carry city and are still stored.
Google requires that "Your Data safety form responses must remain accurate and complete at all times."
Answering "we do not collect approximate location" while a month of city-bearing events sits in the org is
a prospective truth stated as a present one.

Two clean ways out, and the ticket should pick one rather than leave it: (a) leave the Approximate
Location / Coarse Location entries in place until the pre-rule retention window has expired, then remove
them; or (b) delete the affected issues — Sentry's own guidance for data already captured is that "the best
way to do that is by deleting the entire issue" — and remove the entries once the org is clean.

---

## 3. Does opt-in make the Play data type *optional*, or absent?

**Optional. Not absent.** These are different answers and Play asks for the first one explicitly.

Play's form question, verbatim: *"Is this data required for your app, or can users choose whether it's
collected?"* And the criterion:

> You can declare that your app collects certain data optionally only if all users – regardless of device
> or region – can either optionally provide information, opt-out, or opt-in to have the data collected.

The switch in `settings_screen.dart` is available to every user on every device in every region, defaults
off, and `Sentry.close()` fires on withdrawal. Every limb is met, including the "regardless of device or
region" one that usually breaks these claims.

**Why it is not absent.** Play's collection definition is "transmitting data from your app off a user's
device", and the only exemptions are on-device processing ("User data accessed by your app that is only
processed locally on the user's device and not sent off device does not need to be disclosed"),
end-to-end encryption, and ephemeral processing (in memory, "retained for no longer than necessary to
service the specific request in real-time"). Crash reports go off device and are retained 30 days. None of
the three applies. Consent is not an exemption — Play offers no "collected only with consent" answer, it
offers *optional*, and that is the box.

**Sharing: no.** Play's exception is verbatim — transferring data "to a 'service provider' that processes
it on behalf of the developer" is not sharing, a service provider being "an entity that processes user data
on behalf of the developer and based on the developer's instructions." Sentry is a processor under a DPA
(the policy already frames it that way, place of processing US under the DPF and SCCs).

→ **Play answers for Crash logs: Collected = yes. Shared = no. Ephemeral = no. Required or optional =
optional.** Not contingent on the geo scrub.

**Apple has no equivalent lever, and the asymmetry matters.** Apple's App Privacy has no
required/optional toggle. It has an *optional disclosure* exception, which requires **all** of four
criteria, including:

> Collection of the data occurs only in infrequent cases that are not part of your app's primary
> functionality, and which are optional for the user.
> The data is provided by the user in your app's interface, it is clear to the user what data is collected,
> the user's name or account name is prominently displayed in the submission form alongside the other data
> elements being submitted, and the user affirmatively chooses to provide the data for collection each time.

Crash reporting fails the fourth outright — the user does not affirmatively provide each crash report, and
no account name is displayed. Apple also states: "Data collected on an ongoing basis after an initial
permission request must be disclosed." So **on Apple, opt-in changes nothing: Crash Data is disclosed,
full stop.** The two stores are not answering the same question and should not be given the same answer.

---

## 4. With tracing off, is "Diagnostics" still right, and should Apple's "Performance Data" go?

### Play — the category is right; one of the three data types is genuinely in doubt

Play's category is **App info and performance**, and it holds three types
([declare-data-use](https://developer.android.com/privacy-and-security/declare-data-use)):

- **Crash logs** — "Crash log data from your app. For example, the number of times your app has crashed,
  stack traces, or other information directly related to a crash."
- **Diagnostics** — "Information about the performance of your app. For example battery life, loading time,
  latency, framerate, or any technical diagnostics."
- **Other app performance data** — "Any other app performance data not listed here."

**Crash logs: unambiguously yes.** Stack traces are the paradigm case.

**Diagnostics: undecided, and it is not the tracing change that decides it.** #917 removed loading time,
latency and framerate — those came from transactions. But Sentry's device context, attached to *every*
event including crashes, is specified to carry `battery_level`, `charging`, `low_memory`, `free_memory`,
`memory_size`, `free_storage`, `storage_size`, `boot_time` and more
([event-payload contexts](https://develop.sentry.dev/sdk/data-model/event-payloads/contexts/)); the Flutter
enricher adds orientation, screen dimensions and density
(`flutter_enricher_event_processor.dart:175–192`). "Battery life … or any technical diagnostics" reads
directly onto that. The counter-argument — that context riding on a crash is "other information directly
related to a crash", i.e. Crash logs — is available but is a judgement call, not a reading.

→ **Contingency B (again not the geo one): a measured crash event is needed to see which device-context
fields this app's builds actually populate.** #889 enumerated `user.*` and stopped there. If battery and
storage figures are present, declare Diagnostics; if the context is essentially model and OS version,
Crash logs alone will do. Do not decide this from the SDK spec — see the documentation-vs-measurement
record in question 1.

### Apple — the equivalent is the Diagnostics category, and "Performance Data" should **not** be removed yet

Apple's Diagnostics category holds:

- **Crash Data** — "Such as crash logs"
- **Performance Data** — "Such as launch time, hang rate, or energy use"
- **Other Diagnostic Data** — "Any other data collected for the purposes of measuring technical diagnostics
  related to the app"

**This is the finding the ticket's framing would have missed.** #917 kills *launch time* — app-start
transactions are gone with `isTracingEnabled()` false. It does **not** kill *hang rate*.
`enableAppHangTracking` is `true` by default and `configureSentryOptions` never touches it, so iOS app
hangs are still detected at a 2-second threshold and reported as error events; on Android the same is true
of `anrEnabled = true`. Apple's own example term for Performance Data is "hang rate". The SDK is, right
now, reporting exactly the thing Apple names.

→ **Performance Data must stay on Apple's answers as the code stands.** To remove it honestly, the app has
to set `enableAppHangTracking = false` (and, for the Play Diagnostics answer, `anrEnabled = false`) in
`sentry_config.dart`. That is a code change, and it belongs in its own ticket, not in the declaration one.
It is also worth weighing on the merits: the consent string says "Send crash reports to help fix bugs", and
an ANR or app hang is a defensible reading of that in a way an app-start transaction was not — the same
argument #917 made for switching tracing off cuts the other way here.

**Purposes.** Apple's App Functionality purpose is described as "Such as to authenticate the user, enable
features, prevent fraud, implement security measures, ensure server up-time, **minimize app crashes**,
improve scalability and performance, or perform customer support" — the fit is verbatim. App Functionality
is the right and probably the only purpose for all of the Diagnostics types here.

---

## 5. Apple's "used for tracking" answer

**No — for every crash-data type, and it was already no before #901.**

Apple's definition, from
[User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/):

> Tracking refers to the act of linking user or device data collected from your app with user or device data
> collected from other companies' apps, websites, or offline properties for targeted advertising or
> advertising measurement purposes. Tracking also refers to sharing user or device data with data brokers.

The [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) page words it the
same way: "linking data collected from your app about a particular end-user or device, such as a user ID,
device ID, or profile, with Third-Party Data for targeted advertising or advertising measurement purposes,
or sharing data collected from your app about a particular end-user or device with a data broker."

Both limbs fail here. There is no advertising anywhere in the app, no IDFA access, no ATT prompt, and
Sentry is an error-monitoring processor, not a data broker.

The example worth actually checking, rather than waving past, is Apple's fourth:

> Placing a third-party SDK in your app that combines user data from your app with user data from other
> developers' apps to target advertising or measure advertising efficiency, even if you don't use the SDK
> for these purposes. For example, using an analytics SDK that repurposes the data it collects from your
> app to enable targeted advertising in other developers' apps.

This is the trap for any third-party SDK, and it is why "we don't do advertising" is not on its own a
sufficient answer. It does not catch Sentry: Sentry's product is error monitoring per-organisation, and
nothing in its terms repurposes customer event data into an advertising graph. Worth a one-line note in the
declaration record so the next person does not have to re-reason it.

**The ticket's caution is correct and should be preserved in the record:** stripping `user.id` is *not*
what makes this answer "no". Tracking is about ad-linkage and data brokers, not about whether a user is
identifiable. Even with the per-install UUID still attached, the answer would have been "no". Anyone who
reads #901 as having *changed* the tracking answer has misread the definition, and the same misreading
would put "used for tracking" back to yes the next time an identifier appears for a good reason.

---

## Draft answer sheet

**Google Play — Data safety**

| Data type | Collected | Shared | Ephemeral | Required/optional | Purpose |
|---|---|---|---|---|---|
| App info and performance → Crash logs | Yes | No | No | **Optional** | App functionality |
| App info and performance → Diagnostics | **See Contingency B** | No | No | Optional | App functionality |
| Location → Approximate location | **Remove — see Contingency C** | No | No | Optional | App functionality |

**Apple — App Privacy** (no required/optional dimension exists)

| Data type | Disclosed | Linked to user | Used for tracking | Purpose |
|---|---|---|---|---|
| Diagnostics → Crash Data | Yes | **No** (was yes) | No | App Functionality |
| Diagnostics → Performance Data | **Yes — keep**, hangs/ANR are still on | No | No | App Functionality |
| Diagnostics → Other Diagnostic Data | See Contingency B | No | No | App Functionality |
| Location → Coarse Location | **Remove — see Contingency C** | No | No | App Functionality |

Apple's answers publish independently of a build: App Store Connect help states "Your updated responses
will be published on your app's product page after you click Publish" (only privacy-policy *URL* changes
wait for the next version). That answers one of map #935's "Not yet specified" items in passing — Apple's
side is not gated on the 2.1.0 submission the way Play's is.

---

## What is contingent on what

**Contingency C — the geo scrub, verified against a real event.** This is the ticket's stated caution, and
exactly one conclusion rests on it:

- **Removing Play "Approximate location" and Apple "Coarse Location".** Nothing else. If the rule turns out
  not to match, both entries stay, declared as optional (Play) / not-linked (Apple), and the code cannot
  fix it — `beforeSend` provably cannot reach a field Relay adds at ingest.
- Even on success, removal is not immediate: pre-rule events retain city for the 30-day window, so the
  removal is honest only after that tail expires or the affected issues are deleted.

**Contingency A — a post-#901 event confirming no surviving identifier.** Independent of the geo rule.
Question 1's "not linked" verdict rests on it. `device_unique_identifier` is documented as
`sendDefaultPii`-gated and so should be absent, but Sentry's documentation was already wrong about `user.id`
in this exact org, so the documentation is not evidence.

**Contingency B — a post-#917 event showing which device-context fields are populated.** Independent of
the geo rule. Decides Play "Diagnostics" and Apple "Other Diagnostic Data" only.

**Not contingent on anything unverified:**

- Question 3 — Play Crash logs is **collected and optional**, not absent, and not shared. Read straight off
  the code and Play's own criteria.
- Question 5 — Apple "used for tracking" is **no**, and was no before #901.
- Play **Crash logs** and Apple **Crash Data** stay declared. Only the *other* types in the category move.
- Apple **Performance Data stays** until `enableAppHangTracking` / `anrEnabled` are actually turned off.
  This is a code read (`sentry_flutter_options.dart:71, 286` against `sentry_config.dart`), not a
  measurement.

---

## Side finding for the map: the policy is now stale in the other direction

Map #935 says a form contradicting the privacy policy is a finding "in either direction". Here the
*policy* is the stale one. `docs/privacy-policy/en.txt` — snapshotted 2026-08-28 in `3d5a5861` (#933),
one day *after* #901 and #917 landed — still says:

> When it is on, a crash sends a technical report … together with a randomly generated identifier for your
> installation. … Sentry's servers may derive an approximate location (country, region and city) from the
> connection the report arrives on.

and lists "Personal Data processed: diagnostics; device information; device logs; **an installation
identifier; approximate location**; Usage Data."

Both clauses now describe behaviour `develop` has removed or is removing. **The forms must not be filled in
by copying the policy** — that would re-import a declaration of an identifier that no longer leaves the
device. The policy needs its own correction, which is a separate ticket on a different map, and the
sequencing question (whether the policy is corrected before or after the geo scrub is verified) is worth
raising there rather than silently resolving here.

---

## Sources

- [App Privacy Details — Apple Developer](https://developer.apple.com/app-store/app-privacy-details/)
- [User Privacy and Data Use — Apple Developer](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- [Manage app privacy — App Store Connect Help](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
- [Provide information for Google Play's Data safety section — Play Console Help](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Declare your app's data use — Android Developers](https://developer.android.com/privacy-and-security/declare-data-use)
- [Advanced Data Scrubbing — Sentry docs](https://docs.sentry.io/security-legal-pii/scrubbing/advanced-datascrubbing/)
- [Event payload contexts — develop.sentry.dev](https://develop.sentry.dev/sdk/data-model/event-payloads/contexts/)
- [Data Collected (Flutter) — Sentry docs](https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/)
- [Data Collected (Android) — Sentry docs](https://docs.sentry.io/platforms/android/data-management/data-collected/)
- [getsentry/sentry#92201 — geo extracted despite "store IP address" disabled](https://github.com/getsentry/sentry/issues/92201)
