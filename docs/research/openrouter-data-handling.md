# What OpenRouter does with prompts and images

Research notes gathered 2026-08-15 against primary sources only — OpenRouter's
own documentation, privacy policy, terms of service, OpenAPI reference, and its
live policy APIs at `openrouter.ai`. No blog posts, no third-party summaries.
Where the rendered docs are JavaScript-heavy, the underlying Markdown was
fetched directly (every OpenRouter docs page is served verbatim at the same URL
with a `.md` suffix), so the quotes below are the source text rather than a
paraphrase of a rendering.

Written to resolve
[#654](https://github.com/simonoppowa/OpenNutriTracker/issues/654). The
deliverable is **what could truthfully be written** in the README privacy table
and the in-app disclosure if OpenRouter were added — not a recommendation about
whether to add it.

Policy versions as of the access date:

| Document | Version marker | URL |
| :-- | :-- | :-- |
| Privacy Policy | Last Updated: July 6, 2026 | <https://openrouter.ai/privacy> |
| Terms of Service | Last Updated: July 29, 2026 | <https://openrouter.ai/terms> |
| Docs pages | unversioned, accessed 2026-08-15 | <https://openrouter.ai/docs> |

---

## Summary

OpenRouter's own retention posture is stronger than its reputation and is stated
plainly: it does not store prompts or responses unless you opt in, it does not
train on them, and it says so in both the docs and the privacy policy. The
awkward part is not OpenRouter — it is that OpenRouter is a **router**, so the
question "where does the data go" no longer has a single fixed answer, which is
exactly the property the README's privacy claim depends on.

Five findings drive everything downstream:

1. **OpenRouter itself retains nothing by default.** "OpenRouter itself has a ZDR
   policy; your prompts are not retained unless you specifically opt in to prompt
   logging." Two independent opt-ins exist, both off by default. Request
   *metadata* (token counts, latency) is always stored; content is not.
2. **The upstream provider is the variable, and it is enforceable per request.**
   `provider.zdr: true`, `provider.data_collection: "deny"` and
   `provider.only: [...]` are request-body fields — no account toggle needed, and
   they cannot be weakened by an account setting.
3. **The `:free` belief is half right and needs restating.** There is no
   documented blanket rule that `:free` slugs permit training. What is documented
   is that OpenRouter keeps *"separate settings for paid and free models"* for
   training consent, and individual model pages carry provider-authored terms
   conditioned on free usage ("If you are using X for free, we may use your
   inputs and outputs to train and improve our models"). Treat free usage as a
   distinct data-policy class; do not treat the `:free` suffix as self-describing.
4. **The default response body does not name the upstream provider.** Provider
   attribution requires opting in with the `X-OpenRouter-Metadata: enabled`
   header. This is a direct problem for a README that names each destination.
5. **The app's current Anthropic image quote cannot be carried over.**
   OpenRouter's equivalent commitment is materially weaker — files are not
   persisted "beyond the duration necessary to route the request, **except as
   required for abuse detection, security, billing, or legal compliance**."

The load-bearing consequence for the README: adding OpenRouter adds **two**
network destinations, not one — `openrouter.ai` plus whichever upstream provider
serves the request — and the second is only nameable in advance if the app pins
it with `provider.only` and `allow_fallbacks: false`.

---

## 1. What OpenRouter retains, and for how long

### Default behaviour: nothing, for content

The Zero Data Retention page states OpenRouter's own position in one sentence
(<https://openrouter.ai/docs/guides/features/zdr>):

> OpenRouter itself has a ZDR policy; your prompts are not retained unless you
> specifically opt in to prompt logging.

The Data Collection page is more explicit
(<https://openrouter.ai/docs/guides/privacy/data-collection>):

> Any prompt retention on OpenRouter is always opt-in. OpenRouter has never
> shared, sold, or licensed underlying prompt data to any third party. We
> document which providers may capture data for training, and provide settings to
> control how your own prompts may be used.

> OpenRouter does not store your prompts or responses, *unless* you opt in to one
> or both of the following:

The two opt-ins, both quoted verbatim from that page:

> * **Private Input & Output Logging:** Make your prompts and completions visible
>   in your logs for debugging, comparing model responses, and optimizing
>   prompts. OpenRouter does not access or use this data. For organizations, only
>   admins can view logged data. Off by default.
> * **OpenRouter Use of Inputs/Outputs:** Allow OpenRouter to use your prompt and
>   completion data to improve the product. In exchange, you receive a 1%
>   discount on all model usage. Off by default.

Both are account/workspace settings. **Neither is on by default**, and an API
client that never touches the dashboard gets the no-retention path.

### What is always retained

Metadata, always; content, never by default. Same page:

> OpenRouter does store metadata (e.g. number of prompt and completion tokens,
> latency, etc) for each request. This is used to power our reporting and model
> ranking, and your [logs metadata].

> This metadata does not include the content of your prompts or responses, only
> information about the request itself.

There is also a sampling behaviour worth naming honestly, because it is the one
case where prompt *content* leaves the request path without an opt-in:

> *Anonymous Input Categorization: OpenRouter samples a small number of prompts
> for categorization to power our reporting and model ranking. If you are not
> opted in to OpenRouter use of inputs/outputs, any categorization of your
> prompts is stored completely anonymously and never associated with your account
> or user ID. The categorization is done by model with a zero-data-retention
> policy.*

The Terms restate this with a storage commitment
(<https://openrouter.ai/terms>, §6.5 "License to Categorize Inputs"):

> OpenRouter uses a hosted model for categorizing Inputs, which does not store or
> log any Inputs provided to it. […] Unless explicitly opted in to prompt
> logging, we do not store your Inputs after categorizing them and do not
> associate the categorized Inputs with any specific user or organizational
> accounts.

So: a sampled prompt is sent to a categorising model, a topic label is kept, the
prompt text is not. The privacy policy §2 corroborates the de-identification
("We disassociate Inputs and Outputs from your user ID and assign a topic
category to each Input").

### Retention duration when logging *is* enabled

<https://openrouter.ai/docs/guides/features/input-output-logging>:

> **Retention**: Data is retained for a minimum of 3 months, and may be retained
> beyond 3 months at OpenRouter's discretion unless you request deletion. Account
> owners can request deletion of their stored data at any time by contacting
> support@openrouter.ai.

> **Storage**: Prompt and response data is stored in an isolated Google Cloud
> Storage project with separate access controls. All data is encrypted at rest
> using Google Cloud's default encryption (AES-256).

> **Privacy**: OpenRouter does not access or use your prompt and response data
> logged with this feature for model training, analytics, or any other purpose.

Note the asymmetry: "a **minimum** of 3 months … at OpenRouter's discretion"
is an open-ended floor, not a ceiling. If the app ever enabled this, "3 months"
would be an understatement, not a claim.

### Images specifically

This is the direct analogue of the Anthropic sentence the README currently
quotes. Privacy Policy §7 "Personal Data Retention", subsection "Image, Audio,
and Video Data" (<https://openrouter.ai/privacy>):

> Image, audio, and video data submitted through the Service is transmitted to
> the applicable Model Provider for inference. We do not persist image, audio or
> video files beyond the duration necessary to route the request, except as
> required for abuse detection, security, billing, or legal compliance. Model
> Providers' retention practices vary; check the applicable provider's data
> practices. You may request deletion of your data by contacting us at
> [email protected].

And §1, under "Biometric Data Processing":

> OpenRouter acts as an intermediary, passing source image, audio and visual data
> to Models, and does not independently process or store this biometric data, or
> generate any biometric identifiers.

**This is weaker than Anthropic's image statement and must not be paraphrased
into it.** Anthropic says images are "ephemeral and not stored beyond the
duration of the API request" with no carve-out. OpenRouter says "beyond the
duration necessary to route the request" **with a four-way carve-out** (abuse
detection, security, billing, legal compliance). Any README text that reuses the
Anthropic phrasing for the OpenRouter path would be false.

One more retention surface, from the Terms §6.3(b) "Processing-Related Storage":

> Certain features of the Service, such as batch or other large-volume request
> processing, require OpenRouter to temporarily store your User Content in order
> to process, route, and fulfill your request, including where the volume or size
> of a request cannot be processed in memory.

A single meal photo is not batch processing, but "cannot be processed in memory"
is a size-dependent trigger and the Terms do not state a byte threshold. Flagged
below as not fully established.

### Training

Privacy Policy §1, standalone sentence:

> OpenRouter does not use your Inputs or Outputs for model training.

This is unconditional on its face and is the cleanest sentence in the whole
corpus. It says nothing about providers — see Q2.

---

## 2. Does behaviour vary by model or upstream provider? And what about `:free`?

### Yes, and OpenRouter says the variation is the provider's, not theirs

<https://openrouter.ai/docs/guides/privacy/provider-logging>:

> Each provider on OpenRouter has its own data handling policies. We reflect
> those policies in structured data on each AI endpoint that we offer.

> Wherever possible, OpenRouter works with providers to ensure that prompts will
> not be trained on, but there are exceptions. If you opt out of training in your
> account settings, OpenRouter will not route to providers that train. This
> setting has no bearing on OpenRouter's own policies and what we do with your
> prompts.

Retention, unlike training, is **not** routed on by default:

> Providers also have their own data retention policies, often for compliance
> reasons. OpenRouter does not have routing rules that change based on data
> retention policies of providers, but the retention policies as reflected in
> each provider's terms are shown below. Any user of OpenRouter can ignore
> providers that don't meet their own data retention requirements.

That is an important distinction: *training* has an account-level routing rule;
*retention* does not, and is instead handled by the separate ZDR mechanism in Q3.

The Privacy Policy §1 "Model Provider Data Practices" is blunter:

> Different Model Providers have different data practices, including with respect
> to whether they retain or use your Inputs and Outputs to train, fine-tune,
> evaluate, or improve their Models. Some Model Providers may use your Inputs and
> Outputs for model training or improvement. […] Where disclosed to us, we label
> Models that do not use your data for training. If you do not want your Inputs
> used for model training, select a Model or Model Provider that commits to not
> using your data for that purpose.

> We do not control, and are not responsible for, LLMs' handling of your Inputs
> or Outputs, including for use in their model training.

§3:

> Model Providers process your Inputs to generate Outputs and may, depending on
> their own terms and data practices, retain and use your Inputs and Outputs for
> their own purposes, such as model training and improvement. We contractually
> require Model Providers to comply with applicable data protection laws, but the
> Model Provider's own terms govern their independent use of your data to the
> extent permitted by our agreements.

§4, under CCPA:

> OpenRouter cannot control Model Provider-side training once user data is
> transmitted to a training-permitted Model Provider.

Terms §6.1:

> Some Models may store or train on your Inputs for improving their own large
> language models and may allow you to opt-out of model training, as described in
> their Model Terms. Where possible, OpenRouter has opted out of model training
> with the Models it uses. OpenRouter strives to accurately represent the status
> of prompt logging and training for each Model on our Site. However, OpenRouter
> is not liable for errors or misrepresentations made in any Model Terms.

And the Terms' disclaimer section, in capitals in the original:

> OPENROUTER MAKES NO REPRESENTATION OR WARRANTY REGARDING ANY MODEL PROVIDER'S
> DATA HANDLING, RETENTION, TRAINING, SECURITY, AVAILABILITY, OR INTELLECTUAL
> PROPERTY PRACTICES.

Read together: OpenRouter's *routing controls* are contractual and reliable; its
*descriptions of provider policies* are explicitly best-effort and disclaimed.
The provider-routing docs say the same thing about the model-page tags:

> Some model providers may log prompts, so we display them with a **Data Policy**
> tag on model pages. This is not a definitive source of third party data
> policies, but represents our best knowledge.
> — <https://openrouter.ai/docs/guides/routing/provider-selection>

There is one genuinely reassuring default in the ZDR page, though:

> If OpenRouter is not able to establish or ascertain a clear policy for a
> provider or endpoint, we take a conservative stance and assume that the
> endpoint both retains and trains on data and mark it as such.

Unknown fails closed, not open.

### The `:free` question — partially confirmed, and the common framing is wrong

**The `:free` variant documentation says nothing about data at all.**
<https://openrouter.ai/docs/guides/routing/model-variants/free> is 20 lines long
and its entire "Details" section reads:

> Free variants provide access to models without cost, but may have different
> rate limits or availability compared to paid versions.

No training clause, no retention clause. So the belief that "`:free` means they
train on you" has **no blanket documentary basis**. But two primary sources show
the belief is tracking something real:

**(a) OpenRouter maintains separate training consent for free vs paid.** From
<https://openrouter.ai/docs/guides/privacy/provider-logging>:

> On your account settings page, you can set whether you would like to allow
> routing to providers that may train on your data (according to their own
> policies). **There are separate settings for paid and free models.**

A separate toggle exists precisely because the two classes behave differently.
This is the strongest primary-source confirmation available that free usage is a
distinct data-policy class.

**(b) Individual model pages carry provider-authored terms conditioned on free
usage.** On <https://openrouter.ai/poolside/laguna-xs-2.1:free>, the model
description ends:

> If you are using Laguna XS 2.1 for free, we may use your inputs and outputs to
> train and improve our models.

Two details matter here and are easy to get wrong:

- The "we" is the **model provider** (Poolside), not OpenRouter. It is the
  provider's own term, surfaced by OpenRouter.
- The identical sentence appears on the **paid** slug page
  (`poolside/laguna-xs-2.1`) too, because it is one shared model description. The
  operative condition is *"if you are using it for free"* — the economic fact —
  **not the `:free` suffix in the slug**. A promotional zero-price paid slug would
  be caught by the same clause.

**Verdict:** *refuted as a platform-wide rule about the `:free` suffix;
confirmed as a real, provider-specific pattern attached to free usage.* The
correct engineering posture is not "avoid `:free`" but "assert
`data_collection: "deny"` and/or `zdr: true` per request", which is policy-driven
rather than slug-driven and therefore cannot be silently invalidated when a
provider changes its terms.

### Live provider-policy data

OpenRouter's own provider-logging page renders its table by fetching
`https://openrouter.ai/api/frontend/v1/all-providers`. Querying that endpoint
directly on 2026-08-15 (81 providers):

| Property | Count |
| :-- | --: |
| Providers with `training: true` | 3 (DeepSeek, Liquid, NVIDIA) |
| Providers with `retainsPrompts: false` (zero retention) | 45 |
| Providers retaining prompts, period unstated | 24 |
| Providers retaining for 30 days | 11 |
| Providers retaining for 55 days | 1 |

Selected entries, verbatim from that JSON:

```json
"Anthropic":      {"training": false, "retainsPrompts": true,  "retentionDays": 30, "requiresUserIDs": true}
"Amazon Bedrock": {"training": false, "retainsPrompts": false, "requiresUserIDs": false}
"Google AI Studio":{"training": false,"retainsPrompts": true,  "retentionDays": 55, "requiresUserIDs": false}
"OpenAI":         {"training": false, "retainsPrompts": true,  "requiresUserIDs": true}
```

Note the finding that matters most for this app: **OpenRouter classifies
first-party Anthropic as 30-day retention**, and cross-checking
`https://openrouter.ai/api/v1/endpoints/zdr` confirms **zero** ZDR endpoints are
served by first-party Anthropic. The 52 Claude endpoints on the ZDR list are all
served via Amazon Bedrock or Google Vertex. The ZDR docs page says the same thing
in prose — enabling the Anthropic ZDR scope "Removes first-party Anthropic
endpoints (Bedrock and Vertex remain available)".

This does not contradict the app's current README quote, which is Anthropic's
statement about *image files* specifically rather than about text retention. But
it does mean a ZDR-enforced Claude request through OpenRouter would be served by
AWS or Google, not by Anthropic — a different named destination than the one the
README lists today.

---

## 3. Is there a no-training / zero-retention mode, and can a client enforce it per request?

**Yes to both, and the per-request path is the one that matters here.**

### Definition

<https://openrouter.ai/docs/guides/features/zdr>:

> Zero Data Retention (ZDR) means that a provider will not store your data for
> any period of time.

> Providers that do not retain your data are also unable to train on your data.
> However we do have some endpoints & providers who do not train on your data but
> *do* retain it (e.g. to scan for abuse or for legal reasons). OpenRouter gives
> you controls over both of these policies.

That second sentence is the reason there are two independent knobs rather than
one: `zdr` (retention) and `data_collection` (storage/training).

### Enforcement scopes

> OpenRouter has privacy settings that, when enabled, only allow you to route to
> endpoints that have a Zero Data Retention policy. **You can enforce ZDR
> globally, per model group, per guardrail, or per request.**

### Per-request enforcement — the answer to "can a client enforce it per request"

> In addition to account-level and guardrail-level settings, you can enforce Zero
> Data Retention on a per-request basis using the `zdr` parameter in your API
> calls.

> The request-level `zdr` parameter operates as an "OR" with your account-wide
> and guardrail ZDR settings. If any is enabled, ZDR enforcement will be applied.
> This means the per-request parameter can only be used to ensure ZDR is enabled
> for a specific request, not to override or disable account-wide or guardrail
> enforcement.

> This is useful for customers who don't want to globally enforce ZDR but need to
> ensure specific requests only route to ZDR endpoints.

```json
{
  "model": "gpt-4",
  "messages": [],
  "provider": { "zdr": true }
}
```

> When `zdr` is set to `true`, the request will only be routed to endpoints that
> have a Zero Data Retention policy. When `zdr` is `false` or not provided, ZDR
> enforcement still applies if enabled in your account or guardrail settings.

The "OR" semantics are exactly what a privacy-first client wants: a request-level
`zdr: true` is a **ratchet**. It can only tighten, never loosen, and no account
setting — including one a user might change later in the OpenRouter dashboard —
can weaken a request the app sends. This is the single most useful finding for
issue #654, because it means the app's guarantee does not depend on how the user
configured an account the project cannot see.

### The separate no-training control

<https://openrouter.ai/docs/guides/routing/provider-selection>, "Requiring
Providers to Comply with Data Policies":

| Field | Type | Default | Description |
| :-- | :-- | :-- | :-- |
| `data_collection` | `"allow"` \| `"deny"` | `"allow"` | Control whether to use providers that may store data. |

> * `allow`: (default) allow providers which store user data non-transiently and
>   may train on it
> * `deny`: use only providers which do not collect user data

Note the default is `"allow"` — permissive. A client that sends nothing gets the
permissive path, so this must be set explicitly.

### Two documented limits on ZDR

Both from the ZDR page, and both must be disclosed rather than glossed:

> ZDR enforcement only applies to provider routing for inference requests. It does
> not apply to plugins and tools you choose to enable, such as web search. These
> may be operated by third-party services with their own data retention policies.

(Not relevant to this app unless plugins are ever enabled — but it is a
documented boundary of the guarantee.)

> OpenRouter has taken the stance that in-memory caching of prompts is *not*
> considered "retaining" data, and we therefore allow endpoints/models with
> implicit caching to be hit when a ZDR routing policy is in effect.

So "zero retention" means zero *persistent* retention. Prompt content may sit in
a provider's in-memory cache. Every Claude endpoint on the current ZDR list
reports `supports_implicit_caching: false`, so this is presently moot for Claude
via Bedrock/Vertex — but it is a policy stance that could change without the
label changing, and it is not what a lay reader assumes "zero data retention"
means.

---

## 4. Does OpenRouter publish which upstream provider served a request?

**Yes — but only if you opt in per request, and not in the default response
body.** This is the finding with the most direct consequence for the README.

### Not in the default response

The OpenAPI schema for `POST /api/v1/chat/completions`
(<https://openrouter.ai/docs/api-reference/chat-completion>) defines the 200
response object with these properties and no others: `id`, `choices`, `created`,
`model`, `object`, `openrouter_metadata`, `service_tier`, `system_fingerprint`,
`usage`. **There is no top-level `provider` field.** The narrative response type
in <https://openrouter.ai/docs/api-reference/overview> agrees — it lists `id`,
`choices`, `created`, `model`, `object`, `system_fingerprint`, `usage` and
nothing else.

`model` tells you which *model* answered, which is not the same as which
*company's infrastructure* answered. `anthropic/claude-*` could be served by
Anthropic, Amazon Bedrock, or Google Vertex — as the ZDR endpoint list above
demonstrates concretely.

### Available via an opt-in header

<https://openrouter.ai/docs/guides/features/router-metadata>:

> OpenRouter's router runs every request through a multi-stage pipeline: it picks
> a provider, may compress context, may run guardrails, may invoke server-side
> tools, and may retry against fallbacks. **By default, none of that is visible on
> the response.**

> Router metadata is a **per-request opt-in** that adds an `openrouter_metadata`
> field to successful responses, capturing exactly what the router did.

Enabled with a request header:

```
X-OpenRouter-Metadata: enabled
```

> Any other value (including misspellings, empty strings, and unknown levels)
> falls back to `disabled`. The default behavior, when the header is absent, is
> `disabled`.

Response shape, verbatim from the docs:

```json
"openrouter_metadata": {
  "requested": "openai/gpt-4o-mini",
  "strategy": "direct",
  "summary": "available=1, selected=OpenAI",
  "attempt": 1,
  "is_byok": false,
  "endpoints": {
    "total": 1,
    "available": [
      { "provider": "OpenAI", "model": "openai/gpt-4o-mini", "selected": true }
    ]
  },
  "attempts": [
    { "provider": "OpenAI", "model": "openai/gpt-4o-mini", "status": 200 }
  ]
}
```

And the field reference confirms the gap explicitly:

> `requested` — The model slug (or alias) the client sent. **May differ from the
> provider/model that actually served the request.**

`attempts[]` is the field that matters for a falsifiable privacy claim: it records
*every* provider contacted, not just the successful one, so a request that failed
over to a fallback is visible rather than hidden.

**Consequence for the README.** The app can determine and even display the actual
upstream provider, but only by sending the metadata header on every request and
reading `openrouter_metadata.endpoints.available[].selected` (or `attempts[]`).
Without it, the app genuinely cannot tell the user which company received their
meal photo — which would silently break the "every destination that receives a
request is listed" promise the README makes.

---

## 5. Can a caller restrict which upstream providers may serve a request?

**Yes — comprehensively, and per request.** From
<https://openrouter.ai/docs/guides/routing/provider-selection>, the `provider`
object in the request body. Relevant fields, verbatim from the docs table:

| Field | Type | Default | Description |
| :-- | :-- | :-- | :-- |
| `order` | `string[]` | – | List of provider slugs to try in order (e.g. `["anthropic", "openai"]`) |
| `allow_fallbacks` | `boolean` | `true` | Whether to allow backup providers when the primary is unavailable |
| `only` | `string[]` | – | List of provider slugs to allow for this request |
| `ignore` | `string[]` | – | List of provider slugs to skip for this request |
| `data_collection` | `"allow"` \| `"deny"` | `"allow"` | Control whether to use providers that may store data |
| `zdr` | `boolean` | – | Restrict routing to only ZDR (Zero Data Retention) endpoints |
| `require_parameters` | `boolean` | `false` | Only use providers that support all parameters in your request |

Note `allow_fallbacks` defaults to **`true`** — by default OpenRouter *will*
silently route elsewhere if the preferred provider is unavailable. Pinning a
destination therefore requires **both** `only` and `allow_fallbacks: false`.

On `only`:

> You can allow only specific providers for a request by setting the `only` field
> in the `provider` object.

> Note that when you allow providers for a specific request, both restrictions
> apply: your account-wide allowed providers act as the ceiling, and the request's
> `only` list narrows within it. If no provider satisfies both, the request fails
> with a 404.

Same ratchet property as `zdr` — a per-request `only` can only narrow. It fails
closed with a 404 rather than falling back to an unlisted provider, which is the
correct failure mode for a falsifiable privacy claim: a misconfiguration produces
a visible error, not a silent extra destination.

Endpoint granularity is finer than "provider":

> When you use a base provider slug (e.g. `"google-vertex"`) in any provider
> routing field (`order`, `only`, or `ignore`), it matches **all** endpoints for
> that provider, including any variants or regions. […] To target a **specific**
> variant or region, use the full slug including the suffix (e.g.
> `"google-vertex/us-east5"` […]).

So the app could pin not just a company but a **region** — e.g.
`google-vertex/us-east5` — which is directly relevant to any GDPR-flavoured claim
the project may want to make later.

There is also enterprise-only in-region routing, noted for completeness and
because it is *not* available to this project
(<https://openrouter.ai/docs/guides/privacy/provider-logging>):

> For enterprise customers, OpenRouter supports in-region routing in the EU and
> US. When enabled for your account, your prompts and completions are processed
> within the selected region and do not leave it. […] This feature is only
> enabled for enterprise customers by request.

---

## What we could truthfully claim

Everything below is conditional on the app actually sending the stated request
fields. These are not aspirational — each maps to a quoted primary source above.

### Preconditions the implementation must meet

For any of the claims in this section to hold, every request would need to carry:

```jsonc
{
  "provider": {
    "zdr": true,               // ratchet: cannot be weakened by account settings
    "data_collection": "deny", // default is "allow" — must be explicit
    "only": ["<pinned-slug>"], // makes the destination nameable in the README
    "allow_fallbacks": false   // default is true — without this, fails over silently
  }
}
```

plus the header `X-OpenRouter-Metadata: enabled` if the app wants to *verify* and
display which provider served the request rather than merely constrain it.

If `only` + `allow_fallbacks: false` are **not** sent, the README cannot honestly
enumerate destinations, because the set is chosen at routing time by OpenRouter.
That is the crux of #654.

### Proposed README privacy-table row

With the pinning above in place, one row becomes two, because there are two
recipients:

| Destination | When | What is sent |
| :-- | :-- | :-- |
| [OpenRouter](https://openrouter.ai/) | **Only if you save your own OpenRouter API key** | The meal line you type on the multi-item add screen, or a meal photo you choose to read there, and your app language |
| *<pinned upstream provider>* | The same request, forwarded by OpenRouter | The same content — OpenRouter routes it to this provider and does not add to it |

The second row can only name a fixed provider if `only` + `allow_fallbacks: false`
are set. Otherwise it must read something like "whichever provider OpenRouter
selects at request time (visible in-app after each request)", which is weaker but
still falsifiable if the metadata header is used.

### Sentences that are defensible verbatim

Each of these is directly supported by a quote above.

- "OpenRouter does not store your prompts or responses unless you opt in; the app
  does not opt in." — supported by the Data Collection page's "OpenRouter does not
  store your prompts or responses, *unless* you opt in to one or both of the
  following", both listed as "Off by default".
- "OpenRouter states that it does not use inputs or outputs for model training."
  — Privacy Policy §1, verbatim: "OpenRouter does not use your Inputs or Outputs
  for model training."
- "Each request asserts zero data retention, which OpenRouter defines as the
  provider not storing your data for any period of time. This is a per-request
  parameter, so it cannot be weakened by any account-level setting." — supported
  by the ZDR page's definition and its "OR" semantics.
- "Each request also refuses providers that may store or train on the data
  (`data_collection: "deny"`)." — supported by the provider-selection table.
- "OpenRouter stores request metadata — token counts and latency — for every
  request. This does not include the content of your prompt or your photo." —
  Data Collection page, verbatim.
- "OpenRouter says it does not persist image files beyond the duration necessary
  to route the request, except as required for abuse detection, security, billing,
  or legal compliance." — Privacy Policy §7, and **the carve-out must be included**.

### Sentences that would be false or unsupportable

State these plainly so nobody reaches for them later:

- ❌ Reusing the Anthropic wording — images are "ephemeral and not stored beyond
  the duration of the API request" — for the OpenRouter path. OpenRouter's
  commitment has an explicit four-way exception. Not equivalent.
- ❌ "Your data is never stored anywhere." Even under ZDR, in-memory caching is
  excluded from the definition by OpenRouter's own stated stance, and request
  metadata is always retained.
- ❌ "Free models don't train on your data" *or* "free models always train on your
  data." Neither is documented as a platform rule. The honest statement is that
  free usage is governed by a separate consent setting and by per-model provider
  terms.
- ❌ Naming a single upstream provider without sending `only` +
  `allow_fallbacks: false`. Fallback routing is on by default.
- ❌ Any claim that OpenRouter guarantees provider behaviour. The Terms disclaim
  exactly that, in capitals.

### The honest framing of what changes

Today the README names Anthropic and quotes Anthropic's own image policy. Adding
OpenRouter means:

1. **One more company sees the photo** — OpenRouter itself, as router — even
   though it commits to not persisting it.
2. **The strongest available image-retention sentence gets weaker**, because
   OpenRouter's carve-out is real and must be disclosed.
3. **In exchange, the app gains an enforceable, per-request, account-independent
   ZDR + no-training assertion** that the direct Anthropic integration has no
   equivalent of, plus the ability to pin a region.

Whether that trade is worth making is the decision #654 asks for; this document
only establishes that the trade is describable without saying anything false.

---

## What I could not establish from primary sources

Listed rather than smoothed over.

1. **Whether OpenRouter retains prompt content for abuse detection on the default
   (non-opted-in) path.** The ZDR page says prompts "are not retained unless you
   specifically opt in to prompt logging" — unqualified. The Privacy Policy's
   image clause carves out "abuse detection, security, billing, or legal
   compliance". These are in tension for text and are never reconciled in one
   place. I could not find a document stating whether text prompts have the same
   carve-out as image files.
2. **The size threshold for Terms §6.3(b) "Processing-Related Storage".** The
   clause triggers where a request "cannot be processed in memory". No byte
   figure is published, so I cannot say whether a base64 meal photo of typical
   size crosses it. §6.3(c) says retention periods "vary by feature and are
   described in the applicable feature documentation" but the linked feature docs
   do not cover ordinary chat completions.
3. **A machine-readable per-endpoint data policy on the public API.** The public
   `/api/v1/models` and `/api/v1/models/{id}/endpoints` responses return
   `data_policy: null` for every model I sampled, including `:free` variants. The
   populated data lives at `/api/frontend/v1/all-providers`, which the docs page
   itself consumes but which is not published as a stable public API and carries
   no compatibility guarantee. Only `/api/v1/endpoints/zdr` is documented as
   programmatically available ("this list is also available progammatically via
   …"), and it is a ZDR allow-list, not a full policy feed. An app that wanted to
   *display* the policy of the serving provider would be relying on an
   undocumented endpoint.
4. **What `requiresUserIDs: true` means in practice.** It appears in the provider
   policy JSON for Anthropic and OpenAI and implies OpenRouter forwards some user
   identifier upstream, which would be privacy-relevant for a no-account app. I
   found no prose documentation of this field anywhere in the docs, and I am not
   willing to guess what identifier is sent. **This needs answering before any
   "nothing identifying is sent" claim is made.**
5. **The exact labels and defaults of the free-vs-paid training toggles.**
   `https://openrouter.ai/settings/privacy` requires authentication, so I could
   confirm from the docs only that "There are separate settings for paid and free
   models" — not their default values. Since the app should assert
   `data_collection: "deny"` per request regardless, this does not block anything,
   but it means I cannot state what an unconfigured account does.
6. **Whether any OpenRouter-side content moderation inspects prompts by default.**
   Guardrails are documented as an opt-in feature; I found nothing stating whether
   a baseline filter runs on all traffic.
