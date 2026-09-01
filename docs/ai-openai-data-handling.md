# What does OpenAI do with prompts and images, and what survives of the README's claims?

**Verdict: OpenAI publishes no equivalent to Anthropic's ephemerality
sentence, and the honest answer is that no such sentence exists.** The
nearest thing OpenAI writes about images runs the *other* way: image
inputs are covered by the same up-to-30-day abuse-monitoring retention as
text, and the only image-specific sentence in OpenAI's data documentation
describes a case where an image is *kept for human review even under the
strongest retention control OpenAI sells*. The word "ephemeral" appears
exactly once on OpenAI's data-controls page and refers to Code Interpreter
container storage, not to images. **The README cannot quote one sentence
for an OpenAI path; it needs two, and both are weaker than what it quotes
today.** This is a documents review, not legal advice.

## The sentences the README could stand behind

There is no single-sentence answer, so these are the two that would have to
be quoted together. Both were read on the live page on 2026-08-16.

**On training** — [Data controls in the OpenAI platform](https://developers.openai.com/api/docs/guides/your-data):

> Your data is your data. As of March 1, 2023, data sent to the OpenAI API
> is not used to train or improve OpenAI models (unless you explicitly opt
> in to share data with us).

**On retention** — same page, and this is the one that must not be trimmed:

> By default, abuse monitoring logs are generated for all API feature usage
> and retained for up to 30 days, unless longer retention is required by
> law, or is reasonably necessary to protect our services or any third
> party from harm.

Quote that qualifier in full. The [Enterprise privacy](https://openai.com/enterprise-privacy/)
page (updated 8 January 2026) carries a **shorter** version of the same
promise — *"After 30 days, API inputs and outputs are removed from our
systems, unless we are legally required to retain them"* — which omits the
"reasonably necessary … from harm" escape hatch. **Do not quote the
enterprise-privacy version.** It is the more flattering of the two and the
developer documentation contradicts it by being broader. Using the weaker
text is the project's own house rule, and here the two OpenAI pages
disagree with each other.

## Bottom line up front

1. **The ephemerality sentence has no counterpart.** Anthropic says image
   uploads are *"ephemeral and not stored beyond the duration of the API
   request"*. OpenAI's equivalent claim is "up to 30 days", with two
   exceptions, plus a CSAM-scanning carve-out that survives even Zero Data
   Retention. The gap is not a wording difference; it is the difference
   between *nothing is kept* and *content is kept for a month by default*.
   See [Section C](#c-images-the-sentence-that-does-not-exist).
2. **Training is genuinely fine, and it is the one place OpenAI matches
   Anthropic.** API data is not trained on by default, the position is
   contractual-adjacent (documentation, incorporated by Service terms §1)
   rather than marketing, and it is explicitly different from the consumer
   products. See [Section A](#a-training).
3. **Zero Data Retention is out of reach for the app's actual user.** It is
   *"subject to prior approval by OpenAI and acceptance of additional
   requirements"*, routed through a sales team, and the marketing page
   scopes it to *"qualifying organizations"*. A solo BYO-key hobbyist is
   not going to obtain it. **The app must therefore promise the 30-day
   default, not the ZDR case**, and must not mention ZDR as though it were
   available. See [Section B](#b-retention-and-whether-zdr-is-reachable).
4. **Identity is the one question that answers in OpenAI's favour, and
   decisively.** `safety_identifier` is documented *"optional"* and the
   guidance says identifiers *"are recommended … but they are not
   required."* The legacy `user` field is deprecated. On a direct path the
   app sends no identifier at all — which is strictly better than the
   OpenRouter path, where an account-level identity is forwarded and cannot
   be suppressed ([#664](https://github.com/simonoppowa/OpenNutriTracker/issues/664)).
   See [Section D](#d-identity-the-field-is-optional-and-that-is-verified).
5. **WebP is accepted, verbatim and without qualification.** No transcode
   is needed. The app's fallback media types are `webp`, `jpeg`, `png`,
   `gif` — exactly OpenAI's accepted set. See
   [Section C](#c-images-the-sentence-that-does-not-exist).
6. **§6 is not engaged, and this time the consistency argument from
   [#679](https://github.com/simonoppowa/OpenNutriTracker/issues/679) *is*
   available.** Anthropic's Usage Policy prohibits misusing or soliciting
   *"private information such as non-public contact details, health data,
   biometric or neural data (including facial recognition)"* — which names
   health data where OpenAI says only "private or sensitive", and which the
   project already accepted. But §6 does change what the disclosure must
   say. See [Section E](#e-service-terms-6-in-full).
7. **A fourth destination is real, documented, and named.** Cloudflare is a
   listed API sub-processor performing processing *"at the data center that
   is closest to the End User"*, and content OpenAI's classifiers flag may
   be shared with moderation vendors in the Philippines. The README's
   "every destination" table cannot describe an OpenAI path as one hop. See
   [Section F](#f-region-and-sub-processors-the-fourth-destination).

## How this was read

Primary sources only, all read on 2026-08-16. `openai.com` returns HTTP 403
to automated fetching, as [`ai-openai-key-transfer.md`](ai-openai-key-transfer.md)
recorded, so every `openai.com` quote below was read in a real browser
against the live page. `developers.openai.com` does answer automated
fetches, but **every quote from it was still verified against the rendered
page**, because a summarising fetch is exactly the failure mode
[`ai-openai-key-transfer.md`](ai-openai-key-transfer.md) §G caught inventing
a decisive sentence. Where the finding is an *absence*, it was established
by string search of the rendered page and the search term is stated so the
check is repeatable. Two search-result summaries produced during this work
were discarded rather than cited: one paraphrased the Anthropic Usage
Policy clauses closely enough to be misleading, and one attributed ZDR
eligibility criteria to OpenAI pages that do not state them.

| Document | Date it carries |
| --- | --- |
| [Data controls in the OpenAI platform](https://developers.openai.com/api/docs/guides/your-data) | no date carried |
| [Enterprise privacy at OpenAI](https://openai.com/enterprise-privacy/) | Updated **January 8, 2026** |
| [Service terms](https://openai.com/policies/service-terms/) | Updated **June 12, 2026** |
| [OpenAI Sub-processor list](https://openai.com/policies/sub-processor-list/) | Last updated **July 9, 2026** |
| [Images and vision](https://developers.openai.com/api/docs/guides/images-vision) | no date carried |
| [Safety best practices](https://developers.openai.com/api/docs/guides/safety-best-practices) | no date carried |
| [Create chat completion (API reference)](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create) | no date carried |
| [Business data privacy, security, and compliance](https://openai.com/business-data/) | no date carried — **marketing page** |
| [Anthropic Vision documentation](https://platform.claude.com/docs/en/build-with-claude/vision) | no date carried |
| [Anthropic Usage Policy](https://www.anthropic.com/legal/aup) | Effective **September 15, 2025** |

**Note the weight of the evidence.** The single most load-bearing document
here — the data-controls guide — **carries no date at all**. That is worse
than the policy documents [`ai-openai-policy-fit.md`](ai-openai-policy-fit.md)
relied on, all of which carry effective dates. The retention promise the
README would quote is a documentation page that can change without notice
and without a version marker. Service terms §1 (*"use APIs in accordance
with the applicable documentation"*) makes that documentation binding on
the Customer; it does not make it a promise binding on OpenAI.

### The behaviour this is read against

Verified in source, in
[`meal_photo_encoder.dart`](../lib/features/add_meal/util/meal_photo_encoder.dart):

- Encoding is *"WebP, quality 80, longest edge 1024 px"*, produced in memory
  and never written to the app's documents directory.
- The emitted media type is `image/webp`. If the on-device WebP encoder is
  unavailable the raw file is sent under its own type, from the set
  `{webp, jpeg, png, gif}` (`_mediaTypes`).
- `maxBytes` is `3 * 1024 * 1024`, and the comment records that *"a 1024 px
  WebP is 80–200 KB, so this never fires"*.
- One request, no conversation history, no account, no profile.

## A. Training

**API input is not used for training by default, and the position is
different from the consumer products.** This is the one axis on which
OpenAI is not weaker than Anthropic.

The operative sentence is quoted at the top of this note. What matters more
than the sentence is the *table* on the same page, which states the answer
per endpoint in a column headed **"Data used for training"**. For both
endpoints the app could use:

| Endpoint | Data used for training | Abuse monitoring retention | Application state retention |
| --- | --- | --- | --- |
| `/v1/chat/completions` | **No** | 30 days | None, see exceptions |
| `/v1/responses` | **No** | 30 days | None, see exceptions |

**The consumer contrast is stated by OpenAI itself**, on the enterprise
privacy page, and it is worth quoting because it is the thing users
actually worry about:

> OpenAI uses data from different places including public sources, licensed
> third-party data, and information created by human reviewers. We also use
> data from versions of ChatGPT and other services for individuals. By
> default, data from ChatGPT Business, ChatGPT Enterprise, ChatGPT for
> Healthcare, ChatGPT Edu, ChatGPT for Teachers, and the API Platform
> (after March 1, 2023) isn't used for training our models, unless you have
> explicitly opted in to share your data with us to improve the services.

*"We also use data from versions of ChatGPT and other services for
individuals"* is the consumer position; the API is carved out of it. A user
who has read that ChatGPT trains on conversations is reading something
true — about a different product.

**The opt-in shape.** Training requires an affirmative act by the account
holder. The enterprise privacy page: *"If you have explicitly opted in to
share your data with us (for example, through our opt-in feedback
mechanisms) to improve our services, then we may use the shared data to
train our models."* The marketing page locates the control: *"you can do so
through explicit opt-in in the API dashboard."* It is off unless the key
holder turns it on, and the app cannot turn it on.

**Where this is stated.** In documentation and on an FAQ page, not in the
Services Agreement or the Service terms. I searched the Service terms
(updated 12 June 2026) end to end: it contains **no retention provision and
no training provision at all**. So the training promise is a published
policy statement, not a contractual warranty — the same character as
Anthropic's, and no weaker.

**One caveat the app controls.** On `/v1/chat/completions` the `store`
parameter is *"optional boolean or null"* and is documented as *"Whether or
not to store the output of this chat completion request for use in our
model distillation or evals products."* On `/v1/responses` the default runs
the other way:

> The Responses API has a 30 day Application State retention period by
> default, or when the `store` parameter is set to true. Response data will
> be stored for at least 30 days.

Note *"at least"*. **An OpenAI client should use `/v1/chat/completions`, or
set `store: false` explicitly on `/v1/responses`** — otherwise the app opts
its user into a 30-day application-state store *on top of* abuse-monitoring
retention, purely by not passing a parameter. This is a concrete
implementation requirement, not a policy observation.

## B. Retention, and whether ZDR is reachable

**Two stores, not one.** OpenAI distinguishes *abuse monitoring logs*
(*"Logs generated from your use of the platform, necessary for OpenAI to
enforce our Usage Policies"*) from *application state* (*"Data persisted
from some API features in order to fulfill the task or request"*). For a
single stateless chat-completions call the second is "None"; the first is
30 days. The README must describe the first.

**What is in the logs.** *"Abuse monitoring logs may contain certain
customer content, such as prompts and responses, as well as metadata
derived from that customer content, such as classifier outputs."* So: the
meal line, the photo, and the model's answer.

**Who can read them.** This is the part with no Anthropic counterpart in
the README today, and it is the part a privacy-focused reader will care
about most. From the enterprise privacy page:

> Our access to API business data stored on our systems is limited to (1)
> authorized employees that require access for engineering support,
> investigating potential platform abuse, and legal compliance and (2)
> specialized third-party contractors who are bound by confidentiality and
> security obligations, solely to review for abuse and misuse.

**Human review by third-party contractors is contemplated, by name, for API
data.** Combined with [Section F](#f-region-and-sub-processors-the-fourth-destination),
those contractors are identifiable and located.

### Could a BYO-key hobbyist actually get ZDR?

**No, on the published terms.** The gate is stated three times, and each
statement is an obstacle:

> Eligible customers may have their customer content excluded from these
> abuse monitoring logs, subject to the limitations below, by getting
> approved for the Zero Data Retention or Modified Abuse Monitoring
> controls. **Currently, these controls are subject to prior approval by
> OpenAI and acceptance of additional requirements.**

> Get in touch with our sales team to learn more about these offerings and
> inquire about eligibility.

And from the marketing page: *"We offer data retention controls for
**qualifying organizations** … Qualifying organizations are able to
configure how long OpenAI retains business data, including opting for our
zero data retention policy in the API platform."*

Three separate barriers: **eligibility** (undefined, and OpenAI publishes no
criteria), **prior approval**, and **acceptance of additional requirements**
(an unnamed further agreement). The route is a sales conversation, and the
noun used is *organizations*. There is also a duty attached — approved
customers are *"responsible for ensuring their users abide by OpenAI's
policies … and complying with any moderation and reporting requirements
under applicable law"* — which is a compliance obligation a hobbyist has no
apparatus to discharge.

**Consequence for the app.** Any disclosure string must describe the
default. Wording like "you can request zero data retention" would be
technically true and practically false, and it is exactly the kind of
generalising-from-the-stronger-case the project's README exists to avoid.

**Two further retentions that apply to the default user specifically.**

- *"When Zero Data Retention is not enabled for an organization, all queries
  use extended prompt caching for all supported models."* Prompt caching
  *"may store encrypted key/value tensors in GPU-local storage as
  application state … not retained after the 24-hour expiration."* So a
  non-ZDR user — every user of this app — gets a 24-hour encrypted
  derivative of their request on a GPU host. It is not the image, and it is
  encrypted, but it is not nothing, and it is a consequence of *not* having
  the control they cannot obtain.
- The 30-day window has the *"reasonably necessary to protect our services
  or any third party from harm"* extension, which is open-ended.

## C. Images: the sentence that does not exist

**This is the ticket's central question, and the answer is decisive.**

### The absence, established by search

The string `ephemeral` occurs **exactly once** on the data-controls page.
Its context, in full:

> Hosted containers used by Hosted Shell and Code Interpreter may write
> temporary application state to the container filesystem (backed by
> ephemeral block storage) while the container is active.

That is about Code Interpreter disk, not image inputs. **OpenAI uses the
word, but never about images.** The images-and-vision guide contains no
retention or training statement of any kind — it is entirely about formats,
tokens, sizing and cost. The Service terms contain no retention provision.
There is nowhere else for such a sentence to live.

### The image-specific sentence that does exist

There is exactly one, and it is not reassuring:

> Images and files may be uploaded as inputs to `/v1/responses` (including
> when using the Computer Use tool), `/v1/chat/completions`, and
> `/v1/images`. **Image and file inputs are scanned for CSAM content upon
> submission. If the classifier detects potential CSAM content, the image
> will be retained for manual review, even if Zero Data Retention, Modified
> Abuse Monitoring, or Eyes Off is enabled.**

And images are singled out again, as the one exception to the strongest
control OpenAI sells: *"Modified Abuse Monitoring excludes customer content
**(other than image and file inputs in rare cases, as described below)**
from abuse monitoring logs across all API endpoints."*

**Every image is scanned. A false positive is retained for human review, and
no retention control prevents it.** The scanning is unobjectionable and the
carve-out is one almost nobody would argue against — but the README's claim
is falsifiable, and "the image is retained only for the request" would be
false on this path.

### Side by side

| | Anthropic (vision docs) | OpenAI |
| --- | --- | --- |
| Image retention | *"ephemeral and not stored beyond the duration of the API request"* | up to **30 days** in abuse-monitoring logs |
| After processing | *"automatically deleted after they have been processed"* | removed after 30 days, subject to two exceptions |
| Training on images | *"Anthropic does not use uploaded images to train models"* | not used for training (parity) |
| Image-specific carve-out | none | CSAM classifier hit → **retained for manual review**, survives ZDR |
| Human review | not contemplated in the vision docs | *"specialized third-party contractors … solely to review for abuse and misuse"* |

Anthropic's text, verified on the live page, is a FAQ answer:

> **Can I delete images I've uploaded?** No. Image uploads are ephemeral and
> not stored beyond the duration of the API request. Uploaded images are
> automatically deleted after they have been processed.

**Note what that is.** It is an FAQ entry in a documentation page, not a
contractual term — the same evidentiary weight as OpenAI's data-controls
guide, and the README should not imply otherwise. The two vendors are
promising different things at the *same* level of formality. The difference
is in the substance, not the standing.

### Formats and limits — WebP is fine

Verified verbatim from the images-and-vision guide:

> **Supported file types**
> PNG (.png) - JPEG (.jpeg and .jpg) - WEBP (.webp) - Non-animated GIF (.gif)
>
> **Size limits**
> Up to 512 MB total payload size per request - Up to 1500 individual image
> inputs per request
>
> **Other requirements**
> No watermarks or logos - No NSFW content - Clear enough for a human to
> understand

**WebP is accepted with no qualification, so no transcode is needed.** The
app's `_mediaTypes` set is exactly OpenAI's accepted set. Its 3 MB cap is
three orders of magnitude inside the 512 MB payload limit.

Three notes:

- **There is no global pixel-dimension cap**, only per-model patch budgets.
  At 1024×1024 the patch count is `32 × 32 = 1024`, inside the 1,536-patch
  budget of the mini and nano models, so **no server-side resize happens** —
  the app's 1024 px choice lands well.
- **Animated GIF is excluded.** The encoder's fallback path can emit
  `image/gif` verbatim from a source file, so an animated GIF chosen from
  the picker would be rejected. A narrow edge case; worth a guard.
- ***"No watermarks or logos"* is stated as an input requirement**, and a
  photo of packaged food routinely contains a brand logo. Read in context
  the list is aimed at image-*generation* fidelity, and I found no
  enforcement of it against vision inputs — but it is phrased as a
  requirement for *"Input images … to be used in the API"*, and I cannot
  show it does not apply. **Unresolved; recorded because it is the kind of
  line that surfaces later.**

## D. Identity: the field is optional, and that is verified

**Confirmed on both the guidance page and the API reference.** From
[Safety best practices](https://developers.openai.com/api/docs/guides/safety-best-practices):

> Safety identifiers are recommended for products where individual users
> interact with a model, but **they are not required**. Include safety
> identifiers in your API requests with the `safety_identifier` parameter

And OpenAI's own advice is to avoid sending anything identifying even when
you do use it: *"A safety identifier should be a string that uniquely
identifies each user. Hash the username or email address in order to avoid
sending us any identifying information."*

From the chat-completions reference, read field by field:

- **`safety_identifier: optional string or null`** — *"A stable identifier
  used to help detect users of your application that may be violating
  OpenAI's usage policies. The IDs should be a string that uniquely
  identifies each user, with a maximum length of 64 characters. We recommend
  hashing their username or email address, in order to avoid sending us any
  identifying information."*
- **`prompt_cache_key: optional string or null`** — *"Used by OpenAI to
  cache responses for similar requests to optimize your cache hit rates.
  **Replaces the user field.**"*
- **`user`** is marked **Deprecated**: *"This field is being replaced by
  `safety_identifier` and `prompt_cache_key`. Use `prompt_cache_key` instead
  to maintain caching optimizations."*

**So the ticket's question is answered, with a correction: the field is no
longer `user`.** It has been split in two, and both halves are optional.

**What omitting them costs.** Nothing in policy terms — no documented
penalty, no rate-limit consequence, no degraded eligibility; I searched the
reference and the safety guide for any. The only stated cost is technical
and it is a *benefit* here: `prompt_cache_key` exists to *"boost cache hit
rates by better bucketing similar requests"*, so omitting it means requests
are not bucketed together. A privacy-preserving app wants exactly that.

**This is the one place the direct path is unambiguously better than
OpenRouter.** There, an account-level identity is forwarded upstream and
cannot be suppressed. Here the app simply omits both fields and OpenAI
receives no application-level identifier at all. The account behind the key
is still known to OpenAI as the billing customer — that is unavoidable on
any BYO-key path and the README should not imply otherwise — but nothing
the *app* adds distinguishes one user from another.

## E. Service terms §6, in full

The ticket's appended question. Quoted complete, from the live page
(Updated: June 12, 2026). Note the heading is **"Image and Video
Capabilities"**, not "Visual Capabilities":

> **6. Image and Video Capabilities**
>
> Our models can accept images and videos as part of Inputs to the Services
> ("Visual Capabilities"). You may not use Visual Capabilities to assist in
> identifying a person nor to solicit or infer private or sensitive
> information about a person. You may not use Visual Capabilities to
> reproduce the likeness of any person without express consent and all
> necessary rights. By choosing to share an image or video publicly on the
> Services, such as by sharing it to the Sora feed or uploading it to create
> a Sora cameo, you represent you have all necessary rights, and you give
> OpenAI the right to reproduce, distribute, modify, display and perform it
> for the purpose of operating and promoting the Services. You also agree to
> give users the limited right to reproduce and remix that content solely on
> the Services. Uploading a cameo or sharing an image or video does not give
> other users any rights to use those materials outside of the Services.

[`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) §E quoted only the
second sentence. Seeing the whole clause changes the reading in the app's
favour.

**1. The clause is a use restriction, and "use … to" is the operative
construction.** All three prohibitions are transitive: *use Visual
Capabilities **to** assist in identifying*, *to solicit or infer*, *to
reproduce the likeness*. Each requires the capability to be aimed at a
person. The photo prompt asks which foods are visible and forbids
estimating weight or volume. Nothing is aimed at a person, and the output
schema — `query`, `quantity`, `unit`, `additionalProperties: false` — has
no field in which an inference about a person could be returned. **A model
cannot infer private information about a person into a slot that does not
exist.** That is the same structural argument that carried B1 in
[`ai-openai-policy-fit.md`](ai-openai-policy-fit.md), and it is stronger
here because it is about output shape rather than intent.

**2. The rest of the clause is about Sora and public sharing**, which the
API path never touches. Reading sentences two and three next to sentences
four through six makes clear the section governs consumer image/video
features primarily; the API is reached only by the first three sentences.

**3. Incidental faces do not engage it.** The prohibition is on *using* the
capability to identify. A face appearing in the frame is not a use. If
incidental presence were enough, the clause would prohibit nearly all
photography, which no reading supports.

**4. Dietary information is the genuinely arguable limb, and it still
fails.** The argument would be: food intake is health-adjacent, health data
is "private or sensitive", the photo is of an identifiable person's meal,
therefore the app infers sensitive information about a person. It fails on
two independent grounds. The inference is about *the plate*, not the
person — the output is a food list, and attributing that food to a person
is done by the user's own diary on their own device, not by OpenAI's model.
And *"solicit or infer … about a person"* requires a person as the object
of the inference; there is no person-referent anywhere in the request. The
app does not even tell the model whose meal it is, because it sends no
identifier at all ([Section D](#d-identity-the-field-is-optional-and-that-is-verified)).

**5. The consistency argument from #679 is available here — unlike in
[`ai-openai-key-transfer.md`](ai-openai-key-transfer.md).** Anthropic's
Usage Policy (effective 15 September 2025), under *Do Not Compromise
Privacy or Identity Rights*, prohibits:

> Misuse, collect, solicit, or gain access without permission to private
> information such as non-public contact details, health data, biometric or
> neural data (including facial recognition), or confidential or proprietary
> data

and under the surveillance heading:

> Target or track a person's physical location, emotional state, or
> communication without their consent, including using our products for
> facial recognition, battlefield management applications or predictive
> policing

**Anthropic names *health data* explicitly, where OpenAI says only "private
or sensitive information".** If dietary intake is health data, Anthropic's
clause reaches it more clearly than OpenAI's does — and the project shipped
on Anthropic having reviewed that policy. Anthropic's vision documentation
adds a model-level restriction with no OpenAI equivalent: *"People
identification: Claude cannot be used to name people in images and refuses
to do so."* So on this axis OpenAI is **not** the stricter vendor, and §6
cannot be what separates them. This is the move that resolved #679, and it
works here.

**Verdict on §6: not engaged, on the better reading, and more comfortably
than [`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) §E suggested.**

### What the disclosure would have to say

§6 is a restriction on the *user's* conduct (the Customer, under BYO-key).
It is not engaged by the app's designed behaviour, but the app hands the
user a camera, and the user could point it at anything. The honest
disclosure obligation is therefore small but real:

- **Say the photo goes to OpenAI and is not merely read on-device.** The
  existing photo-path copy already does this for Anthropic.
- **Say the photo is retained for up to 30 days**, not "sent for that one
  request". The current README sentence — *"sent for that one request, and
  then unreachable"* — is true of the *app's* copy but would read as a
  claim about the provider, and on an OpenAI path it would be false.
- **Do not claim a §6 permission.** The app should not tell the user the
  clause is satisfied; it should avoid a feature that would engage it. It
  already does — no face detection, no person-attribute output, no schema
  field for either.
- **A note that photos of other people are the user's responsibility** is
  proportionate, because §6 binds the key holder and not the project
  ([`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) §A).

## F. Region and sub-processors: the fourth destination

**This is the finding with the largest effect on the README's structure.**
The [Sub-processor list](https://openai.com/policies/sub-processor-list/)
(last updated 9 July 2026) names, for the **API** specifically:

| Entity | Purpose | Location of processing |
| --- | --- | --- |
| **Cloudflare, Ltd.** | Content delivery network provider; Web Hosting | *"Processing is performed at the data center that is closest to the End User"* |
| Microsoft Corporation | Cloud infrastructure | 23 countries |
| CoreWeave, Oracle Cloud, Google Cloud Platform, Amazon Web Services, Cerebras | Cloud infrastructure | Norway, Spain, Sweden, UK, US, Brazil, Japan, Malaysia, Netherlands, Finland, Canada |
| **TaskUs, LLC** | Customer support; **Moderation of content** | **Philippines** |
| **Accenture International Limited** | Customer support; **Moderation of content** | US, Canada, **Philippines** |
| Cinder Technologies | Platform for content moderation | US *(except where ZDR is used)* |
| Snowflake, Confluent | Data warehousing; infrastructure management | US *(except where ZDR is used)* |
| Intercom, Salesforce, Pylon Labs, Okta (via Auth0) | Customer support; authentication | US and others |

**Cloudflare terminates TLS.** The data-controls page states it for the
residency endpoints — *"For requests sent to `us.api.openai.com` or
`eu.api.openai.com`, OpenAI uses Cloudflare Regional Services so that TLS
termination and HTTPS decryption occur within the selected processing
region"* — and the sub-processor list shows Cloudflare serving the API
generally. **A request to OpenAI is decrypted by a CDN before OpenAI
processes it.** The README's per-destination table describes the Anthropic
path as one hop and the OpenRouter path as two; an OpenAI path is one hop
plus a named CDN sub-processor, and saying so is the honest version.

**Flagged content reaches moderation vendors.** From the same page:

> **Moderation:** For content that OpenAI's models flag as being in
> violation of OpenAI's policies, OpenAI may share samples of the flagged
> Customer Content with relevant Sub-processors to assist OpenAI in its
> review and enforcement. Sharing with the Sub-processor platform only
> occurs when content is flagged, the Sub-processor platform only retains
> samples of content for the period of review, and OpenAI's Sub-processors
> only process the content to assist OpenAI in its review.

That is the concrete form of the enterprise page's *"specialized
third-party contractors"*. It is conditional on a flag, time-limited, and
purpose-limited — but the destinations are named and one of them is in a
different jurisdiction from OpenAI. **Note that TaskUs and Accenture do
*not* carry the "except where ZDR is used" asterisk** that Cinder,
Snowflake and Confluent do. I would not over-read a footnote marker, but it
is not obviously the case that ZDR removes the moderation path, and ZDR is
unavailable to this app's users anyway.

**Data residency is also out of reach, and its absence has a cost.**
Residency is *"a project configuration option"* requiring a sales
conversation (*"Contact our sales team to see if you're eligible"*), carries
*"a 10% uplift"*, and every non-US region *"requires approval for abuse
monitoring controls, and execut[ing] a Modified Retention amendment"*.
Image support outside the US is stricter still: *"Image support in these
regions requires approval for enhanced Zero Data Retention or enhanced
Modified Abuse Monitoring."*

**So a hobbyist's request goes to the default `api.openai.com` endpoint with
no region selected.** OpenAI does not publish where those are served from,
and the sub-processor list shows API cloud infrastructure across roughly
twenty-five countries. **The README cannot state a processing region for an
OpenAI path**, and should not imply one.

## What the README would have to change

Stated plainly, because the point of the exercise is a falsifiable claim:

1. **The ephemerality sentence cannot be reused or adapted.** It is
   Anthropic's, it is already marked as not travelling to OpenRouter, and
   OpenAI has no counterpart. The README would need a new sentence quoting
   the 30-day text with its full qualifier.
2. **The destination table needs a sub-processor note**, at minimum naming
   Cloudflare as terminating TLS and noting that flagged content may reach
   moderation vendors abroad.
3. **The photo paragraph's "sent for that one request, and then
   unreachable" needs scoping** to the app's own copy, since on an OpenAI
   path the provider's copy persists up to 30 days.
4. **The identity paragraph gains a favourable line**: unlike OpenRouter,
   the direct OpenAI path forwards no application-level identifier, because
   `safety_identifier` and `prompt_cache_key` are both optional and the app
   would send neither.
5. **Nothing may reference ZDR or data residency** as available.

## Not established

- **Whether any individual has ever obtained ZDR without an enterprise
  relationship.** OpenAI publishes no eligibility criteria, no application
  form, and no self-serve path — only *"get in touch with our sales team"*.
  The finding here is that the published route is closed to a hobbyist, not
  that approval is impossible. Community reports exist and are not evidence;
  none is cited.
- **Which region serves a default `api.openai.com` request.** Not published.
  The sub-processor list gives per-vendor country lists, not a default
  routing rule, and the residency documentation describes only the opt-in
  configuration. **"US by default" is a common assumption and I found no
  primary source stating it.**
- **Whether Cloudflare sits in front of every API request or only the
  residency endpoints.** The Cloudflare row in the sub-processor list is
  scoped to "API" without qualification, which suggests all requests; the
  TLS-termination sentence in the docs is scoped to `us.`/`eu.` endpoints.
  These are consistent with each other but do not settle the general case.
- **Whether *"No watermarks or logos"* is enforced against vision inputs.**
  Stated as an input requirement, plainly aimed at generation fidelity, and
  a meal photo of packaged food will often breach it on a literal reading.
  No enforcement evidence either way.
- **What retention applies to a request that errors or is rejected by a
  classifier before inference.** Not addressed anywhere I looked.
- **Whether the 30-day promise has a contractual home.** It appears in
  documentation and an FAQ. The Services Agreement was not re-read for this
  note; [`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) and
  [`ai-openai-key-transfer.md`](ai-openai-key-transfer.md) between them
  quote §§2.2, 3.1–3.3, 5.4, 8.2, 14.1, 16.10 and 17 and record no retention
  clause, but neither was searching for one. **A DPA may contain the real
  obligation; the DPA is executed per-customer via a form and I could not
  read one.**
- **The exact wording discrepancy's significance.** The docs page and the
  enterprise page state the 30-day exception differently. Which governs is
  unclear; this note recommends the broader text on conservatism grounds,
  not because it is established as controlling.
- **Anything about the `/v1/responses` "at least 30 days" upper bound.**
  "At least" has no stated ceiling. Avoided rather than resolved, by
  recommending `/v1/chat/completions`.
- **Legal advice.** One non-lawyer reading published documents on one date.
  The most load-bearing page carries no date and can change silently.

## Sources

OpenAI (`openai.com` read in a browser; the site 403s automated fetching):
[Data controls in the OpenAI platform](https://developers.openai.com/api/docs/guides/your-data) ·
[Enterprise privacy at OpenAI](https://openai.com/enterprise-privacy/) ·
[Service terms](https://openai.com/policies/service-terms/) ·
[OpenAI Sub-processor list](https://openai.com/policies/sub-processor-list/) ·
[Images and vision](https://developers.openai.com/api/docs/guides/images-vision) ·
[Safety best practices](https://developers.openai.com/api/docs/guides/safety-best-practices) ·
[Create chat completion](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create) ·
[Business data privacy, security, and compliance](https://openai.com/business-data/) ·
[Trust Portal](https://trust.openai.com/)

Comparison documents:
[Anthropic Vision documentation](https://platform.claude.com/docs/en/build-with-claude/vision) ·
[Anthropic Usage Policy](https://www.anthropic.com/legal/aup)

Related notes in this repo:
[`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) ·
[`ai-openai-key-transfer.md`](ai-openai-key-transfer.md) ·
[`ai-model-candidates.md`](ai-model-candidates.md) ·
[`ai-legal-constraints.md`](ai-legal-constraints.md) ·
[`ai-open-research-questions.md`](ai-open-research-questions.md)

In-repo files cited:
[`lib/features/add_meal/util/meal_photo_encoder.dart`](../lib/features/add_meal/util/meal_photo_encoder.dart) ·
[`lib/features/add_meal/domain/meal_items_api.dart`](../lib/features/add_meal/domain/meal_items_api.dart) ·
[`lib/features/add_meal/data/model_meal_photo_interpreter.dart`](../lib/features/add_meal/data/model_meal_photo_interpreter.dart)
