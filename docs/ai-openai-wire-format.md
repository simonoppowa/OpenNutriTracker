# Which OpenAI API, and what does its wire format demand?

**Verdict: build the direct client on the Responses API (`POST
https://api.openai.com/v1/responses`), not on Chat Completions — and send
`store: false` on every request.** OpenAI recommends Responses in three
separate places in its own reference, and the choice removes a problem rather
than adding one: on Chat Completions, `max_tokens` is already deprecated and
`reasoning: none` is incompatible with tool calling on the models this feature
would actually use.

**The storage objection is real and does not change the answer.** A parallel
reading for [#680](https://github.com/simonoppowa/OpenNutriTracker/issues/680)
found that `/v1/responses` stores by default and concluded the app should use
Chat Completions instead. The first half is correct — verified, quoted in
[A2](#a2-the-storage-default). The second
half does not follow, for three documented reasons: **Chat Completions has a
storage default too** (*"Chat completions are stored by default for new
accounts"* — and a user creating an account to use this app is a new account);
**the retention that actually holds the meal text and the photograph is
abuse-monitoring retention, which is 30 days on both endpoints and is not
governed by `store` at all**; and **`store: false` is documented for both**, so
the delta is a field the client sends, not an endpoint it picks. Choosing Chat
Completions to avoid a parameter you have to send anyway costs the tool-calling
combination this feature needs.

**But the port is larger than the map assumed.** The map's note that
`OpenRouterMealItemsApi` is *"the OpenAI-compatible shape"* is true of **Chat
Completions**, which is not the API to build on. Against Responses, the
existing client agrees on almost nothing at the wire level: not the endpoint,
not the message array, not the tool wrapper, not the token field, not the
response envelope, not the failure signal. The parts that survive unchanged are
the JSON Schema itself, the `arguments`-as-a-string decode, and the data-URI
image. **Everything else is a rewrite**, which bears directly on
[#685](https://github.com/simonoppowa/OpenNutriTracker/issues/685) — a shared
"OpenAI dialect" base with OpenRouter would be sharing a dialect neither client
speaks.

Three findings the existing code has backwards, each documented below:

1. **404 is not a capability refusal on OpenAI.** OpenAI documents no 404 for
   this endpoint at all, and documents capability as a *property of the model*,
   listed per model in the docs. `isCapabilityRefusal` has nothing to detect.
2. **429 is not reliably transient**, and **403 is not an auth failure.** 429
   carries billing and quota exhaustion — *"Retrying billing, spend, or quota
   errors won't restore API access"* — and the only documented 403 is
   *"Country, region, or territory not supported"*.
3. **A failed generation can arrive as HTTP 200**, exactly as it does on
   OpenRouter, but with a different shape: `status: "failed"` plus a top-level
   `error` object. There is no `finish_reason: "error"` — that value does not
   exist in OpenAI's enum, and Responses has no `finish_reason` field at all.

The strict-mode answer is in [Section F](#f-strict-mode). Short version: the
nullable union **is** the sanctioned way to express an optional field, the
documentation says so in as many words, and the objection recorded in
`openrouter_meal_items_api.dart` — that `required` would oblige the model to
produce a number for every item — does not survive it. That is for
[#683](https://github.com/simonoppowa/OpenNutriTracker/issues/683) to decide,
not this note.

## How this was read

Primary sources only, all read on **2026-08-16** from `developers.openai.com`.
`platform.openai.com/docs` now redirects there.

Every page on that site publishes a Markdown twin — *"Markdown versions of
documentation pages are available by appending `.md` to the page URL"* — and
every quote below was taken from that twin and then grep-verified verbatim
against the downloaded file rather than transcribed from a rendering or a
summary. Where the documentation is silent, this note says silent. It does not
fill the gap with what OpenRouter does; that is the mistake the ticket was
written to avoid.

No live call was made and no key was used. [#684](https://github.com/simonoppowa/OpenNutriTracker/issues/684)
covers probing, and [Not established](#not-established-without-a-live-call)
lists what it has to settle.

| Page read | URL |
| --- | --- |
| Function calling | [`/api/docs/guides/function-calling`](https://developers.openai.com/api/docs/guides/function-calling) |
| Structured model outputs | [`/api/docs/guides/structured-outputs`](https://developers.openai.com/api/docs/guides/structured-outputs) |
| Images and vision | [`/api/docs/guides/images-vision`](https://developers.openai.com/api/docs/guides/images-vision) |
| Migrate to the Responses API | [`/api/docs/guides/migrate-to-responses`](https://developers.openai.com/api/docs/guides/migrate-to-responses) |
| Error codes | [`/api/docs/guides/error-codes`](https://developers.openai.com/api/docs/guides/error-codes) |
| Rate limits | [`/api/docs/guides/rate-limits`](https://developers.openai.com/api/docs/guides/rate-limits) |
| Reasoning | [`/api/docs/guides/reasoning`](https://developers.openai.com/api/docs/guides/reasoning) |
| Deprecations | [`/api/docs/deprecations`](https://developers.openai.com/api/docs/deprecations) |
| How we use your data | [`/api/docs/guides/your-data`](https://developers.openai.com/api/docs/guides/your-data) |
| Chat Completions — Get | [`/api/reference/resources/chat/subresources/completions/methods/retrieve`](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/retrieve) |
| API Overview (auth, headers) | [`/api/reference/overview`](https://developers.openai.com/api/reference/overview) |
| Responses — Create | [`/api/reference/resources/responses/methods/create`](https://developers.openai.com/api/reference/resources/responses/methods/create) |
| Chat — Create chat completion | [`/api/reference/resources/chat`](https://developers.openai.com/api/reference/resources/chat) |
| Chat Completions Overview | [`/api/reference/chat-completions/overview`](https://developers.openai.com/api/reference/chat-completions/overview) |
| Models, and per-model pages | [`/api/docs/models`](https://developers.openai.com/api/docs/models) |

## What differs from the existing OpenRouter client

Read against
[`openrouter_meal_items_api.dart`](../lib/features/add_meal/data/openrouter_meal_items_api.dart)
line by line. "Same" means the byte-level shape is identical and the code
transfers unchanged.

| What | `OpenRouterMealItemsApi` sends today | Direct OpenAI, Responses API | Same? |
| --- | --- | --- | --- |
| Endpoint | `openrouter.ai/api/v1/chat/completions` | `api.openai.com/v1/responses` | no |
| Auth header | `authorization: Bearer …` | `Authorization: Bearer …` | **yes** |
| Version header | none | none required | **yes** |
| System prompt | first element of `messages`, `role: "system"` | top-level `instructions` string | no |
| User content | `messages[].content` | `input[].content` | no |
| Text part | `{"type": "text", "text": …}` | `{"type": "input_text", "text": …}` | no |
| Image part | `{"type": "image_url", "image_url": {"url": "data:…"}}` | `{"type": "input_image", "image_url": "data:…"}` | no — flattened |
| Part order | text, then image | docs are **silent**; every example is text, then image | effectively yes |
| Tool wrapper | `{"type":"function","function":{name, description, parameters}}` | `{"type":"function", name, description, parameters}` | no — *"externally tagged"* vs *"internally tagged"* |
| Forced tool | `{"type":"function","function":{"name": …}}` | `{"type":"function","name": …}` | no |
| Token cap | `max_tokens` | `max_output_tokens` | no |
| Token cap covers | visible output | visible output **+ reasoning tokens** | no |
| `strict` omitted means | non-strict | **attempts strict**, falls back | no |
| Routing block | `provider: {require_parameters, data_collection, only}` | no equivalent; drop it | no |
| Metadata header | `x-openrouter-metadata: enabled` | no equivalent; drop it | no |
| Storage | not applicable | **stored by default**, 30 days; must send `store: false` ([A2](#a2-the-storage-default)) | new field |
| Success envelope | `choices[0].message.tool_calls[]` | `output[]`, filtered on `type == "function_call"` | no |
| Tool `arguments` | JSON **string** | JSON **string** | **yes** |
| Schema (`mealItemsToolSchema`) | plain JSON Schema | plain JSON Schema | **yes** |
| Failure-as-200 | `finish_reason: "error"` + `choice.error.code` | `status: "failed"` + top-level `error.code` | different shape, same hazard |
| `finish_reason` | OpenRouter adds `"error"` | field does not exist on Responses | no |
| 404 | capability refusal | undocumented for this endpoint | no |
| 403 | treated as auth failure | documented only as geo-block | no |
| 429 | treated as transient | transient **or** terminal billing/quota | no |
| 422 | treated as non-retryable | documented as *"Please try the request again"* | inverted |

## A. Which API

**Settle this first, because it changes every other answer.** Both APIs support
function calling and image input; the reference marks them both "Supported" on
every current model page. So this is not a capability decision — it is a
direction-of-travel decision, and OpenAI has signposted it clearly.

**The recommendation, verbatim.** Migration guide, first line under the title:

> **While Chat Completions remains supported, Responses is recommended for all
> new projects.**

The reference repeats it on the endpoint itself. Both
`/api/reference/chat-completions/overview` and the `Create chat completion`
method page open with the same block:

> **Starting a new project?** We recommend trying [Responses] to take advantage
> of the latest OpenAI platform features.

And the API Overview's *"Start here"* list, step 1 — *"Choose the API surface
for your application"* — offers three: Responses *"for direct model requests,
tool use, audio, image, and text inputs, and stateful interactions"*, Realtime,
and Administration. **Chat Completions is not among them.** It survives in the
reference index as a one-page overview with no `create` method page of its own;
the full parameter list lives under `/api/reference/resources/chat`.

**Neither is deprecated, and neither is tagged legacy.** I read the whole
deprecations page. Chat Completions appears nowhere on it, in neither the
upcoming nor the historical sections. The page defines the term it does not
apply here:

> We use the term "legacy" to refer to models and endpoints that no longer
> receive updates. We tag endpoints and models as legacy to signal to
> developers where we're moving as a platform and that they should likely
> migrate to newer models or endpoints.

The endpoint that *is* tagged legacy is `/v1/completions` — the 2023
freeform-prompt endpoint, unrelated. The Assistants API is genuinely
deprecated, *"with a sunset date of August 26, 2026"*. Chat Completions is
neither. So this is a recommendation, not a deadline, and a Chat Completions
client would not stop working.

**What each demands differently for this exact call.** Beyond the table above,
two differences are decisive rather than cosmetic:

- **Reasoning models and tool calling on Chat Completions.** *"Starting with
  GPT-5.4, tool calling is not supported in Chat Completions with `reasoning:
  none`."* Every current cheap model — `gpt-5.4-nano`, `gpt-5.6-luna` — is a
  reasoning model with `reasoning.effort` support. On Chat Completions you
  therefore cannot combine "don't think, just extract" with a forced tool call.
  On Responses you can. For a one-shot tokeniser with no conversation, that is
  the difference between paying for reasoning tokens on every meal line and
  not.
- **`max_tokens` is already deprecated on Chat Completions** ([Section
  D](#d-token-limits)). Porting the current `_maxTokens = 1024` constant
  straight across would send a deprecated field on day one.

**What Chat Completions would cost this app, confirmed rather than assumed.**
Almost everything on OpenAI's own Responses benefits list is irrelevant here —
built-in tools, the agentic loop, `previous_response_id`, the Conversations
API, stateful context, encrypted reasoning replay, background mode, streaming.
This is one request with no history, so none of it applies. Three things do:

- **Tool calling with `reasoning: none`.** *"Starting with GPT-5.4, tool
  calling is not supported in Chat Completions with `reasoning: none`."* This
  is the concrete cost, and it lands squarely on this feature: every candidate
  model is a GPT-5.4-or-later reasoning model, and the call is a one-shot
  tokenisation that wants no thinking at all. On Chat Completions the app would
  pay for reasoning tokens on every meal line or drop to an older model.
- **`max_tokens` is deprecated** there, so the constant would have to be
  renamed at once anyway ([Section D](#d-token-limits)).
- **`detail: "original"` is Responses-only** — the Chat Completions `detail`
  enum in the reference is `auto | low | high` ([Section C](#c-images)).

Nothing suggests Chat Completions is feature-frozen in a way that would bite
later; it is simply not where new features land first (*"We recommend migrating
all flows to the Responses API over time to take advantage of the latest OpenAI
features and improvements"*). The migration guide's capability comparison table
would settle this directly, but its check/cross glyphs are images that the
Markdown twin strips, leaving the columns blank — so **it is not usable as
evidence** and is not cited here.

**The one honest argument from familiarity** is that Chat Completions is what
the app already speaks, so `OpenRouterMealItemsApi` could be subclassed or
parameterised. The divergence table is the answer: against Responses the
overlap is three items, and against Chat Completions the overlap would be real
but bought by building the app's newest client on the surface OpenAI tells you
not to start new projects on.

### A2. The storage default

This is the only argument against Responses with real weight behind it, it came
from the parallel [#680](https://github.com/simonoppowa/OpenNutriTracker/issues/680)
reading rather than from this one, and it is half right.

**1. `store` genuinely defaults to true on `/v1/responses`. Confirmed.** Note
first where it is *not* documented: the create reference gives the parameter as
`store: optional boolean or null`, *"Whether to store the generated model
response for later retrieval via API"*, and **states no default**. The same is
true of the Chat Completions entry. The default lives in prose on two other
pages. The operative one, from the per-endpoint retention detail under
`/v1/responses`:

> The Responses API has a 30 day Application State retention period by default,
> or when the `store` parameter is set to `true`. Response data will be stored
> for at least 30 days.

"By default" and "at least 30 days" are both OpenAI's words. The claim is
correct.

**2. `/v1/chat/completions` has a storage default too, which is where the
comparison breaks.** The migration guide says it three times, in identical
words each time:

> Responses are stored by default. Chat completions are stored by default for
> new accounts. To disable storage in either API, set `store: false`.

Stored chat completions are real objects, not a figure of speech — `GET
/chat/completions/{completion_id}` exists, and *"Only Chat Completions that
have been created with the `store` parameter set to `true` will be returned."*
And the purpose OpenAI documents for that storage reads, if anything, worse
than the Responses one: *"Whether or not to store the output of this chat
completion request for use in our model distillation or evals products."*
Against Responses' *"for later retrieval via API"*.

**There is a genuine inconsistency inside OpenAI's own documentation here, and
it should be recorded rather than resolved.** The per-endpoint retention table
lists `/v1/chat/completions` application state retention as *"None, see below
for exceptions"*, and its exception bullets — audio outputs, ZDR, image inputs,
prompt caching — contain **no** store-driven retention period, while
`/v1/responses` gets the explicit 30-day bullet quoted above. So the retention
page implies chat completions retain nothing by default; the migration guide
says they are stored by default for new accounts; the reference confirms stored
chat completions exist and are retrievable. All three are current. **Neither
this note nor #680 can say how long a stored chat completion is kept, because
OpenAI does not say.**

**3. `store: false` does not suppress everything — and what it fails to
suppress is identical on both endpoints.** Three retentions survive it, and all
three are listed against `/v1/chat/completions` and `/v1/responses` in the same
words:

- **Abuse monitoring, 30 days.** *"By default, abuse monitoring logs are
  generated for all API feature usage and retained for up to 30 days"*, and the
  endpoint table gives both endpoints "30 days" in that column. Reducing it
  requires Zero Data Retention or Modified Abuse Monitoring, both *"subject to
  prior approval by OpenAI"* — unavailable to an individual with a personal key.
- **CSAM scanning of image inputs**, applied to `/v1/responses` and
  `/v1/chat/completions` alike: *"Image and file inputs are scanned for CSAM
  content upon submission. If the classifier detects potential CSAM content,
  the image will be retained for manual review, even if Zero Data Retention,
  Modified Abuse Monitoring, or Eyes Off is enabled."*
- **Prompt caching**, *"encrypted key/value tensors in GPU-local storage"*, not
  retained past 24 hours — listed identically under both.

**This is what decides it.** The thing the README's privacy claim is actually
about — where the user's meal text and photograph go and how long they are kept
— is governed by abuse-monitoring retention, which is 30 days on both endpoints
and which `store` does not touch. The `store` delta is a separate, additive
30-day application-state retention that the client removes with one field. So
the two APIs are not materially different in retention once `store: false` is
sent; they are different in what happens if you forget to send it.

One asymmetry does survive: under `/v1/responses` only, *"When Zero Data
Retention is not enabled for an organization, all queries use extended prompt
caching for all supported models."* There is no chat-completions counterpart.
It concerns encrypted GPU-local tensors with a 24-hour ceiling rather than
conversation state, so it does not change the conclusion, but it is a real
Responses-specific residue and #680 should have it.

**4. Omitting `store` is unsafe on *both*, which inverts the argument.** On
Responses, omitting it stores. On Chat Completions, omitting it stores *for new
accounts* — meaning the behaviour of an app that omits the field depends on
when its user opened their OpenAI account, which is worse for a client author
than a default that is merely wrong. **Send `store: false` explicitly on
whichever endpoint is chosen**, and once it is sent, the storage argument for
preferring Chat Completions is spent. What remains is a defence-in-depth
argument — that forgetting the field fails less badly on Chat Completions — and
that is an argument for a test asserting the field is present, not for an API.

**Recommendation unchanged: Responses, with `store: false` non-negotiable.**
Two research notes reaching different conclusions from the same page is worth
surfacing rather than smoothing over: #680's finding about the Responses
default is sound and this note adopts it, and its inference that Chat
Completions is therefore the safer endpoint is not supported by the retention
table it came from.

## B. Forced tool calls

**The shape.** Responses takes the function name at the top level of the
`tool_choice` object, with no nested `function` wrapper:

> **Forced Function:** Call exactly one specific function.
> `tool_choice: {"type": "function", "name": "get_weather"}`

The reference calls this `ToolChoiceFunction` and describes it as *"Use this
option to force the model to call a specific function."*

Chat Completions uses the nested form, and this is one place the existing
client's assumption **holds exactly** — the reference gives the same bytes it
sends:

> Specifying a particular tool via `{"type": "function", "function": {"name":
> "my_function"}}` forces the model to call that tool.

**Guarantee or preference? The documentation will not say, and the answer
matters less than it looks.** "Call exactly one specific function" is
imperative, and `ToolChoiceFunction` says "force". But nothing in the guide or
the reference states that a forced tool call *excludes* a text message from the
same turn, and the surrounding text cuts slightly the other way. The
handling section says:

> Since model responses can include zero, one, or multiple calls, it is best
> practice to assume there are several.

and the reference describes `output` as:

> An array of content items generated by the model.
> - The length and order of items in the `output` array is dependent on the
>   model's response.
> - Rather than accessing the first item in the `output` array and assuming
>   it's an `assistant` message with the content generated by the model, you
>   might consider using the `output_text` property where supported in SDKs.

So OpenAI's own advice is that `output` is heterogeneous and position-dependent
reads are wrong. On a reasoning model it is heterogeneous *by construction* — a
`reasoning` item precedes the `function_call` item. **A direct client must
iterate `output` and select `type == "function_call"`**, exactly as
`_itemsFrom` iterates `tool_calls` today. It must not index `output[0]`.

**Prose is detectable, which is what the no-macros guarantee actually needs.**
It does not need prose to be impossible. A text answer arrives as an output
item of `type: "message"`, never as a `function_call`, so a client filtering on
`function_call` sees no tool call and raises — which is the behaviour
`MealInterpreterException('response has no tool call')` already has. A
safety refusal is likewise structurally distinct: it arrives as a content part
of `type: "refusal"` inside a message item, described as *"A refusal from the
model"* carrying *"The refusal explanation from the model"*. Both are
message-shaped; neither can be mistaken for tool arguments.

**And the guarantee never rested on `tool_choice` anyway.** It rests on
`mealItemsToolSchema` having no macro fields, so there is no key a calorie
count could be written into, and on `validateParsedMealItems` bounding
everything that comes back. A model that ignored the forced tool and answered
in prose would produce a handled error, not a wrong number. Structured Outputs
is explicit that schema adherence is not semantic correctness:

> Structured Outputs can still contain mistakes.

and

> The model will always try to adhere to the provided schema, which can result
> in hallucinations if the input is completely unrelated to the schema.

That second sentence is worth carrying into
[#684](https://github.com/simonoppowa/OpenNutriTracker/issues/684): the
empty-answer rule — a photo with no food in it — is precisely the "input
unrelated to the schema" case, and the documentation predicts the model will
invent items rather than return none. The prompt has to say what to do
instead; the docs say so directly (*"You could include language in your prompt
to specify that you want to return empty parameters"*).

`parallel_tool_calls: false` is available and documented as ensuring *"exactly
zero or one tool is called"* — worth sending, though with a single tool defined
it buys little.

## C. Images

**Data URI or hosted URL — both, plus a third option.**

> You can provide images as input to generation requests in multiple ways:
> - By providing a fully qualified URL to an image file
> - By providing an image as a Base64-encoded data URL
> - By providing a file ID (created with the Files API)

The reference field description is the operative one for a client that holds
bytes: `image_url` is *"The URL of the image to be sent to the model. A fully
qualified URL or base64 encoded image in a data URL."* The documented data-URI
form matches what the app already builds — the Python example sends
`f"data:image/jpeg;base64,{base64_image}"`. Only the *envelope* changes: on
Responses the field is a bare string on the part, not a nested
`image_url: {url: …}` object.

The hosted-URL and file-ID routes are both wrong for this app for the same
reason the photo is never written to disk: they would put the photograph
somewhere it can be fetched from.

**WebP is supported, explicitly and by name.** From the image input
requirements table:

> Supported file types: PNG (`.png`) - JPEG (`.jpeg` and `.jpg`) - WEBP
> (`.webp`) - Non-animated GIF (`.gif`)

**Size limits are on the payload, not the image.**

> Size limits: Up to 512 MB total payload size per request - Up to 1500
> individual image inputs per request

Plus three requirements stated as prose rather than as validation:

> Other requirements: No watermarks or logos - No NSFW content - Clear enough
> for a human to understand

Note there is **no documented pixel-dimension ceiling that rejects an image**.
Dimensions are handled by resizing rather than refusal, per model — on
`gpt-5.4-nano` and the other small models, *"`high` allows up to 1,536 patches
or a 2048-pixel maximum dimension. If either limit is exceeded, we resize the
image while preserving aspect ratio."* The app's existing WebP downscale is
therefore a cost and latency optimisation on this path, not a compatibility
requirement.

**Detail settings.**

> The `detail` parameter tells the model what level of detail to use when
> processing and understanding the image (`low`, `high`, `original`, or
> `auto`). If you skip the parameter, the model will use `auto`. This behavior
> is the same in both the Responses API and the Chat Completions API.

with `low` documented as *"The model receives a low-resolution 512px x 512px
version of the image."* Two caveats for a client: `original` is *"Available on
`gpt-5.4` and future models"* only, and Chat Completions' `detail` enum in the
reference is `auto | low | high` — **`original` is Responses-only**. Which
level suits a plate of food is a question for
[#684](https://github.com/simonoppowa/OpenNutriTracker/issues/684) and not
answerable from documentation, though the guide's warning is suggestive:
*"`low` and `high` detail levels may resize the image before analysis, which
can obscure small details."*

**Ordering: the documentation is silent, and the OpenRouter client's comment
does not transfer.** `_contentJson` says text-before-image is *"what its own
image documentation recommends"* — that is a claim about OpenRouter's docs, and
I found **no equivalent recommendation anywhere in OpenAI's**. I searched the
images-vision, function-calling, structured-outputs and text guides for any
ordering guidance and there is none. What OpenAI does is show text first in
every single example, in every language binding, on both APIs. That is evidence
of a house style, not a documented requirement, and it happens to match what
the app already sends. **Keep text-first; do not claim the docs require it.**

One limitation belongs in the photo prompt's evidence file rather than here,
but it is directly on point for the counts-only rule:

> **Counting**: The model may give approximate counts for objects in images.

## D. Token limits

**On Responses the question does not arise: the field is `max_output_tokens`,
and `max_tokens` is not a Responses parameter at all.** It appears zero times
in the Responses create reference.

> `max_output_tokens: optional number or null`
> An upper bound for the number of tokens that can be generated for a response,
> including visible output tokens and reasoning tokens.

**On Chat Completions, `max_completion_tokens` is current and `max_tokens` is
deprecated.** Verbatim, from the `max_tokens` entry in the reference:

> This value is now deprecated in favor of `max_completion_tokens`, and is not
> compatible with [o-series models].

`max_completion_tokens` is described identically to the Responses field: *"An
upper bound for the number of tokens that can be generated for a completion,
including visible output tokens and reasoning tokens."*

**What happens if the wrong one is sent: the docs say only "not compatible with
o-series models".** They do not say whether GPT-5-family models reject
`max_tokens`, ignore it, or honour it, and they do not give the status code or
message for the o-series rejection. That is an unresolved item, though on the
Responses recommendation it is moot — the field simply does not exist there.

**The finding that actually matters is the semantic one, not the naming one.**
Both current fields count reasoning tokens against the budget, and every model
worth using here is a reasoning model. The reasoning guide:

> If the generated tokens reach the context window limit or the
> `max_output_tokens` value you've set, you'll receive a response with a
> `status` of `incomplete` and `incomplete_details` with `reason` set to
> `max_output_tokens`. This might occur before any visible output tokens are
> produced, meaning you could incur costs for input and reasoning tokens
> without receiving a visible response.

and:

> OpenAI recommends reserving at least 25,000 tokens for reasoning and outputs
> when you start experimenting with these models.

**A straight port of `_maxTokens = 1024` is therefore a plausible way to get
billed for nothing.** The Anthropic client's reasoning for 1024 — *"a large
budget only buys a longer runaway before it is cut off"* — was sound for a
non-reasoning model and is not sound here. The client must either raise the cap
substantially or send `reasoning: {effort: "none"}` and keep it low, and must
treat `status: "incomplete"` with `incomplete_details.reason ==
"max_output_tokens"` as a distinct failure. Which combination is right is a
measurement, not a reading.

## E. Failure taxonomy

**Status codes OpenAI documents for API errors**, from the error-codes table.
This is the complete list on that page:

| Status | What OpenAI documents | Against `MealInterpreterException` |
| --- | --- | --- |
| 401 | Invalid authentication; incorrect key; not a member of an organization; IP not on allowlist | `isAuthFailure` — **correct** |
| 403 | *"Country, region, or territory not supported"* | `isAuthFailure` — **wrong**; this is a geo-block |
| 429 | rate limit; `credit_balance_exhausted`; `organization_spend_limit_exceeded`; `project_spend_limit_exceeded`; `organization_usage_limit_exceeded` | `isTransient` — **only sometimes** |
| 500 | *"Issue on our servers"* | `isTransient` — correct |
| 503 | overloaded; *"Slow Down"* | `isTransient` — correct |

**There is no 400 and no 404 in that table.** Both exist as SDK exception types
— `BadRequestError` *"(formerly `InvalidRequestError`)"*, *"Your request was
malformed or missing some required parameters"*, and `NotFoundError`,
*"Requested resource does not exist"* — but neither is given a documented
trigger on the generation endpoints.

**429 is the one the existing code gets most wrong.** The rate-limits guide is
unambiguous:

> `Retry-After` may be present on `429` responses caused by a temporary rate
> limit. It does not mean that quota, billing, or other errors that require
> user action can be resolved by retrying.

and, for a hand-rolled HTTP client, which is what this app has:

> If you're using your own HTTP client, follow `Retry-After` when the header is
> present and contains a valid value. If it's missing or invalid, fall back to
> exponential backoff with jitter. Limit both the number of attempts and the
> total time spent retrying. … Don't retry quota, billing, or other errors that
> require you to take action.

So on OpenAI, `isTransient` cannot be decided from the status line alone.
Distinguishing a rate limit from an exhausted credit balance needs `error.code`
— *"For billing-related errors, inspect `error.code` to identify the specific
cause. The broader `error.type` can still be `insufficient_quota`."* This is a
real user-facing difference: telling somebody to try again later when their
prepaid balance is empty is the same failure mode
`AiCredentialStorage` already avoids for a wrong key.

**422 is documented as retryable**, which inverts `isRejectedRequest`:
`UnprocessableEntityError`, *"Unable to process the request despite the format
being correct. Solution: Please try the request again."* The corpus finding
behind `isRejectedRequest` — Adobe APP14 JPEGs refused with a 400 on every
attempt — was measured against a different provider and cannot be assumed to
carry.

**404-as-capability-refusal has no OpenAI analogue, and needs none.** The
existing mapping exists because OpenRouter answers *"No endpoints found that
support image input"* with a 404 when `require_parameters` is set. OpenAI has
no broker and no routing layer, so there is nothing to find no endpoints for.
**Capability is a published property of each model**: every model page carries
an `Endpoints` table (`v1/responses`: Supported / Not supported) and a
`Supported features` list naming `function_calling`, `image_input`,
`structured_outputs` explicitly. `gpt-5.4-nano` and `gpt-5.6-luna` both list
all three; the models index states flatly that *"All latest OpenAI models
support text and image input, text output, multilingual capabilities, and
vision."* A curated catalogue ([#686](https://github.com/simonoppowa/OpenNutriTracker/issues/686))
can therefore guarantee capability at build time rather than discovering it at
runtime, which is strictly better than a 404 the user has to be told about.
**What OpenAI returns for a model that cannot do tools or vision, or that does
not exist, is not documented** — see [Not established](#not-established-without-a-live-call).

**Yes, a failed generation can arrive as HTTP 200 — and the code must handle
it.** This is the hazard `_throwIfFailedGeneration` exists for, present on
OpenAI in a different shape. The `Response` object carries:

- `status`, described as *"The status of the response generation. One of
  `completed`, `failed`, `in_progress`, `cancelled`, `queued`, or
  `incomplete`."*
- `error`, *"An error object returned when the model fails to generate a
  Response"*, with `code` and a human-readable `message`.
- `incomplete_details`, *"Details about why the response is incomplete"*, whose
  `reason` is `max_output_tokens` or `content_filter`.

The documented `error.code` values include `server_error`,
`rate_limit_exceeded`, `invalid_prompt`, and — directly relevant to the photo
path — `invalid_image`, `invalid_image_format`, `invalid_base64_image`,
`image_too_large`, `image_too_small`, `image_parse_error`,
`unsupported_image_media_type`, `image_content_policy_violation`,
`empty_image_file`, `invalid_image_mode`. **These are string codes, not
integers**, so the existing trick of carrying an embedded numeric code out as
`statusCode` does not transfer; the taxonomy needs a string arm or a mapping.

**The real `finish_reason` values, for the record — Responses has none.** The
field is Chat Completions-only, and its enum is:

> This will be `stop` if the model hit a natural stop point or a provided stop
> sequence, `length` if the maximum number of tokens specified in the request
> was reached, `content_filter` if content was omitted due to a flag from our
> content filters, `tool_calls` if the model called a tool, or `function_call`
> (deprecated) if the model called a function.

`"error"` is **not** among them. It is an OpenRouter extension, and
`_throwIfFailedGeneration`'s comment is right about the hazard and wrong about
the marker as soon as it leaves OpenRouter.

## F. Strict mode

This section feeds [#683](https://github.com/simonoppowa/OpenNutriTracker/issues/683),
so it quotes rather than summarises.

**1. Every property must appear in `required`. Confirmed, in two places.**

Function calling guide, under *Strict mode*:

> Under the hood, strict mode works by leveraging our structured outputs
> feature and therefore introduces a couple requirements:
>
> 1. `additionalProperties` must be set to `false` for each object in the
>    `parameters`.
> 2. All fields in `properties` must be marked as `required`.

Structured outputs guide, under *All fields must be `required`*:

> To use Structured Outputs, all fields or function parameters must be
> specified as `required`.

So the 400 recorded in `openrouter_meal_items_api.dart` — *"'required' is
required to be supplied and to be an array including every key in properties.
Missing 'quantity'."* — was OpenAI's documented behaviour working as designed,
not a broker quirk. And the failure mode is documented: *"If you send `strict:
true` and your schema does not meet the requirements above, the request will be
rejected with details about the missing constraints."*

**2. The nullable union is the sanctioned way to express an optional field.
Documented explicitly, twice.**

Function calling guide, immediately after the two requirements:

> You can denote optional fields by adding `null` as a `type` option (see
> example below).

Structured outputs guide, the operative sentence:

> Although all fields must be required (and the model will return a value for
> each parameter), it is possible to emulate an optional parameter by using a
> union type with `null`.

Both guides carry a worked example doing exactly this: `"units": {"type":
["string", "null"], "enum": ["celsius", "fahrenheit"]}` with `"required":
["location", "units"]`.

**This is the finding that reopens the schema question.** The comment in
`openrouter_meal_items_api.dart` reasons that *"making them required would
oblige the model to produce a number for every item, which is the estimation
this whole design exists to prevent"* — and against a plain `required` that is
correct. Against `required` plus `["number", "null"]` it is not: the model is
obliged to emit the *key*, and `null` is a conforming value for it. The
parenthesis *"and the model will return a value for each parameter"* is the
only behavioural consequence, and the value can be `null`.

The downstream effect on this app is small.
[`_mealItemFrom`](../lib/features/add_meal/domain/meal_items_api.dart) already
maps a non-`num`, non-`String` `quantity` to `null` and a non-`String` `unit`
to `null`, so an explicit JSON `null` is already handled and needs no change.
Whether to take the trade at all — a schema change affecting all three
providers, for a guarantee that
[`validateParsedMealItems`](../lib/features/add_meal/util/meal_text_parser.dart)
already enforces — is [#683](https://github.com/simonoppowa/OpenNutriTracker/issues/683)'s
call. The claim *"the schema cannot bend"* is the part that does not survive
this reading.

**3. `additionalProperties: false` is required. Confirmed, and stated as a
requirement rather than a recommendation.**

> `additionalProperties` controls whether it is allowable for an object to
> contain additional keys / values that were not defined in the JSON Schema.
>
> Structured Outputs only supports generating specified keys / values, so we
> require developers to set `additionalProperties: false` to opt into
> Structured Outputs.

The section is headed *"`additionalProperties: false` must always be set in
objects"* — every object, at every level, not just the root.
`mealItemsToolSchema` already satisfies this on both of its objects, so this
requirement costs nothing.

**4. The default when `strict` is omitted differs by API, and this is a live
trap on Responses.**

> If you omit `strict`, the default depends on the API: Responses requests will
> attempt to normalize your schema into strict mode when possible, and will
> fall back to non-strict, best-effort function calling if the schema cannot be
> made compatible with strict mode. When fallback happens, the response tool
> will show `strict: false`. Chat Completions requests remain non-strict by
> default. To opt out of strict mode in Responses and keep non-strict,
> best-effort function calling, explicitly set `strict: false`.

The migration guide says it again in the imperative: *"In Chat Completions,
functions are non-strict by default. In Responses, omitting `strict` attempts
strict mode."*

**So on Responses, "just don't send `strict`" is not the no-op it is on
OpenRouter.** With the schema as it stands, normalisation should fail
(`quantity` and `unit` are neither `required` nor nullable) and Responses should
fall back — a benign outcome, but one reached by a documented code path rather
than by the request being left alone. If the intent is genuinely non-strict, the
client should **send `strict: false` explicitly**. If the schema changes under
[#683](https://github.com/simonoppowa/OpenNutriTracker/issues/683),
`strict: true` becomes available and OpenAI recommends it: *"Setting
`strict` to `true` will ensure function calls reliably adhere to the function
schema, instead of being best effort. We recommend always enabling strict
mode."*

**5. One inconsistency in OpenAI's own documentation, flagged because it lands
exactly on this app's `unit` field.** The `unit` property is a nullable field
*with an enum*, and the docs show two different answers for whether `null` must
appear in the enum list:

- The `get_weather` example, in both guides: `"type": ["string", "null"],
  "enum": ["celsius", "fahrenheit"]` — `null` **absent** from the enum. Under
  plain JSON Schema, `enum` is an independent constraint, so this schema admits
  no valid value of `null` at all.
- The moderation example's Go binding: `"type": []string{"string", "null"}, …
  "enum": []any{"violence", "sexual", "self_harm", nil}` — `null` **present**.
  Its own curl equivalent, on the same page, omits it.

OpenAI states no rule either way. This is a probe question, not a reading
question, and it is narrow enough to answer in one call.

## G. What else a direct client must send

Mostly good news: the broker was hiding less than expected.

**Required headers: two, and the app already sends both.** The API Overview
gives the whole auth surface — *"Provide API credentials with HTTP Bearer
authentication"*, `Authorization: Bearer OPENAI_API_KEY_OR_ACCESS_TOKEN` — and
every raw `curl` example in the quickstart sends exactly `Content-Type:
application/json` and `Authorization: Bearer $OPENAI_API_KEY`. Nothing else.

**No versioning header.** There is no `anthropic-version` equivalent to pin.
Versioning is in the path (`/v1/`), and `openai-version` is a **response**
header — *"REST API version used for this request (currently `2020-10-01`)"* —
not something a client sends. The backwards-compatibility section commits to
*"avoiding breaking changes in major API versions whenever reasonably
possible"* and enumerates additive changes as compatible, which is the closest
thing to a stability promise on offer.

**Organisation and project headers are optional, and conditional.**

> If you belong to more than one organization or access projects through a
> legacy user API key, pass a header to specify which organization and project
> to use for an API request

— `OpenAI-Organization` and `OpenAI-Project`. Neither applies to a user with one
personal key, and neither should be sent. There is no analogue of OpenRouter's
`x-openrouter-metadata`, and nothing corresponding to `HTTP-Referer` /
`X-Title`, so the deliberate omission recorded in the OpenRouter client has no
counterpart to worry about here.

**`store: false` is the one genuinely new field, it is a privacy field, and it
is not optional.** A client that omits it opts the user into a 30-day
server-side retention of their meal text and photograph without asking.
[Section A2](#a2-the-storage-default) is
the evidence and the reasoning; the short form is: send it, on whichever
endpoint, on every request, and assert it in a test. Note what it does **not**
do — it does not touch abuse-monitoring logs, which are *"generated for all API
feature usage and retained for up to 30 days"* by default on both endpoints and
can only be reduced through approved Zero Data Retention or Modified Abuse
Monitoring controls. A client author must not read `store: false` as "OpenAI
keeps nothing", and neither should the README. What the app can honestly claim
belongs to [#680](https://github.com/simonoppowa/OpenNutriTracker/issues/680)
and [#689](https://github.com/simonoppowa/OpenNutriTracker/issues/689).

**Two optional fields worth a deliberate decision rather than a default.**

- `safety_identifier` — *"A stable identifier used to help detect users of your
  application that may be violating OpenAI's usage policies. … We recommend
  hashing their username or email address, in order to avoid sending us any
  identifying information."* This app has no account and no username; sending
  anything here would be inventing an identifier to send. Omit.
- `X-Client-Request-Id` — *"This header isn't added automatically; you must
  explicitly set it on the request"*, and OpenAI *"logs this value internally"*.
  Useful for support, and precisely the kind of correlatable per-request ID this
  project would not add without a reason. Omit.

**One structural note on the system prompt.** Responses takes it as top-level
`instructions` — *"A system (or developer) message inserted into the model's
context"* — which is the idiomatic form and the one the migration guide maps
*"System or developer guidance"* onto. A `role: "system"` message in `input`
also remains valid (`role` is *"One of `user`, `assistant`, `system`, or
`developer`"*). Prefer `instructions`: it is one fewer array element and it
keeps the shared prompt constants out of the message-rendering switch.

## Not established without a live call

Everything here is a gap in the published documentation, not a gap in the
reading. Each is scoped for
[#684](https://github.com/simonoppowa/OpenNutriTracker/issues/684).

- **What status code a nonexistent model returns from `/v1/responses`.** The
  error-codes table has no 404 entry. `NotFoundError` exists as an SDK type for
  *"Requested resource does not exist"* with no endpoint named. The only place
  in the whole API documentation set that ties 404 to model access is the
  content-provenance guide, about a *different* endpoint — *"an organization
  without access receives `404`"* — which is suggestive and not authoritative.
- **What happens when a model that lacks `image_input` or `function_calling` is
  sent an image or a tool.** Silent everywhere. I searched the combined
  single-file export of every API guide and reference page for it. Capability
  is documented per model as a static fact and never as an error. Whether it is
  a 400, a 404, or a silently-ignored parameter is unknown.
- **Whether `null` must appear in the `enum` list of a nullable enum property
  under `strict: true`.** OpenAI's own examples disagree ([Section
  F](#f-strict-mode) item 5). This lands directly on the `unit` field and
  should be probed before #683 commits to a schema.
- **Whether a forced `tool_choice` can produce a `message` output item in the
  same turn.** The docs neither promise nor forbid it. The client is safe
  either way if it iterates `output`, but the answer decides whether "prose is
  impossible" or only "prose is detectable" can be written down as a property.
- **Whether GPT-5-family models reject `max_tokens` on Chat Completions.** The
  reference says only *"not compatible with o-series models"*. Moot on the
  Responses recommendation.
- **What `max_output_tokens` this workload actually needs**, and whether
  `reasoning: {effort: "none"}` is compatible with a forced tool call on
  Responses for the models under consideration. The Chat Completions
  incompatibility is documented; the Responses side is not stated either way.
  This is a measurement.
- **Whether a strict-mode `["number", "null"]` `quantity` changes how often the
  model volunteers an amount the user did not state.** Pure behaviour. The
  documentation cannot answer it and the existing live corpus can.
- **How long a stored chat completion is retained.** OpenAI's own pages
  disagree about whether `/v1/chat/completions` retains application state by
  default at all ([Section A2](#a2-the-storage-default)
  item 2), and no retention period is published for the stored case the way the
  30-day one is for Responses. Not answerable by probing either — this one
  needs OpenAI support, and could ride along with
  [#691](https://github.com/simonoppowa/OpenNutriTracker/issues/691).
- **Whether `store: false` is honoured on a request that also carries an
  image.** The documentation states it for server-side compaction (*"no data is
  retained when `store="false"`"*) and nowhere ties it to image inputs
  specifically. The CSAM-scanning carve-out is explicit that images survive
  even ZDR, so the two statements need reconciling against an actual response.
- **The exact HTTP error body schema.** `error.code` and `error.type` are
  referenced by the error-codes guide and `{code, message, param}` appears in
  worked examples, but no canonical schema for the non-streaming REST error
  envelope is published in the reference.
- **Whether the WebP the app produces passes.** *"Clear enough for a human to
  understand"* is not a machine-checkable requirement, and
  `unsupported_image_media_type` / `image_parse_error` exist as error codes.
  WebP is named as supported; that a specific encoder's output is accepted is a
  probe.

## Sources

OpenAI developer documentation, all read 2026-08-16 via the published Markdown
twins (append `.md` to any page URL):

[Function calling](https://developers.openai.com/api/docs/guides/function-calling) ·
[Structured model outputs](https://developers.openai.com/api/docs/guides/structured-outputs) ·
[Images and vision](https://developers.openai.com/api/docs/guides/images-vision) ·
[Migrate to the Responses API](https://developers.openai.com/api/docs/guides/migrate-to-responses) ·
[Reasoning](https://developers.openai.com/api/docs/guides/reasoning) ·
[Error codes](https://developers.openai.com/api/docs/guides/error-codes) ·
[Rate limits](https://developers.openai.com/api/docs/guides/rate-limits) ·
[Deprecations](https://developers.openai.com/api/docs/deprecations) ·
[Models](https://developers.openai.com/api/docs/models) ·
[GPT-5.4 nano](https://developers.openai.com/api/docs/models/gpt-5.4-nano) ·
[GPT-5.6 Luna](https://developers.openai.com/api/docs/models/gpt-5.6-luna) ·
[How we use your data](https://developers.openai.com/api/docs/guides/your-data) ·
[Quickstart](https://developers.openai.com/api/docs/quickstart)

OpenAI API reference:
[API Overview](https://developers.openai.com/api/reference/overview) ·
[Responses — Create a model response](https://developers.openai.com/api/reference/resources/responses/methods/create) ·
[Chat — Create chat completion](https://developers.openai.com/api/reference/resources/chat) ·
[Chat Completions Overview](https://developers.openai.com/api/reference/chat-completions/overview) ·
[Chat Completions — Get](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/retrieve) ·
[Responses Overview](https://developers.openai.com/api/reference/responses/overview)

Related notes in this repo:
[`ai-openai-policy-fit.md`](ai-openai-policy-fit.md) ·
[`ai-openai-key-transfer.md`](ai-openai-key-transfer.md) ·
[`ai-model-candidates.md`](ai-model-candidates.md) ·
[`ai-open-research-questions.md`](ai-open-research-questions.md)

In-repo files cited:
[`lib/features/add_meal/data/openrouter_meal_items_api.dart`](../lib/features/add_meal/data/openrouter_meal_items_api.dart) ·
[`lib/features/add_meal/data/anthropic_meal_items_api.dart`](../lib/features/add_meal/data/anthropic_meal_items_api.dart) ·
[`lib/features/add_meal/domain/meal_items_api.dart`](../lib/features/add_meal/domain/meal_items_api.dart) ·
[`lib/features/add_meal/domain/meal_interpreter_exception.dart`](../lib/features/add_meal/domain/meal_interpreter_exception.dart)
