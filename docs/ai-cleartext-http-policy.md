# What permitting cleartext HTTP would cost, and whether it can be scoped

Research notes gathered 2026-08-20 against primary sources only —
`developer.android.com`, `developer.apple.com`, and F-Droid's own documentation.
Apple's documentation pages are client-rendered and returned nothing but a
`<title>` to automated fetching, so every Apple quote below was taken from
Apple's own DocC JSON endpoints under `developer.apple.com/tutorials/data/…`,
which are the documents that back the rendered pages. Where a page would not
yield its content by either route it is named in
[Not verified](#not-verified) rather than replaced with a secondary source.
Nothing here rests on a tutorial, a forum thread or a Stack Overflow answer.

Written to answer one question for
[#734](https://github.com/simonoppowa/OpenNutriTracker/issues/734) on map
[#732](https://github.com/simonoppowa/OpenNutriTracker/issues/732): **what does
it cost this app to permit cleartext HTTP, and can that permission be scoped
narrowly instead of granted globally?** The motivating address is
`http://192.168.1.5:11434` — Ollama on a desktop, the overwhelmingly common
shape of a self-hosted LLM endpoint. This document states what each option
costs. It does not pick one.

## Bottom line up front

**Scoping is expressible on iOS and is not expressible on Android**, and that
asymmetry is the whole answer. Everything else is secondary.

1. **Android cannot express "any private address."** A `<domain-config>` matches
   a literal string, optionally with DNS-suffix matching via
   `includeSubdomains`. The documentation describes no wildcard, no CIDR, and no
   range. Worse, the matching that does exist is right-anchored (a suffix rule)
   while an address range is left-anchored (a network prefix), so even a
   generous reading of suffix matching over IP-shaped strings would point the
   wrong way. And the config is a compiled build-time resource, while the
   address is runtime user input — so the one form that *is* expressible, an
   exact literal host, is exactly the thing the app cannot know in advance.
2. **iOS can express it exactly.** `NSExceptionDomains` accepts IPv4 and IPv6
   literals *and* CIDR ranges as of iOS 17, in Apple's own words: *"You can also
   use a classless inter-domain routing (CIDR) range."* So
   `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` and friends are a literal,
   checkable expression of "private ranges only." Option B is achievable on
   iOS and only approximable on Android.
3. **On iOS the narrow option costs an App Store justification and the looser
   one does not.** Apple lists five exceptions that require justification at
   review; `NSExceptionAllowsInsecureHTTPLoads` — which the CIDR form needs — is
   one of them. `NSAllowsLocalNetworking` is **not** on that list. So the
   cheaper-at-review path is the *broader* one, which permits cleartext to any
   IP literal (public ones included), any unqualified name, and any `.local`
   name. Narrower scope, higher review cost. That inversion is the iOS decision.
4. **The cleartext gate may not be the gate that is actually stopping this
   app.** Both vendors document that their cleartext enforcement is
   layer-specific. Android: *"there's no expectation that the `Socket` API
   honors this flag."* Apple: *"ATS doesn't apply to calls your app makes to
   lower-level networking interfaces."* This app reaches the network through
   `package:http` → `dart:io` `HttpClient`, which is built on `SecureSocket` /
   raw sockets, not on `HttpsURLConnection` or `URLSession`. A string search of
   the Flutter engine binary pinned by [`.fvmrc`](../.fvmrc) finds no reference
   to `NetworkSecurityPolicy` or `isCleartextTrafficPermitted`, and no such
   check exists anywhere in the pinned Dart SDK, the `http` package, or the
   Flutter framework. **The premise that the platform refuses the request
   before the app sees it is plausible but unverified for this stack, and a
   ten-minute device test would settle it.** See [Section F](#f-does-any-of-this-reach-this-apps-http-client).
5. **The gate that certainly does bite is the local-network permission, and it
   is on both platforms.** It is unrelated to cleartext — it would apply to
   `https://192.168.1.5` too. iOS has had it since iOS 14 and an outgoing TCP
   connection to a LAN address triggers it. Android 17 introduces
   `ACCESS_LOCAL_NETWORK`, mandatory for apps targeting API 37, and Android
   documents it as enforced *"deep in the networking stack, and thus they apply
   to all networking APIs"* — the opposite of the best-effort language attached
   to cleartext. Whatever this decision picks, LAN access is a runtime
   permission prompt on both platforms within about two target-SDK cycles.
6. **F-Droid does not care.** Its ten anti-features are Ads, Disabled Algorithm,
   Known Vulnerability, Non-Free Addons, Non-Free Assets, Non-Free
   Dependencies, Non-Free Network Services, No Source Since, Tethered Network
   Services and Tracking. None concerns cleartext, transport encryption, or
   network configuration. The Inclusion Policy says nothing about it either.
   Permitting cleartext adds no anti-feature and no metadata obligation to
   [#575](https://github.com/simonoppowa/OpenNutriTracker/issues/575).
7. **Loopback is nearly free, and about to be free outright on Android.** From
   Android 17, if no configuration is defined for localhost an implicit one is
   included that *"allows cleartext traffic."* Below Android 17 a one-line
   `<domain>localhost</domain>` config covers it. On iOS, loopback is not a
   local network address under Apple's definition (a local network requires a
   *"broadcast-capable network interface"*), so the permission prompt should not
   apply — see the caveat in [Not verified](#not-verified).

Two operational findings that hold regardless of which option is chosen:

- **`android:usesCleartextTraffic` has a shelf life and is unnecessary here
  anyway.** Google's own words: *"This attribute is getting deprecated and will
  be ignored for apps targeting API levels 38 and above."* The app's `minSdk`
  is 24 (Flutter 3.44.6's `minSdkVersionInt`), and a network security config
  needs API 24, so the manifest flag buys nothing this app needs. Any
  implementation should be a network security config, not the attribute.
- **The README already carries a sentence this decision touches**, and so does
  [`ai-legal-constraints.md`](ai-legal-constraints.md), which asserts at the
  Data safety analysis that *"The 'Encryption in transit' declaration remains
  true — HTTPS to whatever endpoint."* Permitting cleartext makes that claim
  conditional on what the user typed. It is one sentence in two files, but it
  is a sentence that currently says something false-once-shipped.

## A. What the repo declares today

Confirmed by reading, not by assumption:

- [`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml)
  declares **neither** `android:usesCleartextTraffic` **nor**
  `android:networkSecurityConfig`. A repo-wide grep for either string across
  `android/` returns nothing. `android/app/src/main/res/xml/` contains only
  `data_extraction_rules.xml` — there is no `network_security_config.xml` to
  edit, so an implementation creates a file rather than changing one.
- [`android/app/build.gradle`](../android/app/build.gradle) sets
  `compileSdkVersion 36` and `targetSdkVersion 36`. `minSdkVersion` is
  `flutter.minSdkVersion`, which in the pinned Flutter 3.44.6 is **24**.
- [`ios/Runner/Info.plist`](../ios/Runner/Info.plist) contains **no**
  `NSAppTransportSecurity` dictionary, no `NSLocalNetworkUsageDescription`, and
  no `NSBonjourServices`. A grep for every ATS key across `ios/` returns
  nothing.
- [`ios/Podfile`](../ios/Podfile) pins `platform :ios, '15.5'`, and the Runner
  target's `IPHONEOS_DEPLOYMENT_TARGET` is `15.5`. **This matters**: iOS 15.5
  and 16 sit inside the version band where ATS permits IP-literal destinations
  by default, and iOS 17 is where that stops. The app therefore straddles the
  change.
- The AI clients
  ([`anthropic_meal_items_api.dart`](../lib/features/add_meal/data/anthropic_meal_items_api.dart),
  [`openai_meal_items_api.dart`](../lib/features/add_meal/data/openai_meal_items_api.dart),
  [`openrouter_meal_items_api.dart`](../lib/features/add_meal/data/openrouter_meal_items_api.dart))
  all import `package:http/http.dart`. [`pubspec.yaml`](../pubspec.yaml) pins
  `http: ^1.6.0`. There is no `cupertino_http`, no `cronet_http`, and no `dio`.
- [`README.md`](../README.md) publishes a **"What leaves your device"** table
  introduced as *"These destinations, nothing else"*, plus a per-destination
  retention analysis. That is a falsifiable claim, which is why permitting
  cleartext is a decision and not a config tweak.

## B. Android — what is blocked, and how narrowly it can be told not to be

### B1. The default, and the two switches

The default is documented on the Network security configuration page:

> Up to Android 8.1 (API level 27), cleartext support is enabled by default.
> Applications can opt out of cleartext traffic for additional security.
>
> Starting with Android 9 (API level 28), cleartext support is disabled by
> default. Applications that require cleartext traffic can opt in to cleartext
> traffic.

The Android 9 behaviour-changes page states the same thing in terms of the API
the platform stacks consult:

> If your app targets Android 9 or higher, the `isCleartextTrafficPermitted()`
> method returns `false` by default. If your app needs to enable cleartext for
> specific domains, you must explicitly set `cleartextTrafficPermitted` to
> `true` for those domains in your app's Network Security Configuration.

There are two switches, and only one of them has a future.

**`android:usesCleartextTraffic`** — a single global boolean on `<application>`:

> Indicates whether the app intends to use cleartext network traffic, such as
> cleartext HTTP. The default value for apps that target API level 27 or lower
> is `"true"`. Apps that target API level 28 or higher default to `"false"`.

with two notes that between them retire it for this app:

> This attribute is getting deprecated and will be ignored for apps targeting
> API levels 38 and above. Specify a Network Security Configuration to control
> cleartext traffic for API levels 24 and above. If your app targets API levels
> 23 and below, you must specify `android:usesCleartextTraffic` in addition to
> a Network Security Config.

> This flag is ignored on Android 7.0 (API level 24) and above if an Android
> Network Security Config is present.

Android 17's all-apps behaviour-changes page repeats the plan:

> In a future release, we plan to deprecate the `usesCleartextTraffic` element.
> Apps that need to make unencrypted (HTTP) connections should migrate to using
> a network security configuration file, which lets you specify which domains
> your app needs to make cleartext connections to.

This app's `minSdk` is 24, so the attribute is redundant today and ignored
tomorrow. Any Android implementation of any option below is a
`res/xml/network_security_config.xml` plus one manifest attribute.

**The network security config** is the other switch, and it is the one that can
in principle be scoped. `<base-config>` sets the app-wide default;
`<domain-config>` overrides it per destination. The documented default
`<base-config>` for API 28 and above is:

```xml
<base-config cleartextTrafficPermitted="false">
    <trust-anchors>
        <certificates src="system" />
    </trust-anchors>
</base-config>
```

and the documented shape of a per-destination permit, using the page's own
example domain, is:

```xml
<domain-config cleartextTrafficPermitted="true">
    <domain includeSubdomains="true">insecure.example.com</domain>
</domain-config>
```

### B2. What a `domain-config` can actually match — the crux

This is the question the map hangs on, and the documentation answers it
narrowly. The `<domain>` element is:

```xml
<domain includeSubdomains=["true" | "false"]>example.com</domain>
```

with exactly one attribute:

> `includeSubdomains`: If `"true"`, then this domain rule matches the domain and
> all subdomains, including subdomains of subdomains. Otherwise, the rule only
> applies to exact matches.

and one resolution rule between competing configs:

> Note that if multiple `domain-config` elements cover a destination, the
> configuration with the most specific (longest) matching domain rule is used.

That is the entire matching vocabulary. Reading the page for wildcards, CIDR
notation, address ranges, port numbers or negation returns nothing — none of
those words appear.

**IP literals are legal `<domain>` values.** The page does not say so in the
`<domain>` reference, but it says so unavoidably in the localhost section,
which defines a configuration as targeting localhost when its domain is
`localhost`, `ip6-localhost`, or:

> a numerical IP address and `InetAddress.isLoopback()` is `true` (for example,
> `127.0.0.1` or `[::1]`)

A rule that inspects whether the numerical IP address in a `<domain>` element is
a loopback address presupposes that a numerical IP address is a valid
`<domain>` element. So *one* address can be permitted. **A range cannot.**

Three reasons this is not a technicality:

1. **No range syntax exists.** There is no documented CIDR form, no wildcard,
   no prefix form. The only generalising operator is `includeSubdomains`.
2. **The one generalising operator points the wrong way.** `includeSubdomains`
   is a DNS-suffix rule: it extends a match leftward across label boundaries,
   matching `X.example.com` from `example.com`. An IPv4 range is a *prefix*:
   `192.168.0.0/16` constrains the leftmost 16 bits. Suffix matching over
   IP-shaped strings, if it happens at all, would generalise `1.5` to
   `192.168.1.5` — the host part, not the network part. Whether the matcher
   even applies suffix logic to IP-shaped strings is undocumented and is in
   [Not verified](#not-verified); either way it is the wrong axis.
3. **Enumeration is not a workaround.** The RFC1918 space is
   `10.0.0.0/8` + `172.16.0.0/12` + `192.168.0.0/16` ≈ 17.9 million addresses.
   That is not a resource file.

And even if a range were expressible, there is a second, independent blocker:
**the network security config is a compiled resource, read by the platform,
fixed at build time.** The address in question is typed by the user into a
settings field at runtime. The app cannot ship a `<domain>` element for a host
it will not learn about until after it is installed. The only literal hosts a
build can know are ones the project chooses — `localhost` being the realistic
member of that set.

**So option B is not expressible on Android.** What is available instead is an
approximation with the enforcement moved: `<base-config
cleartextTrafficPermitted="true">` — a global permit — combined with the app
itself refusing, in Dart, to build a request to any `http://` host that does not
parse as an RFC1918, loopback or link-local literal. That is a real restriction
and it is testable in the repo's own test suite. It is not a *platform*
restriction, and the difference is the whole residual exposure: nothing outside
the app checks, the check is defeated by any other code path in the app or in
any dependency that makes its own HTTP calls, and a reader auditing the APK
sees `cleartextTrafficPermitted="true"` with no indication of the narrowing.

### B3. The localhost special case

Loopback is treated differently, and increasingly so.

From Android 17 (API level 37), the Network security configuration page
documents an implicit configuration:

> From Android 17 (API level 37) and higher, if no configuration has been
> defined for localhost, an implicit configuration is included.

which, by default:

> - Allows cleartext traffic.
> - Doesn't enforce certificate transparency (CT).
> - Doesn't enforce certificate pinning.
> - Delegates to `<base-config>` for trust anchors.

The rationale the page gives is that enforcing these features for localhost
connections is generally unnecessary.

Below Android 17 there is no special case: a user running the server on the
phone itself hits the same API 28 default as anyone else, and needs an explicit
`<domain>localhost</domain>` (and, for the numeric form, `127.0.0.1` and
`[::1]` — Android's localhost definition covers numeric loopback literals, but
only inside an implicit-configuration rule that does not exist before API 37).

Whether the Android 17 implicit config keys off the *device* version or the
*target* SDK is ambiguous in the page's wording and is in
[Not verified](#not-verified). If it keys off the target SDK, this app gets it
when it targets 37 and not before.

## C. Android 17 adds a second gate, and scoping does not avoid it

This is the finding most likely to be missed, because it is filed under privacy
rather than security and it has nothing to do with cleartext.

Android 17 introduces `ACCESS_LOCAL_NETWORK`, a runtime permission:

> Android 17 introduces the `ACCESS_LOCAL_NETWORK` runtime permission to protect
> users from unauthorized local network access… Apps targeting Android 17 (API
> level 37) or higher now have two paths to maintain communication with LAN
> devices: Adopt system-mediated, privacy-preserving device pickers to skip the
> permission prompt, or explicitly request this new permission at runtime to
> maintain local network communication.

Enforcement is by target SDK:

> In Android 16, apps could opt in to local network permissions. Beginning with
> Android 17, enforcement is mandatory for apps that target Android 17 (API
> level 37) or higher.

with a grace period this app currently sits inside:

> Apps with INTERNET permission receive an implicit permission grant for
> `ACCESS_LOCAL_NETWORK`, allowing them to retain access. This is temporary and
> will be blocked by default once app bumps target SDK to 37.

> Don't request `ACCESS_LOCAL_NETWORK` at runtime prior to targeting SDK 37.

Three things make this consequential:

**It applies to every networking API, unlike cleartext.** Android's own
description is categorical where the cleartext language is hedged:

> These restrictions are implemented deep in the networking stack, and thus they
> apply to all networking APIs. This includes sockets created in the platform or
> managed code, networking libraries like Cronet and OkHttp, and any APIs
> implemented on top of those.

"Sockets created in the platform or managed code" reaches `dart:io`. So even if
the cleartext policy turns out not to touch this app's HTTP client
([Section F](#f-does-any-of-this-reach-this-apps-http-client)), this will.

**Android names the exact ranges Apple's CIDR list would name.** The Local
network definition page defines a local network as *"an IP network that
utilizes a broadcast-capable network interface, such as Wi-Fi or Ethernet, but
excludes cellular (WWAN) or VPN connections"*, and enumerates:

| Family | Ranges named |
| :-- | :-- |
| IPv4 | `169.254.0.0/16` (link-local), `100.64.0.0/10` (CGNAT), `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` |
| IPv6 | link-local, directly-connected routes, stub networks such as Thread, multiple-subnets |
| Special | multicast `224.0.0.0/4` and `ff00::/8`, IPv4 broadcast `255.255.255.255` |

Loopback appears nowhere on that list, which is consistent with the
broadcast-capable-interface definition excluding it, but the page does not say
so — see [Not verified](#not-verified).

**The timing is close.** Google Play's target API requirements page, read on
2026-08-20, requires new apps and updates to target **API 36 or higher as of
31 August 2026** (extensions available to 1 November 2026). The app is already
at 36. On the annual cadence that page describes, the API 37 requirement
follows in the 2027 cycle, at which point `ACCESS_LOCAL_NETWORK` becomes a
runtime prompt this feature must handle. Costed properly, the LAN feature
carries a permission-request flow on Android regardless of which cleartext
option is picked.

The user-facing surface: the permission sits in the `NEARBY_DEVICES` group, and
the documentation notes that *"If a user has already granted another permission
in this group (such as Bluetooth permissions), they won't be re-prompted for
local network access."* Denial is not an exception the app can catch cleanly —
TCP typically surfaces as a timeout.

## D. iOS — App Transport Security, and where scoping is genuinely expressible

### D1. What ATS blocks, and which of the app's traffic it covers

Apple's framing:

> On Apple platforms, a networking security feature called App Transport
> Security (ATS) improves privacy and data integrity for all apps and app
> extensions. It does this by requiring that network connections made by your
> app are secured by the Transport Layer Security (TLS) protocol using reliable
> certificates and ciphers. ATS blocks connections that don't meet minimum
> security requirements.

> ATS operates by default for apps linked against the iOS 9.0 or macOS 10.11
> SDKs or later.

and the scope sentence that matters most for a Flutter app:

> The system enforces ATS when you use the standard URL Loading System.

> ATS doesn't apply to calls your app makes to lower-level networking
> interfaces like the Network framework or CFNetwork. In these cases, you take
> responsibility for ensuring the security of the connection.

When it does apply, the failure is a console message rather than a nice error:

> App Transport Security has blocked a cleartext HTTP (http://) resource load
> since it is insecure. Temporary exceptions can be configured via your app's
> Info.plist file.

### D2. The global keys, and what each actually permits

`NSAppTransportSecurity` is a dictionary of optional keys, all defaulting to
values Apple describes as suitable for most apps. Three matter here.

**`NSAllowsArbitraryLoads`** (Boolean, default `NO`, iOS 9.0+) —

> Set this key's value to `YES` to disable App Transport Security (ATS)
> restrictions for all domains not specified in the `NSExceptionDomains`
> dictionary.

It is broader than "allow HTTP": it also drops the extended checks on HTTPS
connections, including the TLS 1.2 minimum and forward secrecy. Apple attaches
a justification requirement to it (see D3), and notes that from iOS 10 it is
**ignored** — treated as `NO` — if `NSAllowsArbitraryLoadsForMedia`,
`NSAllowsArbitraryLoadsInWebContent` or `NSAllowsLocalNetworking` is present.

**`NSAllowsLocalNetworking`** (Boolean, default `NO`, iOS 10.0+) — the key with
the confusing name, because it predates and is unrelated to the local-network
*permission* in [Section E](#e-ios-local-network-permission). Verbatim:

> The `NSAllowsLocalNetworking` key controls whether App Transport Security
> (ATS) allows your app to connect to unqualified domains, `.local` domains, and
> IP addresses using IPv4 or IPv6.

> In iOS 10 through iOS 16, iPadOS 13.1 through iPadOS 16, and macOS 10.12
> through macOS 13, ATS allows all three of these connections by default, so you
> no longer need an exception for any of them. However, if you need to maintain
> compatibility with older versions of the OS, set both of the
> `NSAllowsArbitraryLoads` and `NSAllowsLocalNetworking` keys to `YES`.

> In iOS 17, iPadOS 17, and macOS 14, ATS no longer allows connections to IP
> addresses by default. Add individual IP addresses and classless inter-domain
> routing (CIDR) ranges in the `NSExceptionDomains` dictionary.

> The local networking exception tells newer versions of the OS to ignore the
> arbitrary loads key, and enable access to unqualified domains, `.local`
> domains, and IP addresses that they would otherwise restrict.

Two consequences, and one unresolved tension.

- **On iOS 15.5 and 16 — inside this app's deployment band — ATS already
  permits `http://192.168.1.5:11434` with no plist entry at all**, because IP
  literals are one of the three destination classes ATS allows by default in
  that version range. The problem starts at iOS 17.
- **`NSAllowsLocalNetworking` is not RFC1918-scoped.** It covers *any* IP
  literal, public ones included, plus every unqualified name and every `.local`
  name. It is narrower than `NSAllowsArbitraryLoads` — it does not touch the
  HTTPS extended checks for named hosts — but it is not "private ranges only."
- **The tension:** the third paragraph says newer OS versions must add IPs and
  CIDR ranges to `NSExceptionDomains`; the fourth says the local networking
  exception itself enables IP addresses newer OS versions "would otherwise
  restrict." Apple does not reconcile these. Which one governs iOS 17+ decides
  whether `NSAllowsLocalNetworking` alone is sufficient there. It is in
  [Not verified](#not-verified) and it is the single most testable open
  question on the iOS side.

Apple also suggests declaring intent even where the default is permissive:

> While ATS doesn't block local loads by default in newer versions of the OS,
> consider setting `NSAllowsLocalNetworking` to `YES` as a declaration of
> intent, if appropriate, even if you don't support older OS versions.

### D3. `NSExceptionDomains` — the only place a range is expressible

The domain-keyed dictionary is where iOS diverges from Android decisively:

> The value for this key is a dictionary with keys that name specific domains,
> IP addresses, or IP address ranges for which you want to set exceptions.

with explicit rules, of which the second is the finding:

> **Use a DNS domain name, IP address, or range of IP addresses** — In iOS 17,
> iPadOS 17, and macOS 14, you can use an IPv4 address, for example
> `192.168.42.63`, or an IPv6 address, for example `2001:db8:12::34`. You can
> also use a classless inter-domain routing (CIDR) range, for example
> `2001:db8:12::/48`.

> **Don't include a port number** — Use `example.com`, not `example.com:443`.

> **Don't use wildcard domains** — Don't use `*.example.com`. Instead, use
> `example.com` and set `NSIncludesSubdomains` to `YES`.

and a note that matters for a settings field where the user might type either a
name or an address:

> If you exclude a DNS domain name and your app contacts a host by IP address,
> the ATS exclusion for the domain name doesn't apply to the connection even if
> a DNS query for the domain name would resolve to the IP address. If you
> exclude an IP address and your app contacts a host by DNS name that resolves
> to that IP address, the ATS exclusion for the IP address doesn't apply to the
> connection.

Read plainly: a CIDR exception for `192.168.0.0/16` covers
`http://192.168.1.5:11434` and does **not** cover `http://ollama.lan:11434`,
even if `ollama.lan` resolves into that range. A user who types a hostname
instead of an address falls outside the exception. Whatever B looks like on
iOS, it is an address-based permission, and a hostname-based local setup needs
either `NSAllowsLocalNetworking` (which covers unqualified names and `.local`)
or a separate named exception.

One more interaction, which reverses the usual precedence:

> If you specify an exception domain dictionary, ATS ignores any global
> configuration keys, like `NSAllowsArbitraryLoads`, for that domain. This is
> true even if you leave the domain-specific dictionary empty and rely entirely
> on its keys' default values.

So the CIDR entries cannot lean on a global key; each needs
`NSExceptionAllowsInsecureHTTPLoads` set on it:

> Set the value for this key to `YES` to allow insecure HTTP loads for the given
> domain, or to be able to loosen the server trust evaluation requirements for
> HTTPS connections to the domain.

### D4. What Apple documents about App Store review

Apple documents the review consequence explicitly, and the list is the finding:

> Adding certain ATS exceptions to your app's Information Property List file
> requires you to provide justification, and might trigger additional App Store
> review for your app. Exceptions that require justification are:
>
> - Arbitrary connection exceptions (`NSAllowsArbitraryLoads`)
> - Media streaming exceptions (`NSAllowsArbitraryLoadsForMedia`)
> - Web content loads (`NSAllowsArbitraryLoadsInWebContent`)
> - Per-domain nonsecure connections (`NSExceptionAllowsInsecureHTTPLoads`)
> - Per-domain minimum TLS version (`NSExceptionMinimumTLSVersion`)

`NSAllowsLocalNetworking` is absent from that list, and unlike
`NSAllowsArbitraryLoads` and `NSExceptionAllowsInsecureHTTPLoads` its
documentation page carries no "You must supply a justification" note.

Apple also lists example justifications, one of which describes this feature
almost exactly:

> - The app must connect to a server managed by another entity that doesn't
>   support secure connections.
> - The app must support connecting to devices that cannot be upgraded to use
>   secure connections, and that must be accessed using public host names.

The first fits a user-run Ollama server. Note the qualifier on the second —
*"public host names"* — which does not fit a LAN address. And the closing
instruction:

> When submitting your app to the App Store, provide sufficient information for
> the App Store to determine why your app cannot make secure connections by
> default.

> Always look for a way to avoid using exceptions as a first recourse. If you
> must use an exception, make it as limited in scope as possible.

**The inversion is worth stating once more.** The exception that most limits
scope — CIDR ranges confined to RFC1918 — is the one Apple requires a
justification for. The looser `NSAllowsLocalNetworking` is free at review.
Following Apple's "as limited in scope as possible" instruction costs a review
conversation; ignoring it does not.

## E. iOS local network permission

This is a separate mechanism from ATS, on a separate timeline, and it applies
whether or not the connection is encrypted.

**Availability** (from Apple's technote on local network privacy): iOS 14+,
iPadOS 14+, visionOS 1+, macOS 15+. Not supported on tvOS or watchOS.

**What counts as local:**

> A local network is an IP network associated with a broadcast-capable network
> interface. Such interfaces include Wi-Fi and Ethernet, but not cellular (WWAN)
> or VPN. A local network address is any address on a local network. Traffic to
> a local network address goes directly; it's not forwarded by a router.

> In addition, all multicast addresses (224.0.0.0/4, ff00::/8) and the IPv4
> broadcast address (255.255.255.255) are local network addresses.

**Does it apply to a plain HTTP client hitting a LAN IP, as opposed to Bonjour
discovery? Yes.** The technote's operations table lists *making an outgoing TCP
connection* as requiring local network access — alongside sending UDP unicast,
multicast and broadcast, and resolving a `.local` DNS name. Bonjour registration,
browsing and resolution require it too, but they are not the only trigger. A
`URLSession` (or any TCP client) opening a connection to `192.168.1.5:11434`
requires it. Notably:

- **The multicast entitlement is not needed.** `com.apple.developer.networking.multicast`
  is documented as required for sending or receiving UDP multicast/broadcast and
  for arbitrary Bonjour service types. A unicast TCP connection needs none of
  that.
- **`NSBonjourServices` is not needed** either, since the app registers and
  browses nothing.
- **`NSLocalNetworkUsageDescription` is needed.** Apple: *"Any app that uses the
  local network, directly or indirectly, should include this description. This
  includes apps that use Bonjour and services implemented with Bonjour, as well
  as direct unicast or multicast connections to local hosts."* Available iOS
  14.0+, macOS 11.0+.

**What the user sees.** The privilege has three states — undetermined, allowed,
denied. On the first local network operation the system presents an alert
carrying the `NSLocalNetworkUsageDescription` string, and records the choice.
Users change it later in *Settings > Privacy & Security > Local Network*. Two
behaviours worth designing around:

> If an iOS app is in the background and performs a local network operation
> while its Local Network privilege is undetermined, the system denies that
> operation without presenting the local network alert.

and the technote's exclusions — traffic via `WKWebView`, `SFSafariViewController`
and Safari does not require it, nor does traffic to a DNS server or proxy that
happens to sit on the local network.

**This is a user-visible sentence the project writes.** The
`NSLocalNetworkUsageDescription` string is displayed verbatim in a system alert.
It joins `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` in
[`Info.plist`](../ios/Runner/Info.plist), and it is read by more users than the
README is.

## F. Does any of this reach this app's HTTP client?

Both vendors document that their cleartext enforcement lives at a particular
layer, and both say so unprompted.

Android, in the `usesCleartextTraffic` reference:

> This flag is honored on a best-effort basis because it's impossible to prevent
> all cleartext traffic from Android applications given the level of access
> provided to them. For example, there's no expectation that the `Socket` API
> honors this flag, because it can't determine whether its traffic is in
> cleartext.

> However, most network traffic from applications is handled by higher-level
> network stacks and components, which can honor this flag by either reading it
> from `ApplicationInfo.flags` or
> `NetworkSecurityPolicy.isCleartextTrafficPermitted()`.

Apple, in *Preventing Insecure Network Connections*:

> ATS doesn't apply to calls your app makes to lower-level networking interfaces
> like the Network framework or CFNetwork.

Both mechanisms are opt-in from the client's side: the client must ask the
policy, or route through a stack that asks on its behalf.

**This app's client does not obviously ask.** The AI clients use
`package:http`, which on mobile resolves to `dart:io`'s `HttpClient`, which
opens `Socket`/`SecureSocket` connections directly. Three observations against
the pinned toolchain (Flutter 3.44.6 per [`.fvmrc`](../.fvmrc)):

- Searching the Dart SDK's `_http` and `io` libraries, the Flutter framework,
  and the `http` package for `cleartext`, `Insecure HTTP`, or
  `isInsecureConnectionAllowed` returns nothing.
- A `strings` scan of the Flutter Android engine binary finds no
  `NetworkSecurityPolicy`, no `isCleartextTrafficPermitted`, and no JNI class
  path for either. (Matches are Skia's `clearTextureSupport` and an unrelated
  media string.)
- The Flutter Android embedding jar contains no network-security classes.

**The honest conclusion is a question, not an answer.** These are observations
about the shipped toolchain, not platform documentation, and they were not
confirmed by running the app. If they hold, the premise in
[#734](https://github.com/simonoppowa/OpenNutriTracker/issues/734) — that
`http://192.168.1.5:11434` is *"refused by the platform before the app sees
it"* — is false for this stack on both platforms today, and options A/B/C are
about declared posture rather than about whether the request succeeds. That
would change what each option buys quite a lot: in particular **option A,
"require HTTPS", would have to be enforced by the app in Dart**, because
neither platform would be enforcing it on the app's behalf.

The test is small and decisive: build a debug APK and an iOS build with no
config changes, point the client at an `http://` LAN address, and see whether
the request completes. Do that before costing anything below. It is filed in
[Not verified](#not-verified) because it was not run here.

## G. F-Droid

F-Droid's own [Anti-Features](https://f-droid.org/en/docs/Anti-Features/) page
documents ten labels, and the complete list is the answer:

| Anti-feature | F-Droid's description |
| :-- | :-- |
| Ads | advertising |
| Disabled Algorithm | signed using an unsafe algorithm |
| Known Vulnerability | known security vulnerability |
| Non-Free Addons | promotes other non-libre apps or plugins |
| Non-Free Assets | non-libre media in things that are not code |
| Non-Free Dependencies | needs a non-libre app to work |
| Non-Free Network Services | promotes or depends entirely on a non-free network service |
| No Source Since | source code no longer available |
| Tethered Network Services | depends entirely on a service which is impossible (or not easy) to replace |
| Tracking | tracks and/or reports your activity to somewhere |

**None concerns cleartext, transport encryption, TLS, or network
configuration.** The two that sound closest are scoped elsewhere:
*Disabled Algorithm* is *"applied to apps that were signed using a signature
algorithm that is considered outdated or unsafe"* — app signing, not transport;
*Known Vulnerability* is *"applied to apps with a known security vulnerability,
found by one of the scanners in fdroidserver"* — scanner output over
dependencies, with nothing on the page extending it to application
configuration.

The [Inclusion Policy](https://f-droid.org/en/docs/Inclusion_Policy/) contains
nothing about network security, encryption, cleartext, HTTP versus HTTPS, or
user-configurable endpoints. Its relevant machinery is the disclosure rule —
apps that *"contain undisclosed anti-features will receive a rejection"* — which
bites only where an anti-feature applies, and none does here. And anti-features
are labels rather than bars: they *"serve as warning indicators about user
freedom, privacy or etc. without necessarily disqualifying applications from
inclusion."* Only `Tracking` hides an app by default in the client.

**So permitting cleartext costs
[#575](https://github.com/simonoppowa/OpenNutriTracker/issues/575) nothing** — no
anti-feature, no metadata field, no hidden listing. This is entirely separate
from the `NonFreeNet` question that
[`fdroid-submission-feasibility.md`](fdroid-submission-feasibility.md) and
[`ai-legal-constraints.md`](ai-legal-constraints.md) already work through, which
is about *which* services the app promotes and is unaffected either way.

One second-order note: `ACCESS_LOCAL_NETWORK` would appear in the app's
permission list, and F-Droid renders permissions on its app pages. That is a new
line on the listing whenever the app targets API 37 — but again, it follows from
LAN access, not from cleartext.

## H. Is it user-visible?

Yes, on five surfaces, three of which a stranger can check without trusting the
project.

1. **The repo.** GPL-3.0, public. A new
   `android/app/src/main/res/xml/network_security_config.xml` and a new
   `NSAppTransportSecurity` dictionary in
   [`Info.plist`](../ios/Runner/Info.plist) are both diffs anyone can read,
   which is the strongest form of the README's existing "you can check this"
   posture.
2. **The shipped artifacts.** The merged manifest ships inside the APK and the
   `Info.plist` ships inside the app bundle; both are readable from a downloaded
   build. The README already teaches APK verification with `apksigner`, so this
   audience exists.
3. **The iOS system alert.** If the app reaches a LAN address, iOS shows the
   local-network prompt carrying the project's own
   `NSLocalNetworkUsageDescription` sentence. That is the most-read sentence in
   this entire decision, and it is written by the project.
4. **The Android permission list**, once the app targets API 37 and declares
   `ACCESS_LOCAL_NETWORK` — visible in Play, in F-Droid, and in system settings
   under *Nearby devices*.
5. **Google Play's Data safety section.** Developers must declare whether user
   data collected by the app is encrypted in transit. Permitting cleartext makes
   that answer depend on an address the project does not control.
   [`ai-legal-constraints.md`](ai-legal-constraints.md) currently records
   *"The 'Encryption in transit' declaration remains true — HTTPS to whatever
   endpoint."* Whichever option is chosen, that line needs revisiting; under B
   or C it is no longer unconditionally true. The Data safety guidance lives on
   `support.google.com` rather than `developer.android.com`, and the exact
   question wording could not be extracted — see
   [Not verified](#not-verified).

Apple's privacy nutrition labels have no encryption-in-transit field, so there
is no App Store listing equivalent to (5).

**The README consequence.** The *"These destinations, nothing else"* table
cannot enumerate an address the app does not know — a problem
[#732](https://github.com/simonoppowa/OpenNutriTracker/issues/732) already
names for the provider itself. Cleartext adds a second, smaller sentence on top
of it: not only *where* the data goes but *how* it travels. Under B that
sentence is checkable and bounded ("plain HTTP, and only to addresses on your
own network"). Under C it is checkable and unbounded. Under A there is no
sentence to write, which is A's main non-obvious benefit.

## The three options

Costs below assume [Section F](#f-does-any-of-this-reach-this-apps-http-client)
resolves the ordinary way — that the platform gates do apply. If it resolves the
other way, every row marked *platform-enforced* becomes *app-enforced* and A in
particular gets more expensive rather than free.

| | **A. Require HTTPS** | **B. Private/loopback only** | **C. Permit broadly** |
| :-- | :-- | :-- | :-- |
| **Android config** | none | **not expressible.** Closest: `base-config cleartextTrafficPermitted="true"` + a Dart-side RFC1918/loopback host check | `base-config cleartextTrafficPermitted="true"` in a network security config (not the deprecated attribute) |
| **iOS config** | none | `NSExceptionDomains` with RFC1918/loopback/link-local CIDR entries, each `NSExceptionAllowsInsecureHTTPLoads=YES`; or the looser `NSAllowsLocalNetworking=YES` | `NSAllowsArbitraryLoads=YES` |
| **Scoping achievable?** | n/a | **iOS yes, Android no** | n/a |
| **App Store justification** | none | **yes** for the CIDR form; **none** for `NSAllowsLocalNetworking` | **yes** — and it also drops TLS-version and forward-secrecy checks on HTTPS |
| **F-Droid** | none | none | none |
| **Local-network permission** | still required if the endpoint is a LAN address | required | required |
| **README / Data safety** | no change; every existing claim stands | one bounded sentence; Data safety "encrypted in transit" becomes conditional | one unbounded sentence; same Data safety change |
| **Who enforces the narrowing** | platform | iOS: platform. Android: **the app's own Dart code, and nothing else** | nobody |
| **Residual exposure** | none new | Android: any code path in the app or any dependency can speak cleartext anywhere, and no auditor of the APK can see the intended limit | any cleartext to any host from any code path, plus weakened HTTPS on iOS |
| **What it costs users** | most self-hosted setups fail; the user must front Ollama with a reverse proxy holding a certificate the device trusts | works for the common `http://192.168.1.5:11434` case; **fails for a hostname** like `ollama.lan` under the iOS CIDR form; fails for a remote box the user rents | works everywhere the user points it |

Three asymmetries worth carrying into the decision:

- **B is not one option, it is two.** On iOS the CIDR form and the
  `NSAllowsLocalNetworking` form differ in scope *and* in review cost, in
  opposite directions. On Android there is only the approximation.
- **A is not free either.** [#732](https://github.com/simonoppowa/OpenNutriTracker/issues/732)
  scopes this feature at a user-run server; requiring HTTPS means requiring a
  reverse proxy and a trusted certificate in front of Ollama, which is a
  materially different feature from the one the map describes. It is the only
  option with nothing to write in the README, and the only one where the
  platform keeps enforcing the property the README claims.
- **C's real cost is not the config line, it is the loss of the check.** Under
  A and B a reader can verify the transport claim from the shipped artifact.
  Under C the artifact says only "anything, anywhere," and the claim moves back
  into prose the reader has to trust.

## Not verified

- **Whether Android's cleartext policy or Apple's ATS applies to this app's HTTP
  client at all.** The vendor sentences quoted in
  [Section F](#f-does-any-of-this-reach-this-apps-http-client) are documented;
  the conclusion drawn from them for `package:http` → `dart:io` is an inference
  from the pinned SDK's source and binaries, not from platform documentation and
  not from a device test. **This is the highest-value open item in the
  document** and it invalidates or confirms the framing of the whole question.
- **Whether `<domain includeSubdomains="true">` does anything at all when its
  value is IP-shaped.** Undocumented on the Network security configuration page.
  Section B2's argument does not depend on the answer — suffix matching is the
  wrong axis for a network prefix either way — but the behaviour itself is
  unestablished.
- **Whether `NSAllowsLocalNetworking=YES` alone restores IP-literal access on
  iOS 17+.** Apple's page says both that iOS 17 requires `NSExceptionDomains`
  entries for IP addresses *and* that the local networking exception enables
  "IP addresses that they would otherwise restrict." The two paragraphs are in
  tension and Apple does not reconcile them. Testable on a device in minutes;
  it decides whether the justification-free iOS path exists at all.
- **`NetworkSecurityPolicy` API reference.** Both the Java and Kotlin reference
  pages returned only navigation to automated fetching, so
  `isCleartextTrafficPermitted(String hostname)` was not read at its own page.
  Per-host evaluation is established indirectly, from the "most specific
  (longest) matching domain rule" sentence and from the method's own signature
  as cited on other pages.
- **`Manifest.permission#ACCESS_LOCAL_NETWORK`.** Same problem — the reference
  page would not render. The permission's protection level and the exact
  constant string were not read at the reference; the manifest form
  `android.permission.ACCESS_LOCAL_NETWORK` comes from the Local network
  permission guide.
- **The literal text of the Android local-network prompt**, and of the iOS local
  network alert beyond the fact that it carries
  `NSLocalNetworkUsageDescription`. Neither page reproduces the alert copy.
- **Whether the Android 17 implicit localhost configuration keys off the device
  version or the app's target SDK.** The page's phrasing — "From Android 17 (API
  level 37) and higher" — reads as a platform-version statement, but the
  surrounding section concerns target-SDK-gated behaviour and a second reading
  of the same page returned "apps targeting API 37 or higher." Not settled.
- **Whether loopback is exempt from the local-network permission** on either
  platform. Neither Apple's technote nor Android's local network definition
  mentions loopback at all. Exemption is inferred from both definitions
  requiring a broadcast-capable interface, which loopback is not. Inference,
  not documentation.
- **Google Play's Data safety question wording.** The Play Console Help page
  did not yield the form's verbatim text to automated fetching, and it lives on
  `support.google.com`, outside the source set this document was scoped to. The
  claim in Section H rests on the paraphrase there plus the existing analysis in
  [`ai-legal-constraints.md`](ai-legal-constraints.md).
- **Whether Google Play has any *policy* against cleartext**, as opposed to the
  advisory "Cleartext communications" risk page on `developer.android.com`.
  Nothing policy-shaped was found on `developer.android.com`; the Play Developer
  Program Policies were not read.
- **The App Store Review Guidelines' own text on ATS.** Only the developer
  documentation article was read. Apple's justification requirements are quoted
  from *Preventing Insecure Network Connections* and from the two key pages that
  carry the note; the Guidelines document itself was not consulted.
- **When Google Play will require API 37.** The target API requirements page as
  read on 2026-08-20 names API 36 with a 31 August 2026 date and an extension to
  1 November 2026. No API 37 date is published there yet; the 2027 estimate in
  Section C is extrapolation from the annual cadence, not a published deadline.
- **Whether F-Droid's `fdroidserver` scanners inspect the network security
  config.** Only the Anti-Features and Inclusion Policy pages were read; the
  scanner source was not.
- **macOS, tvOS, watchOS and visionOS.** Availability strings are reported where
  Apple gave them, but this app ships iOS and Android and no other platform was
  analysed.
- **Whether a server running on the phone itself is reachable in practice** —
  process lifetime, background execution and battery are separate questions this
  document does not touch. Only the transport policy for loopback was
  established.

## Sources

Android (all `developer.android.com`):
[Network security configuration](https://developer.android.com/privacy-and-security/security-config) —
defaults per API level, `base-config` / `domain-config` / `domain` element
reference, `includeSubdomains`, longest-match rule, the Android 17 implicit
localhost configuration ·
[`<application>` manifest element](https://developer.android.com/guide/topics/manifest/application-element) —
`usesCleartextTraffic` description, defaults, best-effort/`Socket` caveat, the
API 38 deprecation note, `networkSecurityConfig` attribute ·
[Behavior changes: Android 9 (API 28)](https://developer.android.com/about/versions/pie/android-9.0-changes-28) —
`isCleartextTrafficPermitted()` returning `false` by default ·
[Behavior changes: all apps (Android 17)](https://developer.android.com/about/versions/17/behavior-changes-all) —
the `usesCleartextTraffic` deprecation plan, cross-profile loopback ·
[Behavior changes: apps targeting Android 17](https://developer.android.com/about/versions/17/behavior-changes-17) —
`ACCESS_LOCAL_NETWORK` introduction and mandatory enforcement, certificate
transparency default ·
[Local network permission](https://developer.android.com/privacy-and-security/local-network-permission) —
manifest and runtime request, `NEARBY_DEVICES` group, "all networking APIs"
statement, the implicit grant for apps below target 37 ·
[Local network definition](https://developer.android.com/privacy-and-security/local-network-definition) —
the enumerated IPv4/IPv6 ranges and the broadcast-capable-interface definition ·
[Cleartext communications](https://developer.android.com/privacy-and-security/risks/cleartext-communications) —
Google's stated risk and its scoping note ·
[Target API level requirements for Google Play](https://developer.android.com/google/play/requirements/target-sdk) —
the API 36 deadline and extension window.

Apple (all `developer.apple.com`; read via the DocC JSON endpoints under
`/tutorials/data/` because the rendered pages returned no body to automated
fetching):
[Preventing Insecure Network Connections](https://developer.apple.com/documentation/security/preventing-insecure-network-connections) —
ATS requirements, the URL Loading System scope and the lower-level-interfaces
carve-out, the exception dictionary structure, the justification list and
example justifications ·
[NSAppTransportSecurity](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity) —
child keys, defaults, availability, the iOS 9 versus iOS 10+ versioning rule ·
[NSAllowsArbitraryLoads](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowsarbitraryloads) —
what it disables, the justification note, the iOS 10+ ignore rule ·
[NSAllowsLocalNetworking](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowslocalnetworking) —
what it covers, the iOS 9 / iOS 10–16 / iOS 17+ version bands, the
declaration-of-intent note ·
[NSExceptionDomains](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsexceptiondomains) —
domain string rules, IPv4/IPv6/CIDR support, no ports, no wildcards, the
DNS-name-versus-IP non-equivalence note, the global-key override rule ·
[NSExceptionAllowsInsecureHTTPLoads](https://developer.apple.com/documentation/bundleresources/information-property-list/nsexceptionallowsinsecurehttploads) —
what it permits and its justification requirement ·
[NSLocalNetworkUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nslocalnetworkusagedescription) —
when it is required, availability ·
[TN3179: Understanding local network privacy](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy) —
platform availability, the local network definition, the operations table
(outgoing TCP requires access), the multicast entitlement scope, background
denial, the Settings location.

F-Droid (all `f-droid.org`):
[Anti-Features](https://f-droid.org/en/docs/Anti-Features/) — the complete list
of ten and each description, `Disabled Algorithm` and `Known Vulnerability`
scope, `Tracking` as the only default-hidden flag ·
[Inclusion Policy](https://f-droid.org/en/docs/Inclusion_Policy/) — anti-features
as labels rather than bars, the undisclosed-anti-feature rejection rule, and the
absence of any network-security clause.

Google Play (outside the primary source set, used only where noted and flagged
in Not verified):
[Provide information for Google Play's Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469).

Repo files read to establish current state:
[`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml) ·
[`android/app/build.gradle`](../android/app/build.gradle) ·
[`ios/Runner/Info.plist`](../ios/Runner/Info.plist) ·
[`ios/Podfile`](../ios/Podfile) ·
[`pubspec.yaml`](../pubspec.yaml) ·
[`.fvmrc`](../.fvmrc) ·
[`README.md`](../README.md) ·
[`lib/features/add_meal/data/anthropic_meal_items_api.dart`](../lib/features/add_meal/data/anthropic_meal_items_api.dart)

Related notes in this repo:
[`ai-legal-constraints.md`](ai-legal-constraints.md) ·
[`fdroid-submission-feasibility.md`](fdroid-submission-feasibility.md) ·
[`ai-model-candidates.md`](ai-model-candidates.md)
