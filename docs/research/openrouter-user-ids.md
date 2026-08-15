# What `requiresUserIDs` means, and what OpenRouter forwards upstream

Research notes gathered 2026-08-15 against primary sources: OpenRouter's own
documentation, privacy policy, provider-policy endpoint and API reference;
Anthropic's and OpenAI's own developer documentation; and — for the questions the
documentation does not answer — OpenRouter's **own documented debug facility**,
which returns "the exact request body that was sent to the upstream provider".
No blog posts, no third-party summaries.

Written to resolve
[#664](https://github.com/simonoppowa/OpenNutriTracker/issues/664), which was
opened by open question 4 of
[`openrouter-data-handling.md`](openrouter-data-handling.md): *"What
`requiresUserIDs: true` means in practice … I found no prose documentation of
this field anywhere in the docs, and I am not willing to guess what identifier is
sent. This needs answering before any 'nothing identifying is sent' claim is
made."*

The deliverable is **what could truthfully be claimed** about identifiers — not a
recommendation about whether to adopt OpenRouter.

Where OpenRouter's rendered docs are JavaScript-heavy, the underlying Markdown
was fetched directly (every OpenRouter docs page is served verbatim at the same
URL with a `.md` suffix), so the quotes below are source text rather than a
paraphrase of a rendering. Anthropic's and OpenAI's docs sites both do the same.

---

## Summary

The short answer to the issue title is **yes, and you cannot turn it off.**

1. **`requiresUserIDs` is never documented in prose, anywhere.** The token appears
   in OpenRouter's provider-policy JSON and nowhere else — not in the docs, not
   in the API changelog, not in the privacy policy. Its *meaning*, however, is
   documented under a different name: the docs speak of a provider that
   "requires a user identity".
2. **For a provider flagged `requiresUserIDs: true`, OpenRouter populates a
   per-user identifier field in every upstream request** — whether or not the
   caller supplies one. Observed directly: first-party Anthropic receives
   `metadata.user_id`, OpenAI receives `user`.
3. **The caller cannot see the value.** OpenRouter redacts it from its own debug
   echo. The docs describe it only as "the hashed identity", and say the raw
   caller-supplied value is "never" forwarded. I could not verify the hash
   construction, and OpenRouter does not describe it.
4. **The caller can influence it but not suppress it.** Sending `user` folds your
   value into the hashed identity; omitting `user` substitutes a stable
   account-level identity. There is no third option and no opt-out flag.
5. **The only lever that removes the identifier is provider selection.** Routing
   to a provider with `requiresUserIDs: false` sends `metadata.user_id: null`
   (observed on Amazon Bedrock). Neither `zdr: true` nor
   `data_collection: "deny"` is that lever — Google Vertex is a zero-retention
   provider that *does* receive a user identity.
6. **Anthropic and OpenAI both say this is optional, not required.** Anthropic:
   "The choice to pass IDs to Anthropic through the API is up to you." OpenAI:
   safety identifiers "are recommended … but they are not required." So
   `requiresUserIDs: true` is OpenRouter's own classification of a provider
   relationship, not a restatement of either provider's published rule.
7. **Nothing lands on the user's device.** The identity is minted and hashed
   server-side at OpenRouter from account state. The device-side consequence is
   the inverse: to get per-user isolation the *app* would have to mint and
   persist a stable pseudonym locally — which is exactly the device identifier
   the README currently says does not exist.

---

## 1. What does `requiresUserIDs` mean?

**No prose documentation of the field exists.** Searching OpenRouter's complete
documentation corpus (<https://openrouter.ai/docs/llms-full.txt>, 3.7 MB,
fetched 2026-08-15) for the string `requiresUserIDs` returns **zero matches**.
The API changelog at <https://openrouter.ai/docs/changelog.md> — "generated
automatically from OpenAPI specification diffs when releases ship" — contains no
entry for it either. Web search finds no announcement, blog post or forum answer
naming the field. This is a firm negative finding, not a gap in searching.

The field is real and live. From
<https://openrouter.ai/api/frontend/v1/all-providers> on 2026-08-15 (81
providers):

```json
"Anthropic":  {"training": false, "trainingOpenRouter": false, "retainsPrompts": true,  "retentionDays": 30, "canPublish": false, "requiresUserIDs": true}
"OpenAI":     {"training": false, "trainingOpenRouter": false, "retainsPrompts": true,                       "canPublish": false, "requiresUserIDs": true}
"Google":     {"training": false, "trainingOpenRouter": false, "retainsPrompts": false,                      "canPublish": false, "requiresUserIDs": true}
"Amazon Bedrock": {"training": false, "trainingOpenRouter": false, "retainsPrompts": false,                  "canPublish": false, "requiresUserIDs": false}
```

Nine of the 81 providers carry `requiresUserIDs: true`, and the property is
present on every provider (never absent):

| `requiresUserIDs: true` (9) | Anthropic, Claude Platform on AWS, Google *(slug `google-vertex`)*, Liquid, Meta, OpenAI, Runway, Xiaomi, xAI |
| :-- | :-- |
| `requiresUserIDs: false` (72) | everyone else, including Amazon Bedrock and Google AI Studio |

Two details are easy to get wrong here. **"Google" is Vertex, not AI Studio** —
`google-vertex` is `true`, `Google AI Studio` is `false`. And **Bedrock is
`false` while "Claude Platform on AWS" is `true`**; they are distinct providers
in this list.

The endpoint is the same one OpenRouter's own docs consume. From
<https://openrouter.ai/docs/guides/privacy/provider-logging.md>, the page's
embedded React component:

> ```js
> fetch("https://openrouter.ai/api/frontend/v1/all-providers", …)
> ```

— and its table renders exactly three columns, `Provider`, `Data Retention`,
`Train on Prompts`. **`requiresUserIDs` is fetched by OpenRouter's own privacy
documentation page and then not displayed.** That is the whole reason this
question had to be answered by experiment.

### The meaning, documented under another name

The docs never say "requires user IDs", but they do say **"requires a user
identity"**, in a sentence that appears verbatim in the OpenAPI schema, in three
SDK references, and in the User Tracking cookbook. From the request schema for
`POST /api/v1/chat/completions`
(<https://openrouter.ai/docs/api/api-reference/chat/create-a-chat-completion>,
reached by redirect from `/docs/api-reference/chat-completion`):

```yaml
user:
  description: >-
    Per-end-user identifier for abuse isolation. Use a stable ID, hash,
    or pseudonym. When a provider requires a user identity, OpenRouter
    folds it into the hashed identity sent upstream and never forwards
    it raw. If omitted, requests use an account-level identity, so
    provider policy blocks can affect the whole account.
  example: user-123
  type: string
```

That is the definition. `requiresUserIDs: true` is the machine-readable form of
"this provider requires a user identity", and it selects which upstream requests
get an identity field populated.

An older, shorter gloss survives on the API overview page
(<https://openrouter.ai/docs/api_reference/overview>), in the request-type
listing:

> ```ts
> user?: string; // A stable identifier for your end-users. Used to help detect and prevent abuse.
> ```

The Responses API has the same concept under OpenAI's newer name,
`safety_identifier`, with an identical description
(<https://openrouter.ai/docs/client-sdks/python/sdks/betaresponses/README>):

> `safety_identifier` — Recommended per-end-user identifier for abuse isolation.
> Use a stable ID, hash, or pseudonym. When a provider requires a user identity,
> OpenRouter folds it into the hashed identity sent upstream and never forwards
> it raw. If omitted, requests use an account-level identity, so provider policy
> blocks can affect the whole account.

The same page also still carries the legacy `user` field with the pre-hashing
wording and a length cap:

> A unique identifier representing your end-user, which helps distinguish between
> different users of your app. This allows your app to identify specific users in
> case of abuse reports, preventing your entire app from being affected by the
> actions of individual users. Maximum of 256 characters.

---

## 2. What value is actually sent upstream?

**Documented answer:** "the hashed identity". **Observed answer:** a real value in
`metadata.user_id` (Anthropic) or `user` (OpenAI), whose contents OpenRouter
deliberately withholds from the caller.

### Method

OpenRouter documents a debug switch at
<https://openrouter.ai/docs/api_reference/errors-and-debugging>:

> OpenRouter provides a `debug` option that allows you to inspect the exact
> request body that was sent to the upstream provider.

> ```ts
> type DebugOptions = {
>   echo_upstream_body?: boolean; // If true, returns the transformed request body sent to the provider
> };
> ```

Streaming only. I sent `max_tokens: 1` requests with `debug.echo_upstream_body:
true`, pinning the provider so routing could not confound the result
(`provider: {order: [...], allow_fallbacks: false}`), with and without a caller
`user` value. Results below are the returned upstream bodies verbatim.

### Anthropic (first-party, `requiresUserIDs: true`)

*Without* any `user` field in the request:

```json
{
  "messages": [{"role": "user", "content": "hi"}],
  "model": "claude-haiku-4-5-20251001",
  "stream": true,
  "metadata": {"user_id": "<redacted>"},
  "max_tokens": 1,
  "stop_sequences": []
}
```

*With* `"user": "probe-user-abc123"` — byte-identical, still `"<redacted>"`.

### OpenAI (`requiresUserIDs: true`)

*Without* any `user` field in the request:

```json
{
  "model": "gpt-4o-mini",
  "stream": true,
  "stream_options": {"include_usage": true},
  "user": "<included to upstream but not in debug info>",
  "messages": [{"role": "user", "content": "hi"}],
  "max_tokens": 1
}
```

*With* `"user": "probe-user-abc123"` — identical.

### Amazon Bedrock (`requiresUserIDs: false`)

```json
{
  "messages": [{"role": "user", "content": "hi"}],
  "metadata": {"user_id": null},
  "max_tokens": 1,
  "stop_sequences": [],
  "anthropic_version": "bedrock-2023-05-31",
  "anthropic_beta": ["fine-grained-tool-streaming-2025-05-14"]
}
```

`null` **with or without** a caller-supplied `user`. On a `requiresUserIDs:
false` provider the caller's `user` value is dropped rather than forwarded.

### Google Vertex (`requiresUserIDs: true`, `retainsPrompts: false`)

```json
{
  "messages": [{"role": "user", "content": "hi"}],
  "stream": true,
  "metadata": {"user_id": "<redacted>"},
  "max_tokens": 1,
  "stop_sequences": [],
  "anthropic_version": "vertex-2023-10-16"
}
```

Populated, on a **zero-retention** provider. Retention policy and identity policy
are orthogonal.

### What this establishes, and what it does not

Established: on `requiresUserIDs: true` providers a per-user identifier field is
**always** populated upstream; on `requiresUserIDs: false` providers it is
**never** populated. Both hold independently of what the caller sends.

Not established: the actual value. OpenRouter substitutes `"<redacted>"` /
`"<included to upstream but not in debug info>"` in its own echo, so the hash
input is unobservable from the client side. The docs assert it is a hash and
assert the raw caller value is not forwarded; **neither claim is independently
verifiable from outside**, and OpenRouter publishes no description of the hash
construction, its inputs, its salt, or whether it is stable across time. Whether
it derives from the account, the API key, the workspace, or some combination is
undocumented. It is at minimum stable enough to serve as a per-account or
per-end-user abuse handle, since that is its stated purpose.

One adjacent observation worth recording: on DeepInfra the upstream body carried
`"prompt_cache_key": "<included to upstream but not in debug info>"` — a second
opaque, OpenRouter-derived value forwarded to providers and hidden from the
caller. It is a cache-routing key rather than an abuse identifier, but it is
another field the caller neither supplied nor can inspect.

---

## 3. Does the caller supply it, or does OpenRouter generate one?

**Both, and the caller's role is optional.** The schema marks `user` optional —
the chat-completions request body lists only `messages` as `required`. Omitting
it does not fail the request; every probe above ran without a `user` field and
returned normally.

What happens on omission is stated plainly, and confirmed by probe. From
<https://openrouter.ai/docs/cookbook/administration/user-tracking>:

> Send a stable per-end-user identifier with every request: `user` on chat
> completions, or `safety_identifier` on the Responses API. A client-side hash or
> pseudonym works — when a provider requires a user identity, OpenRouter folds it
> into the hashed identity sent upstream and never forwards the raw value.
> **Requests that include neither field share a single account-level identity
> upstream**, so a provider policy block triggered by one end-user can affect your
> whole account.

So the three states are:

| Caller sends | What goes upstream (on a `requiresUserIDs: true` provider) |
| :-- | :-- |
| `user` / `safety_identifier` | hashed identity incorporating the caller's value |
| nothing | a **single account-level identity**, shared by every request on the account |
| nothing, and provider is `requiresUserIDs: false` | field present but `null` |

The middle row is the one that matters. **"Send nothing" is not "send nothing" —
it is "send the account identity".** The absence of a `user` parameter is not the
absence of an identifier.

On what to supply, if supplying:

> Include a `user` parameter in chat-completions requests with a stable
> identifier for your end-user. This can be a user ID, client-side hash,
> pseudonym, or another stable identifier.

and, under "Consider Privacy":

> * Use internal user IDs rather than exposing personal information
> * Avoid including personally identifiable information in user identifiers
> * Consider using anonymized identifiers for better privacy protection

---

## 4. Can it be suppressed or opted out of?

**No — not by any request parameter or account setting I could find.**

- No request field disables it. The `provider` preferences object documents
  `data_collection: "allow" | "deny"` and the request-level `zdr` boolean
  (<https://openrouter.ai/docs/guides/routing/provider-selection>,
  <https://openrouter.ai/docs/guides/features/zdr>). Neither keys on
  `requiresUserIDs`, and no `require_*`-style filter for it exists in the
  provider-preferences schema.
- No account setting disables it. The privacy documentation
  (<https://openrouter.ai/docs/guides/privacy/data-collection>,
  <https://openrouter.ai/docs/guides/privacy/provider-logging>) describes exactly
  three user-facing controls — prompt logging, OpenRouter's use of
  inputs/outputs, and training-provider routing. None concerns identity
  forwarding.
- Sending an empty or omitted `user` does not suppress it; it substitutes the
  account identity (§3, confirmed by probe).

**The only effective lever is provider selection**, and it is indirect: route
only to providers with `requiresUserIDs: false`, and `metadata.user_id` arrives
`null`. Two cautions on relying on that:

1. **ZDR is not a proxy for it.** Google Vertex is `retainsPrompts: false` *and*
   `requiresUserIDs: true`. A request asserting `zdr: true` can land there. In my
   probes `zdr: true` and `data_collection: "deny"` both routed Claude to Amazon
   Bedrock — which happens to be `requiresUserIDs: false` — but that is a routing
   outcome, not a guarantee. (This matches the earlier finding in
   `openrouter-data-handling.md` that unpinned Claude requests were served by
   Bedrock every time.)
2. **There is no supported way to express the constraint.** Achieving it means
   pinning providers by slug with `allow_fallbacks: false`, or filtering client
   side against `/api/frontend/v1/all-providers` — an **undocumented frontend
   endpoint with no stability guarantee**, as recorded in
   `openrouter-data-handling.md`. A guarantee built on either is a guarantee
   OpenRouter has not promised to keep.

---

## 5. What do Anthropic and OpenAI actually say they require?

**Both say it is optional.** This is the finding that most complicates the
`requiresUserIDs` name.

### Anthropic

The API field, from <https://docs.claude.com/en/api/messages> —
`metadata.user_id`, and note it is `optional`:

> An external identifier for the user who is associated with the request.
>
> This should be a uuid, hash value, or other opaque identifier. Anthropic may
> use this id to help detect abuse. Do not include any identifying information
> such as name, email address, or phone number.

The guidance aimed at customers who serve their own end users, from
<https://support.claude.com/en/articles/9199617-api-safeguards-tools> ("API
Safeguards Tools", dated March 16, 2026), under **Basic Safeguards**:

> Store IDs linked with each API call, so if you need to pinpoint specific
> violative content you have the ability to find it in your systems.

> Consider assigning IDs to users, which can help you track specific individuals
> who are violating Anthropic's AUP, allowing for more targeted action in cases
> of misuse.

> **The choice to pass IDs to Anthropic through the API is up to you.** But, if
> provided, we can more precisely pinpoint violations. To help protect end-users'
> privacy, any IDs passed should be cryptographically hashed.

Anthropic frames it as a recommendation with a privacy instruction attached
(hash them), not a requirement.

### OpenAI

From <https://developers.openai.com/api/docs/guides/safety-best-practices>
(same content at `platform.openai.com/docs/guides/safety-best-practices`), under
**Implement safety identifiers**:

> Sending safety identifiers in your requests can help OpenAI monitor and detect
> abuse. This allows OpenAI to provide your team with more actionable feedback in
> the event that we detect any policy violations in your application.

> Safety identifiers can also help your team respond to abuse faster. They create
> a stable way to trace activity back to an individual end user and reduce the
> chance that one user's misuse disrupts access for your broader organization.

> A safety identifier should be a string that uniquely identifies each user.
> **Hash the username or email address in order to avoid sending us any
> identifying information.** If you offer a preview of your product to
> non-logged in users, you can send a session ID instead.

> **Safety identifiers are recommended for products where individual users
> interact with a model, but they are not required.** Include safety identifiers
> in your API requests with the `safety_identifier` parameter.

### What follows

Neither provider's published documentation states a hard requirement. So
`requiresUserIDs: true` is best read as **OpenRouter's own classification of its
commercial relationship with that provider** — plausibly a term of the
aggregator/reseller agreement rather than of the public API — and OpenRouter has
published nothing describing it.

Practically, the direction of both providers' advice and OpenRouter's
implementation agree: the identifier should be an opaque hash, and its purpose is
abuse attribution. What no primary source establishes is *why OpenRouter cannot
omit it*, given that both providers say it is optional. **That gap is
documentary, not resolvable by testing**, and it should be stated as unknown
rather than guessed at.

---

## 6. Does any of this reach the end user's device?

**No value flows to the device, and the mechanism is entirely server-side at
OpenRouter.** The identity is minted, hashed and attached inside OpenRouter's
routing layer; the client sees only `"<redacted>"` even when it explicitly asks
for the upstream body. Nothing is written to the device, no cookie or advertising
identifier is involved, and the app is never handed an identifier to store.

The device-side consequence runs the other way, and is the part that matters for
the README:

- **Do nothing** and OpenRouter substitutes the account-level identity. On a
  BYOK design like this app's — where the user pastes their own key, held in the
  Android Keystore / iOS Keychain — that account is *the individual user's own
  account*. So the account-level identity is already, in effect, a stable
  per-user identifier upstream. It cannot correlate two OpenNutriTracker users
  with each other (there is no shared project account), but it does give the
  upstream provider a stable handle for that person's requests.
- **Opt into per-user isolation** and the app must mint and persist a stable
  pseudonym locally, then send it on every request. That is precisely a *device
  identifier* — a new, app-generated, persistent local ID whose only purpose is
  to be transmitted. It would have to be created, stored and disclosed.

There is no configuration in which the app both talks to a `requiresUserIDs:
true` provider through OpenRouter and sends no per-user identity upstream.

Worth noting for completeness: OpenRouter's privacy policy
(<https://openrouter.ai/privacy>, Last Updated July 6, 2026) describes what is
transmitted to Model Providers purely in terms of Inputs —

> When you use our Service, we transmit your Inputs to the Model Provider(s) you
> select.

— and **says nothing about forwarding a user identity**. The only documentation
of this behaviour is the API field description and the User Tracking cookbook
page. The privacy policy is not where a reader would learn it.

---

## What we could truthfully claim about identifiers

The README today says, at line 150 (in the paragraph about the food-database
backend, immediately after the USDA/BLS/Supabase sentences, and followed by
"Search results are cached locally and pruned after 90 days"):

> Requests carry a User-Agent naming the app, platform, and version, with no user
> or device identifier.

and at line 156:

> No advertising ID and no cross-app tracking …

**Neither sentence is falsified by this research as currently scoped**, and that
scoping is worth defending. The first sits inside the food-database paragraph and
reads as a statement about search requests to the Supabase backend. The second is
about advertising and cross-app tracking, which none of this is: the OpenRouter
identity is not an advertising ID, is not shared with other apps, and is not used
for tracking in the ad-tech sense. The direct Anthropic path shipping today sends
no `metadata.user_id` at all, because the app does not set one.

What changes if an OpenRouter path is added:

**Claims that would still hold, unqualified**

- No advertising ID, no cross-app tracking, no `NSPrivacyTracking`. Unaffected.
- The project never sees the key, never proxies the request, never pays for it.
  Unaffected — BYOK is orthogonal.
- Only the typed line or the picked photo is sent; never diary, profile or
  history. Unaffected.
- OpenNutriTracker does not generate, store or transmit a user or device
  identifier — **provided the app declines to set `user`**. This stays literally
  true because the identity is minted at OpenRouter, not on the device.

**Claims that would need qualification**

- Any sentence generalising "no user identifier is sent" **beyond the
  food-database backend** to cover the AI path. On a `requiresUserIDs: true`
  provider a stable per-user identity is attached to every request. The app does
  not create it and cannot remove it.
- "The request carries only what you typed" — accurate about content, incomplete
  about metadata, once an opaque per-user identity rides along.
- Anything asserting the app controls what leaves the device on the AI path. It
  controls the body; OpenRouter adds fields to it.

**Wording that would be defensible** (illustrative, not a proposed diff)

> Through OpenRouter, some upstream providers require a per-user identity.
> OpenRouter attaches an opaque, hashed identifier derived from your own
> OpenRouter account; the app neither creates nor sends one, and it never touches
> your device. It cannot be switched off from the app, and it identifies your
> account to that provider for abuse detection.

Three things that wording is careful about, each for a reason:

- It says **"derived from your own OpenRouter account"**, not "anonymous". Under
  BYOK the account is the person.
- It says **"cannot be switched off"** rather than offering a mitigation. Pinning
  to `requiresUserIDs: false` providers works today but rests on an undocumented
  endpoint and on OpenRouter's routing behaviour, neither of which is promised.
- It does **not** claim the identifier is unlinkable or non-identifying. We know
  it is called a hash; we have not seen it, and OpenRouter does not say what goes
  into it.

**The claim that cannot be made either way:** that the identity is anonymous, or
that it is not personal data. The value is unobservable, its construction is
undocumented, and it is by design stable and attributable — that is its entire
purpose.

---

## What I could not establish from primary sources

Stated plainly, because each one blocks a stronger claim:

1. **Any prose definition of `requiresUserIDs`.** Not documented anywhere I could
   find — not in 3.7 MB of documentation, not in the API changelog, not in the
   privacy policy, not in any announcement discoverable by search. Its meaning
   here is inferred from the parallel phrase "when a provider requires a user
   identity" plus observed behaviour, and that inference is strong but it is an
   inference.
2. **The actual value sent upstream.** Redacted by OpenRouter in its own debug
   echo. Unobservable from the client.
3. **How the hash is constructed** — inputs, salt, rotation, stability over time,
   whether it is per-account, per-key or per-workspace. Undocumented. Therefore
   no claim about linkability or reversibility is available in either direction.
4. **Whether OpenRouter's assertion that the raw `user` value is "never
   forwarded" is true.** It is asserted in the schema description; it cannot be
   externally verified, since the field is redacted in the echo.
5. **Why OpenRouter treats an identity as mandatory for Anthropic and OpenAI**
   when both providers publish that it is optional. Presumably a term of
   OpenRouter's aggregator agreements, but no primary source says so and I will
   not guess.
6. **Whether the `requiresUserIDs` classification is stable.** It lives on
   `/api/frontend/v1/all-providers`, which is undocumented, unversioned, and
   carries no compatibility guarantee. A provider could flip from `false` to
   `true` without any changelog entry, silently invalidating a claim built on
   today's values.
