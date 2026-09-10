# OpenAI behavioural screen (#684)

**Verdict: forced tool calls and the counts-never-measurements guarantee both
hold, on all three models, with no exceptions in 54 calls. Two model-quality
problems disqualify `gpt-5.4-mini` and weaken `gpt-5.4-nano`, and
`gpt-5.6-luna` is clean. One finding changes the failure taxonomy: OpenAI
answers an unknown model with 400, not 404.**

**The empty-answer rule is NOT answered here.** The non-food corpus from the
previous screen no longer exists on disk, and it was never committed — see
[The gap](#the-gap-the-empty-answer-rule) at the bottom. Everything else in
#684 is answered.

Run 2026-08-19 against the live API with `tool/live_openai.dart`, which drives
the **real** `ModelMealTextInterpreter` and `ModelMealPhotoInterpreter` through
a probe-local `MealItemsApi`. The shipping schema, prompts, `mealItemsFromJson`
and `validateParsedMealItems` are all exercised — not re-translated, which is
the mistake every probe before #673 made.

## What was measured

| | `gpt-5.4-nano` | `gpt-5.4-mini` | `gpt-5.6-luna` |
| :-- | :-- | :-- | :-- |
| Forced tool call returned as a tool call (text) | **7/7** | **7/7** | **7/7** |
| Forced tool call returned as a tool call (photo) | **11/11** | **11/11** | **11/11** |
| Unit outside the enum survived validation | 0 | 0 | 0 |
| Measurement leaked from a photo | **0** | **0** | **0** |
| Food photo wrongly returned empty | **0/11** | **0/11** | **0/11** |
| Spurious `serving` on a bare count | seen | seen | not seen |
| Duplicate rows for one food | 2 photos | **1 photo, 12 rows** | none |

54 successful calls, 0 failures, 0 prose replies.

## 1. Forced tool calls are reliable

Every one of 54 calls came back as a `function_call`, never prose. `tool_choice`
with an explicit `{'type': 'function', 'name': ...}` is honoured on the
Responses API across all three models, including with an image in the input.

`strict: false` must be sent explicitly. #683 predicted this and it is confirmed:
the schema has `quantity` and `unit` outside `required`, and Responses
normalises an unspecified `strict` into strict mode, which rejects exactly that
shape. Omitting the field is the dangerous option, not the neutral one.

## 2. The counts-never-measurements guarantee holds

**Zero measurements leaked in 33 photo calls.** No model attached a unit to
anything read from a photograph, so the discard path in
`ModelMealPhotoInterpreter` was never even exercised. Counts did come back —
17 rows carried `x1.0` — which is what the guarantee permits.

## 3. The unit enum held, and the 1000× litre bug did not reappear

`1.5 l milk` produced **1500 ml** on all three models. That is correct: the
model returns `l` and `validateParsedMealItems` normalises to ml. The #669 bug
was `1.5 l` → `1.5 ml`, a thousandfold under-count with nothing flagged because
a unit *was* stated. It did not recur.

`2 tbsp olive oil` produced quantity 2 with **no unit** on all three — the
prompt's "do not substitute a different unit" rule held, and no model mapped a
tablespoon onto grams.

## 4. Two model-quality problems

### Duplicate rows — disqualifying for `gpt-5.4-mini`

On a photo of a bunch of bananas, `gpt-5.4-mini` returned **twelve separate
`banana x1.0` rows**. In the app that is twelve diary entries from one
photograph, each needing individual deletion. `gpt-5.4-nano` duplicated more
mildly (`olive oil, olive oil, olive oil`; `яблоко, яблоки` — singular and
plural of the same fruit as two rows). `gpt-5.6-luna` returned `bananas`,
`apples` and `olive oil` as one row each.

Nothing in the schema or the validator forbids duplicates, and nothing should:
two separate eggs on a plate are legitimately two rows. This is a model-quality
difference, and it is the clearest separator in the matrix.

### Spurious `serving` on a bare count

Twice across two runs, a bare count came back carrying `unit: serving`:
`porridge 1.0 serving` (mini, run 1) and `Eier 2.0 serving` (nano, run 2).
**Intermittent — different models, different inputs, not reproducible on
demand.** `serving` is in the enum, so `validateParsedMealItems` accepts it,
and the review row then scales by serving size rather than using the bare-count
default. The logged amount changes silently.

`gpt-5.6-luna` did not do this in either run, but two runs is not evidence of
immunity.

## 5. The failure taxonomy diverges — 400, not 404

| condition | Anthropic | OpenRouter | **OpenAI** |
| :-- | :-- | :-- | :-- |
| bad key | 401 | 401 | **401** |
| unknown model | 404 | 404 | **400** |

> `The requested model 'gpt-does-not-exist' does not exist.` — HTTP **400**

This matters because #695 gave each client its own `_failureFor`, and the
obvious OpenAI mapping sends 400 to `rejected`. On the photo path `rejected`
means *"Couldn't use that image. Try another photo."* — advice that can never
work when the real problem is the model id. OpenAI reuses 400 for both, so
**status alone cannot separate them**; a direct client has to read the error
body, or accept that a model problem is reported as an image problem.

Not a blocker, and it costs nothing today because the curated list is fixed in
code — but it is a real difference from both shipped providers, and it is the
kind of thing #659 spent a ticket on.

## 6. One caveat about language

`gpt-5.4-nano` answered `яблоко, яблоки` — Russian — for a photo of apples,
with no locale in the request. The probe deliberately passes no `localeCode`,
and production always passes one, so this may not reproduce in the app. Worth a
single check when the real client is written rather than a ticket of its own.

## The gap: the empty-answer rule

**#684 asks for the non-food slice, and it could not be run.**

The corpus from #669 — 45 images, of which a 15-image slice was scored, with
the true answer being 13 empty and 2 with food — is not on disk. It was never
committed, which was the right call for photographs, but it means the
`42/45` and `15/15` baselines have nothing to compare against.

What was run instead is the *opposite* slice: 11 food-bearing photos from
`assets/demo/meals/`. That answers false negatives, and the answer is
**0/33 — no model wrongly returned empty for a photo with food in it.**

That is worth stating carefully, because it points the other way from #669:

> `openai/gpt-5.4-nano` returned empty for **both** food-bearing photos

— measured through OpenRouter. Here, direct, `gpt-5.4-nano` found food in
all eleven. **Different corpus, different route, so this is not a refutation.**
The candidates are that the OpenRouter path was the problem, that the two food
photos in that slice were unusually hard, or that the model changed. Naming
which would need the original images.

**Still unmeasured:** whether these models invent food in a photo that has
none. That is the false-positive direction, and it needs non-food images.

## The gap, partly closed (#719, 2026-08-19)

**No hallucination was observed — and the sample is too weak to conclude much
from that.** Both statements matter; the second is why this section exists
rather than a one-line "passed".

The #669 corpus is still gone, so a set was assembled from images already in
the repo, chosen so nothing personal left the machine:

| image | what it is | correct answer |
| :-- | :-- | :-- |
| `alex_demo_avatar.jpg` | a portrait photograph of a man | empty |
| `feature_graphic.png` | app logo — **a spoon** — plus "OpenNutriTracker" | empty |
| `banner_top.png` | the same mark and wordmark | empty |
| `logo.png` | the same mark | empty |
| `playstore_banner.png` | Google Play badge, pure text and chevron | empty |

**Scoring rule, fixed before the run** — #669 had to revise its own scoring
after seeing results, which is exactly the trap worth avoiding:

- returning **empty** is correct for all five;
- an item naming a **food that is not depicted** is a hallucination;
- an item naming **cutlery or brand text** is a lesser, separate error — wrong,
  but not invented food.

### Result: 5/5 empty on both shipped models

`gpt-5.6-luna` and `gpt-5.6-terra`, 10 calls, no failures, nothing returned.

The one genuinely informative case is the spoon. Two of the five images show
cutlery beside the word *"NutriTracker"*, which is about as strong a nudge
toward "this is about food" as a picture can carry without containing any.
Neither model took it.

### Why this is weak evidence

- **Five images, and only one is a photograph.** The other four are flat
  graphics with large areas of white. The failure mode worth fearing is a
  model looking at a cluttered real scene — #669's slice was office desks —
  and finding a snack in it. Nothing here tests that.
- **No comparability.** The recorded baselines (`claude-haiku` pinned 15/15,
  `gemini-3.7-flash` 15/15, direct Anthropic 42/45) were scored on different
  images. These numbers sit beside them only by coincidence of being fractions.
- **A null result on an easy set is close to unfalsifiable.** A model that
  hallucinates on real scenes would very likely still return empty for a Play
  Store badge.

**What would settle it** is 15–45 photographs of ordinary scenes containing no
food — rooms, desks, streets — run with
`ONLY=photo MODELS=gpt-5.6-luna,gpt-5.6-terra fvm dart run tool/live_openai.dart <key-file> <dir>`.
The harness handles jpg, webp and png. Whoever assembles that set should decide
first whether to keep near-misses in it: #669's slice contained a desk with a
tomato on it and another with a bottle of water, both of which two models
correctly found, and both of which had been mislabelled non-food.
