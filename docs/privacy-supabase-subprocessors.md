# Is Cloudflare a named sub-processor under a Supabase DPA?

Research for [#890](https://github.com/simonoppowa/OpenNutriTracker/issues/890), on
map [#867](https://github.com/simonoppowa/OpenNutriTracker/issues/867). Researched
2026-08-27 against Supabase's own published terms, sub-processor list and
documentation, plus Cloudflare's documentation where the Supabase side is silent.

**The short answer: yes, on all counts, and nothing needs signing.** Cloudflare, Inc
is a named sub-processor on Supabase's published list. The DPA is incorporated into
the Terms of Service by its own words and is effective from the moment the account
was created — there is no button to press and no document to sign. Sub-processor
changes carry a 30-day notice with an objection right, but **only if you subscribe**,
which is the one action the maintainer would have to take. Supabase's own
documentation names Cloudflare twice, in writing, as part of the platform's request
path. And Supabase's GDPR guide states outright that sub-processors "can affect your
data residency" — so the Frankfurt claim survives only if it is stated as
*storage and primary processing*, not as "the data never leaves the EU".

The obvious URL is a red herring: `https://supabase.com/legal/subprocessors` really
does return **404** (confirmed on the wire, 2026-08-27). It was never the right URL.

---

## 1. Where Supabase publishes the sub-processor list

**Live URL:
[`https://supabase.com/legal/customer-resources/subprocessor-list`](https://supabase.com/legal/customer-resources/subprocessor-list)**
(HTTP 200). It is linked from the [Legal Hub](https://supabase.com/legal) under
*Customer Legal Resources*, and — decisively — it is the URL the DPA itself names as
the operative list (clause 6.2, quoted in §3 below).

The page is a wrapper. The list is a PDF:

> The third-party sub-processors Supabase engages to help provide its services are
> indicated in the latest linked Subprocessor List available below. This page is
> updated with an updated Subprocessor List as our sub-processors change. You can
> subscribe to receive notifications of updates to this page, below.

Current document:
[Subprocessor List — Updated June 1, 2026](https://supabase.com/legal/subprocessor-list/June-1-2026.pdf).

**Cloudflare is on it**, verbatim:

> | Name of Sub-processor | Description of Processing |
> | --- | --- |
> | Cloudflare, Inc | Provision of hosting services |

**The stated purpose is "Provision of hosting services". No location is stated —
for Cloudflare or for anyone.** The PDF has exactly two columns, *Name of
Sub-processor* and *Description of Processing*. There is no country column, no
processing-location column, and no entity address. This matters for a policy
disclosure that wants to say *where* data goes: the list identifies **who**, and
Supabase does not publish **where** for any of them.

The full list, June 1 2026, reproduced in the order printed:

| Name of Sub-processor | Description of Processing |
| --- | --- |
| Supabase, Inc. | Provision of support services |
| Active Campaign, LLC d/b/a Postmark | Communication with Authorized Users in connection with the provision of the Services and support |
| Amazon Web Services, Inc | Provision of hosting services |
| Atlassian Corporation Plc | Provision of status page services |
| Braintrust Data, Inc | Provision of monitoring and tracing |
| Clay Labs Inc. | Provision of customer insight services |
| Clazar, Inc | Provision of marketplace services |
| **Cloudflare, Inc** | **Provision of hosting services** |
| ConfigCat Korlátolt Felelősségű Társaság | Feature flagging |
| Google, LLC | Provision of hosting services |
| Fly.io, Inc | Provision of hosting services |
| FrontApp, Inc | Communication with Authorized Users in connection with the provision of the Services and support |
| Functional Software, Inc d/b/a Sentry | Error monitoring and tracing |
| Github, Inc | Authorized Users account authentication |
| Hex Technologies, Inc | Provision of data analytics services |
| Hubspot, Inc | Communication with Authorized Users in connection with the provision of the Services and support |
| Notion Labs, Inc | Communication with Authorized Users in connection with the provision of the Services and support |
| Sublime Security Inc | Email Security |
| Latacora, LLC | Managed Security Service Provider |
| OpenAI, LLC | Provision of natural language processing and generation services |
| PandaDoc, Inc | Communication with Authorized Users in connection with the provision of the Services and support |
| Slack Technologies, LLC | Communication with Authorized Users in connection with the provision of the Services and support |
| Upstash, Inc | Provision of serverless data hosting services |
| Vercel, Inc | Provision of hosting services |

Two observations for the policy author:

- **The list is not segmented by service.** Most of these entries — Postmark, Front,
  Hubspot, Notion, PandaDoc, Slack, Clay, Clazar, Hubspot — are described as
  *communication with Authorized Users*, i.e. they process the **maintainer's** account
  and support data, not app end-user data. Nothing on the page says which entries touch
  which data, so the list cannot be copied into a user-facing policy wholesale without
  overstating who sees end-user food searches.
- **`Supabase, Inc.` appears as a sub-processor of `Supabase Pte. Ltd.`** The
  contracting party in the Terms of Service is *SUPABASE PTE. LTD., a Singapore
  entity with a registered address of 65 Chulia Street #38-02/03, OCBC Centre,
  Singapore 049513*. The US entity is a sub-processor beneath it. If the policy names
  the processor, that is the entity to name.

## 2. Is a DPA in force on a Free-plan account by default?

**Yes. It is in force automatically, it requires no signature, and there is nothing
in the dashboard to accept.** Three independent statements, none of which is
conditioned on plan or on any customer action.

The Terms of Service define the DPA and then incorporate it, in §7(b) (*Customer
Data*):

> The Parties agree to comply with the Data Processing Addendum, which is
> incorporated into this Agreement.

> "Data Processing Addendum" means the Data Processing Addendum available at
> https://supabase.com/legal/customer-resources/data-processing-addendum, or, if the
> Parties have a separately executed agreement in effect that covers the same subject
> matter, the separately executed agreement.

— [Terms of Service](https://supabase.com/terms). Note the fallback runs the *other*
way from what one might expect: the published DPA is the default, and a separately
executed agreement is the exception.

The DPA says the same thing from its own side, and dates itself to account creation
([Data Processing Addendum](https://supabase.com/legal/customer-resources/data-processing-addendum),
Version 1 — August 1, 2026):

> This Data Processing Addendum (the "DPA") supplements and forms part of the Supabase
> Terms of Service available at https://supabase.com/terms, or such other agreement
> entered into between the Customer and Supabase Pte. Ltd ("Supabase") relevant to
> Customer's use of the Services (the "Agreement"), and in case of any conflict,
> supersedes the Agreement in relation to the transfer and processing of Covered Data
> in connection with the performance of the Services. **This DPA is effective as of the
> Effective Date of the Agreement.**

And the Agreement's Effective Date is *use*, not signature:

> THIS AGREEMENT TAKES EFFECT WHEN YOU CLICK THE "I ACCEPT" BUTTON BELOW OR BY
> ACCESSING OR USING THE SERVICES (the "Effective Date").

Even the Standard Contractual Clauses annexed to the DPA need no separate signing
(DPA clause 12.2, *Signature of the SCCs*):

> The Parties agree that acceptance of the Agreement shall have the same effect as
> signing the SCCs.

The DPA also fixes the roles the way [#873](https://github.com/simonoppowa/OpenNutriTracker/issues/873)
adjudicated them, without needing anyone to argue it (clause 2, *Role of the Parties*):

> The Parties acknowledge and agree that Supabase acts as a processor/service provider,
> and Customer as controller/business under the Agreement and this DPA.

**No Free-plan carve-out exists.** The word "plan" does not appear anywhere in the
Terms of Service; the Agreement governs "your access to and use of the Cloud Services"
without tier distinction, and neither the DPA nor its sub-processor clauses condition
anything on a paid subscription. (By contrast, the docs *are* explicit when something
is tier-gated — the ISO 27001 certificate is "Enterprise and Team customers", and a
HIPAA BAA must be separately signed. The DPA is described with no such qualifier.)

**So what would the maintainer actually have to DO?** For the DPA itself: nothing.
One thing is worth doing, and it is not the DPA:

- **Subscribe to sub-processor change notifications** at the bottom of the
  [sub-processor list page](https://supabase.com/legal/customer-resources/subprocessor-list)
  (first name, last name, email). Per §3 below, the 30-day notice and the objection
  right are **conditional on having subscribed**. Without it, the list can change
  silently and the policy goes stale unnoticed.

**Not established from documentation:** whether the dashboard *also* surfaces a
countersigned/counterparty-executed DPA PDF for download (the org dashboard has a
*Legal Documents* section that serves SOC 2 and similar). That would be cosmetic —
the contract is already in force — but if a countersigned copy is wanted for the
record, the org dashboard's documents page is where to look, and Supabase support is
what would confirm it. Nothing was signed or clicked in the course of this research.

## 3. The Art. 28 sub-processor terms

DPA **clause 6.2 (Authorization)** is a general (blanket) authorization pinned to the
published list:

> Customer grants Supabase general authorization (or, where applicable, has Customer's
> Controller's general authorization) to engage any of the Sub-processors provided in
> Supabase's Sub-processor list, available at
> https://supabase.com/legal/customer-resources/subprocessor-list ("Subprocessor
> List"), as amended from time to time in accordance with clause 6.3 (the "Authorized
> Sub-processors"), to Process Covered Data. Supabase shall: (a) enter into a written
> agreement with each Authorized Sub-processor imposing data protection obligations
> that, in substance, are no less protective of Covered Data than Supabase's
> obligations under this DPA; and (b) remain liable for each Authorized Sub-processor's
> compliance with the obligations under this DPA.

That is Art. 28(2) general written authorization plus Art. 28(4) flow-down and
retained liability. The SCC counterpart is elected explicitly in Schedule 2:

> 1.3 Option 2 of Clause 9(a) (General written authorization) shall apply, and the time
> period to be specified is determined in clause 6.3 of the DPA.

DPA **clause 6.3 (Updates to the Subprocessor List)** carries the notice and objection
machinery — quoted in full because the conditional in the second sentence is the
load-bearing part:

> Supabase offers a mechanism for Customer to subscribe to notifications of changes to
> the Subprocessor List via
> https://supabase.com/legal/customer-resources/subprocessor-list. **If Customer
> subscribes to receive such updates**, Supabase will provide Customer with at least
> thirty (30) days' notice of any proposed changes to the Authorized Sub-processors.
> Customer shall notify Supabase if it objects to the proposed change to the Authorized
> Sub-processors (including, where applicable, when exercising its right to object
> under clause 9(a) of the SCCs) by providing Supabase with written notice of the
> objection within five (5) days after Supabase has provided notice to Customer of such
> proposed change (an "Objection"). In the event Customer submits an Objection to
> Supabase, Supabase and Customer shall work together in good faith to find a mutually
> acceptable resolution to address such Objection. If Supabase and Customer are unable
> to reach a mutually acceptable resolution within a reasonable timeframe, which shall
> not exceed thirty (30) days, Customer may terminate the portion of the Agreement
> relating to the Services affected by such change by providing written notice to
> Supabase.

To answer the ticket's three sub-questions plainly:

- **How are changes notified?** By email, to subscribers only. The page is also
  updated, but there is no push to non-subscribers.
- **Is there an objection right?** Yes — written objection, then good-faith
  negotiation, then a right to terminate the affected portion of the Agreement.
  There is **no right to block the change**; the remedy is exit, not veto.
- **Notice period?** At least **30 days** before the change. The window to object is
  **5 days** after notice, and resolution is capped at **30 days**.

The 5-day objection window is short and starts on Supabase's notice, which is another
reason to subscribe rather than to poll the page.

Retention has a matching flow-down (clause 11): on expiry of the retention period
Supabase "shall delete all copies of Covered Data Processed by Supabase or any
Authorized Sub-processors."

## 4. Does Supabase document the Cloudflare layer specifically?

**Yes — twice in the product documentation, and once as a global status component.**
[#869](https://github.com/simonoppowa/OpenNutriTracker/issues/869) measured it; these
are Supabase acknowledging it in writing, which is what a paper trail needs.

The logging documentation describes the API path as running through Cloudflare, and
names exactly the field prefix #869 observed
([Logs](https://supabase.com/docs/guides/monitoring-and-debugging/logs)):

> API logs run through the Cloudflare edge servers and will have attached Cloudflare
> metadata under the `metadata.request.cf.*` fields.

The same page defines the `edge_logs` source as Cloudflare-sourced:

> `edge_logs`: Edge network logs, containing request and response metadata retrieved
> from Cloudflare.

It also publishes the allow-list of headers retained in API logs, which includes two
Cloudflare-injected headers on the request side and two on the response side:

> Request headers: `accept` `cf-connecting-ip` `cf-ipcountry` `host` `user-agent`
> `x-forwarded-proto` `referer` `content-length` `x-real-ip` `x-client-info`
> `x-forwarded-user-agent` `range` `prefer`
>
> Response headers: `cf-cache-status` `cf-ray` `content-location` `content-range`
> `content-type` `content-length` `date` `transfer-encoding` `x-kong-proxy-latency`
> `x-kong-upstream-latency` `sb-gateway-mode` `sb-gateway-version`

Note `cf-ipcountry` in particular: Supabase documents that a **country derived from
the end user's IP** is retained in project logs by default. That is a per-request
location inference about the app's users, published as a documented platform
behaviour, not something the project configured.

The security guide names Cloudflare as the DDoS layer
([Supabase Security](https://supabase.com/docs/guides/security)):

> Supabase protects against Distributed Denial of Service (DDoS) attacks at the edge
> via Cloudflare.

And the status page treats the gateway as a **global, non-regional** component:
[status.supabase.com](https://status.supabase.com) lists `API Gateway` — described as
"API Gateway for all Supabase Products" — in the same flat list as the per-region
components (`eu-central-1`, `us-east-1`, and so on), i.e. it is not scoped to a region
the way Database and Storage are.

**What the documentation does *not* say anywhere:** that this layer is optional,
configurable, or avoidable. It is described as how the platform works. That is
consistent with #869's finding and is the point that matters — the project is not
using a feature it could turn off, so Cloudflare is in the path of every request by
design, and the sub-processor listing is the right and only place it is disclosed.

The storage CDN documentation is a near-miss worth recording so nobody re-searches
it: [Storage CDN](https://supabase.com/docs/guides/storage/cdn/fundamentals) describes
the CDN in detail — "All requests to the Supabase Storage API are routed to the CDN
first" — but never names the provider. The provider identification comes from the two
pages quoted above, not from there.

## 5. Supabase's stated position on EU data residency

**Supabase scopes its residency claim to storage and primary processing, and states
explicitly that sub-processors can affect the residency analysis. It does not address
Cloudflare edge termination specifically.**

The DPA's location clause (**clause 6.1, *Location***) is the contractual position, and
it is carefully bounded:

> Supabase may Process Covered Data anywhere that Supabase or its Sub-processors
> maintain facilities, subject to the remainder of this clause 6, its obligations with
> respect to data transfers as required by Applicable Data Protection Laws and clause
> 12 of this DPA. **Where Customer directs Supabase to Process Covered Data in a
> specific geographical region, Supabase shall ensure that such Covered Data is stored
> and primarily Processed in that region unless otherwise required to comply with
> Customer's additional instructions, applicable law or as necessary to provide
> Services requested by Customer.**

Three limits in one sentence: **"stored and primarily Processed"** (not exclusively),
and two carve-outs, one of which — "as necessary to provide Services requested by
Customer" — is exactly the shape of a global edge gateway. The default, absent a region
direction, is that processing may occur "anywhere that Supabase or its Sub-processors
maintain facilities".

The GDPR guide says the same thing in plain language, and names sub-processors as a
residency factor
([GDPR compliance and Supabase](https://supabase.com/docs/guides/security/gdpr-compliance)):

> Each Supabase project is deployed to a single primary region, and your project's
> primary Postgres database, Auth service, and Storage objects are hosted in that
> region. Choosing a specific region within the EU pins these services to that exact
> AWS region.

> Choosing a region is a data-location control and does not make your application GDPR
> compliant on its own. **Backups, logs, data exported to external systems, Edge
> Function execution, and sub-processors can affect your data residency and
> international transfer analysis.**

The regions page repeats the framing
([Available regions](https://supabase.com/docs/guides/platform/regions)):

> The region you choose also determines where your primary project data is stored.
> [...] Region selection is a data-location control, not proof of regulatory compliance.

Incidentally relevant to this project's configuration: the same page warns that the
general "Europe" grouping includes London and Zurich, which are not EU member states,
and advises choosing a specific region if EU-only matters. This project uses the
**specific** region `eu-central-1` (Frankfurt), so it is already on the right side of
that warning — the Postgres database, Auth and Storage objects are pinned to Frankfurt.

**Nothing in Supabase's documentation or terms addresses TLS termination at the edge.**
No page states where the Cloudflare layer decrypts, whether it can be regionalised, or
whether an EU project's requests are terminated in the EU. The transfer machinery in
DPA clause 12 and Schedule 2 (EU SCCs, Module Two controller-to-processor, Irish
governing law, UK Addendum, Swiss regime) is what covers transfers out of the EEA in
the abstract — it is a lawful-transfer mechanism, not a claim that transfers do not
happen.

Cloudflare's own documentation supplies the missing behaviour, and it points the
unhelpful way. Restricting decryption to a region is a **separate paid product**,
[Regional Services](https://developers.cloudflare.com/data-localization/regional-services/),
part of the Data Localization Suite:

> With Regional Services, TLS termination — the point at which encrypted HTTPS traffic
> is decrypted so Cloudflare can inspect and apply your security rules — only occurs
> inside the configured region. For example, if a hostname is configured to
> regionalize to the European Union (EU), any HTTPS request from the United States (US)
> will be forwarded in encrypted form to an EU data center before being decrypted.

The existence of that product is the proof of the default: without it, decryption
happens at the data centre that receives the connection, which #869 measured as the
PoP nearest the end user (`cf.colo` varying by client location). **There is no
published evidence that Supabase enables Regional Services on customer project
hostnames**, and no Supabase page mentions it.

**This is the one question documentation cannot settle, and it is worth asking.** The
precise question is: *does Cloudflare terminate TLS for `*.supabase.co` project
endpoints at the PoP nearest the client, or is Regional Services (or equivalent)
applied for projects in EU regions?* That wants **a written question to Supabase
support**, and the answer should be recorded here when it arrives. Until then the
honest reading is the conservative one: request metadata for an EU project is
processed at a Cloudflare PoP wherever the user happens to be, including outside the
EEA, under the SCCs in DPA Schedule 2.

---

## What this means for the policy

**Two parties must be named, and the Frankfurt claim survives only in Supabase's own
narrower wording.**

**Processor: Supabase Pte. Ltd.** — the Singapore entity named in the Terms of Service,
not "Supabase" loosely and not Supabase, Inc. (which is itself a sub-processor
beneath it). The processor relationship is not an inference the project has to defend;
DPA clause 2 states it: Supabase "acts as a processor/service provider, and Customer as
controller/business".

**Sub-processor: Cloudflare, Inc.** — named on the published list with the stated
purpose *"Provision of hosting services"*, and independently acknowledged in Supabase's
documentation as the edge the API path runs through. Both the naming and the purpose
can be quoted from primary sources. **No location can be quoted for it**, because
Supabase publishes none; a policy that wants to state where Cloudflare processes must
either say "worldwide edge locations, selected by proximity to the user" on the
strength of #869's measurement plus Cloudflare's own routing documentation, or say
nothing about location for that entity.

**Amazon Web Services, Inc.** should be named too if the policy names the hosting
chain at all: it is on the same list with the same stated purpose, and the GDPR guide
confirms the project's Postgres, Auth and Storage sit in an AWS region. Naming
Cloudflare but not AWS would describe the transit layer while omitting the layer that
actually stores the data.

**The other twenty-one entries should not be copied across.** Most are described as
*communication with Authorized Users* — the maintainer's own account, support and
marketing contact data — and nothing on the list suggests they touch app end-user food
searches. The list is Supabase's, covering all of its services and all of its customer
relationships; a user-facing policy that reproduced it wholesale would tell users that
Slack, Hubspot and OpenAI process their data, which is not established and is probably
false for this project. If the policy wants completeness, link the list rather than
inline it — that also keeps it accurate as the list changes.

**On residency: do not write "your data stays in the EU". Write what Supabase writes.**
The defensible sentence is that the database, authentication and stored objects are
hosted in Frankfurt (`eu-central-1`), because that is what
[the GDPR guide](https://supabase.com/docs/guides/security/gdpr-compliance) claims and
what DPA clause 6.1 obliges — *stored and primarily Processed* in the directed region.
The indefensible sentence is any claim that requests never leave the EU. They do:
every request terminates at a Cloudflare PoP chosen by proximity to the user, request
metadata including IP-derived country lands in the project's logs, and Supabase's own
guide warns that "logs [...] and sub-processors can affect your data residency and
international transfer analysis". Transfers outside the EEA are **covered** by the
SCCs in DPA Schedule 2 rather than avoided, and that is a different — and honest —
thing to say.

**No contractual gap was found, and nothing needs signing.** The paper trail
[#873](https://github.com/simonoppowa/OpenNutriTracker/issues/873) went looking for
exists: a DPA in force by default, a general authorization pinned to a published list,
Cloudflare on that list, flow-down obligations and retained liability, and SCCs
executed by acceptance. The only outstanding action is a free one — **subscribe to
sub-processor change notifications**, without which the 30-day notice and 5-day
objection right in clause 6.3 never fire.

---

## Sources

- [Supabase Legal Hub](https://supabase.com/legal)
- [Supabase Terms of Service](https://supabase.com/terms)
- [Supabase Data Processing Addendum, Version 1 — August 1, 2026](https://supabase.com/legal/customer-resources/data-processing-addendum) (`https://supabase.com/legal/dpa` 308-redirects here)
- [Supabase Subprocessor List page](https://supabase.com/legal/customer-resources/subprocessor-list) — and the [June 1, 2026 PDF](https://supabase.com/legal/subprocessor-list/June-1-2026.pdf)
- `https://supabase.com/legal/subprocessors` — **HTTP 404**, confirmed 2026-08-27
- [Logs — Supabase Docs](https://supabase.com/docs/guides/monitoring-and-debugging/logs)
- [Supabase Security — Supabase Docs](https://supabase.com/docs/guides/security)
- [GDPR compliance and Supabase — Supabase Docs](https://supabase.com/docs/guides/security/gdpr-compliance)
- [Available regions — Supabase Docs](https://supabase.com/docs/guides/platform/regions)
- [Storage CDN — Supabase Docs](https://supabase.com/docs/guides/storage/cdn/fundamentals)
- [Supabase status page](https://status.supabase.com)
- [Regional Services — Cloudflare Data Localization Suite](https://developers.cloudflare.com/data-localization/regional-services/)
