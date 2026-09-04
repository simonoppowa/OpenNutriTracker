# What Ollama, LM Studio, llama.cpp's server and vLLM actually expose

Research notes gathered 2026-08-20 against each project's own documentation and,
where the documentation was silent or ambiguous, against its own source. For
Ollama that meant `docs/api/openai-compatibility.mdx` plus `openai/openai.go`,
`middleware/openai.go`, `server/routes.go`, `server/images.go` and
`api/types.go`. For llama.cpp, `tools/server/README.md` plus
`tools/server/server.cpp`, `server-common.cpp/.h`, `server-http.cpp` and
`tools/mtmd/mtmd-helper.cpp`. For vLLM, `docs.vllm.ai` plus
`vllm/entrypoints/openai/**` and `vllm/multimodal/media/image.py`. LM Studio's
server is closed source, so it is documentation only — its docs site is
client-rendered, so every LM Studio quote below was taken from the Markdown
source in `github.com/lmstudio-ai/docs`, which is the same text the site
renders.

Nothing here rests on a blog post, a tutorial or a Stack Overflow answer. **No
server was installed, started or called.** Everything that needs a running
server to answer is in [Not verified](#not-verified) rather than guessed at, and
that section is deliberately long: three of the four runtimes leave at least one
question the docs simply do not address.

Written to answer [#733](https://github.com/simonoppowa/OpenNutriTracker/issues/733)
on map [#732](https://github.com/simonoppowa/OpenNutriTracker/issues/732). The
thing being matched against is the request
[`OpenRouterMealItemsApi`](../lib/features/add_meal/data/openrouter_meal_items_api.dart)
already puts on the wire, and the schema in
[`meal_items_api.dart`](../lib/features/add_meal/domain/meal_items_api.dart) —
`query` required, `quantity` and `unit` optional, `additionalProperties: false`,
no `strict` field.

## Bottom line up front

1. **Nothing rejects the extra fields, so the routing block is not the reason to
   fork the client.** All four accept unknown top-level keys and ignore them.
   vLLM says so in a code comment — *"OpenAI API does allow extra fields"* — and
   sets `extra="allow"`, logging ignored keys at **debug** level only. Ollama
   binds into a Go struct that has no `provider` field, using gin's
   `ShouldBindJSON`; neither `DisallowUnknownFields` nor
   `EnableDecoderDisallowUnknownFields` appears anywhere in `ollama/ollama`.
   llama.cpp reads named keys with a `json_value` helper and then **copies every
   remaining top-level property through** into its internal params object, where
   unknown keys are inert. LM Studio's docs say *"All parameters recognized by
   `/v1/chat/completions` will be honored"* and nothing about unrecognised ones
   — that is the one gap ([Not verified](#not-verified)). So `provider`,
   `require_parameters`, `data_collection` and `allow_fallbacks` are dead weight
   on a local server, not a 400.
2. **The thing that actually diverges is the forced `tool_choice`, and only
   vLLM honours it.** This is the finding that costs something, because the
   forced call is how the app gets a parseable answer at all.
   - **vLLM**: full support, in exactly the bytes the app sends. Validated
     against `tools`, then enforced by the structured-outputs backend — *"You
     are guaranteed a validly-parsable function call - not a high-quality
     one."*
   - **llama.cpp**: `tool_choice` is parsed as a **string**, and an object is
     **silently downgraded to `"auto"`**. `json_value` catches the type error
     and returns the default with a server-side log line. No 400, no 500 — the
     request succeeds with the forcing quietly discarded.
   - **Ollama**: `tool_choice` is not supported at all. The compatibility doc
     lists it as an unchecked box, and `ChatCompletionRequest` in
     `openai/openai.go` has no such field. Dropped on the floor.
   - **LM Studio**: documented values are `"auto"`, `"none"` and `"required"`
     only. A named-function object appears nowhere in its documentation, and
     `"required"` is annotated *"(llama.cpp only)"* — i.e. not on the MLX
     engine.
   With one tool defined, `tool_choice: "required"` is semantically what the app
   wants and is available on vLLM, llama.cpp (with `--jinja`) and LM Studio's
   llama.cpp engine. On Ollama there is no forcing of any kind, and the app is
   back to prompt-and-hope with `_itemsFrom` raising
   `'response has no tool call'` when the model answers in prose. That is a
   handled failure, not a wrong number — the guarantee in
   [#683](https://github.com/simonoppowa/OpenNutriTracker/issues/683) holds —
   but it is a *usefulness* cliff on the most popular of the four runtimes.
3. **The photo path has a format problem, and it is llama.cpp's.**
   `MealPhotoEncoder` produces `image/webp` on the normal path. llama.cpp
   decodes images with `stbi_load_from_memory` from `stb_image.h`, whose
   documented format list the server README repeats as *"jpeg, png, tga, bmp,
   gif, ..."* — **no WebP**. llama.cpp's own web UI ships
   `tools/ui/src/lib/utils/webp-to-png.ts`, which converts WebP to PNG in the
   browser before sending, which is about as clear a confirmation as a source
   tree can give. Ollama is the mirror image: `decodeImageURL` accepts exactly
   `jpeg`, `jpg`, `png`, `webp` and rejects everything else with `400 invalid
   image input` — so WebP is fine and the encoder's **GIF fallback is not**.
   vLLM decodes with Pillow's `Image.open` and ignores the declared media type
   entirely.
4. **No schema rewrite is needed anywhere.** Nothing here has OpenAI's
   strict-mode rule that every key in `properties` must also appear in
   `required`. LM Studio's own tool-calling example uses a schema with
   `"required": ["query"]`, two optional properties and
   `additionalProperties: false` — structurally identical to
   `mealItemsToolSchema`. vLLM feeds the schema straight to a JSON-Schema
   constrained-decoding backend; its docs *recommend* the OpenAI strict style
   *"For best compatibility with strict schema enforcement"* but explicitly do
   not require it for named or `"required"` tool choice. `strict` itself is
   accepted by vLLM (it changes behaviour only for `tool_choice: "auto"`) and
   silently dropped by Ollama and llama.cpp, which have no such field.
5. **Auth is optional on all four, and a bearer token sent to a keyless server
   is ignored rather than refused.** Ollama documents *"No authentication is
   required when accessing Ollama's API locally"* and its own example passes
   `api_key='ollama',  # required but ignored`. llama.cpp's middleware opens
   with *"If API key is not set, skip validation"*. vLLM only registers its
   authentication middleware when a key is configured. LM Studio: *"By default,
   LM Studio does not require authentication for API requests."* So the app can
   send the header unconditionally without breaking a keyless server — but it
   should not, because on a LAN address that is a credential leaked to whatever
   answered.
6. **`/v1/models` is enough to populate a picker on three of the four, and
   useless for capability on all four.** Ollama returns `{id, object, created,
   owned_by}` for every pulled model and nothing else. vLLM returns `{id,
   object, created, owned_by, root, parent, max_model_len, permission}` for the
   model it was started with. LM Studio returns *"the models visible to the
   server"*, which *"may include all downloaded models when Just-In-Time loading
   is enabled"*. llama.cpp in single-model mode returns *"one single element"* —
   the `-m` path, or `--alias` if set — so there is nothing to pick from.
   **Neither vision nor tool support is on any of those four responses.** Both
   flags exist, but on non-OpenAI paths: LM Studio's `GET /api/v1/models`
   carries `capabilities.vision` and `capabilities.trained_for_tool_use`;
   Ollama's `POST /api/show` carries `capabilities: ["completion", "vision"]`;
   llama-server **in router mode** puts `architecture.input_modalities:
   ["text","image"]` on the same handler that serves `/v1/models`. vLLM
   publishes nothing equivalent.
7. **Only vLLM and llama.cpp can serve TLS, and neither does by default.** vLLM
   takes `--ssl-keyfile`/`--ssl-certfile`. llama.cpp takes
   `--ssl-key-file`/`--ssl-cert-file` and needs a build with
   `-DLLAMA_OPENSSL=ON`, otherwise it logs *"the server is built without SSL
   support"*. Ollama has no TLS at all — `ListenAndServeTLS`, `tls.Config` and
   `OLLAMA_TLS` return **zero** hits across the whole repository, and the FAQ's
   answer to exposing it is *"can be exposed using a proxy server such as
   Nginx"*. LM Studio's documentation contains no TLS or HTTPS server option;
   its own answer to leaving localhost is `lms server start --bind 0.0.0.0` plus
   a recommendation to turn authentication on. **Plain HTTP is the default
   everywhere and the only option on two of the four.**
8. **The failure taxonomy does not survive the port.** Three concrete
   divergences, all measured against `_failureFor`: a **404 means "model not
   found"** on Ollama and vLLM — not "no endpoint supports this capability", and
   `MealInterpreterFailure.unsupported` is roughly the right bucket by accident
   rather than by design. **llama.cpp answers 500 for a capability problem**:
   sending `tools` to a server started without `--jinja` throws a
   `std::runtime_error`, and its `ex_wrapper` maps `std::invalid_argument` to
   400 and *everything else* to 500. The app would call that transient and tell
   the user to check their network forever. And llama.cpp has a **501**
   (`not_supported_error`) that no current provider emits.

## The four at a glance

| | Ollama | LM Studio | llama.cpp `llama-server` | vLLM |
| --- | --- | --- | --- | --- |
| Default bind | `127.0.0.1:11434` | `localhost:1234` | `127.0.0.1:8080` | port `8000` |
| Chat path | `/v1/chat/completions` | `/v1/chat/completions` | `/v1/chat/completions` **and** `/chat/completions` | `/v1/chat/completions` |
| `/v1/models` exists | yes | yes | yes | yes |
| …fields | `id, object, created, owned_by` | not enumerated in docs | `id, object, created, owned_by, meta{n_ctx_train, n_params, …}` | `id, object, created, owned_by, root, parent, max_model_len, permission` |
| …lists more than one model | yes, every pulled model | yes (all downloaded, if JIT on) | **no** — one element, unless in router mode | the served model(s) |
| …flags vision | no (`/api/show` does) | no (`/api/v1/models` does) | only in router mode | no |
| …flags tool support | no | no (`/api/v1/models` does) | no | no |
| Accepts OpenAI `tools[]` | yes | yes | **only with `--jinja`** | yes |
| Forced `tool_choice` by name | **no field at all** | **undocumented**; `auto`/`none`/`required` only | **silently downgraded to `auto`** | **yes, enforced** |
| `tool_choice: "required"` | no | yes, *"llama.cpp only"* | yes | yes, enforced |
| Optional properties in schema | fine | fine (own example does it) | fine | fine |
| `strict` on a tool | ignored (no field) | not documented | ignored (no field) | accepted; matters only for `auto` |
| `image_url: {"url": "data:…"}` | **yes** (bare string too) | **undocumented** | **yes** | **yes** |
| Image formats | `jpeg`, `jpg`, `png`, `webp` only | undocumented | stb_image set — **no WebP** | whatever Pillow opens |
| Remote image URL | **refused** | undocumented | accepted | accepted (5 s fetch timeout) |
| API key | none locally | optional toggle + tokens | optional `--api-key` | optional `--api-key` |
| Bearer sent to keyless server | ignored | ignored (docs imply) | ignored (explicit in source) | ignored (middleware not mounted) |
| Unknown top-level fields | ignored | *not established* | copied through, inert | ignored, logged at debug |
| HTTPS | **none** | **none documented** | `--ssl-*`, needs OpenSSL build | `--ssl-keyfile`/`--ssl-certfile` |
| Model not pulled/loaded | 404 | *not established* | 404 (router) / n/a | 404 `NotFoundError` |
| Tools to an incapable model | **400** `"…does not support tools"` | falls back to a prompt shim | **500** without `--jinja` | *not established* |

## A. What the existing client sends, field by field

Read against
[`openrouter_meal_items_api.dart`](../lib/features/add_meal/data/openrouter_meal_items_api.dart).
"Survives" means the exact bytes it already builds are accepted and mean the
same thing.

| What it sends | Survives? | Note |
| --- | --- | --- |
| `model` | yes, everywhere | the *value* is a local identifier — a pulled tag, a GGUF path, an alias, a HF repo id |
| `max_tokens: 1024` | yes, everywhere | Ollama and LM Studio document it; llama.cpp aliases it to `n_predict`; vLLM accepts it but marks it *"deprecated in favor of the max_completion_tokens field"* |
| `messages[0]` as `role: "system"` | yes, everywhere | |
| text part `{"type":"text","text":…}` | yes on Ollama, llama.cpp, vLLM; undocumented on LM Studio | Ollama's source accepts exactly `text`, `image_url` and `input_audio` and returns `invalid message format` for anything else |
| image part `{"type":"image_url","image_url":{"url":"data:…"}}` | yes on Ollama, llama.cpp, vLLM | see [Section E](#e-vision) |
| text **before** image | yes | none of the four documents an ordering requirement |
| `tools[]` with the `function` wrapper | yes on Ollama, LM Studio, vLLM; llama.cpp needs `--jinja` | |
| no `strict` key | correct on all four | nothing here normalises an absent `strict` into strict mode the way OpenAI's Responses API does |
| `tool_choice` named object | **vLLM only** | see [Section D](#d-tool-calling) |
| `provider{require_parameters, data_collection, only, allow_fallbacks}` | inert on all four | see [Section C](#c-the-extra-fields) |
| `authorization: Bearer …` header | harmless but wrong | see [Section F](#f-auth) |
| `x-openrouter-metadata: enabled` header | inert | there is nothing to name; `_warnIfThePinDidNotHold` has no input |
| reading `choices[0].message.tool_calls[].function.arguments` as a **JSON string** | yes, everywhere | all four emit the OpenAI Chat Completions envelope; Ollama marshals `arguments` back to a string explicitly in `ToToolCalls` |
| treating `finish_reason: "error"` as a failed generation | harmless | that value is an OpenRouter extension; none of the four produces it, so `_throwIfFailedGeneration` is simply never entered |

**The conclusion this table points at:** the *body* generalises almost perfectly.
What does not generalise is a short, enumerable list — the endpoint, the
`tool_choice` shape, the `provider` block, the auth header, the metadata header
and the status-code table. See [Section I](#i-so-does-this-need-a-fourth-client).

## B. Base URLs, ports and paths

**Ollama.** `http://localhost:11434/v1/`, and the FAQ is explicit: *"Ollama
binds 127.0.0.1 port 11434 by default. Change the bind address with the
`OLLAMA_HOST` environment variable."* The OpenAI-compatible surface is a real
`/v1` prefix served by middleware in front of the native handlers —
`r.POST("/v1/chat/completions", …, middleware.ChatMiddleware(), s.ChatHandler)`.
`/v1/models`, `/v1/models/{model}`, `/v1/completions`, `/v1/embeddings` and (as
of v0.13.3) `/v1/responses` are also served.

**LM Studio.** `http://localhost:1234/v1`. The overview page says *"Note: The
following examples assume the server port is `1234`"* and the port is a
configurable server setting. Supported OpenAI-compatible endpoints are
`/v1/models`, `/v1/responses`, `/v1/chat/completions`, `/v1/embeddings`,
`/v1/completions`. Two other surfaces exist alongside: the legacy `/api/v0/*`
REST API and the current `/api/v1/*` REST API, both of which return richer model
metadata than `/v1/models` does.

**llama.cpp.** *"by default listens on `127.0.0.1:8080`"*, `--host` and `--port`
to change it. Both prefixed and unprefixed paths are registered for most
endpoints — `/v1/chat/completions` **and** `/chat/completions`, `/v1/models`
**and** `/models` — so a base URL with or without `/v1` reaches the same
handler. Only `/health` and `/v1/health` skip the API-key check.

**vLLM.** Port `8000` by default. `vllm serve` examples use
`base_url="http://localhost:8000/v1"`. One warning from vLLM's own page is worth
carrying into any UI copy, because it bears on the privacy claim rather than on
compatibility:

> The `--api-key` option (or `VLLM_API_KEY` environment variable) only
> authenticates requests to endpoints under the `/v1`, `/v2`, and `/inference`
> path prefixes. Other endpoints on the same HTTP server are **not**
> authenticated — most notably `/invocations`, which exposes the same inference
> capabilities as the `/v1` endpoints.

## C. The extra fields

This is the item that decides the client architecture, so it is answered from
source in every case where source exists.

**vLLM — accepted and ignored, by design.** `OpenAIBaseModel`, which every
request model inherits from:

```python
class OpenAIBaseModel(BaseModel):
    # OpenAI API does allow extra fields
    model_config = ConfigDict(extra="allow")
```

and a `__log_extra_fields__` validator whose entire effect is one
`logger.debug("The following fields were present in the request but ignored: %s", …)`.
Not a warning, not an error.

**Ollama — dropped at the struct boundary.** `ChatMiddleware` calls
`c.ShouldBindJSON(&req)` into `openai.ChatCompletionRequest`, whose fields are
`model`, `messages`, `stream`, `stream_options`, `max_tokens`, `seed`, `stop`,
`temperature`, `frequency_penalty`, `presence_penalty`, `top_p`,
`response_format`, `tools`, `reasoning`, `reasoning_effort`, `logprobs`,
`top_logprobs` and an internal `_debug_render_only`. Gin's default JSON binding
does not disallow unknown fields, and a search of `ollama/ollama` for
`DisallowUnknownFields` and `EnableDecoderDisallowUnknownFields` returns zero
hits for both, against four hits for `ShouldBindJSON`. Anything not in that list
— `provider`, `tool_choice`, `strict`, `user`, `n` — is discarded silently.

**llama.cpp — copied through and then ignored.** After reading the keys it knows
about, `oaicompat_chat_params_parse` ends with:

```cpp
// Copy remaining properties to llama_params
// This allows user to use llama.cpp-specific params like "mirostat", ... via OAI endpoint.
for (const auto & item : body.items()) {
    if (!llama_params.contains(item.key()) || item.key() == "n_predict") {
        llama_params[item.key()] = item.value();
    }
}
```

so a `provider` object lands in the internal params blob and is never read. The
only fields llama.cpp actively *refuses* are `best_of` and `suffix` — *"Params
supported by OAI but unsupported by llama.cpp"* — plus `echo` set to true. None
of those is anything the app sends.

**LM Studio — not established.** The closest its documentation comes is *"All
parameters recognized by `/v1/chat/completions` will be honored"*, on the tool
use page. That says what happens to recognised parameters and nothing about the
rest, and the server is closed source. See [Not verified](#not-verified).

## D. Tool calling

### D1. Does a forced `tool_choice` work?

**vLLM — yes, and it is the only unambiguous yes.** The request model types it
as `Literal["none"] | Literal["auto"] | Literal["required"] |
ChatCompletionNamedToolChoiceParam | None`, and a `check_tool_usage` validator
runs before anything else: it rejects a missing `tools`, rejects a value that is
neither `"auto"`/`"required"` nor an object, rejects an object without a
`function` dict or without a string `name`, and rejects a name that *"does not
match any of the specified `tools`"*. All of those raise `VLLMValidationError`,
which maps to **400** with `param` set to `tool_choice`. Once past validation,
enforcement is real:

> vLLM supports named function calling in the chat completion API by default.
> … You are guaranteed a validly-parsable function call - not a high-quality
> one.

and from the constrained-decoding table, for a named function: *"Arguments are
guaranteed to be valid JSON conforming to the function's parameter schema."*

**llama.cpp — no, and it fails in the worst available way.** The parser takes a
string:

```cpp
common_chat_tool_choice common_chat_tool_choice_parse_oaicompat(const std::string & tool_choice) {
    if (tool_choice == "auto")     { return COMMON_CHAT_TOOL_CHOICE_AUTO; }
    if (tool_choice == "none")     { return COMMON_CHAT_TOOL_CHOICE_NONE; }
    if (tool_choice == "required") { return COMMON_CHAT_TOOL_CHOICE_REQUIRED; }
    throw std::invalid_argument("Invalid tool_choice: " + tool_choice);
}
```

but that `throw` is unreachable for an object, because the value is read as
`json_value(body, "tool_choice", std::string("auto"))` and `json_value` is:

```cpp
try {
    return body.at(key);
} catch (NLOHMANN_JSON_NAMESPACE::detail::type_error const & err) {
    LOG_WRN("Wrong type supplied for parameter '%s'. Expected '%s', using default value: %s\n", …);
    return default_value;
}
```

So `{"type":"function","function":{"name":"log_meal_items"}}` becomes `"auto"`,
the request succeeds, and the only trace is a warning in the server operator's
terminal. A client cannot detect this from the response. **If the app targets
llama.cpp it must send the string `"required"`**, which llama.cpp does enforce:
`COMMON_CHAT_TOOL_CHOICE_REQUIRED` sets the grammar's minimum tool-call count to
1 and switches off lazy grammar triggering across every template handler.

**Ollama — no.** The compatibility doc's supported-fields list for
`/v1/chat/completions` has `- [ ] tool_choice`, and the struct confirms it. The
practical consequence: with `tools` present, a capable model *may* emit a tool
call and Ollama will parse it, but nothing obliges it to.

**LM Studio — string values only, per its own changelog.** From the 0.3.15
entry, *"Improved Tool Use API Support"*:

> `"tool_choice": "none"` — Model will not call tools
> `"tool_choice": "auto"` — Model decides
> `"tool_choice": "required"` — Model must call tools (llama.cpp only)

A named-function object is not among them, and the parenthesis matters: LM
Studio runs GGUF models on llama.cpp and MLX models on its own `mlx-engine`, and
`"required"` is only claimed for the former.

### D2. Does the schema's optional properties cause trouble?

No, and this is the least eventful answer in the note. None of the four
implements OpenAI's strict-mode requirement that every key in `properties` also
appear in `required`.

- **LM Studio** publishes a worked `curl` example whose tool schema is
  `"required": ["query"]` with `category` and `max_price` optional and
  `"additionalProperties": false` — the same shape as `mealItemsToolSchema`,
  down to the required key being called `query`.
- **vLLM** hands the schema to a structured-outputs backend, which speaks JSON
  Schema. Its *Strict Mode* section recommends the OpenAI style — *"Set
  `additionalProperties` to `false`… Mark all fields in `properties` as
  required… Represent optional fields by allowing `null`"* — but prefixes it
  with *"For best compatibility with strict schema enforcement"*, and the table
  above it says constrained decoding applies to named and `"required"` choices
  **regardless of the `strict` field**.
- **Ollama** unmarshals `parameters` into `ToolFunctionParameters{Type, $defs,
  Items, Required, Properties}` where each property is a `ToolProperty{anyOf,
  type, items, description, enum, properties, required}`. Nested objects,
  arrays, enums and per-object `required` all survive. `additionalProperties`
  has no field and is dropped — which is consistent with the schema's own
  comment that it is *"documentation of intent rather than a defence"*.
- **llama.cpp** builds a grammar from the tool schema. Its only schema-adjacent
  refusal is *"Cannot use custom grammar constraints with tools."* — a
  `std::invalid_argument`, so 400 — which fires when a request carries both
  `tools` and a top-level `grammar`. The app sends no `grammar`.

Sending `strict` either way changes nothing on Ollama and llama.cpp (no such
field) and, on vLLM, changes nothing for a named or `"required"` choice. LM
Studio does document `strict` — but on `response_format.json_schema`, which is a
different feature from tool calling.

### D3. What a client gets back

All four return the OpenAI Chat Completions envelope with
`choices[0].message.tool_calls[]`, each carrying `function.name` and
`function.arguments` **as a JSON string**. Ollama's `ToToolCalls` marshals the
arguments map back to a string explicitly. LM Studio documents the same shape
and adds that *"The `finish_reason` field of the top-level response object will
also be populated with `"tool_calls"`."* `_itemsFrom` and `_argumentsFrom`
transfer unchanged.

## E. Vision

**Ollama — the data-URI object form works, and the format list is short.**
`FromChatRequest` accepts `image_url` as **either** an object with a `url` key
**or** a bare string, so the exact part the app builds today is fine. (Ollama's
own examples use the bare-string form, which is not OpenAI-shaped; the object
form is handled first in the source.) Then:

```go
func decodeImageURL(url string) (api.ImageData, error) {
    if strings.HasPrefix(url, "http://") || strings.HasPrefix(url, "https://") {
        return nil, errors.New("image URLs are not currently supported, please use base64 encoded data instead")
    }
    types := []string{"jpeg", "jpg", "png", "webp"}
    …
}
```

Anything whose prefix is not `data:image/{jpeg,jpg,png,webp};base64,` (or the
bare `data:;base64,`) returns `invalid image input`, which `ChatMiddleware`
turns into **400**. So `image/webp` — the app's normal output — is accepted, and
`image/gif`, which `MealPhotoEncoder._mediaTypes` can produce when the device
has no WebP encoder, is **not**.

**llama.cpp — the object form works; WebP does not.** The README documents the
part shape precisely: *"If `type == "image_url"`: `image_url.url` can be a remote
URL, base64 (raw or URI-encoded via `data:image/...;base64`) or path to local
file"*, and *"Accepts formats supported by `stb_image` (jpeg, png, tga, bmp,
gif, ...)"*. `tools/mtmd/mtmd-helper.cpp` defines `STB_IMAGE_IMPLEMENTATION` and
decodes with `stbi_load_from_memory`. stb_image has no WebP decoder, and
llama.cpp's own web UI carries `webpBase64UrlToPngDataURL` to convert WebP to
PNG on the client before upload. Multimodality is also gated on the build and
the run: the README calls it *"currently an experimental feature"* and it
requires a multimodal projector to be loaded.

**vLLM — the object form works and the declared media type is ignored.** Its
multimodal guide's own base64 example is
`{"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}`.
`ImageMediaIO.load_base64(media_type, data)` discards `media_type` and calls
`load_bytes`, which is `Image.open(BytesIO(data))` — so the format question is
"what can this Pillow build open", and WebP is in Pillow's standard set. One
documented rejection worth knowing: if `width × height` exceeds
`VLLM_MAX_IMAGE_PIXELS` the loader raises a `ValueError`, and vLLM maps
`ValueError` to **400**. The docs also note *"`image_url.detail` parameter is not
supported"*, which the app does not send.

**LM Studio — undocumented.** Its OpenAI-compatibility overview describes the
endpoint as *"Chat Completions (text and images)"* and stops there. The string
`image_url` appears **nowhere** in `lmstudio-ai/docs`. Its own `/api/v1/chat`
endpoint uses a different shape entirely — `{"type": "image", "data_url":
"data:image/png;base64,…"}` — which is evidence about the native API and not
about the compatibility layer. Whether `/v1/chat/completions` accepts the
OpenAI `image_url` object, a bare string, or either, is a live-server question.

**Which models can see at all** is per-model on every runtime, and only two of
them will tell a client: LM Studio's `GET /api/v1/models` has
`capabilities.vision: boolean`, and Ollama's `POST /api/show` has
`capabilities: ["completion", "vision"]`. Both are outside the OpenAI-compatible
surface. llama-server's router mode reports `architecture.input_modalities`
containing `"image"` on the handler bound to both `/models` and `/v1/models`.
vLLM offers nothing.

## F. Auth

| Runtime | Key concept | Default | Bearer to a keyless server |
| --- | --- | --- | --- |
| Ollama | none for local; `OLLAMA_API_KEY` is for `ollama.com`, not for a local server | no auth | ignored — no field reads it |
| LM Studio | API tokens with per-token permissions, behind a *Require Authentication* switch | off | ignored (docs state the default; behaviour not verified) |
| llama.cpp | `--api-key`, `--api-key-file`, `LLAMA_API_KEY`; comma-separated list | none | ignored — *"If API key is not set, skip validation"* |
| vLLM | `--api-key` / `VLLM_API_KEY` | none | ignored — middleware only mounted `if tokens := …` |

Ollama's own quickstart is the clearest statement of the shape of this problem:
its Python example passes `api_key='ollama',  # required but ignored` — the key
exists to satisfy the OpenAI SDK's client constructor, not the server. Its
authentication page: *"No authentication is required when accessing Ollama's API
locally via `http://localhost:11434`."*

Where a key **is** set, all four take `Authorization: Bearer <key>`. llama.cpp
additionally falls back to an `X-Api-Key` header for Anthropic-shaped clients,
and returns `401 {"error":{"message":"Invalid API Key","type":"authentication_error","code":401}}`
on a mismatch. vLLM returns `401 {"error": "Unauthorized"}` — note that shape is
**not** the OpenAI error envelope, so a client that parses `error.message` finds
a string where it expected an object.

This bears on `AiSelection.apiKey` being a non-nullable `String`, as #732
records: the correct behaviour for this provider is to omit the header when the
user supplied nothing, not to send `Bearer ` with an empty value.

## G. HTTPS

- **Ollama: none.** No TLS listener exists. The FAQ's answer is a reverse proxy
  (*"Ollama runs an HTTP server and can be exposed using a proxy server such as
  Nginx"*), or `ngrok`/`cloudflared` with a rewritten host header.
- **LM Studio: none documented.** The server settings are Port, Require
  Authentication, Serve on Local Network, MCP toggles, CORS and JIT loading.
  There is no certificate setting, and the page on leaving localhost recommends
  authentication rather than TLS: *"Any bind other than `127.0.0.1` exposes the
  server beyond `localhost`; we recommend enabling authentication."*
- **llama.cpp: optional, and needs the right build.** `--ssl-key-file FNAME`
  and `--ssl-cert-file FNAME`, both PEM, with *"`llama-server` can also be built
  with SSL support using OpenSSL 3"* via `-DLLAMA_OPENSSL=ON`. A binary built
  without it logs *"the server is built without SSL support"* and refuses to
  start with those flags.
- **vLLM: optional.** `--ssl-keyfile`, `--ssl-certfile`, plus `--ssl-ca-certs`,
  `--ssl-cert-reqs`, `--ssl-ciphers` and `--enable-ssl-refresh`.

In every case a user who turns TLS on for a home server is almost certainly
using a self-signed certificate, which is a second problem and not this ticket's.

## H. Failure shapes

**Ollama** publishes a status-code list: `200`, `400` *"(missing parameters,
invalid JSON, etc.)"*, `404` *"(model doesn't exist, etc.)"*, `429`, `500`,
`502` *"(e.g. when a cloud model cannot be reached)"*. The body is
`{"error": "…"}` natively, and the compatibility middleware rewrites it into
`{"error":{"type":…,"message":…}}` while **preserving the status code**, with
`type` being `invalid_request_error` for 400, `not_found_error` for 404 and
`api_error` otherwise.

Three specific cases, from `server/routes.go` and `server/images.go`:

- **Model not pulled** → `404` with `model %q not found, try pulling it first`.
- **Tools to a model with no tool capability** → `400`. `ChatHandler` appends
  `model.CapabilityTools` to the requested capabilities whenever `tools` is
  non-empty; `CheckCapabilities` fails with `errCapabilities` (`"does not
  support"`) joined with `errCapabilityTools` (`"tools"`), and
  `handleScheduleError` maps `errCapabilities` to `http.StatusBadRequest`.
- **Image to a text-only model** → **no check exists**. `ChatHandler` never adds
  `model.CapabilityVision` to the requested set, even when the message carries
  images. The image is decoded, the request proceeds, and what the model does
  with pixels it has no projector for is a runtime question this note cannot
  answer.

**llama.cpp** maps its internal error enum to status codes in
`format_error_response`: `400 invalid_request_error`, `401
authentication_error`, `403 permission_error`, `404 not_found_error`, `500
server_error`, `501 not_supported_error`, `503 unavailable_error`, and the
README confirms *"`llama-server` returns errors in the same format as OAI"*.
The trap is which exceptions reach which code — `ex_wrapper`:

```cpp
} catch (const std::invalid_argument & e) {
    // treat invalid_argument as invalid request (400)
} catch (const std::exception & e) {
    // treat other exceptions as server error (500)
```

`"tools param requires --jinja flag"` and `"tool_choice param requires --jinja
flag"` are both `std::runtime_error`, so **a server started without `--jinja`
answers a tool request with 500**. That is a permanent configuration problem
wearing a transient status code, and it is the single most likely first-run
failure for this provider.

**vLLM** maps its exception hierarchy explicitly: `VLLMValidationError` → 400
with the offending `param`; `VLLMUnprocessableEntityError` → 422;
`VLLMNotFoundError` → 404; any other client error → 400; raw `ValueError`,
`TypeError`, `OverflowError` → 400; `NotImplementedError` → 501; server errors →
500. A model name it was not started with produces `404` *"The model `X` does
not exist."*

**LM Studio** publishes no status-code table. Its changelog notes that *"Errors
returned from streaming endpoints now follow the correct format expected by
OpenAI clients"*, which implies the non-streaming ones already did, but that is
an inference and not a specification.

**What this costs `_failureFor`.** The current table reads 401→auth,
400/403/422→rejected, 402→billing, 404→unsupported, else→transient. Ported
unchanged to a local server it gets three things wrong: 404 becomes *"you named
a model this box does not have"*, which `unsupported` covers by luck rather than
design and which wants a different message ("pull it, or pick another"); 402 is
unreachable, since none of these has billing; and 500 is the one status a local
server most needs to *not* be transient, because llama.cpp uses it for the
missing-`--jinja` case. 501 and 502 are new arrivals with no current arm.

## I. So: does this need a fourth client?

The evidence says **the OpenRouter client generalises**, and the
divergence list is short enough to enumerate:

1. `_endpoint` becomes a constructor field instead of a `static const`.
2. The `provider` block is omitted. Not because anything rejects it — nothing
   does — but because every one of its four keys is a statement about a broker
   that is not in the path, and a request that asserts `data_collection: "deny"`
   to a machine in the user's own house is a claim the app cannot mean.
3. `tool_choice` becomes the string `"required"` rather than a named function,
   or is omitted for Ollama. This is the only change that alters what the model
   is asked to do.
4. The `authorization` header is sent only when the user supplied a key, and
   `x-openrouter-metadata` is dropped along with `_warnIfThePinDidNotHold`,
   which has no metadata to check.
5. `_failureFor` becomes a per-provider table rather than a `static` one — which
   the existing doc comment already argues for: *"the same number does not mean
   the same thing to every provider."*

Everything below that line — `_contentJson`, `_itemsFrom`, `_argumentsFrom`,
`mealItemsFromJson`, `validateParsedMealItems`, the tool wrapper, the data-URI
image, the arguments-as-a-string decode — is byte-identical across all four
runtimes and across OpenRouter.

That is the opposite of the situation that made `AnthropicMealItemsApi` and
`OpenRouterMealItemsApi` two classes. The reason recorded there is that the two
*"agree on nothing"* about shape: a different tool wrapper, a different image
carrier, a reversed part order, a different arguments type, a different failure
envelope. Here the shape is the same and only the *policy* differs. Five
constructor parameters is not "a chain of provider checks"; it is what a
parameter is for.

Two caveats the build ticket should carry. First, `tool_choice` is a genuine
behavioural fork, not a formatting one, and it is the place a shared class would
first grow a real branch — worth making an explicit mode on the constructor
rather than an `if`. Second, none of this touches the parts of #732 that remain
open: the 20-second `defaultTimeout` is unaffected by anything measured here and
is still wrong for a 7B model on a laptop CPU, and cleartext is still refused by
both platforms before any of this code runs.

## Not verified

Everything below needs a running server, or a vendor who publishes more than
they currently do. This is the input to whatever ticket stands one up.

- **Whether LM Studio rejects unknown top-level fields.** The single most
  important gap, because it is the one runtime that could turn finding 1 from
  "all four" into "three of four". Its server is closed source and its docs say
  only that recognised parameters are honoured. One request carrying a
  `provider` block settles it.
- **Whether LM Studio's `/v1/chat/completions` accepts the OpenAI `image_url`
  content part, and in which form.** `image_url` appears nowhere in its
  documentation. Its native endpoint uses `{"type":"image","data_url":…}`.
- **Whether LM Studio accepts a named-function `tool_choice` anyway.** Absence
  from a changelog is not a rejection. If it accepts one, the next question is
  whether it enforces it or downgrades it the way llama.cpp does.
- **What LM Studio returns for a model that is not loaded, for an image sent to
  a text-only model, and for a malformed tool schema.** No status-code table is
  published at all.
- **What LM Studio's `/v1/models` response actually contains.** The docs give
  the endpoint and a `curl` line and no response body.
- **What Ollama does with an image sent to a model with no vision capability.**
  Established from source: there is no capability check on this path, so it is
  not a 400. What it *is* — a silently text-only answer, a runner error, a 500 —
  is unknown.
- **Whether llama.cpp actually refuses a WebP data URI, and with what status.**
  The stb_image inference is strong and the web UI's converter corroborates it,
  but the failure path from `mtmd_helper_bitmap_init_from_buf` to an HTTP status
  was not traced. Under `ex_wrapper` a non-`invalid_argument` throw is a 500.
- **Whether a llama.cpp server started without `--jinja` really answers 500 for
  a `tools` request.** Traced through `ex_wrapper` and the `std::runtime_error`
  throw, not observed. This one matters enough to confirm before writing user
  copy for it.
- **Whether `tool_choice: "required"` on Ollama does anything at all.** The
  field does not exist in the struct, so the expectation is "ignored", but the
  behavioural question — how often a small local model volunteers a tool call
  unprompted with one tool defined — is the real question and it is a
  measurement, not a reading.
- **What vLLM returns for an image sent to a text-only model.** Its
  `ValueError`→400 mapping suggests 400, but no primary source names the case
  or the message.
- **Whether a stock Pillow build in a vLLM container decodes WebP.** Pillow
  ships WebP support by default; a container that stripped `libwebp` would not.
- **Ollama's behaviour when the model string names a cloud model.** The chat
  handler has a `modelSourceCloud` branch that proxies to ollama.com and can
  return `401` with a `signin_url`. A user typing a `-cloud` suffix would be
  sending their photograph off their own machine, which is exactly the thing
  this provider exists to avoid, and the app has no way to tell from the model
  list that it happened.
- **Latency and timeout behaviour on any of the four.** Nothing measured. #732's
  20-second `defaultTimeout` question is untouched by this note.
- **Whether any of the four surfaces a "model is loading" state distinguishable
  from a hang.** llama.cpp's router publishes `status.value: "loading"` on
  `/models` and LM Studio's `/api/v1/models` has `loaded_instances`, but neither
  appears in a chat-completions response, and Ollama's JIT load simply blocks.

## Sources

Ollama (own docs and source, `main` as of 2026-08-20):
[OpenAI compatibility](https://github.com/ollama/ollama/blob/main/docs/api/openai-compatibility.mdx) — endpoint list, supported request fields, the `tool_choice` unchecked box, the vision example, `api_key='ollama', # required but ignored` ·
[Authentication](https://github.com/ollama/ollama/blob/main/docs/api/authentication.mdx) — no local auth ·
[Errors](https://github.com/ollama/ollama/blob/main/docs/api/errors.mdx) — status-code list and error body ·
[Vision](https://github.com/ollama/ollama/blob/main/docs/capabilities/vision.mdx) ·
[Tool calling](https://github.com/ollama/ollama/blob/main/docs/capabilities/tool-calling.mdx) ·
[API reference](https://github.com/ollama/ollama/blob/main/docs/api.md) — `/api/tags`, `/api/show` with `capabilities` ·
[FAQ](https://github.com/ollama/ollama/blob/main/docs/faq.mdx) — default bind, no TLS, Nginx guidance ·
[`openai/openai.go`](https://github.com/ollama/ollama/blob/main/openai/openai.go) — `ChatCompletionRequest` fields, `Model` fields, `decodeImageURL`, `ToToolCalls`, `NewError` ·
[`middleware/openai.go`](https://github.com/ollama/ollama/blob/main/middleware/openai.go) — `ShouldBindJSON`, 400 on bind failure, error-status passthrough ·
[`server/routes.go`](https://github.com/ollama/ollama/blob/main/server/routes.go) — route table, capability set for chat, `handleScheduleError` ·
[`server/images.go`](https://github.com/ollama/ollama/blob/main/server/images.go) — `errCapabilities`, `CheckCapabilities` ·
[`api/types.go`](https://github.com/ollama/ollama/blob/main/api/types.go) — `Tool`, `ToolProperty`, `ToolFunctionParameters`

llama.cpp (`master` as of 2026-08-20):
[`tools/server/README.md`](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md) — host/port, `--api-key`, `--ssl-*`, `/v1/models` body, multimodal part shapes and stb_image formats, `--jinja`, router mode, API errors ·
[`tools/server/server.cpp`](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/server.cpp) — `ex_wrapper` status mapping, full route table, router rebinding of `get_models` ·
[`tools/server/server-common.cpp`](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/server-common.cpp) — `format_error_response`, `tool_choice` read, unsupported-param list, the copy-remaining-properties loop ·
[`tools/server/server-common.h`](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/server-common.h) — `json_value` type-error fallback, `error_type` enum ·
[`tools/server/server-http.cpp`](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/server-http.cpp) — API-key middleware, 401 body, SSL build guard ·
[`common/chat.h`](https://github.com/ggml-org/llama.cpp/blob/master/common/chat.h) · [`common/chat.cpp`](https://github.com/ggml-org/llama.cpp/blob/master/common/chat.cpp) — `common_chat_tool_choice`, `common_chat_tool_choice_parse_oaicompat`, `REQUIRED` grammar effects ·
[`tools/mtmd/mtmd-helper.cpp`](https://github.com/ggml-org/llama.cpp/blob/master/tools/mtmd/mtmd-helper.cpp) — `STB_IMAGE_IMPLEMENTATION`, `stbi_load_from_memory` ·
[`tools/ui/src/lib/utils/webp-to-png.ts`](https://github.com/ggml-org/llama.cpp/blob/master/tools/ui/src/lib/utils/webp-to-png.ts) — the web UI's client-side WebP→PNG conversion ·
[`docs/function-calling.md`](https://github.com/ggml-org/llama.cpp/blob/master/docs/function-calling.md) — contains no `tool_choice` guidance, which is itself the finding

vLLM (`main` as of 2026-08-20):
[OpenAI-Compatible Server](https://docs.vllm.ai/en/latest/serving/online_serving/openai_compatible_server/) — supported APIs, `--api-key` warning, `image_url.detail` unsupported, extra parameters ·
[Tool Calling](https://github.com/vllm-project/vllm/blob/main/docs/features/tool_calling.md) — named function calling guarantee, `"required"`, the constrained-decoding table, Strict Mode ·
[Multimodal Inputs](https://github.com/vllm-project/vllm/blob/main/docs/features/multimodal_inputs.md) — data-URI example, fetch timeouts, `--allowed-local-media-path` ·
[`vllm/entrypoints/openai/engine/protocol.py`](https://github.com/vllm-project/vllm/blob/main/vllm/entrypoints/openai/engine/protocol.py) — `OpenAIBaseModel` `extra="allow"`, `__log_extra_fields__`, `ModelCard` ·
[`vllm/entrypoints/openai/chat_completion/protocol.py`](https://github.com/vllm-project/vllm/blob/main/vllm/entrypoints/openai/chat_completion/protocol.py) — `tool_choice` type and `check_tool_usage`, `max_tokens` deprecation ·
[`vllm/entrypoints/openai/cli_args.py`](https://github.com/vllm-project/vllm/blob/main/vllm/entrypoints/openai/cli_args.py) — port 8000, `api_key`, `ssl_*` ·
[`vllm/entrypoints/serve/middleware/authenticate.py`](https://github.com/vllm-project/vllm/blob/main/vllm/entrypoints/serve/middleware/authenticate.py) · [`register.py`](https://github.com/vllm-project/vllm/blob/main/vllm/entrypoints/serve/middleware/register.py) — conditional mounting, `GUARDED_PREFIX`, 401 body ·
[`vllm/entrypoints/serve/exception_handling/error_response.py`](https://github.com/vllm-project/vllm/blob/main/vllm/entrypoints/serve/exception_handling/error_response.py) — exception→status map ·
[`vllm/entrypoints/serve/engine/serving.py`](https://github.com/vllm-project/vllm/blob/main/vllm/entrypoints/serve/engine/serving.py) — `The model X does not exist.` ·
[`vllm/multimodal/media/image.py`](https://github.com/vllm-project/vllm/blob/main/vllm/multimodal/media/image.py) — `Image.open`, `VLLM_MAX_IMAGE_PIXELS`

LM Studio (docs only; source of the rendered site is
[`lmstudio-ai/docs`](https://github.com/lmstudio-ai/docs)):
[OpenAI Compatibility Endpoints](https://lmstudio.ai/docs/developer/openai-compat) — endpoint list, port 1234 ·
[Chat Completions](https://lmstudio.ai/docs/developer/openai-compat/chat-completions) — supported payload parameters ·
[List Models](https://lmstudio.ai/docs/developer/openai-compat/models) — JIT note ·
[Tool Use](https://lmstudio.ai/docs/developer/openai-compat/tools) — native vs default tool support, the optional-properties example, *"All parameters recognized…"* ·
[Structured Output](https://lmstudio.ai/docs/developer/openai-compat/structured-output) — `response_format.json_schema`, grammar/Outlines backends ·
[REST API v0](https://lmstudio.ai/docs/developer/rest/endpoints) — `type: "vlm"` on `/api/v0/models` ·
[List your models (`/api/v1/models`)](https://github.com/lmstudio-ai/docs/blob/main/1_developer/2_rest/list.md) — `capabilities.vision`, `capabilities.trained_for_tool_use` ·
[Authentication](https://lmstudio.ai/docs/developer/core/authentication) — default is no auth ·
[Server Settings](https://lmstudio.ai/docs/developer/core/server/settings) · [Serve on Local Network](https://lmstudio.ai/docs/developer/core/server/serve-on-network) — no TLS option, `--bind 0.0.0.0` ·
[API changelog](https://github.com/lmstudio-ai/docs/blob/main/1_developer/api-changelog.md) — the `tool_choice` value list and the *"llama.cpp only"* note

Related notes in this repo:
[`ai-openai-wire-format.md`](ai-openai-wire-format.md) ·
[`ai-model-candidates.md`](ai-model-candidates.md) ·
[`ai-open-research-questions.md`](ai-open-research-questions.md)

In-repo files cited:
[`lib/features/add_meal/data/openrouter_meal_items_api.dart`](../lib/features/add_meal/data/openrouter_meal_items_api.dart) ·
[`lib/features/add_meal/domain/meal_items_api.dart`](../lib/features/add_meal/domain/meal_items_api.dart) ·
[`lib/features/add_meal/util/meal_photo_encoder.dart`](../lib/features/add_meal/util/meal_photo_encoder.dart) ·
[`lib/features/add_meal/data/anthropic_meal_items_api.dart`](../lib/features/add_meal/data/anthropic_meal_items_api.dart)
