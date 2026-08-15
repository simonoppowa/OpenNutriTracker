# OpenRouter's tool-calling and vision surface

Research notes gathered 2026-08-15 against primary sources only: OpenRouter's
own documentation under `openrouter.ai/docs`, its published OpenAPI reference
for `POST /api/v1/chat/completions`, and live responses from
`GET https://openrouter.ai/api/v1/models` and
`GET /api/v1/models/{author}/{slug}/endpoints`. No blog posts, no third-party
write-ups, no SDK source. Written to resolve
[#655](https://github.com/simonoppowa/OpenNutriTracker/issues/655).

Anything I could not establish from a primary source is called out inline and
collected again at the end rather than smoothed over.

## Summary

OpenRouter's wire format is what you would guess from OpenAI compatibility, and
the two shapes this app needs both exist:
`tools: [{type: "function", function: {name, description, parameters, strict}}]`
and `tool_choice: {type: "function", function: {name}}`. Images go in as
`{type: "image_url", image_url: {url: "data:image/webp;base64,..."}}`, and
`image/webp` is on the explicitly supported list.

The part that matters for this app is not the shape but the enforcement. Three
statements in OpenRouter's own docs, read together, say that a forced tool call
is a routing preference rather than a contract:

1. Routing to tool-capable providers is **"a best effort"**, not a guarantee.
2. Providers that do not support a parameter **still receive the request and
   ignore the parameter**, unless you set `provider.require_parameters: true`.
3. The soft preference that steers toward parameter-supporting providers covers
   `tools`, `response_format` and `verbosity` — **`tool_choice` is not in that
   list** — and even for the parameters it does cover, "If none of a model's
   providers support the parameter, the request is still routed to that model
   and the parameter is ignored."

OpenRouter also publishes a **Tool Call Error Rate** per provider endpoint,
built by validating returned tool arguments against the caller's JSON Schema.
The existence of that metric is itself primary-source evidence that
schema-conforming tool calls are a measured rate, not a floor.

Error classification is unusually good: OpenRouter normalises upstream failures
into a stable `error_type` vocabulary that includes `invalid_image`,
`image_too_large`, `image_too_small`, `unsupported_image_format`, and
`image_download_failed`. Failures can be classified rather than guessed at.

## 1. Tool calling: request shape and forcing

### Declaring tools

Source: [Tool & Function Calling](https://openrouter.ai/docs/guides/features/tool-calling)
(`.md` form at `https://openrouter.ai/docs/guides/features/tool-calling.md`).

The guide's "Step 1: Inference Request with Tools" example, verbatim:

```json
{
  "model": "google/gemini-3-flash-preview",
  "messages": [
    { "role": "user", "content": "What are the titles of some James Joyce books?" }
  ],
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "search_gutenberg_books",
        "description": "Search for books in the Project Gutenberg library",
        "parameters": {
          "type": "object",
          "properties": {
            "search_terms": {
              "type": "array",
              "items": {"type": "string"},
              "description": "List of search terms to find books"
            }
          },
          "required": ["search_terms"]
        }
      }
    }
  ]
}
```

The same page states the compatibility claim directly: "We then write a JSON
'spec' compatible with the OpenAI function calling parameter." And a note that
matters for a multi-turn implementation: "The `tools` parameter must be included
in every request (Steps 1 and 3) so the router can validate the tool schema on
each call."

The authoritative field list is the OpenAPI reference at
[POST /api/v1/chat/completions](https://openrouter.ai/docs/api/api-reference/chat/create-a-chat-completion)
(`.md` form at
`https://openrouter.ai/docs/api/api-reference/chat/create-a-chat-completion.md`),
schema `ChatFunctionTool`:

```yaml
function:
  properties:
    description:
      description: Function description for the model
      type: string
    name:
      description: "Function name (a-z, A-Z, 0-9, underscores, dashes, max 64 chars)"
      maxLength: 64
      type: string
    parameters:
      additionalProperties: {}
      description: Function parameters as JSON Schema object
      type: object
    strict:
      description: Enable strict schema adherence
      example: false
      type: [boolean, 'null']
  required:
    - name
type:
  enum:
    - function
```

So: **`strict` is accepted on the tool definition** (`tools[].function.strict`,
boolean or null, described as "Enable strict schema adherence"), and tool names
are capped at 64 characters. `log_meal_items` is comfortably inside that.

### Forcing a specific tool

Same OpenAPI reference, schema `ChatToolChoice`:

```yaml
ChatToolChoice:
  anyOf:
    - enum: [none]
    - enum: [auto]
    - enum: [required]
    - $ref: '#/components/schemas/ChatNamedToolChoice'
    - $ref: '#/components/schemas/ChatServerToolChoice'
  description: Tool choice configuration
  example: auto
```

and `ChatNamedToolChoice`:

```yaml
ChatNamedToolChoice:
  description: Named tool choice for specific function
  example:
    function:
      name: get_weather
    type: function
  properties:
    function:
      properties:
        name:
          description: Function name to call
          type: string
      required: [name]
    type:
      enum: [function]
  required: [type, function]
```

The prose form is in [Parameters](https://openrouter.ai/docs/api_reference/parameters),
under "Tool Choice":

> "Controls which (if any) tool is called by the model. 'none' means the model
> will not call any tool and instead generates a message. 'auto' means the model
> can pick between generating a message or calling one or more tools. 'required'
> means the model must call one or more tools. Specifying a particular tool via
> `{"type": "function", "function": {"name": "my_function"}}` forces the model to
> call that tool."

The tool-calling guide repeats the forcing shape:

```json
// Force specific tool
{
  "tool_choice": {
    "type": "function",
    "function": {"name": "search_database"}
  }
}
```

**Confirmed exactly as expected.** Note the guide only documents
`auto` / `none` / named — it omits `"required"`, which the OpenAPI schema and
the Parameters page both list. Prefer the OpenAPI schema where they differ.

`parallel_tool_calls` also exists (default `true`); setting it to `false` means
"the model will only request one tool call at a time instead of potentially
multiple calls in parallel."

There is one OpenRouter-specific deviation worth knowing about, `ChatServerToolChoice`:

> "OpenRouter extension: force a specific server tool by naming it directly in
> `tool_choice.type` instead of wrapping it in
> `{ type: "function", function: { name } }`."

That applies only to OpenRouter's own built-in server tools
(`openrouter:web_search` and friends). It does not change the shape for
caller-defined functions.

### Is forcing honoured uniformly?

**No, and OpenRouter says so in three places.** This is the load-bearing part of
the whole document.

**(a) Routing to tool-capable providers is best-effort.** From
[Provider Selection](https://openrouter.ai/docs/guides/routing/provider-selection):

> "When you send a request with `tools` or `tool_choice`, OpenRouter makes a
> best effort to route to providers known to support tool use."

**(b) Non-supporting providers silently ignore parameters by default.** Same
page, under "Requiring Providers to Support All Parameters":

> "With the default routing strategy, providers that don't support all the LLM
> parameters specified in your request can still receive the request, but will
> ignore unknown parameters. When you set `require_parameters` to `true`, the
> request won't even be routed to that provider."

`require_parameters` defaults to `false`.

**(c) The soft preference does not cover `tool_choice`, and yields entirely when
no provider supports it.** Same page, "Default parameter preferences":

> "Even when `require_parameters` is `false`, a small set of parameters is used
> as a soft preference when choosing between providers of the same model:
> `tools`, `response_format` (including structured outputs), and `verbosity`. If
> some of a model's providers support one of these parameters and others don't,
> the request is only routed to the supporting providers. If none of a model's
> providers support the parameter, the request is still routed to that model and
> the parameter is ignored — this preference never removes a model from your
> request's candidate list."

Read plainly: `tools` steers routing softly; `tool_choice` does not appear in the
soft-preference set at all; and in the worst case the request still goes out with
the parameter dropped.

**(d) Tool-call correctness is a measured rate.** From
[Auto Exacto](https://openrouter.ai/docs/guides/routing/auto-exacto), which runs
by default on every tool-calling request:

> "For each request that includes tools, OpenRouter inspects every tool call the
> model returned and validates it against the schemas the caller supplied."

Arguments are validated with `@cfworker/json-schema` pinned to JSON Schema
Draft 7 (`new Validator(parameters, '7')`), and each tool call is bucketed as
`InvalidJson` (`JSON.parse(arguments)` throws), `UnknownName` (`function.name`
is not present in the request's `tools[]`), or `SchemaMismatch` (validator
returns `valid: false`). The published rate is:

```
requests_with_tool_call_errors / requests_where_finish_reason_is_tool_calls
```

Two caveats OpenRouter states itself: Draft 2019-09/2020-12 keywords such as
`unevaluatedProperties` "are not enforced under Draft 7", and "Tools whose
`parameters` schema is absent or fails to compile are treated as having no
schema and are always considered valid, so the metric is conservative when
caller-side schemas are malformed."

Auto Exacto reorders providers toward the ones with better tool-calling success
rates, and is bypassed if you sort by price (`provider.sort: "price"`, the
`:floor` variant, or a price default in account settings). So opting into
cheapest-provider routing also opts out of the quality ordering on tool calls.

**On `strict`:** the field exists and is described as "Enable strict schema
adherence", but I found **no primary-source statement about how uniformly
`strict` is enforced on tool definitions.** The nearest documented statement is
about `response_format` structured outputs, from
[Structured Outputs](https://openrouter.ai/docs/guides/features/structured-outputs):

> "Use strict mode: Set `strict: true` so that providers with a native strict
> mode enforce your schema exactly. Enforcement varies by provider: some
> guarantee schema-conforming output, while others translate your schema into
> their own structured-output format or treat it as a strong hint, so exact
> compliance is not guaranteed on every endpoint. Strict modes may also restrict
> which JSON Schema features you can use."

It is reasonable to assume the same "varies by provider" caveat applies to
`tools[].function.strict`, but OpenRouter does not say so, so treat that as an
inference and not a citation.

## 2. Vision: request shape, media types, limits

### Request shape

Source: [Image Inputs](https://openrouter.ai/docs/guides/overview/multimodal/image-understanding).

> "Requests with images, to multimodel models, are available via the
> `/api/v1/chat/completions` API with a multi-part `messages` parameter. The
> `image_url` can either be a URL or a base64-encoded image. Note that multiple
> images can be sent in separate content array entries. The number of images you
> can send in a single request varies per provider and per model. Due to how the
> content is parsed, we recommend sending the text prompt first, then the images.
> If the images must come first, we recommend putting it in the system prompt."

Verbatim from that page's Python example:

```json
{
  "role": "user",
  "content": [
    { "type": "text", "text": "What's in this image?" },
    { "type": "image_url", "image_url": { "url": "<https URL or data: URL>" } }
  ]
}
```

Base64 goes in as a data URL; the page's helper builds
`data_url = f"data:image/jpeg;base64,{base64_image}"`.

**Text before images is an actual documented recommendation**, not a style
preference. Worth checking the current photo-interpreter payload against it.

The OpenAPI schema `ChatContentImage` gives the full field list:

```yaml
ChatContentImage:
  description: Image content part for vision models
  properties:
    image_url:
      properties:
        detail:
          enum: [auto, low, high, original]
        url:
          description: "URL of the image (data: URLs supported)"
          type: string
      required: [url]
    type:
      enum: [image_url]
  required: [type, image_url]
```

`detail` is optional and accepts `auto`, `low`, `high`, and OpenRouter's own
`original`:

> "`original` is an OpenRouter extension (not in the OpenAI Chat Completions
> spec) requesting true original-resolution media; it is downgraded to `high` for
> providers that lack an original-resolution tier."

### Media types

The Image Inputs page closes with an explicit list:

> "Supported image content types are:
> * `image/png`
> * `image/jpeg`
> * `image/webp`
> * `image/gif`"

**WebP is explicitly supported.** That is a direct, unambiguous primary-source
answer, and it matches what the existing Anthropic client already sends.

### Size and pixel-dimension limits

**Not documented, and deliberately so.** I could find no OpenRouter-level
statement of a maximum image byte size, maximum pixel dimensions, or maximum
base64 payload for image inputs — not on the Image Inputs page, not on the
[Multimodal Capabilities](https://openrouter.ai/docs/guides/overview/multimodal/overview)
overview, not in [Limits](https://openrouter.ai/docs/api_reference/limits), and
not in the chat-completions OpenAPI schema.

The only primary-source statement on the subject is the error taxonomy, which
pushes the limit down to the provider:

> "`image_too_large` … An image exceeds **the provider's** maximum file size or
> pixel dimensions."
> "`image_too_small` … An image is below **the provider's** minimum pixel
> dimensions."

(Emphasis added.) So limits are per-provider and per-endpoint, are not published
in any machine-readable form I could find, and can only be discovered by hitting
them. A `payload_too_large` / HTTP 413 also exists for the request body as a
whole, but the size threshold is not stated either.

Practical consequence: 1024px WebP is far below any plausible provider ceiling,
so the current encoding is safe by a wide margin — but that is an argument from
headroom, not from a documented limit.

## 3. Capability discovery via GET /api/v1/models

Source: [Models](https://openrouter.ai/docs/guides/overview/models), plus a live
call to `https://openrouter.ai/api/v1/models` made on 2026-08-15 (413 models
returned).

**Yes, both flags are exposed, in two different places.**

Tool support lives in `supported_parameters`, a flat `string[]`. The docs list
the meanings:

> * `tools` - Function calling capabilities
> * `tool_choice` - Tool selection control
> * `structured_outputs` - JSON schema enforcement
> * `response_format` - Output format specification

Image input lives in `architecture.input_modalities`:

```typescript
{
  "input_modalities": string[], // Supported input types: ["file", "image", "text"]
  "output_modalities": string[], // Supported output types: ["text"]
  "tokenizer": string,
  "instruct_type": string | null
}
```

Live response fragment (trimmed, from the 2026-08-15 call):

```json
{
  "id": "anthropic/claude-sonnet-5",
  "canonical_slug": "anthropic/claude-sonnet-5-20260630",
  "name": "Anthropic: Claude Sonnet 5",
  "context_length": 1000000,
  "architecture": {
    "modality": "text+image+file->text",
    "input_modalities": ["text", "image", "file"],
    "output_modalities": ["text"],
    "tokenizer": "Claude",
    "instruct_type": null
  },
  "supported_parameters": [
    "include_reasoning", "max_completion_tokens", "max_tokens",
    "reasoning", "reasoning_effort", "response_format", "stop",
    "structured_outputs", "tool_choice", "tools", "verbosity"
  ],
  "top_provider": { "context_length": 1000000, "max_completion_tokens": 128000, "is_moderated": false },
  "links": { "details": "/api/v1/models/anthropic/claude-sonnet-5/endpoints" }
}
```

Server-side filtering works. `supported_parameters` is documented as a query
parameter:

```bash
curl "https://openrouter.ai/api/v1/models?supported_parameters=tools"
```

`input_modalities` also works as a query parameter and behaves as a filter
(verified live: `?input_modalities=image` narrows the list), even though the
Models page documents only `output_modalities`, `supported_parameters` and
`sort`. Treat `input_modalities` as observed-working-but-undocumented.

### Is it trustworthy?

Mostly, with one real trap. **The model-level `supported_parameters` is a union
across that model's provider endpoints, not an intersection.** Verified live for
`anthropic/claude-sonnet-5`: the model-level array includes
`structured_outputs`, but the per-endpoint arrays returned by
`GET /api/v1/models/anthropic/claude-sonnet-5/endpoints` show the Google Vertex
endpoints omitting `structured_outputs` while Anthropic, Azure and Bedrock
endpoints include it. So a model listed as supporting a parameter can still be
served by an endpoint that does not — which is exactly the
silently-ignored-parameter case from §1.

The per-endpoint record is the finer-grained truth:

```json
{
  "name": "Amazon Bedrock | anthropic/claude-sonnet-5-20260630",
  "provider_name": "Amazon Bedrock",
  "context_length": 1000000,
  "max_completion_tokens": 128000,
  "supported_parameters": [
    "reasoning", "include_reasoning", "max_tokens", "stop",
    "tool_choice", "tools", "structured_outputs", "response_format",
    "verbosity", "reasoning_effort"
  ],
  "uptime_last_30m": 98.83
}
```

Note that `architecture` / `input_modalities` is returned at the **model** level
in that endpoints response, not per endpoint — so there is no per-endpoint image
capability flag to check.

On freshness, OpenRouter's own framing is best-effort-but-prompt: the Models API
"makes the most important information about all LLMs freely available as soon as
we confirm it," and the schema "is cached at the edge". No accuracy or
completeness guarantee is stated anywhere I could find. There is also a small
population of models advertising `tools` without `tool_choice` — 4 of 413 on
2026-08-15, all `amazon/nova-*` — so the two flags genuinely are independent and
both must be checked.

## 4. Error shape

Source: [Errors and Debugging](https://openrouter.ai/docs/api_reference/errors-and-debugging).

Base envelope:

```typescript
type ErrorResponse = {
  error: {
    code: number;
    message: string;
    metadata?: Record<string, unknown>;
  };
};
```

> "The HTTP Response will have the same status code as `error.code`, forming a
> request error if: Your original request is invalid / Your API key/account is
> out of credits. Otherwise, the returned HTTP response status will be 200 OK
> and any error occurred while the LLM is producing the output will be emitted
> in the response body or as an SSE data event."

**That last sentence is the one to design around: a failure mid-generation
arrives as HTTP 200.** For non-streaming Chat Completions the error is embedded
in the choice:

```json
{
  "choices": [{
    "message": { "role": "assistant", "content": "partial output..." },
    "finish_reason": "error",
    "error": {
      "code": 502,
      "message": "Provider disconnected mid-stream",
      "metadata": { "error_type": "provider_unavailable" }
    }
  }]
}
```

So classification must check `choices[0].finish_reason == "error"` and
`choices[0].error`, not only the HTTP status.

### The typed vocabulary

> "When a provider error reaches your application, OpenRouter tags it with a
> canonical `error_type` string … Use this value, not the HTTP status code
> alone, to programmatically distinguish error categories. It is stable across
> all three API skins even when the native protocol code is lossy."

For Chat Completions it lives at `error.metadata.error_type`, with the upstream
provider's own code alongside it at `error.metadata.provider_code`:

```json
{
  "error": {
    "code": 429,
    "message": "Rate limit exceeded",
    "metadata": { "error_type": "rate_limit_exceeded", "provider_code": "rate_limited" }
  }
}
```

The image bucket is directly relevant to the photo path:

| `error_type`               | HTTP | Description (verbatim)                                                                                        |
| -------------------------- | ---- | ------------------------------------------------------------------------------------------------------------- |
| `invalid_image`            | 400  | An image in the request is corrupt or unreadable.                                                             |
| `image_too_large`          | 400  | An image exceeds the provider's maximum file size or pixel dimensions.                                        |
| `image_too_small`          | 400  | An image is below the provider's minimum pixel dimensions.                                                    |
| `unsupported_image_format` | 400  | The image format is not supported by the provider.                                                            |
| `image_not_found`          | 404  | The referenced image URL or file ID could not be resolved.                                                    |
| `image_download_failed`    | 400  | OpenRouter could not download the image from the provided URL (DNS failure, timeout, non-200 response, etc.). |

Other buckets that matter here: `invalid_request` (400, "A request parameter is
malformed or missing"), `invalid_prompt` (400, "A specific message in the
`messages` array is invalid"), `context_length_exceeded` (400),
`payload_too_large` (413, "The request body exceeds the maximum allowed size"),
`content_policy_violation` (400), `refusal` (400, "The model explicitly refused
to comply with the request"), `rate_limit_exceeded` (429),
`provider_overloaded` (503), `provider_unavailable` (502), `timeout` (504),
`server` (500, message masked), and `unmapped` (500).

Top-level HTTP codes, from the same page: 400 bad request, 401 invalid
credentials, 402 insufficient credits, 403 forbidden / guardrail / moderation,
408 timeout, 429 rate limited, 502 "Your chosen model is down or we received an
invalid response from it", 503 "There is no available model provider that meets
your routing requirements". On 429 and 503 a standard `Retry-After` header may be
present. On 500 the message is replaced with a generic string and
`provider_code` and `openrouter_metadata` are omitted, but `error_type` survives
as `server`.

Moderation blocks put `reasons`, `flagged_input` (truncated to 100 chars),
`provider_name` and `model_slug` in `error.metadata`.

### What is NOT covered

**There is no documented error for "this model does not support tools" or "this
model does not support images."** No `error_type` in the published vocabulary
names either condition. Based on §1 the more likely behaviour for tools is no
error at all — the parameter is dropped and the model answers in prose. For
images, the Multimodal overview says only that "OpenRouter automatically filters
available models based on your request content" with "Vision models: Required for
image processing", which suggests routing-level filtering that would surface as
503 ("no available model provider that meets your routing requirements") rather
than a dedicated capability error. **I could not confirm either behaviour from a
primary source**; confirming it needs a live probe against a text-only model,
which I did not run.

## 5. Models supporting both forced tool calling and image input

Query used (live, 2026-08-15):

```bash
curl "https://openrouter.ai/api/v1/models?supported_parameters=tools,tool_choice&input_modalities=image"
```

That returned **202 models**, of which **187 also advertise
`structured_outputs`**. (Filtering the unfiltered 413-model dump locally on
`'tools' in supported_parameters and 'tool_choice' in supported_parameters and
'image' in architecture.input_modalities` gives 215; the difference is the
default `output_modalities=text` filter on the server-side query, which drops
image-*output* models such as `google/gemini-3-pro-image`.)

The equivalent website filter is
`https://openrouter.ai/models?supported_parameters=tools&input_modalities=image`.

By vendor, the 202: openai 72, google 31, anthropic 28, qwen 22, mistralai 9,
bytedance-seed 6, moonshotai 5, x-ai 5, meta 3, thinkingmachines 3, z-ai 3,
meta-llama 2, minimax 2, nex-agi 2, nvidia 2, sakana 2, and one each from amazon,
dots-studio, rekaai, stepfun, xiaomi. (`:batch` variants counted; they inflate
anthropic and google.)

Representative list, `:batch` and `:free` variants removed. All of these carry
`structured_outputs` except where noted:

- `anthropic/claude-sonnet-5`, `anthropic/claude-opus-4.5`,
  `anthropic/claude-haiku-4.5`
- `google/gemini-3-flash-preview`, `google/gemini-2.5-flash`,
  `google/gemini-2.5-flash-lite`
- `openai/gpt-5`, `openai/gpt-5-mini`, `openai/gpt-5-nano`, `openai/gpt-4o`,
  `openai/gpt-4o-mini`
- `qwen/qwen3-vl-8b-instruct`, `qwen/qwen3-vl-30b-a3b-instruct`,
  `qwen/qwen3-vl-235b-a22b-instruct`
- `mistralai/mistral-medium-3.1`, `mistralai/mistral-medium-3`
- `meta-llama/llama-4-scout`, `meta-llama/llama-4-maverick`
- `moonshotai/kimi-k2.5`, `moonshotai/kimi-k3`
- `x-ai/grok-4.5`, `x-ai/grok-4.6`
- `z-ai/glm-4.6v`, `z-ai/glm-5v-turbo` — **no `structured_outputs`**

Two things this list does not tell you. First, it is a union over provider
endpoints (§3), so any given request to one of these may land on an endpoint that
lacks `tool_choice`. Second, `supported_parameters` says the parameter is
accepted, not that forcing is obeyed — see below.

## What this means for the forced-tool-call guarantee

The app's safety property today is structural: the model is forced into
`log_meal_items`, whose schema has no nutrition fields, so there is no slot in
which a calorie count could be returned. The guarantee holds because the model
has no other channel. Behind OpenRouter, that reasoning has to be re-examined,
because two of its premises weaken.

**The forcing premise weakens from guarantee to preference.** OpenRouter says it
makes "a best effort to route to providers known to support tool use", that
non-supporting providers "can still receive the request, but will ignore unknown
parameters" unless `require_parameters` is set, and that the soft
parameter-preference list is `tools`, `response_format` and `verbosity` —
`tool_choice` is absent from it. There is no documented guarantee that a named
`tool_choice` is honoured, and no documented error when it is not. The observable
failure mode is a plain assistant message where a `tool_calls` array was expected
— and a plain assistant message is precisely the free-text channel the schema was
designed to eliminate. **This is the finding that matters for #655.**

**The schema-adherence premise weakens too, but less.** OpenRouter's own Tool
Call Error Rate exists because models return arguments that fail JSON Schema
validation — bucketed as `InvalidJson`, `UnknownName` and `SchemaMismatch`. The
`SchemaMismatch` bucket is the interesting one here: a Draft-7 validation
failure. Note that OpenRouter validates but does not reject; the metric is
observability, not enforcement. Note also the Draft-7 pinning — if the tool
schema relies on `unevaluatedProperties` or other 2019-09/2020-12 keywords to
close the object, OpenRouter's own validator would not enforce them, and by
extension a provider translating the schema may not either.

Three things follow, none of which require a decision here:

1. **The structural guarantee must be re-established client-side.** Whatever the
   provider does, the parsed response has to be rejected unless it is a tool call
   to the expected name with arguments that validate against the schema. The
   existing Anthropic client already walks content blocks and skips anything that
   is not `tool_use` with the expected name; that same discipline is what carries
   the guarantee across a provider that ignores forcing. A response that is not a
   conforming tool call should be a hard error, never a fallback to reading prose.
   This is stricter than "harden against unexpected provider replies" — it is the
   safety property itself.
2. **`provider.require_parameters: true` is the closest thing to a lever.** It is
   the one documented switch that stops a request being routed to a provider that
   would ignore the parameters. It does not promise the forcing is obeyed, only
   that the endpoint claims to accept it. Cost: fewer eligible endpoints, so more
   503s.
3. **Model choice narrows the risk but does not close it.** Requiring both `tools`
   and `tool_choice` in `supported_parameters` plus `image` in `input_modalities`
   leaves 202 models, and requiring `structured_outputs` on top leaves 187. That
   is a comfortable catalogue. But because `supported_parameters` is a union over
   endpoints, model-level filtering alone does not pin the behaviour of the
   endpoint that actually serves the request. Also worth noting: sorting by price
   (`provider.sort: "price"` or the `:floor` variant) opts out of Auto Exacto,
   which is the mechanism that steers tool-calling requests toward endpoints with
   better tool-call success rates. Cheapest-first and reliable-tool-calls are in
   direct tension.

The mechanical port is otherwise straightforward. `tool_choice:
{type:"function", function:{name:"log_meal_items"}}` maps 1:1 onto the current
Anthropic `{type:"tool", name:"log_meal_items"}`. Base64 WebP at 1024px maps onto
`{type:"image_url", image_url:{url:"data:image/webp;base64,..."}}` with
`image/webp` explicitly supported and 1024px nowhere near any plausible ceiling.
The one free improvement available is `tools[].function.strict: true`, though its
per-provider enforcement is undocumented. The one free correctness fix is
ordering the text part before the image part, which OpenRouter explicitly
recommends.

## What I could not establish from primary sources

- **Whether a named `tool_choice` is honoured by any specific model or provider
  endpoint.** OpenRouter documents the parameter and documents that routing is
  best-effort. It does not publish per-model or per-endpoint conformance for
  forcing, and there is no `tool_choice_honoured` flag anywhere in the Models API.
- **How `tools[].function.strict` is enforced.** The field exists and is
  described as "Enable strict schema adherence". The "enforcement varies by
  provider" caveat is documented for `response_format` structured outputs only.
  Applying it to tool `strict` is an inference.
- **Any OpenRouter-level image size or pixel-dimension limit.** Not stated
  anywhere. The error taxonomy explicitly defers to "the provider's maximum file
  size or pixel dimensions". The `payload_too_large` / 413 threshold for the
  request body as a whole is also unstated.
- **What actually happens when tools are sent to a model with no tool support, or
  an image to a text-only model.** No dedicated `error_type` covers either. The
  docs support inferring silent parameter-dropping for tools and routing-level
  filtering (surfacing as 503) for images, but neither is stated outright.
  Settling this needs a live probe, which I did not run.
- **Actual Tool Call Error Rate figures.** OpenRouter says they are on the
  Performance tab of every model page and in the AutoExacto Benchmarks card, but
  I found no public API that returns them, and did not scrape the rendered pages.
  Real numbers would turn the risk above from qualitative to quantitative and are
  worth pulling before committing to a provider list.
- **`input_modalities` as a Models API query parameter.** It works (verified
  live) but is not in the documented parameter list, so it could change without
  a deprecation notice.

## Sources

All fetched 2026-08-15.

- [Tool & Function Calling](https://openrouter.ai/docs/guides/features/tool-calling)
- [POST /api/v1/chat/completions OpenAPI reference](https://openrouter.ai/docs/api/api-reference/chat/create-a-chat-completion)
- [Parameters](https://openrouter.ai/docs/api_reference/parameters)
- [Provider Selection](https://openrouter.ai/docs/guides/routing/provider-selection)
- [Auto Exacto](https://openrouter.ai/docs/guides/routing/auto-exacto)
- [Structured Outputs](https://openrouter.ai/docs/guides/features/structured-outputs)
- [Image Inputs](https://openrouter.ai/docs/guides/overview/multimodal/image-understanding)
- [Multimodal Capabilities](https://openrouter.ai/docs/guides/overview/multimodal/overview)
- [Models](https://openrouter.ai/docs/guides/overview/models)
- [Errors and Debugging](https://openrouter.ai/docs/api_reference/errors-and-debugging)
- [Limits](https://openrouter.ai/docs/api_reference/limits)
- Live: `GET https://openrouter.ai/api/v1/models` (413 models)
- Live: `GET https://openrouter.ai/api/v1/models?supported_parameters=tools,tool_choice&input_modalities=image` (202 models)
- Live: `GET https://openrouter.ai/api/v1/models/anthropic/claude-sonnet-5/endpoints`
