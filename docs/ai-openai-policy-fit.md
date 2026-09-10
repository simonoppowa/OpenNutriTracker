# Does OpenAI's usage policy permit a BYO-key nutrition tracker?

**Verdict: nothing in OpenAI's current published terms prohibits this app, and
the rejection recorded in [#599](https://github.com/simonoppowa/OpenNutriTracker/issues/599)
decision #7 and [#656](https://github.com/simonoppowa/OpenNutriTracker/issues/656)
does not survive a re-reading.** All three clauses are conduct tests, and the
app's conduct does not meet any of them. The disordered-eating clause in
particular is **narrower than the one the project already accepted from
Anthropic**, so it cannot be what separates the two vendors. But the cover
OpenAI offers is the *absence of a prohibition*, never a carve-out, and one
clause the earlier reading had backwards — Services Agreement §3.3(g) — now
cuts against BYO-key rather than for it. This is a documents review, not legal
advice.

## Bottom line up front

1. **The bound party is the key holder, and under BYO-key that is the user.**
   Both consumer Terms of Use say the API is governed by the business terms,
   and the Services Agreement's restrictions run against "Customer". A user
   with their own key and their own billing is the Customer. This project
   holds no account, signs nothing, and §16.10 gives it no rights under the
   agreement either. Our exposure is reputational and second-hand, not
   contractual.
2. **§3.3(g) is a restriction, not a permission, and the prior note had it
   backwards.** It reads *"buy, sell, or transfer API keys from, to, or with a
   third party."* Whether pasting your own key into third-party software you
   installed on your own device is a "transfer" is genuinely unresolved. It is
   the single most load-bearing ambiguity in this note, and it did not appear
   in either earlier evaluation. §2.2 is real and does contemplate app
   distribution — but it contemplates the *opposite* shape, where the developer
   holds the key.
3. **None of the three prohibitions is met.** No advice is given, so the
   licensed-advice clause never engages; nothing is promoted to anyone, so the
   minors clause never engages; and a search-term extractor with no nutrition
   fields in its schema does not promote or facilitate disordered eating. See
   [Section B](#b-clause-by-clause).
4. **The distinction from Google is real and load-bearing.** Google Cloud
   §20(d) is a **distribution** test — *"directed towards or is likely to be
   accessed by individuals under the age of 18"* — which a general-audience app
   on Play and F-Droid fails on the day it ships, whatever it does. OpenAI has
   **no distribution or audience test anywhere** in the Usage Policies, the
   Services Agreement or the Service terms. Its minors clauses ask what you
   *do*. The two rejections were never the same rejection, and #656 conflated
   them.
5. **There is no equivalent to Anthropic's carve-out. Say so plainly.**
   Anthropic writes *"Wellness advice (e.g., advice on sleep, stress,
   nutrition, exercise, etc.) does not fall under this category"* — nutrition
   is named and excluded. OpenAI names nutrition nowhere. What it offers is
   silence, plus one line pointing mildly the other way (Service terms §9,
   *"Our Services are not intended for use in the diagnosis or treatment of any
   health condition"*). Under the project's own standard, silence is materially
   weaker cover than a carve-out, and that difference should decide the vendor
   question even though it does not decide the permission question.
6. **Two clauses nobody was looking at matter more than one that was.** Service
   terms §6 restricts Visual Capabilities in a way that touches the photo path,
   and §3.3(c) is the only age clause on the whole API path. Neither appears in
   #656. See [Section E](#e-clauses-nobody-was-looking-at).

**This does not make OpenAI a good choice, only a permitted one.** The
catalogue's separate technical objection stands untouched: `strict: true`
breaks every `openai/*` call, and `openai/gpt-5.4-nano` failed the photo screen
outright ([`ai-model-candidates.md`](ai-model-candidates.md),
[`lib/core/utils/ai_model_catalogue.dart`](../lib/core/utils/ai_model_catalogue.dart)).
Policy fit is a necessary condition, not a sufficient one, and no model should
be added on the strength of this note alone.

## How this was read

Primary sources only, all read on 2026-08-16 directly from openai.com,
cloud.google.com and anthropic.com. openai.com returns HTTP 403 to automated
fetching, so every OpenAI quote below was read in a real browser against the
live page, not a mirror, cache or PDF copy. No secondary summary, law-firm
client alert or blog post is cited as evidence anywhere in this note; where
search turned up commentary about these clauses it was discarded.

| Document | Date it carries |
| --- | --- |
| [Usage policies](https://openai.com/policies/usage-policies/) | Effective **October 29, 2025** |
| [OpenAI Services Agreement](https://openai.com/policies/services-agreement/) | Updated **December 1, 2025**; Effective **January 1, 2026** |
| [Service terms](https://openai.com/policies/service-terms/) | Updated **June 12, 2026** |
| [Europe Terms of Use](https://openai.com/policies/terms-of-use/) | Updated **January 16, 2026** |
| [Terms of Use (rest of world)](https://openai.com/policies/row-terms-of-use/) | no date extracted — see [Not verified](#not-verified) |
| [Sharing & publication policy](https://openai.com/policies/sharing-publication-policy/) | Updated **November 14, 2022** |
| [Anthropic Usage Policy](https://www.anthropic.com/legal/aup) | Effective **September 15, 2025** |
| [Google Cloud Service Specific Terms](https://cloud.google.com/terms/service-terms) | Last modified **July 29, 2026** |

The behaviour the clauses are read against is the shipped behaviour, verified
in source rather than assumed:
[`mealItemsToolSchema`](../lib/features/add_meal/domain/meal_items_api.dart)
has exactly three fields — `query`, `quantity`, `unit` — with
`additionalProperties: false` and `required: ['query']`. There is no nutrition
field, so a model has nowhere to put a calorie or a macro even if asked. The
confirmation step in
[`bulk_add_screen.dart`](../lib/features/add_meal/presentation/screens/bulk_add_screen.dart)
is documented as *"not optional"*. Both interpreters' prompts open with "You do
not estimate nutrition".

## A. Who is bound, and by which document

**The API is not on the consumer terms.** Both consumer Terms of Use say so in
identical words: *"Our Business Terms govern use of ChatGPT Enterprise, our
APIs, and our other services for businesses and developers."* The Business
Terms are now the Services Agreement — the page carries a "View previous
business terms" link, confirming the succession.

**The Services Agreement claims the API path regardless of who holds the key.**
Its scope line: *"This OpenAI Services Agreement only applies to use of
OpenAI's APIs, ChatGPT Enterprise, ChatGPT Business, ChatGPT for Clinicians,
and other services for customers who are businesses and developers, and does
not apply to OpenAI services used by consumers or individuals unless specified
above."* APIs are specified above, so API use is inside. A hobbyist with a
personal key is treated as a developer. This is the natural reading; it is not
the only possible one, and the sentence is clumsy enough that a contrary
reading is not absurd.

**The restriction that carries the Usage Policies is §3.3(a):** *"Customer will
not, and will not permit End Users to: (a) use the Services or Customer Content
in a way that violates applicable laws or OpenAI Policies"*. §17 defines
*"OpenAI Policies"* as *"the Service-Specific Terms, Sharing and Publication
Policy, and Usage Policies."* So the Usage Policies bind **Customer** — the
entity with the account and the billing relationship. Under BYO-key that is the
user, and only the user.

**The project is not a party.** It has no account, no Order Form, no key, and
pays nothing. §16.10: *"There are no intended third-party beneficiaries to this
Agreement"* — so the arrangement gives this project no rights either, which is
worth stating because it means the app cannot rely on anything in the agreement
as protection.

### What §2.2 actually says

The prior evaluation cited §2.2 as contemplating BYO-key. It does not. Verbatim:

> **2.2. Use.** OpenAI grants Customer a non-exclusive right to access and use
> the Services during the Term. This includes the right to use OpenAI's API to
> integrate the Services into Customer Applications and to make Customer
> Applications available to End Users.

That is a permission for the **developer-as-Customer** shape: the developer
holds the key, builds a Customer Application, ships it to End Users, and
answers for them under §3.2 (*"Customer is responsible for all activities that
occur under its Account, including the activities of End Users … who access the
Services through a Customer Application"*). That is exactly the arrangement
BYO-key exists to avoid, and it is the arrangement under which the developer
*would* be squarely bound by the Usage Policies.

There is a definitional gap under BYO-key. *"Customer Application"* means
*"Customer's applications, products, or services that integrate with an OpenAI
API."* When the user is the Customer, OpenNutriTracker is not the Customer's
application — the user did not build it. The agreement has no category for
"third-party software the Customer runs with their own key". The arrangement is
therefore **neither expressly permitted nor expressly forbidden**, and §2.2
does not shift the obligation, does not permit the arrangement, and does not
push a flow-down duty onto us. It simply addresses a different shape.

### §3.3(g): the finding that changes the picture

> **3.3. Restrictions.** Customer will not, and will not permit End Users to:
> … (g) buy, sell, or transfer API keys from, to, or with a third party;

This is a **prohibition**, and the prior note's characterisation of it as
contemplating BYO-key is wrong. The question it raises is real: when a user
pastes their own key into an app they installed, is that a "transfer … to … a
third party"?

Arguments that it is not, on the shipped design:

- The project never receives the key. It is held in
  [`ai_credential_storage`](../lib/core/utils/ai_credential_storage.dart) on
  the user's device and travels only from that device to OpenAI. There is no
  proxy and no server-side component.
- The clause sits in a list about commerce and account integrity — buying,
  selling, reselling (§3.1: *"Customer may not resell or lease access to its
  Account"*), sharing credentials *"between multiple users"*. Every neighbour
  concerns a key moving to a different *person*. Here it does not.
- Nobody but the Customer ever uses the key, and all billing lands on the
  Customer.

The argument that it is: the key is made readable by software the Customer did
not write and does not control, and "transfer … with a third party" is broad
enough to be read as reaching that.

**This is genuinely ambiguous and should not be resolved in either direction
here.** It is, however, the clause a BYO-key design most plausibly trips, and
it is worth more attention than the three clauses the ticket was written
about. If it were ever read against us, the remedy is unattractive: BYO-key
without the user handing the key to anything is not a design that exists.

## B. Clause by clause

### B1. *"suicide, self-harm, or disordered eating promotion or facilitation"*

Under **Protect people**, Usage Policies effective 29 October 2025. Verbatim:

> Protect people. Everyone has a right to safety and security. So you cannot
> use our services for: … suicide, self-harm, or disordered eating promotion or
> facilitation

Both operative verbs describe conduct directed at an outcome. **Promotion**
requires advocating for the behaviour. **Facilitation** requires making it
easier or providing means toward it. Neither is a status test on the product
category, and the clause does not name calorie tracking, dieting or weight
management anywhere.

What the model is asked to do is convert `"2 eggs, 100g toast, black coffee"`
into `[{query: "eggs", quantity: 2}, {query: "toast", quantity: 100, unit:
"g"}, {query: "black coffee"}]`. That is tokenisation. The model contributes no
number the user did not type, offers no opinion on the meal, and cannot report
a calorie count because the schema has no field for one. Every figure the user
sees is retrieved from Open Food Facts, USDA FDC or BLS by searching the
returned strings.

**The strongest evidence is internal, not textual.** Anthropic's Usage Policy,
under *Do Not Create Psychologically or Emotionally Harmful Content*, prohibits:

> Facilitate, promote, or glamorize any form of suicide or self-harm, including
> disordered eating and unhealthy or compulsive exercise

That is the same prohibition with a **wider** reach: it adds "glamorize", and
it adds compulsive exercise. The project reviewed it, shipped on Anthropic
anyway, and was right to. OpenAI's narrower version cannot exclude an app that
Anthropic's broader one does not. Either the app promotes and facilitates
disordered eating — in which case the current Anthropic-only catalogue is also
non-compliant and the whole feature is in question — or it does not, in which
case B1 is not a reason to exclude OpenAI. There is no consistent third
position, and #656 did not notice it was holding one.

Where a nutrition tracker *could* meet this clause is worth naming so the line
stays visible: emitting a deficit target, ranking foods as good or bad,
nudging toward a calorie floor, or commenting on a logged day. The app does
none of these, and the schema is what keeps it that way — a structural
guarantee rather than a promise in a prompt (settled 2026-08-14; decision #5
reversed, [#250](https://github.com/simonoppowa/OpenNutriTracker/issues/250)
stays closed).

### B2. *"promoting unhealthy dieting or exercise behavior to minors"*

Under **Keep minors safe**. The section's preamble, verbatim:

> Keep minors safe. Children and teens deserve special protection. Our services
> are designed to prevent harm and support their well-being, and must never be
> used to exploit, endanger, or sexualize anyone under 18 years old. We
> prohibit use of our services for: … promoting unhealthy dieting or exercise
> behavior to minors … shaming or otherwise stigmatizing the body type or
> appearance of minors

**Read the grammar.** The prohibited act is *promoting X to Y*. It requires
three things: a promoter, something promoted, and a minor recipient. The app
promotes nothing to anyone — it has no chat surface, no recommendations, no
commentary. There is no output channel through which a diet could be
advocated. The second clause, *shaming or otherwise stigmatizing*, requires an
evaluative statement about a person's body, which nothing in this app can
produce. A tool with no opinions cannot promote and cannot shame.

**Note what is not here.** There is no requirement that the service be
adults-only, no age-gate obligation, no audience restriction, no "not likely to
be accessed by minors" wording, and no prohibition on general-audience
distribution. The preamble's *"must never be used to exploit, endanger, or
sexualize anyone under 18"* is likewise conduct, not audience. I read the whole
document; nothing elsewhere reintroduces a distribution test.

### B3. *"provision of tailored advice that requires a license"*

Under **Protect people**. Verbatim:

> provision of tailored advice that requires a license, such as legal or
> medical advice, without appropriate involvement by a licensed professional

Three conditions must all hold: it must be **advice**, it must be **tailored**,
and it must be advice **that requires a license**. The app fails the first,
which ends it. Returning `{query: "toast"}` is not advice under any reading;
the app never tells the user what to eat, how much, or whether the day went
well. It transcribes what the user already said or photographed.

Even if a reviewer insisted the surrounding product gives dietary advice, the
model does not, and the model is what the Usage Policies govern. And the
numbers the app *does* show come from public food databases, not the model —
so the model is not the source of anything advisory.

**But note where this leaves us.** The defence is entirely factual — "the app
gives no advice" — and it moves the day the product adds a suggestion, a
summary, a coach, or any commentary at all. With Anthropic the carve-out means
even a genuinely advisory nutrition feature stays outside the High-Risk
category. With OpenAI, the margin is only as wide as the current feature set.
That is what [Section D](#d-openai-against-anthropic-absence-against-carve-out)
is about.

### B4. The clause that was not on the list, and is satisfied anyway

Under **Empower people**, the Usage Policies prohibit *"automation of
high-stakes decisions in sensitive areas without human review"*, and the
enumerated sensitive areas include **medical**. This is the closest the
document comes to touching the app, and it comes with its own escape hatch:
*without human review*. The confirmation step in `bulk_add_screen.dart` is
documented as *"not optional"* and exists so nothing reaches the diary
unreviewed. Nothing is automated and nothing is decided. Satisfied on both
limbs.

## C. OpenAI against Google: conduct test against distribution test

**The distinction is real, and it is the reason the two rejections were never
the same rejection.** Verified against the live Google document rather than
taken from the earlier note.

Google Cloud Service Specific Terms, last modified 29 July 2026, §20(d):

> **d. Age Restrictions.** Customer will not, and will not allow End Users to,
> use a Generative AI Service as part of a website, Customer Application, or
> other online service that is directed towards or is likely to be accessed by
> individuals under the age of 18.

§20(g) makes this a "Use Restriction". §20(f) adds that Google *"may
immediately suspend or terminate Customer's use of a Generative AI Service
based on any suspected violation of … subsection (d)"* — suspicion, not
finding. §20(e) adds a healthcare restriction against use *"as a substitute for
professional medical advice"*.

| | Google §20(d) | OpenAI *Keep minors safe* |
| --- | --- | --- |
| Test | **Distribution** — where the app is offered | **Conduct** — what the app does |
| Trigger | *likely to be accessed by* under-18s | *promoting … to* minors |
| Can a general-audience app comply? | **No.** Play and F-Droid are open listings; the condition is met at publication | **Yes**, by not promoting dieting |
| Compliance evidence | would need an age gate that excludes minors | the absence of an advisory output channel |

A general-audience calorie tracker on Google Play and F-Droid fails §20(d) the
moment it lists, no matter how the model is used — the clause is about the
storefront, not the software. OpenAI's clause can be complied with by a
general-audience app, and this one does comply, because it has no mechanism for
promoting anything.

**I checked specifically for a re-entry point and found none.** The Usage
Policies, the Services Agreement and the Service terms contain no age-gating
obligation, no audience restriction and no age-verification requirement for API
applications. The one age clause on the API path is Services Agreement §3.3(c),
and it is a consent test rather than an exclusion:

> Customer will not, and will not permit End Users to: … (c) allow minors to
> use OpenAI Services without consent from their parent or guardian

Minors are contemplated as users, conditionally. It binds the Customer — under
BYO-key, the user, who is the only person using their key. Consumer Terms of
Use set the floor consistently: *"You must be at least 13 years old or the
minimum age required in your country to consent to use the Services. If you are
under 18, you must have your parent or legal guardian's permission to use the
Services"* (Europe ToU, 16 January 2026; the rest-of-world ToU carries the same
sentence).

**The only audience rule I found in OpenAI's developer surface runs the
opposite way to Google's.** The Apps SDK submission guidelines require *"Plugins
must be suitable for general audiences, including users aged 13–17"* and that
*"Plugins may not explicitly target children under 13."* That is an
*inclusion* requirement — build for teenagers — and it is the inverse of an
exclusion test. It governs ChatGPT plugins and Codex, **not** a mobile app
calling the API with the user's key, so it does not bind us. It is cited only
as evidence of posture: OpenAI's developer-facing age rules ask apps to be safe
for minors, not to keep minors out.

## D. OpenAI against Anthropic: absence against carve-out

**Anthropic gives an explicit carve-out. OpenAI gives silence. These are not
the same thing, and the difference should survive into any decision.**

Anthropic's Usage Policy lists *High-Risk Use Cases* which attract two extra
duties — human-in-the-loop review by *"a qualified professional in that
field"*, and disclosure that AI is involved *"at a minimum at the beginning of
each session"*. Its healthcare entry ends with the sentence the project chose
Anthropic for:

> **Healthcare:** Use cases related to healthcare decisions, medical diagnosis,
> patient care, therapy, mental health, or other medical guidance. Wellness
> advice (e.g., advice on sleep, stress, nutrition, exercise, etc.) does not
> fall under this category

Nutrition is named and placed outside. That is affirmative cover: it does not
depend on the app being read a particular way, it survives a product change
toward advice, and it is quotable to a reviewer in one line.

OpenAI has nothing comparable. There is no "High-Risk Use Cases" construct at
all in the October 2025 Usage Policies, and no wellness, nutrition, fitness or
diet exception anywhere in the Usage Policies, the Services Agreement or the
Service terms. The nearest OpenAI comes to addressing the domain points
gently the *other* way — Service terms §9, updated 12 June 2026:

> **9. Medical Use.** Our Services are not intended for use in the diagnosis or
> treatment of any health condition. You are responsible for complying with
> applicable laws for any use of our Services in a medical or healthcare
> context.

That is a disclaimer of intent plus a compliance pass-through, not a
prohibition and certainly not a carve-out. It is weaker than Google's §20(e)
(which is a restriction) and weaker than Anthropic's carve-out (which is a
permission). It does not bar the app — logging what you ate is neither
diagnosis nor treatment — but it is the opposite of reassurance.

| | Anthropic | OpenAI |
| --- | --- | --- |
| Disordered eating | prohibited, **wider** wording ("glamorize", compulsive exercise) | prohibited |
| Nutrition named favourably | **yes** — explicit carve-out from High-Risk | no |
| Advice regime | High-Risk duties, from which wellness is exempt | flat ban on unlicensed tailored advice, no exemption |
| Minors + dieting | no clause | conduct clause, not met |
| Audience/distribution test | none | none |
| Health posture statement | carve-out | §9 disclaimer of intent |

**So the honest summary is: OpenAI is permitted by absence.** Everything above
holds because the app gives no advice and promotes nothing, and it would stop
holding if either of those changed. Under Anthropic, the same product change
would still be covered. A project that treats "no prohibition found" as weaker
than an explicit carve-out — as this one does, and as it did when it declined
xAI on the same reasoning ([`ai-model-candidates.md`](ai-model-candidates.md)
finding 3) — should reach the same conclusion here. **OpenAI is not barred; it
is simply less protected, and it should be ranked as such rather than
re-rejected.**

## E. Clauses nobody was looking at

**Service terms §6 touches the photo path**, and did not appear in #656:

> You may not use Visual Capabilities to assist in identifying a person nor to
> solicit or infer private or sensitive information about a person.

The photo prompt asks only which foods are visible and forbids estimating
weight or volume, so no inference about a person is requested. Two things keep
this from being clean: meal photographs frequently contain people incidentally,
and dietary intake is a category some regimes treat as sensitive personal data.
The clause is about *using* the capability to identify or infer, which the app
does not do, so on the better reading it is not engaged — but it is closer to
the app's behaviour than B2 or B3 are, and it deserves a look before any
OpenAI-backed photo path ships. **Ambiguous; not resolved here.**

Three more, checked and clear:

- **Service terms §1** binds documentation: *"Customer will only, and will
  ensure that its End Users only, use APIs in accordance with the applicable
  documentation."* The safety-best-practices guide contains recommendations
  (adversarial testing, human review, the free Moderation API) rather than
  requirements, and imposes no AI-disclosure duty, no age gate and no
  health-app conditions.
- **Services Agreement §5.4** forbids processing Protected Health Information
  without a signed Healthcare Addendum. PHI is a defined term under the HIPAA
  Privacy Rule tied to covered entities; a person's own food diary is not PHI.
  Not engaged, but adjacent enough to note.
- **Sharing & Publication Policy** is incorporated into "OpenAI Policies" but
  is dated 14 November 2022, still references GPT‑3 and a "Content Policy" that
  no longer exists, and governs social posting and book publishing. Nothing in
  it reaches this app.

Also checked and found not to apply: the **App Developer Terms**, which govern
ChatGPT Apps and Actions (Service terms §5(c), §7(a)), not an API integration
in a mobile app.

## Not verified

- **Whether pasting your own key into third-party client software is a
  "transfer … to … a third party" under §3.3(g).** The controlling ambiguity of
  this whole note. OpenAI publishes no guidance, FAQ or help-centre article
  interpreting the clause that I could find, and the surrounding restrictions
  cut both ways. Unresolvable from public documents.
- **Whether an individual hobbyist with a personal API key is a "business or
  developer"** within the Services Agreement's scope sentence. The reading
  taken here — that they are, because APIs are named — is the natural one and
  is corroborated by both consumer ToU routing API use to the business terms,
  but the sentence is not clean and I did not find OpenAI stating it anywhere
  else.
- **The rest-of-world Terms of Use date.** The page renders no "Updated:" line
  that could be extracted; the minimum-age and business-terms sentences were
  read from the live page on 2026-08-16 and are quoted accurately, but the
  version date is unconfirmed. The Europe ToU date (16 January 2026) is
  confirmed.
- **What the pre-29-October-2025 Usage Policies required.** The January 2024
  version is widely described as carrying a disclosure duty for consumer-facing
  medical uses, and the changelog entry *"We've updated our Usage Policies to
  reflect a universal set of policies"* is consistent with such
  service-specific guidance having been dropped. OpenAI publishes no archived
  copy I could reach, so I could not confirm what was removed. Only the current
  document binds, and it contains no disclosure duty.
- **Enforcement history against nutrition or fitness applications.** None
  found, and I do not believe it is findable. OpenAI's published enforcement
  reporting is the *Disrupting malicious uses of AI* series, which covers
  influence operations, scams, cyber intrusion and state-affiliated actors —
  threat-intelligence categories, not consumer app policy. OpenAI does not
  publish case-level developer enforcement data, so **"no enforcement found"
  here means "not published", not "has not happened"**, and should not be
  cited as comfort.
- **Any OpenAI developer guidance specific to health or wellness apps.** I
  looked in the Usage Policies, Services Agreement, Service terms, the API
  safety-best-practices guide and the Apps SDK submission guidelines. There is
  none. The Apps SDK guidelines' prohibited-category list reaches
  prescription-only drugs but says nothing about diet, nutrition or fitness —
  and governs ChatGPT plugins regardless.
- **Whether OpenAI's Model Spec bears on this.** It does not, as far as I can
  tell. Both the 2025-10-27 and 2025-12-18 versions were searched for eating
  disorders, dieting, nutrition, calories and body image; the only near-match
  is a section heading, *"Do not encourage self-harm, delusions, or mania"*,
  whose body I could not retrieve in full. It governs model behaviour rather
  than developer permission in any case.
- **How OpenAI would actually read B1 against this app.** Everything in
  [Section B1](#b1-suicide-self-harm-or-disordered-eating-promotion-or-facilitation)
  is textual analysis plus an internal-consistency argument. No OpenAI
  interpretation of "disordered eating promotion or facilitation" exists in
  public, and a reviewer minded to treat calorie tracking as a category risk
  would not be contradicted by anything in the document.
- **Legal advice.** This is a reading of published documents on one date by a
  non-lawyer. Terms on all three sites change without notice — Google's moved
  documents entirely between #656 and now — and the dates above are the only
  guarantee offered.

## Sources

OpenAI (read in a browser; the site 403s automated fetching):
[Usage policies](https://openai.com/policies/usage-policies/) ·
[OpenAI Services Agreement](https://openai.com/policies/services-agreement/) ·
[Service terms](https://openai.com/policies/service-terms/) ·
[Europe Terms of Use](https://openai.com/policies/terms-of-use/) ·
[Terms of Use (rest of world)](https://openai.com/policies/row-terms-of-use/) ·
[Sharing & publication policy](https://openai.com/policies/sharing-publication-policy/) ·
[Safety best practices](https://developers.openai.com/api/docs/guides/safety-best-practices) ·
[Apps SDK app submission guidelines](https://developers.openai.com/apps-sdk/app-submission-guidelines) ·
[Disrupting malicious uses of AI](https://openai.com/index/disrupting-malicious-ai-uses/) ·
[Model Spec (2025/12/18)](https://model-spec.openai.com/2025-12-18.html)

Comparison documents:
[Anthropic Usage Policy](https://www.anthropic.com/legal/aup) ·
[Google Cloud Service Specific Terms](https://cloud.google.com/terms/service-terms)

Related notes in this repo:
[`ai-model-candidates.md`](ai-model-candidates.md) ·
[`ai-legal-constraints.md`](ai-legal-constraints.md) ·
[`ai-cohort-restrictions.md`](ai-cohort-restrictions.md) ·
[`ai-open-research-questions.md`](ai-open-research-questions.md)

In-repo files cited:
[`lib/features/add_meal/domain/meal_items_api.dart`](../lib/features/add_meal/domain/meal_items_api.dart) ·
[`lib/features/add_meal/data/model_meal_text_interpreter.dart`](../lib/features/add_meal/data/model_meal_text_interpreter.dart) ·
[`lib/features/add_meal/data/model_meal_photo_interpreter.dart`](../lib/features/add_meal/data/model_meal_photo_interpreter.dart) ·
[`lib/features/add_meal/presentation/screens/bulk_add_screen.dart`](../lib/features/add_meal/presentation/screens/bulk_add_screen.dart) ·
[`lib/core/utils/ai_model_catalogue.dart`](../lib/core/utils/ai_model_catalogue.dart)
