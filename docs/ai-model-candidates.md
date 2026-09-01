# Which other models could serve AI meal logging

Research notes gathered 2026-08-16 against primary sources only — OpenRouter's
own `/api/v1/models`, `/api/v1/models/{id}/endpoints`, `/api/v1/providers` and
`/api/frontend/v1/all-providers`, OpenRouter's own documentation and Terms of
Service, and each vendor's own legal pages. Where a page blocked automated
fetching (openai.com, minimax.io, mistral.ai, ai.developer.meta.com), it was
read in a real browser rather than through a mirror, and the quotes below are
from the vendor's own page. Nothing here rests on a leaderboard, a blog post or
a secondary write-up.

Written to answer one question for [#668](https://github.com/simonoppowa/OpenNutriTracker/issues/668):
**beyond `anthropic/claude-sonnet-5` and `anthropic/claude-haiku-4.5`, which
models are fit to be offered?** The constraints it is answered against are
settled elsewhere and are not re-argued here: no model may emit a nutrition
value, `tool_choice` must be honoured, `strict: true` is unusable, image input
is required, and every OpenRouter request carries `require_parameters: true`,
`data_collection: "deny"` and a vendor pin with `allow_fallbacks: false`
([#663](https://github.com/simonoppowa/OpenNutriTracker/issues/663),
[`lib/core/utils/ai_model_catalogue.dart`](../lib/core/utils/ai_model_catalogue.dart),
[`lib/features/add_meal/data/openrouter_meal_items_api.dart`](../lib/features/add_meal/data/openrouter_meal_items_api.dart)).

Things I could not establish from a primary source are in
[Not verified](#not-verified) rather than inferred.

## Bottom line up front

**No additional vendor clears every bar, and the catalogue should stay as it
is.** The ruled-out list is the useful output, and three of its entries are new
rather than restatements.

1. **Anthropic has nothing newer or cheaper that fits.** Haiku 4.5 is still the
   newest Haiku — there is no Haiku 5. Nothing Anthropic-branded is cheaper
   *and* pinnable: `anthropic/claude-3-haiku` is four times cheaper than Haiku
   4.5 and is served **only by Amazon Bedrock**, so `only: ["anthropic"]`
   cannot reach it. Everything else Anthropic serves is a quality-up at
   2.5×–15× the price of the current default. Adding one is a measurement
   question, not a policy question.
2. **Google has not moved in our favour.** The clause moved documents but
   survived: the under-18 restriction that excluded `google/gemini-3.7-flash`
   is no longer only a free-tier Gemini API term — it now sits in the **Google
   Cloud Service Specific Terms**, which is the document OpenRouter itself
   names as the Model Terms for *both* `google-ai-studio` and `google-vertex`.
   The training-on-input objection *has* gone away (Cloud does not train). The
   age objection has not, and it alone is fatal.
3. **The one genuine near-miss is xAI/SpaceXAI.** Its Acceptable Use Policy
   contains no disordered-eating clause, no minors clause and no
   professional-advice clause, its enterprise terms forbid training on user
   content outright, and it offers zero-data-retention endpoints. But "no
   prohibition found" is weaker than Anthropic's *explicit* carve-out of
   nutrition from High-Risk Use Cases, and xAI has no equivalent carve-out to
   point at. It is a defensible second vendor if the project wants one; it is
   not an obvious one, and it would still need the photo screen.
4. **Meta is newly pinnable and newly barred.** Meta now serves its own models
   first-party on OpenRouter (`meta/muse-spark-*`, provider slug `meta`), which
   removes the old "Meta publishes weights but does not serve them" objection.
   Its Model API terms replace it with a harder one: *"You and your End Users
   must be at least 18 years of age to use the Services and Integrated
   Products, and you will not create Integrated Products targeted at
   individuals under the age of 18."*

Two operational findings that matter regardless of which models are curated:

- **The pin is looser than the code comment assumes.** OpenRouter documents
  that a base slug matches *all* endpoint variants under it. `anthropic` today
  includes an endpoint tagged `anthropic/claude-on-aws`, whose `provider_name`
  is **Amazon Bedrock** and whose base URL is
  `https://aws-external-anthropic.us-east-1.api.aws/v1`. It is not currently
  attached to either curated model — only to `claude-sonnet-4.5` — so nothing
  is broken today. But if it appears on Sonnet 5 or Haiku 4.5, `only:
  ["anthropic"]` will accept it and `_warnIfThePinDidNotHold` will log a false
  alarm, because it compares the pin slug against the display name
  "Amazon Bedrock". See [Section D](#d-what-the-routing-block-actually-buys).
- **`:batch` variants are half price and unusable.** OpenRouter's own docs
  index describes the Batch API as *"Submit and retrieve **asynchronous**
  batches of inference requests"*. Every `:batch` model in the catalogue is
  therefore out for an interactive meal entry, however attractive
  `anthropic/claude-sonnet-5:batch` at $1/$5 looks.

## A. How the filter ran, with the numbers

Every figure below is from OpenRouter's own API, queried 2026-08-16.

| Stage | Models left |
| --- | --- |
| Listed on `/api/v1/models` | **413** |
| …with `image` in `architecture.input_modalities` | 245 |
| …that also list both `tools` and `tool_choice` in `supported_parameters` | **216** |
| …with at least one **first-party endpoint** — an endpoint whose provider slug is the vendor named in the model slug — that itself advertises `tools` and `tool_choice` | **178** |
| …whose first-party provider is not tagged as training on input (fails `data_collection: "deny"`) | 176 |
| …excluding `:batch` variants and `~vendor/...-latest` floating aliases | **124**, across 17 vendors |
| …after applying the vendors' own usage policies and terms | **13**, all Anthropic |

The 216 figure reproduces the "~215 technically capable" measurement recorded
in the catalogue's own doc comment, so the capability screen has not drifted.
The collapse from 124 to 13 is entirely policy, exactly as #656 found.

The 17 vendors surviving the structural screen are: `anthropic` (13 models),
`openai` (36), `qwen`/Alibaba (20), `google` (18), `mistralai` (8),
`bytedance-seed` (6), `x-ai` (5), `moonshotai` (4), `z-ai` (3), `meta` (2),
`sakana` (2), `nex-agi` (2), `amazon` (1), `minimax` (1), `stepfun` (1),
`xiaomi` (1), `rekaai` (1).

The 38 models that have image + tools + `tool_choice` but **no** pinnable
first-party endpoint fail constraint 5 outright and are listed in
[Section E](#e-ruled-out-and-the-clause-that-rules-each-out).

## B. Is there a newer or cheaper Anthropic model?

All 13 Anthropic models that survive the structural screen, from OpenRouter's
`/api/v1/models` and `/endpoints` (prices per 1M tokens, input/output):

| Slug | In | Out | Context | First-party endpoint tags |
| --- | --- | --- | --- | --- |
| `anthropic/claude-haiku-4.5` **(curated)** | $1.00 | $5.00 | 200k | `anthropic` |
| `anthropic/claude-sonnet-5` **(curated, default)** | $2.00 | $10.00 | 1M | `anthropic` |
| `anthropic/claude-sonnet-4.5` | $3.00 | $15.00 | 1M | `anthropic`, `anthropic/2`, **`anthropic/claude-on-aws`** |
| `anthropic/claude-sonnet-4.6` | $3.00 | $15.00 | 1M | `anthropic`, `anthropic/2` |
| `anthropic/claude-opus-4.5` | $5.00 | $25.00 | 200k | `anthropic`, `anthropic/2` |
| `anthropic/claude-opus-4.6` | $5.00 | $25.00 | 1M | `anthropic`, `anthropic/2` |
| `anthropic/claude-opus-4.7` | $5.00 | $25.00 | 1M | `anthropic`, `anthropic/2` |
| `anthropic/claude-opus-4.8` | $5.00 | $25.00 | 1M | `anthropic`, `anthropic/2` |
| `anthropic/claude-opus-5` | $5.00 | $25.00 | 1M | `anthropic` |
| `anthropic/claude-opus-4.8-fast` | $10.00 | $50.00 | 1M | `anthropic` |
| `anthropic/claude-opus-5-fast` | $10.00 | $50.00 | 1M | `anthropic` |
| `anthropic/claude-fable-5` | $10.00 | $50.00 | 1M | `anthropic` |
| `anthropic/claude-opus-4.7-fast` | $30.00 | $150.00 | 1M | `anthropic` |

Reading that table against the question:

- **Newer, cheaper: does not exist.** Haiku 4.5 (created 2025-10-15 per the
  API's `created` field) is the most recent model in the Haiku family; the API
  lists no Haiku 5. Sonnet 5 is the newest Sonnet and is *cheaper* than both
  Sonnet 4.5 and 4.6, so the two curated entries are already the cheapest
  members of their families.
- **Cheaper at all: only by leaving Anthropic's own endpoint.**
  `anthropic/claude-3-haiku` is listed at $0.25/$1.25 — a quarter of Haiku 4.5
  — and its `/endpoints` response contains exactly one endpoint, tagged
  `amazon-bedrock`, `provider_name` "Amazon Bedrock". Under
  `only: ["anthropic"]` with `allow_fallbacks: false` it can only 404. It is
  also a March 2024 model, so it would need the photo screen even if the pin
  worked.
- **Better, at a price: `anthropic/claude-opus-5`.** It is the cheapest Opus
  ($5/$25) and pins cleanly to `anthropic`. On the price ratio alone it would
  cost roughly 2.5× the default's measured ~$0.0033 per photo, i.e. around
  $0.008. Whether it identifies more staples in low-quality photos than Sonnet
  5 is not answerable from any primary source — the catalogue's own comment
  says membership requires a behavioural screen against a photo corpus, and
  that screen has not been run for Opus 5. **No recommendation either way.**
- **`-fast` and `fable` are not for this.** `claude-opus-5-fast` is the same
  model at double the price, and `claude-fable-5` is a separate $10/$50 family.
  Neither is defensible for a task whose entire output is a list of food names.
- **Anthropic's own policy position is unchanged and still the best available.**
  Usage Policy, effective 15 September 2025, under *High-Risk Use Case
  Requirements*: healthcare is high-risk, but *"Wellness advice (e.g., advice
  on sleep, stress, nutrition, exercise, etc.) does not fall under this
  category"* — an explicit carve-out no other vendor offers. The Universal
  Usage Standards still prohibit content that would *"Facilitate, promote, or
  glamorize any form of suicide or self-harm, including disordered eating and
  unhealthy or compulsive exercise"*, which the design already respects by
  never letting the model produce a number or a judgement. The Commercial
  Terms state *"Anthropic may not train models on Customer Content from
  Services"* and contain **no age gate on the customer's end users and no
  restriction on the audience of the customer's application** — the single
  clause that disqualifies Google and Meta.

  Sources: [Usage Policy](https://www.anthropic.com/legal/aup) ·
  [Commercial Terms of Service](https://www.anthropic.com/legal/commercial-terms)

## C. xAI / SpaceXAI — the only non-Anthropic vendor with nothing against this

Five models qualify structurally: `x-ai/grok-4.6` and `x-ai/grok-4.5` ($2/$6),
`x-ai/grok-4.3`, `x-ai/grok-4.20` ($1.25/$2.50, 2M context) and
`x-ai/grok-build-0.1`. All list image input, `tools` and `tool_choice`; all
have first-party endpoints tagged `xai`, `xai/priority`, `xai/zdr` and
`xai/zdr/priority`. Images are billed as prompt tokens — OpenRouter lists no
separate per-image price for any of them. `grok-4.6` carries a documented price
override above 200k prompt tokens, which a meal request never approaches.

What its documents say, and do not say:

- **Data.** OpenRouter's provider record for `xai` reports
  `training: false, retainsPrompts: true, retentionDays: 30` — the same profile
  as `anthropic`, so it survives `data_collection: "deny"`. The vendor's own
  enterprise terms go further: *"SpaceXAI will not use any User Content to
  train any foundation models, large language models, or other artificial
  intelligence systems or to develop any new products, services, or features"*,
  and *"All User Content will be automatically and permanently deleted no later
  than 30 days after the end of the interaction or session in which it was
  submitted"*.
- **No disordered-eating clause, no body-image clause, no minors clause beyond
  CSAM, no professional-advice clause.** The AUP (effective 14 August 2026) was
  read in full; the words "eating", "diet", "health" and "18" do not appear in
  any prohibition. This is a genuine absence, not a failure to find the right
  page — the AUP is roughly 6,000 words of running text and states it *"applies
  to anyone using our Service, including consumers, developers and
  businesses."*
- **The one clause that could be argued at us**, from the same AUP: users must
  not be *"Making high-stakes automated decisions that affect a person's
  safety, legal or material rights, or well-being (such as making financial
  credit, educational, employment, housing, insurance, legal, medical, or
  other important decisions about or for them)"*. A meal-name extractor whose
  output the user reviews before anything is written is not an automated
  decision, and the enumerated examples are all consequential third-party
  determinations. It is still the closest thing xAI has to a health clause, and
  it has no carve-out attached.
- **The age wording is of a different kind to Google's and Meta's.** The
  enterprise terms carry a scope note: *"These terms are for enterprise
  (business) users of the SpaceXAI API and related SpaceXAI Services (including
  Grok) who are at least 18 years old."* That reaches whoever accepts the
  terms. It does not say the *application* may not be one that minors use,
  which is what makes the Google and Meta clauses fatal for a general-audience
  tracker.

**Verdict: possible, not recommended on this evidence.** Anthropic's carve-out
says nutrition is out of scope for the high-risk regime; xAI says nothing at
all, and silence is a weaker foundation for a project that has chosen to be
able to name and defend its destination. Adding it would also require the
photo screen, and would double the surface the project has to re-check whenever
a vendor edits a policy.

Sources: [SpaceXAI Acceptable Use Policy](https://x.ai/legal/acceptable-use-policy) ·
[Terms of Service — Enterprise](https://x.ai/legal/terms-of-service-enterprise)

## D. What the routing block actually buys

Worth recording, because two of these are stronger than the code comments
assume and one is weaker.

**`data_collection: "deny"` filters on training, not on retention.** OpenRouter's
provider-routing documentation: `allow` is *"allow providers which store user
data non-transiently and may train on it"*, `deny` is *"use only providers
which do not collect user data"*. Its own provider records make the operative
distinction visible: `anthropic` is `training: false, retainsPrompts: true,
retentionDays: 30` and is reachable under `deny`, so `deny` is keyed on
training rather than on retention. Across all 81 provider records only three
are tagged `training: true` — `deepseek`, `liquid` and `nvidia`. The
documentation also warns that the tags are *"not a definitive source of third
party data policies, but represents our best knowledge"*, which is why
[Section E](#e-ruled-out-and-the-clause-that-rules-each-out) treats a conflict
between a tag and the vendor's own terms as disqualifying.

**A base slug matches every variant under it.** From the same page: *"When you
use a base provider slug (e.g. `"google-vertex"`) in any provider routing field
(`order`, `only`, or `ignore`), it matches all endpoints for that provider,
including any variants or regions… Note that service tier endpoints (e.g.
`openai/priority`, `google-vertex/flex`) are not matched by base slugs — they
require explicit opt-in."* Two consequences:

- Good: for any vendor whose only first-party endpoint carries a quantisation
  suffix — `z-ai/fp8`, `moonshotai/int4`, `seed/fp8`, `minimax/fp8`,
  `xiaomi/fp8`, `stepfun/fp8`, `reka/bf16` — a plain `only: ["z-ai"]` would
  still reach it. The pin mechanism is not the obstacle for those vendors.
- Bad: `only: ["anthropic"]` also matches `anthropic/2` and
  `anthropic/claude-on-aws`. The latter is OpenRouter's "Claude Platform on
  AWS" provider — `provider_name` "Amazon Bedrock", base URL
  `https://aws-external-anthropic.us-east-1.api.aws/v1`. Its governing terms
  per OpenRouter's own record are still
  `https://www.anthropic.com/legal/commercial-terms`, so the *policy* outcome
  is unchanged, but the guarantee the settings screen makes — that the company
  named is the company that answered — becomes "Anthropic's contract, on
  Amazon's metal". Today that endpoint exists only for `claude-sonnet-4.5`, not
  for either curated model.

**A `zdr` routing flag exists and the app does not use it.** `zdr: true`
restricts routing to zero-data-retention endpoints. It cannot simply be turned
on: neither curated Anthropic model has a ZDR-tagged endpoint, so the flag
would 404 every request today. It is listed here because it is the one routing
control that would materially strengthen the privacy claim if Anthropic ever
publishes ZDR endpoints.

**OpenRouter passes the vendors' terms through to the end user.** Terms of
Service §5.1: *"By accessing or using any Model through the Service, you agree…
to comply with the applicable terms for each Model ("Model Terms"), a list of
which is provided here."* The linked list renders from the same
`terms_of_service_url` field returned by `/api/v1/providers`, which is how each
rule-out below identifies *which* vendor document governs. §5.2 adds that the
user *"will be responsible for all acts and omissions of your Authorized
Users"*.

This matters most for the age clauses. OpenRouter's own eligibility rule (§2)
is *"You must be at least 13 years of age to use the Service… If you are under
18 years of age, you must have your parent or guardian's permission"* — so the
router itself contemplates 13-to-17-year-old key holders, while Google's and
Meta's Model Terms forbid the application those keys would be used in.

Sources: [Provider Routing](https://openrouter.ai/docs/features/provider-routing) ·
[OpenRouter Terms of Service](https://openrouter.ai/terms) ·
[`/api/v1/providers`](https://openrouter.ai/api/v1/providers) ·
[`/api/frontend/v1/all-providers`](https://openrouter.ai/api/frontend/v1/all-providers)

## E. Ruled out, and the clause that rules each out

### E1. Ruled out by an age or audience clause

These are the hard ones. A general-audience nutrition tracker distributed on
Google Play and F-Droid cannot promise its users are adults or that minors will
not install it.

**OpenAI — 36 models** (`openai/gpt-5.x`, `gpt-5.6-*`, `gpt-4.1*`, `o3`,
`o4-mini`, …). Usage Policies, effective 29 October 2025, read in a browser on
openai.com. Under *Protect people*, prohibited: *"suicide, self-harm, or
disordered eating promotion or facilitation"*. Under *Keep minors safe*,
prohibited: *"promoting unhealthy dieting or exercise behavior to minors"* and
*"shaming or otherwise stigmatizing the body type or appearance of minors"*.
Also under *Protect people*: *"provision of tailored advice that requires a
license, such as legal or medical advice, without appropriate involvement by a
licensed professional"*. There is no wellness or nutrition carve-out anywhere
in the document. Unchanged from the #656 finding, and independent of the
separate fact that `strict: true` breaks every `openai/*` call.
[Usage policies](https://openai.com/policies/usage-policies/)

**Google — 18 models** (`google/gemini-3.7-flash`, `gemini-3.5-flash-lite`,
`gemini-3.1-pro-preview`, the Gemini 2.5 line, `gemma-4-*`, …). **The document
to cite has changed; the answer has not.** OpenRouter's provider records give
`https://cloud.google.com/terms/` as the Model Terms for both
`google-ai-studio` and `google-vertex`, so the free-tier
[Gemini API Additional Terms](https://ai.google.dev/gemini-api/terms) — with
its training clause, its human-reviewer clause and its "not for consumer use"
line — is **not** the governing document on the OpenRouter path. Under Cloud
terms, the training objection genuinely disappears: Service Specific Terms §18,
*"Google will not use Customer Data to train or fine-tune any AI/ML models
without Customer's prior permission or instruction."* The age objection does
not. Service Specific Terms §20(d), *Age Restrictions*: *"Customer will not,
and will not allow End Users to, use a Generative AI Service as part of a
website, Customer Application, or other online service that is directed towards
or is likely to be accessed by individuals under the age of 18."* §20(e) adds a
Healthcare Restriction against use *"as a substitute for professional medical
advice"*. Both are declared "Use Restrictions" by §20(g). Last modified
29 July 2026.

So `google/gemini-3.7-flash` — measured better and ~5× cheaper than the current
default — stays excluded, on one clause instead of four.
[Google Cloud Service Specific Terms](https://cloud.google.com/terms/service-terms) ·
[Google Cloud Terms of Service](https://cloud.google.com/terms/) ·
[Generative AI Prohibited Use Policy](https://policies.google.com/terms/generative-ai/use-policy)
(last modified 17 December 2024; contains no eating-disorder or nutrition
clause, so it neither helps nor hurts)

**Meta — 2 models** (`meta/muse-spark-1.1`, `meta/muse-spark-1.2`, $1.25/$4.25,
first-party endpoint tagged `meta`). Meta Model API Terms of Service, last
updated 5 August 2026, §10.1: *"You and your End Users must be at least 18
years of age to use the Services and Integrated Products, and you will not
create Integrated Products targeted at individuals under the age of 18."*
Independently, §6.1 provides that on "Discounted Services" *"Meta may use your
Content to train, develop, evaluate, and improve Meta's artificial intelligence
models"* and that *"the Discounted Services do not offer a mechanism to exclude
specific traffic from training"* — so which tier OpenRouter buys would have to
be established before `data_collection: "deny"` meant anything here.
[Meta Model API Terms of Service](https://ai.developer.meta.com/legal/terms-of-service)

**Sakana AI — 2 models** (`sakana/fugu-ultra`, `sakana/sakana-namazu`). Two
independent bars. Age: *"You must be at least 18 years old to use the
Service."* Geography: *"The Service is provided for users in countries or
regions other than the European Economic Area, the UK, and Switzerland
("Supported Regions"). The Company does not, and does not intend to, provide or
market the Service to countries or regions outside the Supported Regions."*
For a German-authored app with a European user base that is disqualifying on
its own.
[Sakana AI Terms of Service](https://console.sakana.ai/terms-of-service)

### E2. Ruled out by a data clause that contradicts the routing promise

The app tells the user it asked the router to exclude providers that train on
input. Where a vendor's own terms reserve exactly that right, the promise rests
on OpenRouter's classification overriding the vendor's own document — which
OpenRouter itself says is only *"our best knowledge"*.

**Moonshot AI — 4 models** (`moonshotai/kimi-k3`, `kimi-k2.7-code`, `kimi-k2.6`,
`kimi-k2.5`). OpenRouter tags `moonshotai` as `training: false,
retainsPrompts: false`. Moonshot's own model-use agreement says: *"We may use
Content to provide, maintain, develop, support, and improve the Services…
Customer who requires restrictions on the use of Customer Content for training
or improving Moonshot AI models may contact Moonshot AI to discuss available
enterprise arrangements or separate written agreements. Unless otherwise
expressly agreed in writing, Customer Content may be used for the foregoing
purposes."* Whether OpenRouter holds such a written agreement is not something
any primary source discloses. The same document also requires that *"To use the
Services as an individual, you must be at least 18 years old or the minimum age
required by your country to consent to such use"* — an eligibility clause of
the milder kind, but on top of the data conflict.
[Moonshot AI model use agreement](https://platform.moonshot.ai/docs/agreement/modeluse)

**Z.AI — 3 models** (`z-ai/glm-5v-turbo`, `glm-4.6v`, `glm-4.5v`). OpenRouter
tags `z-ai` as `training: false, retainsPrompts: false`. Z.AI's own terms:
*"For individual users, we may use User Content to provide, maintain, develop,
and improve our Services"* and *"For individual users, we reserve the right to
process any User Content to improve our existing Services and/or to develop new
products and services"*. The same document also bars use *"for any services
that require subject qualification or professional review, or as a substitute
for professional services, including but not limited to professional fields
such as medical care"* and *"high-risk automated decision-making in areas that
may materially affect the safety, rights and interests, or well-being of
individuals and society, such as health"*.
[Z.AI Terms of Service](https://chat.z.ai/legal-agreement/terms-of-service)

**NVIDIA — 2 models** (`nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free`,
`nvidia/nemotron-nano-12b-v2-vl:free`). OpenRouter's own provider record tags
`nvidia` as `training: true`, so both fail `data_collection: "deny"` before any
policy reading. Structural, not arguable.

**Reka — 1 model** (`rekaai/reka-edge`). Reka's terms: *"If you use the Services
on a free basis, you acknowledge and agree that Reka may use Your Content to
train, develop, and improve its machine learning models and related
technologies. This may include human review and other forms of analysis."*
Paid requests are excluded from that, so the answer depends on how OpenRouter
is billed — undisclosed. Moot anyway: `reka-edge` has a 16k context window, the
smallest in the candidate set, and would need the photo screen.
[Reka Terms of Use](https://reka.ai/legal/terms-of-use)

### E3. Ruled out on the absence of any policy to rely on

These vendors clear every structural bar — first-party pinnable endpoint,
image input, `tools` + `tool_choice`, not tagged as training. None of them
publishes anything resembling Anthropic's nutrition carve-out, and several
publish broad professional-advice or high-risk-decision restrictions with no
carve-out attached. For a project whose defence of this feature is "the vendor
says in writing that wellness advice is out of scope", that absence is the
rule-out.

- **Alibaba / Qwen — 20 models** (`qwen/qwen3.8-max`, `qwen3.7-flash` at
  $0.03/$0.13 — the cheapest capable model in the whole candidate set —
  `qwen3-vl-*`, …), served first-party by provider slug `alibaba`. The Model
  Terms OpenRouter names are Alibaba Cloud's International Website Product
  Terms of Service, whose §4.48 covers Model Studio; it addresses IP, Member
  Content and end-user consent, and contains no usage-policy treatment of
  health, nutrition or minors at all.
  [Alibaba Cloud Product Terms of Service](https://www.alibabacloud.com/help/en/legal/latest/alibaba-cloud-international-website-product-terms-of-service-v-3-8-0)
- **Mistral — 8 models** (`mistralai/mistral-medium-3.1` at $0.40/$2.00,
  `mistral-small-2603` at $0.15/$0.60, `ministral-*-2512`,
  `mistral-large-2512`), served first-party by `mistral`. Its Usage Policy
  (effective 11 June 2026) is the one European option, and it cuts the wrong
  way: under *Professional advice*, *"You shall not use our Mistral AI Products
  to provide professional advice without proper qualification. This includes,
  for instance: … Offering medical diagnoses, treatment suggestions, or **any
  form of health-related guidance**."* Extracting "two eggs and a slice of
  toast" into food names is not guidance, but the clause is broader than
  anything Anthropic imposes and there is no carve-out beside it.
  [Mistral Usage Policy](https://legal.mistral.ai/terms/usage-policy) ·
  [Commercial Terms of Service](https://legal.mistral.ai/terms/commercial-terms-of-service)
- **MiniMax — 1 model** (`minimax/minimax-m3`, $0.30/$1.20). Terms of Service
  effective 30 March 2026, read in a browser: no eating-disorder, nutrition or
  minors-audience clause; the only age wording is *"if you are under 18, please
  read this Agreement with a guardian and obtain their consent"*. Its AI Output
  section disclaims medical advice. Nothing prohibits this use and nothing
  permits it. OpenRouter tags `minimax` as `retainsPrompts: true`.
  [MiniMax Terms of Service](https://www.minimax.io/platform/protocol/terms-of-service)
- **ByteDance Seed — 6 models** (`bytedance-seed/seed-2.0-lite`, `seed-2.0-mini`,
  `seed-2-1-turbo`, …), first-party via `seed` (BytePlus). The BytePlus terms
  OpenRouter names contain no health, nutrition, minors or training clause.
  [BytePlus Terms of Service](https://docs.byteplus.com/en/docs/legal/docs-terms-of-service)
- **Xiaomi — 1 model** (`xiaomi/mimo-v2.5`, $0.14/$0.28). Terms exist at
  `platform.xiaomimimo.com` but the page did not render to text for automated
  reading; see [Not verified](#not-verified).
- **StepFun — 1 model** (`stepfun/step-3.7-flash`) and **Nex AGI — 2 models**
  (`nex-agi/nex-n2-pro`, `nex-n2-mini`). OpenRouter's `/api/v1/providers` lists
  **no terms-of-service URL at all** for `stepfun`, and none for `nex-agi`
  (privacy policy only). A vendor with no published terms cannot be assessed,
  and cannot be offered by a project that invites users to check where their
  photograph goes.
- **Amazon — 1 model** (`amazon/nova-2-lite-v1`, $0.30/$2.50), served via
  `amazon-bedrock`. The AWS Acceptable Use Policy and AWS Service Terms contain
  no eating-disorder clause and no general age clause (the only age wording in
  the Service Terms is a DeepRacer Student provision), and Bedrock is tagged
  `retainsPrompts: false`. It is excluded on the same reasoning that produced
  the vendor pin in the first place: routing to Amazon puts the request under
  Amazon's terms rather than under a policy with a nutrition carve-out, which
  is precisely the substitution constraint 5 exists to prevent.
  [AWS Acceptable Use Policy](https://aws.amazon.com/aup/) ·
  [AWS Service Terms](https://aws.amazon.com/service-terms/)

### E4. Ruled out structurally, before any policy question

- **38 models with no pinnable first-party endpoint.** Includes all
  `meta-llama/*` (weights published, not served by `meta`'s own endpoint),
  `thinkingmachines/*`, `dots-studio/*`, `openrouter/*` stealth models, and
  individual models from vendors that do serve others first-party —
  `anthropic/claude-3-haiku` (Bedrock only), `anthropic/claude-opus-4`
  (Vertex only), `anthropic/claude-sonnet-4` and `claude-opus-4.1` (Vertex and
  Bedrock only), plus several `openai/*`, `google/*`, `qwen/*`,
  `moonshotai/*`, `minimax/*`, `mistralai/*` and `x-ai/*` entries. Under
  `only: [...]` with `allow_fallbacks: false` these can only 404.
- **All 10 `~vendor/...-latest` aliases** in the candidate set (11 exist in
  total; `~deepseek/deepseek-v4-flash-latest` has no image input), e.g.
  `~anthropic/claude-sonnet-latest`,
  `~google/gemini-flash-latest`. OpenRouter describes each as a model that
  *"always redirects to the latest model in the … family"*. Offering one would
  change which model an existing user's photographs go to without an app
  update — the exact silent behaviour change the pin exists to prevent, and
  contrary to the reasoning already recorded in `AiModelCatalogue`.
- **All `:batch` variants**, at 50% of list price. OpenRouter's documentation
  index describes the Batch API as *"Submit and retrieve asynchronous batches
  of inference requests"*.
- **168 models with no image input**, which the photo path requires, plus a
  further **29** that accept images but do not advertise `tools` and
  `tool_choice`, which the forced tool call requires.

## Not verified

- **No live request was made.** Every capability and routing claim above is
  from OpenRouter's declarations about itself, not from a probe. In particular:
  that `only: ["z-ai"]` reaches `z-ai/fp8` follows from the documented base-slug
  rule, and that `only: ["xai"]` may or may not reach `xai/zdr` is genuinely
  unclear — the docs exclude "service tier endpoints" from base-slug matching
  and do not say whether a `/zdr` suffix counts as one. Running a probe would
  cost the user's own credit, so none was run.
- **Whether OpenRouter holds a written no-training agreement with Moonshot AI
  or Z.AI.** Both vendors' terms make training-on-content the default absent a
  separate written agreement; OpenRouter tags both `training: false`. Neither
  party publishes the contract. This is the crux of E2 and it is unresolvable
  from public documents.
- **Which Meta service tier OpenRouter buys** (Standard, no training; or
  Discounted, training with no opt-out). Not disclosed. Moot given §10.1.
- **Whether Reka's OpenRouter traffic is billed as paid**, which is what
  decides whether Reka's free-tier training clause applies.
- **Xiaomi's terms.** `https://platform.xiaomimimo.com/#/docs/terms/user-agreement`
  is client-rendered and returned no readable text to automated fetching; it
  was not read in a browser because `xiaomi/mimo-v2.5` fails E3 regardless.
- **Alibaba's Membership Agreement**, which §4.48 incorporates by reference and
  which is where an age or eligibility clause would live if one exists. Only
  the Product Terms were read.
- **Relative photo accuracy of every model named here.** Nothing in this
  document is a quality claim. The catalogue's stated rule — that membership
  requires a behavioural screen against a photo corpus, because advertised
  capability flags do not predict it — is untouched by any of this, and no
  model should be added on the strength of policy fit alone.
- **Anthropic Commercial Terms revision date.** The page carries no visible
  effective date; quotes are as published on 2026-08-16.

## Sources

OpenRouter (own API and docs):
[`/api/v1/models`](https://openrouter.ai/api/v1/models) ·
[`/api/v1/models/{author}/{slug}/endpoints`](https://openrouter.ai/api/v1/models/anthropic/claude-sonnet-5/endpoints) ·
[`/api/v1/providers`](https://openrouter.ai/api/v1/providers) ·
[`/api/frontend/v1/all-providers`](https://openrouter.ai/api/frontend/v1/all-providers) ·
[Provider Routing](https://openrouter.ai/docs/features/provider-routing) ·
[Batch API Quickstart](https://openrouter.ai/docs/batch-quickstart.md) ·
[Terms of Service](https://openrouter.ai/terms)

Vendor terms and policies:
[Anthropic Usage Policy](https://www.anthropic.com/legal/aup) ·
[Anthropic Commercial Terms](https://www.anthropic.com/legal/commercial-terms) ·
[OpenAI Usage Policies](https://openai.com/policies/usage-policies/) ·
[Google Cloud Service Specific Terms](https://cloud.google.com/terms/service-terms) ·
[Google Cloud Terms of Service](https://cloud.google.com/terms/) ·
[Google Generative AI Prohibited Use Policy](https://policies.google.com/terms/generative-ai/use-policy) ·
[Gemini API Additional Terms](https://ai.google.dev/gemini-api/terms) ·
[SpaceXAI Acceptable Use Policy](https://x.ai/legal/acceptable-use-policy) ·
[SpaceXAI Enterprise Terms](https://x.ai/legal/terms-of-service-enterprise) ·
[Meta Model API Terms of Service](https://ai.developer.meta.com/legal/terms-of-service) ·
[Mistral Usage Policy](https://legal.mistral.ai/terms/usage-policy) ·
[Mistral Commercial Terms](https://legal.mistral.ai/terms/commercial-terms-of-service) ·
[Moonshot AI model use agreement](https://platform.moonshot.ai/docs/agreement/modeluse) ·
[Z.AI Terms of Service](https://chat.z.ai/legal-agreement/terms-of-service) ·
[MiniMax Terms of Service](https://www.minimax.io/platform/protocol/terms-of-service) ·
[Alibaba Cloud Product Terms of Service](https://www.alibabacloud.com/help/en/legal/latest/alibaba-cloud-international-website-product-terms-of-service-v-3-8-0) ·
[BytePlus Terms of Service](https://docs.byteplus.com/en/docs/legal/docs-terms-of-service) ·
[AWS Acceptable Use Policy](https://aws.amazon.com/aup/) ·
[AWS Service Terms](https://aws.amazon.com/service-terms/) ·
[Reka Terms of Use](https://reka.ai/legal/terms-of-use) ·
[Sakana AI Terms of Service](https://console.sakana.ai/terms-of-service)

Related notes in this repo:
[`ai-legal-constraints.md`](ai-legal-constraints.md) ·
[`ai-cohort-restrictions.md`](ai-cohort-restrictions.md) ·
[`ai-open-research-questions.md`](ai-open-research-questions.md)

In-repo files cited:
[`lib/core/utils/ai_model_catalogue.dart`](../lib/core/utils/ai_model_catalogue.dart) ·
[`lib/features/add_meal/data/openrouter_meal_items_api.dart`](../lib/features/add_meal/data/openrouter_meal_items_api.dart) ·
[`tool/live_routing_policy.dart`](../tool/live_routing_policy.dart)
