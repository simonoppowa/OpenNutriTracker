# Which models should join the OpenRouter list

Research notes gathered **2026-08-20** against primary sources only —
OpenRouter's own `/api/v1/models`, `/api/v1/models/{id}/endpoints`,
`/api/v1/providers` and `/api/frontend/v1/all-providers` (queried by `curl`, no
API key, no billed inference call), OpenRouter's own documentation and Terms of
Service, and each vendor's own legal pages fetched from the vendor's own
domain. Nothing here rests on a leaderboard, a model card, a blog post or a
third-party write-up. Where a page refused automated fetching it is named in
[Not verified](#not-verified) rather than replaced with a secondary source.

Written to answer the maintainer's question — **the curated OpenRouter list has
two entries, both Anthropic-served; what should be added?** The constraints are
settled elsewhere and are not re-argued: vision is required, `tool_choice` must
be honoured, `strict: true` is unusable, no model may emit a nutrition value,
and every request carries `require_parameters: true`, `data_collection: "deny"`
and a vendor pin with `allow_fallbacks: false`
([`ai_model_catalogue.dart`](../lib/core/utils/ai_model_catalogue.dart),
[`openrouter_meal_items_api.dart`](../lib/features/add_meal/data/openrouter_meal_items_api.dart),
[#663](https://github.com/simonoppowa/OpenNutriTracker/issues/663)).

**Nothing below is a decision, and nothing below can be.** The catalogue's own
rule stands: membership requires a behavioural screen against a photo corpus,
because a capability flag is not fitness. That has now been measured three
times — `openai/gpt-5.4-nano` advertised everything and returned empty for both
food-bearing photos in the #669 slice; `gpt-5.4-mini` turned one photo of a
bunch of bananas into twelve `banana` rows
([`ai-openai-behavioural-screen.md`](ai-openai-behavioural-screen.md)). No
screen was run here. Section G ranks **screening candidates**, in the order I
would spend the photo corpus on them, and that is the whole of the output.

## How this relates to `ai-model-candidates.md`

[`ai-model-candidates.md`](ai-model-candidates.md) answered almost this
question on 2026-08-16 for
[#668](https://github.com/simonoppowa/OpenNutriTracker/issues/668) and
concluded "no additional vendor clears every bar, and the catalogue should stay
as it is." Everything in it was re-checked against the live documents and the
live API. The summary:

| Its finding | Status now |
| --- | --- |
| Structural funnel: 216 capable, 124 pinnable across 17 vendors | **Re-verified.** 216 and 125 across the same 17 vendors ([Section B](#b-the-funnel-re-run)) |
| No newer or cheaper Anthropic model that pins | **Re-verified.** Still no Haiku 5; `claude-3-haiku` is still Bedrock-only |
| Google barred by Cloud SST §20(d) | **Re-verified verbatim** in the live document, renumbered from §19 |
| Sakana barred on age + EEA exclusion | **Re-verified verbatim**, and a third bar found (training) |
| Meta barred by Model API ToS §10.1 | **Could not re-verify** — the document 500s to every request ([Not verified](#not-verified)) |
| xAI ruled out because "no prohibition found" is weaker than a carve-out | **Overturned as a standard**, and replaced by a different, stronger objection ([Section D](#d-xai-re-examined)) |
| OpenAI barred by the *Keep minors safe* clause | **Overturned** — by [#679](https://github.com/simonoppowa/OpenNutriTracker/issues/679), not by me ([Section C](#c-the-standard-that-changed)) |
| Mistral ruled out on its professional-advice clause alone | **Stale in both directions** ([Section E3](#e3-no-carve-out-and-the-rest-of-the-page)) |
| Z.AI ruled out on individual-user training clauses | **Weaker than recorded** — its own terms exempt API developers |
| Alibaba's terms "contain no usage-policy treatment of health … at all" | **Wrong.** §4.48 contains a medical restriction |
| `anthropic/claude-on-aws` will leak through `only: ["anthropic"]` | **No longer true.** It is a top-level slug now ([Section F](#f-what-the-routing-block-buys-now)) |
| `:batch` unusable because asynchronous | **Re-verified, and now moot** — the Batch API is documented text-only |
| Anthropic Commercial Terms carry no visible date | **Resolved.** Effective June 17, 2025 |

## Bottom line up front

1. **Applying the standard the project actually shipped admits OpenAI on the
   OpenRouter path, and the two strongest candidates are the two models the app
   already ships direct.** `openai/gpt-5.6-luna` and `openai/gpt-5.6-terra` each
   have a first-party endpoint tagged `openai`, each advertises `tools`,
   `tool_choice` and `max_tokens`, and `openai` is tagged `training: false`, so
   they survive `require_parameters: true` and `data_collection: "deny"` under
   `only: ["openai"]`. The policy work is already done and already accepted
   ([`ai-openai-policy-fit.md`](ai-openai-policy-fit.md),
   [#679](https://github.com/simonoppowa/OpenNutriTracker/issues/679)); the
   behavioural work is already done for these exact two model names
   ([#684](https://github.com/simonoppowa/OpenNutriTracker/issues/684),
   [#719](https://github.com/simonoppowa/OpenNutriTracker/issues/719)) — but
   over a **different route**, which is exactly the confound #669 and #684
   disagreed over. This is the least new evidence any candidate needs.
2. **The xAI re-examination changes the reasoning and, in the end, not the
   answer — but the objection is now a data clause the earlier note never
   looked at, not the absence of a policy.** SpaceXAI's enterprise terms —
   the document OpenRouter itself names as the Model Terms for `xai` — carry a
   warranty not to submit Personal Data except through the ZDR-Enabled API. The
   app's pin reaches the plain `xai` endpoint, and a meal photograph is personal
   data. **This is fixable**: OpenRouter documents a `zdr: true` routing flag,
   every Grok model carries an `xai/zdr` endpoint at the same price, and
   OpenRouter names SpaceXAI as one of the model groups ZDR can be enforced
   for. So xAI is not ruled out by policy silence; it is gated on a routing
   change the app has not made. See [Section D](#d-xai-re-examined).
3. **Two of the previous note's xAI quotes stop one clause short, and the
   missing clauses cut against it.** The training sentence continues *"subject
   to disclosures to Customer and Customer-controlled user settings"*, and the
   30-day deletion sentence continues into three exceptions including
   *"reasonably necessary for safety, security, compliance, moderation, abuse
   prevention, or investigation"*. Both are accurate as far as they go and both
   are weaker than they read.
4. **The E1 rejections hold, and I checked rather than assumed.** Google Cloud
   Service Specific Terms §20(d) is present verbatim in the version last
   modified 29 July 2026; Sakana's age and EEA clauses are present verbatim.
   Meta's document is unreachable from here, so its exclusion now rests on a
   quote nobody has re-read — say that plainly rather than carry it forward as
   settled.
5. **Mistral is the interesting correction, and it moves both ways.** Under
   #679's standard its professional-advice clause is a conduct test the app
   does not meet, so the E3 rule-out fails — but its Commercial Terms §4.2
   reserves training *"when you … have not opted-out of training on a Mistral AI
   Product set to opt-in by default"*, which is a straight E2-grade conflict
   with OpenRouter's `training: false` tag. It swaps a bad reason for a real
   one, and stays out.
6. **`claude-on-aws` is now its own top-level provider slug**, not
   `anthropic/claude-on-aws`. It is attached to `claude-sonnet-5`,
   `claude-opus-5` and others today — so the previous note's prediction came
   true — but because it is no longer a variant *under* `anthropic`, the
   documented base-slug rule means `only: ["anthropic"]` does not match it and
   `_warnIfThePinDidNotHold` will not false-alarm. The hazard resolved itself.
7. **Nothing here can be added on documentation.** Every candidate below still
   needs the photo screen, and two of the ranked candidates
   (`x-ai/grok-4.6`, `x-ai/grok-4.5`) carry `reasoning.mandatory: true`, which
   interacts badly with the client's fixed `max_tokens: 1024` and should be
   screened for truncation specifically.

## A. What the app actually sends, checked against the docs

Re-read from [`openrouter_meal_items_api.dart`](../lib/features/add_meal/data/openrouter_meal_items_api.dart)
and matched line by line against OpenRouter's own
[Provider Routing](https://openrouter.ai/docs/features/provider-routing) page,
because three of the four filters below turn on wording that has changed since
the last pass.

- `require_parameters: true` — *"providers that don't support all the LLM
  parameters specified in your request can still receive the request, but will
  ignore unknown parameters. When you set `require_parameters` to `true`, the
  request won't even be routed to that provider."* The page also now names the
  soft-preference set used when the flag is *off*: `tools`, `response_format`
  and `verbosity`. `tool_choice` is still not in it, so the client comment is
  still right about why the flag is necessary.
- `data_collection: "deny"` — *"use only providers which do not collect user
  data"*, against `allow` = *"allow providers which store user data
  non-transiently and may train on it"*. Still keyed on training, not
  retention: `anthropic` is `retainsPrompts: true, retentionDays: 30` and is
  reachable under `deny`. Across all 80 provider records only three carry
  `training: true` — `deepseek`, `liquid`, `nvidia` — unchanged. The page still
  warns the tags are *"not a definitive source of third party data policies, but
  represents our best knowledge."*
- `only` + `allow_fallbacks: false` — base-slug matching is unchanged: *"it
  matches **all** endpoints for that provider, including any variants or
  regions"*, and *"service tier endpoints (e.g. `openai/priority`,
  `google-vertex/flex`) are **not** matched by base slugs."*
- **The parameter the app sends that nobody checked: `max_tokens`.** Every
  first-party endpoint of every candidate below lists `max_tokens` in its
  `supported_parameters`. Azure's endpoints for the same models list
  `max_completion_tokens` instead — so with `require_parameters: true` a pin
  that ever reached Azure would 404. It cannot, under `only: ["openai"]`, but
  it is worth knowing that the pin is load-bearing for capability and not only
  for policy.

## B. The funnel, re-run

Every figure from OpenRouter's own API, queried 2026-08-20. The right-hand
column is `ai-model-candidates.md`'s figure from 2026-08-16.

| Stage | Models left | Was |
| --- | --- | --- |
| Listed on `/api/v1/models` | **414** | 413 |
| …with `image` in `architecture.input_modalities` | 245 | 245 |
| …also listing `tools` **and** `tool_choice` | **216** | 216 |
| …excluding 55 `:batch` variants and 10 `~vendor/…-latest` aliases | 151 | — |
| …with a first-party endpoint that itself advertises `tools` + `tool_choice` | 127 | — |
| …whose first-party provider is not tagged `training: true` | **125** | 124 |

The 17 surviving vendors are identical to the previous pass: `openai` (36),
`qwen`/Alibaba (21), `google` (18), `anthropic` (13), `mistralai` (8),
`bytedance-seed` (6), `x-ai` (5), `moonshotai` (4), `z-ai` (3), `sakana` (2),
`meta` (2), `nex-agi` (2), `minimax` (1), `stepfun` (1), `xiaomi` (1), `rekaai`
(1), `amazon` (1). Qwen gained one model; nothing else moved. **The structural
screen has not drifted in four days, and the collapse from 125 to 13 was, and
still is, entirely policy.**

Two structural notes worth carrying:

- **`:batch` is now excluded by documentation, not by inference.** OpenRouter's
  Batch API Quickstart states under *Limitations* that the API *"is currently
  text-only"* and that *"validation rejects any request that carries image,
  audio, video, or file content parts."* The previous note excluded batch
  because it is asynchronous, which is true and sufficient; it is now also
  simply unable to carry the photo.
- **Only Google prices images separately.** 29 model records carry a non-zero
  `pricing.image` field and every one of them is a Gemini or Gemma model. For
  Anthropic, OpenAI, xAI, Mistral, Alibaba and everyone else on the shortlist,
  an image is billed as prompt tokens and OpenRouter publishes no per-image
  rate. That matters for [Section G](#g-the-ranking).

## C. The standard that changed

`ai-model-candidates.md` §E3 rejected six vendors under a single heading:
*"Ruled out on the absence of any policy to rely on."* Its stated rationale is
that *"'no prohibition found' is weaker than Anthropic's explicit carve-out"*,
and that for a project whose defence is *"the vendor says in writing that
wellness advice is out of scope"*, silence is the rule-out.

[#679](https://github.com/simonoppowa/OpenNutriTracker/issues/679) then
accepted OpenAI as a shipping first-party provider on exactly the ground E3
rejects. The catalogue records the reversal in its own doc comment: *"OpenAI
offers no carve-out, only the absence of a prohibition, so the defence is
factual — the app gives no advice."*
[`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) is explicit that it is
applying the same test E3 used and reaching the opposite result: it notes the
project *"declined xAI on the same reasoning"* and argues OpenAI *"is not
barred; it is simply less protected, and it should be ranked as such rather
than re-rejected."*

**So E3 as a rule-out is dead, and what replaces it is a ranking.** Three
consequences, and I have tried to be even-handed about all three.

**C1. E3's headline reason was never the real one, and the doc half-knew it.**
Look at what E3 actually did. Alibaba, ByteDance, StepFun, Nex AGI and MiniMax
were excluded for having *nothing*; Mistral was excluded for having a
professional-advice clause that is *broader* than Anthropic's. Those are
opposite complaints filed under one heading. A vendor cannot be disqualified
both for saying nothing about health and for saying too much about it. The
heading concealed that the section was doing two different jobs.

**C2. Applying #679 consistently, the six E3 vendors split three ways.**
Conduct tests the app does not meet are not prohibitions (Mistral's
*"health-related guidance"*, Z.AI's *"substitute for professional services"*,
Alibaba's medical restriction, xAI's high-stakes-decisions clause). Vendors with
no published terms at all are still out, but on *unassessability*, not on
silence — you cannot promise a user where their photograph goes if the
destination publishes nothing. And a vendor whose own document contradicts
OpenRouter's `training` tag is out on the same E2 reasoning as before,
regardless of any of this.

**C3. Anthropic's advantage survives and should stay in the ranking.** The
carve-out is intact, verbatim, in the version effective 15 September 2025:
*"Wellness advice (e.g., advice on sleep, stress, nutrition, exercise, etc.)
does not fall under this category."* And #679's finding that Anthropic's
disordered-eating prohibition is broader than OpenAI's is, if anything,
understated — the same section also prohibits *"behaviors that promote
unhealthy or unattainable body image or beauty standards, such as using the
model to critique anyone's body shape or size"*, which has no OpenAI
counterpart at all. Anthropic remains the best-covered vendor. It is no longer
the *only permitted* one.

Sources: [Anthropic Usage Policy](https://www.anthropic.com/legal/aup) ·
[Anthropic Commercial Terms](https://www.anthropic.com/legal/commercial-terms)
(Effective June 17, 2025 — the date the previous note could not find)

## D. xAI re-examined

Five models qualify structurally, unchanged: `x-ai/grok-4.6` and `x-ai/grok-4.5`
($2.00/$6.00 per 1M in/out, 500k context), `x-ai/grok-4.3` (1M) and
`x-ai/grok-4.20` (2M) at $1.25/$2.50, and `x-ai/grok-build-0.1` at $1.00/$2.00.
Every one carries four first-party endpoints — `xai`, `xai/priority`,
`xai/zdr`, `xai/zdr/priority` — and all four advertise `tools`, `tool_choice`
and `max_tokens`. `xai` is tagged `training: false, retainsPrompts: true,
retentionDays: 30`, the same profile as `anthropic`, so it survives
`data_collection: "deny"`.

### D1. The AUP still says nothing about this, and I read all of it

Effective **August 14, 2026**, read in full. It states that it *"applies to
anyone using our Service, including consumers, developers and businesses."*
The words *diet*, *nutrition*, *health*, *wellness* and *food* do not occur
anywhere in it. The only minors provision is *"Sexualizing or exploiting
children"*. There is no professional-advice clause except a securities one.

**One correction to the previous note.** It described the AUP as *"roughly
6,000 words of running text"* and used that length to argue the absence is
genuine rather than a failure to find the right page. The document is **855
words**. The absence is still real — I read every bullet — but it is the
absence of a short document, not of an exhaustive one, and the length argument
should not be repeated.

The nearest clause remains, verbatim: users must not be *"Making high-stakes
automated decisions that affect a person's safety, legal or material rights, or
well-being (such as making financial credit, educational, employment, housing,
insurance, legal, medical, or other important decisions about or for them)"*.
Under #679's standard this is a conduct test with a human-review escape built
into the word *automated*, and the review step in `bulk_add_screen.dart` is
documented as *"not optional"*. It is not met.

### D2. The clause that actually rules xAI out today

From the **Terms of Service — Enterprise** (Last Updated August 14, 2026),
which OpenRouter's own provider record names as the Model Terms for `xai`,
under *Zero Data Retention*:

> Customer represents and warrants that it will not intentionally submit, and
> will use reasonable efforts to prevent Permitted Users and End Users from
> submitting any Personal Data to the Services except through SpaceXAI's
> ZDR-Enabled API.

A meal photograph submitted by the person who took it is personal data on any
reading. The app's pin is `only: ["xai"]` with `allow_fallbacks: false`, and
the plain `xai` endpoint is **not** the ZDR-Enabled API. Under the documented
base-slug rule `only: ["xai"]` matches every variant under `xai`, which means
it matches both `xai` and `xai/zdr` — so the app would not merely land on the
wrong one, it would land on either, non-deterministically, with no way to say
which in the settings screen. That is a worse position than the previous note's
"defensible but not obvious".

This is not an *unfixable* objection, and that is the substantive change:

- OpenRouter documents a per-request `zdr` flag: *"When `zdr` is set to `true`,
  the request will only be routed to endpoints that have a Zero Data Retention
  policy."* The same page names the enforceable model groups — *"Anthropic,
  OpenAI, Google, SpaceXAI, and non-frontier"*.
- Every Grok model above has an `xai/zdr` endpoint **at the same price** as its
  plain endpoint. Enforcing ZDR here costs nothing.
- The previous note listed `zdr: true` as unusable because *"neither curated
  Anthropic model has a ZDR-tagged endpoint"*. **That is still true** — I
  checked `/endpoints` for both, and the tags are `anthropic`, `azure`,
  `amazon-bedrock`, `google-vertex` and (on Sonnet 5) `claude-on-aws`, none of
  them ZDR. So `zdr: true` cannot be a blanket setting; it would have to be a
  per-model property, which is a change to `AiModel` and not just to a request
  body.

The same document carries two more provisions worth recording, neither fatal:
a HIPAA clause requiring a Business Associate Agreement *and* the ZDR API
before any protected health information is submitted (a food diary is not PHI,
which is tied to covered entities, but it is adjacent); and a flow-down
requiring the Customer to *"maintain legally enforceable terms of service and an
acceptable use policy with all Permitted Users and End Users that are no less
protective"* — which is OpenRouter's obligation, not ours, but it is the
mechanism by which xAI's terms reach a BYO-key user at all.

### D3. Where the previous note's quotes stop

Both xAI data quotes in `ai-model-candidates.md` are accurate and both end one
clause early.

- Training. The note quotes through *"…or to develop any new products, services,
  or features"*. The sentence continues: *"subject to disclosures to Customer
  and Customer-controlled user settings."* That is a settings-dependent
  commitment, not an outright bar, and whether OpenRouter's account settings
  are configured favourably is not public.
- Deletion. The note quotes through *"…no later than 30 days after the end of
  the interaction or session in which it was submitted"*. The sentence
  continues into three exceptions, the third being *"reasonably necessary for
  safety, security, compliance, moderation, abuse prevention, or
  investigation"*.

**Verdict: xAI is a live screening candidate, and it is gated on a routing
change rather than on a policy reading.** With `zdr: true` sent for the model,
the ZDR warranty is satisfied and nothing else in either document reaches this
app. Without it, xAI should not be offered — and that is a different rule-out
from the one recorded, on a clause the earlier note did not quote.

Sources: [SpaceXAI Acceptable Use Policy](https://x.ai/legal/acceptable-use-policy) ·
[Terms of Service — Enterprise](https://x.ai/legal/terms-of-service-enterprise) ·
[Provider Routing](https://openrouter.ai/docs/features/provider-routing)

## E. Ruled out, and the clause that rules each out

### E1. Age or audience clauses — re-verified, not assumed

**Google — 18 models.** Google Cloud Service Specific Terms, last modified
**29 July 2026**, read live. The clause is intact and has only been renumbered
(§19 → §20). §20(d), *Age Restrictions*: *"Customer will not, and will not
allow End Users to, use a Generative AI Service as part of a website, Customer
Application, or other online service that is directed towards or is likely to
be accessed by individuals under the age of 18."* §20(g) makes it a Use
Restriction; §20(f) permits suspension on *suspicion* of a violation of (d).
§20(e) adds a healthcare restriction, and §18 confirms the training objection is
gone (*"Google will not use Customer Data to train or fine-tune any AI/ML
models without Customer's prior permission or instruction"*). This is a
distribution test, which is why it survives #679 while OpenAI's minors clause
did not — the distinction is set out at length in
[`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) §C and I found nothing to
disturb it. `google/gemini-3.7-flash` stays out.
[Google Cloud Service Specific Terms](https://cloud.google.com/terms/service-terms)

**Sakana AI — 2 models.** Terms re-read live. *"You must be at least 18 years
old to use the Service."* And the geography clause, which for a German-authored
app is the harder one: the Service is *"provided for users in countries or
regions other than the European Economic Area, the UK, and Switzerland"*, and
the company *"may use technical means, including without limitation IP address
controls, to restrict access"*. **A third bar, not in the previous note:** the
same terms list *"Training AI models developed and operated by the Company"*
among the purposes for which Content may be used, which conflicts with
OpenRouter's `training: false` tag for `sakana`.
[Sakana AI Terms of Service](https://console.sakana.ai/terms-of-service)

**Meta — 2 models** (`meta/muse-spark-1.1`, `1.2`; a third, `muse-glimmer-30b`,
has no first-party endpoint and fails structurally). **The governing document
could not be re-read.** `https://ai.developer.meta.com/legal/terms-of-service`
returned HTTP 500 to every attempt on 2026-08-20, from two URL forms and both a
browser user-agent and WebFetch. The §10.1 age quote in `ai-model-candidates.md`
is therefore carried forward **unverified**. Meta stays out, because nothing
suggests the clause changed and because a vendor whose terms the project cannot
read is not one to route a photograph to — but the exclusion should be recorded
as resting on a four-day-old reading, not on a current one.

### E2. Data clauses that contradict the routing promise

**Mistral — 8 models. Newly in this category.** Commercial Terms of Service,
Effective **August 5, 2026**, §4.2 *Training*: Mistral will not train on
Customer Data *"except (a) when you (i) opted-in to training on a Mistral AI
Product set to opt-out by default or (ii) have not opted-out of training on a
Mistral AI Product set to opt-in by default"*, and *"(d) when Customer uses Labs
or Preview Models"*. OpenRouter tags `mistral` as `training: false`. Whether
OpenRouter's La Plateforme account has opted out, and which default applies to
the products behind these endpoints, is not disclosed by either party. This is
the identical shape to the Moonshot and Z.AI objections and it was not in the
previous note.
[Mistral Commercial Terms of Service](https://legal.mistral.ai/terms/commercial-terms-of-service)

**Moonshot AI — 4 models.** Re-verified verbatim: *"Unless otherwise expressly
agreed in writing, Customer Content may be used for the foregoing purposes"*,
where the purposes include *"develop, support, and improve the Services"*.
OpenRouter tags `moonshotai` `training: false`. Unresolved and unresolvable
from public documents.
[Moonshot AI model use agreement](https://platform.moonshot.ai/docs/agreement/modeluse)

**Z.AI — 3 models. The rejection is weaker than recorded.** The individual-user
clauses the previous note quoted are still there, but so is a sentence it did
not quote: *"For enterprises and developers using API Services, we will not use
your User Content for developing or improving Services unless you explicitly
agree to such use."* OpenRouter is an API developer, so the individual-user
training clauses probably never applied to this path. Z.AI still fails on the
other clause the note found — no use *"for any services that require subject
qualification or professional review, or as a substitute for professional
services, including but not limited to professional fields such as medical
care"* — which under #679's standard is a conduct test the app does not meet.
**So Z.AI is now, on the project's current standard, in the same position as
OpenAI was: permitted by absence of an applicable prohibition.** It is ranked
low in [Section G](#g-the-ranking) on other grounds, not excluded.
[Z.AI Terms of Service](https://chat.z.ai/legal-agreement/terms-of-service)

**NVIDIA — 2 models.** `nvidia` is still one of exactly three providers tagged
`training: true`. Structural, not arguable.

**Reka — 1 model.** Re-verified: *"If you use the Services on a free basis, you
acknowledge and agree that Reka may use Your Content to train, develop, and
improve its machine learning models … This may include human review"*, with
paid requests excluded. Whether OpenRouter's traffic is billed as paid is still
undisclosed. Moot: `rekaai/reka-edge` has a 16k context window and the terms
also require the user to be *"AT LEAST EIGHTEEN (18) YEARS OLD"*.
[Reka Terms of Use](https://reka.ai/legal/terms-of-use)

### E3. No carve-out, and the rest of the page

This is the section the standard change rewrites. None of these vendors has
anything resembling Anthropic's carve-out. Under #679 that is a **ranking
input**, not a rule-out. What follows is what each actually says.

- **Mistral — 8 models**, first-party via `mistral`, the only EU-headquartered
  vendor on the list (FR), and the only non-Anthropic vendor with a ZDR-tagged
  endpoint on any candidate (`mistral/zdr`, on `mistral-small-2603` alone).
  Usage Policy effective **11 June 2026**, unchanged, under *Professional
  advice*: *"Offering medical diagnoses, treatment suggestions, or any form of
  health-related guidance."* Broader than OpenAI's — no licence qualifier — but
  still a conduct test: the app offers no guidance. Its minors provision is the
  mild consent kind, not an audience test — the Commercial Terms bar the
  Customer from including *"personal information of children under 13 or the
  applicable age of digital consent"* or from allowing *"minors to use the
  Mistral AI Products without legally adequate consent from their parent or
  guardian"*, and say nothing about who the Customer's app is distributed to.
  **Mistral is excluded by
  §E2, not by this clause**, which is a correction to the previous note in both
  directions.
  [Mistral Usage Policy](https://legal.mistral.ai/terms/usage-policy)
- **Alibaba / Qwen — 21 models**, first-party via `alibaba`, including
  `qwen/qwen3.7-flash` at $0.03/$0.13, still the cheapest capable model in the
  set. **The previous note's characterisation is wrong.** Its Product Terms
  §4.48 (Model Studio) does address the domain: output *"shall not constitute
  (nor be treated as), nor be a substitute for, any professional, medical,
  legal, reliable, or accurate advice or information"*, *"shall not be used as a
  basis for making any professional, medical, legal, business, or financial
  decisions"*, and is *"not intended for use in, or in association with, any
  regulated uses"*. That is a disclaimer plus a use restriction. There is still
  no minors clause and no training clause in the Product Terms, and the
  Membership Agreement it incorporates was not read.
  [Alibaba Cloud Product Terms of Service](https://www.alibabacloud.com/help/en/legal/latest/alibaba-cloud-international-website-product-terms-of-service-v-3-8-0)
- **ByteDance Seed — 6 models**, first-party via `seed` (BytePlus), tagged
  `retainsPrompts: false`. The BytePlus Terms of Service OpenRouter names carry
  *Last Updated: August 23, 2022* and contain no health, medical, minors or
  training provision — re-verified by searching the full text. The gap between
  a 2022 general cloud contract and a 2026 vision model is itself the finding.
  [BytePlus Terms of Service](https://docs.byteplus.com/en/docs/legal/docs-terms-of-service)
- **Amazon — 1 model** (`amazon/nova-2-lite-v1`). AWS Acceptable Use Policy,
  *Last Updated: July 1, 2021*, re-read: no eating-disorder clause, no age
  clause, `amazon-bedrock` tagged `retainsPrompts: false`. Excluded on the same
  reasoning that produced the vendor pin: routing to Amazon puts the request
  under Amazon's terms rather than under a policy that names nutrition.
  [AWS Acceptable Use Policy](https://aws.amazon.com/aup/)
- **StepFun — 1 model** and **Nex AGI — 2 models**. `/api/v1/providers` still
  lists **no terms-of-service URL at all** for either (`nex-agi` has a privacy
  policy only). **This is the one E3 rule-out that survives the standard change
  intact**, and it should be restated on its own ground: not "no carve-out" but
  *unassessable*. An app that invites the user to check where their photograph
  goes cannot route it to a destination that publishes no terms.
- **MiniMax — 1 model** and **Xiaomi — 1 model.** Both terms pages are
  client-rendered and returned no readable text; see
  [Not verified](#not-verified). Neither is a serious candidate at the top of
  the ranking, so neither was chased into a browser.

### E4. Structural, before any policy question

- **24 of the 151 candidate models have no pinnable first-party endpoint** and
  can only 404 under `only: [...]` with `allow_fallbacks: false`. Includes all
  `meta-llama/*` and `thinkingmachines/*`, the three `openrouter/*` router
  models, `meta/muse-glimmer-30b`, `mistralai/mistral-small-3.2-24b-instruct`,
  `qwen/qwen3.5-9b`, `qwen/qwen3.6-35b-a3b`, the Gemma models served only by
  third parties, and four Anthropic models — `claude-3-haiku` (Bedrock only),
  `claude-opus-4` (Vertex only), `claude-opus-4.1` and `claude-sonnet-4`
  (Vertex and Bedrock only).
- **All 10 `~vendor/…-latest` aliases** in the candidate set, now including
  `~x-ai/grok-latest`. Each *"always redirects to the latest model"*, which is
  the silent behaviour change the pin exists to prevent.
- **All 55 `:batch` variants**, now on two independent grounds — asynchronous,
  and documented as text-only.
- **169 models with no image input**, plus **29** that accept images but do not
  advertise `tools` and `tool_choice`.

## F. What the routing block buys now

Three changes since the last pass, two of them good.

**The `claude-on-aws` hazard has resolved itself.** The previous note warned
that OpenRouter's Claude-on-AWS endpoint sat at `anthropic/claude-on-aws` — a
variant under the `anthropic` base slug — so that if it ever appeared on Sonnet
5 or Haiku 4.5, `only: ["anthropic"]` would accept it and
`_warnIfThePinDidNotHold` would log a false alarm against the display name
"Amazon Bedrock". It has appeared: `anthropic/claude-sonnet-5` now lists it,
alongside `claude-opus-5`, `claude-opus-4.5` through `4.8`, `claude-sonnet-4.5`,
`4.6` and `claude-fable-5`. But its slug is now **`claude-on-aws`**, a
top-level provider in `/api/v1/providers` with `provider_name` "Claude Platform
on AWS" and base URL `https://aws-external-anthropic.us-east-1.api.aws/v1`. It
is not under `anthropic`, so the documented base-slug rule does not reach it.
Its governing terms are still Anthropic's Commercial Terms, so the policy answer
would have been unchanged either way — but the warning no longer applies and
should not be carried forward. `anthropic/2`, which the previous note also
listed, no longer appears on any candidate model.

**`zdr: true` is real, documented, and now matters to a specific candidate.**
See [Section D2](#d2-the-clause-that-actually-rules-xai-out-today). It remains
unusable as a blanket setting because no Anthropic endpoint is ZDR-tagged.

**OpenRouter still passes vendor terms through to the end user.** Terms of
Service, Last Updated **29 July 2026**, §5.1: *"By accessing or using any Model
through the Service, you agree … to comply with the applicable terms for each
Model ('Model Terms')"*, with the user *"solely responsible for reviewing the
Model Terms applicable to each Model before accessing or using that Model"*.
And §2 still contemplates minor key-holders: *"You must be at least 13 years of
age to use the Service … If you are under 18 years of age, you must have your
parent or guardian's permission."* That combination is why the Google and Meta
audience clauses are fatal and OpenAI's conduct clause is not.
[OpenRouter Terms of Service](https://openrouter.ai/terms)

## G. The ranking

**These are screening candidates in the order I would spend a photo corpus on
them, not a shortlist and not a recommendation.** No model on it can be added
on the strength of this document. Prices are per **1M tokens**, input/output,
read off OpenRouter's own endpoint records for the pinned first-party endpoint
on 2026-08-20. None of these models has a per-image price; images are billed as
prompt tokens.

| # | Model | Pin | In / Out per 1M | Cost vs. `claude-sonnet-5` | Screened? |
| --- | --- | --- | --- | --- | --- |
| 1 | `openai/gpt-5.6-luna` | `openai` | $0.20 / $1.20 | 10–12% | direct route only |
| 2 | `openai/gpt-5.6-terra` | `openai` | $2.00 / $12.00 | 100–120% | direct route only |
| 3 | `x-ai/grok-4.20` | `xai` + `zdr` | $1.25 / $2.50 | 25–63% | no |
| 4 | `x-ai/grok-4.3` | `xai` + `zdr` | $1.25 / $2.50 | 25–63% | no |
| 5 | `anthropic/claude-opus-5` | `anthropic` | $5.00 / $25.00 | exactly 250% | no |
| 6 | `x-ai/grok-4.6` | `xai` + `zdr` | $2.00 / $6.00 | 60–100% | no |

**How the cost column is computed, and why it is a range.** The catalogue
records two measured figures — roughly $0.0033 a photo for Sonnet 5 and
$0.0017 for Haiku 4.5 — and those two are in exactly the same 2:1 ratio as
their prices, so they do **not** determine how many tokens are input and how
many are output. Rather than invent a split, the column brackets it: the low
end is the ratio of prompt prices, the high end the ratio of completion prices,
and a request of any shape must fall between them. Where both ratios coincide
the figure is exact — `claude-opus-5` is 2.5× on both, i.e. about $0.008 a
photo, which reproduces the previous note's estimate by a different route.
**Three things break this arithmetic and are why it is a bracket and not a
price:** each vendor tokenises an image differently, so the input count is not
transferable; reasoning tokens bill as output, and `grok-4.6` and `grok-4.5`
carry `reasoning.mandatory: true` while `gpt-5.6-luna`/`terra` default reasoning
on at medium effort; and OpenRouter's own fee on top is not modelled here.

Notes on each:

1. **`openai/gpt-5.6-luna`** — the same model name the app already ships on the
   direct path, where it is the default. Endpoint `openai`, 1.05M context,
   `tools`/`tool_choice`/`max_tokens` all present. #684 and #719 measured 18/18
   forced tool calls, zero measurement leaks, zero duplicate rows and 5/5 empty
   on non-food images — **through the direct API, not through OpenRouter**.
   That is the same route confound that #684 refused to resolve about
   `gpt-5.4-nano`, so it is a strong prior and not a substitute for the screen.
   It is also the cheapest thing on this list by an order of magnitude.
2. **`openai/gpt-5.6-terra`** — the app's second direct entry, offered there for
   being the less conservative reader. Same structural profile.
3. **`x-ai/grok-4.20`** — the Grok to screen first, not the newest one:
   `reasoning.default_enabled` is **false**, so it will not spend the client's
   `max_tokens: 1024` on thinking before it emits the tool call. 2M context.
   Requires the ZDR routing change in [Section D2](#d2-the-clause-that-actually-rules-xai-out-today).
4. **`x-ai/grok-4.3`** — same price, 1M context, reasoning on but at `low`
   effort by default.
5. **`anthropic/claude-opus-5`** — the only quality-up that stays inside the
   vendor with the carve-out. Cheapest Opus, pins cleanly, and the decision is
   purely "does it find more staples in bad photographs than Sonnet 5", which
   no document can answer. Placed below the cheaper candidates only because
   2.5× the current cost is a lot to pay for an unmeasured improvement.
6. **`x-ai/grok-4.6` / `x-ai/grok-4.5`** — `reasoning.mandatory: true` on both.
   Screen them for truncation against `max_tokens: 1024` before screening them
   for anything else.

**Deliberately not ranked**, and why: `qwen/qwen3.7-flash` at $0.03/$0.13 is
30× cheaper than anything above it and Alibaba's §4.48 does not bar this use —
but the pin lands in Singapore under a general cloud contract with no
health-specific commitments in either direction, and the project has not
decided whether it is willing to name Alibaba in the settings screen. Mistral is
the natural European candidate and is held out by §4.2 alone. `z-ai/glm-4.6v`
is now arguably permitted and is a 131k-context model with no published
carve-out from a vendor whose terms conflict with the router's tag in a way
that is only *probably* resolved.

## Not verified

- **No live request was made and none can be made from here.** Every capability,
  price and routing claim is OpenRouter's declaration about itself. In
  particular: that `only: ["xai"]` reaches `xai/zdr` follows from the documented
  base-slug rule and was **not** probed, and the docs do not say whether a
  `/zdr` suffix is a "variant" (matched) or a "service tier" (not matched). The
  existence of `xai/zdr/priority` suggests `/zdr` is a variant and `/priority`
  is the tier, but that is inference. **This is the single most load-bearing
  unverified claim in Section D and it decides whether the ZDR warranty is
  breached today, satisfied today, or coin-flipped per request.**
- **Meta's Model API Terms of Service.** `ai.developer.meta.com` returned HTTP
  500 to every attempt on 2026-08-20 — two URL forms, browser user-agent and
  WebFetch. The §10.1 age quote and the §6.1 Discounted-Services training quote
  in `ai-model-candidates.md` could not be re-verified. Neither was disproved.
- **Whether OpenRouter has opted out of Mistral training**, which is the whole
  of the §4.2 objection, and correspondingly whether it holds written
  no-training agreements with Moonshot AI. Neither party publishes the contract.
- **MiniMax and Xiaomi terms.** `platform.minimax.io/protocol/terms-of-service`
  (reached via a 307 from `minimax.io`) and
  `platform.xiaomimimo.com/#/docs/terms/user-agreement` are both
  client-rendered and returned title-only text to automated fetching. Neither
  was read in a browser, because neither model is near the top of the ranking.
  The previous note's MiniMax reading is therefore carried forward unverified.
- **Alibaba's Membership Agreement**, which §4.48 incorporates and where any age
  or eligibility clause would live. Still only the Product Terms were read.
- **Anthropic's "products serving minors" guideline.** The Usage Policy's
  *Additional Use Case Guidelines* require that *"Products serving minors …
  must comply with the additional guidelines outlined in our Help Center
  article"*. The article was not retrieved. This binds the **currently shipping**
  Anthropic path, so it is not a differentiator between vendors — but it is an
  obligation the project does not appear to have recorded anywhere, and it is
  worth a look independently of this question.
- **Whether the OpenAI behavioural results transfer across routes.** #684
  measured `gpt-5.6-luna` and `gpt-5.6-terra` on the direct API. #669 measured
  `openai/gpt-5.4-nano` through OpenRouter and got the opposite result for a
  different model. Nothing here establishes that a model behaves the same way
  through the broker, and the catalogue's own comment about `anthropic/2` and
  Bedrock is a reminder that OpenRouter is not a transparent pipe.
- **Every quality claim.** There are none in this document. No model was asked
  to read a photograph.
- **OpenRouter's own fee.** Not modelled in Section G, and not published in the
  endpoint data I read.
- **Legal advice.** A reading of published documents on one date by a
  non-lawyer. Terms on all of these sites change without notice; the dates given
  are the only guarantee offered.

## Sources

OpenRouter (own API and docs, queried 2026-08-20):
[`/api/v1/models`](https://openrouter.ai/api/v1/models) — the 414-model
catalogue, capability flags, prices and `created` dates ·
[`/api/v1/models/{author}/{slug}/endpoints`](https://openrouter.ai/api/v1/models/x-ai/grok-4.6/endpoints)
— per-candidate endpoint tags, per-endpoint prices and `supported_parameters`,
fetched for all 151 candidates ·
[`/api/v1/providers`](https://openrouter.ai/api/v1/providers) — provider slugs
and the terms-of-service URL naming each Model Terms document ·
[`/api/frontend/v1/all-providers`](https://openrouter.ai/api/frontend/v1/all-providers)
— `dataPolicy` records, base URLs, the `claude-on-aws` adapter ·
[Provider Routing](https://openrouter.ai/docs/features/provider-routing) —
`require_parameters`, `data_collection`, `allow_fallbacks`, base-slug matching,
`zdr` ·
[Batch API Quickstart](https://openrouter.ai/docs/batch-quickstart.md) — the
text-only limitation ·
[Terms of Service](https://openrouter.ai/terms) — §2 eligibility, §5.1 Model
Terms pass-through

Vendor documents (each fetched from the vendor's own domain):
[Anthropic Usage Policy](https://www.anthropic.com/legal/aup) — the nutrition
carve-out, the disordered-eating and body-image prohibitions, the minors
guideline ·
[Anthropic Commercial Terms](https://www.anthropic.com/legal/commercial-terms) —
the no-training sentence and the effective date ·
[SpaceXAI Acceptable Use Policy](https://x.ai/legal/acceptable-use-policy) —
read in full; the high-stakes-decisions clause and the absences ·
[SpaceXAI Terms of Service — Enterprise](https://x.ai/legal/terms-of-service-enterprise)
— the ZDR Personal Data warranty, the training and deletion sentences in full,
the flow-down ·
[Google Cloud Service Specific Terms](https://cloud.google.com/terms/service-terms)
— §20(d) age restriction, §20(e) healthcare, §18 training ·
[Mistral Usage Policy](https://legal.mistral.ai/terms/usage-policy) —
professional advice ·
[Mistral Commercial Terms of Service](https://legal.mistral.ai/terms/commercial-terms-of-service)
— §4.2 training exceptions, the minors consent clause ·
[Moonshot AI model use agreement](https://platform.moonshot.ai/docs/agreement/modeluse) ·
[Z.AI Terms of Service](https://chat.z.ai/legal-agreement/terms-of-service) —
including the API-developer carve-out the previous note missed ·
[Reka Terms of Use](https://reka.ai/legal/terms-of-use) ·
[Sakana AI Terms of Service](https://console.sakana.ai/terms-of-service) ·
[Alibaba Cloud Product Terms of Service](https://www.alibabacloud.com/help/en/legal/latest/alibaba-cloud-international-website-product-terms-of-service-v-3-8-0)
— §4.48 Model Studio ·
[BytePlus Terms of Service](https://docs.byteplus.com/en/docs/legal/docs-terms-of-service) ·
[AWS Acceptable Use Policy](https://aws.amazon.com/aup/)

Attempted and failed (see [Not verified](#not-verified)):
[Meta Model API Terms of Service](https://ai.developer.meta.com/legal/terms-of-service)
(HTTP 500) ·
[MiniMax Terms of Service](https://platform.minimax.io/protocol/terms-of-service)
(client-rendered) ·
[Xiaomi user agreement](https://platform.xiaomimimo.com/#/docs/terms/user-agreement)
(client-rendered)

Related notes in this repo:
[`ai-model-candidates.md`](ai-model-candidates.md) — the document this one
re-checks ·
[`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) — the standard now in force ·
[`ai-openai-behavioural-screen.md`](ai-openai-behavioural-screen.md) — what the
two OpenAI models have and have not been screened for ·
[`ai-legal-constraints.md`](ai-legal-constraints.md) ·
[`ai-cohort-restrictions.md`](ai-cohort-restrictions.md) ·
[`ai-open-research-questions.md`](ai-open-research-questions.md)

In-repo files cited:
[`lib/core/utils/ai_model_catalogue.dart`](../lib/core/utils/ai_model_catalogue.dart) ·
[`lib/features/add_meal/data/openrouter_meal_items_api.dart`](../lib/features/add_meal/data/openrouter_meal_items_api.dart) ·
[`lib/features/add_meal/domain/meal_items_api.dart`](../lib/features/add_meal/domain/meal_items_api.dart) ·
[`lib/features/add_meal/presentation/screens/bulk_add_screen.dart`](../lib/features/add_meal/presentation/screens/bulk_add_screen.dart)
