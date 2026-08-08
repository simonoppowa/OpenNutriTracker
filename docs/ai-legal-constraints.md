# Legal and platform-policy constraints on AI-assisted meal logging

Research notes gathered 2026-08-02 against primary sources — EUR-Lex for EU
legislation, the European Commission's own MDCG guidance, Apple's and Google's
own policy pages, F-Droid's own documentation, gnu.org, and
gesetze-im-internet.de. Where a secondary source pointed at a provision, the
provision itself was fetched and quoted. Written to inform issue
[#599](https://github.com/simonoppowa/OpenNutriTracker/issues/599) and the tier-1
scoping decision it defers.

**This is not legal advice.** It reports what the texts say, distinguishes what
plainly attaches from what plainly does not, and names the judgements a lawyer
should make rather than guessing at them. Anything I could not verify is listed
at the end rather than smoothed over.

> **Partly superseded — read this first.** Two later documents correct
> conclusions below. Where they conflict, they win.
>
> - [`ai-cohort-restrictions.md`](ai-cohort-restrictions.md) corrects the
>   F-Droid section twice: the Translate You `gradle: [libre]` citation is
>   stale, and "a build flavour would avoid `NonFreeNet`" is too optimistic —
>   the flavour has to remove the prefilled commercial endpoint, not just
>   proprietary libraries. It also finds a blocker this document missed
>   entirely: bundled Google ML Kit, which is present-tense and unrelated to
>   AI. (Independently reached by
>   [`fdroid-submission-feasibility.md`](fdroid-submission-feasibility.md),
>   written earlier for #575.)
> - [`ai-open-research-questions.md`](ai-open-research-questions.md) closes
>   several items from the "not verified" list here — including the Digital
>   Omnibus deferral, now confirmed from EUR-Lex as Regulation (EU) 2026/1744.
>   **Article 50 was not deferred**, which is the point the timeline here
>   turns on.

The thing assessed is the design recorded in #599 as revised on 2026-08-02:
tier 0 is a deterministic parser with no model and no new network call; tiers 1–2
are opt-in, off by default, with the user supplying their own endpoint URL, API
key and model name, requests going from the device straight to that endpoint, the
project operating no server and paying nothing, database values winning on every
match, and model-supplied macros used only on a database miss and flagged
`estimated`.

## Bottom line up front

Tier 0 attaches nothing: no AI Act obligation, no medical-device question, no new
GDPR processing, no store declaration, no F-Droid label. For tiers 1–2 the only
EU obligation that plausibly bites is **Article 50(2) of the AI Act** — a
machine-readable marking duty on generated content, in force since today,
2 August 2026, and most likely engaged by the tier-2 photo path rather than the
text path; everything else in the AI Act either exempts free-software projects,
exempts the user, or lands in a risk tier this app is nowhere near. Medical-device
law turns entirely on the *intended purpose you state in your own marketing*, not
on accuracy or on the `estimated` flag, so it stays out of scope for as long as
the store listing and in-app copy avoid claiming to detect, monitor or treat
anything. Under GDPR the project processes nothing — the user directs each
transmission to a counterparty the user chose — but "does shipping the code make
you a controller" is a genuine judgement call, not a settled question, and it is
the one place where the honest answer is "ask a lawyer". The concrete work is
small and mostly writing: an in-app disclosure and consent gate, an in-app report
control (Google Play requires one for any app that generates content with AI), a
privacy-policy section, revised Data safety answers, and — separately and
independently of AI — the Google Play health disclaimer wording that the current
store listing appears to be missing already.

## Tier 0 — nothing attaches

Tier 0 is a deterministic text parser resolving food names against the existing
Open Food Facts / USDA / BLS databases. No model, no inference, no new
destination. Taking each instrument in turn:

- **AI Act.** Article 3(1) defines an AI system as "a machine-based system that
  is designed to operate with varying levels of autonomy and that may exhibit
  adaptiveness after deployment, and that, for explicit or implicit objectives,
  **infers**, from the input it receives, how to generate outputs" ([Reg. (EU)
  2024/1689 Art. 3(1)](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=OJ:L_202401689)).
  A parser that applies fixed rules to digits and unit symbols does not infer; it
  computes. Even if the definition were stretched, Article 50 attaches only to
  systems that interact with natural persons as AI or that *generate* synthetic
  content — tier 0 generates nothing, it retrieves. The system is also released
  under a free and open-source licence, and Article 2(12) disapplies the whole
  Regulation to such systems "unless they are placed on the market or put into
  service as high-risk AI systems or as an AI system that falls under Article 5
  or 50". None of those carve-backs is met.
- **MDR.** No change in intended purpose; the numbers still come from the same
  databases they came from before, and MDCG 2019-11 rev.1 expressly excludes
  "wellness or fitness apps" from medical device software (p. 8).
- **GDPR.** No new personal data leaves the device. The README's destination
  table is unchanged.
- **Apple 5.1.2, Google Play User Data / Data safety.** No new data collected,
  no new third party, nothing to declare. Google Play's AI-Generated Content
  policy is scoped to "content that is created by generative AI models based on
  user prompts" — a parser is neither.
- **F-Droid.** No new network service, proprietary or otherwise; `NonFreeNet`
  requires an app that "promote[s] or depend[s] entirely on a proprietary network
  service".
- **GPL-3.0.** No third-party code, no service call, no licence interaction.
- **German law.** No new duty. The existing Impressum and misleading-advertising
  positions are unchanged.

The single thing worth saying out loud: #599 already records that tier 0 must not
be marketed as "AI". That is the right call for product reasons, and it is also
what keeps this paragraph true. If the release notes or store listing call the
parser "AI", the Article 50(1) question stops being obviously answerable in the
negative — not because the parser changed, but because Article 3(12) defines
"intended purpose" partly by reference to "promotional or sales materials and
statements".

## EU AI Act — Regulation (EU) 2024/1689

Primary text: [OJ L, 2024/1689](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=OJ:L_202401689)
([ELI](https://eur-lex.europa.eu/eli/reg/2024/1689/oj/eng)), as amended by
[Regulation (EU) 2026/1744](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=OJ%3AL_202601744)
of 8 July 2026 (the "Digital Omnibus on AI",
[ELI](https://eur-lex.europa.eu/eli/reg/2026/1744/oj/eng)).

### Application timeline

Article 113 as amended by Regulation (EU) 2026/1744 Art. 1(40):

| Provision | Applies from | Status today (2026-08-02) |
| :-- | :-- | :-- |
| Chapters I and II — scope, definitions, Art. 4 AI literacy, Art. 5 prohibitions | 2 February 2025 | **in force** |
| Art. 5(1) points (ba), (bb) and Art. 5(1a), (1b) (inserted by the Omnibus) | 2 December 2026 | not yet |
| Chapter III Section 4, Chapter V, Chapter VII, Chapter XII, Art. 78 | 2 August 2025 | **in force** |
| Articles 102 to 110 | 27 July 2026 | **in force** |
| General date of application — including **Chapter IV, Article 50** | **2 August 2026** | **in force as of today** |
| Chapter III Sections 1–3 for Art. 6(2) / Annex III high-risk systems | **2 December 2027** | not yet |
| Chapter III Sections 1–3 for Art. 6(1) / Annex I high-risk systems | **2 August 2028** | not yet |

The Omnibus did **not** move Article 50. It changed only Article 50(7) (removing
the Commission's implementing-act empowerment over codes of practice) and added a
transitional in Article 111(4): "Providers of AI systems, including
general-purpose AI systems, generating synthetic audio, image, video or text
content, that have been placed on the market before 2 August 2026 shall take the
necessary steps in order to comply with Article 50(2) by 2 December 2026."

That transitional is worth noting for sequencing. It is drafted for systems
*already on the market* on 2 August 2026. Tiers 1–2 would be placed on the market
after that date, so on the face of it the four-month grace does not apply to
them — an argument that the marking duty is immediate on first release rather
than deferred. This is exactly the kind of point a lawyer should confirm.

### Who is provider, who is deployer

Article 3(3): "'provider' means a natural or legal person … that develops an AI
system … and places it on the market or puts the AI system into service under its
own name or trademark, **whether for payment or free of charge**".

Article 3(4): "'deployer' means a natural or legal person … using an AI system
under its authority **except where the AI system is used in the course of a
personal non-professional activity**".

Article 2(10) says the same thing from the other end: "This Regulation does not
apply to obligations of deployers who are natural persons using AI systems in the
course of a purely personal non-professional activity."

So:

- **The user is out of scope, completely.** Someone logging their own dinner is
  not a deployer, whether they point the app at Anthropic or at Ollama on their
  laptop. This is not a close question.
- **The endpoint operator** (Anthropic, OpenAI, whoever) is the provider of the
  general-purpose AI model, with Chapter V obligations that are none of this
  project's business. If the endpoint is the user's own Ollama, the user is
  putting a model into service for own use — and Article 2(10) exempts them
  anyway.
- **The project** develops the software that turns a user prompt plus a
  user-supplied model into structured meal data, and distributes it under its own
  name. If that composite is an "AI system" within Article 3(1), the project is
  its provider. The awkwardness is that the inference component is not shipped:
  it arrives at runtime from an address the user typed. I could find nothing in
  the Regulation that resolves this cleanly. The safest working assumption is
  **provider, not deployer** — the project never uses the system under its own
  authority.

Two provisions that people reach for here and that do **not** apply:

- **Article 25** ("Responsibilities along the AI value chain") reclassifies
  distributors, importers, deployers and third parties as providers when they
  put their name on, substantially modify, or change the intended purpose of a
  **high-risk** AI system. Every limb of Article 25(1) is expressly about
  high-risk systems. Nothing here is high-risk, so Article 25 is inert.
- **Article 2(12)**, the free-and-open-source exemption: "This Regulation does
  not apply to AI systems released under free and open-source licences, unless
  they are placed on the market or put into service as high-risk AI systems or as
  an AI system that falls under Article 5 or 50." OpenNutriTracker is GPL-3.0.
  The exemption therefore covers everything **except** Article 50 — which is
  precisely the article in play. Article 2(12) is not the escape hatch it looks
  like at first glance; it disposes of every other chapter and leaves Article 50
  standing.

  Recital 103 adds a monetisation caveat: components "provided against a price or
  otherwise monetised, including through the provision of technical support or
  other services … should not benefit from the exceptions". The repo has a
  Patreon link (`.github/FUNDING.yml`). Voluntary donations are not obviously
  "against a price", and recital 103 also says "making AI components available
  through open repositories should not, in itself, constitute a monetisation" —
  but this is a judgement, not a certainty.

### Article 50 in detail

**Article 50(1) — interaction disclosure.**

> Providers shall ensure that AI systems intended to interact directly with
> natural persons are designed and developed in such a way that the natural
> persons concerned are informed that they are interacting with an AI system,
> unless this is obvious from the point of view of a natural person who is
> reasonably well-informed, observant and circumspect, taking into account the
> circumstances and the context of use.

Recital 132 frames this as a rule against impersonation and deception, aimed at
systems a person might mistake for a human. A meal-logging feature that returns a
review list of foods is not that. And even on the broadest reading, the "obvious"
exception is comfortably met: the user opened Settings, pasted an endpoint URL, an
API key and a model name, and enabled a feature that is off by default. Nobody
reaching that screen is unaware they are talking to a model.

Practically: comply anyway. A one-line label on the entry point costs nothing and
removes the argument.

**Article 50(2) — machine-readable marking. This is the one that matters.**

> Providers of AI systems, including general-purpose AI systems, generating
> synthetic audio, image, video or text content, shall ensure that the outputs of
> the AI system are marked in a machine-readable format and detectable as
> artificially generated or manipulated. Providers shall ensure their technical
> solutions are effective, interoperable, robust and reliable as far as this is
> technically feasible, taking into account the specificities and limitations of
> various types of content, the costs of implementation and the generally
> acknowledged state of the art … **This obligation shall not apply to the extent
> the AI systems perform an assistive function for standard editing or do not
> substantially alter the input data provided by the deployer or the semantics
> thereof** …

Three things follow.

*First, "does a nutrition estimate count as content requiring disclosure?"* The
model emits **text** — food names, quantities, units, and on a database miss a set
of kcal/macro numbers. Text is squarely inside "synthetic audio, image, video or
text content". Recital 133 explains the mischief as synthetic content that "becomes
increasingly hard for humans to distinguish from human-generated and authentic
content", with impacts on "the integrity and trust in the information ecosystem".
A private food diary is a long way from that mischief. But the operative text of
Article 50(2) contains no "public dissemination" qualifier — the recital narrows
the *reason*, not the *scope*. On the text, a model-generated kcal figure is
generated text content.

*Second, the exception does real work, and it splits the two tiers.* The carve-out
covers systems that "do not substantially alter the input data provided by the
deployer or the semantics thereof".

- **Tier 1 (text).** The user types "two eggs and a slice of toast"; the model
  returns `{egg, 2, piece}, {bread, 1, slice}`. That is structuring the user's own
  input without altering its semantics — a good fit for the exception. Where the
  model additionally supplies macros for a database miss, it is creating new
  information, and the fit weakens.
- **Tier 2 (photo).** The model looks at a picture and produces names, portions
  and possibly numbers that were nowhere in the input as data. That is not
  "assistive editing" and it does alter the semantics of the input. The exception
  most likely does not cover it.

*Third, note what the obligation actually is.* Article 50(2) requires
**machine-readable marking** — watermarks, metadata, provenance signals; recital
133 lists "watermarks, metadata identifications, cryptographic methods for proving
provenance and authenticity of content, logging methods, fingerprints". It does
**not** require an on-screen badge. The visible-labelling duty in Article 50(4) is
confined to deep fakes and to text "published with the purpose of informing the
public on matters of public interest" — neither applies here.

This is a useful result: the `estimated` value on `MealSourceEntity`, persisted in
the Hive record and carried into `docs/export-format.md`, is a machine-readable
provenance marker, and is a much better fit for Article 50(2) than the on-screen
badge is. The on-screen badge is worth building for the misleading-advertising
reasons below, not for Article 50.

The proportionality language — "as far as this is technically feasible, taking
into account … the costs of implementation and the generally acknowledged state of
the art" — is the lever for a project that cannot watermark at generation time
because it does not run the model. There is no state of the art for watermarking a
JSON payload returned by an arbitrary third-party endpoint.

**Article 50(3) and (4)** do not apply: no emotion recognition, no biometric
categorisation, no deep fakes, no publication to inform the public.

**Article 50(5) — how the information must be given.** The user's question used
the phrase "clearly perceptible"; that phrase is not in Article 50. The operative
wording is:

> The information referred to in paragraphs 1 to 4 shall be provided to the
> natural persons concerned in a **clear and distinguishable manner at the latest
> at the time of the first interaction or exposure**. The information shall
> conform to the applicable accessibility requirements.

Two consequences. It governs only the information required by paragraphs 1–4, so
it does not turn the 50(2) machine-readable marking into a visible label. And the
accessibility sentence means whatever disclosure you do write has to be reachable
by a screen reader — which for this repo means a `Semantics` label, not just a
styled `Text`.

**Penalty.** Article 99(4)(g): breach of "transparency obligations for providers
and deployers pursuant to Article 50" attracts administrative fines "up to EUR
15 000 000 or, if the offender is an undertaking, up to 3 % of its total worldwide
annual turnover", with Article 99(6) capping SMEs at whichever of the percentage
or the absolute figure is **lower**. For a solo project with no turnover the
percentage limb is zero, but the EUR figure is not, and Article 99(1) requires
penalties to be "effective, proportionate and dissuasive" while "tak[ing] into
account the interests of SMEs, including start-ups, and their economic viability".

### Could it be high-risk via Annex III?

No. Annex III has eight headings: biometrics; critical infrastructure; education
and vocational training; employment and worker management; access to essential
private and public services and benefits; law enforcement; migration, asylum and
border control; administration of justice and democratic processes. Reading each
entry against a consumer food diary:

- The nearest miss is point 5(a), eligibility for "essential public assistance
  benefits and services, including healthcare services" — but that entry is
  confined to systems "intended to be used by public authorities or on behalf of
  public authorities".
- Point 5(c) covers "risk assessment and pricing in relation to natural persons
  in the case of life and health insurance". Not this.
- Point 1 covers biometrics. A meal photo containing a face is not biometric
  processing: Annex III(1)(a) is remote biometric identification, (b) is biometric
  categorisation "according to sensitive or protected attributes … based on the
  inference of those attributes", (c) is emotion recognition. Naming the food on
  the plate is none of these, and the design should keep it that way — do not
  ask the model anything about the people in the photo.

Even if an entry were somehow engaged, Article 6(3) derogates where the system
"does not pose a significant risk of harm to the health, safety or fundamental
rights of natural persons", including where it "is intended to perform a narrow
procedural task" — with the caveat that a system "shall always be considered to be
high-risk where the AI system performs profiling of natural persons". And the
Annex III obligations do not apply until **2 December 2027** in any event.

**Article 4 (AI literacy)** has applied since 2 February 2025 and, as amended by
the Omnibus, requires providers and deployers to "take measures to support the
development of AI literacy of their staff and other persons dealing with the
operation and use of AI systems on their behalf" — expressly adding that it "does
not require providers or deployers to guarantee any specific level of AI literacy
of any individual". For a project with no staff this is close to nominal;
documenting the feature's limitations in the repo discharges the spirit of it.

## EU medical device law — MDR 2017/745

Primary text: [consolidated Regulation (EU) 2017/745](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:02017R0745-20240709).
Guidance: [MDCG 2019-11 rev.1, June 2025](https://health.ec.europa.eu/document/download/b45335c5-1679-4c71-a91c-fc7a4d37f12b_en?filename=mdcg_2019_11_en.pdf)
([announcement](https://health.ec.europa.eu/latest-updates/update-mdcg-2019-11-rev1-qualification-and-classification-software-regulation-eu-2017745-and-2025-06-17_en)).

### The qualification test

Article 2(1) MDR:

> 'medical device' means any instrument, apparatus, appliance, **software**,
> implant, reagent, material or other article **intended by the manufacturer** to
> be used, alone or in combination, for human beings for one or more of the
> following specific medical purposes:
> — diagnosis, prevention, monitoring, prediction, prognosis, treatment or
> alleviation of disease,
> — diagnosis, monitoring, treatment, alleviation of, or compensation for, an
> injury or disability,
> — investigation, replacement or modification of the anatomy or of a
> physiological or pathological process or state, …

Article 2(12) MDR defines intended purpose as "the use for which a device is
intended **according to the data supplied by the manufacturer on the label, in the
instructions for use or in promotional or sales materials or statements** and as
specified by the manufacturer in the clinical evaluation".

MDCG 2019-11 rev.1 states the qualification rule directly (§3.1, p. 8):

> Software must have a medical purpose on its own to be qualified as a MDSW … the
> intended purpose, as described by the manufacturer of the software is relevant
> for the qualification and classification of any device.

and, in the same section, excludes this category of app by name:

> In addition, software only intended for non-medical purposes … such as
> invoicing, staff planning, e-mailing, web or voice messaging, data parsing, word
> processing, and back-up, **wellness or fitness apps, do not qualify as MDSW**.

### Does "estimates calories from a photo, user logs it against a weight goal" cross the line?

On the current design, no. The intended purpose stated in the store listing, the
in-app copy and the README is nutritional tracking and weight management for
general wellness. That is the "wellness or fitness apps" category MDCG expressly
excludes. Adding a model that names foods from a photo does not change the
purpose; it changes the input method. MDCG's decision steps make the same point
from the other direction — step 3 asks whether the software performs an action on
data beyond storage, archival, communication, simple search or lossless
compression, and step 4 asks "is the action for the benefit of individual
patients?", with step 5 asking whether the software meets the MDSW definition at
all. A calorie estimate benefits an individual *user*; it is not directed at a
*patient* in a diagnostic or therapeutic sense.

### What specifically would push it over

Any statement — in the app, on the store listing, in release notes, in the
README — that attaches the output to a disease, injury or physiological state.
Concretely, the things to never write:

- "helps you manage diabetes" / "for coeliac disease" / "detects nutrient
  deficiencies" — monitoring or diagnosis of disease;
- "supports recovery from an eating disorder" — MDCG's own worked example of MDSW
  is software "intended to alleviate certain eating disorder behaviours such as
  bulimia and anorexia" reacting to "different patient inputs related of the
  disease (diet, physical activity, body image, etc.)" (p. 9). This is the single
  closest example in the guidance to what a nutrition app could accidentally
  become;
- "medically supervised weight loss" or anything implying a clinical protocol;
- linking the output to a clinician or to a treatment decision.

Note the app already ships an intermittent-fasting timer behind a "content-warning
gate" and a low-kcal warning that advises consulting a healthcare professional.
Those are the right instincts — they push away from a medical purpose, not toward
one.

### Does the `estimated` flag or a disclaimer change the analysis?

**No, and it is important to be clear about why.** Qualification depends on stated
intended purpose, not on accuracy, and MDCG says so explicitly (p. 8):

> It must be highlighted that the risk of harm to patients, users of the software,
> or any other person, related to the use of the software within healthcare,
> including a possible malfunction **is not a criterion on whether the software
> qualifies as a medical device**.

So a disclaimer cannot cure a stated medical purpose — you cannot claim to detect
disease and then disclaim your way out. Conversely, an `estimated` marker does not
make an otherwise-medical device non-medical, and its absence would not make a
wellness app medical. What the disclaimer *does* do is form part of the
"promotional or sales materials or statements" that constitute the intended
purpose under Article 2(12) MDR — so keeping the marketing free of medical claims
is the whole game, and the disclaimer is evidence of that, not a shield.

For completeness, if it ever did qualify, Annex VIII Rule 11 would put it at class
IIa at minimum: "Software intended to provide information which is used to take
decisions with diagnosis or therapeutic purposes is classified as class IIa". That
means a notified body, a QMS, a clinical evaluation and a CE mark — an order of
magnitude beyond anything this project can absorb. The correct posture is to stay
firmly outside the definition rather than to manage the classification.

## GDPR — Regulation (EU) 2016/679

Primary text: [Regulation (EU) 2016/679](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:32016R0679).
Guidance: [EDPB Guidelines 07/2020 on the concepts of controller and processor](https://www.edpb.europa.eu/system/files/2023-10/EDPB_guidelines_202007_controllerprocessor_final_en.pdf).

### Who is controller for the meal text and photos?

Article 4(7): "'controller' means the natural or legal person … which, alone or
jointly with others, **determines the purposes and means of the processing** of
personal data". Article 4(8): "'processor' means a natural or legal person … which
processes personal data **on behalf of** the controller".

Article 2(2)(c) excludes processing "by a natural person in the course of a purely
personal or household activity". Someone logging their own meals is inside that
exclusion.

Recital 18 supplies the carve-back everyone cites at this point:

> This Regulation does not apply to the processing of personal data by a natural
> person in the course of a purely personal or household activity and thus with no
> connection to a professional or commercial activity … **However, this Regulation
> applies to controllers or processors which provide the means for processing
> personal data for such personal or household activities.**

Read carefully, recital 18 says the Regulation *applies to* such controllers and
processors. It does not say that providing the means *makes* you one. Whether the
project is a controller still has to be answered under Article 4(7).

Against controllership, on the BYO-endpoint design:

- The project does not determine the **purpose** of any transmission. The user
  does, per request, by choosing to send a particular photo or sentence.
- The project does not determine the **recipient**. The user pastes the endpoint
  URL. EDPB 07/2020 §40 lists "the categories of recipients ('who shall have
  access to them?')" among the "essential means" that "are traditionally and
  inherently reserved to the controller" — and here the user determines it.
- The project does not determine **retention**. That is between the user and the
  endpoint's terms.
- The project never **receives** the data. There is no server, no log, no key.

For controllership, honestly stated: the project does determine part of what EDPB
calls essential means — "the type of personal data which are processed ('which
data shall be processed?')" — because the request body is built by code the
project wrote. It decides that the photo goes in, that the prompt includes the
user's free text, and (a design choice worth making explicitly) whether anything
else does.

The better reading is that the project is **neither controller nor processor**:
it processes no personal data at all, it merely ships a tool. But this is the
genuinely contestable question in the whole document, and the answer would be
different if the project ever operated a proxy, bundled a key, or received
telemetry about requests. Two guardrails follow from that: never add a
project-operated relay, and never log request contents to Sentry.

### The photo containing an identifiable third party

Meal photos may contain faces, hands or other diners. When the user sends such a
photo to a commercial endpoint, that is processing of a third party's personal
data by the user, and the third party did not consent.

This is the **user's** exposure, not the project's, and in practice a small one:
Article 2(2)(c) covers purely personal or household activity, and a single
API call to a service the user chose in order to log their own dinner sits much
closer to the household end than to publication. It is not a problem the project
can solve on the user's behalf, and it is not one the project creates.

What the project can do — as design choices, not obligations:

- Make the photo path opt-in per use, not a background behaviour.
- Say plainly, at the point of sending, that the photo leaves the device and
  where it goes.
- Consider offering an on-device crop or face-blur before send. This is a
  courtesy, not a duty, and it should not be presented as making the send lawful.

Note that faces in a photo are **not** Article 9 biometric data merely by being
faces. Article 4(14) and Article 9(1) cover "biometric data **for the purpose of
uniquely identifying a natural person**". Naming the food on the plate is not that
purpose. Do not add any feature that asks the model about the people in the frame.

### Article 9 — the special-category angle

Article 9(1) prohibits, subject to exceptions, "processing of personal data
revealing racial or ethnic origin, political opinions, **religious or philosophical
beliefs** … or **data concerning health** or data concerning a natural person's sex
life or sexual orientation".

Article 4(15) defines data concerning health as "personal data related to the
physical or mental health of a natural person … which reveal information about his
or her health status", and recital 35 reads it broadly: "all data pertaining to the
health status of a data subject which reveal information relating to the past,
current or future physical or mental health status … any information on, for
example, a disease, disability, disease risk, medical history, clinical treatment
or the physiological or biomedical state of the data subject **independent of its
source**".

A food log can plainly reveal all three of the categories in the question — a
consistently gluten-free diary suggests coeliac disease; a halal or kosher or
Lenten pattern reveals religious belief; a sudden shift in intake plus a weight
curve can suggest pregnancy. Whether a bare list of foods is itself "data
concerning health" is contested and depends on inference, but the safe assumption
is that a longitudinal diary is.

Where that matters:

- **Not for the project**, which holds none of it and never has. The data sits in
  AES-encrypted Hive boxes on the device.
- **Not for the user's own data** while they stay inside Article 2(2)(c).
- **For the endpoint operator**, whose lawful basis for handling Article 9 data is
  a matter between them and the user, governed by their terms. It is a reason to
  surface which endpoint the user is about to send to, and to make the default
  endpoint's data-handling terms discoverable from the settings screen.

Article 26 (joint controllers) would only come into play if the project turned out
to be a controller alongside the user — an outcome that would require a written
arrangement whose "essence … shall be made available to the data subject". That
would be an odd result, and if a lawyer thought it likely, the design should
change rather than the paperwork.

## Apple App Review Guidelines

Primary text: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/),
last updated 8 June 2026. Guidelines 1.4.1 and 1.4.2 were already verified in
[#599](https://github.com/simonoppowa/OpenNutriTracker/issues/599) and nothing
found here changes that analysis.

### The AI-specific provision does exist. It is in 5.1.2(i)

The phrase "third-party AI" appears **exactly once** in the entire guidelines
document, in 5.1.2(i) "Data Use and Sharing":

> Unless otherwise permitted by law, you may not use, transmit, or share someone's
> personal data without first obtaining their permission. You must provide access
> to information about how and where the data will be used. **You must clearly
> disclose where personal data will be shared with third parties, including with
> third-party AI, and obtain explicit permission before doing so.**

There is no separate AI section, no AI-specific guideline number, and nothing in
the guidelines about labelling AI-generated output. The whole of Apple's
AI-specific requirement, for this feature, is that sentence: **disclose, and get
explicit permission, before sharing personal data with third-party AI.**

### 5.1.1 — Data Collection and Storage

5.1.1(i) requires the privacy policy to "Identify what data, if any, the
app/service collects, how it collects that data, and all uses of that data", and
to:

> Confirm that any third party with whom an app shares user data … will provide
> the same or equal protection of user data as stated in the app's privacy policy
> and required by these Guidelines.

This is the one place where BYO-key creates a genuine tension rather than an
easier answer. You cannot confirm the data-protection posture of an endpoint you
have never seen, because the user typed the URL. The honest position is that the
recipient is the user's counterparty, chosen by the user, and that the policy
names the *default* endpoint and describes the category for the rest. Whether App
Review accepts that framing is unknowable in advance; it is a review-risk item,
not a resolvable question.

5.1.1(ii) requires consent for collection "even if such data is considered to be
anonymous", and "an easily accessible and understandable way to withdraw consent"
— satisfied by the settings toggle, provided disabling it is as easy as enabling
it.

5.1.1(iii) data minimisation: "Where possible, use the out-of-process picker or a
share sheet rather than requesting full access to protected resources like Photos
or Contacts." Relevant to the tier-2 camera/photo entry point.

5.1.1(ix) is worth flagging even though it is not AI-specific:

> Apps that provide services in highly regulated fields (such as banking and
> financial services, healthcare, gambling, legal cannabis use, air travel and
> crypto exchanges) or that require sensitive user information should be submitted
> by a legal entity that provides the services, and not by an individual
> developer.

A nutrition tracker is not "healthcare" on any ordinary reading, and the
guideline is aimed at apps that *provide* regulated services. But the app is
published by an individual, and anything that pushes the app toward looking like
healthcare — see the MDR section — makes this clause more visible than it needs
to be.

### 5.1.3 — Health and Health Research

5.1.3(i) prohibits using or disclosing data gathered "in the health, fitness, and
medical research context—including from the Clinical Health Records API, HealthKit
API, Motion and Fitness, MovementDisorder APIs, or health-related human subject
research—for advertising, marketing, or other use-based data mining purposes", and
ends: "You must disclose the specific health data that you are collecting from the
device."

The app does not use HealthKit (README: "No location, contacts, microphone, or
health-data access"), so the API-scoped part of 5.1.3(i) does not engage. The
prohibition on advertising and use-based data mining is satisfied trivially — there
is no advertising and no data mining. 5.1.3(ii)–(iv) concern writing to HealthKit
and human-subject research; neither applies.

### Does a user-supplied API key change the analysis versus a developer-supplied one?

For **5.1.2(i)**, no. The rule is about *where personal data will be shared*, not
about who pays for the sharing. Personal data leaves the device to a third party
either way, so the disclose-and-obtain-permission duty is identical.

What BYO-key does change is the *content* of the disclosure. With a
developer-supplied key you name one recipient and can point at its terms. With a
user-supplied endpoint you must instead say: (a) that the destination is whatever
address the user configured; (b) which address is prefilled by default and what
its terms say; and (c) that the project has no visibility into and no control over
what the chosen endpoint does with the data. That last sentence is both the honest
position and the strongest one.

What BYO-key genuinely improves is the *first-party* story: the project receives
nothing, so there is no first-party collection to disclose, no retention policy to
write, and no deletion mechanism to build for data the project never holds.

## Google Play

### Generative AI — the in-app reporting requirement is the concrete new build item

[AI-Generated Content policy](https://support.google.com/googleplay/android-developer/answer/13985936):

> AI-generated content is content that is created by generative AI models based on
> user prompts. Examples of AI-generated content include:
> - Text–to-text conversational generative AI chatbots, in which interacting with
>   the chatbot is a central feature of the app
> - Image or video generated by AI based on text, image, or voice prompts

and the operative requirement:

> **Apps that generate content using AI must contain in-app user reporting or
> flagging features that allow users to report or flag offensive content to
> developers without needing to exit the app.** Developers should utilize user
> reports to inform content filtering and moderation in their apps.

The two listed examples are chatbots and image/video generation, and a structured
meal list is neither. But the operative sentence is not scoped to those examples —
it says "apps that generate content using AI". Tiers 1–2 do generate text content
from user prompts. Arguing the scope is not worth it: a "Report this result"
affordance on the review screen is a few hours of work and settles it. Build it.

There is a live-policy caveat here: the equivalent requirement under Apple's 1.2
(user-generated content) is not engaged, because model output on the user's own
device is not content posted by a community of users. Google's rule is
developer-facing reporting, not community moderation, which is a lower bar.

### User Data policy

[User Data policy](https://support.google.com/googleplay/android-developer/answer/9888076)
extends the third-party rules to AI explicitly:

> If you include third party code (for example, an SDK) in your app, you must
> ensure that the third party code used in your app, and that third party's
> practices with respect to user data from your app, are compliant with Google
> Play Developer Program policies … **These requirements also apply to third-party
> AI integrations (such as products, services, code) and you remain responsible
> for ensuring compliance with this policy, including limited use, disclosure and
> consent.**

Note "you remain responsible" — Google places the burden on the developer even
where the integration is one the user configured. This is the same tension as
Apple 5.1.1(i), and it has the same honest answer and the same residual risk.

Two helpful provisions. On sale:

> "Sale" means the exchange or transfer of personal and sensitive user data to a
> third party for monetary consideration. **User-initiated transfer of personal and
> sensitive user data (for example, when the user is using a feature of the app to
> transfer a file to a third party …), is not regarded as sale.**

And the Prominent Disclosure & Consent requirement is triggered where the handling
"may not be within the reasonable expectation of the user of the product or feature
in question". An opt-in settings screen where the user pastes their own endpoint is
arguably within expectation. Send an in-app disclosure anyway before the first
request, and again the first time a photo is sent — it is cheap and it is what the
Apple rule requires regardless.

Health data is listed in the policy's own enumeration of "personal and sensitive
user data", alongside "camera".

### Health Content and Services — an existing gap, independent of AI

[Health Content and Services](https://support.google.com/googleplay/android-developer/answer/12261419).
Scope:

> If your app offers health-related features or information as part of its
> functionality, or accesses health data to support non-health features, it must
> comply with the existing Google Play Developer Policies …

Google's own [health app categories](https://support.google.com/googleplay/android-developer/answer/13996367)
places nutrition trackers in "health and fitness apps" — "These apps usually inform
or let users track or sync information about their personal health and fitness …
in areas such as fitness, nutrition, wellness, and sleep. Examples include fitness
trackers, **nutrition trackers**, sleep trackers, and stress management apps" — and
not in "medical apps", which is the SaMD-adjacent category. That is the right
outcome and consistent with the MDR analysis.

But the policy then says:

> Apps that are regulated because they are a medical device must be declared as
> such … **Other health and medical apps must include a clear disclaimer in their
> app description indicating that the app is "not a medical device and does not
> diagnose, treat, cure, or prevent any medical condition."**
>
> Apps must also remind users to consult a healthcare professional for medical
> advice, diagnosis, or treatment.

Two observations about the repo as it stands today:

1. `fastlane/metadata/android/en-US/full_description.txt` does not contain that
   disclaimer, or anything close to it.
2. The in-app disclaimer string (`disclaimerText` in `lib/l10n/intl_en.arb`) reads
   "OpenNutriTracker is not a medical **application**. All data provided is not
   validated and should be used with caution. Please maintain a healthy lifestyle
   and consult a professional if you have any problems." That covers the
   consult-a-professional limb well, but it is not the phrase Google specifies, and
   the policy requires the disclaimer "in their app description", not only in-app.

This is a **present-tense finding that has nothing to do with AI** and is the most
actionable item in this document. It costs one paragraph in the store listing.

The policy also requires the Health apps declaration form in Play Console for all
developers, with nutrition tracking as a declarable feature.

### Data safety — what BYO-key does and does not change

[Data safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469).

Collection:

> "Collect" means transmitting data from your app off a user's device.

with the on-device exclusion:

> On-device access/processing: User data accessed by your app that is only
> processed locally on the user's device and not sent off device does not need to
> be disclosed.

Sharing:

> "Sharing" refers to transferring user data collected from your app to a third
> party.

with an exception that fits this design almost exactly:

> The following types of data transfers do not need to be disclosed as "sharing":
> … **User-initiated action or prominent disclosure and user consent.** Transferring
> user data to a third party based on a specific user-initiated action, where the
> user reasonably expects the data to be shared, or based on a prominent in-app
> disclosure and consent that meets the requirements described in our User Data
> policy.

So the answer to "does BYO-key change the Data safety form answers, given the app
itself transmits nothing to the developer?" is: **it changes the *sharing* answers,
not the *collection* answers.**

- **Collection.** Yes, tiers 1–2 collect in Play's sense, because "collect" means
  transmitting off device — irrespective of destination. Photos and the meal
  description (which Play would treat under "Health and fitness" and "Photos and
  videos") must be declared as collected, marked **optional** (the user can use the
  entire app without ever enabling the feature), with purpose "App functionality".
  Tier 0 collects nothing new.
- **Sharing.** The user-initiated-action exception is a strong fit — the user
  pastes an endpoint, then taps a button to send a specific photo or sentence. On
  the strict reading you need not declare sharing. Declare it anyway: it costs
  nothing, it is unambiguously true, and it aligns the Play answers with the
  Apple 5.1.2(i) disclosure you have to write regardless.
- **Ephemeral processing** is defined as data "only stored in memory and retained
  for no longer than necessary to service the specific request in real-time", and
  such data "needs to be included in your form response, but … will not be
  disclosed in your app's Data safety section". **Do not rely on this.** You cannot
  warrant the retention behaviour of an endpoint the user chose. Anthropic's own
  vision documentation describing images as ephemeral would support the claim for
  that one default, but not for an arbitrary URL.

The "Encryption in transit" declaration remains true — HTTPS to whatever endpoint.

## F-Droid

Primary text: [Anti-Features](https://f-droid.org/en/docs/Anti-Features/),
[Inclusion Policy](https://f-droid.org/en/docs/Inclusion_Policy/).

### The label, and whether it blocks inclusion

> **Non-Free Network Services** — This Anti-Feature is applied to apps that
> **promote or depend entirely on** a proprietary network service.

The Inclusion Policy answers the blocking question directly:

> F-Droid uses pre-defined labels known as Anti-Features which serve as warning
> indicators about user freedom, privacy or etc. **without necessarily disqualifying
> applications from inclusion.**

So `NonFreeNet` is a label, not a bar. It is also not one of the flags the client
hides by default — the Anti-Features page notes that only apps marked `Tracking`
"are not displayed by default".

The Inclusion Policy also contains a line that BYO-key satisfies by construction:

> F-Droid does not sign up for any API keys. Even if provided by a third party, we
> include them in both binary and source code releases.

### Does supporting Ollama avoid the flag? On the observed record, no

Three LLM clients currently in the F-Droid main repository, all of which support
a locally-hosted endpoint, and all of which carry `NonFreeNet`:

| App | Local option supported | Anti-Feature and F-Droid's stated reason |
| :-- | :-- | :-- |
| [maid](https://f-droid.org/packages/com.danemadsen.maid/) | llama.cpp locally, plus Ollama | `NonFreeNet` — "Remote models rely on Mistral, Google Gemini and OpenAI." |
| [oxproxion](https://f-droid.org/packages/io.github.stardomains3.oxproxion/) | Ollama, LM Studio, llama.cpp, MLX LM | `NonFreeNet` — "Depends on OpenRouter API servers (OpenRouter LLM endpoints)." |
| [Kai 9000](https://f-droid.org/packages/com.inspiredandroid.kai/) | Ollama, LM Studio, any OpenAI-compatible API | `NonFreeNet` — "Rely on Gemini and Groq" |

maid is the decisive case: it ships genuine on-device inference via llama.cpp and
is still flagged, because it also *promotes* proprietary remote models. The
"promote" limb of the definition does the work, and shipping a prefilled default
endpoint pointing at a commercial provider is promotion in exactly that sense.

### The precedent that actually points at a solution

Two apps handle an optional proprietary network integration without earning any
anti-feature, and both do it the same way — a **build flavour**, not a settings
toggle:

- **[Breezy Weather](https://f-droid.org/packages/org.breezyweather/)** supports
  more than 50 weather sources, some of them proprietary. The F-Droid build is the
  `freenet` gradle flavour — the shipped version name is literally `6.2.1_freenet`,
  and the [fdroiddata metadata](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/org.breezyweather.yml)
  pins `gradle: [freenet]`. The listing carries **no** anti-features.
- **[Translate You](https://f-droid.org/packages/com.bnyro.translate/)** supports
  DeepL among six engines; the [metadata](https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/com.bnyro.translate.yml)
  builds `gradle: [libre]`. Also no anti-features.

So the shape that works is: an `fdroid` product flavour that either omits the
cloud path entirely or ships the endpoint field with no prefilled commercial
default. A runtime toggle in Settings is not enough — maid, oxproxion and Kai 9000
all have one, and all three are flagged.

### Practical relevance today

The [RFP for OpenNutriTracker (#2540)](https://gitlab.com/fdroid/rfp/-/issues/2540)
is still open and has had no activity since it was filed on 2023-09-11. There is
nothing in F-Droid to lose right now. The forward-looking point is that if the RFP
is ever picked up, a `NonFreeNet` label would be the outcome of a prefilled
commercial default, it would not block inclusion, and a build flavour would avoid
it if the project cared to.

## GPL-3.0

Primary sources: [GPL FAQ](https://www.gnu.org/licenses/gpl-faq.html),
[Why the Affero GPL](https://www.gnu.org/licenses/why-affero-gpl.html), and the
GPLv3 text in this repo's `LICENSE`.

**There is no licence problem, and the expectation in the issue is correct.** The
FSF's own criterion for whether two pieces of software form one program turns on
the mechanism and semantics of communication:

> If the modules are included in the same executable file, they are definitely
> combined in one program. If modules are designed to run linked together in a
> shared address space, that almost surely means combining them into one program.
> **By contrast, pipes, sockets and command-line arguments are communication
> mechanisms normally used between two separate programs. So when they are used for
> communication, the modules normally are separate programs.**

An HTTPS request carrying JSON to a remote endpoint is a socket, and the semantics
are an ordinary request/response — not "exchanging complex internal data
structures". The remote model is not linked, is not conveyed, and is not part of
the Corresponding Source. Nothing about the GPL is engaged by calling a proprietary
network API.

### The Affero clause, and why it is misread

The AGPL closes a gap about **running modified software on a server**, not about
being a client of one. gnu.org states the loophole as: "When D modifies the
program, he might very likely run it on his own server and never release copies",
and the trigger as: "If you run a modified program on a server and let other users
communicate with it there, your server must also allow them to download the source
code corresponding to the modified version running there."

The FAQ makes the client/server point explicitly — the question is "whether or not
there is a reasonable expectation that a person will be interacting with the
program remotely over a network", and:

> If a program is not expressly designed to interact with a user through a network,
> but is being run in an environment where it happens to do so, then it does not
> fall into this category.

OpenNutriTracker runs no server. Its users interact with it on their own devices.
Even if the app were AGPL rather than GPL, nothing would be triggered by making
outbound API calls.

GPLv3 section 13, the one place "Affero" appears in the licence, is a
**compatibility** clause, not an obligation:

> Notwithstanding any other provision of this License, you have permission to link
> or combine any covered work with a work licensed under version 3 of the GNU
> Affero General Public License into a single combined work, and to convey the
> resulting work. The terms of this License will continue to apply to the part
> which is the covered work, but the special requirements of the GNU Affero General
> Public License, section 13, concerning interaction through a network will apply
> to the combination as such.

It only bites if you *combine* GPLv3 code with AGPLv3 code. Calling an API does not
combine anything.

Two real constraints that are adjacent but not licence matters:

- **Never ship a project API key.** That is a credential-distribution problem
  (and F-Droid would strip or refuse it — see the Inclusion Policy quote above),
  not a GPL problem.
- **The endpoint's terms of service** bind whoever agreed to them — the user. If a
  provider's terms restrict a use case, that is the user's contract, not a
  condition on the software licence.

## German-specific

The developer appears to be Germany-based. Four instruments add something, and one
that people expect to add something does not.

### KI-MIG — the German AI Act implementation, in force since 29 July 2026

[Gesetz zur Marktüberwachung und Innovationsförderung von künstlicher Intelligenz
(KI-MIG)](https://www.gesetze-im-internet.de/ki-mig/BJNR0DF0B0026.html), published
in the Bundesgesetzblatt on 28 July 2026, in force 29 July 2026
([BMDS announcement](https://bmds.bund.de/aktuelles/aktuelle-meldungen/detail/neues-ki-gesetz-tritt-in-kraft),
[legislative record](https://bmds.bund.de/service/gesetzgebungsverfahren/gesetz-zur-durchfuehrung-der-ki-verordnung)).

§ 1 Anwendungsbereich:

> Dieses Gesetz dient der Durchführung der Verordnung (EU) 2024/1689. Es gilt für
> KI-Systeme im Sinne des Artikels 3 Nummer 1 der Verordnung (EU) 2024/1689 und
> regelt **ergänzend zu den in der Verordnung enthaltenen Bestimmungen** die
> zuständigen Behörden gemäß Artikel 70 Absatz 1 Satz 1 …, Maßnahmen zur
> Innovationsförderung sowie Bußgelder bei Verstößen gegen die Vorschriften der
> Verordnung gemäß Artikel 99 Absatz 1 Satz 1 …

**It adds no substantive obligation beyond the Regulation.** It is institutional:
it designates the Bundesnetzagentur as market-surveillance authority, single point
of contact and complaints body; it provides for regulatory sandboxes; and it
handles procedure.

§ 15 does create German *Ordnungswidrigkeiten*, but only for AI Act provisions the
Regulation itself does not fine — Articles 21, 27, 45 and 86 — capped at
"eine Geldbuße bis zu fünfzigtausend Euro" (§ 15(3)). **Article 50 is not among
them**; Article 50 breaches are fined under Article 99(4)(g) of the Regulation
directly, with § 16 KI-MIG applying the Ordnungswidrigkeitengesetz procedure.

Net effect for this project: the German layer changes *who enforces* (BNetzA) and
*how*, not *what is owed*.

### UWG § 5 — the strongest German argument for the `estimated` marker

[§ 5 UWG, Irreführende geschäftliche Handlungen](https://www.gesetze-im-internet.de/uwg_2004/__5.html):

> (1) Unlauter handelt, wer eine irreführende geschäftliche Handlung vornimmt, die
> geeignet ist, den Verbraucher … zu einer geschäftlichen Entscheidung zu
> veranlassen, die er andernfalls nicht getroffen hätte.
>
> (2) Eine geschäftliche Handlung ist irreführend, wenn sie unwahre Angaben enthält
> oder sonstige zur Täuschung geeignete Angaben über folgende Umstände enthält:
> 1. die wesentlichen Merkmale der Ware oder Dienstleistung wie … Zwecktauglichkeit,
> Verwendungsmöglichkeit, Menge, Beschaffenheit … **von der Verwendung zu erwartende
> Ergebnisse** oder die Ergebnisse oder wesentlichen Bestandteile von Tests der
> Waren oder Dienstleistungen …

This is the realistic German exposure, and it is not about AI as such. The README
sells the app on "every number is cited". Presenting a model's guess at the
calories in a home-cooked stew in the same visual register as a BLS-sourced figure
is capable of misleading about "die wesentlichen Merkmale" and "von der Verwendung
zu erwartende Ergebnisse".

This is the provision that turns the `estimated` provenance marker from good
manners into a compliance artefact. It also means the marker must be visible where
the number is read — the diary row, the day total, the export — not only on the
review screen where the item was added.

Practical note on enforcement: UWG claims are typically brought by competitors and
by qualified associations under § 8(3) UWG, which is a far cheaper and more likely
route than a regulator action.

### DDG § 5 — Impressum

[§ 5 DDG, Allgemeine Informationspflichten](https://www.gesetze-im-internet.de/ddg/__5.html)
(the successor to TMG § 5) requires providers of "geschäftsmäßige, in der Regel
gegen Entgelt angebotene digitale Dienste" to keep permanently available, "leicht
erkennbar und unmittelbar erreichbar":

> 1. den Namen und die Anschrift, unter der sie niedergelassen sind …
> 2. Angaben, die eine schnelle elektronische Kontaktaufnahme und eine unmittelbare
> Kommunikation mit ihnen ermöglichen, einschließlich der Adresse für die
> elektronische Post …

Whether a free open-source app is "geschäftsmäßig" is the usual German argument;
the presence of a Patreon and paid store presence makes the conservative answer the
right one. This duty is entirely independent of AI and applies today. Worth
confirming that an Impressum is reachable from the app and from the project site.

### TDDDG § 25 — terminal-equipment access

[§ 25 TDDDG](https://www.gesetze-im-internet.de/ttdsg/__25.html) requires consent
for storing information on, or accessing information already stored on, the user's
terminal equipment, with an exception in § 25(2) Nr. 2:

> … wenn die Speicherung von Informationen in der Endeinrichtung des Endnutzers
> oder der Zugriff auf bereits in der Endeinrichtung des Endnutzers gespeicherte
> Informationen **unbedingt erforderlich ist, damit der Anbieter eines digitalen
> Dienstes einen vom Nutzer ausdrücklich gewünschten digitalen Dienst zur Verfügung
> stellen kann.**

Reading a photo the user just selected, in order to perform the analysis the user
just requested, and storing the API key the user just pasted, both fit § 25(2)
Nr. 2 comfortably. No separate consent banner is needed for the *device access*.
The *transmission to a third party* is a GDPR question, addressed above, not a
§ 25 one.

### HWG § 1 — only if the marketing goes medical

[§ 1 HWG](https://www.gesetze-im-internet.de/heilmwerbg/__1.html) applies to
advertising for medicinal products, for medical devices within Article 2(1) MDR,
and:

> 2. andere Mittel, Verfahren, Behandlungen und Gegenstände, soweit sich die
> Werbeaussage bezieht a) auf die **Erkennung, Beseitigung oder Linderung von
> Krankheiten, Leiden, Körperschäden oder krankhaften Beschwerden beim Menschen** …

The trigger is the *content of the advertising statement*, not the nature of the
product. This is the same lever as MDR intended purpose: keep the marketing off
disease-detection and disease-alleviation ground and the HWG never engages. It is
worth noting that HWG imposes stricter rules than UWG once it does engage, so the
two sections reinforce each other.

### What does *not* apply: nutrition and health claims law

[Regulation (EC) No 1924/2006](https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:02006R1924-20141213)
Article 1(2): "This Regulation shall apply to nutrition and health claims made in
commercial communications, whether in the labelling, presentation or advertising of
**foods to be delivered as such to the final consumer**." A "claim" under Article
2(2)(1) is a representation "that a food has particular characteristics". The
addressees are food business operators marketing foods. An app that reports values
sourced from public composition databases is not making a claim about a food it
places on the market. The same reasoning keeps LFGB out of scope. Neither adds a
duty here.

## Concrete obligations checklist

### Must be built or written — tiers 1–2

| # | Item | Driven by |
| :-- | :-- | :-- |
| 1 | **In-app disclosure + explicit consent gate**, shown before the first request and again before the first photo send, naming the default endpoint and stating that the destination is whatever the user configured and that the project sees nothing. Must be screen-reader reachable. | Apple 5.1.2(i); Google Play User Data (Prominent Disclosure); AI Act Art. 50(1)+(5) |
| 2 | **In-app "report this result" control** on the review screen, routed to the issue tracker or a mail intent, without leaving the app. | Google Play AI-Generated Content policy |
| 3 | **`estimated` provenance persisted machine-readably** — the new `MealSourceEntity` value in the Hive record and in `docs/export-format.md`, not only rendered on screen. | AI Act Art. 50(2) (machine-readable marking) |
| 4 | **Visible `estimated` marker on every surface where the number is read** — diary row, day total, nutrient panel, export. | UWG § 5(2) Nr. 1; the README's "every number is cited" claim |
| 5 | **Privacy-policy section** covering: what is sent (meal text, optionally a photo), to whom (an endpoint the user configures; name the prefilled default), that the project receives and stores nothing, that retention is governed by the chosen endpoint's terms, and that the feature is off by default. | Apple 5.1.1(i); Google Play Health policy privacy-policy requirement; GDPR transparency posture |
| 6 | **Settings copy** stating plainly: off by default; the key is stored in Keystore/Keychain and never leaves the device except to the endpoint the user named; the project has no visibility into the endpoint; how to turn it off and delete the key. | Apple 5.1.1(ii) withdraw-consent; F-Droid/user-trust posture |
| 7 | **Data safety form revision**: declare "Photos" and health/fitness info as **collected**, marked **optional**, purpose "App functionality". Declare sharing too, notwithstanding the user-initiated exception. Do not claim the ephemeral carve-out. | Google Play Data safety |
| 8 | **Health apps declaration** in Play Console kept accurate for the new features. | Google Play Health Content and Services |
| 9 | **Never log request or response contents to Sentry**, and never introduce a project-operated relay. | The GDPR "not a controller" position depends on both |

### Must be written — independent of AI, applies today

| # | Item | Driven by |
| :-- | :-- | :-- |
| 10 | Add to the Play store description: the app "is not a medical device and does not diagnose, treat, cure, or prevent any medical condition", plus a reminder to consult a healthcare professional. The current `full_description.txt` has neither; the in-app `disclaimerText` says "not a medical **application**", which is not the specified phrase and is not in the app description. | Google Play Health Content and Services |
| 11 | Confirm an Impressum with name, postal address and email is reachable from the app and the project site. | DDG § 5(1) |

### Advisable, not required

- Keep the AI feature out of the store listing's headline feature list, or describe
  it in a way that cannot be read as a health claim. Every medical-adjacent word
  in marketing copy is an input to the MDR intended-purpose test and to HWG § 1.
- Offer an on-device crop before sending a photo. Courtesy toward third parties in
  frame; not a legal requirement and should not be presented as one.
- Never ask the model anything about people in the photo. Keeps Annex III(1) and
  GDPR Article 9 biometrics unambiguously out of scope.
- If F-Droid inclusion is ever pursued, add an `fdroid` product flavour that omits
  the cloud path or ships no prefilled commercial endpoint — the Breezy Weather /
  Translate You pattern. A runtime toggle will not avoid `NonFreeNet`.
- Document the feature's known failure modes in the repo. This is the cheapest way
  to discharge AI Act Article 4 and the best evidence against a UWG § 5 claim.
- Surface the default endpoint's data-handling terms from the settings screen, so
  a user can see what they are agreeing to before pasting a key.

## What I could not verify

- **Whether a free, non-commercial GPL app is "made available on the market … in
  the course of a commercial activity"** within AI Act Article 3(10), and therefore
  whether "placing on the market" in Article 3(3) is met at all. The Blue Guide is
  the usual authority and reads it broadly, but I did not fetch it. If it is not
  met, the project is not a provider and Article 50 does not attach.
- **Whether voluntary donations (the repo's Patreon) count as "monetised"** under
  recital 103 and so cost the project the Article 2(12) free-software exemption.
  Since the exemption is disapplied for Article 50 anyway, this matters less than
  it looks, but it matters for everything else.
- **Whether the Article 111(4) four-month transitional reaches a feature released
  after 2 August 2026.** On its face it is scoped to systems already on the market
  on that date, which would mean no grace period for tiers 1–2.
- **MDCG 2025-6** (FAQ on the interplay between MDR/IVDR and the AI Act, June 2025)
  exists and is on the Commission's site, but I did not read it. It is scoped to
  AI systems that *are* medical devices, so it should not change the analysis here
  — but that is an assumption, not a verified fact.
- **CJEU case law on controllership for embedded code** (Fashion ID, C-40/17) and
  on the household exemption for photographs (Ryneš, C-212/13; Lindqvist,
  C-101/01). These are the cases that would decide the "does shipping the code make
  you a controller" question, and I did not read the judgments.
- **How App Review actually treats a user-supplied endpoint** under 5.1.1(i)'s
  "confirm that any third party … will provide the same or equal protection"
  requirement. There is no published guidance and this is unknowable from the text.
- **Whether Google would read a structured meal list as "AI-generated content"**
  within the policy's scope. The examples say chatbots and images; the operative
  sentence is broader. Building the report control moots the question.
- **Whether the app's Play Console Health apps declaration is currently accurate**
  — that lives in the Console and is not visible from the repo.
- **The exact Bundesgesetzblatt citation for KI-MIG.** Entry into force
  (29 July 2026) and the consolidated text on gesetze-im-internet.de are confirmed;
  the BGBl. number is not.

## Questions worth paying a lawyer for

1. **Is the project a "provider" of an AI system under Article 3(3) at all, given
   that the inference component is supplied by the user at runtime and the software
   is free and open-source?** Everything in the AI Act section downstream of this
   changes if the answer is no. This is the single highest-leverage question.
2. **Does Article 50(2) reach a structured nutrition estimate, and does the
   "do not substantially alter … the semantics" exception cover the tier-1 text
   path and/or the tier-2 photo path?** If tier 1 is inside the exception and tier
   2 is not, that is a real scoping decision — it could justify shipping tier 1 and
   deferring tier 2 on compliance grounds rather than product grounds.
3. **Is the machine-readable `estimated` provenance marker a defensible Article
   50(2) technical solution for a project that does not run the model**, given the
   "as far as this is technically feasible … costs of implementation … state of the
   art" proportionality language? A short written rationale, reviewed once, is
   worth having on file before release.
4. **Does shipping the code that makes the request make the project a controller or
   joint controller under GDPR Article 4(7), read with recital 18 and the Fashion ID
   line of cases?** If the answer is yes, the design should change — a project that
   is a controller for data it never receives is an unmanageable position.
5. **Does the app's current Play store description satisfy the Google Play Health
   Content and Services disclaimer requirement**, and if not, is the exact
   specified wording required or is an equivalent acceptable? This is cheap to fix
   and applies today, before any AI work lands.
6. **Is the developer's current publishing arrangement (individual, not a legal
   entity) a risk under Apple 5.1.1(ix)** as the app accumulates health-adjacent
   features — and would incorporating change the MDR, UWG or product-liability
   picture in a way that matters?
7. **Under UWG § 5, how prominent must the `estimated` marker be to defeat a
   misleading-advertising claim, given that the project's own marketing leads with
   "every number is cited"?** This is a German-law judgement about a claim the
   project chose to make, and it is the most likely source of an actual complaint.
