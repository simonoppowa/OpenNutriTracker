# Does an iOS build send the user's IP to Sentry despite `sendDefaultPii`?

Research for [#889](https://github.com/simonoppowa/OpenNutriTracker/issues/889), on
map [#867](https://github.com/simonoppowa/OpenNutriTracker/issues/867). Researched
2026-08-27 against the pinned SDK sources on disk, the sentry-cocoa and Relay
sources at the versions this app actually meets, and Sentry's own SDK
documentation.

**The short answer: no. Neither iOS event path attaches the IP, and the Apple
documentation that raised the alarm is stale.** `sendDefaultPii` does propagate
across the method channel into sentry-cocoa; sentry-cocoa 8.58.1 turns it into an
explicit `sdk.settings.infer_ip: "never"` on natively-originated events; and
Dart-originated events escape the server-side legacy backfill for a different
reason — their `platform` is `"other"`, and Relay's legacy rule fires only for
`javascript`, `cocoa` and `objc`. Android was never at risk. **But two things the
ticket did not ask are true and matter more than the answer:** Relay derives
`user.geo` from the connection IP *even when `user.ip_address` is absent*, which
contradicts what #870 recorded; and the org-level "Prevent Storing of IP Addresses"
toggle does **not** stop that geo lookup. See §3 and §4.

Versions this rests on, both pinned in the repo:

- [`pubspec.lock:1262`](pubspec.lock:1262) — `sentry_flutter` `9.19.0`
- [`ios/Podfile.lock:86`](ios/Podfile.lock:86) — `Sentry/HybridSDK (8.58.1)`

and the app's own options, which set three things and never `sendDefaultPii`
([`lib/core/utils/sentry_config.dart:22`](lib/core/utils/sentry_config.dart:22)):

```dart
void configureSentryOptions(SentryOptions options, {required String dsn}) {
  options.dsn = dsn;
  options.tracesSampleRate = 1.0;
  options.enablePrintBreadcrumbs = false;
}
```

---

## 1. Does the Flutter SDK initialise the native Cocoa SDK, and does `sendDefaultPii` reach it?

**Yes to both.** The native SDK is initialised by default, and `sendDefaultPii` is
one of the keys carried across the method channel.

`autoInitializeNativeSdk` defaults to `true`, and the app never touches it:

> `bool autoInitializeNativeSdk = true;`
> — `~/.pub-cache/hosted/pub.dev/sentry_flutter-9.19.0/lib/src/sentry_flutter_options.dart:33`

`NativeSdkIntegration` is the only gate, and it is open:

> ```dart
> if (!options.autoInitializeNativeSdk) {
>   return;
> }
> try {
>   await _native.init(hub);
> ```
> — `~/.pub-cache/hosted/pub.dev/sentry_flutter-9.19.0/lib/src/integrations/native_sdk_integration.dart:24`

The options map sent over the channel to `initNativeSdk` includes the flag
verbatim:

> `'sendDefaultPii': options.sendDefaultPii,`
> — `~/.pub-cache/hosted/pub.dev/sentry_flutter-9.19.0/lib/src/native/sentry_native_channel.dart:60`

and the Swift side reads it straight onto the native options object:

> ```swift
> if let sendDefaultPii = data["sendDefaultPii"] as? Bool {
>     options.sendDefaultPii = sendDefaultPii
> }
> ```
> — `~/.pub-cache/hosted/pub.dev/sentry_flutter-9.19.0/ios/sentry_flutter/Sources/sentry_flutter/SentryFlutter.swift:46`

So the premise the ticket was worried about — that the Dart-side flag might not
reach the native layer — is false. It reaches it.

## 2. What does sentry-cocoa do with `ip_address`, and do the two event paths differ?

**sentry-cocoa 8.58.1 never sets `ip_address` at all. It sends a server-side
instruction instead, and `sendDefaultPii` gates it.** The two paths differ in
*mechanism* but arrive at the same result.

### 2a. The native path (a hard crash, an ANR, a watchdog termination)

`grep` for `{{auto}}` across `Sources/` in the sentry-cocoa 8.58.1 tarball returns
**nothing**. The IP is no longer expressed as a magic user value. It is expressed
as an SDK setting:

> ```swift
> @objc public init(options: Options?) {
>     autoInferIP = options?.sendDefaultPii ?? false
> }
> ...
> @objc public func serialize() -> NSDictionary {
>     [
>         "infer_ip": autoInferIP ? "auto" : "never"
>     ]
> }
> ```
> — `getsentry/sentry-cocoa@8.58.1`, `Sources/Swift/Protocol/SentrySDKSettings.swift:11-28`

That object is part of the SDK metadata block…

> `"settings": self.settings.serialize()`
> — `Sources/Swift/Helper/SentrySdkInfo.swift:154`

…which the client stamps onto every event it prepares:

> ```objc
> - (void)setSdk:(SentryEvent *)event
> {
>     if (event.sdk) {
>         return;
>     }
>     event.sdk = [[[SentrySdkInfo alloc] initWithOptions:self.options] serialize];
> ```
> — `Sources/Sentry/SentryClient.m:955-961`

With `sendDefaultPii = NO`, that serialises to `"sdk": { …, "settings": {
"infer_ip": "never" } }`.

The Flutter plugin's `beforeSend` hook runs afterwards and *merges into* that
dictionary — it appends `packages`, `integrations` and `features` and reassigns
`event.sdk = sdk` — so the `settings` key survives
(`sentry_flutter-9.19.0/ios/sentry_flutter/Sources/sentry_flutter/SentryFlutterPlugin.swift:323-347`).
The plugin also renames the SDK to `"sentry.cocoa.flutter"`
(`SentryFlutterPlugin.swift:23`), which changes the name but not the settings.

The change is dated. sentry-cocoa's changelog for **8.56.0** records:

> `- Ensure IP address is only inferred by Relay if sendDefaultPii is true (#5877)`
> — `getsentry/sentry-cocoa@8.58.1`, `CHANGELOG.md:127` (under the `## 8.56.0` heading at `:106`)

and the PR that landed it is titled
["feat: Replace `user.ipAddress = {{auto}}` with a new settings.infer_ip property in the sdk metadata"](https://github.com/getsentry/sentry-cocoa/pull/5877)
(merged 2025-08-15). The pin is 8.58.1, so this app has it.

**The doc comment inside sentry-cocoa itself still describes the old behaviour**,
which is presumably where the Apple docs got it:

> ```
> Due to backward compatibility concerns, Sentry sets
> sdk.settings.infer_ip  to @c auto out of the box for Cocoa. If you want to stop Sentry from
> using the connections IP address, you have to enable Prevent Storing of IP Addresses in your
> project settings in Sentry.
> ```
> — `Sources/Sentry/Public/SentryOptions.h:274-277`

That paragraph is contradicted by the code twelve directories away in the same
release. **Recorded here because it is the plausible-sounding wrong answer**, and
because Sentry's public Apple documentation still repeats it today:

> "Due to backward compatibility concerns, Sentry sets the IP address to `"{{auto}}"`
> out of the box for Apple. Therefore setting `send-default-pii` to `false` won't stop
> Sentry from collecting users' IP addresses via the client connection."
> — [`docs/platforms/apple/common/enriching-events/identify-user/index.mdx`](https://github.com/getsentry/sentry-docs/blob/master/docs/platforms/apple/common/enriching-events/identify-user/index.mdx),
> read 2026-08-27

The equivalent Flutter page carries no such warning.

### 2b. The Dart path (a caught or uncaught Dart exception, a transaction)

This path never touches `SentryClient.m`. The Dart SDK builds the whole envelope
and hands the *bytes* to the native layer, which parses and posts them without
running the client pipeline:

> ```swift
> guard let envelope = PrivateSentrySDKOnly.envelope(with: data) else { … }
> PrivateSentrySDKOnly.capture(envelope)
> ```
> — `sentry_flutter-9.19.0/ios/sentry_flutter/Sources/sentry_flutter/SentryFlutterPlugin.swift:448-453`

The plugin's own comment says as much: *"for now, in sentry-cocoa, beforeSend is
not called before captureEnvelope"* (`SentryFlutterPlugin.swift:319`). So on this
path the native SDK contributes the transport and nothing else — no `setSdk`, no
`infer_ip`, no `{{auto}}`.

What the Dart SDK puts in the payload is what #870 already established:

> `user?.ipAddress ?? (_options.sendDefaultPii ? _defaultIpAddress : null);`
> — `~/.pub-cache/hosted/pub.dev/sentry-9.19.0/lib/src/sentry_client.dart:348`

with `sendDefaultPii` false, so no `ip_address` key. Two further facts about this
payload turn out to be decisive in §3, and neither was established before:

- The Dart SDK's SDK-metadata serialiser emits **no `settings` key at all** —
  `name`, `version`, `packages`, `integrations`, `features`, and nothing else
  (`sentry-9.19.0/lib/src/protocol/sdk_version.dart:98-108`). So a Dart event
  carries no `infer_ip` instruction in either direction.
- The Dart event's `platform` is **`"other"`**:
  > `..platform = event.platform ?? sdkPlatform(_options.platform.isWeb);`
  > — `sentry-9.19.0/lib/src/sentry_client.dart:241`
  > `const String _ioSdkPlatform = 'other';`
  > — `sentry-9.19.0/lib/src/version.dart:30`

  `sentry_flutter` never overrides it — `grep` for an assignment to `event.platform`
  across `sentry_flutter-9.19.0/lib/` finds none. A natively-originated event, by
  contrast, is `"cocoa"`
  (`sentry-cocoa Sources/Sentry/include/SentryInternalDefines.h:5`, applied at
  `Sources/Sentry/SentryEvent.m:50`).

So the two paths look like this on the wire:

| | Dart exception / transaction | Native crash |
|---|---|---|
| Built by | sentry-dart 9.19.0 | sentry-cocoa 8.58.1 |
| Sent by | sentry-cocoa (envelope passthrough) | sentry-cocoa |
| `platform` | `other` | `cocoa` |
| `sdk.name` | `sentry.dart.flutter` | `sentry.cocoa.flutter` |
| `user.ip_address` | absent | absent |
| `sdk.settings.infer_ip` | **absent** | `never` |

The interesting row is the last one: the two paths hand Relay *different*
instructions, and only one of them is explicit.

## 3. What does Relay do when `ip_address` is absent entirely?

**This is the crux, and it very nearly went the other way.** Relay does not treat
an absent `ip_address` uniformly — its default is a legacy mode that backfills the
connection IP for three specific platforms.

Sentry's SDK spec documents the three settings:

> - `auto`: infer the IP address based on available request information. […]
> - `never`: Do not infer the IP address from the request. This is the default if an invalid value for `infer_ip` was sent.
> - `legacy`: Infer the IP address only if the value is `{{auto}}`. For Javascript and Cocoa it will also infer if `ip_address` is empty. **This is the default if no value was sent.**
>
> — [`develop-docs/sdk/foundations/envelopes/event-payloads/sdk.mdx`](https://github.com/getsentry/sentry-docs/blob/master/develop-docs/sdk/foundations/envelopes/event-payloads/sdk.mdx)

The implementation keys on the **event's `platform` field**, not on the SDK name:

> ```rust
> // Legacy behaviour:
> // * Backfill if there is a REMOTE_ADDR and the user.ip_address was not backfilled until now
> // * Empty means {{auto}} for some SDKs
> if infer_ip == AutoInferSetting::Legacy {
>     …
>             // In an ideal world all SDKs would set {{auto}} explicitly.
>             if let Some("javascript") | Some("cocoa") | Some("objc") = platform {
>                 user.ip_address = Annotated::new(client_ip.to_owned());
>             }
> ```
> — [`getsentry/relay@26.8.0`, `relay-event-normalization/src/event.rs:482-503`](https://github.com/getsentry/relay/blob/26.8.0/relay-event-normalization/src/event.rs)

and `never` short-circuits before any of that:

> ```rust
> // If infer_ip is set to Never then we just remove auto and don't continue
> if let AutoInferSetting::Never = infer_ip {
>     // No user means there is also no IP so we can stop here
>     let Some(user) = user.value_mut() else {
>         return;
>     };
>     // If there is no IP we can also stop
>     let Some(ip) = user.ip_address.value() else {
>         return;
>     };
> ```
> — same file, `:439-448` — the `Never` arm

Applying that to the two rows of the table:

- **Native crash** — `infer_ip: "never"` → the first `return` fires (the event has a
  `user` with an id but no ip). **No IP stored.**
- **Dart exception** — no `infer_ip` → defaults to `Legacy` → `platform` is
  `"other"`, which is not `javascript`/`cocoa`/`objc`. **No IP stored.**

**The margin here is thin and worth stating plainly.** The Dart path is protected
by the string `"other"` rather than by anything anyone chose for privacy reasons.
If a future `sentry_flutter` set `event.platform = "cocoa"` on Apple targets — a
perfectly reasonable thing to do for symbolication or issue grouping — the IP
would start being stored on that path, silently, with no option change on our
side. The native path is protected by an explicit instruction and is robust.

### The finding the ticket did not ask for: `user.geo` is inferred anyway

#870 recorded that "Relay only infers `geo` when `ip_address` is present". **On
Relay 26.8.0 that is not true.** The geo lookup falls back to the connection IP:

> ```rust
> pub fn normalize_user_geoinfo(
>     geoip_lookup: &GeoIpLookup,
>     user: &mut Annotated<User>,
>     ip_addr: Option<&IpAddr>,
> ) {
>     …
>     if let Some(ip_address) = user
>         .ip_address
>         .value()
>         .filter(|ip| !ip.is_auto())
>         .or(ip_addr)
> ```
> — [`relay-event-normalization/src/event.rs:511-526`](https://github.com/getsentry/relay/blob/26.8.0/relay-event-normalization/src/event.rs)

`.or(ip_addr)` is the fallback, and the caller passes the **unfiltered**
connection IP:

> ```rust
> let client_ip = config.client_ip.filter(|_| config.infer_ip_address);
> …
> normalize_ip_addresses(…, client_ip, event.client_sdk.value());
>
> if let Some(geoip_lookup) = config.geoip_lookup {
>     normalize_user_geoinfo(geoip_lookup, &mut event.user, config.client_ip);
> }
> ```
> — same file, `:282-298`

Note the asymmetry: `normalize_ip_addresses` gets the filtered `client_ip`,
`normalize_user_geoinfo` gets `config.client_ip`. So on **both** iOS paths — and on
Android, and on every event this app has ever sent — Relay may store
`user.geo` (country code, region, city) derived from the connection IP, while
storing no IP.

**One link in that chain is not established from source.** `geoip_lookup` is
`Option`, populated from a `processing.geoip_path` config value
(`getsentry/relay@26.8.0`, `relay-config/src/config.rs:1139`), and whether
Sentry's SaaS processing Relays supply that database is a deployment fact I cannot
read out of any repository. It is one lookup to settle — see §5.

## 4. Is there a server-side control, and would it settle this?

**There are three, they live in different places, and — this is the useful part —
none of them is needed for the IP, and none of them fixes the geo.**

**(a) "Prevent Storing of IP Addresses", organisation-wide.** It exists, at
`/settings/:orgId/security-and-privacy/`:

> ```ts
> 'organization-security-and-privacy.scrubIPAddresses': {
>   name: 'scrubIPAddresses',
>   formId: 'organization-security-and-privacy',
>   route: '/settings/:orgId/security-and-privacy/',
>   label: t('Prevent Storing of IP Addresses'),
>   hintText: t('Preventing IP addresses from being stored for new events on all projects'),
> },
> ```
> — [`getsentry/sentry`, `static/app/views/settings/fieldRegistry.generated.ts:675-683`](https://github.com/getsentry/sentry/blob/master/static/app/views/settings/fieldRegistry.generated.ts)

**(b) The same toggle per project**, at
`/settings/:orgId/projects/:projectId/security-and-privacy/`, same label, hint
*"Preventing IP addresses from being stored for new events"* (same file, `:425-431`).
The Apple docs point at this one; the org-level one is strictly broader.

Either flips two switches in Relay. It disables inference at the source:

> ```rust
> // if the setting is enabled we do not want to infer the ip address
> infer_ip_address: !project_info
>     .config
>     .datascrubbing_settings
>     .scrub_ip_addresses,
> ```
> — [`relay-server/src/processing/utils/event.rs:259-263`](https://github.com/getsentry/relay/blob/26.8.0/relay-server/src/processing/utils/event.rs)

and adds a scrubbing rule that removes the known IP-bearing fields outright:

> ```rust
> if datascrubbing_config.scrub_ip_addresses {
>     // legacy(?) scrubs all fields that are known to have IPs regardless of actual content
>     applications.insert(KNOWN_IP_FIELDS.clone(), vec!["@anything:remove".to_owned()]);
>     // checks actual contents of all fields and scrubs where there is an IP address
>     applied_rules.push("@ip:replace".to_owned());
> }
> ```
> — [`relay-pii/src/convert.rs:148-154`](https://github.com/getsentry/relay/blob/26.8.0/relay-pii/src/convert.rs), with

> `"($request.env.REMOTE_ADDR | $user.ip_address | $sdk.client_ip | $span.sentry_tags.'user.ip' | attributes.'client.address')"`
> — `relay-pii/src/convert.rs:24`

**(c) `beforeSend` and advanced data scrubbing.** `beforeSend` is a client-side
hook and is the wrong instrument here: on iOS it is *not invoked* for the Dart
path at all (`SentryFlutterPlugin.swift:319`, quoted in §2b), and the IP is not in
the payload it would see anyway — it is added downstream by Relay. Server-side
advanced scrubbing (`[Remove] [$user.ip_address] from [**]`) is the general form of
(a) and, per Sentry's docs, *"Adding such a rule ultimately overrules any other
logic."*

**Would a single org toggle settle the question regardless of platform? For the IP,
yes — and it is unnecessary today.** Turning on the org-level "Prevent Storing of IP
Addresses" makes the answer platform-independent and immune to the `platform ==
"other"` fragility identified in §3, at zero cost to a project that has no use for
IPs. That is the recommendation. But it is belt-and-braces, not a fix: the SDKs
already withhold the IP.

**For the geo, no — the toggle does not reach it.** As quoted in §3,
`normalize_user_geoinfo` is passed `config.client_ip` and not the
`infer_ip_address`-filtered value, and `user.geo` is not in `KNOWN_IP_FIELDS`. An
explicit advanced-scrubbing rule on `$user.geo` would be needed, and I have not
verified that `$user.geo` is a valid selector. Two further limits, both from the
hint text: the toggle applies to **new events** only, and nothing here is
retroactive over the 30-day window #878 established.

## 5. What is not settled, and how to settle it

Three things, in descending order of how much they matter.

**(i) Does Sentry SaaS actually populate `user.geo`?** Not answerable from source
(§3). **The measurement is a single lookup and needs no code:** open any existing
event in `opennutritracker.sentry.io` — the org already holds ~3K of them per
#878 — and read its JSON (the "JSON" link on the event page, or
`GET /api/0/projects/{org}/{project}/events/{event_id}/`). Look at `user`. If it
contains a `geo` object with `country_code`, geo is live and the policy must
account for coarse location. If `user` holds only `id`, it is not. This settles
§3's open link and simultaneously *confirms* the whole of this document against
production rather than against source, which is why it is first.

**(ii) A CI regression check for the payload.** The finding in §3 — that the Dart
path is protected only by `platform == "other"` — is exactly the kind of thing an
SDK upgrade changes silently, and this map has now watched prose drift from code
several times. #748's precedent applies: add a check to the `ios-integration-tests`
job in [`.github/workflows/default_workflow.yml:266`](.github/workflows/default_workflow.yml:266)
rather than waiting for a device.

Concretely, and not implemented here: add
`integration_test/sentry_payload_test.dart`, run by the existing
`flutter test integration_test/ -d "$DEVICE_UDID" --flavor full` step (which runs the
whole directory from one build, so no workflow edit is needed). In it, start an
`HttpServer.bind(InternetAddress.loopbackIPv4, 0)` inside the test process, call
`SentryFlutter.init` with the app's own `configureSentryOptions` but a DSN pointing
at that port, capture an exception, await the request, gunzip and split the
envelope on newlines, and assert on the event item:

- `json['platform'] == 'other'`
- `json['user']?['ip_address'] == null`
- `json['sdk']?['settings'] == null` (this is the assertion that would catch a
  future SDK starting to send `infer_ip: "auto"`)

Note what this does and does not prove. It pins the **payload the SDK emits**,
which is the half that can regress on a version bump. It cannot exercise Relay, and
it cannot exercise the native crash path — a real `SIGSEGV` would tear down the
test host, and the crash is only converted and sent on the *next* launch, which a
single `flutter test` run cannot observe. The native path's `infer_ip: "never"` is
established from source in §2a and is the more robust of the two anyway; it is the
Dart path that is worth guarding.

**(iii) The stale Apple documentation.** Worth reporting upstream to
`getsentry/sentry-docs` and to the `SentryOptions.h` comment, since it is the
reason this ticket existed. Not a blocker for anything here.

## 6. Does Android differ?

**No, and it was never at risk — for a third, independent reason.**

`sendDefaultPii` propagates on Android too, through a JNI call rather than a method
channel:

> `androidOptions.setSendDefaultPii(options.sendDefaultPii);`
> — `~/.pub-cache/hosted/pub.dev/sentry_flutter-9.19.0/lib/src/native/java/sentry_native_java_init.dart:241`

The pinned native SDK is `io.sentry:sentry-android:8.39.1`
(`sentry_flutter-9.19.0/android/build.gradle:65`), which still uses the older
`{{auto}}` mechanism and gates it on the flag:

> ```java
> if (user.getIpAddress() == null && options.isSendDefaultPii()) {
>   user.setIpAddress(IpAddressUtils.DEFAULT_IP_ADDRESS);
> }
> ```
> — [`getsentry/sentry-java@8.39.1`, `sentry/src/main/java/io/sentry/MainEventProcessor.java:210`](https://github.com/getsentry/sentry-java/blob/8.39.1/sentry/src/main/java/io/sentry/MainEventProcessor.java)

`grep` for `infer_ip` across `getsentry/sentry-java` returns nothing, so Android
events carry no `sdk.settings` either and also land in Relay's `Legacy` default.
But the Android platform string is `"java"`:

> `public static final String DEFAULT_PLATFORM = "java";`
> — [`sentry-java@8.39.1`, `sentry/src/main/java/io/sentry/SentryBaseEvent.java:25`](https://github.com/getsentry/sentry-java/blob/8.39.1/sentry/src/main/java/io/sentry/SentryBaseEvent.java)

which is not in Relay's `javascript`/`cocoa`/`objc` list. So Android is protected
twice over — the SDK withholds `{{auto}}`, and the legacy backfill would not fire
even if it did not. The layering worry that motivated this ticket has no Android
analogue.

## 7. Incidental, and it is not the IP

**Both platforms attach a stable per-installation UUID as `user.id`, and neither
gates it on `sendDefaultPii`.** On iOS:

> ```objc
> // We only want to set the id if the customer didn't set a user so we at least set something to
> // identify the user.
> if (event.user == nil) {
>     SentryUser *user = [[SentryUser alloc] init];
>     user.userId = [SentryInstallation idWithCacheDirectoryPath:self.options.cacheDirectoryPath];
> ```
> — `sentry-cocoa@8.58.1`, `Sources/Sentry/SentryClient.m:979-986`

On Android, `user.setId(Installation.id(context))` sits immediately *above* the
`isSendDefaultPii()` check quoted in §6 and outside it
(`sentry-java@8.39.1`, `DefaultAndroidEventProcessor.java:176-181`). And the value
reaches Dart-originated events too, because `LoadContextsIntegration` copies the
native user onto the event when the event has none
(`sentry_flutter-9.19.0/lib/src/integrations/load_contexts_integration.dart:205-208`).

So every event this app sends, on both platforms, carries a random identifier that
is stable for the life of the install. That is a weaker identifier than an IP — no
location, no network, no cross-app linkage — and it is what makes "how many users
hit this crash" work at all. It is flagged rather than resolved: it is an
identifier the current policy does not mention, and it belongs to whichever ticket
owns the Sentry payload description, not to this one.

---

## What this means for the policy

**The IP is not a category the policy must declare, on iOS or Android.** The
worry in #889 was specific and checkable, and it does not survive contact with the
pinned versions: `sendDefaultPii` propagates to sentry-cocoa (§1), sentry-cocoa
8.58.1 turns it into `infer_ip: "never"` (§2a), and the Dart path escapes Relay's
legacy backfill on its `platform` string (§3). #870's conclusion — that
`sendDefaultPii = false` genuinely withholds the IP — **holds on iOS**, though not
quite for the reason #870 gave, since the reasoning it applied was Dart-side and
the native path needed a different argument.

**Android does not differ**, and is protected by two independent mechanisms rather
than one (§6). There is no iOS/Android asymmetry to write into the documents.

**A server-side setting removes the question, and it should be turned on anyway.**
The org-level "Prevent Storing of IP Addresses" at
`/settings/opennutritracker/security-and-privacy/` (§4a) makes the answer
platform-independent and version-independent. It costs nothing — this project has
no use for an IP — and it retires the one fragility this research found: the Dart
path is currently protected by `platform == "other"`, a value chosen for unrelated
reasons that an SDK upgrade could change without a changelog entry anyone here
would read. **That is the most useful outcome available and it is a one-click
change**, so it is recommended plainly rather than left as an option.

**One thing got worse, and it is not the IP.** #870 recorded that Relay infers geo
only when `ip_address` is present. On Relay 26.8.0 the geo lookup falls back to the
connection IP regardless (§3), and the "Prevent Storing of IP Addresses" toggle
does **not** cover it. If SaaS ships a GeoIP database — the one link not settled
from source — then every event already carries an approximate country, and *that*
is a category the policy would have to declare, on both platforms, with the same
US-region third-country transfer #878 established. **This should be settled before
the Sentry passage is written**, and it is one lookup in an event the org already
holds (§5i). Writing the policy on the assumption that no location is stored would
repeat exactly the kind of drift this map keeps finding.

---

## Sources

- Pinned locally: `~/.pub-cache/hosted/pub.dev/sentry_flutter-9.19.0/`, `~/.pub-cache/hosted/pub.dev/sentry-9.19.0/`
- [getsentry/sentry-cocoa @ 8.58.1](https://github.com/getsentry/sentry-cocoa/tree/8.58.1) — the version in `ios/Podfile.lock`
- [getsentry/sentry-java @ 8.39.1](https://github.com/getsentry/sentry-java/tree/8.39.1) — the version in `sentry_flutter`'s `android/build.gradle`
- [getsentry/relay @ 26.8.0](https://github.com/getsentry/relay/tree/26.8.0) — latest release at time of writing
- [getsentry/sentry `fieldRegistry.generated.ts`](https://github.com/getsentry/sentry/blob/master/static/app/views/settings/fieldRegistry.generated.ts)
- [SDK Interface — Sentry developer documentation](https://develop.sentry.dev/sdk/foundations/envelopes/event-payloads/sdk/)
- [Users — Sentry Apple documentation](https://docs.sentry.io/platforms/apple/enriching-events/identify-user/)
- [Users — Sentry Flutter documentation](https://docs.sentry.io/platforms/dart/guides/flutter/enriching-events/identify-user/)
- [sentry-cocoa PR #5877](https://github.com/getsentry/sentry-cocoa/pull/5877)
