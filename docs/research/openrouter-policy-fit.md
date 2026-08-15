# Do OpenRouter's terms preserve the policy fit Anthropic was chosen for?

Research for issue #656. All findings are from primary sources (the terms and policies
themselves), fetched 2026-08-15. Nothing here is legal advice.

## Summary

**No — not by default, and not for the reason you would expect.**

The problem is not that OpenRouter loosens anything. OpenRouter has no acceptable-use
policy of its own that touches health, nutrition or wellness at all, and no high-risk-use
category. Instead it *passes through* whatever the upstream provider requires, and makes
the developer solely responsible for knowing what that is (§§5.1, 5.2, 5.6, 5.8, 7).

The problem is that on OpenRouter a model ID does not determine which provider's terms
apply. `anthropic/claude-haiku-4.5` is served by **four** providers — Anthropic, Google
Vertex, Azure and Amazon Bedrock — and OpenRouter load-balances across them by default.
So selecting a Claude model through OpenRouter does not reliably put you under Anthropic's
Usage Policy alone; it can put you under Google Cloud's terms, which contain a flat
under-18 restriction that decision #7 rejected Google over.

The three findings that matter most:

1. Anthropic's Usage Policy — including the wellness carve-out that decision #7 relied on
   — expressly reaches brokered access. It survives the broker intact.
2. OpenAI's "disordered eating promotion or facilitation" prohibition also survives the
   broker intact, and OpenAI's Usage Policies have since added *more* nutrition-adjacent
   language ("promoting unhealthy dieting or exercise behavior to minors").
3. Half of decision #7's Google objection survives and half dies. The training-on-
   submissions objection **dies** (OpenRouter routes Google models under Google Cloud
   terms, which forbid training on customer data). The under-18 objection **survives**
   and is arguably stronger, because Google Cloud's Generative AI terms impose it on the
   developer directly as a "Use Restriction."

Practical consequence: the policy reasoning in decision #7 survives **only if the app
pins the provider**, which OpenRouter supports via `provider.only` /
`provider.order` + `allow_fallbacks: false`.

---

## Sources

| Document | URL | Version |
|---|---|---|
| OpenRouter Terms of Service | https://openrouter.ai/terms | Last Updated July 29, 2026 |
| OpenRouter Privacy Policy | https://openrouter.ai/privacy | Last Updated July 6, 2026 |
| OpenRouter Stealth Program EULA + AUP | https://openrouter.ai/terms/stealth | undated |
| OpenRouter provider ToS list ("Model Terms") | https://openrouter.ai/docs/features/provider-routing#terms-of-service | live |
| OpenRouter machine-readable provider list | https://openrouter.ai/api/v1/providers | live |
| Anthropic Usage Policy | https://www.anthropic.com/legal/aup | Effective September 15, 2025 |
| Anthropic Commercial Terms of Service | https://www.anthropic.com/legal/commercial-terms | Effective June 17, 2025 |
| OpenAI Usage Policies | https://openai.com/policies/usage-policies/ | Effective October 29, 2025 |
| OpenAI Terms of Use (row) | https://openai.com/policies/row-terms-of-use/ | Effective January 1, 2026 |
| OpenAI Services Agreement | https://openai.com/policies/business-terms/ | Effective January 1, 2026 |
| Google Cloud Service Specific Terms | https://cloud.google.com/terms/service-terms | live (page footer 2026) |
| Google Cloud Services Summary | https://cloud.google.com/terms/services | live |
| Google Generative AI Prohibited Use Policy | https://policies.google.com/terms/generative-ai/use-policy | Last Modified December 17, 2024 |
| Gemini API Additional Terms of Service | https://ai.google.dev/gemini-api/terms | Effective March 23, 2026 |

---

## 1. What do OpenRouter's own terms say about health, medical, nutrition or dietary use?

**Essentially nothing.** OpenRouter has no standalone acceptable-use policy for the main
service. Prohibited conduct lives in §7 of the ToS, and every item there is about
platform abuse — illegal use, crypto proceeds, fake identities, reselling API access,
scraping, IP infringement, red teaming, malware, fraud. There is no content or subject-
matter category at all. Health, medical, nutrition, diet, eating disorders and body image
appear **nowhere** in §7.

The only §7 items with any bearing on this question are the two that point back upstream:

> use the Service for any illegal purpose, in violation of any local, state, national, or
> international law or in violation of any applicable Model Terms

> post, upload, or distribute any Input or other content that is unlawful, or is not in
> compliance with the Terms of Service for the Model or Provider you are using

**Is there a high-risk-use-case category?** No — not in the sense Anthropic's policy has
one. "High-risk" appears in OpenRouter's terms only twice, and in both places it allocates
*responsibility* rather than defining a category or imposing requirements:

§5.6 (Configuration and Model Selection):

> You are solely responsible for selecting the Models you use, configuring your account
> settings, setting permissions and restrictions for your Authorized Users and your
> customers, and determining whether each Model and the applicable Model Terms are
> appropriate for your use case, including any regulated, high-risk, sensitive, or
> customer-facing use.

§16.1 (Disclaimers), in all caps:

> THE OPENROUTER ENTITIES DO NOT WARRANT THAT THE OUTPUT WILL BE AVAILABLE FOR YOUR
> INTENDED USE OR SUITABLE FOR A PARTICULAR PURPOSE, INCLUDING WITHOUT LIMITATION ANY
> REGULATED, HIGH-RISK, SAFETY-CRITICAL, LEGAL, MEDICAL, FINANCIAL, EMPLOYMENT, OR
> CUSTOMER-FACING USE.

And §16.2:

> YOU ARE SOLELY RESPONSIBLE FOR EVALUATING OUTPUTS, IMPLEMENTING APPROPRIATE HUMAN REVIEW
> AND SAFEGUARDS, AND DETERMINING WHETHER ANY MODEL, MODEL TERMS, INPUT, OUTPUT, OR USE
> CASE IS APPROPRIATE FOR YOUR BUSINESS, LEGAL, SECURITY, PRIVACY, AND COMPLIANCE
> REQUIREMENTS.

So wellness/nutrition falls neither inside nor outside an OpenRouter high-risk category,
because no such category exists. OpenRouter takes no position; it disclaims medical
suitability and pushes the classification question entirely onto the developer.

**One exception, narrow:** OpenRouter *does* have a real AUP for its Stealth Program
(unreleased/anonymised models), at https://openrouter.ai/terms/stealth, Exhibit A. Clause
(iii) forbids submitting to Stealth Models

> any information or data that is subject to safeguarding and/or limitations on
> distribution pursuant to applicable laws and/or regulations, including information that
> you know or reasonably should know is from or about children under the age of 13 or
> other age of online minority in the applicable jurisdiction or that includes health
> information, financial information, or other categories of sensitive information

That is a genuine health-data prohibition, but it applies **only to Stealth Program
models**, not to OpenRouter generally. If OpenNutriTracker ever routes to a stealth/cloaked
model, food logs plausibly count as health information and this clause bites. Avoiding
stealth models is the simple mitigation.

---

## 2. Do upstream provider policies bind the end user?

**Yes, explicitly and in both directions — OpenRouter pushes them down, and at least
Anthropic pulls them across.**

### OpenRouter's flow-down (ToS §5)

§5.1 (Applicability and Acceptance):

> By accessing or using any Model through the Service, you agree, and will ensure that your
> Authorized Users and customers agree, to comply with the applicable terms for each Model
> ("Model Terms"), a list of which is provided here.

> You are solely responsible for reviewing the Model Terms applicable to each Model before
> accessing or using that Model and for determining whether the applicable Model Terms
> allow you and your Authorized Users to access and use the Service, Inputs, and Outputs
> as you intend.

§5.2 (Flow-Down to Authorized Users):

> You will require that all of your Authorized Users and customers access and use the
> Service and Models only in accordance with this Agreement, any documentation provided by
> OpenRouter on the Site and Service, and the applicable Model Terms. You will be
> responsible for all acts and omissions of your Authorized Users, including any violation
> of applicable Model Terms.

§5.8 (Conflicts) settles the precedence question:

> The applicable Model Terms govern your, your Authorized Users', and your customers'
> access to and use of the applicable Model to the extent required by the applicable Model
> Provider. OpenRouter does not modify, waive, or limit any Model Terms unless expressly
> stated in writing.

§5.3 makes acceptance rolling:

> Your continued access to or use of a Model after the Model Terms for that Model are
> updated constitutes your acceptance of such updated Model Terms.

And §20 gives providers standing:

> Model Providers are intended third-party beneficiaries of Sections 5, 6.1, 15, 17, and
> this Section 20 to the extent such provisions relate to your, Authorized Users', or your
> customers' access to or use of the applicable Models, compliance with applicable Model
> Terms, User Content, Inputs, Outputs, usage restrictions, or limitations of liability.

§5.5 backs it with enforcement: OpenRouter may suspend or terminate access if it believes
you "violated, or may violate, any Model Terms, or if we are required or requested to do
so by the applicable Model Provider."

So yes: **a user selecting an OpenAI model through OpenRouter thereby becomes subject to
OpenAI's usage policy.** That is the direct effect of §§5.1, 5.2 and 5.8 read with the
provider ToS list.

### The catch: OpenRouter's list of Model Terms may be wrong, and it disclaims liability

The provider list is at
https://openrouter.ai/docs/features/provider-routing#terms-of-service, which says only:

> You can view the terms of service for each provider below. You may not violate the terms
> of service or policies of third-party providers that power the models on OpenRouter.

But §6.1 of the ToS disclaims its accuracy:

> While we strive to keep the Model Terms up to date every time we add or remove each Model
> from the Service, there may be incorrect or missing terms. [...] However, OpenRouter is
> not liable for errors or misrepresentations made in any Model Terms. You are encouraged
> to review Model Terms yourself as needed.

This matters concretely. The machine-readable list at https://openrouter.ai/api/v1/providers
gives, for the three providers in question:

| Provider slug | `terms_of_service_url` |
|---|---|
| `anthropic` | https://www.anthropic.com/legal/commercial-terms |
| `openai` | https://openai.com/policies/row-terms-of-use/ |
| `google-ai-studio` | https://cloud.google.com/terms/ |
| `google-vertex` | https://cloud.google.com/terms/ |
| `azure` | https://www.microsoft.com/en-us/legal/terms-of-use?oneroute=true |
| `amazon-bedrock` | https://aws.amazon.com/service-terms/ |

Two of these are questionable. OpenRouter points **Google AI Studio** at the Google Cloud
Platform terms, when Google AI Studio's own governing document is the Gemini API Additional
Terms of Service at https://ai.google.dev/gemini-api/terms — a materially different
document (see Q4). And it points **OpenAI** at the consumer Terms of Use rather than the
Services Agreement. Both still incorporate the respective Usage Policies, so the *policy*
answer is unchanged, but it confirms you cannot treat OpenRouter's list as authoritative.

### Anthropic pulls across independently

Anthropic does not wait to be flowed down to. The first sentence of the Usage Policy:

> Our Usage Policy (also referred to as our "Acceptable Use Policy" or "AUP") applies to
> anyone who can submit inputs to Anthropic's products and/or services, including via any
> authorized resellers or passthrough access, all of whom we refer to as "users."

"Passthrough access" is exactly what OpenRouter is. Anthropic's Usage Policy therefore
applies to an OpenNutriTracker user on a Claude model whether or not OpenRouter's §5 says
so. It is also incorporated into the Commercial Terms at D.2:

> Customer and its Users may only use the Services in compliance with these Terms,
> including (a) the Usage Policy [...]

### OpenAI flows down through its Services Agreement

OpenAI Services Agreement §3.3 (Restrictions):

> Customer will not, and will not permit End Users to: (a) use the Services or Customer
> Content in a way that violates applicable laws or OpenAI Policies; [...] (c) allow minors
> to use OpenAI Services without consent from their parent or guardian;

"OpenAI Policies" is defined to mean "the Service-Specific Terms, Sharing and Publication
Policy, and Usage Policies", and "End User" is defined to include anyone "who uses Customer
Applications." The consumer-facing Terms of Use say the same more simply:

> In using our Services, you must comply with all applicable laws as well as our Sharing &
> Publication Policy, Usage Policies, and any other documentation, guidelines, or policies
> we make available to you.

---

## 3. Does anything restrict consumer use, or use by services likely to be accessed by under-18s?

This is where the answer diverges sharply by provider.

### OpenRouter itself: no consumer-use restriction

Nothing in the ToS restricts consumer use. §16.1 disclaims warranties for "CUSTOMER-FACING
USE" but does not forbid it, and §5.6 expressly contemplates "customer-facing use" as
something the developer may choose.

### Anthropic: consumer use permitted, with disclosure duties

Anthropic's Usage Policy is *structured around* consumer use rather than against it. The
High-Risk Use Case Requirements "apply to specific consumer-facing use cases," and the
Additional Use Case Guidelines cover "consumer-facing chatbots, products serving minors."
Two obligations attach:

> All consumer-facing chatbots, including any external-facing or interactive AI agent, must
> disclose to users that they are interacting with AI rather than a human. This disclosure
> must be provided at a minimum at the beginning of each chat session.

> Products serving minors, including organizations providing minors with the ability to
> directly interact with products that incorporate our API(s), must comply with the
> additional guidelines outlined in our Help Center article.

Note the difference in kind: Anthropic imposes *conditions* on serving minors. It does not
prohibit it.

### Google: a flat prohibition, in both terms families

**Google Cloud Service Specific Terms**, §20 (Generative AI Services), subsection (d) —
this is the terms family OpenRouter routes Google models under:

> **Age Restrictions.** Customer will not, and will not allow End Users to, use a Generative
> AI Service as part of a website, Customer Application, or other online service that is
> directed towards or is likely to be accessed by individuals under the age of 18.

Subsection (g) escalates it: "The restrictions contained in subsections (d) and (e) above
are deemed to be 'Restrictions' or 'Use Restrictions' under the applicable Agreement." And
(f) allows immediate suspension for suspected violation of (d).

**Gemini API Additional Terms** (the AI Studio document) says the same plus the consumer
prohibition:

> You must be 18 years of age or older to use the APIs. You also will not use the Services
> as part of a website, application, or other service (collectively, "API Clients") that is
> directed towards or is likely to be accessed by individuals under the age of 18.

> Use of Google AI Studio and Gemini API is for developers building with Google AI models
> for professional or business purposes, not for consumer use.

So decision #7's characterisation of Google is accurate and, for the age restriction,
survives the broker under *either* Google terms document.

### OpenAI: minors permitted with parental consent, but with nutrition-specific limits

OpenAI does not prohibit consumer use or under-18 access. Terms of Use:

> Minimum age. You must be at least 13 years old or the minimum age required in your
> country to consent to use the Services. If you are under 18 you must have your parent or
> legal guardian's permission to use the Services.

But the Usage Policies add a "Keep minors safe" section whose bullets are unusually close
to this app's subject matter — see Q4.

---

## 4a. Does OpenAI's "disordered eating" prohibition reach a user selecting an OpenAI model via OpenRouter?

**Yes.** The chain is unbroken: OpenRouter ToS §5.1/§5.2 → OpenAI Terms of Use / Services
Agreement → Usage Policies.

The prohibition, verbatim, from the "Protect people" section:

> suicide, self-harm, or disordered eating promotion or facilitation

The Usage Policies' own scoping sentence is "Your use of OpenAI services must follow these
Usage Policies," and the changelog entry for the current version (Effective October 29,
2025) confirms it is not API-vs-consumer split:

> 2025-10-29: We've updated our Usage Policies to reflect a universal set of policies across
> OpenAI products and services.

**The exposure is broader than decision #7 recorded.** Three further bullets sit awkwardly
beside a calorie tracker, and two are nutrition-specific. From "Keep minors safe":

> promoting unhealthy dieting or exercise behavior to minors

> shaming or otherwise stigmatizing the body type or appearance of minors

From "Protect people":

> provision of tailored advice that requires a license, such as legal or medical advice,
> without appropriate involvement by a licensed professional

And from "Empower people", which prohibits "automation of high-stakes decisions in sensitive
areas without human review", with "medical" listed among the sensitive areas.

Two observations. First, "promoting unhealthy dieting or exercise behavior to minors" is a
much more direct hit on a calorie tracker than "disordered eating promotion or facilitation"
— an app that computes and displays a calorie deficit target to a 15-year-old is squarely in
the zone that bullet describes, and OpenNutriTracker has no age gate. Second, OpenAI has no
wellness carve-out anywhere. Where Anthropic explicitly excludes nutrition advice from its
high-risk category, OpenAI's "tailored advice that requires a license" bullet leaves the
boundary between nutrition guidance and medical advice entirely undefined. Decision #7's
discomfort with OpenAI is, if anything, better founded now than when it was written.

## 4b. Do Google's train-on-submissions terms reach a user selecting a Gemini model via OpenRouter?

**No — this specific objection does not survive the broker.** But it is replaced by a
different Google restriction that does.

Decision #7's training objection comes from the Gemini API Additional Terms' Unpaid Services
section:

> When you use Unpaid Services, including, for example, Google AI Studio and the unpaid
> quota on Gemini API, Google uses the content you submit to the Services and any generated
> responses to provide, improve, and develop Google products and services and machine
> learning technologies

> To help with quality and improve our products, human reviewers may read, annotate, and
> process your API input and output.

Those clauses are scoped to **Unpaid Services**. Three things defeat their application here:

1. OpenRouter is a paying customer. The same document's Paid Services section says:
   "Google doesn't use your prompts (including associated system instructions, cached
   content, and files such as images, videos, or documents) or responses to improve our
   products."
2. OpenRouter routes Google models under Google Cloud terms (see the provider table in Q2),
   where §18 (Training Restriction) of the Service Specific Terms is unconditional:
   > Google will not use Customer Data to train or fine-tune any AI/ML models without
   > Customer's prior permission or instruction.
   And §20(h): absent permission, Google "will not store outside Customer's Account (i)
   Customer Data prompted to a Generative AI Service for longer than is reasonably necessary
   to create the Generated Output, or (ii) the Generated Output."
3. OpenRouter ToS §6.1: "Where possible, OpenRouter has opted out of model training with the
   Models it uses."

**What replaces it.** Routing Gemini under Google Cloud terms swaps the training problem for
the age problem quoted in Q3 — §20(d)'s "directed towards or is likely to be accessed by
individuals under the age of 18," deemed a Use Restriction by §20(g). Plus §20(e):

> **Healthcare Restrictions.** Customer will not, and will not allow End Users to, use the
> Generative AI Services for clinical purposes (for clarity, non-clinical research,
> scheduling, or other administrative tasks is not restricted), as a substitute for
> professional medical advice, or in any manner that is overseen by or requires clearance or
> approval from any applicable regulatory authority.

§20(c) also folds the Generative AI Prohibited Use Policy into the Cloud AUP. That policy
(Last Modified December 17, 2024) contains no nutrition or eating-disorder clause; its only
adjacent items are "Facilitates self-harm" and "Facilitating misleading claims related to
governmental or democratic processes or harmful health practices, in order to deceive."

Net: for Gemini via OpenRouter, decision #7's *training* objection is obsolete, its
*consumer-use* objection is obsolete (the "not for consumer use" sentence lives only in the
AI Studio terms, not the Cloud terms), and its *under-18* objection survives and hardens.
The healthcare restriction is comfortably satisfiable — a calorie tracker is not clinical
practice — but "a substitute for professional medical advice" is looser language than
Anthropic's explicit wellness carve-out.

**Caveat.** OpenRouter lists `google-ai-studio` under Cloud terms while AI Studio's actual
governing document is the Gemini API Additional Terms. Both `google-ai-studio` and
`google-vertex` endpoints serve `google/gemini-2.5-flash`. If a request lands on an
AI Studio endpoint and the AI Studio terms in fact govern, then the "not for consumer use"
sentence *does* apply and OpenNutriTracker is offside on its face. I could not resolve this
from primary sources — see "Not established" below.

---

## 5. Age and jurisdiction restrictions on OpenRouter accounts

**Age.** ToS §2 (Eligibility):

> You must be at least 13 years of age to use the Service. By agreeing to these Terms, you
> represent and warrant to us that: (a) you are at least 13 years of age; (b) you have not
> previously been suspended or removed from the Service; and (c) your registration and your
> use of the Service is in compliance with all applicable laws and regulations. If you are
> under 18 years of age, you must have your parent or guardian's permission to use the
> Service.

The Privacy Policy (Last Updated July 6, 2026) repeats it: "This Site is offered and
available to users who are 13 years of age or older."

Note the mismatch. OpenRouter's own floor is 13, but a developer routing to Google inherits
Google's 18 floor *and* the obligation that the app not be "likely to be accessed by"
under-18s. The broker's permissiveness does not help; §5.8 makes the stricter Model Terms
govern.

**Jurisdiction.** Three separate mechanisms:

- ToS §18: "These Terms are governed by the laws of the State of New York without regard to
  conflict of law principles." §19 mandates binding arbitration with a class-action waiver.
- ToS §5.7 (Model Restrictions) creates a per-provider geographic gate:
  > certain Model Providers do not authorize users either (i) acting on behalf of certain
  > entities or organizations, or (ii) who are located in certain countries or regions, to
  > access their Models, as described in their Model Terms and documentation ("Restricted
  > Models"), and that you may not access these Restricted Models through our Service.

  Circumvention (VPNs, proxies) is "a material breach subject to immediate suspension
  and/or termination."
- ToS §6.8 warns that OpenRouter's country-of-origin reporting to providers is unreliable
  ("it is not always possible to accurately represent your country of origin, and this
  limitation may affect your ability to use the Service"), and disclaims responsibility for
  incorrect location reporting.

Upstream, Anthropic maintains a Supported Regions Policy (country list at
https://www.anthropic.com/supported-countries) and OpenAI's Services Agreement §16.12
states "Customer and End Users may not access or offer access to the Services outside of the
Supported Countries and Territories," with export-control obligations in §16.11. For a
globally distributed F-Droid/Play app these are the developer's problem to police under
OpenRouter §5.2, with §6.8 conceding the mechanism is imperfect.

---

## Does decision #7's reasoning survive?

**Partially, and only under an explicit provider pin.**

### What survives

**Anthropic's wellness carve-out survives fully.** The exact sentence decision #7 relied on
is still live in the Usage Policy (Effective September 15, 2025), under "High-Risk Use
Cases":

> Healthcare: Use cases related to healthcare decisions, medical diagnosis, patient care,
> therapy, mental health, or other medical guidance. Wellness advice (e.g., advice on sleep,
> stress, nutrition, exercise, etc.) does not fall under this category

And it reaches brokered access by its own terms — "including via any authorized resellers or
passthrough access." A Claude request routed through OpenRouter to the `anthropic` provider
lands in exactly the policy position decision #7 chose. Nothing in OpenRouter's terms
weakens it, because OpenRouter adds no subject-matter restrictions of its own and §5.8 says
it "does not modify, waive, or limit any Model Terms."

**The OpenAI objection survives and strengthens.** Decision #7 rejected OpenAI partly over
"disordered eating promotion or facilitation." That bullet is unchanged, applies universally
across OpenAI products, and reaches OpenRouter users through §5.1/§5.2. The October 2025
Usage Policies added "promoting unhealthy dieting or exercise behavior to minors" and
"shaming or otherwise stigmatizing the body type or appearance of minors" — both closer to a
calorie tracker's core function than the original bullet. There is still no wellness
carve-out anywhere in OpenAI's policies.

**Half the Google objection survives.** The under-18 restriction is present in *both* Google
terms families and is deemed a Use Restriction under the Cloud terms, enforceable by
immediate suspension. OpenNutriTracker is a general-audience consumer nutrition app with no
age gate; "likely to be accessed by individuals under the age of 18" is difficult to argue
against.

### What does not survive

**The Google training objection is obsolete on this path.** OpenRouter routes Google models
under Google Cloud terms as a paying customer, where §18 forbids training on customer data
outright and §20(h) forbids retention beyond what generating the output requires. The
free-tier training and human-review clauses that decision #7 cited apply to Unpaid Services
only. The "not for consumer use" sentence likewise lives only in the AI Studio terms.

**Most importantly: the reasoning does not survive a bare model selection.** Decision #7
implicitly assumed model identity determines governing policy. On OpenRouter it does not.
Querying https://openrouter.ai/api/v1/models/anthropic/claude-haiku-4.5/endpoints returns
endpoints from **Anthropic, Google Vertex, Azure, and Amazon Bedrock**. The provider-routing
documentation states:

> OpenRouter routes requests to the best available providers for your model. By default,
> requests are load balanced across the top providers to maximize uptime.

So an unpinned `anthropic/claude-haiku-4.5` request may be served by Google Vertex — putting
the request under Google Cloud's Service Specific Terms, including §20(d)'s under-18
restriction, which is the precise clause decision #7 rejected Google to avoid. Anthropic's
Usage Policy still applies (via "passthrough access"), but it applies *in addition to*, not
instead of, the serving platform's terms. The policy fit Anthropic was chosen for is
therefore not a property of choosing a Claude model; it is a property of choosing a Claude
model **and** pinning the provider.

### Which models it survives for

| Selection | Governing policy | Verdict |
|---|---|---|
| Claude, `provider.only: ["anthropic"]`, `allow_fallbacks: false` | Anthropic Usage Policy only | **Survives.** Wellness carve-out intact; obligations are the AI-disclosure duty and the minors guidelines. |
| Claude, unpinned (default) | Anthropic AUP **plus** whichever of Google Cloud / AWS / Microsoft terms served the request | **Does not survive.** Can silently inherit Google's under-18 Use Restriction. |
| Any OpenAI model | OpenAI Usage Policies | **Does not survive.** Disordered-eating and minors-dieting bullets apply; no wellness carve-out. |
| Any Gemini model | Google Cloud Service Specific Terms §20 (per OpenRouter's list) | **Does not survive** the under-18 restriction, though the training objection falls away. |
| Any stealth/cloaked model | Stealth AUP Exhibit A | **Does not survive.** Clause (iii) forbids submitting health information. |

### Additional obligations the broker adds regardless of model

- §5.1 puts an ongoing duty on the developer to review Model Terms for every model offered,
  and §5.3 makes silent upstream changes binding on continued use. If the app lets users
  pick from OpenRouter's full catalogue (413 models at time of writing), that duty scales
  with the catalogue.
- §5.2 makes the developer "responsible for all acts and omissions of your Authorized
  Users," which on a BYO-key consumer app is a meaningful transfer of risk.
- The default `data_collection: "allow"` setting routes to providers "which store user data
  non-transiently and may train on it." Nutrition logs are health-adjacent; if the app
  brokers on users' behalf, `data_collection: "deny"` or `zdr: true` is worth setting
  deliberately. OpenRouter cautions the tag "is not a definitive source of third party data
  policies, but represents our best knowledge."

### Recommendation implied by the findings

If the project adopts OpenRouter, decision #7's policy reasoning can be preserved, but only
by making the pin part of the request rather than a user preference: `provider.only:
["anthropic"]` with `allow_fallbacks: false`, on a Claude model, and excluding stealth
models. Letting users freely choose any OpenRouter model reopens every question decision #7
closed — and does so invisibly, since the routing decision is not surfaced to the user.

---

## Not established from primary sources

1. **Which Google terms actually govern `google-ai-studio` endpoints.** OpenRouter's
   provider list points AI Studio at https://cloud.google.com/terms/, but Google's own
   document for AI Studio and the Gemini API is https://ai.google.dev/gemini-api/terms.
   These differ materially — the AI Studio terms add "not for consumer use" and a flat
   "18 years of age or older to use the APIs." I could not find a primary source resolving
   which applies to OpenRouter's AI Studio endpoints, and OpenRouter §6.1 explicitly
   disclaims the accuracy of its own list. Treat the stricter (AI Studio) reading as the
   safe assumption.

2. **Whether Google Cloud §20 covers Anthropic models served on Vertex.** The Cloud Services
   Summary defines Generative AI Services to include the "Gemini Enterprise Agent Platform
   API (formerly Vertex AI API)", which "enables customers to access generative AI foundation
   models via an API" — which would capture Claude on Vertex. But §19(a) says "Customer's use
   of Separate Offerings is subject to separate terms and conditions," and I found no primary
   source stating whether partner models in Vertex Model Garden are Generative AI Services or
   Separate Offerings. This is the pivot for whether an unpinned Claude request can inherit
   Google's under-18 restriction. It probably can; I cannot prove it.

3. **Whether Azure- or Bedrock-served Claude adds further restrictions.** OpenRouter points
   these at https://www.microsoft.com/en-us/legal/terms-of-use?oneroute=true and
   https://aws.amazon.com/service-terms/ respectively. Neither was examined in depth. The
   Microsoft link in particular appears to be the general website terms of use rather than
   the Azure OpenAI / Azure AI Foundry service terms, so it is likely another instance of
   finding (1).

4. **How OpenRouter classifies nutrition prompts internally.** ToS §6.5 discloses a hosted
   categorisation model applied to all Inputs ("OpenRouter uses a hosted model for
   categorizing Inputs, which does not store or log any Inputs provided to it"), used for
   public Rankings. No primary source describes the category taxonomy, so I cannot say
   whether food-log prompts would surface in any public aggregate.

5. **Whether any provider has enforced these clauses against a nutrition or calorie-tracking
   app.** No primary source; enforcement actions are not published.
