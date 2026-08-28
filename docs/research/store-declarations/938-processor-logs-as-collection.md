# Is what a processor logs on our behalf "collection"? — Play and Apple

Research resolving [#938](https://github.com/simonoppowa/OpenNutriTracker/issues/938),
under map [#935](https://github.com/simonoppowa/OpenNutriTracker/issues/935).
Read **2026-08-28**. First-party store documentation only for the store rules;
Supabase and Sentry docs are cited only for facts about their own products.

---

## Bottom line up front

**Both stores say declare it. Neither store's definition contains the exemption
the current position relies on, and the factual premise the position rests on is
wrong.**

1. **Play: Approximate location must be declared.** Play's data-type table has a
   note written for exactly this case — *"Approximate location that is inferred,
   such as via IP address or Access Point Name, must be disclosed here"* — and
   `developer.android.com` lists *"Derives location information from an IP address
   or access point name"* as an example of an app accessing Location data, in a
   list that does **not** require a location permission. [Q1, Q5]
2. **Play: 24 hours does not rescue it.** "Ephemeral" means *"only stored in
   memory and retained for no longer than necessary to service the specific
   request in real-time."* A 24-hour queryable log store fails both halves. Play's
   own FAQ addresses this exact shape — data used transiently *"before that data is
   logged on our servers"* — and says the logged use must be declared. [Q2]
3. **Play grants no "we never read it" exemption to a processor.** Play's only two
   collection exemptions are on-device processing and end-to-end encryption. The
   two FAQ carve-outs that *do* turn partly on non-access (payment services, user
   cloud backups) each additionally require the other party to collect **directly
   from the user under its own terms** — i.e. precisely *not* as the developer's
   service provider. Supabase is a service provider, so the carve-out is
   unavailable by its own wording. [Q1]
4. **Apple: Coarse Location must be declared.** Apple's "collect" test is
   retention-and-access, not receipt: *"transmitting data off the device in a way
   that allows you and/or your third-party partners to access it for a period
   longer than what is necessary to service the transmitted request in real time."*
   Apple's worked example says data sent to your servers is exempt only if
   *"immediately discarded after servicing the request"*. Apple's IP guidance says
   to declare the derived type — *"such as precise location, coarse location,
   device ID, or diagnostics"*. [Q3, Q5]
5. **The premise "the developer cannot read it back" is false.** Supabase's Logs
   Explorer surfaces edge logs, including `metadata.request.cf.city`,
   `.cf.country`, `.cf.region` and `.cf.asn`, to project members in the dashboard.
   The developer does not read them; the developer *can*. Apple's test is
   explicitly about what the transmission *allows*, so this alone decides Apple. [Q3]
6. **Sentry reaches the same result a fortiori for Crash logs / Diagnostics, but
   *not* for approximate location** — because Advanced Data Scrubbing runs *"just
   before it is saved in Sentry"*, so `$user.geo.**` is genuinely never stored.
   That is a different mechanism from the Supabase case and produces the opposite
   answer. [Q4]
7. **Honest caveat:** neither store wrote its definition with "our processor
   derives it, we never look" in mind. Play's collection definition is about
   transmission *from the app*, and approximate location is not transmitted from
   the app — it is manufactured at the far end. There is a coherent
   non-declaration argument. It is not the safest defensible position, and section
   "The strongest argument for *not* declaring" says why it loses.

---

## The facts this rests on

| | |
|---|---|
| Backend | Supabase, operated by the developer, reached with `supabase_flutter: ^2.16.0` (`pubspec.yaml:81`) |
| What the gateway records | Source IP; country/region/city/postal code derived from it; ISP by name; TLS fingerprint |
| Retention | 24 hours |
| App-side transmission | The request only. Since [#911](https://github.com/simonoppowa/OpenNutriTracker/pull/911) the search term is an RPC body, not a URL parameter |
| Developer reads it? | No — but see below |
| Disclosed in policy? | Yes, both languages (`docs/privacy-policy-gaps.md:149`) |
| Crash reporting | `sentry_flutter: ^9.26.0`, consent-gated toggle; `event.user` nulled client-side (`lib/core/utils/sentry_config.dart:56-78`) |

**Two facts worth correcting before the form is filled in.**

*The logs are visible to the developer.* Supabase's logging guide describes edge
logs as API request/response records passing through Cloudflare with *"attached
Cloudflare metadata"*, carrying `metadata.request.cf.city`, `.cf.country`,
`.cf.region`, `.cf.asn` (the ISP) and TLS fields including
`.cf.botManagement.ja3Hash` — and states that *"The Supabase Platform includes a
Logs Explorer that allows log tracing and debugging"*, available to project
members in the dashboard.
<https://supabase.com/docs/guides/telemetry/logs>

So "we never read it back" is a description of developer conduct, and "we cannot"
is inaccurate. No store definition turns on conduct; Apple's turns on capability.

*The 24 hours is a billing artefact, not a design guarantee.* Supabase's pricing
page lists log retention of **1 day (Free), 7 days (Pro), 28 days (Team)**.
<https://supabase.com/pricing> — the number in the privacy policy silently becomes
7 days on the day the project upgrades. Nothing in the repository would notice.

---

## Q1 — Does Play count what a service provider logs as collection *by the developer*?

**Yes.** Play's framework treats a service provider as an extension of the first
party, not as a separate collector, so processor-side handling collapses into the
developer's own collection column.

Play defines the term only inside the *sharing* carve-outs:

> **Service providers.** Transferring user data to a "service provider" that
> processes it on behalf of the developer. **"Service provider"** means an entity
> that processes user data on behalf of the developer and based on the developer's
> instructions.

and, in the first/third-party definitions:

> **"Third party"** means any organization other than the first party or its
> service providers.

> **"First party"** means the primary organization responsible for processing data
> collected by the app, which is typically the organization publishing the app on
> Google Play and appearing on the store listing.

<https://support.google.com/googleplay/android-developer/answer/10787469>

**This is the load-bearing structural point.** Play's form asks two separate
questions per data type — *collected*, *shared*, or both (form fields
`PSL_DATA_USAGE_ONLY_COLLECTED` / `PSL_DATA_USAGE_ONLY_SHARED`, same page). The
service-provider concept is an exemption from **sharing only**. Nowhere does Play
say processor-held data is not *collected*. A reading where a service provider's
logging is neither collection nor sharing would put the data outside the form
entirely, which is not a state Play's taxonomy has: a service provider is defined
as *not a third party*, so what it holds is held on the first party's side of the
line. The developer is the first party. Google's own FAQ confirms a hosting
provider is the paradigm case:

> A service provider may only process user data on your behalf. For example, an
> analytics provider that processes user data from your app solely on your behalf,
> **or a cloud provider hosting user data from your app for your use**, will
> typically qualify as "service providers."

Same page.

**Play addresses the derived-location case by name.** Two independent first-party
statements:

> **Approximate location** — User or device physical location to an area greater
> than or equal to 3 square kilometers, such as the city a user is in, or location
> provided by Android's `ACCESS_COARSE_LOCATION` permission.
> **Note:** Approximate location that is **inferred, such as via IP address** or
> Access Point Name, **must be disclosed here.**

<https://support.google.com/googleplay/android-developer/answer/10787469>

Note the passive voice: *inferred*, not "inferred by you". The clause exists
because inference happens somewhere other than the app.

And on `developer.android.com`, under the heading "Location", introduced by
*"There are different ways that your app, or a library included in your app, may
access user data related to [category]. The following list provides several
examples but isn't exhaustive:"* —

> - Declares at least one of the following permissions: `ACCESS_COARSE_LOCATION`,
>   `ACCESS_FINE_LOCATION`, `ACCESS_MEDIA_LOCATION`
> - **Derives location information from an IP address or access point name.**

<https://developer.android.com/privacy-and-security/declare-data-use>

The second bullet is disjunctive with the permission bullet. An app with no
location permission at all — this app — still lands in the Location category if
location is derived from its traffic. That page also states: *"You alone are
responsible for making complete and accurate declarations in your app's Play store
listing. Only you possess all the information required to complete the Data safety
form."*

And the IP FAQ:

> **How should I treat the collection and use of IP addresses?** As with other data
> types, you should disclose your collection, use and sharing of IP addresses based
> on their particular usage and practices. For example, where developers use IP
> addresses as a means to determine location, then that data type should be
> declared.

<https://support.google.com/googleplay/android-developer/answer/10787469>

**Why "we never access it" does not help under Play.** Play's exhaustive list of
what is *not* collection is two items:

> **On-device access/processing:** User data accessed by your app that is only
> processed locally on the user's device and not sent off device does not need to be
> disclosed.
>
> **End-to-end encryption:** User data that is sent off device, but that is
> unreadable by you or anyone other than the sender and recipient as a result of
> end-to-end encryption does not need to be disclosed. **The encrypted data must not
> be readable by any intermediary entity, including the developer**, and only sender
> and recipient may have necessary keys.

Same page. Neither applies: the data leaves the device, and it is plainly readable
by Supabase and Cloudflare. Note the E2EE carve-out is the one place Play makes
developer non-readability count — and it requires *nobody* in the middle can read
it. That is the opposite of a gateway log.

The two FAQ carve-outs that come closest are decisive against the position, because
of their *second* prong:

> If your app uses a payment service such as PayPal, Google Pay […] you don't need to
> declare collection of the data that the payment service collects […] if the
> following conditions are met: **Your app never accesses this information; and** the
> payment service **collects this information directly from the user, and collection
> is governed by that service's terms.**

> If the user chooses to upload their data directly to **their own** external drive
> or cloud storage account […] and this upload is **governed by the external drive or
> cloud storage provider's terms of service and privacy policy**, and your app never
> collects or accesses the data in question, then your app does not need to declare
> the collection of this data.

Same page. Google is willing to excuse non-accessed data — but only when the other
party collects **on its own account, under its own terms**, for its own or the
user's purposes. That is the definition of *not* being a service provider. Here
Supabase processes on the developer's instructions and the collection is governed
by **the developer's** published privacy policy, which describes the gateway log as
part of the app's own data handling. The developer has claimed the relationship
that closes this exit.

Finally, the umbrella obligation, from the Play User Data policy: developers must
disclose *"how your app accesses, collects, uses, and shares user data, not limited
by the data disclosed in the Data safety section"*, and *"you must ensure that the
third party code used in your app, and that third party's practices with respect to
user data from your app, are compliant with Google Play Developer Program
policies."*
<https://support.google.com/googleplay/android-developer/answer/10144311>

---

## Q2 — Does 24-hour retention change the answer? (ephemeral processing)

**No.** The 24-hour figure is what *disqualifies* it.

> **Ephemeral processing:** User data transmitted off device that is processed
> ephemerally needs to be included in your form response, but if it meets the
> standard below, it will **not** be disclosed in your app's Data safety section on
> Google Play.
>
> Processing data "ephemerally" means accessing and using it while the data is
> **only stored in memory** and **retained for no longer than necessary to service
> the specific request in real-time.**
>
> For example, a weather app that transmits user location off the device to fetch the
> current weather at the user's location but only uses location data in memory and
> does not store that data once the request has been fulfilled, can treat its
> transient use of location as ephemeral.

<https://support.google.com/googleplay/android-developer/answer/10787469>

Two conjunctive conditions; the gateway log fails both. It is written to a queryable
log store, not held in memory, and it survives 86,400× longer than the request it
describes. The retention exists to be searched *after* the fact — that is what a log
is for.

Google addresses this precise architecture in an FAQ that could have been written
about a CDN in front of an API:

> **How do I declare collection of data that is used in a transient way to load pages
> and service other client-side requests in real time before that data is logged on
> our servers and used for other purposes?**
> If this use is ephemeral, you do not need to include it in your form response.
> However, **you must declare any use of that user data beyond the ephemeral
> processing, including any purposes for which you use the user data that you log.**

Same page. The real-time servicing is ephemeral; **the log is not**, and the log is
what the question is about.

Note also: ephemeral is not an escape from the form, it is an escape from the public
listing. Play Console has an explicit field — *"Is this data processed ephemerally?"*
(`PSL_DATA_USAGE_EPHEMERAL`, same page) — which only exists once the data type has
been declared.

**One documentation inconsistency, recorded because it will come up.** The body text
says ephemeral data *"needs to be included in your form response"*; the FAQ above
says *"you do not need to include it in your form response."* Google contradicts
itself on the same page. It does not matter here — the gateway log is not ephemeral
under either reading — but do not build an argument on the FAQ's phrasing.

---

## Q3 — Apple: does "collect" capture data the recipient derives and we never receive?

**Yes.** Apple's definition is not about receipt. It is about **retention** and
**access capability**, and it names both the developer's own servers and third-party
partners.

> "Collect" refers to **transmitting data off the device in a way that allows you
> and/or your third-party partners to access it for a period longer than what is
> necessary to service the transmitted request in real time.**

> "Third-party partners" refers to analytics tools, advertising networks, third-party
> SDKs, or other external vendors whose code you've added to your app.

> You need to identify all of the data **you or your third-party partners** collect,
> unless the data meets all of the criteria for optional disclosure listed below.

<https://developer.apple.com/app-store/app-privacy-details/>

Applied here, four separate routes all reach "collected":

**a) The retention test, stated as a worked example.** Apple's "Additional guidance"
section:

> **You collect data to service a request but do not retain it after servicing the
> request.**
> "Collect" refers to transmitting data off the device and **storing it in a readable
> form for longer than the time it takes** you and/or your third-party partners to
> service the request. For example, if an authentication token or **IP address is sent
> on a server call and not retained**, or if data is sent to **your servers** then
> **immediately discarded** after servicing the request, you do not need to disclose
> this in your answers in App Store Connect.

Same page. Apple frames the exemption in terms of *your servers* and conditions it on
*immediate discard*. Twenty-four hours of readable, queryable retention is the
negation of the stated condition. This is the closest either store comes to a direct
ruling on this exact question, and it rules against non-declaration.

**b) The IP guidance says to declare the derived type, not the raw field.**

> **You collect and store IP address from your users.**
> Declare the relevant data types based on how you use IP address, such as precise
> location, **coarse location**, device ID, or diagnostics.

Same page. Apple has no "IP address" data type; it expects the developer to declare
what the IP *becomes*. Here it becomes country/region/city/postal code — Apple's
**Coarse Location**: *"Information that describes the location of a user or device
with lower resolution than a latitude and longitude with three or more decimal
places."*

**c) "Allows … to access" is a capability test, and the capability exists.** Even
setting aside Supabase's own access, the Logs Explorer makes those fields readable by
the developer for the full retention window
(<https://supabase.com/docs/guides/telemetry/logs>). The transmission *allows* the
developer to access the data for longer than real time. That is the definition,
satisfied on its face.

**d) Supabase is literally a "third-party partner" under Apple's narrow definition.**
`supabase_flutter: ^2.16.0` is a third-party SDK whose code has been added to the app
(`pubspec.yaml:81`). So even a reading that treats a hosted backend as external rather
than as "your servers" still lands inside "you **and/or your third-party partners**".

**Does the optional-disclosure exception apply?** No. It requires **all four** criteria
— Apple states *"Data types must meet all criteria in order to be considered optional
for disclosure."* Criterion 3 requires collection to occur *"only in infrequent cases
that are not part of your app's primary functionality, and which are optional for the
user."* Food search **is** the primary functionality and is not optional. Criterion 4
requires the data to be *"provided by the user in your app's interface"* with
affirmative per-submission choice. Both fail.

**Apple's on-device carve-out does not reach this**, and its second sentence points the
other way:

> Data that is processed only on device is not "collected" and does not need to be
> disclosed in your answers. **If you derive anything from that data and send it off
> device, the resulting data should be considered separately.**

Same page. Apple's instinct where derivation is concerned is that the *derived* item is
its own declarable thing. Here the derivation happens off-device, so the carve-out has
no purchase at all.

**On the page-rendering warning in the ticket:** `developer.apple.com/app-store/app-privacy-details/`
is **server-rendered** and fetched cleanly — 133 KB of HTML containing the full
definitions, verified independently of the fetch tool by raw retrieval and string match
on *"transmitting data off the device"*. No inference was needed. Other
`developer.apple.com` pages may still be JS-gated; this one is not.

**Bonus finding for #935.** #935's "Not yet specified" list asks whether changing Apple's
App Privacy answers requires a version submission. The same page answers it:

> You're responsible for keeping your responses accurate and up to date. If your
> practices change, update your responses in App Store Connect. **You may update your
> answers at any time, and you do not need to submit an app update in order to change
> your answers.**

Same page. Apple's answers are decoupled from the build; Play's are reviewed with the
submission. The sequencing decision in #935 can rely on that asymmetry.

---

## Q4 — Does the same reasoning reach Sentry?

**It reaches Sentry more easily for crash data, and — because of the scrubbing rule —
stops short of approximate location.** The two cases diverge, and the reason is
mechanical, not rhetorical.

**Crash logs and Diagnostics: unambiguously collected, declare them.** The developer
reads what is stored, retention is long, and Sentry is a service provider under Play's
definition (processing on the developer's behalf on the developer's instructions) and a
third-party partner under Apple's (`sentry_flutter: ^9.26.0`). No exemption applies to
any of it. Play data types: **Crash logs** (*"Crash log data from your app. For example,
the number of times your app has crashed, stack traces…"*) and **Diagnostics**
(*"Information about the performance of your app…"*). Apple: **Crash Data**, and
**Performance Data** only if tracing is on. This is a "collected" answer, and the
collection is user-optional (consent toggle) in a way the Supabase path is not — which
matters for Play's required/optional field.

**Approximate location: the scrubbing rule genuinely takes it out — and this is the one
place non-storage is documented, not assumed.**

Sentry derives geo regardless of the IP setting:

> **Geographic information is extracted from the user's IP address. This occurs even if
> the setting to stop storing IP addresses is turned on.**
> To scrub geo data, it's necessary to add an *Advanced Data Scrubbing* rule. For
> example, the rule `[Remove] [Anything] from [$user.geo.**]` will remove all geo
> information.

<https://docs.sentry.io/security-legal-pii/scrubbing/server-side-scrubbing/>

(This corroborates the reasoning already written into
`lib/core/utils/sentry_config.dart:74-78`: the client-side `beforeSend` that nulls
`event.user` *cannot* reach `user.geo`, because geo is created server-side at ingest.)

And on timing, which is the whole question:

> Advanced Data Scrubbing is an alternative way to redact sensitive information **just
> before it is saved in Sentry**.
> Data scrubbing settings always apply to all new events within a project/organization
> (going forward).
> Advanced Data Scrubbing rules take precedence over other Server-Side Data Scrubbing
> settings.

<https://docs.sentry.io/security-legal-pii/scrubbing/advanced-datascrubbing/>

With `[Remove] [Anything] from [$user.geo.**]` at **organization** level plus *Prevent
Storing of IP Addresses*, the geo exists only in memory during ingest and is removed
before the write. That is Play's ephemeral standard met on its own terms — *"only stored
in memory and retained for no longer than necessary"* — and it fails Apple's
storing-in-readable-form-for-longer test. **Approximate/Coarse Location does not need
declaring on account of Sentry.**

This is exactly the argument that **fails** for Supabase, and the contrast is the point
of the whole ticket: Sentry's geo is deleted before storage; Supabase's is *written to
storage and kept for a day*. The distinction the stores draw is storage, not readership.

**Three risks attached to that conclusion, all worth writing down:**

1. **The rule is a console setting, not code.** Nothing in this repository creates,
   asserts or tests the `$user.geo.**` rule or the IP toggle. A Sentry org
   administrator can undo the store declaration's factual basis with two clicks and no
   diff. `sentry_config.dart` is pinned by a test precisely because settings drift —
   the org-level half has no such protection. Consider recording the rule's existence
   and screenshot/date in the repo alongside the declaration.
2. **Scrubbing applies to the stored event, not to Sentry's own infrastructure logs.**
   Whether Sentry's ingest tier retains connection metadata in its own operational logs
   is not answerable from Sentry's user-facing scrubbing docs. Same class of question as
   Cloudflare's own logs behind Supabase — see "Could not verify".
3. **`tracesSampleRate` is now `null`** (`lib/core/utils/sentry_config.dart:52`), so
   Apple's **Performance Data** should *not* be declared for the build carrying that
   change — but `docs/privacy-policy-gaps.md:3` records `1.0` in **released v2.0.2**,
   and Play's form covers *"the sum of your app's data collection … across all its
   versions currently distributed on Google Play"* (support.google.com, same page).
   While v2.0.2 is the live build, performance data is in scope.

---

## Q5 — Verdicts

### Google Play — Data safety form

**Declare Approximate location. Yes, on account of the Supabase gateway logs.**

| Field | Answer |
|---|---|
| Data type | **Location → Approximate location** |
| Collected | **Yes** |
| Shared | **No** — Supabase is a service provider; transfers to service providers are exempt from the sharing disclosure |
| Processed ephemerally | **No** — 24 h on-disk retention fails *"only stored in memory"* |
| Required or optional | **Required** — food search is primary functionality; the user cannot turn it off |
| Purpose | **App functionality** (*"Used for features that are available in the app"*) |

Supporting authority: the Approximate location note (*"inferred, such as via IP
address … must be disclosed here"*), the `developer.android.com` bullet (*"Derives
location information from an IP address or access point name"*), the IP FAQ, and the
transient-then-logged FAQ. All cited above.

*Also reachable, and worth a deliberate decision rather than silence:*

- **Device or other IDs** — Play's IP FAQ contemplates using IP *"to extract
  identifiers"*, which this does not do; the IP is an incidental log field, not a key.
  The **TLS/JA3 fingerprint** is the more tempting candidate but is a fingerprint of the
  *client stack*, identical across every install of the same build, so it does not
  *"relate to an individual device, browser or app"* in Play's sense. **Defensible not to
  declare**; record the reasoning.
- **ISP name** — no Play data type fits. Not location, not an identifier. **Do not
  declare.**
- **Crash logs** and **Diagnostics** — declare on account of Sentry (collected; not
  shared, service provider; optional, consent-gated; purpose Analytics and/or App
  functionality). Not new, but check they are actually on the form.

### Apple — App Store Connect App Privacy

**Declare Coarse Location. Yes, on account of the Supabase gateway logs.**

| Field | Answer |
|---|---|
| Data type | **Location → Coarse Location** |
| Purpose | **App Functionality** |
| Linked to the user's identity | **Not Linked** — the app has no accounts and `beforeSend` strips the user block; the gateway record carries no identifier the developer holds. Confirm before ticking |
| Used for tracking | **No** |

Supporting authority: the "collect" definition, the not-retained worked example
(*"immediately discarded"*), and the IP guidance (*"Declare the relevant data types based
on how you use IP address, such as … coarse location …"*). All cited above.

*Also:* **Crash Data** on account of Sentry. **Performance Data** only while a build with
a non-null `tracesSampleRate` is live (v2.0.2 is).

### The strongest argument for *not* declaring, and why it should still lose

State it fairly, because it is not frivolous:

- Play's operative definition is *"'Collect' means transmitting data from your app off a
  user's device"*, and the app transmits a search request. It does not transmit a
  location. The city and postal code are manufactured at the far end from a network-layer
  artefact the app cannot suppress and would exist for any HTTPS request to any host.
- Play's IP FAQ conditions declaration on *"where developers **use** IP addresses as a
  means to determine location"*. Nobody here uses anything. No code path reads the field,
  no product decision consumes it, and the derivation is a property of Cloudflare's edge
  that the developer did not request and cannot disable.
- On that reading, every app on earth that terminates TLS behind a CDN collects
  approximate location, which is a conclusion Google's Data safety section demonstrably
  does not enforce.

**It should still lose, for four reasons.** (1) The data-type note is written in the
passive — *"Approximate location that is inferred"* — and `developer.android.com` makes
"derives location from an IP address" an example of collection standing alone, disjoint
from any permission. (2) Play's structure leaves no third box: a service provider is
defined as *not a third party*, so what it holds sits on the first party's side. (3) The
two carve-outs that reward non-access both require the other party to collect *under its
own terms*, which a processor by definition does not. (4) The "we cannot read it" half of
the premise is not true, and Apple's definition turns on exactly that.

Against a **1-bit public label** — the listing says "Approximate location" or it does
not — where the downside of over-declaring is a slightly less flattering listing and the
downside of under-declaring is *"blocked updates or removal from Google Play"*
(support.google.com, same page), the asymmetry is not close.

**If the honest answer is wanted plainly:** neither store wrote these definitions with a
developer-instructed processor deriving location and the developer never looking. Play's
definition is drafted around what leaves the app; Apple's around what can be accessed
after it leaves. Play's is genuinely ambiguous on the facts. **Apple's is not** — its
text is retention-and-capability, and both are satisfied. The safest defensible position
is therefore *declare on both*, with the reasoning recorded, rather than declaring on
Apple and arguing the Play distinction on a form that has no field for arguments.

### Two things that would make this cheaper to defend

Both are out of scope for the declaration itself but change the underlying facts:

1. **Fix the policy's "24 hours" or fix the plan.** It is Supabase's Free-plan retention
   (<https://supabase.com/pricing>), not a configured guarantee. Upgrading to Pro makes
   the published policy wrong by 6 days, silently.
2. **Record the Sentry org scrubbing rule in the repo.** The Coarse/Approximate Location
   *non*-declaration for Sentry rests entirely on a console setting that no test, no
   review and no diff protects.

---

## Could not verify

- **Whether Cloudflare, or Supabase's own infrastructure, retains the same fields beyond
  the project-visible 1-day window.** Supabase's docs describe what the *project's*
  Logs Explorer holds; they do not speak to the sub-processor's independent retention.
  Not answerable from first-party store documentation, and it does not change either
  verdict — 24 hours already fails both tests.
- **Whether Sentry's ingest tier keeps connection metadata in operational logs outside
  the scrubbed event.** Sentry's scrubbing docs describe the event payload only. Same
  class of unknown; same non-effect on the verdict.
- **How Google enforces this in practice.** Google publishes no threshold, and the FAQ
  explicitly declines to decide for developers: *"we cannot make determinations on
  behalf of the developers as to how they handle user data. Only you possess all the
  information required to complete the Data safety form."* No first-party statement
  exists on whether CDN-derived location has ever triggered enforcement. The verdicts
  above are what the text says, not a prediction of what is policed.
- **Whether the app's Play form and Apple answers currently omit approximate location.**
  Not checked — no console access from here. #935's current-state ticket owns that.
- **The exact Supabase Logs Explorer permission model** (whether every project member or
  only owners can read edge logs). Immaterial: developer access exists either way, which
  is all Apple's definition needs.

---

## Sources

Google (first-party):
- [Provide information for Google Play's Data safety section — Play Console Help](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Declare your app's data use — Android Developers](https://developer.android.com/privacy-and-security/declare-data-use)
- [User Data policy — Play Console Help](https://support.google.com/googleplay/android-developer/answer/10144311)

Apple (first-party):
- [App Privacy Details on the App Store — Apple Developer](https://developer.apple.com/app-store/app-privacy-details/)

Product facts (first-party to the processor, not to the stores):
- [Logging — Supabase Docs](https://supabase.com/docs/guides/telemetry/logs)
- [Pricing — Supabase](https://supabase.com/pricing)
- [Server-Side Data Scrubbing — Sentry Docs](https://docs.sentry.io/security-legal-pii/scrubbing/server-side-scrubbing/)
- [Advanced Data Scrubbing — Sentry Docs](https://docs.sentry.io/security-legal-pii/scrubbing/advanced-datascrubbing/)
