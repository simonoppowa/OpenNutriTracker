# Do Anthropic or OpenRouter distinguish exhausted credit from a rate limit?

**Verdict: yes — both, and by HTTP status alone.** Each provider answers
**402** when the account cannot pay and **429** when the account is going too
fast. No message-string parsing is required, and no body inspection is
required. The `billing` meaning can therefore be produced by both providers the
app already ships, today. It does not have to wait for OpenAI.

**The 402 belief about OpenRouter is confirmed, from OpenRouter's own error
documentation** — *"Your account or API key has insufficient credits. Add more
credits and retry the request."* listed against 402, and again in a typed table
as `payment_required`. It was not taken from a search summary; the quote was
grep-verified against the downloaded page.

|  | Anthropic | OpenRouter |
| --- | --- | --- |
| No credit / insufficient balance | **402** `billing_error` | **402** `payment_required` |
| Ordinary rate limit | **429** `rate_limit_error` | **429** `rate_limit_exceeded` |
| **Separable by status alone?** | **yes** | **yes** |
| Named code in the body | `error.type` | `error.metadata.error_type` |
| Arrives inside a 200? | no | **no** — explicitly excluded (see [B3](#b3-billing-never-arrives-inside-a-200)) |

Three things qualify this, none of which changes the verdict:

1. **Anthropic never writes "insufficient credits → 402" in one place.** Its 402
   is documented as *"There's an issue with your billing or payment
   information"*; the fact that an empty balance stops API calls is stated in a
   separate help-centre article that does not mention a status code. The join is
   an inference. It is a well-corroborated one — see [A2](#a2-the-join-anthropic-does-not-make).
2. **On OpenRouter, 402 is sufficient but not exhaustive.** A credit-based cap
   can also surface as **400** `token_limit_exceeded`, and a free-model daily
   quota surfaces as **429**. Details in [C](#c-the-third-case-quota-and-spend-caps).
3. **Today both clients map 402 to `transient`**, via the `_ =>` default in
   `_failureFor`. A user out of credit is currently told to try again later,
   forever — the exact loop the `billing` decision was written to prevent.

## How this was read

Primary sources only, all read on **2026-08-17**. No live call was made and no
key was used.

Anthropic's docs publish a Markdown twin at `…​.md`; both Anthropic pages were
downloaded that way and every quote below was **grep-verified verbatim against
the downloaded file**, not transcribed from a rendering or a summary.
OpenRouter's docs are client-rendered, so the pages were downloaded as HTML and
quotes verified against the raw markup — including the JSX payload, because
**the "HTTP Status" column of OpenRouter's typed-error tables renders empty in
the served HTML**; the statuses live in `HTTPStatus.S402_Payment_Required`-style
constants that are resolved in the browser. Every status in section B was read
out of those constants.

One search summary was checked against its source and **held up**: the
help-centre sentence quoted in [A2](#a2-the-join-anthropic-does-not-make) is
real and on the page attributed. The same check found that the article contains
no occurrence of the string `402` at all, which is why this note treats the
link as inference rather than documentation.

| Page read | URL | Date shown |
| --- | --- | --- |
| Claude API errors | [`/docs/en/api/errors`](https://platform.claude.com/docs/en/api/errors) | none |
| Claude API rate limits | [`/docs/en/api/rate-limits`](https://platform.claude.com/docs/en/api/rate-limits) | none |
| How do I pay for my API usage? | [`support.anthropic.com/…/8977456`](https://support.anthropic.com/en/articles/8977456-how-do-i-pay-for-my-api-usage) | none |
| OpenRouter — Errors and Debugging | [`/docs/api-reference/errors`](https://openrouter.ai/docs/api-reference/errors) | `dateModified` **2026-08-14** |
| OpenRouter — Limits | [`/docs/api-reference/limits`](https://openrouter.ai/docs/api-reference/limits) | `dateModified` **2026-08-08** |

## A. Anthropic

### A1. The two codes

From the error list, verbatim:

> * 402 - `billing_error`: There's an issue with your billing or payment information. Check your payment details in the [Claude Console](https://platform.claude.com), or in AWS Marketplace if you're using Claude Platform on AWS.

> * 429 - `rate_limit_error`: Your account has hit a rate limit.

Distinct statuses, distinct `type` strings. The body shape is a top-level
`error` object that *"always includes a `type` and `message` value"*, so the
string is available too if a client wants belt and braces — but it is not
needed to separate these two.

Note 403 is **not** the billing case here: it is `permission_error`, *"Your API
key does not have permission to use the specified resource."* The app's current
`401 || 403 => auth` mapping is right for Anthropic.

### A2. The join Anthropic does not make

The errors page says 402 is about *"billing or payment information"*. It does
not say "empty credit balance". The help-centre article says, verbatim and
verified:

> If you run out of credits, you will no longer be able to call the API or use Workbench.

That article never mentions a status code. So "zero balance ⇒ 402" is an
inference from two pages, not a documented statement on either.

Two things corroborate it. Anthropic's 402 is the only documented status in the
billing family, and 429 is documented narrowly as *"hit a rate limit"* with no
mention of money. And **OpenRouter, which implements an Anthropic-compatible
skin, maps its own `payment_required` (defined as insufficient credits) onto
Anthropic's `billing_error`** — a third party's reading of which Anthropic-native
code means "out of credit". That is corroboration, not Anthropic's word.

The rate-limits page contains no occurrence of `402` or `billing_error` in an
error context (checked by grep): the two concerns are documented apart, which is
consistent with them being separate statuses.

## B. OpenRouter

### B1. The two codes

From the `Error codes` list, verbatim:

> **402**: Your account or API key has insufficient credits. Add more credits and retry the request.

> **429**: You are being rate limited

And from the typed-error tables — `payment_required`, status **402**:

> The account or API key has insufficient credits. Add credits and retry.

`rate_limit_exceeded`, status **429**:

> Request- or token-level rate limit hit. Respect the `Retry-After` header before retrying.

The Limits page states the same split structurally: a two-row table whose
"Credit limits" row (*"How much you can spend (account balance and per-key
credit caps)"*) carries **402** in its "Error on exceeding" column, and whose
"Rate limits" row carries 429.

### B2. There is also a stable named code — and it is an enum, not prose

OpenRouter tags every error with a canonical string:

> When a provider error reaches your application, OpenRouter tags it with a canonical `error_type` string — both on the non-streaming response body and on mid-stream SSE events. Use this value, not the HTTP status code alone, to programmatically distinguish error categories. It is stable across all three API skins even when the native protocol code is lossy.

This is worth reading carefully, because it looks like it contradicts the
verdict and does not. OpenRouter is warning that **its status codes are lossy in
aggregate** — of the 27 documented `error_type` values, **13 share status 400**,
and two each share 404 and 500. But **402 and 429 each map to exactly one
`error_type`**, `payment_required` and `rate_limit_exceeded`. For the pair this
note is about the status is therefore sufficient. `error_type` is available as a
refinement, and it is a **closed enum**, not a message string, so consuming it
would not be the unstable thing the project is trying to avoid.

On the Chat Completions skin the app uses, it appears at
`error.metadata.error_type`. The Limits page shows it in a real 429 body:

```json
{ "error": { "code": 429, "message": "Rate limit exceeded",
             "metadata": { "error_type": "rate_limit_exceeded" } } }
```

### B3. Billing never arrives inside a 200

This matters because `openrouter_meal_items_api.dart` already carries a second
failure path for a 200 that is not a success. Billing does not use it:

> The HTTP Response will have the same status code as `error.code`, forming a request error if:
> * Your original request is invalid
> * **Your API key/account is out of credits**

Out-of-credit is named in the class that gets a real status line. Corroborated
by the pre-stream section — auth and rate-limit checks are applied *"before any
work begins"*, and mid-stream errors are listed as provider disconnect, provider
timeout, token limit during generation, output content filter, provider
overload. No billing case among them.

So the 402 will reach `_failureFor(response.statusCode)` on the status line, and
`_throwIfFailedGeneration` does not need to learn about billing.

### B4. One alarming-looking thing that does not apply here

OpenRouter documents a transformation turning certain limit errors into
*successes*: `context_length_exceeded`, `max_tokens_exceeded`,
**`token_limit_exceeded`** and `string_too_long` are each *"Transformed To"*
`Success` with finish reason `length`, so that limit errors are handled
*"without treating them as failures"*.

**That table sits under the Responses API skin (`/api/v1/responses`), not Chat
Completions** — confirmed structurally: it is an `h4` nested inside the `h3` for
`Responses API`, and the `Chat Completions (/api/v1/chat/completions)` section
above it has no such table. The app calls `/api/v1/chat/completions`, so a
credit-based cap will not silently arrive as a successful `length` completion.

## C. The third case: quota and spend caps

There is a distinct third case on both providers, and it is the messiest part of
the answer.

**Anthropic — monthly spend cap.** Documented as a real thing:

> Each of the Start, Build, and Scale tiers carries a monthly spend cap, which is the maximum your organization can spend on the API each calendar month. Once you reach your tier's spend cap, API usage pauses until the next month unless you request a higher limit.

Users can also set their own limit below the tier cap. **The status returned
when usage "pauses" is not documented on either page.** Either 402 or 429 is
plausible and neither is stated. This is listed under
[Not established](#not-established).

**OpenRouter — four sub-cases, and they do not share a status:**

| Case | Status | Notes |
| --- | --- | --- |
| Account balance at or below zero | **402** | *"If your account has a negative credit balance, you may see errors, including for free models."* |
| Per-key credit cap exhausted | **402** | Handled under the page's own *"Handling 402 errors"* heading: *"If `limit_remaining` on the key is exhausted, raise the key's credit limit or wait for it to reset"*. Resettable, but still 402. |
| Free-model daily/minute request cap | **429** | A quota that presents as a rate limit. |
| `token_limit_exceeded` | **400** | *"A token budget enforced by OpenRouter (e.g. credit-based cap) was exceeded."* |

The last two are the wrinkles.

A **free-model daily cap** is a 429, so "try again later" is technically correct
advice but "later" means tomorrow, not in sixty seconds. Nothing in the status
distinguishes it from a per-minute limit; `X-RateLimit-Reset` on the response
would, and `error_type` would not (both are `rate_limit_exceeded`).

**`token_limit_exceeded` is a 400 that is partly a billing condition** — its own
description names a credit-based cap. The app currently maps `400 => rejected`,
which for the photo path means telling the user something is wrong with their
image. This is the one case where status alone gives the wrong answer on
OpenRouter, and the only one where reading `error.metadata.error_type` buys
something real.

## D. Retryability

Both providers publish guidance, and both put billing outside the retryable set.

**Anthropic**, verbatim:

> The official SDKs automatically retry transient failures (such as connection errors, rate limits, and 5xx server errors) with exponential backoff, twice by default, honoring the `retry-after` header when present.

Rate limits are named as retryable. 402 is not in the list. A 429 carries a
`retry-after` header *"indicating how long to wait"*, plus `anthropic-ratelimit-*`
headers giving remaining quota and an RFC 3339 reset time.

**OpenRouter**, from the Limits page: for 429, *"Retry with exponential backoff.
Rate limits are transient; wait and retry rather than immediately re-sending.
Honor the `Retry-After` header when present."* For 402 the resolution steps are
all user actions — add credits, raise the key's cap, or wait for its reset.
`Retry-After` is documented on 429 and 503 only.

So the shape the `billing` meaning wants — *fatal until the user acts, retrying
will not help* — is what both providers' own guidance describes for 402.

## What this means for the two clients

Both `_failureFor` switches currently read:

```dart
401 || 403 => MealInterpreterFailure.auth,
400 || 422 => MealInterpreterFailure.rejected,
404 => MealInterpreterFailure.unsupported,
_   => MealInterpreterFailure.transient,
```

402 falls through to `transient` on both. Adding `402 => billing` is a one-line
change per client, needs no body parsing, and is justified by each provider's
own documentation rather than by OpenAI's. Whether to also catch OpenRouter's
`token_limit_exceeded` is a separate and much smaller question, and it does
require reading the body.

Noticed in passing and out of scope: OpenRouter's **403** is documented as
*"Forbidden (insufficient permissions, guardrail block, or moderation flag)"*,
so the current `403 => auth` mapping tells a user whose photo tripped a
moderation filter to go check their API key. Anthropic's 403 has no such
overload.

## Not established

- **What status Anthropic returns when a monthly spend cap or a self-set spend
  limit is reached.** The behaviour is documented ("usage pauses until the next
  month"); the status is not, on either page read. Not inferable — the case sits
  between 402 and 429 on the published descriptions.
- **Whether an empty Anthropic credit balance returns 402 specifically.** Argued
  in [A2](#a2-the-join-anthropic-does-not-make) as a strong inference from two
  pages plus OpenRouter's mapping. Not a documented sentence.
- **Whether OpenRouter's pre-stream 402 body carries
  `error.metadata.error_type`.** The typed-code section describes Chat
  Completions `error_type` as appearing on mid-stream chunks and on non-streaming
  responses *"when a provider error interrupts generation"*; the only pre-stream
  example body shown is a 429. Immaterial to the verdict, which rests on the
  status line.
- **OpenRouter's free-model request-per-minute and per-day numbers.** Rendered
  from client-side constants (`FREE_MODEL_RATE_LIMIT_RPM`,
  `FREE_MODEL_NO_CREDITS_RPD`) that the served HTML does not resolve.
- **Whether either provider's 402 is ever transient in practice.** Documentation
  says the user must act. Only a live account with a drained balance would
  confirm it, and this note made no calls.
- **Anthropic page dates.** Neither doc page displays a last-updated date, so
  the only guarantee offered is the read date, 2026-08-17. The OpenRouter dates
  in the table above come from `dateModified` in the pages' own structured data.

## Sources

Anthropic:
[Claude API errors](https://platform.claude.com/docs/en/api/errors) ·
[Rate limits](https://platform.claude.com/docs/en/api/rate-limits) ·
[How do I pay for my API usage?](https://support.anthropic.com/en/articles/8977456-how-do-i-pay-for-my-api-usage)

OpenRouter:
[Errors and Debugging](https://openrouter.ai/docs/api-reference/errors) ·
[Limits](https://openrouter.ai/docs/api-reference/limits)

Related notes in this repo:
[`ai-openai-wire-format.md`](ai-openai-wire-format.md) ·
[`ai-model-candidates.md`](ai-model-candidates.md) ·
[`ai-open-research-questions.md`](ai-open-research-questions.md)

In-repo files cited:
[`lib/features/add_meal/domain/meal_interpreter_exception.dart`](../lib/features/add_meal/domain/meal_interpreter_exception.dart) ·
[`lib/features/add_meal/data/anthropic_meal_items_api.dart`](../lib/features/add_meal/data/anthropic_meal_items_api.dart) ·
[`lib/features/add_meal/data/openrouter_meal_items_api.dart`](../lib/features/add_meal/data/openrouter_meal_items_api.dart)
