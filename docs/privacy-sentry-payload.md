# What does Sentry receive at 100% trace sampling?

Research for [#870](https://github.com/simonoppowa/OpenNutriTracker/issues/870), on
map [#867](https://github.com/simonoppowa/OpenNutriTracker/issues/867). Researched
2026-08-27 against Sentry's own documentation, the `sentry-dart` source at tag
`9.19.0` (the version this app pins), and this repo's `main`.

> [!WARNING]
> **Superseded in part.** This document concludes that server-side geolocation is gated on
> `ip_address` being present on the event. That is **wrong**, and it was disproved by
> [#889](https://github.com/simonoppowa/OpenNutriTracker/issues/889) by reading a live event in
> this project's Sentry organisation: `user.geo` was populated with `country_code`, `city` and
> `region` while `user.ip_address` was `null`. Relay resolves geo from the **connection** IP
> before the filtering step, so the city of every crash is stored on both platforms, and the
> organisation's *Prevent Storing of IP Addresses* setting does not cover it.
>
> #889 also found a **stable per-install UUID** in `user.id`, ungated by `sendDefaultPii`,
> which this document does not mention at all. See `docs/privacy-sentry-ios-ip.md`.
>
> Everything else here — the trace-sampling analysis, the print-breadcrumb finding that led to
> [#877](https://github.com/simonoppowa/OpenNutriTracker/issues/877), and the retention figures —
> stands. The error is preserved rather than edited away so the correction is visible.

**The short answer: transactions do add a category — timings, spans, measurements and
a `ui.load` app-start trace — but the payload that actually matters for the policy is
not the transaction. It is the breadcrumb trail, which rides on *both* error events
and transactions, and which in release builds contains every `debugPrint` line this
app emits — including two log lines that print the full Open Food Facts and USDA FDC
search URLs, user's search term and all.** `sendDefaultPii` is left at its default
`false`, which does keep the IP address off the event on Android; on Apple platforms
Sentry documents that it does not. Sentry is a US entity offering a Frankfurt region
chosen once at organisation creation and never changeable, so where this project's
events land is a fact about the account, not about the code.

---

## 0. What this app actually configures

`lib/main.dart` on `main` sets exactly two options:

```dart
await SentryFlutter.init(
  (options) {
    options.dsn = Env.sentryDns;
    options.tracesSampleRate = 1.0;
  },
  appRunner: () => runAppWithChangeNotifiers(...),
);
```

Everything else is SDK default. `pubspec.yaml` declares `sentry_flutter: ^9.19.0` and
`pubspec.lock` pins `9.19.0`, so every claim below is checked against that tag.

Three absences matter and are established by reading `main.dart`:

- **No `SentryNavigatorObserver`.** The `MaterialApp` built in
  `_buildMaterialApp` sets `routes`, `initialRoute`, `localizationsDelegates` and
  friends, but never `navigatorObservers`.
- **No `SentryWidget`.** `runAppWithChangeNotifiers` calls
  `runApp(MultiProvider(... child: OpenNutriTrackerApp(...)))` directly.
- **No `SentryHttpClient`.** `lib/core/utils/ont_http_client.dart` wraps a plain
  `http.BaseClient` to set a `User-Agent`, and the data sources construct it over a
  vanilla `http.Client`.

Sentry initialises only in release builds and only after consent
(`if (kReleaseMode && hasAcceptedAnonymousData)`).

`tracesSampleRate = 1.0` means every trace is kept:

> Setting a uniform sample rate for all transactions/service spans using the
> `tracesSampleRate` option in your SDK config to a number between `0` and `1`.

> For example, to send 20% of transactions/service spans, set `tracesSampleRate` to
> `0.2`

— https://docs.sentry.io/platforms/dart/guides/flutter/tracing/

## 1. What a transaction event contains that an error event does not

A transaction is a distinct event type with its own schema. Sentry's SDK
specification lists these as required:

> **type** — A Transaction has to have this value set to `transaction`.

> **start_timestamp** — A timestamp representing when the measuring started.

> **timestamp** — A timestamp representing when the measuring finished.

> **contexts.trace** — [containing] `trace_id`, `span_id`, `parent_span_id`, `op`,
> `description`, `status`

and these as recommended or optional:

> **spans** — A list of Spans.

Each span carries `start_timestamp`, `timestamp`, `description`, `op`, `span_id`,
`trace_id`, `parent_span_id`, `tags` and `data`.

> **measurements** — An object containing standard/custom measurements with keys
> signifying the name of the measurement

> **transaction_info.source** — [`custom`] User-defined name; [`url`] Raw URL,
> potentially containing identifiers; [`route`] Parametrized URL / route; [`view`]
> Name of the view handling the request

— https://develop.sentry.dev/sdk/data-model/event-payloads/transaction/

So the *additional* categories relative to an error event are: **wall-clock
timings**, a **span tree** with per-span operation names and free-text descriptions,
**numeric measurements**, and a **transaction name** whose `source` may legitimately
be a raw URL or a route.

**What a transaction does *not* add is device metadata or breadcrumbs — because error
events already carry those, and transactions carry them too.** This is worth stating
plainly because it is the opposite of the intuition in the ticket. In
`packages/dart/lib/src/scope.dart` at `9.19.0`, `applyToEvent` attaches breadcrumbs to
every event except user feedback:

```dart
if (event.type != 'feedback') {
  event.breadcrumbs = (event.breadcrumbs?.isNotEmpty ?? false)
      ? event.breadcrumbs
      : List.from(_breadcrumbs);
```

and `SentryClient.captureTransaction` runs the full event-processor chain
(`runEventProcessors(preparedTransaction, hint, _options.eventProcessors, _options)`),
which is the same chain that `LoadContextsIntegration` registers its device/OS/app
context merge into. A transaction therefore ships the same contexts and the same
breadcrumb buffer as a crash does.

## 2. What this app's transactions actually contain

Given the three absences in §0, most of Sentry's automatic instrumentation is inert
here. One is not.

**Routing instrumentation is off.** Sentry's Flutter integration list marks *Routing*
as opt-in, and the routing page requires the developer to wire the observer in:

> ```dart
> MaterialApp(
>   navigatorObservers: [
>     SentryNavigatorObserver(),
>   ],
>   ...
> )
> ```

— https://docs.sentry.io/platforms/dart/guides/flutter/integrations/routing-instrumentation/

`main.dart` does not do this, so no `ui.load` transaction is named after a screen and
no navigation breadcrumbs are produced by the Dart layer.

**User-interaction tracing is off in practice.** The options default to on —
`bool enableUserInteractionBreadcrumbs = true;` and
`bool enableUserInteractionTracing = true;` in
`packages/flutter/lib/src/sentry_flutter_options.dart` — but the documented
prerequisite is:

> Wrap your root widget with `SentryWidget`

— https://docs.sentry.io/platforms/dart/guides/flutter/integrations/user-interaction-instrumentation/

which this app does not do. The same page notes that even when it is on, breadcrumbs
exclude "widget labels and text to avoid capturing personally identifiable
information (PII)" unless `sendDefaultPii` is set.

**HTTP instrumentation is off.** The HTTP integration is a client you must
construct — the docs describe instantiating `SentryHttpClient()` directly or via
`runWithClient`
(https://docs.sentry.io/platforms/dart/guides/flutter/integrations/http-integration/),
and the integration index lists *Http* and *Dio* under opt-in
(https://docs.sentry.io/platforms/dart/guides/flutter/integrations/). This app's
`ONTHttpClient` wraps a plain `http.Client`, so no HTTP spans and no HTTP breadcrumbs
are created by the SDK.

**One transaction is emitted per launch anyway.** `NativeAppStartIntegration` is added
unconditionally on iOS, Android and macOS in `_createDefaultIntegrations`, and it
returns early only when tracing is disabled:

```dart
if (!options.isTracingEnabled()) {
  options.log(SentryLevel.info,
      'Skipping $integrationName integration because tracing is disabled.');
  return;
}
...
context = SentryTransactionContext(
  'root /',
  SentrySpanOperations.uiLoad,
  origin: SentryTraceOrigins.autoUiTimeToDisplay,
);
```

With `tracesSampleRate = 1.0` tracing *is* enabled, so the app produces an app-start
transaction named `root /` with operation `ui.load` on every cold start.
`native_app_start_handler.dart` then adds an app-start measurement and finished child
spans described by `appStartTypeDescription`, `pluginRegistrationDescription`,
`sentrySetupDescription` and `firstFrameRenderDescription`. `FramesTrackingIntegration`
is likewise added unconditionally on non-web platforms and contributes slow/frozen
frame measurements.

So: setting `tracesSampleRate = 1.0` in this app buys one launch-timing transaction
per session, plus whatever breadcrumbs and contexts the scope holds at that moment —
not a stream of screen-by-screen or request-by-request traces.

## 3. What `sendDefaultPii = false` suppresses, and the IP question

The option is not set in `main.dart`, so it is at its default:

> If this flag is enabled, certain personally identifiable information (PII) is added
> by active integrations. By default, no such data is sent.

— https://docs.sentry.io/platforms/dart/guides/flutter/configuration/options/ (default `false`)

Sentry's per-SDK data inventory splits it cleanly. Held back at `false`:

> **HTTP Headers** — By default, the Sentry SDK doesn't send any HTTP headers.

> **Information About Logged-in User** — By default, the Sentry SDK doesn't send any
> information about the logged-in user, such as email address, user ID, or username.

> **Users' IP Addresses** — By default, the Sentry SDK doesn't send the user's IP
> address.

> **Device Information** — By default the Sentry SDK does not send the name of the
> device.

> **File I/O** — By default the Sentry SDK does not send the name or path of files
> when instrumenting File I/O.

Sent regardless:

> **Request URL** — The full request URL of outgoing and incoming HTTP requests is
> always sent to Sentry.

> **Request Query String** — The full request query string of outgoing and incoming
> HTTP requests is always sent to Sentry.

> **Runtime Information** — By default, the SDK collects basic runtime information
> like the Dart version and platform.

> **User Interaction Data** — By default, the SDK collects basic UI interaction data
> while protecting sensitive information by excluding text content.

— https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/

Note that the two "always sent" URL entries are conditional on HTTP instrumentation
being active, which per §2 it is not in this app. They describe the SDK's behaviour
when the integration is used, not an unconditional upload.

### The `{{auto}}` mechanism

> The user's IP address. If the user is unauthenticated, Sentry uses the IP address as
> a unique identifier for the user.

> You can set `ip_address = "{{auto}}"` to allow Sentry to automatically determine the
> IP address from the connection.

and, decisively for the geolocation half of the question:

> [`geo`] An optional object describing the geographical location of the end user or
> device. […] this object is automatically inferred by Relay if `ip_address` is
> provided.

— https://develop.sentry.dev/sdk/data-model/event-payloads/user/

So server-side geolocation is gated on `ip_address` being present on the event —
including the `{{auto}}` placeholder, which is the instruction that makes Relay look at
the connection.

### Does this app send `{{auto}}`?

**On Android and Dart-side: no.** `packages/dart/lib/src/sentry_client.dart` at
`9.19.0`:

```dart
/// Default value for [SentryUser.ipAddress]. It gets set when an event does not have
/// a user and IP address. Only applies if [SentryOptions.sendDefaultPii] is set
/// to true.
const _defaultIpAddress = '{{auto}}';
```

```dart
final effectiveIpAddress =
    user?.ipAddress ?? (_options.sendDefaultPii ? _defaultIpAddress : null);
```

`_createUserOrSetDefaultIpAddress` is called on both `captureEvent` and
`captureTransaction`, and the SDK's own tests assert `expect(actualIp, isNull)` for the
`sendDefaultPii = false` case. With PII off, no `user.ip_address` is attached, so Relay
has nothing to infer `geo` from.

**On Apple platforms: yes, and Sentry says so explicitly.**

> Due to backward compatibility concerns, Sentry sets the IP address to `"{{auto}}"`
> out of the box for Apple. Therefore setting `sendDefaultPii` to `false` won't stop
> Sentry from collecting users' IP addresses via the client connection.

— https://docs.sentry.io/platforms/apple/guides/ios/enriching-events/identify-user/

This is not contradicted anywhere in the Flutter documentation, and the mechanism by
which it would reach a Flutter event exists: `LoadContextsIntegration` copies the
native user object onto the event when the Dart event has none
(`if (event.user == null && userMap != null && userMap.isNotEmpty)`). **What I could
not settle from documentation is whether `SentryFlutter`'s propagation of
`sendDefaultPii` to the Cocoa SDK changes that Apple default for Flutter apps
specifically.** The Flutter data-collected page states flatly that the IP address is
not sent by default and does not carve out Apple; the Apple page states the opposite
for its own SDK. Treat iOS as unresolved rather than assuming either way.

### The distinction the ticket asks about

**Sentry's ingest necessarily receives the client IP — it is the source address of the
HTTPS connection to `*.ingest.sentry.io`. What `sendDefaultPii = false` controls is
whether that address is *recorded on the event* and thus whether `geo` is derived from
it.** The documentation is explicit about the second half and silent about the first;
no Sentry page states that the ingest endpoint discards or never observes the
connection IP. There is no primary-source basis for claiming Sentry does not receive
the IP, only for claiming it is not attached to the event on Android.

## 4. What `sentry_flutter` 9.19.0 turns on without being asked

From `_createDefaultIntegrations` in `packages/flutter/lib/src/sentry_flutter.dart` at
tag `9.19.0`, the unconditional additions are `WidgetsFlutterBindingIntegration`,
`OnErrorIntegration`, `FlutterErrorIntegration`, `WidgetsBindingIntegration`, the
Flutter framework feature-flag integration, `SentryViewHierarchyIntegration`,
`DebugPrintIntegration`, and (off web) `ThreadInfoIntegration`; with a native binding
present it also adds `LoadReleaseIntegration`, the native SDK integration,
`createLoadDebugImagesIntegration`, `LoadContextsIntegration`,
`FramesTrackingIntegration`, `NativeAppStartIntegration` and `ReplayIntegration`.

Reading each for its gate:

| Default integration | Actually active here? |
|---|---|
| Device / OS / app contexts (`LoadContextsIntegration`) | **Yes**, on all events including transactions |
| App-start tracing (`NativeAppStartIntegration`) | **Yes** — tracing is enabled |
| Slow/frozen frames (`FramesTrackingIntegration`) | **Yes** |
| `debugPrint` → breadcrumbs (`DebugPrintIntegration`) | **Yes**, release builds only — see §5 |
| Native breadcrumbs (`enableAutoNativeBreadcrumbs = true`) | **Yes** |
| Screenshots (`ScreenshotIntegration`) | **No** — gated on `attachScreenshot`, default `false` |
| View hierarchy (`SentryViewHierarchyIntegration`) | **No** — gated on `attachViewHierarchy`, default `false` |
| Session replay (`ReplayIntegration`) | **No** — sample rates default to null/0 |
| Routing / navigation breadcrumbs | **No** — needs `SentryNavigatorObserver` |
| User-interaction tracing and breadcrumbs | **No** — needs `SentryWidget` |
| HTTP / Dio instrumentation | **No** — needs `SentryHttpClient` |

Sources for the gates: `attachScreenshot` "Takes a screenshot of the application when
an error happens and includes it as an attachment", default `false`;
`attachViewHierarchy` "Renders a JSON representation of the entire view hierarchy of
the application when an error happens and includes it as an attachment", default
`false`; `maxBreadcrumbs` "This variable controls the total amount of breadcrumbs that
should be captured", default `100`; `enableAutoNativeBreadcrumbs` "Set this boolean to
`false` to disable automatic breadcrumbs on the Native platforms", default `true`
(https://docs.sentry.io/platforms/dart/guides/flutter/configuration/options/). The
screenshot and view-hierarchy integrations are added to the list unconditionally but
return without registering an event processor unless their option is on —
`if (options.attachScreenshot) { … }` and
`if (!options.attachViewHierarchy || options.platform.isWeb) { return; }` in the
9.19.0 sources. Replay reads `options.replay.sessionSampleRate ?? 0` and
`sentry_replay_options.dart` declares `double? _sessionSampleRate;` with no default.

**Device and OS metadata is therefore attached to everything.** The context schema
that `LoadContextsIntegration` populates is large — device `family`, `model`,
`model_id`, `arch`, `manufacturer`, `brand`, `battery_level`, `orientation`,
`screen_resolution`, `screen_density`, `memory_size`, `free_memory`, `storage_size`,
`free_storage`, `boot_time`, `timezone`, `language`, `processor_count`, `simulator`,
`device_unique_identifier`; OS `name`, `version`, `build`, `kernel_version`, `rooted`,
`theme`; app `app_start_time`, `app_identifier`, `app_name`, `app_version`,
`app_build`, `app_memory`, `in_foreground`, `permissions`, `view_names`
(https://develop.sentry.dev/sdk/data-model/event-payloads/contexts/). **Which subset
each platform populates is not documented per-field**; the schema is the upper bound,
not a promise. Device *name* is confirmed excluded at `sendDefaultPii = false`.

The Android native breadcrumb integrations enabled by `enableAutoNativeBreadcrumbs`
are, per Sentry's Android documentation, Activity Lifecycle, App Lifecycle, System
Events, App Components and User Interaction — each nameable in the manifest to turn it
off (`io.sentry.breadcrumbs.activity-lifecycle`, `…app-lifecycle`,
`…system-events`, `…app-components`, `…user-interaction`)
(https://docs.sentry.io/platforms/android/enriching-events/breadcrumbs/).

## 5. How food-search terms reach Sentry anyway

This is the finding the ticket did not anticipate, and it does not depend on trace
sampling at all.

`DebugPrintIntegration` is added unconditionally and replaces Flutter's `debugPrint`:

```dart
/// Integration which intercepts Flutters [debugPrint] method.
/// If this integration is added, all calls to [debugPrint] a redirected to
/// add a [Breadcrumb]. [debugPrint] is not outputting to the console anymore!
```

It self-disables only in debug builds:

```dart
final isDebug = options.runtimeChecker.isDebugMode();
final enablePrintBreadcrumbs = options.enablePrintBreadcrumbs;
if (isDebug || !enablePrintBreadcrumbs) {
  return;
}
```

and the replacement is a straight breadcrumb:

```dart
_hub.addBreadcrumb(Breadcrumb.console(
  message: message,
  level: SentryLevel.debug,
));
```

`enablePrintBreadcrumbs` defaults to `true` in `packages/dart/lib/src/sentry_options.dart`:

> Enable this option if you want to record calls to `print()` as breadcrumbs. In a
> Flutter environment, this setting also toggles recording of `debugPrint` calls.
> `debugPrint` calls are only recorded in release builds, though.

Sentry only runs in this app in release builds, which is exactly the case in which the
integration is live.

`lib/core/utils/logger_config.dart` routes the entire application log into
`debugPrint` at every level:

```dart
Logger.root.level = Level.ALL;
Logger.root.onRecord.listen((record) {
  debugPrint(
    '${record.level.name}: ${record.loggerName}: ${record.message}',
  );
});
```

And three call sites log a search URL:

- `lib/features/add_meal/data/data_sources/fdc_data_source.dart:24` —
  `log.fine('Fetching FDC results from: $searchUrlString');`
- `lib/features/add_meal/data/data_sources/off_data_source.dart:94` —
  `log.fine('Fetching OFF results from: $searchUrl');`
- `lib/features/add_meal/data/data_sources/off_data_source.dart:115` —
  `log.fine('Fetching OFF result from: $searchUrl');`

Those URLs are built by `OFFConst.getOffWordSearchUrl(searchString, …)` and the FDC
equivalent, so the query string contains the user's typed food-search term. In a
release build with consent given, each becomes a console breadcrumb, and the most
recent 100 breadcrumbs ride along on the next event of any type — crash *or*
app-start transaction.

The Supabase path is better behaved by accident: `sp_food_data_source.dart` logs
`'Successful localized ($locale) response from Supabase'` and `'Successful response
from Supabase'` without the term. But its `catch` block, like the OFF and FDC ones,
calls `Sentry.captureException(exception, stackTrace: stacktrace)`, and `off_data_source`
additionally logs `'Search-a-licious failed ($error); …'` — whether a given exception's
`toString()` embeds the request URI depends on the exception type and is not something
documentation can settle. **I have not verified on-device what a real
`ClientException` or `PostgrestException` message contains here.**

Nothing in Sentry's documentation is wrong about this; it is a property of this
codebase meeting an SDK default.

## 6. Retention and data region

**Retention**, from Sentry's own table:

| Data type | Developer | Team | Business / Enterprise |
|---|---|---|---|
| Errors | 30 days | 90 days | 90 days |
| Spans / transactions | 30 days | 30 days | 30 days + 13 months sampled |
| Attachments | 30 days | 90 days | 90 days |
| Session replays | 30 days | 90 days | 90 days |
| Profiles | 30 days | 30 days | 30 days |

with the exception that Team or Business plans on transaction-based billing get 90-day
transaction retention and no sampled-span retention, and:

> Retention periods are set at the time data is ingested, based on the then-current
> plan. This means plan upgrades or downgrades affect retention for new data only;
> existing data retains its original retention period.

— https://docs.sentry.io/security-legal-pii/security/data-retention-periods/

**Which row applies to this project depends on its Sentry plan, which is not
determinable from the repository.**

**Region.** An EU region exists. Sentry offers storage in "United States of America
(US)", physically in Iowa, and "European Union (EU)", in Frankfurt, Germany. The
choice is made once:

> once selected, your data storage location can't be changed

and for an existing SaaS organisation "the only way to switch it is by creating a new
organization". Error events, transactions, spans, profiles, logs, metrics and session
replays live in the selected region; **user accounts, organization settings, access
tokens and audit logs are always stored in the US regardless** of the selection
(https://docs.sentry.io/organization/data-storage-location/).

**Which region this project's DSN points at cannot be determined from the repo.** The
DSN is an obfuscated build secret (`@EnviedField(varName: 'SENTRY_DNS', obfuscate: true)`
in `lib/core/utils/env.dart`, supplied from `secrets.SENTRY_DNS` in CI); every
committed value is the placeholder `https://stub@sentry.io/0`. The region is readable
from the real DSN's hostname, and that is a one-look check for whoever holds the
account.

**The entity and the transfer mechanism.** Sentry's DPA names the contracting party
"Functional Software, Inc. d/b/a Sentry" and states that Sentry "may store and process
Customer Data in the United States and any other country in which we or our
Subprocessors maintain data processing operations", relying on the Data Privacy
Framework and, "in the event that the Data Privacy Framework is invalidated, or the
Data Privacy Framework does not otherwise apply", on the Standard Contractual Clauses
(https://sentry.io/legal/dpa/). The privacy policy confirms the split hosting:

> our Site and Service are hosted in the United States and Germany

— https://sentry.io/privacy/

That page also draws the line that matters for reading it: "This Privacy Policy does
not apply to data submitted to the Service ("Service Data")" — event payloads are
governed by the Customer Agreement and DPA, not by the policy Sentry publishes for its
own website visitors.

---

## What this means for the policy

**The data categories Sentry actually receives from this app, given today's
configuration:**

1. Crash and error events with Dart stack traces (`captureException` sites across
   `add_meal`, `edit_meal`, `meal_detail`, `add_activity` and the quick-add sheets),
   plus native crashes via the platform SDKs.
2. One app-start performance transaction per launch — `root /`, operation `ui.load`,
   with timing spans and app-start and frame measurements.
3. Device, OS and app contexts on every event and every transaction — model, family,
   architecture, manufacturer, memory and storage figures, screen metrics, timezone,
   language, OS version and build, app version and build. Device *name* is excluded.
4. Up to 100 breadcrumbs on every event and every transaction, comprising native
   lifecycle and system-event breadcrumbs and — the material item — the app's entire
   `logging` output, which includes Open Food Facts and USDA FDC search URLs
   containing the user's search terms.
5. Release, environment, SDK version and integration list.
6. On Apple platforms, possibly the client IP via `{{auto}}` — unresolved, see §3.

Not received: screenshots, view hierarchy, session replay, HTTP headers, request
bodies, user identifiers, device name, file paths, route or screen names, tap targets.

**Is the "crash traces, app and OS version, device model" claim complete? No.** That
exact sentence does not appear on `main`; the nearest in-repo statements are
`README.md:55` — "Anonymous crash reporting is opt-in during onboarding, can be turned
off at any time" — and the settings string `dataCollectionLabel`: "Send anonymous
crash reports to help fix bugs. No food log, weight, or personal data is included."
Whichever wording the policy inherits, three things are missing from it:

- **Performance/transaction data is a separate category from crash reports** and is
  collected unconditionally at `tracesSampleRate = 1.0`. iOS already declares
  `NSPrivacyCollectedDataTypePerformanceData` alongside `…CrashData` in
  `ios/Runner/PrivacyInfo.xcprivacy`; the README and the consent string do not.
- **Breadcrumbs carrying food-search terms.** "No food log, weight, or personal data is
  included" is a claim about the payload that the debug-print breadcrumb path
  contradicts for search terms specifically. This is a code-level defect as much as a
  wording problem — a build ticket that stops logging URLs, or sets
  `enablePrintBreadcrumbs = false`, would make the existing sentence true again and is
  cheaper than describing the leak.
- **Device metadata is broader than "device model"** — memory, storage, screen, battery,
  timezone and language are in scope per the context schema.

**A third-country transfer must be disclosed.** Functional Software, Inc. is a US
entity; its DPA reserves processing in the US "and any other country in which we or
our Subprocessors maintain data processing operations", relying on the Data Privacy
Framework with SCCs as fallback; and even an EU-region organisation has its account
and organisation records stored in the US by design. Selecting the Frankfurt region
would narrow but not eliminate the transfer, and it cannot be selected retroactively
for an existing organisation.

**One open item blocks a complete disclosure and is a lookup, not research:** which
region and which plan tier this project's Sentry organisation uses. Region fixes the
processing location and the transfer wording; plan tier fixes whether errors are kept
30 or 90 days. Both are visible in the Sentry account and neither is inferable from
the code.

---

## Sources

- [Options — Sentry for Flutter](https://docs.sentry.io/platforms/dart/guides/flutter/configuration/options/)
- [Data Collected — Sentry for Flutter](https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/)
- [Integrations — Sentry for Flutter](https://docs.sentry.io/platforms/dart/guides/flutter/integrations/)
- [Routing Instrumentation — Sentry for Flutter](https://docs.sentry.io/platforms/dart/guides/flutter/integrations/routing-instrumentation/)
- [User Interaction Instrumentation — Sentry for Flutter](https://docs.sentry.io/platforms/dart/guides/flutter/integrations/user-interaction-instrumentation/)
- [HTTP Integration — Sentry for Flutter](https://docs.sentry.io/platforms/dart/guides/flutter/integrations/http-integration/)
- [Set Up Tracing — Sentry for Flutter](https://docs.sentry.io/platforms/dart/guides/flutter/tracing/)
- [Users — Sentry for Flutter](https://docs.sentry.io/platforms/dart/guides/flutter/enriching-events/identify-user/)
- [Users — Sentry for iOS](https://docs.sentry.io/platforms/apple/guides/ios/enriching-events/identify-user/)
- [Breadcrumbs — Sentry for Android](https://docs.sentry.io/platforms/android/enriching-events/breadcrumbs/)
- [Transaction Payload — Sentry Developer Documentation](https://develop.sentry.dev/sdk/data-model/event-payloads/transaction/)
- [User Interface — Sentry Developer Documentation](https://develop.sentry.dev/sdk/data-model/event-payloads/user/)
- [Contexts Interface — Sentry Developer Documentation](https://develop.sentry.dev/sdk/data-model/event-payloads/contexts/)
- [Data Retention Periods — Sentry](https://docs.sentry.io/security-legal-pii/security/data-retention-periods/)
- [Data Storage Location — Sentry](https://docs.sentry.io/organization/data-storage-location/)
- [Data Processing Addendum — Sentry](https://sentry.io/legal/dpa/)
- [Privacy Policy — Sentry](https://sentry.io/privacy/)
- `getsentry/sentry-dart` at tag `9.19.0`: `packages/flutter/lib/src/sentry_flutter.dart`,
  `packages/flutter/lib/src/sentry_flutter_options.dart`,
  `packages/flutter/lib/src/integrations/debug_print_integration.dart`,
  `packages/flutter/lib/src/integrations/screenshot_integration.dart`,
  `packages/flutter/lib/src/integrations/native_app_start_integration.dart`,
  `packages/flutter/lib/src/integrations/native_app_start_handler.dart`,
  `packages/flutter/lib/src/integrations/load_contexts_integration.dart`,
  `packages/flutter/lib/src/view_hierarchy/view_hierarchy_integration.dart`,
  `packages/dart/lib/src/sentry_client.dart`, `packages/dart/lib/src/scope.dart`,
  `packages/dart/lib/src/sentry_options.dart`
