# Does BYO-key fall foul of OpenAI's API-key transfer prohibition?

**Verdict: §3.3(g) almost certainly does not reach this design, and the best
evidence for that is OpenAI's own — its current help centre tells users how to
vet "third-party libraries, frameworks, and tools that request access to your
API key" rather than telling them not to.** But two things stop this being a
clean pass. First, **the precedent argument that resolved
[#679](https://github.com/simonoppowa/OpenNutriTracker/issues/679) is not
available here: neither Anthropic nor OpenRouter has any equivalent clause**, so
the project has never accepted this restriction before and cannot argue from
consistency. Second, **the sentence that actually bites is not §3.3(g)** — it is
the API reference's *"Don't … expose it in any client-side code such as browsers
or apps"*, which Service terms §1 arguably makes binding. This is a documents
review, not legal advice.

## Bottom line up front

1. **This does not kill the effort.** Nothing found is a prohibition the app
   plainly meets. §3.3(g) is a commerce-and-account-integrity clause whose every
   neighbour concerns a credential reaching a *different person*, and no reading
   of the shipped design puts a key in anyone else's hands.
2. **"Transfer" is defined nowhere.** §17 of the Services Agreement carries over
   sixty definitions and defines neither *transfer*, nor *API key*, nor *third
   party*. The Usage Policies contain the strings "API key", "transfer" and
   "credential" **zero times** — verified by full-text search of the live page,
   not by reading around. There is no interpretive material in the contract
   documents at all.
3. **OpenAI's help centre presupposes the pattern.** *"Use caution with
   third-party libraries, frameworks, and tools that request access to your API
   key … review the company and the product carefully."* A vendor that read
   §3.3(g) as barring the arrangement would write "don't", not "check reviews".
   This is the strongest single item in the note. It is not permission, and the
   help centre does not bind — but it is the only published signal of how OpenAI
   reads its own rule, it is current, and it points one way.
4. **The calibration question answers against OpenAI, and that is the finding.**
   Anthropic's Commercial Terms of Service contain the word "transfer" **zero
   times** and mention API keys exactly once, in a scope sentence. OpenRouter's
   nearest clause transfers *"the access granted under these Terms or any
   Materials"*, where "Materials" is defined as OpenRouter's own IP. **No
   equivalent clause found in either.** OpenAI is genuinely different, and
   "we already do this with Anthropic" is an argument from a silent document.
5. **The guidance comparison inverts the contract comparison, and rescues the
   consistency argument on the narrower ground of custody.** Anthropic's support
   article is verbally *stricter* than anything OpenAI publishes — *"Never share
   your API key"*, and a warning that uploading it to a third-party tool means
   *"you are giving the developer of that tool access to your Claude Console
   account."* The project shipped against Anthropic with that on the page. And
   the case Anthropic describes is one where the key genuinely leaves the device;
   this design is the strictly safer version of the thing already tolerated.
6. **The real exposure is documentation, not §3.3(g).** Service terms §1 binds
   Customer to *"use APIs in accordance with the applicable documentation"*, and
   that documentation says *"Don't share it with others or expose it in any
   client-side code such as browsers or apps. Load API keys from an environment
   variable or key management service on the server."* Read with the user as
   Customer, a long-lived key on a phone is closer to that sentence than to
   §3.3(g). See [Section C](#c-the-clause-that-actually-bites-and-it-is-not-g).
7. **Unresolvable to certainty from public documents.** Both questions above land
   on genuine ambiguity, and picking a side here would be inventing confidence.
   What would resolve it is in [What would settle
   this](#what-would-settle-this): a support enquiry, which only the account
   holder can make.

## How this was read

Primary sources only, all read on 2026-08-16. openai.com, help.openai.com and
platform.openai.com return HTTP 403 to automated fetching, so every OpenAI quote
below was read in a real browser against the live page. Where the finding is an
*absence* — no definition, no clause — it was established by full-text string
search of the rendered page rather than by reading and not noticing, and the
search terms are stated so the check is repeatable. No secondary summary, blog
post or forum answer is cited as evidence anywhere in this note; two that turned
up are quarantined in [Section G](#g-enforcement-and-one-false-quote-to-watch-for)
precisely because they are the kind of thing that gets quoted into a decision.

| Document | Date it carries |
| --- | --- |
| [OpenAI Services Agreement](https://openai.com/policies/services-agreement/) | Updated **December 1, 2025**; Effective **January 1, 2026** |
| [OpenAI Usage policies](https://openai.com/policies/usage-policies/) | Effective **October 29, 2025** |
| [OpenAI Service terms](https://openai.com/policies/service-terms/) | Updated **June 12, 2026** |
| [OpenAI API reference overview](https://developers.openai.com/api/reference/overview) | no date carried |
| [Best Practices for API Key Safety](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety) | "Updated: 3 days ago" (≈ **13 August 2026**) |
| [How can I keep my OpenAI accounts secure?](https://help.openai.com/en/articles/8304786-how-can-i-keep-my-openai-accounts-secure) | "Updated: 18 days ago" (≈ **29 July 2026**) |
| [Can I share my API key with my teammate/coworker?](https://help.openai.com/en/articles/5008148-can-i-share-my-api-key-with-my-teammatecoworker) | "Updated: 18 days ago" (≈ **29 July 2026**) |
| [Anthropic Commercial Terms of Service](https://www.anthropic.com/legal/commercial-terms) | Effective **June 17, 2025** |
| [Anthropic Usage Policy](https://www.anthropic.com/legal/aup) | Effective **September 15, 2025** |
| [Anthropic Service Specific Terms](https://www.anthropic.com/legal/service-specific-terms) | Effective **June 8, 2026** |
| [Anthropic API Key Best Practices](https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure) | **March 16, 2026** |
| [OpenRouter Terms of Service](https://openrouter.ai/terms) | Last Updated **July 29, 2026** |

The three help-centre pages render a relative age rather than a date; the
absolute dates above are derived from the read date and are approximate. The
Services Agreement, Usage Policies and Service terms all carry explicit dates.

### The behaviour the clauses are read against

Verified in source rather than assumed, in
[`ai_credential_storage.dart`](../lib/core/utils/ai_credential_storage.dart) and
the two API clients:

- The key is typed by the holder into the app's settings on their own device.
- It is written through `flutter_secure_storage` to the platform keystore, using
  the hardened options on
  [`SecureAppStorageProvider`](../lib/core/utils/secure_app_storage_provider.dart)
  — `AES_CBC_PKCS7Padding` and `resetOnError: false`.
- `readApiKey` is called at request time and the value is not retained: the
  class documents this as *"nothing should hold a credential in memory longer
  than the request that needs it."*
- It leaves the device only as a request header to the provider's own endpoint —
  `'authorization': 'Bearer ${_apiKey()}'` in
  [`openrouter_meal_items_api.dart`](../lib/features/add_meal/data/openrouter_meal_items_api.dart)
  and `'x-api-key': _apiKey()` in
  [`anthropic_meal_items_api.dart`](../lib/features/add_meal/data/anthropic_meal_items_api.dart).
  Those are the only two sites in `lib/` that read a credential into a header.
- No backend, no proxy, no telemetry, no key in the shipped binary. The project
  holds no account and pays for nothing.

So on the facts: nothing is bought, nothing is sold, no second person ever holds
the key, and every charge lands on the holder. The only open question is whether
"transfer … to … a third party" reaches a credential passing through software
written by someone else while never leaving its owner's device.

## A. §3.3(g) in its own document

Verbatim, from the live page (Updated December 1, 2025; Effective January 1,
2026):

> **3.3. Restrictions.** Customer will not, and will not permit End Users to:
> (a) use the Services or Customer Content in a way that violates applicable
> laws or OpenAI Policies; (b) use the Services or Customer Content in a way
> that violates third parties' rights; (c) allow minors to use OpenAI Services
> without consent from their parent or guardian; (d) Reverse Engineer any aspect
> of the Services or the systems used to provide the Services; (e) except for a
> Permitted Exception, use Output to develop artificial intelligence models that
> compete with OpenAI's products and services; (f) extract data from the
> Services other than as permitted through the Services; **(g) buy, sell, or
> transfer API keys from, to, or with a third party;** (h) interfere with or
> disrupt the Services, including circumvent any rate limits or restrictions or
> bypass any protective measures or safety mitigations for the Services;
> (i) violate or circumvent Usage Limits or otherwise configure the Services to
> avoid Usage Limits.

**"Transfer" is not defined.** §17 runs to more than sixty defined terms and
contains no entry for *transfer*, *API key*, or *third party*. It defines
*"Third-Party Services"* — *"products, services, or content offered by parties
other than OpenAI **through the Services**"* — which is a different concept and
does not describe this app. It defines *"Third-Party Service Terms"*. §16.10 is
headed *"No Third-Party Beneficiaries"*. None of these supplies a meaning for
the lowercase "third party" in (g).

**Nothing elsewhere fills the gap.** Searching the rendered Usage Policies page
(effective 29 October 2025) for `API key`, `api key`, `transfer`, `Transfer` and
`credential` returns **no matches at all** — the document is 9,433 characters
and never mentions keys. The Service terms (updated 12 June 2026) contain no key
or transfer provision either. So the whole interpretive weight sits on the
sentence itself and its neighbours.

**The neighbourhood is about credentials reaching a different person.** §3.1,
two paragraphs earlier:

> Customer must provide accurate and current Account information. Customer will
> not share Account access credentials or individual login credentials between
> multiple users. Customer may not resell or lease access to its Account or any
> End User Account.

and §3.2: *"End User Accounts may only be provisioned to, registered for, and
used by, a single End User."* Read together with (g)'s own verbs — **buy**,
**sell**, transfer — and its prepositions — *from, to, or with* — the family is
unmistakably a market in credentials and multi-person use of one account.
Nothing in the shipped design is in that family. One person holds one key, uses
it themselves, and pays for it themselves.

**Two counterweights, recorded because they cut the other way.** §14.1 excludes
*"CUSTOMER'S BREACH OF SECTION 3.3 (RESTRICTIONS)"* from the cap on indirect
liability, so §3.3 is not a soft clause. And §8.2 lets OpenAI suspend where
*"Customer violates the Agreement or OpenAI Policies"*. Against that: §17 defines
*"Abusive Customer Content"* as *"Inputs or Outputs that violate Section 3.3"* —
a definition that makes sense of (a) and (b) and makes no sense at all of (g),
which is weak evidence that (g) was bolted into a content-shaped list as an
account-integrity rule rather than drafted to reach software design.

## B. The gloss OpenAI publishes

This is the part that was missing when
[`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) called §3.3(g)
*"unresolvable from public documents"*. OpenAI does publish interpretive
material. It is in the help centre, not the contract, and it is consistent.

**[Best Practices for API Key Safety](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety)**,
item 1, under the heading *"Always use a unique API key for each team member on
your account"*:

> An API key is a unique code that identifies your requests to the API. Your API
> key is intended to be used by you. The sharing of API keys is against the
> Terms of Use.
>
> As you begin experimenting, you may want to expand API access to your team.
> OpenAI does not support the sharing of API keys. Please invite new members to
> your account from the Members page and they will quickly receive their own
> unique key upon sign-in.

Note what the sentence *"The sharing of API keys is against the Terms of Use"*
is doing. It is the only place OpenAI restates a key restriction as a rule, and
the whole item is about **team members** — the remedy offered is inviting people
to your account. It also cites the wrong instrument: the API path runs on the
Services Agreement, not the consumer Terms of Use ([#679](https://github.com/simonoppowa/OpenNutriTracker/issues/679)).
That imprecision is a reason not to over-read the help centre in either
direction.

**[Can I share my API key with my teammate/coworker?](https://help.openai.com/en/articles/5008148-can-i-share-my-api-key-with-my-teammatecoworker)**
is the same idea at lower strength:

> We do not recommend sharing your personal API key — even with trusted
> coworkers or teammates. API keys grant access to your organization's usage and
> billing …

*Do not recommend*, not *may not*. Again, people.

**And then the one that matters.** From
**[How can I keep my OpenAI accounts secure?](https://help.openai.com/en/articles/8304786-how-can-i-keep-my-openai-accounts-secure)**,
under its own heading *"Be cautious with third-party products"*:

> Use caution with third-party libraries, frameworks, and tools that request
> access to your API key. Even if a product seems reputable, there is still a
> risk of key exposure or misuse.
>
> Before using a third-party product that requires your API key, review the
> company and the product carefully. Check reviews, read the privacy policy, and
> look for any security concerns raised by the community.

**OpenAI's current security guidance treats "a third-party product that requires
your API key" as a thing a Customer may reasonably do, and gives diligence
advice for doing it.** If §3.3(g) barred the arrangement, this paragraph would
be one word long. The pattern is named, contemplated, and left to the holder's
judgement.

Three honest limits on how far that goes. The help centre is not an *"OpenAI
Policy"* — §17 defines those as *"the Service-Specific Terms, Sharing and
Publication Policy, and Usage Policies"*, and the help centre is none of them,
so this creates no permission and waives nothing. It is a security page, not a
legal one, and security advice is not a licence. And it is undated in any
durable way, so it can move without notice.

## C. The clause that actually bites, and it is not (g)

Same security page, a few paragraphs down, under *"Do not ship your API key"*:

> It can be tempting to embed your API key directly in an application to avoid
> running a server for a mobile app or a similar use case. However, this makes
> the API key vulnerable to misuse.

Read the possessives. *Your* key, embedded by *you*, in an app *you* ship to
other people. That is the developer-holds-the-key shape — §2.2's *Customer
Application* — and it is precisely the arrangement BYO-key exists to avoid. Not
engaged. The same is true of the corresponding item in Best Practices: *"Never
deploy your key in client-side environments like browsers or mobile apps.
Exposing your OpenAI API key in client-side environments like browsers or mobile
apps allows malicious users to take that key and make requests on your behalf."*
Its threat model requires one key distributed to many users; under BYO-key each
install holds only its own holder's key.

**The API reference is different, and it is the strongest thing found against
this design.** Service terms §1 (updated 12 June 2026):

> Customer will only, and will ensure that its End Users only, use APIs in
> accordance with the applicable documentation at
> https://platform.openai.com/docs

That URL redirects to `developers.openai.com` (verified in a browser on
2026-08-16), whose
[API reference overview](https://developers.openai.com/api/reference/overview)
says, under **Authentication**:

> Remember that your API key is a secret. Don't share it with others or expose
> it in any client-side code such as browsers or apps. Load API keys from an
> environment variable or key management service on the server.

With the user as Customer, a long-lived key sitting on a phone inside a mobile
app is nearer to *"client-side code such as … apps"* than anything in §3.3(g) is
to this app. And it arrives through a clause — Service terms §1 — that is a real
contractual obligation, unlike the help centre.

What answers it, and how far:

- **"Expose" is the operative verb, and the design's whole point is that nothing
  is exposed.** The key sits in Android Keystore / iOS Keychain under
  `resetOnError: false`, is read only for the request that needs it, and travels
  only to the provider endpoint. There is no party to whom it is exposed, which
  is the harm every neighbouring sentence names.
- **The third sentence presupposes an addressee that does not exist here.**
  *"Load API keys from an environment variable or key management service on the
  server"* is instruction to someone operating a server. Under BYO-key nobody
  is. The passage is written for the developer-as-Customer shape throughout.
- **It is guidance phrased as advice inside a reference page.** Whether *"use
  APIs in accordance with the applicable documentation"* converts every
  *"Remember that…"* into a term is itself undecided, and the documentation
  behind that link is mostly tutorials.

**And OpenAI does document a client-side pattern — it is the opposite of this
one.** The Realtime guide: *"Use `POST /v1/realtime/client_secrets` to create
ephemeral credentials for browser or mobile clients."* That is OpenAI's answer
for a mobile client that must reach the API, and it requires a backend to mint
the token. It is worth recording plainly: the sanctioned shape for mobile is
server-minted ephemeral credentials, and a serverless GPL app with no
infrastructure cannot implement it. BYO-key is not what OpenAI points mobile
developers at; it is what remains when the pointed-at option is unavailable.

## D. Custody or movement

**Nothing in the contract documents turns on where a key is stored.** §3.3(g) is
a movement test — buy, sell, transfer. §3.1 is a sharing test — *"between
multiple users"*. §3.2 is a per-account test. Storage, encryption, keystores and
device custody appear nowhere in the Services Agreement, nowhere in the Usage
Policies, and nowhere in the Service terms. Searched for; absent.

So the answer to the ticket's third question is: **custody does not change the
§3.3(g) answer, because §3.3(g) does not ask about custody.** Where custody
*does* appear is in documentation and help-centre guidance — which is exactly
the material [Section C](#c-the-clause-that-actually-bites-and-it-is-not-g) is
about — and there it helps rather than hurts.

One place custody matters concretely. The only specific enforcement mechanism
OpenAI publishes anywhere is exposure-triggered:

> When OpenAI detects an API key on the public internet, or leaked inside an app
> in an app store, the API key is disabled immediately.

That is automated scanning for keys **embedded in shipped artifacts**. The app
ships no key in its binary — the credential is user-entered and never enters the
repository or the build — so there is nothing there for that scanner to find.
It is the one point where the design is not merely defensible but actively,
mechanically compliant, and it is worth stating because it is the mechanism most
likely to touch a real user.

## E. Anthropic and OpenRouter: no equivalent clause found

This is the calibration question, and the answer is that **OpenAI is different**.

### Anthropic

**[Commercial Terms of Service](https://www.anthropic.com/legal/commercial-terms),
effective June 17, 2025** — the current version; the page offers a "Previous
Version" link. This is the API instrument: *"They govern Customer's use of
Anthropic API keys and any other Anthropic offerings that references these
Terms."*

Full-text search of the rendered page (26,103 characters):

| Term | Occurrences |
| --- | --- |
| `transfer` / `Transfer` | **0** |
| `credential` / `Credential` | **0** |
| `API key` | **1** — the scope sentence quoted above |

The entire restrictions provision is D.4, and it is three lines:

> **D.4. Use Restrictions.** Customer may not and must not attempt to (a) access
> the Services to build a competing product or service, including to train
> competing AI models or resell the Services except as expressly approved by
> Anthropic; (b) reverse engineer or duplicate the Services; or (c) support any
> third party's attempt at any of the conduct restricted in this sentence.

The only account provision is responsibility, not restriction:

> **D.5. Service Account.** Customer is responsible for all activity under its
> account. Customer will promptly notify Anthropic if Customer believes the
> account it uses to access the Services has been compromised …

The [Usage Policy](https://www.anthropic.com/legal/aup) (effective 15 September
2025) and the [Service Specific Terms](https://www.anthropic.com/legal/service-specific-terms)
(effective 8 June 2026) were searched for the same terms and return **zero**
matches in each. **No equivalent clause exists anywhere in Anthropic's API
regime.**

### OpenRouter

**[Terms of Service](https://openrouter.ai/terms), Last Updated July 29, 2026.**
§3.2 is the only key provision and it is a confidentiality-and-responsibility
clause:

> **3.2 API Credentials.** You are responsible for maintaining the
> confidentiality and security of all API keys, tokens, passwords, and other
> credentials used to access the Service ("API Credentials"). You are
> responsible for all activity and charges under its account or API Credentials,
> whether or not authorized by you, except to the extent caused directly by
> OpenRouter's breach of these Terms.

The nearest thing in §7 (Prohibited Conduct) is:

> sell or otherwise transfer the access granted under these Terms or any
> Materials (as defined in 12) or any right or ability to view, access, or use
> any Material

and §12 defines Materials as OpenRouter's own property — *"The visual
interfaces, graphics, design, compilation, information, data, computer code
(including source code or object code), products, software, services, and all
other elements of the Service ("Materials")"*. That is an IP and licence clause,
not a credential clause. §4 adds that *"Credits are non-transferable, including
between accounts"* — again about value, not keys. **No equivalent clause found.**

### What this means for the consistency argument

| | OpenAI | Anthropic | OpenRouter |
| --- | --- | --- | --- |
| Key buy/sell/transfer clause | **§3.3(g)** | **none** | **none** |
| Credential-sharing clause | §3.1, between users | none | none |
| Key custody obligation in contract | none | none | §3.2, confidentiality |
| Documented third-party-key flow | no | no | **yes** — OAuth PKCE |
| Guidance on giving your key to third-party software | "use caution … review the company" | "never share … exercise caution with third-party tools" | — |

**The precedent argument does not carry.** #679's internal-consistency move
worked because Anthropic's disordered-eating prohibition was demonstrably
*wider* than OpenAI's, so accepting one and rejecting the other was incoherent.
Here the comparison runs the other way: OpenAI has a clause and the other two
have nothing resembling it. The project did not previously accept this
restriction; there was none to accept. Anyone arguing "we already ship BYO-key
against two vendors, so this is settled" is arguing from silence in the two
documents that are silent.

**But the guidance comparison inverts the contract comparison, and that partly
restores the argument on the narrower ground of custody.** Anthropic's
[API Key Best Practices](https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure)
(March 16, 2026) is verbally stricter than anything OpenAI publishes:

> **1. Never share your API key**
>
> Keep it confidential: Just as you wouldn't share your personal password, don't
> share your API key. If someone needs access to the Claude API, they should
> obtain their own key.
>
> Exercise caution with third-party tools: Consider that when you upload your
> API key to third-party tools or platforms (such as an web-based IDE, Cloud
> Provider, or CI/CD platform), you are giving the developer of that tool access
> to your Claude Console account. If you don't trust their reputation, don't
> trust them with your API key.

The project reviewed Anthropic and shipped. And read the case Anthropic
describes: a web IDE, a cloud provider, a CI/CD platform — arrangements where
the key genuinely leaves the user's machine and the developer really does gain
access to the Console account. Anthropic treats that as the holder's risk
decision, not a breach. **OpenNutriTracker's design is the strictly safer
version of the arrangement Anthropic explicitly tolerates**: the key never
reaches the developer, never reaches a server, and never leaves the keystore
except as a header to the provider. So on custody, consistency does hold; it is
only on the *existence of a contractual key clause* that OpenAI stands alone.

### Is there a sanctioned pattern anywhere?

- **OpenAI: no.** Searched the Services Agreement, Usage Policies, Service
  terms, the help centre's security collection and the API reference. There is
  no partner programme, no docs page and no FAQ describing a user supplying
  their own key to third-party software. What exists is the diligence paragraph
  in [Section B](#b-the-gloss-openai-publishes), which presupposes the pattern
  without blessing it, and the ephemeral-client-secret alternative in
  [Section C](#c-the-clause-that-actually-bites-and-it-is-not-g).
- **Do not cite OpenAI's "BYOK" as support.** In OpenAI's documentation the
  acronym means something else: *"OpenAI supports Bring Your Own Key (BYOK)
  encryption with external accounts in AWS KMS, Google Cloud (GCP), and Azure
  Key Vault"* — customer-managed **encryption** keys for enterprise data at
  rest. It has nothing to do with API credentials, and a search for "BYOK" on
  OpenAI's site will surface it first.
- **OpenRouter: yes, explicitly.** It documents OAuth PKCE for exactly this —
  *"Users can connect to OpenRouter in one click using Proof Key for Code
  Exchange (PKCE)"*, with the app exchanging the code for *"a user-controlled
  API key"*. A vendor that builds and documents a flow for third-party apps to
  receive a per-user key is not prohibiting the arrangement.
- **Anthropic: neither.** No third-party key-provisioning flow found in the API
  docs, and no prohibition. The support article contemplates the pattern and
  warns about it.

## F. What §2.2 and "Customer Application" still do not do

Unchanged from [`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) and restated
because it bears on (g): §17 defines *"Customer Application"* as *"Customer's
applications, products, or services that integrate with an OpenAI API."* When
the user is the Customer, this app is not their application — they did not build
it. The Agreement simply has no category for *third-party software the Customer
runs with their own key*, and §3.4's *"Third-Party Services"* is not it either,
being confined to things offered *"through the Services"*.

That definitional gap is the honest reason (g) cannot be resolved by text. The
drafters were not thinking about this arrangement in either direction.

## G. Enforcement, and one false quote to watch for

**No enforcement found in either direction, and I do not believe it is
findable.** OpenAI publishes no case-level developer enforcement data; its only
enforcement reporting is the threat-intelligence *Disrupting malicious uses of
AI* series, which covers influence operations and state actors. The one
concrete, published mechanism touching keys is the automated leak-scanner quoted
in [Section D](#d-custody-or-movement), and it fires on exposure, not on
transfer. **"No enforcement found" here means "not published", not comfort.**

**No OpenAI staff guidance found.** The two developer-forum threads that surface
on any search for this question — *"Bring Your Own Key policy"* and *"Is this
allowed? (This bring your own key usage)"* on community.openai.com — were
checked for staff replies. There are none; the confident answers in them are
community members, including one with no staff designation asserting that
*"Bring your own key application are not strictly prohibited"*. That is not
evidence and should not be cited as any.

**One thing to guard against, recorded because it is exactly what gets pasted
into a decision.** A web search summary attributed to help.openai.com the
sentence *"users are not permitted to share their API keys with others,
including via bring-your-own-key applications."* **That sentence does not appear
on the page.** The page says *"Use caution with third-party libraries,
frameworks, and tools that request access to your API key"* — close to the
opposite in effect. The fabricated version is more decisive than anything OpenAI
has written, and would have settled this ticket the wrong way. Every quote in
this note was read on the live page for that reason.

**On the ecosystem argument.** A large population of BYO-key third-party
clients, CLIs and IDE plugins exists and has existed for years without visible
consequence. This is worth *something* and much less than it looks: it is
evidence that OpenAI has not chosen to read (g) broadly, since a party intending
the broad reading and enforcing it would by now have produced at least one
visible instance. That is an argument from silence, it is weak, and **widespread
practice is not permission.** It should not appear in any decision as a reason;
at most it is context for why the narrow reading is the plausible one.

## What would settle this

Only the account holder can resolve either question, and an agent must not
contact a vendor on the user's behalf. A support enquiry from the maintainer's
own OpenAI account — help.openai.com, new chat — asking two specific things:

1. **Does Services Agreement §3.3(g) apply where a Customer enters their own API
   key into third-party client software installed on their own device, when the
   software's publisher never receives, stores, proxies or transmits the key,
   and the key travels only from that device to OpenAI?**
2. **Does the API reference's *"Don't … expose it in any client-side code such
   as browsers or apps"* bind under Service terms §1 in that arrangement, given
   that the key is held in the platform keystore and there is no server to load
   it on?**

Ask both. The second is the one this note found and the ticket did not, and it
is the one likelier to get a substantive answer, because it is a documentation
question rather than a contract-interpretation question support may decline.

Absent that, the position to hold is: **proceed if the project wants OpenAI, but
record that OpenAI carries a documented key restriction that neither incumbent
vendor has, and that the cover is a reading rather than a permission.** That is
one more reason to rank OpenAI below Anthropic, alongside the absent wellness
carve-out ([`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) §D) and the
standing technical objections in
[`ai-model-candidates.md`](ai-model-candidates.md).

## Not established

- **Whether pasting your own key into locally-installed third-party software is
  a "transfer … to … a third party" under §3.3(g).** Still not resolvable to
  certainty from public documents. What is new since
  [`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) is that the balance has
  shifted: the term is undefined, every neighbour concerns movement between
  people, and OpenAI's own security page gives diligence advice for the exact
  pattern. That is a strong *reading*, not an answer.
- **Whether Service terms §1 makes the API reference's client-side sentence a
  contractual obligation.** The clause says *"in accordance with the applicable
  documentation"* and the documentation says *"Don't … expose it in any
  client-side code such as browsers or apps."* Whether an advisory sentence in a
  reference page is a term, and whether keystore storage is "exposure", are both
  undecided and neither is addressed anywhere OpenAI publishes. **This is now
  the most load-bearing ambiguity in the OpenAI question, displacing §3.3(g).**
- **Whether OpenAI would treat a hobbyist key holder as the "Customer" bound by
  §3.3 at all.** Carried forward unresolved from
  [`ai-openai-policy-fit.md`](ai-openai-policy-fit.md); the scope sentence names
  APIs but addresses *"businesses and developers"*, and OpenAI states the
  position nowhere else.
- **Exact dates for the three OpenAI help-centre pages.** They render only a
  relative age ("Updated: 3 days ago", "Updated: 18 days ago") with no `title`
  or `datetime` attribute in the markup to extract. The absolute dates in the
  table are derived from the 2026-08-16 read date and could be off by a day.
- **Whether OpenAI's App Developer Terms contain a credential provision.** The
  page did not render usable text in the browser on this read (1,686 characters,
  no body). It governs ChatGPT Apps and Actions rather than API integrations
  (Service terms §5(c), §7(a)), so it is not expected to bear on this, but it
  was not searched and should not be described as clear.
- **Whether Anthropic offers any third-party key-provisioning flow.** None found
  in the API documentation, but the search was not exhaustive across the whole
  developer site; the finding is "not found", not "does not exist".
- **Any enforcement history for §3.3(g).** None found, in either direction. See
  [Section G](#g-enforcement-and-one-false-quote-to-watch-for) for why "none
  found" is close to uninformative here.
- **Legal advice.** This is one non-lawyer reading published documents on one
  date. All twelve documents in the table can change without notice, and the
  dates are the only guarantee offered.

## Sources

OpenAI (read in a browser; the sites 403 automated fetching):
[Services Agreement](https://openai.com/policies/services-agreement/) ·
[Usage policies](https://openai.com/policies/usage-policies/) ·
[Service terms](https://openai.com/policies/service-terms/) ·
[API reference overview](https://developers.openai.com/api/reference/overview) ·
[Realtime guide](https://developers.openai.com/api/docs/guides/realtime) ·
[Production best practices](https://developers.openai.com/api/docs/guides/production-best-practices) ·
[Your data](https://developers.openai.com/api/docs/guides/your-data) ·
[Best Practices for API Key Safety](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety) ·
[How can I keep my OpenAI accounts secure?](https://help.openai.com/en/articles/8304786-how-can-i-keep-my-openai-accounts-secure) ·
[Can I share my API key with my teammate/coworker?](https://help.openai.com/en/articles/5008148-can-i-share-my-api-key-with-my-teammatecoworker)

Anthropic:
[Commercial Terms of Service](https://www.anthropic.com/legal/commercial-terms) ·
[Usage Policy](https://www.anthropic.com/legal/aup) ·
[Service Specific Terms](https://www.anthropic.com/legal/service-specific-terms) ·
[API Key Best Practices](https://support.claude.com/en/articles/9767949-api-key-best-practices-keeping-your-keys-safe-and-secure) ·
[API overview](https://platform.claude.com/docs/en/api/overview)

OpenRouter:
[Terms of Service](https://openrouter.ai/terms) ·
[OAuth PKCE](https://openrouter.ai/docs/use-cases/oauth-pkce)

Related notes in this repo:
[`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) ·
[`ai-model-candidates.md`](ai-model-candidates.md) ·
[`ai-legal-constraints.md`](ai-legal-constraints.md) ·
[`ai-open-research-questions.md`](ai-open-research-questions.md)

In-repo files cited:
[`lib/core/utils/ai_credential_storage.dart`](../lib/core/utils/ai_credential_storage.dart) ·
[`lib/core/utils/secure_app_storage_provider.dart`](../lib/core/utils/secure_app_storage_provider.dart) ·
[`lib/features/add_meal/data/anthropic_meal_items_api.dart`](../lib/features/add_meal/data/anthropic_meal_items_api.dart) ·
[`lib/features/add_meal/data/openrouter_meal_items_api.dart`](../lib/features/add_meal/data/openrouter_meal_items_api.dart)
