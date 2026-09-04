# Does anyone read my food photo, and who?

**Verdict: all three providers disclose that a human can end up reading
API content, none of them reviews everything, and only OpenAI names the
companies whose staff do it.** Anthropic and OpenRouter both publish
sub-processor lists, and on both lists **no content-review vendor appears
at all** — that is an established finding, not an absence I failed to
check. The reviewer on the Anthropic path is Anthropic's own staff; the
reviewer on the OpenRouter path is whoever the serving vendor's is, which
under the app's pin is Anthropic again; the reviewers on an OpenAI path
include **TaskUs and Accenture**, named, with the Philippines among their
stated locations. So the row [#696](https://github.com/simonoppowa/OpenNutriTracker/issues/696)
asked for can be written for all three, and the honest shape of it is
*"named vendors / none named / none named"*, not *"named vendors / blank
/ blank"*. This is a documents review, not legal advice.

## The row the README has to be able to write

Every cell below is from a page quoted later in this note and read on
2026-08-17.

| | **Anthropic (direct)** | **OpenRouter (broker)** | **OpenAI** |
| --- | --- | --- | --- |
| **Human review of API content disclosed?** | **Yes** — *"Human review can occur only through a controlled access path"* | **No statement either way.** A right to *"screen"* Inputs is reserved in the Terms; no page says whether a person or a machine does it | **Yes**, and the phrase *"human review"* is OpenAI's own |
| **Trigger** | Content flagged by *"automated trust and safety systems"* | Unstated. Automated categorisation of a **sample** of prompts is disclosed, and it is done *"by model"* | Classifier flag for the vendor path; stored abuse-monitoring logs are reachable by staff more broadly |
| **Who reviews** | *"a small set of approved reviewers"* — Anthropic's own Safeguards / Trust & Safety staff | Not stated. Access limited to *"personnel performing the Service"* | (1) *"authorized employees"* and (2) *"specialized third-party contractors"* |
| **Vendors named?** | **No, and none exists on the list.** The only human-touching sub-processors are user support: Intercom (US), Nutun (South Africa), Boldr (Canada) | **No, and none exists on the list.** Nearest is Google Cloud Natural Language API for *"NLP Categorization"* — a machine | **Yes. TaskUs, LLC (Philippines) and Accenture International Limited (US, Canada, Philippines)**, both purpose *"Moderation of content"* for the API |
| **Images vs text** | Every image is perceptually hashed against NCMEC's CSAM database; a match is reported. No image-specific review carve-out beyond that | The **only** image-specific sentence anywhere: files are not persisted *"except as required for abuse detection, security, billing, or legal compliance"* | Every image is CSAM-scanned on submission; a hit is *"retained for manual review"* **even under every retention control OpenAI sells** |
| **Avoidable by a solo BYO-key developer?** | **No.** Flag-triggered retention and review survive ZDR, and ZDR itself is a sales conversation | **Nothing to avoid, and nothing to opt out of.** The layer below is the serving vendor's answer | **No.** The exemption is called Eyes Off and it presupposes ZDR/MAM approval — and it does not cover images |
| **Sub-processor list** | [trust.anthropic.com/subprocessors](https://trust.anthropic.com/subprocessors) | [openrouter.ai/authorized-sub-processors](https://openrouter.ai/authorized-sub-processors) | [openai.com/policies/sub-processor-list](https://openai.com/policies/sub-processor-list/) |

**Read the "vendors named" row carefully, because it is the one that can
mislead.** OpenAI naming two BPOs is *better disclosure*, not worse
practice. Anthropic and OpenRouter publish lists on which no such vendor
appears; that is evidence they do not use one for this, not evidence they
declined to say. The README should say what each provider publishes, and
should not let OpenAI's specificity read as a black mark.

## Bottom line up front

1. **All three sub-processor lists exist and are citable.** The
   README's class sentence has three places to point, and #696's
   requirement that the row ship for all three or none is satisfiable.
   See [Section E](#e-the-three-sub-processor-lists).
2. **TaskUs and Accenture check out, with one correction.** Both carry
   the purpose *"Moderation of content"* scoped to *"API & ChatGPT
   Business"* on OpenAI's own list (last updated 9 July 2026). **TaskUs
   is Philippines-only; Accenture is United States, Canada and the
   Philippines.** *"TaskUs and Accenture, in the Philippines"* is right
   about TaskUs and incomplete about Accenture. See
   [Section D](#d-openai-the-only-provider-that-names-names).
3. **Anthropic's human-review sentence is real but narrowly scoped, and
   the scope matters to this app.** The sentence *"By default, no
   Anthropic personnel can read your retained conversations"* sits in an
   article about **Covered Models** — currently only Claude Mythos 5 and
   Claude Fable 5. The app uses `claude-haiku-4-5` and
   `anthropic/claude-sonnet-5`, neither of which is a Covered Model. The
   description is the best statement Anthropic publishes and it is
   plainly meant to describe how review works generally, but **it is not
   formally scoped to the traffic this app sends.** See
   [Section B](#b-anthropic-review-is-internal-and-nobody-else-is-named).
4. **OpenRouter genuinely publishes nothing about human review of
   content, and that is the finding.** Not "we could not find it" —
   the Terms reserve a right to *"screen"* Inputs *"in our sole
   judgment"* without saying by whom or when, the Privacy Policy has no
   review clause, and the sub-processor list has no reviewer on it. The
   README must state this as an absence of disclosure, not as an
   assurance. See [Section C](#c-openrouter-two-layers-and-only-one-of-them-is-openrouters).
5. **The "ephemeral" sentence the README quotes has a companion Anthropic
   does not put next to it.** Vision docs: image uploads are
   *"ephemeral and not stored beyond the duration of the API request"*.
   API retention docs: *"if a chat or session is flagged, Anthropic may
   retain inputs and outputs for up to 2 years."* Both are Anthropic's,
   both were read today, and the second is the exception to the first.
   **A flagged meal photo is not ephemeral.** See
   [Section F](#f-images-versus-text).
6. **On images, OpenAI is the only provider whose review path survives
   every control it sells.** The CSAM carve-out is one nobody would
   argue against, but it is the single hardest fact in this note: a
   false positive on a photograph of dinner ends in a person looking at
   it, and no setting, tier or contract prevents that.
7. **Nothing here is avoidable by the app's user on any path.** Review
   is triggered by classifiers, not by settings, and every exemption on
   offer runs through a sales team. See
   [Section G](#g-is-review-avoidable).

## How this was read

Primary sources only, all read on **2026-08-17**. Every quote below was
verified against the page itself, not against a search summary — I fetched
each document, extracted its text, and string-searched the extracted text
for the quoted words. Where the finding is an *absence*, the search term
is stated so the check is repeatable.

Two mechanical notes, because they changed the result:

- **`openai.com` returns HTTP 403 to automated fetching**, as
  [`ai-openai-key-transfer.md`](ai-openai-key-transfer.md) recorded. Both
  `openai.com` pages here were read in a browser against the live
  rendering. `developers.openai.com`, `anthropic.com`,
  `platform.claude.com`, `privacy.claude.com`, `support.claude.com` and
  `openrouter.ai` all answer automated fetches and render server-side.
- **`trust.anthropic.com` and `trust.openrouter.ai` are JavaScript
  applications** (Vanta and SafeBase respectively) that return an empty
  shell to a plain fetch. Both sub-processor lists were read in a browser
  from the rendered DOM. A plain `curl` of
  `trust.anthropic.com/subprocessors` returns 4.9 KB of scaffolding and
  **zero vendor names** — anyone repeating this check with a fetch tool
  will conclude the list is empty. It is not.

**Three search summaries produced during this work were discarded rather
than cited.** One asserted that Anthropic's Trust & Safety access
sentence applies to the API; the page carrying it says *"This article is
about our consumer products such as Claude Free, Pro, Max"* in its first
line. One asserted OpenRouter "doesn't filter content itself, but routes
to providers that enforce their own policies" — a reasonable-sounding
claim that appears on no OpenRouter page I could find, and which would
have resolved question 1 for OpenRouter by invention. One reported that
OpenRouter has no sub-processor list, which is what I had provisionally
concluded myself after guessing four wrong URL slugs; the list exists at
`/authorized-sub-processors` and finding it changed the answer.

**One near-miss worth recording as a trap for the next reader.** Both
Anthropic's Commercial Terms and OpenRouter's Terms contain the exact
phrase *"human review"* — and in both it means the **customer's** duty to
check outputs before relying on them, the opposite of what this ticket
asks. Anthropic: *"It is Customer's responsibility to evaluate whether
Outputs are appropriate for Customer's use case, including where human
review is appropriate."* OpenRouter, in capitals: *"YOU ARE SOLELY
RESPONSIBLE FOR EVALUATING OUTPUTS, IMPLEMENTING APPROPRIATE HUMAN REVIEW
AND SAFEGUARDS."* A keyword search for "human review" finds these first
on both sites.

| Document | Date it carries |
| --- | --- |
| [Anthropic Privacy Policy](https://www.anthropic.com/legal/privacy) | Effective **July 8, 2026** |
| [Anthropic Commercial Terms of Service](https://www.anthropic.com/legal/commercial-terms) | Effective **June 17, 2025** |
| [Anthropic Data Processing Addendum](https://www.anthropic.com/legal/data-processing-addendum) | Effective **February 24, 2025** |
| [Anthropic Usage Policy](https://www.anthropic.com/legal/aup) | Effective **September 15, 2025** |
| [API and data retention](https://platform.claude.com/docs/en/manage-claude/api-and-data-retention) | no date carried |
| [How long do you store my organization's data?](https://privacy.claude.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data) | **July 1, 2026** |
| [Data retention practices for Covered Models](https://privacy.claude.com/en/articles/15425996-data-retention-practices-for-covered-models) | **July 9, 2026** |
| [Covered Models](https://support.claude.com/en/articles/15425695) | **July 1, 2026** |
| [Our Approach to User Safety](https://support.claude.com/en/articles/8106465-our-approach-to-user-safety) | **March 16, 2026** |
| [CSAM Detection and Reporting](https://support.claude.com/en/articles/9020328-csam-detection-and-reporting) | **March 16, 2026** |
| [Safeguards warnings and appeals](https://support.claude.com/en/articles/8241253-safeguards-warnings-and-appeals) | **July 9, 2026** |
| [How does Anthropic protect the personal data of Claude users?](https://privacy.claude.com/en/articles/10458704-how-does-anthropic-protect-the-personal-data-of-claude-users) | **March 16, 2026** — *consumer only* |
| [Anthropic's Transparency Hub](https://www.anthropic.com/transparency/system-trust-reporting) | Last updated **July 23, 2026** |
| [Anthropic Subprocessor List](https://trust.anthropic.com/subprocessors) | **no date carried** |
| [Anthropic Vision documentation](https://platform.claude.com/docs/en/build-with-claude/vision) | no date carried |
| [OpenRouter Privacy Policy](https://openrouter.ai/privacy) | Last Updated **July 6, 2026** |
| [OpenRouter Terms of Service](https://openrouter.ai/terms) | Last Updated **July 29, 2026** |
| [OpenRouter Enterprise Access Agreement](https://openrouter.ai/terms-of-service-enterprise) | Last Updated **June 22, 2026** |
| [OpenRouter Authorized Sub-Processors](https://openrouter.ai/authorized-sub-processors) | Last Updated **January 9, 2026** |
| [OpenRouter Data Collection](https://openrouter.ai/docs/guides/privacy/data-collection) | no date carried |
| [OpenRouter Trust Center](https://trust.openrouter.ai/) | **no date carried** |
| [OpenAI Sub-processor list](https://openai.com/policies/sub-processor-list/) | Last updated **July 9, 2026** |
| [Enterprise privacy at OpenAI](https://openai.com/enterprise-privacy/) | Updated **January 8, 2026** |
| [Data controls in the OpenAI platform](https://developers.openai.com/api/docs/guides/your-data) | no date carried |

**Note the weight of the evidence, again.** The two sub-processor lists
that a README would cite for Anthropic and OpenAI carry dates. **The
Anthropic one does not** — the Vanta-hosted page has no last-updated
marker anywhere in its rendered text, which is worse than OpenAI's
dated list and worse than OpenRouter's dated one. And the single most
load-bearing OpenAI page, the data-controls guide, still carries no date.

### The behaviour this is read against

From [`ai_model_catalogue.dart`](../lib/core/utils/ai_model_catalogue.dart),
verified in source today:

- Direct path: `claude-haiku-4-5`, served by Anthropic.
- OpenRouter path: `anthropic/claude-sonnet-5` and
  `anthropic/claude-haiku-4.5`, both with `providers: ['anthropic']` —
  the `provider.only` pin, fallbacks off.
- One stateless request, no history, no account, no app-added identifier.
- A meal photo is WebP, longest edge 1024 px, held in memory only.

I confirmed the pin matters by listing OpenRouter's endpoints for both
models. `anthropic/claude-sonnet-5` is currently offered by nine
endpoints — Anthropic, three Amazon Bedrock regions, three Google Vertex
regions and two Azure regions. **Without the pin, eight of the nine
answers would come from a company with a different review regime and a
different sub-processor list.** The pin is what makes the second layer of
the OpenRouter answer reducible to Anthropic's.

## A. What the question actually resolves to

The three questions are not the same question and the providers answer
them at different levels:

1. **Does a person ever read it?** All three say or imply yes, under
   conditions.
2. **Whose person?** Anthropic: its own. OpenRouter: unstated, and its
   list contains nobody who could be doing it. OpenAI: its own employees
   *and* two named contractors.
3. **Under what trigger?** Every disclosed trigger across all three is
   **classifier-flag-driven**. No provider discloses review of all
   traffic, and no provider discloses random sampling of content for
   human eyes. OpenRouter samples prompts — but for categorisation, by a
   model, with ZDR.

That third answer is the reassuring one and it holds uniformly. The
README can say, of all three, that review is conditional on an automated
flag and is not routine.

## B. Anthropic: review is internal, and nobody else is named

### The disclosure exists, and here it is

From [Data retention practices for Covered Models](https://privacy.claude.com/en/articles/15425996-data-retention-practices-for-covered-models)
(9 July 2026), under the heading *"How we protect your data"*, quoted
complete because the qualifiers are the substance:

> By default, no Anthropic personnel can read your retained
> conversations. Human review can occur only through a controlled access
> path—for example, when content is flagged by our automated trust and
> safety systems for potential harm. These reviews can only be performed
> by a small set of approved reviewers. Every instance of access is
> recorded in a tamper-proof log that reviewers cannot suppress or
> modify. After 30 days, the data is deleted automatically, except in the
> rare cases where it's been flagged by our automated trust and safety
> systems or we're legally required to keep it.

That is the clearest human-review statement any of the three providers
publishes. **It is also the one with the most awkward scope.** The same
article says, twice:

> This change only applies to organizations that have set up workspaces
> with zero data retention (ZDR) in Claude Console, use Claude Code with
> ZDR in Claude Enterprise, or access Claude through AWS Bedrock, Google
> Cloud Agent Platform, or Microsoft Foundry with ZDR. The rest of this
> article applies only to these organizations.

And the [Covered Models](https://support.claude.com/en/articles/15425695)
page (1 July 2026) names the models: *"Claude Mythos 5"* and *"Claude
Fable 5"*, and adds — this is the sentence that fences it —

> Note: These policies apply only to the models listed on this page. All
> other Claude models continue to operate under your existing agreement
> and configured retention settings.

**The app uses neither Covered Model.** So the best sentence Anthropic
publishes about who may read content is formally addressed to traffic the
app does not send. I do not think Anthropic operates two different
reviewer pools, and the sentence reads as a description of how access
control works generally. But **the README cannot quote it as a statement
about this app's requests** without misrepresenting its scope, and this
note will not pretend otherwise.

The Covered Models page also carries the default, which *is* general in
tone: *"Automated review by default. Retained data is assessed by
automated safety systems designed to flag harmful content."*

### What is scoped to ordinary API traffic

From [How long do you store my organization's data?](https://privacy.claude.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data)
(1 July 2026), which *is* the commercial/API article:

> For Anthropic API users, we automatically delete inputs and outputs on
> our backend within 30 days of receipt or generation, except: … If we
> need to retain them for longer to enforce our Usage Policy (UP)

> We retain inputs and outputs for up to 2 years and trust and safety
> classification scores for up to 7 years if your chat is flagged by our
> automated trust and safety systems as violating our Usage Policy.

And the [API and data retention](https://platform.claude.com/docs/en/manage-claude/api-and-data-retention)
docs page, under *"Retention regardless of arrangement"*:

> Even with ZDR or HIPAA arrangements in place, Anthropic may retain data
> where required by law or where it has been flagged by Anthropic's
> automated trust and safety systems. As a result, if a chat or session
> is flagged, Anthropic may retain inputs and outputs for up to 2 years.

**Two years is a longer retention than either other provider's default
and it is the tail that matters.** OpenAI's flagged-content window is the
30-day abuse-monitoring log plus *"reasonably necessary … from harm"*;
Anthropic's is a stated two years with a stated seven-year tail on the
classification scores. Neither of these sentences says a human reads the
retained material. The purpose stated — *"to enforce our Usage Policy"* —
does not happen without one.

### Who, by name

**Nobody, and that is established rather than assumed.** I read the whole
of [trust.anthropic.com/subprocessors](https://trust.anthropic.com/subprocessors)
from the rendered DOM. It lists **twenty** entities. The complete set that
could conceivably involve a person reading customer content:

| Entity | Purpose as stated | Location | Products |
| --- | --- | --- | --- |
| Intercom | User support | United States | All Products except Claude for Government |
| Nutun | User support | South Africa | All Products except Claude for Government |
| Boldr | User support | Canada | All Products except Claude for Government |
| Sift | Fraud and abuse detection | United States | All products except Claude for Government |
| Arkose Labs | Fraud and abuse detection | United States | All products except Claude for Government |
| Persona | Fraud and abuse detection, identity verification | United States | Claude Free/Pro/Max |
| Yoti | Fraud and abuse detection, identity verification | United Kingdom | Claude Free/Pro/Max |

The remaining thirteen are Google Cloud Platform, Amazon Web Services,
Microsoft Azure, Cloudflare (*"Traffic Routing (CDN)"*, *"Worldwide (Local
to Customer)"*), Stripe, WorkOS, Twilio, Iterable, Sentry, Brave Search,
ElevenLabs, TurboPuffer and Palantir Federal Cloud Service.

**There is no "Moderation of content" row and no BPO with a content
purpose.** The search terms that return nothing on the rendered page are
`moderation`, `moderate`, `review`, `TaskUs`, `Accenture` and
`Teleperformance`. Nutun and Boldr are business-process outsourcers of
the same general kind OpenAI uses — but their stated purpose is *"User
support"*, and Persona and Yoti are scoped to consumer plans, which the
app never touches.

**Two consequences for the README.** Anthropic's answer to *"who reads
it"* is *"Anthropic"* — so the destination table's existing single-hop row
for the Anthropic path stays accurate, with the addition of a named
CDN sub-processor (Cloudflare) that the README already has to think about
for the same reason it does on the OpenAI path. And a reader who wants
the list has one link, [Schedule 4 of the DPA](https://www.anthropic.com/legal/data-processing-addendum)
saying so in as many words: *"Anthropic's list of subprocessors is
available at https://www.anthropic.com/subprocessors"* — which 302s to
the Trust Center page.

### The internal team is named, even though the vendors are not

Anthropic names its own reviewers to the extent of naming the team. The
[Usage Policy](https://www.anthropic.com/legal/aup) (effective 15
September 2025):

> Anthropic's Safeguards Team will implement detection and monitoring to
> enforce our Usage Policy, so please review this policy carefully before
> using our products or services.

The [Transparency Hub](https://www.anthropic.com/transparency/system-trust-reporting)
(last updated 23 July 2026) repeats it and puts numbers beside it:
*"Anthropic's Safeguards Team designs and implements detections and
monitoring to enforce our Usage Policy"*, with **11.4 million banned
accounts**, **398k appeals** and **42k appeal overturns** for January–June
2026. Forty-two thousand overturned bans is not a number a purely
automated pipeline produces; somebody looked. And
[Safeguards warnings and appeals](https://support.claude.com/en/articles/8241253-safeguards-warnings-and-appeals)
(9 July 2026) says so directly: *"Our Safeguards team can further
investigate why your account was disabled."* That is a person, at
Anthropic, and the trigger is the user's own appeal.

**What describes only the consumer products, and must not be reused.**
[How does Anthropic protect the personal data of Claude users?](https://privacy.claude.com/en/articles/10458704-how-does-anthropic-protect-the-personal-data-of-claude-users)
(16 March 2026) opens *"This article is about our consumer products such
as Claude Free, Pro, Max"*, then says:

> By default, Anthropic employees cannot access your conversations
> unless: You explicitly consent to share your data with us as a part of
> giving us feedback… Review is needed to enforce our Usage Policy. In
> such cases, your conversation data is protected through strict access
> controls– only designated members of our Trust & Safety team may access
> this data on a need-to-know basis as a part of their evaluation
> process.

It is the most quotable sentence on the site and **it is about a product
this app does not use.** The Privacy Policy is fenced the same way:
*"This Privacy Policy does not apply to content that we process on behalf
of customers of our business offerings."*

## C. OpenRouter: two layers, and only one of them is OpenRouter's

The ticket asks for these to be separated. They separate cleanly, and the
answer is different at each layer.

### Layer 1 — what OpenRouter itself does

**OpenRouter publishes no statement, in either direction, about human
review of routed content.** Established by reading the Privacy Policy (6
July 2026), the Terms (29 July 2026), the Enterprise Access Agreement,
the Data Collection docs page and the Provider Logging docs page end to
end. The strings `human review` (other than the customer-duty capital
letters), `manual review`, `moderation` and `moderator` return nothing
about OpenRouter's own staff reading prompts. `subprocessor` and
`sub-processor` appear **zero times** in the Privacy Policy and Terms;
they appear only in the Enterprise agreement, which points at the
separate list.

What OpenRouter *does* say:

**It does not keep content by default.** From
[Data Collection](https://openrouter.ai/docs/guides/privacy/data-collection):

> OpenRouter does not store your prompts or responses, *unless* you opt
> in to one or both of the following

— those being Input & Output Logging (*"OpenRouter does not access or use
this data"*) and OpenRouter Use of Inputs/Outputs (a 1% discount). Both
are off by default and the app enables neither.

**The one sampling disclosure is explicitly machine-only**, and it is the
closest thing on the site to a review practice:

> Anonymous Input Categorization: OpenRouter samples a small number of
> prompts for categorization to power our reporting and model ranking. If
> you are not opted in to OpenRouter use of inputs/outputs, any
> categorization of your prompts is stored completely anonymously and
> never associated with your account or user ID. **The categorization is
> done by model with a zero-data-retention policy.**

That sample can include a meal line. It is a machine, it is anonymous,
and the sub-processor list corroborates it: **Google Cloud Natural
Language API — *"NLP Categorization"* — *"API Requests/Responses"* —
USA.** A named third party does receive prompt content, and it is an API,
not a room of people.

**A right to screen is reserved without describing how it is exercised.**
Terms §6.7:

> We are under no obligation to edit or control Inputs that you or other
> users post or publish, and will not be in any way responsible or liable
> for Inputs. OpenRouter may, however, at any time and without prior
> notice, screen, remove, edit, or block any Inputs that in our sole
> judgment violates these Terms or is otherwise objectionable or illegal.

*"In our sole judgment"* is a person's judgment on its face. But the
clause is a reservation of rights, not a description of practice, and
**no OpenRouter page says whether that judgment is ever exercised, by
whom, or on what trigger.** The honest README sentence is *"OpenRouter
does not say"*, not *"OpenRouter does not review"*.

**Access is limited by contract to its own staff.** Enterprise Access
Agreement (22 June 2026), in the data-processing part, §4.3 *Limitation
of Access*: *"OpenRouter shall ensure that OpenRouter's access to
Personal Data is limited to those personnel performing the Service in
accordance with the Agreement."* §4.2 adds that OpenRouter *"shall take
commercially reasonable steps to ensure the reliability of any OpenRouter
personnel engaged in the Processing of Personal Data."* Both contemplate
people; neither says what they do.

**The sub-processor list contains no reviewer.** Twenty-four entities, last
updated 9 January 2026. The three that touch prompt content are Google
Cloud Natural Language API (*"NLP Categorization"*), **Upstash Inc.**
(*"Database"*, personal data processed: *"Prompts & Completions"*, USA)
and the catch-all row **"AI Model Providers — Large language model
providers — API Requests/Responses — Various"**. Cloudflare and Google
Cloud Platform carry *"All Customer Data"*. Customer support is Zendesk
and Answer H.Q., processing *"User Accounts, Customer Support
Interactions"* — not prompts.

**A discrepancy worth flagging.** OpenRouter maintains a *second*
sub-processor list, on its SafeBase trust centre at
[trust.openrouter.ai](https://trust.openrouter.ai/), and the two disagree.
That one has eighteen entries, names **OpenAI, Microsoft Azure and Google
Cloud with the purpose *"Inference"***, adds four entities the other
lacks (GitHub, Microsoft Azure, OpenAI, Pylon), omits nine it has
(including Supabase, Attio, Airbyte, Hex and the whole *"AI Model
Providers"* row) and gives Google Cloud Natural Language API no row of
its own, and **carries no date**. Notably it does **not name
Anthropic** — the vendor the app's traffic actually reaches. The
`/authorized-sub-processors` page handles the same problem with the
generic *"AI Model Providers … Various"* row. **Cite
`/authorized-sub-processors`**: it is dated, it is the one the Enterprise
Access Agreement incorporates as Schedule 3 (*"Available at
https://openrouter.ai/authorized-sub-processors"*), and it does not
mislead by naming three inference vendors and omitting a fourth.

### Layer 2 — what the serving vendor does

**Under the app's pin this reduces to Anthropic, and therefore to
[Section B](#b-anthropic-review-is-internal-and-nobody-else-is-named).**
Both curated OpenRouter models carry `providers: ['anthropic']` with
fallbacks off. OpenRouter's own providers API confirms what that resolves
to: the `anthropic` slug's `privacy_policy_url` is
`https://www.anthropic.com/legal/privacy` and its `terms_of_service_url`
is `https://www.anthropic.com/legal/commercial-terms` — Anthropic's own
commercial regime, the same documents Section B reads.

The Privacy Policy states the hand-off plainly:

> Image, audio, and video data submitted through the Service is
> transmitted to the applicable Model Provider for inference. … Model
> Providers' retention practices vary; check the applicable provider's
> data practices.

**So the answer for the README's nested row is: adding OpenRouter adds a
router, not a reviewer.** OpenRouter interposes itself, one named
machine-categoriser and a set of infrastructure sub-processors; it does
not interpose a human content reviewer, and it names none. The person who
might read a flagged meal photo on the OpenRouter path is the same
Anthropic person who might read it on the direct path.

**Two caveats against over-claiming that.** First, "does not name one" is
not "has none" — OpenRouter's disclosure is thinner than Anthropic's
here, and the absence of a review clause is an absence of *disclosure*.
Second, the reduction depends entirely on the pin holding. If a future
model ships without `providers: ['anthropic']`, layer 2 becomes Amazon,
Google or Microsoft and this section is void; the endpoint listing above
shows eight of nine current endpoints for `claude-sonnet-5` are somebody
else's.

## D. OpenAI: the only provider that names names

### The verification the ticket asked for

Read in a browser against the live
[Sub-processor list](https://openai.com/policies/sub-processor-list/),
**last updated July 9, 2026**. The rows, transcribed exactly:

| Entity Name | OpenAI Product or Service | Location of Processing | Purpose of Processing |
| --- | --- | --- | --- |
| **TaskUs, LLC** | API, ChatGPT Enterprise, ChatGPT Edu, ChatGPT Business | **Philippines** | All Services: Customer support · **API & ChatGPT Business: Moderation of content** · ChatGPT Enterprise, Edu & ChatGPT Business: Moderation of GPTs |
| **Accenture International Limited** | API, ChatGPT Enterprise, ChatGPT Edu, ChatGPT Business | **United States, Canada, Philippines** | Customer support · **API & ChatGPT Business: Moderation of content** |
| Cinder Technologies, Inc. | API\*, ChatGPT Enterprise, Edu, Business | United States | API & ChatGPT Business: **Platform for content moderation** |

`*` on the Cinder row means *"Except where Zero Data Retention (ZDR) is
used"*. **TaskUs and Accenture carry no such asterisk.**

**The earlier note's claim survives, with a correction.** *"TaskUs and
Accenture, in the Philippines"* understates Accenture's footprint: its
row lists the United States and Canada as well. A README sentence should
say *"the Philippines among them"* rather than *"in the Philippines"*, or
name the locations per vendor.

The page defines the trigger, and it is narrow:

> **Moderation:** For content that OpenAI's models flag as being in
> violation of OpenAI's policies, OpenAI may share samples of the flagged
> Customer Content with relevant Sub-processors to assist OpenAI in its
> review and enforcement. Sharing with the Sub-processor platform only
> occurs when content is flagged, the Sub-processor platform only retains
> samples of content for the period of review, and OpenAI's
> Sub-processors only process the content to assist OpenAI in its review.

Flag-triggered, sample-only, time-limited to the review, purpose-limited.
That is a good disclosure and the README should not describe it as worse
than it is.

### OpenAI uses the phrase, structurally

The [Enterprise privacy](https://openai.com/enterprise-privacy/) page
(updated 8 January 2026) has a question titled *"Does OpenAI review my
business data?"* — read in a browser:

> We may run any business data submitted to OpenAI's services through
> automated content classifiers and safety tools, including to better
> understand how our services are used. The classifications created are
> metadata about the business data but do not contain any of the business
> data itself. Business data is only subject to human review as described
> below on a service-by-service basis.

And *"below"*, for the API specifically:

> Our access to API business data stored on our systems is limited to (1)
> authorized employees that require access for engineering support,
> investigating potential platform abuse, and legal compliance and (2)
> specialized third-party contractors who are bound by confidentiality
> and security obligations, solely to review for abuse and misuse.

Clause (2) plus the sub-processor list is the whole answer: the
*"specialized third-party contractors"* are TaskUs and Accenture, and
their locations are published.

### And it prices the absence of review

This is the finding that makes OpenAI's disclosure the most legible of
the three: **OpenAI sells "not being read" as a distinct product feature,
which means it has to define it.** From
[Data controls](https://developers.openai.com/api/docs/guides/your-data):

> **Eyes Off** … In this instance, customer content will be retained in
> abuse monitoring logs, but such content will be excluded from **human
> review** unless required by applicable law.

> **Safety Retention** … In this instance, we may retain and **human
> review** customer content when using these models that our classifiers
> detect as potentially violating our Usage Policies or your agreement.

**Read Eyes Off backwards and it says what the default is.** If being
*"excluded from human review"* is a thing an approved customer can be
given, then on the default path retained content is **not** excluded from
human review. No other provider's documents let you make that inference
so cleanly.

## E. The three sub-processor lists

The README's class sentence needs one link per provider. All three exist,
all three were read today, and each is the one the provider's own
contract points at.

| Provider | Link | Incorporated by | Dated? |
| --- | --- | --- | --- |
| Anthropic | [trust.anthropic.com/subprocessors](https://trust.anthropic.com/subprocessors) | DPA Schedule 4 — *"Anthropic's list of subprocessors is available at https://www.anthropic.com/subprocessors"* (307s here) | **No** |
| OpenRouter | [openrouter.ai/authorized-sub-processors](https://openrouter.ai/authorized-sub-processors) | Enterprise Access Agreement Schedule 3 — *"Available at https://openrouter.ai/authorized-sub-processors"* | Yes — 9 Jan 2026 |
| OpenAI | [openai.com/policies/sub-processor-list](https://openai.com/policies/sub-processor-list/) | OpenAI Data Processing Agreement | Yes — 9 Jul 2026 |

**Prefer `www.anthropic.com/subprocessors` in prose** if the README wants
the URL the contract actually names; it redirects. Prefer the
`trust.anthropic.com` form if the README wants the URL a reader lands on.
Do **not** cite `trust.openrouter.ai` — see
[Section C](#c-openrouter-two-layers-and-only-one-of-them-is-openrouters).

## F. Images versus text

**All three providers treat images differently from text, all three
differences are about child-safety scanning, and only OpenAI's has a
stated human consequence.**

| | Anthropic | OpenRouter | OpenAI |
| --- | --- | --- | --- |
| Scanned on submission | Perceptual hash against NCMEC's database, plus *"detection classifiers"* | Not stated | CSAM classifier, *"upon submission"* |
| On a hit | Report to NCMEC with *"information about the input and the related Account"*; the user or organization is notified | Not stated | *"the image will be retained for manual review"* |
| Survives every retention control? | Flagged content survives ZDR (up to 2 years) | n/a | **Yes — explicitly, including Eyes Off** |
| Any other image-specific rule | Images are *"ephemeral"* in the vision FAQ | Files not persisted *"except as required for abuse detection, security, billing, or legal compliance"* | Modified Abuse Monitoring excludes content *"other than image and file inputs in rare cases"* |

Anthropic's mechanism, from [CSAM Detection and Reporting](https://support.claude.com/en/articles/9020328-csam-detection-and-reporting)
(16 March 2026):

> When an image is sent in an input to our services, we will calculate a
> perceptual hash of the image. This hash will be automatically compared
> against the database. In the case of a match, we will notify and
> provide NCMEC information about the input and the related Account.

Every meal photo on the Anthropic path is hashed. **The page says the
comparison is automatic and does not say a person looks at a match before
the report goes out.** The Transparency Hub's numbers show both paths
running: 12,614 hash-matching CSAM reports and 2,018 from a *"Novel CSAM
classifier"* in January–June 2026.

OpenAI's, from Data controls, and this is the hardest sentence in the
note:

> Image and file inputs are scanned for CSAM content upon submission. If
> the classifier detects potential CSAM content, the image will be
> retained for manual review, even if Zero Data Retention, Modified Abuse
> Monitoring, or Eyes Off is enabled.

**On the OpenAI path a false positive on a photograph of dinner ends with
a person looking at that photograph, and there is no configuration that
prevents it.**

### The tension inside Anthropic's own documents

The README currently quotes Anthropic's vision FAQ, verified verbatim
today from the page payload:

> **Can I delete images I've uploaded?** No. Image uploads are ephemeral
> and not stored beyond the duration of the API request. Uploaded images
> are automatically deleted after they have been processed.

Set that beside the API retention docs, also Anthropic's, also read
today: *"if a chat or session is flagged, Anthropic may retain inputs and
outputs for up to 2 years."* A meal photo is an Input. **The two
sentences cannot both be unconditionally true, and the FAQ is the one
without the qualifier.** House rule says quote the weaker text. This does
not make the README's current sentence false — it is Anthropic's, quoted
accurately, and the qualifier lives elsewhere — but a reader who takes
"ephemeral" as absolute has been left with a wrong impression that
Anthropic's own retention page corrects. **If the human-review row ships,
this is the moment to attach the flagged-content exception to the
ephemerality quote**, because the row will otherwise say a photo can be
read while the paragraph above it says the photo no longer exists.

## G. Is review avoidable?

**No, on all three, for the app's actual user.** The routes and their
gates:

| Provider | The control | The gate | Reachable by a solo BYO-key developer? |
| --- | --- | --- | --- |
| Anthropic | Zero data retention | *"contact the Anthropic sales team"*; *"ZDR is enabled per organization"* | **No** — and it would not help: flagged content is retained *"regardless of arrangement"* for up to 2 years |
| OpenRouter | Nothing to configure at layer 1; ZDR enforcement at layer 2 | Self-serve, per-request or per-account | **The ZDR setting is reachable** — but it constrains *retention* by the serving vendor, not review, and Anthropic's flag-triggered retention survives it |
| OpenAI | Eyes Off | Presupposes approval for ZDR or Modified Abuse Monitoring, which are *"subject to prior approval by OpenAI and acceptance of additional requirements"* | **No** — and it does not cover images regardless |

**The OpenRouter row is the interesting one and it is a genuine, if
narrow, difference.** OpenRouter's ZDR enforcement is a self-serve
account or per-request setting — *"You can enforce ZDR globally, per model
group, per guardrail, or per request"* — with no sales conversation. That
is a control the app's user can actually reach, and it is one the direct
Anthropic path does not offer. But it routes to vendor endpoints that
carry a ZDR policy; it does not exempt anyone from classifier flagging,
and Anthropic's *"Retention regardless of arrangement"* clause tells you
what happens next. **It is not an escape from review and the app should
not present it as one.**

The general finding, stated as the ticket asked: **human review on all
three providers is triggered by an automated classifier, and no provider
offers the app's user a setting, tier or contract that turns the
classifier off.** [`ai-openai-data-handling.md`](ai-openai-data-handling.md)
found ZDR unreachable for an individual on OpenAI; review is worse than
that, because even the customers who *can* reach ZDR do not escape it on
images.

## What the README can now say

Stated as sentences, because the point is a claim a sceptic can check:

1. **The human-review row can ship for all three.** Anthropic: reviewed
   by Anthropic staff, no vendor named or listed. OpenRouter: no
   disclosure at the broker layer, and under the pin the reviewer is the
   serving vendor's — Anthropic's. OpenAI: TaskUs and Accenture, with the
   Philippines among the stated locations.
2. **Say "publishes no statement" for OpenRouter, not "does not
   review."** The distinction is the whole point of the ticket and the
   README's credibility rests on it.
3. **Say the trigger.** *"Only when an automated classifier flags the
   content"* is true of all three and is the most reassuring true thing
   available. Do not write it as "never" and do not write it as
   "routinely".
4. **The OpenRouter nested row stays a router row.** No third human
   destination is added by going through the broker. What the broker adds
   is Google Cloud Natural Language API on a sampled, anonymous,
   model-only basis — arguably below the level the table describes, but
   it is a named company that receives prompt text and the table's own
   rule ([#696](https://github.com/simonoppowa/OpenNutriTracker/issues/696))
   should be applied to it deliberately rather than by omission.
5. **Attach the flagged-content exception to the ephemerality quote**, or
   the two claims in the same paragraph will contradict each other.
6. **All three sub-processor links are live and citable.** Anthropic's
   is undated; if the README implies currency, that is worth a hedge.

## Not established

- **Whether Anthropic's Covered-Models review description applies to
  ordinary API traffic.** It is the only place Anthropic writes *"human
  review"* about its own staff and content, and it is fenced to two
  models the app does not use. Anthropic publishes no equivalent sentence
  scoped to `claude-haiku-4-5` or `claude-sonnet-5`. I read the API
  retention docs, the commercial retention article, the DPA, the
  Commercial Terms, the Trust Center FAQ and the Usage Policy looking for
  one; the nearest is the DPA's *"Anthropic will ensure that each person
  it authorizes to process Customer Personal Data is subject to an
  appropriate duty of confidentiality"*, which contemplates persons
  without describing when they read anything.
- **The contents of Anthropic's white paper on exactly this subject.**
  *[Anthropic] Security and Privacy Design of Anthropic Data Retention
  and Review* is listed publicly on the Trust Center under *Best
  Practices and Whitepapers*, marked **View** rather than *Request
  access* — so it is not NDA-gated. **The Vanta document viewer did not
  render in my headless browser and I could not read it.** It is at
  [trust.anthropic.com/resources](https://trust.anthropic.com/resources?s=7ksqkied5hn0pocsj206m&name=%5Banthropic%5D-security-and-privacy-design-of-anthropic-data-retention-and-review).
  **This is the single most likely document to change or sharpen Section
  B, and someone with a real browser should read it before the row
  ships.**
- **Whether OpenRouter has ever exercised the §6.7 screening right, or
  how.** Reserved in the Terms, never described. No transparency report,
  no enforcement statistics, no appeals process documented.
- **Whether Nutun or Boldr ever see Anthropic customer content.** Their
  stated purpose is *"User support"*, which on OpenAI's list is defined
  as initiated by the customer — but **Anthropic's list carries no such
  definition of purposes.** The page gives entity, purpose and location
  and nothing else. A support ticket that includes a pasted prompt is the
  obvious way content reaches a support vendor on any platform; nothing
  on Anthropic's page addresses it either way.
- **The date of Anthropic's sub-processor list.** None is carried
  anywhere in the rendered page. There is an *Updates* tab on the Trust
  Center that I did not enumerate.
- **Why OpenRouter's two sub-processor lists disagree**, and which
  governs. The Enterprise agreement incorporates the
  `/authorized-sub-processors` one, so that is the contractual list; the
  SafeBase one is presented to security reviewers. Neither page
  acknowledges the other.
- **Whether Anthropic's perceptual-hash match is reviewed by a person
  before the NCMEC report.** The page says the comparison is automatic
  and that a match produces a notification; it does not say whether
  anyone looks first. OpenAI's equivalent says *"retained for manual
  review"* in as many words. **The difference in wording is real; whether
  the difference in practice is real cannot be established from the
  pages.**
- **Whether the EU DSA transparency reporting Anthropic publishes
  discloses human-moderator headcounts.** It exists — *"Anthropic
  publishes transparency reports in accordance with its obligations under
  the EU Digital Services Act (DSA) for certain features of Claude.ai"* —
  and the DSA requires disclosure of human resources dedicated to content
  moderation. **It is scoped to claude.ai features, not the API**, so it
  was not pursued. It may nonetheless be the only public source naming
  how many people Anthropic has doing this work.
- **What any of the three do with a request that errors, is rejected by a
  classifier before inference, or is truncated.** Not addressed anywhere
  I looked, on any of the three.
- **Legal advice.** One non-lawyer reading published documents on one
  date. Two of the most load-bearing pages here — Anthropic's
  sub-processor list and OpenAI's data-controls guide — carry no date and
  can change silently.

## Sources

Anthropic:
[Privacy Policy](https://www.anthropic.com/legal/privacy) ·
[Commercial Terms of Service](https://www.anthropic.com/legal/commercial-terms) ·
[Data Processing Addendum](https://www.anthropic.com/legal/data-processing-addendum) ·
[Usage Policy](https://www.anthropic.com/legal/aup) ·
[Subprocessor List](https://trust.anthropic.com/subprocessors) ·
[Trust Center FAQ](https://trust.anthropic.com/faq) ·
[API and data retention](https://platform.claude.com/docs/en/manage-claude/api-and-data-retention) ·
[Vision documentation](https://platform.claude.com/docs/en/build-with-claude/vision) ·
[How long do you store my organization's data?](https://privacy.claude.com/en/articles/7996866-how-long-do-you-store-my-organization-s-data) ·
[Data retention practices for Covered Models](https://privacy.claude.com/en/articles/15425996-data-retention-practices-for-covered-models) ·
[Covered Models](https://support.claude.com/en/articles/15425695) ·
[Our Approach to User Safety](https://support.claude.com/en/articles/8106465-our-approach-to-user-safety) ·
[CSAM Detection and Reporting](https://support.claude.com/en/articles/9020328-csam-detection-and-reporting) ·
[Safeguards warnings and appeals](https://support.claude.com/en/articles/8241253-safeguards-warnings-and-appeals) ·
[API Safeguards Tools](https://support.claude.com/en/articles/9199617-api-safeguards-tools) ·
[How does Anthropic protect the personal data of Claude users?](https://privacy.claude.com/en/articles/10458704-how-does-anthropic-protect-the-personal-data-of-claude-users) ·
[Transparency Hub](https://www.anthropic.com/transparency/system-trust-reporting)

OpenRouter:
[Privacy Policy](https://openrouter.ai/privacy) ·
[Terms of Service](https://openrouter.ai/terms) ·
[Enterprise Access Agreement](https://openrouter.ai/terms-of-service-enterprise) ·
[Authorized Sub-Processors](https://openrouter.ai/authorized-sub-processors) ·
[Trust Center](https://trust.openrouter.ai/) ·
[Data Collection](https://openrouter.ai/docs/guides/privacy/data-collection) ·
[Provider Logging](https://openrouter.ai/docs/guides/privacy/provider-logging) ·
[Zero Data Retention](https://openrouter.ai/docs/guides/features/zdr) ·
[Input & Output Logging](https://openrouter.ai/docs/guides/features/input-output-logging)

OpenAI (`openai.com` read in a browser; the site 403s automated fetching):
[Sub-processor list](https://openai.com/policies/sub-processor-list/) ·
[Enterprise privacy](https://openai.com/enterprise-privacy/) ·
[Data controls in the OpenAI platform](https://developers.openai.com/api/docs/guides/your-data)

Related notes in this repo:
[`ai-openai-data-handling.md`](ai-openai-data-handling.md) ·
[`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) ·
[`ai-openai-key-transfer.md`](ai-openai-key-transfer.md) ·
[`ai-legal-constraints.md`](ai-legal-constraints.md) ·
[`ai-open-research-questions.md`](ai-open-research-questions.md)

In-repo files cited:
[`lib/core/utils/ai_model_catalogue.dart`](../lib/core/utils/ai_model_catalogue.dart) ·
[`lib/features/add_meal/util/meal_photo_encoder.dart`](../lib/features/add_meal/util/meal_photo_encoder.dart)
