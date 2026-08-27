# What can iubenda be made to express, and are EN and DE one config or two?

Research for [#871](https://github.com/simonoppowa/OpenNutriTracker/issues/871), on
map [#867](https://github.com/simonoppowa/OpenNutriTracker/issues/867). Researched
2026-08-27 against iubenda's own help centre and changelog, the documented public
read API, and the two live policy documents (`53501884` EN, `53922100` DE) plus one
unrelated live iubenda policy used as a worked example.

**The short answer: the generator can say almost anything, but only in the wrong
shape.** Two of the missing recipients are already in the catalogue as first-class
services (`OpenAI API`, and `Supabase` / `Supabase (self-hosted)`); the rest have to
go through the *custom service* mechanism, which is a service name plus one free-text
box. Free text buys unlimited wording — including conditionality, which the structured
catalogue cannot express at all — but it is paid for by leaving the machine-readable
spine of the document: a custom service renders as prose with **no** *"Personal Data
processed:"* line and **no** *"Place of processing:"* line. And the two document IDs
are, unavoidably, two records — iubenda gives every language its own policy ID — but
they may or may not be *linked* translations that propagate edits to each other, and
that distinction is invisible from outside the dashboard.

---

## 1. Does the catalogue carry Open Food Facts, a self-hosted Supabase, or the AI providers?

**Two yes, three not found.** iubenda does not publish a complete browsable catalogue,
so this had to be answered from the generator's own legal changelog, which announces
each service as it is added.

**OpenAI is in, and has been since 2023.** From the *Privacy and Cookie Policy
Generator – Legal Changelog*, week of 12–16 June 2023:

> We've added a new hosting and backend infrastructure service to our Privacy and
> Cookie Policy Generator: OpenAI API

**Supabase is in, in both flavours, including the self-hosted one.** Week of
23–27 June 2025:

> We've added the following new hosting and backend services: Supabase, Supabase
> (self-hosted)

and, in the same entry:

> We've added the following new registration and authentication services: Supabase
> Auth, Supabase Auth (self-hosted)

That is directly load-bearing: the *"(self-hosted)"* suffix is an established house
convention in the catalogue, not a one-off — the same changelog carries `n8n
(self-hosted)`, `WordPress (self-hosted)`, `RudderStack (self-hosted)`, `GrowthBook
(self-hosted)`, `Piwik PRO Analytics Suite (self-hosted)`, `Piwik PRO Customer Data
Platform (self-hosted)` and `vtenext Business (self-hosted)`. So the backend this
project operates is not a service iubenda has never heard of. It has a catalogue entry
built for exactly the case where the developer runs the instance.

**Anthropic, OpenRouter and Open Food Facts: not found, but "not found" is weaker than
it looks.** The changelog contains no occurrence of *Anthropic*, *Claude*,
*OpenRouter*, *Hugging Face*, *Mistral*, *Vertex*, *Cohere*, *Groq*, *Replicate*,
*Ollama*, *Azure OpenAI*, or *Food*. Two caveats make this evidence rather than proof:

- The changelog's oldest entry is *Week January 10-14, 2022* and its newest is
  *Week 21 July – 25 July 2025*. It is 241 weekly entries covering roughly three and a
  half years, and it has not been added to for about thirteen months as of today.
  Anything added since July 2025 would not appear.
- The [alphabetical service guide](https://www.iubenda.com/en/help/20713-individual-services/)
  is explicitly partial and cannot be used as a catalogue index either:
  > The list is not yet complete (as creating posts for each of the 1700+ posts takes
  > quite some time), but we will continue to update as we go along.

**What would settle it: typing each name into the generator's own service search in
the dashboard.** That is a thirty-second check for whoever holds the account and it is
the only authoritative answer; no public surface exposes the catalogue for querying.
Note also that the catalogue is claimed at *"over 1700"* on one page and *"over
2,000"* on another, so even iubenda's own marketing copy is not a stable index of it.

## 2. What is the mechanism for a service iubenda has never heard of?

**A "custom service": a name, one free-text box, and an optional purpose tag.** That is
the whole of it. From
[*How to Add a Custom Service and Customize to Your Needs*](https://www.iubenda.com/en/help/386-how-to-add-a-custom-service-and-customize-to-your-needs/):

> The "custom service" is simply a clause that contains details of an additional data
> collection activity that you participate in, written in your own words

The **mandatory** fields are exactly two:

> **Service name.** Here you enter the title of your custom service. Try to make it
> precise but brief.

> **Privacy Policy.** This is where you'll describe the types of data you are
> collecting, who this data is being shared with and if it's a third party service (if
> there is a third party involved, you'll need to include their headquarters – e.g.
> Germany – and privacy policy).

**Read that second quote carefully — it is the finding.** iubenda instructs you to put
the data types, the recipient, and the recipient's *headquarters* into **prose**. There
is no structured field for either. For a catalogue service, iubenda holds those as
data and renders them as fixed lines; for a custom service, they are whatever sentence
you typed.

**The optional *Purpose* field controls placement, not structure:**

> This field allows you to assign a purpose to your custom service with a simple
> click. [...] It includes a drop-down list of over 40 purposes

> Another great benefit of applying this option is that it allows the custom services
> it's applied to, to be displayed alongside all other services in your policy (instead
> of being positioned in a separate section).

> The default value of "No specific purpose" will apply if a purpose is not assigned.
> If you did not assign a purpose to your custom service, you'll find the data
> collection practices outlined in a highlighted area of the privacy policy called
> "Further Information about Personal Data".

So an untagged custom service is quarantined into a trailing section; a tagged one sits
under a real purpose heading among the catalogue services.

### Does a custom entry render into the personal-data-categories list and the place-of-processing list?

**No — and this is confirmed against a live document, not inferred.** The help centre
never states it, so it was checked against a real iubenda policy that uses both
mechanisms side by side:
[TruTech Tools, LTD.](https://www.iubenda.com/app/privacy-policy/62541747/legal?from_cookie_policy=true).

A catalogue service immediately above renders with the structured spine intact:

> **HubSpot Chat (HubSpot Germany GmbH)**
> HubSpot Chat is a service for interacting with the HubSpot live chat platform
> provided by HubSpot Germany GmbH.
> Personal Data processed: Data communicated while using the service; Trackers; Usage
> Data. Place of processing: Germany – Privacy Policy.

The custom service immediately below it, under the same purpose heading, renders with
neither line:

> **AI Chat Data (App and Website)**
> This application and website include AI‑powered chat features that allow users to
> submit free‑text questions. User inputs are processed by third‑party service
> providers to generate responses and support customer interactions.
> For the mobile application, chat data is transmitted to Anthropic, which processes
> the data as a data processor for the purpose of generating AI responses.

No *"Personal Data processed:"*. No *"Place of processing:"*. Multi-paragraph free text
is clearly supported. The same document's *Further information about the processing of
Personal Data* section carries four more custom clauses (`AirCall`, `Barcode
Scanning`, `SearchSpring`, `User Account (Creation and Deletion)`), one of which runs
to seven numbered headings of the owner's own prose — so the box takes a great deal of
text, unstructured.

**Consequence for this app's documents.** The top-of-policy summary — on
[53501884](https://www.iubenda.com/privacy-policy/53501884) it reads

> Among the types of Personal Data that this Application collects, by itself or through
> third parties, there are: Usage Data; Storage permission; Reminders permission;
> Camera permission, without saving or recording; diagnostics; email address; app
> information; device logs; device information; Data communicated while using the
> service.

— is assembled from the structured fields of catalogue services. A custom service has
no structured fields, so **anything declared only as a custom service will not appear
in that list**, however carefully its prose is written. That is not stated in
iubenda's documentation; it follows from the form having no such field and is
consistent with every live rendering examined. **If a build ticket depends on a data
category reaching the summary list, that is worth a written question to iubenda
support before the work is scheduled.**

**Cost:** custom services require a paid tier.

> All pre-built clauses are available on every tier. Custom clauses are available on
> Advanced and Ultimate plans.

> If you have a Pro or Ultra license, you have full access to all services (unlimited
> clauses) for the duration of your license.

The account is at least Pro-equivalent: the read API returns `403` with *"To access
this privacy policy via API, convert it to Pro"* for non-Pro documents, and
`53501884` returns `200`. (The two help pages disagree slightly — *"With a PRO
license you can add as many custom services as you need"* on one, *"Advanced and
Ultimate"* on the other — which is legacy-vs-current pricing, not a contradiction that
affects this account.)

**One translation caveat, which matters here specifically:** custom services are the
one thing that does *not* propagate between languages. See §4.

## 3. Can a recipient be declared conditional?

**Not by the catalogue. Only by free text — which means only as a custom service.**

This is the load-bearing question and the documentation answers it by omission, so it
needs stating precisely.

**What a catalogue service can express is fixed and unconditional.** Every rendering
examined, in both languages, is the same three-part template: a name and provider, a
one-sentence description iubenda wrote, then *"Personal Data processed: …"* and
*"Place of processing: …"*. There is no toggle, no qualifier, no "if enabled" slot.
The help centre documents no per-service conditionality option anywhere, and the
per-policy options that do exist —
[*Picking the right privacy policy options*](https://www.iubenda.com/en/help/5858-switch-privacy-policy-options/)
— are about *whether a practice occurs at all* (profiling, automated decision-making,
the legal basis for transfers abroad), not about whether a given user triggers it. The
closest thing the catalogue has to conditionality is the transfer clause
*"Data Transfer abroad based on consent"*, and that qualifies the **legal basis**, not
the **occurrence**.

**What free text can express is anything, and the worked example above proves it in
practice.** The TruTech clause is already a conditional description of an AI
recipient — *"AI‑powered chat features that allow users to submit free‑text
questions"*, then Anthropic named as the recipient of what those users submit. Nothing
in the mechanism stops a clause reading, in the owner's own words, that a provider
receives data only where the user has enabled the feature and supplied their own
credential, and receives nothing otherwise.

**So the honest formulation is: the AI providers can be described truthfully, but only
by giving up the structured listing for them.** A custom clause can carry the
conditionality, the user-supplied-key detail, and the fact that the endpoint address is
never known to the project. What it cannot do is put those providers in the same
machine-readable shape as TestFlight and Sentry, because that shape has no room for the
qualifier. There is no third option in the generator.

**What the documentation does not answer, and what would:** whether iubenda's legal
team considers a conditional custom clause an acceptable substitute for a service
entry under GDPR Art. 13/14, and whether a recipient the *user* chooses and
authenticates is a recipient of the *owner's* processing at all. Both are legal
questions about the drafting, not questions about the tool, and both want a written
answer from iubenda support (or the project's own reading recorded as a decision) —
they cannot be resolved by reading the help centre.

## 4. Are two IDs necessarily two independent configurations?

**Two IDs are unavoidable; two independent *configurations* are not — but which of the
two situations these documents are in cannot be determined from outside.**

**iubenda has no single-ID multilingual policy.** The creation API's documented output
is a list, one entry per language, each with its own `id` and its own `policy_url`:

> `"privacy_policies" => [ // hashing array, one for each privacy policy that was
> added, each hash has the following structure: { "id" => … "lang" => … "policy_url"
> => … } ]`

and its own example returns exactly that shape for a policy with `"lang" => "it"`. So
`53501884` and `53922100` being separate numbers proves nothing either way — a *linked*
German translation of the English policy would also have its own number.

**iubenda does support one policy source rendered in several languages, and edits
propagate.** From
[*How to Add Another Language to Your Documents*](https://www.iubenda.com/en/help/137-add-language/):

> Any change made in any language of the privacy policy/terms and conditions will be
> automatically added to the other languages (except, as anticipated a little earlier,
> any custom services).

and the dedicated FAQ,
[*Must I Repeat the Process of Adding Services for Every Language…*](https://www.iubenda.com/en/help/3803-must-i-repeat-the-process-of-adding-services-for-every-language-in-which-i-generate-the-policy),
answers its own title:

> If you own a multilingual site or app **it is not necessary** to do so.

> the same data controller and the same list of services of the "original" version,
> except for any custom services that you may have written, which, as it was written by
> you, will have to be recreated by you for the new language.

Available languages are:

> Czech, Danish, Dutch, US English, UK English, French, German, Greek, Italian, Polish,
> Portuguese, Brazilian Portuguese, Russian, Spanish, or Swedish

German is among them. Adding a language is a button —
*"Add language" in the "Manage languages" box on the edit page"* — so if the two
documents are **not** currently linked, there is a supported destination to migrate
toward, though the docs describe adding a language to an existing document, not
merging two existing documents. **Whether an already-separate German document can be
folded into the English one's language set, as opposed to being deleted and re-added
as a translation (which would change its public ID and break every link to
`53922100`), is not documented. That is a question for iubenda support in writing, and
it should be asked before anyone plans the migration.**

**What the live URLs show.** Both were fetched and compared:

- No `hreflang`, no alternate-language `<link>`, no language switcher in either
  document. Each `<link rel="canonical">` points at itself:
  `…/privacy-policy/53501884` and `…/privacy-policy/53922100`. The only cross-document
  links are to *iubenda's own* policy, localised (`65675001` from EN, `45483222` from
  DE) — nothing to do with this project.
- `/privacy-policy/53501884/legal` and `/…/full-legal` both return `200`, but they are
  **rendering variants of the same document in the same language** — `/legal` serves
  `<html lang="en">` with the same `<h1>`. There is no language variant at a path.
- The two documents are currently **in perfect sync**: identical section structure,
  the same five services (TestFlight, Google Play Beta Testing, Sentry, Google Play
  Store, App Store Connect), the same three device permissions, and the same stamp —
  *"Latest update: June 10, 2026"* / *"Letzte Aktualisierung: 10. Juni 2026"*. Only the
  ordering of purpose headings differs, and that is alphabetisation per language
  (EN puts *Infrastructure monitoring* before *Platform services and hosting*; DE puts
  *Plattform-Dienste und Hosting* before *Überwachung der Infrastruktur*).

**That sync is consistent with linked translations and equally consistent with
disciplined manual duplication, so it settles nothing.** The distinction is visible in
one place only: the *Manage languages* box on the document's edit page in the
dashboard. **Whoever holds the account can answer this in one look, and the map should
treat it as an open fact rather than assume either way.**

**The one thing that is certain either way:** even under a linked multilingual setup,
*custom services do not propagate*. Every clause written for Open Food Facts, for a
user-run endpoint, or for an AI provider will have to be written **twice**, once in
English and once in German, and will drift independently thereafter. iubenda offers
only a *"Specify service translations"* checkbox on the custom-service form —
> By checking the "Specify service translations" box, you can localize the custom
> service and use a different name and description based on the languages in which you
> are generating your policy.

— which is a manual second text box, not a translation. Its own advice is to use DeepL
or Google Translate and then *"consult with a native to make sure that the
translations are ok"*.

## 5. The last-updated date, and version history

**The date is automatic on edit, with a manual override; there is no version history.**

From
[*How to Force Update & Change the "Last updated" Date Information*](https://www.iubenda.com/en/help/4158-force-update-and-changing-the-last-updated-date-information):

> Whenever you change your privacy policy and terms & conditions in our generator, this
> is not needed. In those cases (in 99.9% of cases), the generator takes care of this
> for you.

There are exactly two ways to move it:

> (1) You can change your privacy policy/terms and conditions by adding something new
> or by removing something from your existing document

> (2) We've made a dedicated button for this exact use case

which

> will flush the cache and update the date on your privacy policy/terms and conditions
> to now/today.

and lives at *Dashboard > [your website] > Edit > Advanced Settings*.

**Version history: absent from the documentation entirely.** Neither the force-update
page nor [*How to Edit a Privacy Policy*](https://www.iubenda.com/en/help/2739-edit-privacy-policy/)
mentions retained versions, an archive, diffs, or a citable previous revision;
2739 says only that

> Changes are often required and can be done anytime

**This is a genuine gap, not an inference.** No iubenda help page examined states
either that history is kept or that it is discarded. What the generated policy itself
promises the user is a *date*, not a history — from `53501884`:

> It is strongly recommended to check this page often, referring to the date of the
> last modification listed at the bottom.

**What would answer it: a question to iubenda support in writing.** Until then, the
only linkable record of what the policy said on a given day is a third-party archive
(e.g. the Wayback Machine), which is outside iubenda and outside the project's control.
If the map wants users to be able to see *what changed* — as opposed to *that
something changed* — that capability has to be built somewhere other than iubenda, for
example a changelog in this repository that the policy links to.

## 6. Export or API for reviewing the configuration as text

**There is a public read API, and it returns the rendered document — not the
configuration.** From
[*Adding iubenda's Privacy Policy to Your Site: Direct Text Embedding and API*](https://www.iubenda.com/en/help/78-privacy-policy-direct-text-embedding-api/),
three endpoints:

- `https://www.iubenda.com/api/privacy-policy/:public_id`
- `https://www.iubenda.com/api/privacy-policy/:public_id/only-legal`
- `https://www.iubenda.com/api/privacy-policy/:public_id/no-markup`

with the response shape

> `{ :success => true, :content => "… privacy policy content …" }`

and, for documents below the required tier,

> `{ :success => false, :error => "To access this privacy policy via API, convert it to
> Pro" }`

**Verified live on 2026-08-27.** `GET https://www.iubenda.com/api/privacy-policy/53501884`
returns `{"success":true,"content":"…"}` with the policy's HTML, and the `/no-markup`
variant returns the same text in a lighter wrapper. So both documents *can* be diffed
and reviewed as text without touching the dashboard, and both can be pulled by CI.

**But `content` is HTML, not structure.** It is the rendered output, so a review
against it reads the same sentences a user reads. That is the right artefact for
checking *what the policy says*; it is not an export of *which services are ticked,
with which purposes and data categories*. Nothing in the public documentation exposes
the latter:

- The [creation API](https://www.iubenda.com/en/help/61591-api-docs-create-and-recall-a-privacy-policy/)
  is titled *"create and recall"* but documents only `POST api/transactions` with
  `type => create_privacy_policy`. There is no documented `GET` for a policy's
  configuration.
- iubenda ships an MCP connector for Claude and ChatGPT with
  > 28 tools your assistant can use, from setting up a site to running scans

  advertising *"Check what's already set up on my site"* and *"Add Google Analytics to
  my policy"*. **Whether any of those 28 tools returns a configuration as structured
  data is not stated on the public page, and the tool list is not published.** That is
  the one plausible route to a JSON view of the configuration, and it would take either
  reading iubenda's connector documentation once connected, or a question to support,
  to know.

The generated pages also carry a *"Download PDF"* control, which is an export for a
human reader and not a reviewable diff.

---

## What this constrains

**#867's downstream questions that are now bounded:**

- **"Add the missing processors" is two different jobs, not one.** The self-hosted
  Supabase backend can be a proper catalogue service with a structured
  *Personal Data processed* / *Place of processing* line, because
  `Supabase (self-hosted)` exists. Anything not in the catalogue cannot, and drops to
  prose. Confirm each name in the dashboard's service search before scoping the work —
  that check costs seconds and changes what the ticket is.
- **The AI providers cannot be described truthfully *and* structurally.** Any spec that
  assumes a "conditional recipient" checkbox is specifying something the generator does
  not have. The choice is a free-text custom clause that says the true, conditional
  thing but sits outside the structured lists, or a catalogue entry that lists the
  provider unconditionally and is therefore false for the ~all users who never enable
  the feature. That is a decision for the map, and it should be taken explicitly rather
  than discovered during implementation.
- **Whatever is added as a custom service is added twice and drifts.** Any correction
  plan must carry an EN and a DE version of every custom clause, and must expect them
  to diverge over time. Catalogue services do not have this problem — those propagate.
- **"Migrate to one multilingual source" is not yet a scopeable ticket.** It rests on
  two unknowns: whether `53501884` and `53922100` are already linked (one look at the
  dashboard), and whether two separate documents can be merged without re-issuing the
  German public ID (a question to iubenda support). The second one has a real cost
  attached — a changed ID breaks every existing link to the German policy, including
  any already shipped in the app or on the store listings.
- **"Point users at what changed" cannot be satisfied by iubenda.** The generator
  offers a date and, undocumented, possibly nothing else. If the map wants a citable
  history, it has to live in this repository.
- **Review-as-text is solved, review-as-configuration is not.** Both documents are
  fetchable as text over a public API today, so a corrected policy can be diffed in
  CI. Verifying the *configuration* behind it still means clicking through the form,
  unless the MCP connector turns out to expose it.

---

## Sources

- [How to Add a Custom Service and Customize to Your Needs — iubenda help](https://www.iubenda.com/en/help/386-how-to-add-a-custom-service-and-customize-to-your-needs/)
- [How to Add Services to Your Privacy Policy — iubenda help](https://www.iubenda.com/en/help/20-services-privacy-policy/)
- [Privacy and Cookie Policy Generator – Legal Changelog — iubenda help](https://www.iubenda.com/en/help/30061-pcp-legal-changelog/)
- [Compliance for Individual Services — iubenda help](https://www.iubenda.com/en/help/20713-individual-services/)
- [How to Add Another Language to Your Documents — iubenda help](https://www.iubenda.com/en/help/137-add-language/)
- [Must I Repeat the Process of Adding Services for Every Language…? — iubenda help](https://www.iubenda.com/en/help/3803-must-i-repeat-the-process-of-adding-services-for-every-language-in-which-i-generate-the-policy)
- [How to Force Update & Change the "Last updated" Date Information — iubenda help](https://www.iubenda.com/en/help/4158-force-update-and-changing-the-last-updated-date-information)
- [How to Edit a Privacy Policy — iubenda help](https://www.iubenda.com/en/help/2739-edit-privacy-policy/)
- [Picking the right privacy policy options — iubenda help](https://www.iubenda.com/en/help/5858-switch-privacy-policy-options/)
- [Adding iubenda's Privacy Policy to Your Site: Direct Text Embedding and API — iubenda help](https://www.iubenda.com/en/help/78-privacy-policy-direct-text-embedding-api/)
- [API docs: create and recall a privacy policy — iubenda help](https://www.iubenda.com/en/help/61591-api-docs-create-and-recall-a-privacy-policy/)
- [iubenda for Claude and ChatGPT](https://www.iubenda.com/en/iubenda-for-claude-and-chatgpt/)
- [OpenNutriTracker privacy policy, English (53501884)](https://www.iubenda.com/privacy-policy/53501884)
- [OpenNutriTracker privacy policy, German (53922100)](https://www.iubenda.com/privacy-policy/53922100)
- [Privacy Policy of TruTech Tools, LTD. — live example of custom vs. catalogue rendering](https://www.iubenda.com/app/privacy-policy/62541747/legal?from_cookie_policy=true)

**Not usable as sources:** `support.iubenda.com` forum threads (including the public
requests to add Supabase and other services) redirect to an OAuth login and cannot be
read without an account.
