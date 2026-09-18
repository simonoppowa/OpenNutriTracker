# Live portion corpus — photo path (#1160)

11 photographs from `assets/demo/meals`, 3 passes each, app language `en`; 2026-09-18T19:23:59.985797Z.

## Calls a real run of this harness makes

Per provider: **11** photos × 3 passes = **33** calls, every one carrying a photo.

Providers: `anthropic` (`claude-haiku-4-5`), `openrouter` (`anthropic/claude-haiku-4.5`), `openai` (`gpt-5.6-luna`) — **99** calls across 3. Retries are not counted here; a transient failure is retried up to three times.

## The prompt sentences as run

**Schema, `portion` description:**

> How the food was portioned, as one English word whatever language the user wrote in — slice, piece, cup, tablespoon, teaspoon, small, medium, large. Write abbreviations out. Never a weight, a count, or a unit from the unit list. Omit when the user named no portion.

**Photo prompt, the portion bullet:**

> - If you counted items and can see their size, you may add "portion": "small", "medium" or "large". Nothing else belongs in "portion" from a photograph — no cups, bowls, slices or handfuls.

<details><summary>The whole photo system prompt</summary>

```
You identify the foods visible in a photograph of a meal so they can be
looked up in a food database. You do not estimate nutrition, and you do not
estimate weight or volume.

Rules:
- One entry per distinct food you can see. A composed dish a person would
  log as one thing ("lasagne", "chicken curry") is one entry, not a list of
  its ingredients.
- "query" is the food name alone, with no amount in it, in the user's app
  language. Keep a brand only if it is legible in the photo.
- Only include "quantity" when you can count discrete items: 2 eggs, 3
  sausages, 1 banana. A count has no unit, so never include "unit".
- For anything you cannot count — rice, salad, sauce, soup, a drink — omit
  "quantity". Do not guess grams or millilitres from a photograph. The app
  asks the user for the amount, and a guess they cannot check is worse than
  no answer.
- If you counted items and can see their size, you may add "portion":
  "small", "medium" or "large". Nothing else belongs in "portion" from a
  photograph — no cups, bowls, slices or handfuls.
- Only list food you can actually identify. If you cannot tell what a dish
  is, describe it plainly ("meat stew") rather than naming a specific
  recipe you are guessing at.
- If the photo contains no food, return an empty list.
```

</details>

## The guard, as shipped (#1156)

Applied to each item after `validateParsedMealItems`: a `unit` strips the count and the key with it; a fraction strips both too; a key with no count is dropped; a whole count keeps the key only when, trimmed and lower-cased, it is exactly `small`, `medium` or `large`; any other word is dropped and the count stays. *app* is what the interpreter's own `_sizesOnly(_countsOnly(...))` returned for the same item — the guard as it ships — and *guard disagrees* counts the items where the harness's restatement, which exists to say why a word was dropped, and the app differ on what the row keeps. A kept size is matched through `matchPortionToKey` against the English label, the first try `_initialUnit` makes under a count; the resolver is the app's own path (see the text report).

## Summary per provider

| provider | model | calls | failed | items | unpaired items | key arrived | arrived as a size word | kept by guard | dropped: container | dropped: piece | dropped: size-like, not one of three | dropped: other | dropped: no count | dropped: fraction | dropped: unit | guard disagrees with app | resolved (of kept) | has_portion on the row (of resolved) | with rows (of resolved) | matched (of resolved) | ties | middle rung | quiet misses | unstable photos | latency p50 / p95 / max |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| anthropic | `claude-haiku-4-5` | 33 | 0 | 72 | 0 | 2/72 (2.8%) | 1/2 (50.0%) | 0/2 (0.0%) | 0 | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0 | 0 | 0 | 8/11 | 906 / 1552 / 1729 ms |
| openrouter | `anthropic/claude-haiku-4.5` | 33 | 0 | 74 | 0 | 2/74 (2.7%) | 0/2 (0.0%) | 0/2 (0.0%) | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0 | 0 | 0 | 7/11 | 1407 / 1792 / 2879 ms |
| openai | `gpt-5.6-luna` | 33 | 0 | 83 | 0 | 4/83 (4.8%) | 4/4 (100.0%) | 4/4 (100.0%) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 4/4 (100.0%) | 4/4 (100.0%) | 4/4 (100.0%) | 3/4 (75.0%) | 2 | 0 | 1 | 6/11 | 1398 / 3457 / 9486 ms |

## Every item

| provider | photo | pass | query | raw qty | raw unit | raw key | validated qty/unit | guard | kept key | app qty/key | resolved | match |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| anthropic | 1548807371 | 1 | oatmeal porridge |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1548807371 | 1 | hazelnut |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1548807371 | 1 | peanut |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1548807371 | 1 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1548807371 | 2 | oatmeal |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1548807371 | 2 | banana |  |  | `small` | – / – | noCount |  | – / – |  |  |
| anthropic | 1548807371 | 2 | peanuts |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1548807371 | 2 | chocolate chips |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1548807371 | 3 | oatmeal |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1548807371 | 3 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1548807371 | 3 | peanuts |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1548807371 | 3 | hazelnuts |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1552056413 | 1 | white bread | 3.0 |  | `slice` | 3.0 / – | pieceWord |  | 3.0 / – |  |  |
| anthropic | 1552056413 | 2 | bread |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1552056413 | 3 | bread |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1567306226 | 1 | apple |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1567306226 | 2 | apple |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1567306226 | 3 | apple |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 1 | sour cream |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 1 | garlic |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 1 | parsley |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 1 | lemon |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 1 | mint |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 2 | sour cream |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 2 | garlic |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 2 | cilantro |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 2 | lemon |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 2 | mint |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 3 | sour cream |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 3 | garlic |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 3 | lemon |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 3 | parsley |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1571212515 | 3 | mint |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1593357849 | 1 | tempura |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1593357849 | 1 | rice |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1593357849 | 1 | miso soup |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1593357849 | 1 | noodle soup |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1593357849 | 2 | tempura |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1593357849 | 2 | miso soup |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1593357849 | 3 | tempura |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1593357849 | 3 | rice |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1593357849 | 3 | soup |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1627820752 | 1 | cashews |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1627820752 | 2 | cashews |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1627820752 | 3 | cashews |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1646161762 | 1 | cabbage |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1646161762 | 2 | cabbage |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1646161762 | 3 | cabbage |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1739785938 | 1 | raw salmon |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1739785938 | 2 | tuna |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1739785938 | 3 | raw fish |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1757332050 | 1 | banana | 3.0 |  |  | 3.0 / – | noKey |  | 3.0 / – |  |  |
| anthropic | 1757332050 | 2 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1757332050 | 3 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1757801333 | 1 | olive oil |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1757801333 | 2 | Olive oil |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1757801333 | 3 | olive oil |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 1 | grilled chicken |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 1 | mashed potatoes |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 1 | vegetables |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 2 | grilled chicken breast |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 2 | mashed potatoes |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 2 | green beans |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 2 | red bell pepper |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 2 | yellow bell pepper |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 2 | mushrooms |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 3 | grilled chicken breast |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 3 | mashed potatoes |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 3 | green beans |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 3 | red bell pepper |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 3 | yellow bell pepper |  |  |  | – / – | noKey |  | – / – |  |  |
| anthropic | 1762631934 | 3 | mushrooms |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1548807371 | 1 | oatmeal porridge |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1548807371 | 1 | hazelnuts |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1548807371 | 1 | peanuts |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1548807371 | 1 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1548807371 | 2 | oatmeal |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1548807371 | 2 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1548807371 | 2 | peanuts |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1548807371 | 2 | chocolate chips |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1548807371 | 3 | oatmeal porridge |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1548807371 | 3 | peanuts |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1548807371 | 3 | chocolate chips |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1548807371 | 3 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1552056413 | 1 | white bread | 3.0 |  | `slice` | 3.0 / – | pieceWord |  | 3.0 / – |  |  |
| openrouter | 1552056413 | 2 | bread | 4.0 |  | `slice` | 4.0 / – | pieceWord |  | 4.0 / – |  |  |
| openrouter | 1552056413 | 3 | bread |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1567306226 | 1 | apple |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1567306226 | 2 | apple |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1567306226 | 3 | apple |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 1 | sour cream |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 1 | fresh mint |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 1 | garlic |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 1 | lemon |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 1 | parsley |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 2 | sour cream |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 2 | garlic |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 2 | lemon |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 2 | fresh coriander |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 3 | sour cream |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 3 | fresh mint |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 3 | garlic |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 3 | lemon |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1571212515 | 3 | parsley |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1593357849 | 1 | tempura |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1593357849 | 1 | soup |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1593357849 | 1 | noodle soup |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1593357849 | 2 | tempura shrimp and vegetables |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1593357849 | 2 | rice |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1593357849 | 2 | soup |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1593357849 | 2 | noodle soup |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1593357849 | 3 | tempura shrimp and vegetables |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1593357849 | 3 | miso soup |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1593357849 | 3 | noodle soup |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1627820752 | 1 | cashews |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1627820752 | 2 | cashews |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1627820752 | 3 | cashews |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1646161762 | 1 | cabbage |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1646161762 | 2 | cabbage |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1646161762 | 3 | cabbage |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1739785938 | 1 | tuna |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1739785938 | 2 | raw tuna |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1739785938 | 3 | raw tuna |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1757332050 | 1 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1757332050 | 2 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1757332050 | 3 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1757801333 | 1 | olive oil |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1757801333 | 1 | virgin oil |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1757801333 | 2 | olive oil |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1757801333 | 3 | olive oil |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 1 | grilled chicken breast |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 1 | mashed potatoes |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 1 | grilled vegetables |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 2 | grilled chicken breast |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 2 | mashed potatoes |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 2 | green beans |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 2 | red bell pepper |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 2 | yellow bell pepper |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 2 | mushroom |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 3 | grilled chicken breast |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 3 | mashed potatoes |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 3 | peas |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 3 | carrots |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 3 | green beans |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 3 | red bell pepper |  |  |  | – / – | noKey |  | – / – |  |  |
| openrouter | 1762631934 | 3 | yellow bell pepper |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 1 | oatmeal |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 1 | banana | 1.0 |  |  | 1.0 / – | noKey |  | 1.0 / – |  |  |
| openai | 1548807371 | 1 | walnuts |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 1 | almonds |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 1 | hazelnuts |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 1 | dates |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 1 | cinnamon |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 2 | oatmeal |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 2 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 2 | walnuts |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 2 | almonds |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 2 | hazelnuts |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 2 | cashews |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 2 | cinnamon |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 3 | oatmeal |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 3 | banana | 1.0 |  | `medium` | 1.0 / – | kept | medium | 1.0 / medium | Banana, raw (has_portion true; 5 rows) | miss (quiet) |
| openai | 1548807371 | 3 | walnuts |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 3 | almonds |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 3 | hazelnuts |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 3 | pecans |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1548807371 | 3 | cinnamon |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1552056413 | 1 | bread |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1552056413 | 2 | brioche bread |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1552056413 | 3 | brioche bread |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1567306226 | 1 | apple |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1567306226 | 2 | apple |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1567306226 | 3 | apple | 1.0 |  | `medium` | 1.0 / – | kept | medium | 1.0 / medium | Apple, raw (has_portion true; 7 rows) | `1 medium` 200.0 g |
| openai | 1571212515 | 1 | yogurt |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 1 | mint |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 1 | garlic | 1.0 |  |  | 1.0 / – | noKey |  | 1.0 / – |  |  |
| openai | 1571212515 | 1 | lemon | 2.0 |  |  | 2.0 / – | noKey |  | 2.0 / – |  |  |
| openai | 1571212515 | 1 | parsley |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 1 | coriander |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 2 | yogurt |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 2 | mint |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 2 | parsley |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 2 | cilantro |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 2 | garlic |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 2 | lemon |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 2 | orange |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 3 | yogurt |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 3 | mint |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 3 | parsley |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 3 | cilantro |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 3 | garlic |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 3 | lemon |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1571212515 | 3 | orange |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1593357849 | 1 | tempura |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1593357849 | 1 | rice |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1593357849 | 1 | miso soup |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1593357849 | 1 | noodle soup |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1593357849 | 2 | rice |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1593357849 | 2 | tempura |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1593357849 | 2 | miso soup |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1593357849 | 2 | noodle soup |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1593357849 | 3 | rice |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1593357849 | 3 | tempura |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1593357849 | 3 | miso soup |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1593357849 | 3 | noodle soup |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1627820752 | 1 | cashews |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1627820752 | 2 | cashews |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1627820752 | 3 | cashews |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1646161762 | 1 | savoy cabbage |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1646161762 | 2 | savoy cabbage |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1646161762 | 3 | savoy cabbage |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1739785938 | 1 | salmon |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1739785938 | 2 | salmon |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1739785938 | 3 | salmon |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1757332050 | 1 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1757332050 | 2 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1757332050 | 3 | banana |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1757801333 | 1 | olive oil |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1757801333 | 2 | olive oil |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1757801333 | 3 | olive oil |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1762631934 | 1 | grilled chicken breast | 1.0 |  |  | 1.0 / – | noKey |  | 1.0 / – |  |  |
| openai | 1762631934 | 1 | rice |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1762631934 | 1 | mixed vegetables |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1762631934 | 2 | grilled chicken breast | 1.0 |  | `large` | 1.0 / – | kept | large | 1.0 / large | Chicken breast, grilled with sauce, skin eaten (has_portion true; 9 rows) | `1 large breast` 195.0 g **tie** with `1 large or thick slice` |
| openai | 1762631934 | 2 | couscous |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1762631934 | 2 | grilled vegetables |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1762631934 | 3 | grilled chicken breast | 1.0 |  | `large` | 1.0 / – | kept | large | 1.0 / large | Chicken breast, grilled with sauce, skin eaten (has_portion true; 9 rows) | `1 large breast` 195.0 g **tie** with `1 large or thick slice` |
| openai | 1762631934 | 3 | couscous |  |  |  | – / – | noKey |  | – / – |  |  |
| openai | 1762631934 | 3 | grilled vegetables |  |  |  | – / – | noKey |  | – / – |  |  |

## Container and piece words that arrived (the case #1156 forbids) (3)

- anthropic 1552056413-b8b5eed0170b.jpg pass 1: `white bread` 3.0 × `slice` → pieceWord, count 3.0
- openrouter 1552056413-b8b5eed0170b.jpg pass 1: `white bread` 3.0 × `slice` → pieceWord, count 3.0
- openrouter 1552056413-b8b5eed0170b.jpg pass 2: `bread` 4.0 × `slice` → pieceWord, count 4.0

## Items where the restated guard and the app's disagree (0)

_none_

## Items whose raw reply could not be paired (recorded, not dropped) (0)

_none_

## Call failures (0)

_none_

## Backend failures (0)

_none_

## Unstable across passes (21)

- anthropic 1548807371-30dc1bbe6cb5.jpg
  - oatmeal porridge|null|null|null ~ hazelnut|null|null|null ~ peanut|null|null|null ~ banana|null|null|null
  - oatmeal|null|null|null ~ banana|null|null|small ~ peanuts|null|null|null ~ chocolate chips|null|null|null
  - oatmeal|null|null|null ~ banana|null|null|null ~ peanuts|null|null|null ~ hazelnuts|null|null|null
- anthropic 1552056413-b8b5eed0170b.jpg
  - white bread|3.0|null|slice
  - bread|null|null|null
  - bread|null|null|null
- anthropic 1571212515416-fef01fc43637.jpg
  - sour cream|null|null|null ~ garlic|null|null|null ~ parsley|null|null|null ~ lemon|null|null|null ~ mint|null|null|null
  - sour cream|null|null|null ~ garlic|null|null|null ~ cilantro|null|null|null ~ lemon|null|null|null ~ mint|null|null|null
  - sour cream|null|null|null ~ garlic|null|null|null ~ lemon|null|null|null ~ parsley|null|null|null ~ mint|null|null|null
- anthropic 1593357849627-cbbc9fda6b05.jpg
  - tempura|null|null|null ~ rice|null|null|null ~ miso soup|null|null|null ~ noodle soup|null|null|null
  - tempura|null|null|null ~ miso soup|null|null|null
  - tempura|null|null|null ~ rice|null|null|null ~ soup|null|null|null
- anthropic 1739785938237-73b3654200d5.jpg
  - raw salmon|null|null|null
  - tuna|null|null|null
  - raw fish|null|null|null
- anthropic 1757332050958-b797a022c910.jpg
  - banana|3.0|null|null
  - banana|null|null|null
  - banana|null|null|null
- anthropic 1757801333069-f7b3cabaec4a.jpg
  - olive oil|null|null|null
  - Olive oil|null|null|null
  - olive oil|null|null|null
- anthropic 1762631934518-f75e233413ca.jpg
  - grilled chicken|null|null|null ~ mashed potatoes|null|null|null ~ vegetables|null|null|null
  - grilled chicken breast|null|null|null ~ mashed potatoes|null|null|null ~ green beans|null|null|null ~ red bell pepper|null|null|null ~ yellow bell pepper|null|null|null ~ mushrooms|null|null|null
  - grilled chicken breast|null|null|null ~ mashed potatoes|null|null|null ~ green beans|null|null|null ~ red bell pepper|null|null|null ~ yellow bell pepper|null|null|null ~ mushrooms|null|null|null
- openrouter 1548807371-30dc1bbe6cb5.jpg
  - oatmeal porridge|null|null|null ~ hazelnuts|null|null|null ~ peanuts|null|null|null ~ banana|null|null|null
  - oatmeal|null|null|null ~ banana|null|null|null ~ peanuts|null|null|null ~ chocolate chips|null|null|null
  - oatmeal porridge|null|null|null ~ peanuts|null|null|null ~ chocolate chips|null|null|null ~ banana|null|null|null
- openrouter 1552056413-b8b5eed0170b.jpg
  - white bread|3.0|null|slice
  - bread|4.0|null|slice
  - bread|null|null|null
- openrouter 1571212515416-fef01fc43637.jpg
  - sour cream|null|null|null ~ fresh mint|null|null|null ~ garlic|null|null|null ~ lemon|null|null|null ~ parsley|null|null|null
  - sour cream|null|null|null ~ garlic|null|null|null ~ lemon|null|null|null ~ fresh coriander|null|null|null
  - sour cream|null|null|null ~ fresh mint|null|null|null ~ garlic|null|null|null ~ lemon|null|null|null ~ parsley|null|null|null
- openrouter 1593357849627-cbbc9fda6b05.jpg
  - tempura|null|null|null ~ soup|null|null|null ~ noodle soup|null|null|null
  - tempura shrimp and vegetables|null|null|null ~ rice|null|null|null ~ soup|null|null|null ~ noodle soup|null|null|null
  - tempura shrimp and vegetables|null|null|null ~ miso soup|null|null|null ~ noodle soup|null|null|null
- openrouter 1739785938237-73b3654200d5.jpg
  - tuna|null|null|null
  - raw tuna|null|null|null
  - raw tuna|null|null|null
- openrouter 1757801333069-f7b3cabaec4a.jpg
  - olive oil|null|null|null ~ virgin oil|null|null|null
  - olive oil|null|null|null
  - olive oil|null|null|null
- openrouter 1762631934518-f75e233413ca.jpg
  - grilled chicken breast|null|null|null ~ mashed potatoes|null|null|null ~ grilled vegetables|null|null|null
  - grilled chicken breast|null|null|null ~ mashed potatoes|null|null|null ~ green beans|null|null|null ~ red bell pepper|null|null|null ~ yellow bell pepper|null|null|null ~ mushroom|null|null|null
  - grilled chicken breast|null|null|null ~ mashed potatoes|null|null|null ~ peas|null|null|null ~ carrots|null|null|null ~ green beans|null|null|null ~ red bell pepper|null|null|null ~ yellow bell pepper|null|null|null
- openai 1548807371-30dc1bbe6cb5.jpg
  - oatmeal|null|null|null ~ banana|1.0|null|null ~ walnuts|null|null|null ~ almonds|null|null|null ~ hazelnuts|null|null|null ~ dates|null|null|null ~ cinnamon|null|null|null
  - oatmeal|null|null|null ~ banana|null|null|null ~ walnuts|null|null|null ~ almonds|null|null|null ~ hazelnuts|null|null|null ~ cashews|null|null|null ~ cinnamon|null|null|null
  - oatmeal|null|null|null ~ banana|1.0|null|medium ~ walnuts|null|null|null ~ almonds|null|null|null ~ hazelnuts|null|null|null ~ pecans|null|null|null ~ cinnamon|null|null|null
- openai 1552056413-b8b5eed0170b.jpg
  - bread|null|null|null
  - brioche bread|null|null|null
  - brioche bread|null|null|null
- openai 1567306226416-28f0efdc88ce.jpg
  - apple|null|null|null
  - apple|null|null|null
  - apple|1.0|null|medium
- openai 1571212515416-fef01fc43637.jpg
  - yogurt|null|null|null ~ mint|null|null|null ~ garlic|1.0|null|null ~ lemon|2.0|null|null ~ parsley|null|null|null ~ coriander|null|null|null
  - yogurt|null|null|null ~ mint|null|null|null ~ parsley|null|null|null ~ cilantro|null|null|null ~ garlic|null|null|null ~ lemon|null|null|null ~ orange|null|null|null
  - yogurt|null|null|null ~ mint|null|null|null ~ parsley|null|null|null ~ cilantro|null|null|null ~ garlic|null|null|null ~ lemon|null|null|null ~ orange|null|null|null
- openai 1593357849627-cbbc9fda6b05.jpg
  - tempura|null|null|null ~ rice|null|null|null ~ miso soup|null|null|null ~ noodle soup|null|null|null
  - rice|null|null|null ~ tempura|null|null|null ~ miso soup|null|null|null ~ noodle soup|null|null|null
  - rice|null|null|null ~ tempura|null|null|null ~ miso soup|null|null|null ~ noodle soup|null|null|null
- openai 1762631934518-f75e233413ca.jpg
  - grilled chicken breast|1.0|null|null ~ rice|null|null|null ~ mixed vegetables|null|null|null
  - grilled chicken breast|1.0|null|large ~ couscous|null|null|null ~ grilled vegetables|null|null|null
  - grilled chicken breast|1.0|null|large ~ couscous|null|null|null ~ grilled vegetables|null|null|null

## Backend

6 read-only RPC calls for 3 distinct queries; 0 failed.

## Appendix

Every item, raw reply included, is in `portion-photos.items.json` beside this file.
