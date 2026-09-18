# Live portion corpus — text path (#1160)

240 generated lines (seed `20260911`), 143 of them naming a household measure, across 9 locales; 2026-09-18T19:21:22.899752Z.

## Calls a real run of this harness makes

Per provider: **240** text lines + **60** stability (20 lines × 3) = **300** calls, every one carrying text.

Providers: `anthropic` (`claude-haiku-4-5`), `openrouter` (`anthropic/claude-haiku-4.5`), `openai` (`gpt-5.6-luna`) — **900** calls across 3. Retries are not counted here; a transient failure is retried up to three times.

## The prompt sentences as run

Read from the sources at run time, not from a copy.

**Schema, `portion` description:**

> How the food was portioned, as one English word whatever language the user wrote in — slice, piece, cup, tablespoon, teaspoon, small, medium, large. Write abbreviations out. Never a weight, a count, or a unit from the unit list. Omit when the user named no portion.

**Text prompt, the portion bullet:**

> - If the user named a household measure that is not in the unit list — a slice, piece, cup, tablespoon, teaspoon, or a size such as small, medium or large — give the "quantity", leave "unit" out, and put the measure in "portion" as one English word, even when the meal is written in another language: "3 Scheiben Brot" -> query "Brot", quantity 3, portion "slice"; "2 tbsp olive oil" -> quantity 2, portion "tablespoon". Do not substitute a unit from the list: reporting 2 tbsp as 2 g is worse than reporting 2 with no unit.

<details><summary>The whole text system prompt</summary>

```
You extract food items from a meal description so they can be looked up in a
food database. You do not estimate nutrition, and you never invent an amount.

Rules:
- One entry per distinct food. Split on any punctuation or conjunction the
  user's language uses.
- "query" is the food name alone, with no amount in it, in the same language
  the user wrote. Keep a brand if one is given.
- Only include "quantity" if the user stated an amount, including as a word
  ("two eggs" -> 2) or a counter ("2个鸡蛋" -> 2). If no amount is stated,
  omit both "quantity" and "unit".
- Only include "unit" if the user stated one, and only when it is one of
  the listed values. A bare count has no unit.
- If the user named a household measure that is not in the unit list — a
  slice, piece, cup, tablespoon, teaspoon, or a size such as small, medium
  or large — give the "quantity", leave "unit" out, and put the measure in
  "portion" as one English word, even when the meal is written in another
  language: "3 Scheiben Brot" -> query "Brot", quantity 3, portion "slice";
  "2 tbsp olive oil" -> quantity 2, portion "tablespoon". Do not substitute
  a unit from the list: reporting 2 tbsp as 2 g is worse than reporting 2
  with no unit.
- Never convert a quantity between units. Report the number as written.
- If nothing in the input is food, return an empty list.
```

</details>

## How to read the columns

- *Measure lines* are the lines a template generated with a household word, so the key the prompt asks for is known. Rates are over the first item of those lines.
- *English* counts a key that is one of the eight steering words, the English word the line's template asked for (`glass`, `bowl`, `handful`), or ASCII-lettered and not the line's own word; *own word* is a key equal to, or a short inflection of, any written form of the line's own words for that measure — "Scheibe" for a German line, and also "Glas" answered to a *Gläser* line or "tazza" to a *tazze* line — the failure #1157 names.
- *Resolved* is the record the app's resolver lands on for the model's query, searched as the app searches for a user whose app language is the line's locale (`AppLocale`, #1215): `search_food_summary` for an English line; for any other, `search_food_translation` in that locale, the hits cut with `has_portion` read (`rankAndTruncateTranslationRows`, `forResolution: true`, #1209), `food_summary_by_ids` for them, re-sorted onto the cut's order and shown under the translated name — and only when the translation search finds nothing, the English search on the same words, cut the same way (`rankAndTruncateFoodsByName`). Then one `portions_by_food_ids` in the line's locale for the whole page, each row's portions carrying `label_en` (#1208), `mergeAndRankMeals` and `rankForResolution` as `ResolveParsedMealsUseCase` calls them — siblings no longer collapsed, 0.15 off a record with no portion rows, ties broken by the shorter description then the more portions (#1170). *Via translation* counts the resolved measure lines that came through the translation search; the JSON's `resolvedVia` says `english`, `translation` or `englishFallback` per item.
- *has_portion* is the resolved record's `has_portion` column as the search row carried it — the backend's own word, which the cut read; *with rows* is whether `portions_by_food_ids` delivered a row for it. The two should agree, and the report says where they do not. Both are new: the 2026-09-12 run had neither column on the wire.
- *Matched* is `matchPortionToKey(key, portions) != null` — the key against the **English** label of each portion, which is what `_initialUnit` tries first under a count; *tie* means another row scored the same; *middle rung* means the tie was decided by the row whose English label names `medium` or `regular` (#1162), and *moved* that this picked a later row than the earlier-row fallback would have; *not literal* means the hit came through the matcher's two-letter inflection bound and no word of the key is a word of the winning label as written. Ties and non-literal hits together are the *false-match surface* #1160 asks for — the hits where a wrong row is possible; whether one *is* wrong is for the reader, and every one is listed with the row it picked.
- *Key miss* is a key on a resolved food that matched nothing — split into *food has no rows* and a real miss. *portionKeyMissed* is `BulkAddRow.portionKeyMissed` computed by its own conjuncts: a count is stated, the food has portion rows and their lookup did not fail, and neither the key (English label) nor the query words (`matchPortionToQuery`, the label as it arrived) name one — so a miss on a food with no rows is quiet, which is the gate the 2026-09-12 run proposed. *amountNeedsCheck* is the whole getter for a row with a count and no unit: `portionKeyMissed`, or no scalable serving on the record. *amountNeedsCheck fires (old)* is the previous report's column — the miss without the rows gate — kept so the two runs read side by side.
- *Unit step* is which step of `_initialUnit` decides the row's unit: the key, the query words, `serving` on a bare count, or the fallback.

## Summary per provider

| provider | model | lines | failed | empty | measure lines | key emitted | steering word | English | own word | key = expected | resolved (of keyed) | has_portion on the row (of resolved) | with rows (of resolved) | low confidence (of resolved) | matched (of resolved) | tie (of matched) | middle rung (of matched) | not literal (of matched) | false-match surface (of matched) | key miss (of resolved) | of which: food has no rows | of which: query words hit a row | of which: no count | portionKeyMissed (of resolved) | amountNeedsCheck (of resolved) | amountNeedsCheck fires, old column (of resolved) | abbreviation expanded | unit substituted | key on plain line | invariant violations | parser disagreements | unstable | latency p50 / p95 / max |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| anthropic | `claude-haiku-4-5` | 240 | 0 | 3 | 143 | 140/143 (97.9%) | 117/140 (83.6%) | 140/140 (100.0%) | 0/140 (0.0%) | 133/140 (95.0%) | 103/141 (73.0%) | 85/103 (82.5%) | 85/103 (82.5%) | 0/103 (0.0%) | 33/103 (32.0%) | 9/33 (27.3%) | 6/33 (18.2%) (moved 4) | 0/33 (0.0%) | 9/33 (27.3%) | 70/103 (68.0%) | 18/70 (25.7%) | 10/70 (14.3%) | 8/70 (11.4%) | 36/103 (35.0%) | 49/103 (47.6%) | 52/103 (50.5%) | 14/15 (93.3%) (kept 0, other 1, no key 0) | 1 | 1 | 1 | 0 | 2/20 (key alone: 2) | 770 / 1264 / 4536 ms |
| openrouter | `anthropic/claude-haiku-4.5` | 240 | 0 | 3 | 143 | 141/143 (98.6%) | 118/141 (83.7%) | 141/141 (100.0%) | 0/141 (0.0%) | 134/141 (95.0%) | 105/142 (73.9%) | 87/105 (82.9%) | 87/105 (82.9%) | 0/105 (0.0%) | 34/105 (32.4%) | 9/34 (26.5%) | 6/34 (17.6%) (moved 4) | 0/34 (0.0%) | 9/34 (26.5%) | 71/105 (67.6%) | 18/71 (25.4%) | 11/71 (15.5%) | 5/71 (7.0%) | 39/105 (37.1%) | 52/105 (49.5%) | 56/105 (53.3%) | 14/15 (93.3%) (kept 0, other 1, no key 0) | 0 | 1 | 0 | 0 | 2/20 (key alone: 2) | 865 / 2274 / 12968 ms |
| openai | `gpt-5.6-luna` | 240 | 0 | 3 | 143 | 135/143 (94.4%) | 114/135 (84.4%) | 134/135 (99.3%) | 1/135 (0.7%) | 129/135 (95.6%) | 102/141 (72.3%) | 84/102 (82.4%) | 84/102 (82.4%) | 0/102 (0.0%) | 33/102 (32.4%) | 9/33 (27.3%) | 6/33 (18.2%) (moved 4) | 0/33 (0.0%) | 9/33 (27.3%) | 69/102 (67.6%) | 18/69 (26.1%) | 10/69 (14.5%) | 1/69 (1.4%) | 40/102 (39.2%) | 53/102 (52.0%) | 58/102 (56.9%) | 14/15 (93.3%) (kept 0, other 0, no key 1) | 0 | 6 | 2 | 0 | 1/20 (key alone: 1) | 1202 / 2293 / 4127 ms |

## Per locale

| provider | locale | lines | measure lines | key emitted | steering | own word | key = expected | resolved | via translation | has_portion | with rows | matched | middle rung (of matched) | key miss | portionKeyMissed | amountNeedsCheck fires (old) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| anthropic | en | 77 | 55 | 55/55 (100.0%) | 44/55 (80.0%) | 0/55 (0.0%) | 55/55 (100.0%) | 55/55 (100.0%) | – | 50/55 (90.9%) | 50/55 (90.9%) | 19/55 (34.5%) | 3/19 (15.8%) | 36/55 (65.5%) | 19/55 (34.5%) | 22/55 (40.0%) |
| anthropic | de | 65 | 45 | 44/45 (97.8%) | 36/44 (81.8%) | 0/44 (0.0%) | 42/44 (95.5%) | 43/44 (97.7%) | 43/43 (100.0%) | 32/43 (74.4%) | 32/43 (74.4%) | 14/43 (32.6%) | 3/14 (21.4%) | 29/43 (67.4%) | 15/43 (34.9%) | 26/43 (60.5%) |
| anthropic | cs | 12 | 4 | 4/4 (100.0%) | 4/4 (100.0%) | 0/4 (0.0%) | 4/4 (100.0%) | 1/4 (25.0%) | 0/1 (0.0%) | 1/1 (100.0%) | 1/1 (100.0%) | 0/1 (0.0%) | 0/0 (–) | 1/1 (100.0%) | 0/1 (0.0%) | 0/1 (0.0%) |
| anthropic | it | 10 | 4 | 4/4 (100.0%) | 4/4 (100.0%) | 0/4 (0.0%) | 4/4 (100.0%) | 2/4 (50.0%) | 0/2 (0.0%) | 1/2 (50.0%) | 1/2 (50.0%) | 0/2 (0.0%) | 0/0 (–) | 2/2 (100.0%) | 1/2 (50.0%) | 2/2 (100.0%) |
| anthropic | pl | 13 | 8 | 8/8 (100.0%) | 6/8 (75.0%) | 0/8 (0.0%) | 7/8 (87.5%) | 1/8 (12.5%) | 0/1 (0.0%) | 0/1 (0.0%) | 0/1 (0.0%) | 0/1 (0.0%) | 0/0 (–) | 1/1 (100.0%) | 0/1 (0.0%) | 1/1 (100.0%) |
| anthropic | sk | 13 | 9 | 9/9 (100.0%) | 8/9 (88.9%) | 0/9 (0.0%) | 7/9 (77.8%) | 1/9 (11.1%) | 0/1 (0.0%) | 1/1 (100.0%) | 1/1 (100.0%) | 0/1 (0.0%) | 0/0 (–) | 1/1 (100.0%) | 1/1 (100.0%) | 1/1 (100.0%) |
| anthropic | tr | 14 | 6 | 6/6 (100.0%) | 6/6 (100.0%) | 0/6 (0.0%) | 5/6 (83.3%) | 0/6 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| anthropic | uk | 17 | 6 | 6/6 (100.0%) | 6/6 (100.0%) | 0/6 (0.0%) | 5/6 (83.3%) | 0/6 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| anthropic | zh | 19 | 6 | 4/6 (66.7%) | 3/4 (75.0%) | 0/4 (0.0%) | 4/4 (100.0%) | 0/4 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| openrouter | en | 77 | 55 | 55/55 (100.0%) | 44/55 (80.0%) | 0/55 (0.0%) | 55/55 (100.0%) | 55/55 (100.0%) | – | 50/55 (90.9%) | 50/55 (90.9%) | 19/55 (34.5%) | 3/19 (15.8%) | 36/55 (65.5%) | 20/55 (36.4%) | 24/55 (43.6%) |
| openrouter | de | 65 | 45 | 45/45 (100.0%) | 36/45 (80.0%) | 0/45 (0.0%) | 44/45 (97.8%) | 44/45 (97.8%) | 44/44 (100.0%) | 33/44 (75.0%) | 33/44 (75.0%) | 14/44 (31.8%) | 3/14 (21.4%) | 30/44 (68.2%) | 17/44 (38.6%) | 28/44 (63.6%) |
| openrouter | cs | 12 | 4 | 4/4 (100.0%) | 4/4 (100.0%) | 0/4 (0.0%) | 4/4 (100.0%) | 1/4 (25.0%) | 0/1 (0.0%) | 1/1 (100.0%) | 1/1 (100.0%) | 0/1 (0.0%) | 0/0 (–) | 1/1 (100.0%) | 0/1 (0.0%) | 0/1 (0.0%) |
| openrouter | it | 10 | 4 | 4/4 (100.0%) | 4/4 (100.0%) | 0/4 (0.0%) | 4/4 (100.0%) | 2/4 (50.0%) | 0/2 (0.0%) | 1/2 (50.0%) | 1/2 (50.0%) | 0/2 (0.0%) | 0/0 (–) | 2/2 (100.0%) | 1/2 (50.0%) | 2/2 (100.0%) |
| openrouter | pl | 13 | 8 | 8/8 (100.0%) | 6/8 (75.0%) | 0/8 (0.0%) | 7/8 (87.5%) | 1/8 (12.5%) | 0/1 (0.0%) | 0/1 (0.0%) | 0/1 (0.0%) | 0/1 (0.0%) | 0/0 (–) | 1/1 (100.0%) | 0/1 (0.0%) | 1/1 (100.0%) |
| openrouter | sk | 13 | 9 | 8/9 (88.9%) | 8/8 (100.0%) | 0/8 (0.0%) | 6/8 (75.0%) | 1/8 (12.5%) | 0/1 (0.0%) | 1/1 (100.0%) | 1/1 (100.0%) | 0/1 (0.0%) | 0/0 (–) | 1/1 (100.0%) | 1/1 (100.0%) | 1/1 (100.0%) |
| openrouter | tr | 14 | 6 | 6/6 (100.0%) | 6/6 (100.0%) | 0/6 (0.0%) | 5/6 (83.3%) | 0/6 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| openrouter | uk | 17 | 6 | 6/6 (100.0%) | 6/6 (100.0%) | 0/6 (0.0%) | 4/6 (66.7%) | 0/6 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| openrouter | zh | 19 | 6 | 5/6 (83.3%) | 4/5 (80.0%) | 0/5 (0.0%) | 5/5 (100.0%) | 0/5 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| openai | en | 77 | 55 | 52/55 (94.5%) | 43/52 (82.7%) | 0/52 (0.0%) | 51/52 (98.1%) | 52/52 (100.0%) | – | 48/52 (92.3%) | 48/52 (92.3%) | 19/52 (36.5%) | 3/19 (15.8%) | 33/52 (63.5%) | 20/52 (38.5%) | 24/52 (46.2%) |
| openai | de | 65 | 45 | 43/45 (95.6%) | 36/43 (83.7%) | 1/43 (2.3%) | 41/43 (95.3%) | 42/43 (97.7%) | 42/42 (100.0%) | 31/42 (73.8%) | 31/42 (73.8%) | 14/42 (33.3%) | 3/14 (21.4%) | 28/42 (66.7%) | 16/42 (38.1%) | 27/42 (64.3%) |
| openai | cs | 12 | 4 | 4/4 (100.0%) | 4/4 (100.0%) | 0/4 (0.0%) | 4/4 (100.0%) | 1/4 (25.0%) | 0/1 (0.0%) | 1/1 (100.0%) | 1/1 (100.0%) | 0/1 (0.0%) | 0/0 (–) | 1/1 (100.0%) | 0/1 (0.0%) | 0/1 (0.0%) |
| openai | it | 10 | 4 | 4/4 (100.0%) | 4/4 (100.0%) | 0/4 (0.0%) | 4/4 (100.0%) | 2/4 (50.0%) | 0/2 (0.0%) | 1/2 (50.0%) | 1/2 (50.0%) | 0/2 (0.0%) | 0/0 (–) | 2/2 (100.0%) | 1/2 (50.0%) | 2/2 (100.0%) |
| openai | pl | 13 | 8 | 8/8 (100.0%) | 6/8 (75.0%) | 0/8 (0.0%) | 7/8 (87.5%) | 1/8 (12.5%) | 0/1 (0.0%) | 0/1 (0.0%) | 0/1 (0.0%) | 0/1 (0.0%) | 0/0 (–) | 1/1 (100.0%) | 0/1 (0.0%) | 1/1 (100.0%) |
| openai | sk | 13 | 9 | 8/9 (88.9%) | 6/8 (75.0%) | 0/8 (0.0%) | 8/8 (100.0%) | 1/8 (12.5%) | 0/1 (0.0%) | 1/1 (100.0%) | 1/1 (100.0%) | 0/1 (0.0%) | 0/0 (–) | 1/1 (100.0%) | 1/1 (100.0%) | 1/1 (100.0%) |
| openai | tr | 14 | 6 | 5/6 (83.3%) | 5/5 (100.0%) | 0/5 (0.0%) | 4/5 (80.0%) | 0/5 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| openai | uk | 17 | 6 | 5/6 (83.3%) | 5/5 (100.0%) | 0/5 (0.0%) | 4/5 (80.0%) | 0/5 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| openai | zh | 19 | 6 | 6/6 (100.0%) | 5/6 (83.3%) | 0/6 (0.0%) | 6/6 (100.0%) | 0/6 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |

## What the line said and what the key was

Per provider, per measure word as written; keys with counts.

| provider | locale | line said | expected key | keys seen |
| --- | --- | --- | --- | --- |
| anthropic | cs | hrnky | `cup` | `cup` ×1 |
| anthropic | cs | kusy | `piece` | `piece` ×1 |
| anthropic | cs | lžíce | `tablespoon` | `tablespoon` ×1 |
| anthropic | cs | plátky | `slice` | `slice` ×1 |
| anthropic | de | EL | `tablespoon` | `tablespoon` ×4 |
| anthropic | de | Esslöffel | `tablespoon` | `tablespoon` ×4 |
| anthropic | de | Gläser | `glass` | `glass` ×2, `cup` ×1 |
| anthropic | de | Handvoll | `handful` | `handful` ×3 |
| anthropic | de | Scheibe | `slice` | `slice` ×1 |
| anthropic | de | Scheiben | `slice` | `slice` ×3 |
| anthropic | de | Schüssel | `bowl` | `bowl` ×1 |
| anthropic | de | Schüsseln | `bowl` | `bowl` ×2 |
| anthropic | de | Stück | `piece` | `piece` ×3, (none) ×1 |
| anthropic | de | TL | `teaspoon` | `teaspoon` ×2, `tablespoon` ×1 |
| anthropic | de | Tasse | `cup` | `cup` ×1 |
| anthropic | de | Tassen | `cup` | `cup` ×3 |
| anthropic | de | Teelöffel | `teaspoon` | `teaspoon` ×4 |
| anthropic | de | großer | `large` | `large` ×2 |
| anthropic | de | großes | `large` | `large` ×1 |
| anthropic | de | kleine | `small` | `small` ×3 |
| anthropic | de | mittlere | `medium` | `medium` ×2 |
| anthropic | de | mittleres | `medium` | `medium` ×1 |
| anthropic | en | bowl | `bowl` | `bowl` ×2 |
| anthropic | en | bowls | `bowl` | `bowl` ×1 |
| anthropic | en | cups | `cup` | `cup` ×5 |
| anthropic | en | glass | `glass` | `glass` ×1 |
| anthropic | en | glasses | `glass` | `glass` ×3 |
| anthropic | en | handful | `handful` | `handful` ×1 |
| anthropic | en | handfuls | `handful` | `handful` ×3 |
| anthropic | en | large | `large` | `large` ×4 |
| anthropic | en | medium | `medium` | `medium` ×4 |
| anthropic | en | piece | `piece` | `piece` ×3 |
| anthropic | en | pieces | `piece` | `piece` ×2 |
| anthropic | en | slice | `slice` | `slice` ×2 |
| anthropic | en | slices | `slice` | `slice` ×3 |
| anthropic | en | small | `small` | `small` ×4 |
| anthropic | en | tablespoon | `tablespoon` | `tablespoon` ×1 |
| anthropic | en | tablespoons | `tablespoon` | `tablespoon` ×4 |
| anthropic | en | tbsp | `tablespoon` | `tablespoon` ×4 |
| anthropic | en | teaspoon | `teaspoon` | `teaspoon` ×2 |
| anthropic | en | teaspoons | `teaspoon` | `teaspoon` ×2 |
| anthropic | en | tsp | `teaspoon` | `teaspoon` ×4 |
| anthropic | it | cucchiaio | `tablespoon` | `tablespoon` ×1 |
| anthropic | it | fette | `slice` | `slice` ×1 |
| anthropic | it | pezzi | `piece` | `piece` ×1 |
| anthropic | it | tazze | `cup` | `cup` ×1 |
| anthropic | pl | filiżanki | `cup` | `cup` ×1 |
| anthropic | pl | garście | `handful` | `handful` ×1 |
| anthropic | pl | kawałki | `piece` | `piece` ×1 |
| anthropic | pl | kromki | `slice` | `slice` ×1 |
| anthropic | pl | miski | `bowl` | `bowl` ×1 |
| anthropic | pl | szklanki | `glass` | `cup` ×1 |
| anthropic | pl | łyżeczki | `teaspoon` | `teaspoon` ×1 |
| anthropic | pl | łyżki | `tablespoon` | `tablespoon` ×1 |
| anthropic | sk | hrste | `handful` | `piece` ×1 |
| anthropic | sk | kusy | `piece` | `piece` ×1 |
| anthropic | sk | lyžice | `tablespoon` | `tablespoon` ×1 |
| anthropic | sk | lyžičky | `teaspoon` | `teaspoon` ×1 |
| anthropic | sk | malé | `small` | `small` ×1 |
| anthropic | sk | miska | `bowl` | `bowl` ×1 |
| anthropic | sk | plátky | `slice` | `slice` ×1 |
| anthropic | sk | pohár | `glass` | `cup` ×1 |
| anthropic | sk | šálky | `cup` | `cup` ×1 |
| anthropic | tr | bardak | `glass` | `cup` ×1 |
| anthropic | tr | dilim | `slice` | `slice` ×1 |
| anthropic | tr | fincan | `cup` | `cup` ×1 |
| anthropic | tr | parça | `piece` | `piece` ×1 |
| anthropic | tr | yemek kaşığı | `tablespoon` | `tablespoon` ×1 |
| anthropic | tr | çay kaşığı | `teaspoon` | `teaspoon` ×1 |
| anthropic | uk | скибки | `slice` | `slice` ×1 |
| anthropic | uk | склянка | `glass` | `cup` ×1 |
| anthropic | uk | столові ложки | `tablespoon` | `tablespoon` ×1 |
| anthropic | uk | чайні ложки | `teaspoon` | `teaspoon` ×1 |
| anthropic | uk | чашки | `cup` | `cup` ×1 |
| anthropic | uk | шматки | `piece` | `piece` ×1 |
| anthropic | zh | 块 | `piece` | (none) ×1 |
| anthropic | zh | 杯 | `cup` | (none) ×1 |
| anthropic | zh | 汤匙 | `tablespoon` | `tablespoon` ×1 |
| anthropic | zh | 片 | `slice` | `slice` ×1 |
| anthropic | zh | 碗 | `bowl` | `bowl` ×1 |
| anthropic | zh | 茶匙 | `teaspoon` | `teaspoon` ×1 |
| openrouter | cs | hrnky | `cup` | `cup` ×1 |
| openrouter | cs | kusy | `piece` | `piece` ×1 |
| openrouter | cs | lžíce | `tablespoon` | `tablespoon` ×1 |
| openrouter | cs | plátky | `slice` | `slice` ×1 |
| openrouter | de | EL | `tablespoon` | `tablespoon` ×4 |
| openrouter | de | Esslöffel | `tablespoon` | `tablespoon` ×4 |
| openrouter | de | Gläser | `glass` | `glass` ×3 |
| openrouter | de | Handvoll | `handful` | `handful` ×3 |
| openrouter | de | Scheibe | `slice` | `slice` ×1 |
| openrouter | de | Scheiben | `slice` | `slice` ×3 |
| openrouter | de | Schüssel | `bowl` | `bowl` ×1 |
| openrouter | de | Schüsseln | `bowl` | `bowl` ×2 |
| openrouter | de | Stück | `piece` | `piece` ×4 |
| openrouter | de | TL | `teaspoon` | `teaspoon` ×2, `tablespoon` ×1 |
| openrouter | de | Tasse | `cup` | `cup` ×1 |
| openrouter | de | Tassen | `cup` | `cup` ×3 |
| openrouter | de | Teelöffel | `teaspoon` | `teaspoon` ×4 |
| openrouter | de | großer | `large` | `large` ×2 |
| openrouter | de | großes | `large` | `large` ×1 |
| openrouter | de | kleine | `small` | `small` ×3 |
| openrouter | de | mittlere | `medium` | `medium` ×2 |
| openrouter | de | mittleres | `medium` | `medium` ×1 |
| openrouter | en | bowl | `bowl` | `bowl` ×2 |
| openrouter | en | bowls | `bowl` | `bowl` ×1 |
| openrouter | en | cups | `cup` | `cup` ×5 |
| openrouter | en | glass | `glass` | `glass` ×1 |
| openrouter | en | glasses | `glass` | `glass` ×3 |
| openrouter | en | handful | `handful` | `handful` ×1 |
| openrouter | en | handfuls | `handful` | `handful` ×3 |
| openrouter | en | large | `large` | `large` ×4 |
| openrouter | en | medium | `medium` | `medium` ×4 |
| openrouter | en | piece | `piece` | `piece` ×3 |
| openrouter | en | pieces | `piece` | `piece` ×2 |
| openrouter | en | slice | `slice` | `slice` ×2 |
| openrouter | en | slices | `slice` | `slice` ×3 |
| openrouter | en | small | `small` | `small` ×4 |
| openrouter | en | tablespoon | `tablespoon` | `tablespoon` ×1 |
| openrouter | en | tablespoons | `tablespoon` | `tablespoon` ×4 |
| openrouter | en | tbsp | `tablespoon` | `tablespoon` ×4 |
| openrouter | en | teaspoon | `teaspoon` | `teaspoon` ×2 |
| openrouter | en | teaspoons | `teaspoon` | `teaspoon` ×2 |
| openrouter | en | tsp | `teaspoon` | `teaspoon` ×4 |
| openrouter | it | cucchiaio | `tablespoon` | `tablespoon` ×1 |
| openrouter | it | fette | `slice` | `slice` ×1 |
| openrouter | it | pezzi | `piece` | `piece` ×1 |
| openrouter | it | tazze | `cup` | `cup` ×1 |
| openrouter | pl | filiżanki | `cup` | `cup` ×1 |
| openrouter | pl | garście | `handful` | `handful` ×1 |
| openrouter | pl | kawałki | `piece` | `piece` ×1 |
| openrouter | pl | kromki | `slice` | `slice` ×1 |
| openrouter | pl | miski | `bowl` | `bowl` ×1 |
| openrouter | pl | szklanki | `glass` | `cup` ×1 |
| openrouter | pl | łyżeczki | `teaspoon` | `teaspoon` ×1 |
| openrouter | pl | łyżki | `tablespoon` | `tablespoon` ×1 |
| openrouter | sk | hrste | `handful` | (none) ×1 |
| openrouter | sk | kusy | `piece` | `piece` ×1 |
| openrouter | sk | lyžice | `tablespoon` | `tablespoon` ×1 |
| openrouter | sk | lyžičky | `teaspoon` | `teaspoon` ×1 |
| openrouter | sk | malé | `small` | `small` ×1 |
| openrouter | sk | miska | `bowl` | `cup` ×1 |
| openrouter | sk | plátky | `slice` | `slice` ×1 |
| openrouter | sk | pohár | `glass` | `cup` ×1 |
| openrouter | sk | šálky | `cup` | `cup` ×1 |
| openrouter | tr | bardak | `glass` | `cup` ×1 |
| openrouter | tr | dilim | `slice` | `slice` ×1 |
| openrouter | tr | fincan | `cup` | `cup` ×1 |
| openrouter | tr | parça | `piece` | `piece` ×1 |
| openrouter | tr | yemek kaşığı | `tablespoon` | `tablespoon` ×1 |
| openrouter | tr | çay kaşığı | `teaspoon` | `teaspoon` ×1 |
| openrouter | uk | скибки | `slice` | `slice` ×1 |
| openrouter | uk | склянка | `glass` | `cup` ×1 |
| openrouter | uk | столові ложки | `tablespoon` | `tablespoon` ×1 |
| openrouter | uk | чайні ложки | `teaspoon` | `teaspoon` ×1 |
| openrouter | uk | чашки | `cup` | `cup` ×1 |
| openrouter | uk | шматки | `piece` | `slice` ×1 |
| openrouter | zh | 块 | `piece` | (none) ×1 |
| openrouter | zh | 杯 | `cup` | `cup` ×1 |
| openrouter | zh | 汤匙 | `tablespoon` | `tablespoon` ×1 |
| openrouter | zh | 片 | `slice` | `slice` ×1 |
| openrouter | zh | 碗 | `bowl` | `bowl` ×1 |
| openrouter | zh | 茶匙 | `teaspoon` | `teaspoon` ×1 |
| openai | cs | hrnky | `cup` | `cup` ×1 |
| openai | cs | kusy | `piece` | `piece` ×1 |
| openai | cs | lžíce | `tablespoon` | `tablespoon` ×1 |
| openai | cs | plátky | `slice` | `slice` ×1 |
| openai | de | EL | `tablespoon` | `tablespoon` ×4 |
| openai | de | Esslöffel | `tablespoon` | `tablespoon` ×4 |
| openai | de | Gläser | `glass` | `glass` ×3 |
| openai | de | Handvoll | `handful` | (none) ×1, `large` ×1, `Handvoll` ×1 |
| openai | de | Scheibe | `slice` | `slice` ×1 |
| openai | de | Scheiben | `slice` | `slice` ×3 |
| openai | de | Schüssel | `bowl` | `bowl` ×1 |
| openai | de | Schüsseln | `bowl` | `bowl` ×2 |
| openai | de | Stück | `piece` | `piece` ×3, (none) ×1 |
| openai | de | TL | `teaspoon` | `teaspoon` ×3 |
| openai | de | Tasse | `cup` | `cup` ×1 |
| openai | de | Tassen | `cup` | `cup` ×3 |
| openai | de | Teelöffel | `teaspoon` | `teaspoon` ×4 |
| openai | de | großer | `large` | `large` ×2 |
| openai | de | großes | `large` | `large` ×1 |
| openai | de | kleine | `small` | `small` ×3 |
| openai | de | mittlere | `medium` | `medium` ×2 |
| openai | de | mittleres | `medium` | `medium` ×1 |
| openai | en | bowl | `bowl` | `bowl` ×2 |
| openai | en | bowls | `bowl` | `bowl` ×1 |
| openai | en | cups | `cup` | `cup` ×4, (none) ×1 |
| openai | en | glass | `glass` | `glass` ×1 |
| openai | en | glasses | `glass` | `glass` ×3 |
| openai | en | handful | `handful` | `handful` ×1 |
| openai | en | handfuls | `handful` | (none) ×1, `handful` ×1, `piece` ×1 |
| openai | en | large | `large` | `large` ×4 |
| openai | en | medium | `medium` | `medium` ×4 |
| openai | en | piece | `piece` | `piece` ×3 |
| openai | en | pieces | `piece` | `piece` ×2 |
| openai | en | slice | `slice` | `slice` ×2 |
| openai | en | slices | `slice` | `slice` ×3 |
| openai | en | small | `small` | `small` ×4 |
| openai | en | tablespoon | `tablespoon` | `tablespoon` ×1 |
| openai | en | tablespoons | `tablespoon` | `tablespoon` ×4 |
| openai | en | tbsp | `tablespoon` | `tablespoon` ×3, (none) ×1 |
| openai | en | teaspoon | `teaspoon` | `teaspoon` ×2 |
| openai | en | teaspoons | `teaspoon` | `teaspoon` ×2 |
| openai | en | tsp | `teaspoon` | `teaspoon` ×4 |
| openai | it | cucchiaio | `tablespoon` | `tablespoon` ×1 |
| openai | it | fette | `slice` | `slice` ×1 |
| openai | it | pezzi | `piece` | `piece` ×1 |
| openai | it | tazze | `cup` | `cup` ×1 |
| openai | pl | filiżanki | `cup` | `cup` ×1 |
| openai | pl | garście | `handful` | `handful` ×1 |
| openai | pl | kawałki | `piece` | `piece` ×1 |
| openai | pl | kromki | `slice` | `slice` ×1 |
| openai | pl | miski | `bowl` | `bowl` ×1 |
| openai | pl | szklanki | `glass` | `cup` ×1 |
| openai | pl | łyżeczki | `teaspoon` | `teaspoon` ×1 |
| openai | pl | łyżki | `tablespoon` | `tablespoon` ×1 |
| openai | sk | hrste | `handful` | (none) ×1 |
| openai | sk | kusy | `piece` | `piece` ×1 |
| openai | sk | lyžice | `tablespoon` | `tablespoon` ×1 |
| openai | sk | lyžičky | `teaspoon` | `teaspoon` ×1 |
| openai | sk | malé | `small` | `small` ×1 |
| openai | sk | miska | `bowl` | `bowl` ×1 |
| openai | sk | plátky | `slice` | `slice` ×1 |
| openai | sk | pohár | `glass` | `glass` ×1 |
| openai | sk | šálky | `cup` | `cup` ×1 |
| openai | tr | bardak | `glass` | `cup` ×1 |
| openai | tr | dilim | `slice` | `slice` ×1 |
| openai | tr | fincan | `cup` | `cup` ×1 |
| openai | tr | parça | `piece` | (none) ×1 |
| openai | tr | yemek kaşığı | `tablespoon` | `tablespoon` ×1 |
| openai | tr | çay kaşığı | `teaspoon` | `teaspoon` ×1 |
| openai | uk | скибки | `slice` | (none) ×1 |
| openai | uk | склянка | `glass` | `cup` ×1 |
| openai | uk | столові ложки | `tablespoon` | `tablespoon` ×1 |
| openai | uk | чайні ложки | `teaspoon` | `teaspoon` ×1 |
| openai | uk | чашки | `cup` | `cup` ×1 |
| openai | uk | шматки | `piece` | `piece` ×1 |
| openai | zh | 块 | `piece` | `piece` ×1 |
| openai | zh | 杯 | `cup` | `cup` ×1 |
| openai | zh | 汤匙 | `tablespoon` | `tablespoon` ×1 |
| openai | zh | 片 | `slice` | `slice` ×1 |
| openai | zh | 碗 | `bowl` | `bowl` ×1 |
| openai | zh | 茶匙 | `teaspoon` | `teaspoon` ×1 |

## Abbreviation cases (45)

- anthropic `cottage cheese, 2 tbsp` → key `tablespoon` expanded
- anthropic `ich hatte 4 EL Honig` → key `tablespoon` expanded
- anthropic `ich hatte 2 TL Honig` → key `teaspoon` expanded
- anthropic `a tsp of peanut butter` → key `teaspoon` expanded
- anthropic `a tbsp of sugar` → key `tablespoon` expanded
- anthropic `3 tsp of sugar` → key `teaspoon` expanded
- anthropic `3 TL Olivenöl zum Frühstück` → key `teaspoon` expanded
- anthropic `2 EL Honig` → key `tablespoon` expanded
- anthropic `I had 3 tbsp of peanut butter` → key `tablespoon` expanded
- anthropic `5 tsp of sugar` → key `teaspoon` expanded
- anthropic `Butter, 6 EL` → key `tablespoon` expanded
- anthropic `3 TL Quark zum Frühstück` → key `tablespoon` **other key**
- anthropic `1 tbsp butter` → key `tablespoon` expanded
- anthropic `4 tsp of sugar` → key `teaspoon` expanded
- anthropic `Quark, 3 EL` → key `tablespoon` expanded
- openrouter `ich hatte 4 EL Honig` → key `tablespoon` expanded
- openrouter `ich hatte 2 TL Honig` → key `teaspoon` expanded
- openrouter `cottage cheese, 2 tbsp` → key `tablespoon` expanded
- openrouter `a tsp of peanut butter` → key `teaspoon` expanded
- openrouter `a tbsp of sugar` → key `tablespoon` expanded
- openrouter `3 tsp of sugar` → key `teaspoon` expanded
- openrouter `3 TL Olivenöl zum Frühstück` → key `teaspoon` expanded
- openrouter `2 EL Honig` → key `tablespoon` expanded
- openrouter `5 tsp of sugar` → key `teaspoon` expanded
- openrouter `I had 3 tbsp of peanut butter` → key `tablespoon` expanded
- openrouter `3 TL Quark zum Frühstück` → key `tablespoon` **other key**
- openrouter `Butter, 6 EL` → key `tablespoon` expanded
- openrouter `1 tbsp butter` → key `tablespoon` expanded
- openrouter `4 tsp of sugar` → key `teaspoon` expanded
- openrouter `Quark, 3 EL` → key `tablespoon` expanded
- openai `ich hatte 2 TL Honig` → key `teaspoon` expanded
- openai `ich hatte 4 EL Honig` → key `tablespoon` expanded
- openai `cottage cheese, 2 tbsp` → key – **no key**
- openai `a tsp of peanut butter` → key `teaspoon` expanded
- openai `a tbsp of sugar` → key `tablespoon` expanded
- openai `3 tsp of sugar` → key `teaspoon` expanded
- openai `3 TL Olivenöl zum Frühstück` → key `teaspoon` expanded
- openai `2 EL Honig` → key `tablespoon` expanded
- openai `5 tsp of sugar` → key `teaspoon` expanded
- openai `I had 3 tbsp of peanut butter` → key `tablespoon` expanded
- openai `Butter, 6 EL` → key `tablespoon` expanded
- openai `3 TL Quark zum Frühstück` → key `teaspoon` expanded
- openai `1 tbsp butter` → key `tablespoon` expanded
- openai `4 tsp of sugar` → key `teaspoon` expanded
- openai `Quark, 3 EL` → key `tablespoon` expanded

## Unit substitutions (the prompt forbids them) (1)

- anthropic `早餐5杯杏仁` → raw unit ``, validated unit –, quantity 5.0

## Ties (a hit decided by the middle rung or by row order — #1162) (27)

- anthropic `I had 1 slice of bacon` key `slice` on *Bacon, NS as to type of meat, cooked* (2705885) → `1 medium slice (yield after cooking)` 8.0 g; **tie** with `1 thin slice (yield after cooking)` 5.0 g, `1 thick slice (yield after cooking)` 12.0 g; **middle rung** decided, moved off the first row
- anthropic `6 Scheiben Käse` key `slice` on *Käse, NFS* [de, machine] = *Cheese, NFS* (2705704) → `1 Scheibe in Crackergröße` (en `1 cracker-size slice`) 9.0 g; **tie** with `1 Scheibe` (en `1 slice`) 21.0 g
- anthropic `a slice of chicken breast` key `slice` on *Chicken breast, stewed, skin eaten* (2705965) → `1 medium slice` 60.0 g; **tie** with `1 small or thin slice` 30.0 g, `1 large or thick slice` 85.0 g; **middle rung** decided, moved off the first row
- anthropic `ich hatte 2 Scheiben Brot` key `slice` on *Brot, Käse* [de, machine] = *Bread, cheese* (2707618) → `1 mittlere oder normale Scheibe` (en `1 medium or regular slice`) 28.0 g; **tie** with `1 kleine oder dünne/sehr dünne Scheibe` (en `1 small or thin/very thin slice`) 24.0 g, `1 große oder dicke Scheibe` (en `1 large or thick slice`) 43.0 g, `1 Scheibe, Rand nicht gegessen` (en `1 slice, crust not eaten`) 13.0 g, `1 Scheibe, Snackgröße` (en `1 slice, snack-size`) 10.0 g; **middle rung** decided, moved off the first row
- anthropic `1 mittlere Pizza` key `medium` on *Pizza, Käse, gefüllter Rand* [de, machine] = *Pizza, cheese, stuffed crust* (2708618) → `1 Stück, mittlere Pizza` (en `1 piece, medium pizza`) 100.0 g; **tie** with `1 mittlere Pizza (11-12" Durchmesser)` (en `1 medium pizza (11-12" diameter)`) 800.0 g; **middle rung** decided (the first row anyway)
- anthropic `3 kleine Wassermelone und Kaffee` key `small` on *Wassermelone, roh* [de, machine] = *Watermelon, raw* (2709270) → `1 small wedge/slice` 218.0 g; **tie** with `1 small melon` 3200.0 g
- anthropic `ein großer Apfel` key `large` on *Apfel, roh* [de, machine] = *Apple, raw* (2709215) → `1 groß` (en `1 large`) 242.0 g; **tie** with `1 extra large` 295.0 g
- anthropic `eine mittlere Hähnchenbrust` key `medium` on *Hähnchenbrust, geschmort, Haut mitgegessen* [de, machine] = *Chicken breast, stewed, skin eaten* (2705965) → `1 medium breast` 150.0 g; **tie** with `1 mittlere Scheibe` (en `1 medium slice`) 60.0 g; **middle rung** decided (the first row anyway)
- anthropic `4 slices chicken breast` key `slice` on *Chicken breast, stewed, skin eaten* (2705965) → `1 medium slice` 60.0 g; **tie** with `1 small or thin slice` 30.0 g, `1 large or thick slice` 85.0 g; **middle rung** decided, moved off the first row
- openrouter `I had 1 slice of bacon` key `slice` on *Bacon, NS as to type of meat, cooked* (2705885) → `1 medium slice (yield after cooking)` 8.0 g; **tie** with `1 thin slice (yield after cooking)` 5.0 g, `1 thick slice (yield after cooking)` 12.0 g; **middle rung** decided, moved off the first row
- openrouter `6 Scheiben Käse` key `slice` on *Käse, NFS* [de, machine] = *Cheese, NFS* (2705704) → `1 Scheibe in Crackergröße` (en `1 cracker-size slice`) 9.0 g; **tie** with `1 Scheibe` (en `1 slice`) 21.0 g
- openrouter `a slice of chicken breast` key `slice` on *Chicken breast, stewed, skin eaten* (2705965) → `1 medium slice` 60.0 g; **tie** with `1 small or thin slice` 30.0 g, `1 large or thick slice` 85.0 g; **middle rung** decided, moved off the first row
- openrouter `ich hatte 2 Scheiben Brot` key `slice` on *Brot, Käse* [de, machine] = *Bread, cheese* (2707618) → `1 mittlere oder normale Scheibe` (en `1 medium or regular slice`) 28.0 g; **tie** with `1 kleine oder dünne/sehr dünne Scheibe` (en `1 small or thin/very thin slice`) 24.0 g, `1 große oder dicke Scheibe` (en `1 large or thick slice`) 43.0 g, `1 Scheibe, Rand nicht gegessen` (en `1 slice, crust not eaten`) 13.0 g, `1 Scheibe, Snackgröße` (en `1 slice, snack-size`) 10.0 g; **middle rung** decided, moved off the first row
- openrouter `1 mittlere Pizza` key `medium` on *Pizza, Käse, gefüllter Rand* [de, machine] = *Pizza, cheese, stuffed crust* (2708618) → `1 Stück, mittlere Pizza` (en `1 piece, medium pizza`) 100.0 g; **tie** with `1 mittlere Pizza (11-12" Durchmesser)` (en `1 medium pizza (11-12" diameter)`) 800.0 g; **middle rung** decided (the first row anyway)
- openrouter `3 kleine Wassermelone und Kaffee` key `small` on *Wassermelone, roh* [de, machine] = *Watermelon, raw* (2709270) → `1 small wedge/slice` 218.0 g; **tie** with `1 small melon` 3200.0 g
- openrouter `eine mittlere Hähnchenbrust` key `medium` on *Hähnchenbrust, geschmort, Haut mitgegessen* [de, machine] = *Chicken breast, stewed, skin eaten* (2705965) → `1 medium breast` 150.0 g; **tie** with `1 mittlere Scheibe` (en `1 medium slice`) 60.0 g; **middle rung** decided (the first row anyway)
- openrouter `ein großer Apfel` key `large` on *Apfel, roh* [de, machine] = *Apple, raw* (2709215) → `1 groß` (en `1 large`) 242.0 g; **tie** with `1 extra large` 295.0 g
- openrouter `4 slices chicken breast` key `slice` on *Chicken breast, stewed, skin eaten* (2705965) → `1 medium slice` 60.0 g; **tie** with `1 small or thin slice` 30.0 g, `1 large or thick slice` 85.0 g; **middle rung** decided, moved off the first row
- openai `I had 1 slice of bacon` key `slice` on *Bacon, NS as to type of meat, cooked* (2705885) → `1 medium slice (yield after cooking)` 8.0 g; **tie** with `1 thin slice (yield after cooking)` 5.0 g, `1 thick slice (yield after cooking)` 12.0 g; **middle rung** decided, moved off the first row
- openai `6 Scheiben Käse` key `slice` on *Käse, NFS* [de, machine] = *Cheese, NFS* (2705704) → `1 Scheibe in Crackergröße` (en `1 cracker-size slice`) 9.0 g; **tie** with `1 Scheibe` (en `1 slice`) 21.0 g
- openai `a slice of chicken breast` key `slice` on *Chicken breast, stewed, skin eaten* (2705965) → `1 medium slice` 60.0 g; **tie** with `1 small or thin slice` 30.0 g, `1 large or thick slice` 85.0 g; **middle rung** decided, moved off the first row
- openai `ich hatte 2 Scheiben Brot` key `slice` on *Brot, Käse* [de, machine] = *Bread, cheese* (2707618) → `1 mittlere oder normale Scheibe` (en `1 medium or regular slice`) 28.0 g; **tie** with `1 kleine oder dünne/sehr dünne Scheibe` (en `1 small or thin/very thin slice`) 24.0 g, `1 große oder dicke Scheibe` (en `1 large or thick slice`) 43.0 g, `1 Scheibe, Rand nicht gegessen` (en `1 slice, crust not eaten`) 13.0 g, `1 Scheibe, Snackgröße` (en `1 slice, snack-size`) 10.0 g; **middle rung** decided, moved off the first row
- openai `1 mittlere Pizza` key `medium` on *Pizza, Käse, gefüllter Rand* [de, machine] = *Pizza, cheese, stuffed crust* (2708618) → `1 Stück, mittlere Pizza` (en `1 piece, medium pizza`) 100.0 g; **tie** with `1 mittlere Pizza (11-12" Durchmesser)` (en `1 medium pizza (11-12" diameter)`) 800.0 g; **middle rung** decided (the first row anyway)
- openai `3 kleine Wassermelone und Kaffee` key `small` on *Wassermelone, roh* [de, machine] = *Watermelon, raw* (2709270) → `1 small wedge/slice` 218.0 g; **tie** with `1 small melon` 3200.0 g
- openai `eine mittlere Hähnchenbrust` key `medium` on *Hähnchenbrust, geschmort, Haut mitgegessen* [de, machine] = *Chicken breast, stewed, skin eaten* (2705965) → `1 medium breast` 150.0 g; **tie** with `1 mittlere Scheibe` (en `1 medium slice`) 60.0 g; **middle rung** decided (the first row anyway)
- openai `ein großer Apfel` key `large` on *Apfel, roh* [de, machine] = *Apple, raw* (2709215) → `1 groß` (en `1 large`) 242.0 g; **tie** with `1 extra large` 295.0 g
- openai `4 slices chicken breast` key `slice` on *Chicken breast, stewed, skin eaten* (2705965) → `1 medium slice` 60.0 g; **tie** with `1 small or thin slice` 30.0 g, `1 large or thick slice` 85.0 g; **middle rung** decided, moved off the first row

## has_portion on the row against the rows delivered — where they disagree (0)

_none_

## False-match surface — every hit decided by row order or by an inflection, with the row it picked (#1160) (27)

- anthropic `I had 1 slice of bacon` key `slice` on *Bacon, NS as to type of meat, cooked* (2705885) → `1 medium slice (yield after cooking)` 8.0 g; **tie** with `1 thin slice (yield after cooking)` 5.0 g, `1 thick slice (yield after cooking)` 12.0 g; **middle rung** decided, moved off the first row
- anthropic `6 Scheiben Käse` key `slice` on *Käse, NFS* [de, machine] = *Cheese, NFS* (2705704) → `1 Scheibe in Crackergröße` (en `1 cracker-size slice`) 9.0 g; **tie** with `1 Scheibe` (en `1 slice`) 21.0 g
- anthropic `a slice of chicken breast` key `slice` on *Chicken breast, stewed, skin eaten* (2705965) → `1 medium slice` 60.0 g; **tie** with `1 small or thin slice` 30.0 g, `1 large or thick slice` 85.0 g; **middle rung** decided, moved off the first row
- anthropic `ich hatte 2 Scheiben Brot` key `slice` on *Brot, Käse* [de, machine] = *Bread, cheese* (2707618) → `1 mittlere oder normale Scheibe` (en `1 medium or regular slice`) 28.0 g; **tie** with `1 kleine oder dünne/sehr dünne Scheibe` (en `1 small or thin/very thin slice`) 24.0 g, `1 große oder dicke Scheibe` (en `1 large or thick slice`) 43.0 g, `1 Scheibe, Rand nicht gegessen` (en `1 slice, crust not eaten`) 13.0 g, `1 Scheibe, Snackgröße` (en `1 slice, snack-size`) 10.0 g; **middle rung** decided, moved off the first row
- anthropic `1 mittlere Pizza` key `medium` on *Pizza, Käse, gefüllter Rand* [de, machine] = *Pizza, cheese, stuffed crust* (2708618) → `1 Stück, mittlere Pizza` (en `1 piece, medium pizza`) 100.0 g; **tie** with `1 mittlere Pizza (11-12" Durchmesser)` (en `1 medium pizza (11-12" diameter)`) 800.0 g; **middle rung** decided (the first row anyway)
- anthropic `3 kleine Wassermelone und Kaffee` key `small` on *Wassermelone, roh* [de, machine] = *Watermelon, raw* (2709270) → `1 small wedge/slice` 218.0 g; **tie** with `1 small melon` 3200.0 g
- anthropic `ein großer Apfel` key `large` on *Apfel, roh* [de, machine] = *Apple, raw* (2709215) → `1 groß` (en `1 large`) 242.0 g; **tie** with `1 extra large` 295.0 g
- anthropic `eine mittlere Hähnchenbrust` key `medium` on *Hähnchenbrust, geschmort, Haut mitgegessen* [de, machine] = *Chicken breast, stewed, skin eaten* (2705965) → `1 medium breast` 150.0 g; **tie** with `1 mittlere Scheibe` (en `1 medium slice`) 60.0 g; **middle rung** decided (the first row anyway)
- anthropic `4 slices chicken breast` key `slice` on *Chicken breast, stewed, skin eaten* (2705965) → `1 medium slice` 60.0 g; **tie** with `1 small or thin slice` 30.0 g, `1 large or thick slice` 85.0 g; **middle rung** decided, moved off the first row
- openrouter `I had 1 slice of bacon` key `slice` on *Bacon, NS as to type of meat, cooked* (2705885) → `1 medium slice (yield after cooking)` 8.0 g; **tie** with `1 thin slice (yield after cooking)` 5.0 g, `1 thick slice (yield after cooking)` 12.0 g; **middle rung** decided, moved off the first row
- openrouter `6 Scheiben Käse` key `slice` on *Käse, NFS* [de, machine] = *Cheese, NFS* (2705704) → `1 Scheibe in Crackergröße` (en `1 cracker-size slice`) 9.0 g; **tie** with `1 Scheibe` (en `1 slice`) 21.0 g
- openrouter `a slice of chicken breast` key `slice` on *Chicken breast, stewed, skin eaten* (2705965) → `1 medium slice` 60.0 g; **tie** with `1 small or thin slice` 30.0 g, `1 large or thick slice` 85.0 g; **middle rung** decided, moved off the first row
- openrouter `ich hatte 2 Scheiben Brot` key `slice` on *Brot, Käse* [de, machine] = *Bread, cheese* (2707618) → `1 mittlere oder normale Scheibe` (en `1 medium or regular slice`) 28.0 g; **tie** with `1 kleine oder dünne/sehr dünne Scheibe` (en `1 small or thin/very thin slice`) 24.0 g, `1 große oder dicke Scheibe` (en `1 large or thick slice`) 43.0 g, `1 Scheibe, Rand nicht gegessen` (en `1 slice, crust not eaten`) 13.0 g, `1 Scheibe, Snackgröße` (en `1 slice, snack-size`) 10.0 g; **middle rung** decided, moved off the first row
- openrouter `1 mittlere Pizza` key `medium` on *Pizza, Käse, gefüllter Rand* [de, machine] = *Pizza, cheese, stuffed crust* (2708618) → `1 Stück, mittlere Pizza` (en `1 piece, medium pizza`) 100.0 g; **tie** with `1 mittlere Pizza (11-12" Durchmesser)` (en `1 medium pizza (11-12" diameter)`) 800.0 g; **middle rung** decided (the first row anyway)
- openrouter `3 kleine Wassermelone und Kaffee` key `small` on *Wassermelone, roh* [de, machine] = *Watermelon, raw* (2709270) → `1 small wedge/slice` 218.0 g; **tie** with `1 small melon` 3200.0 g
- openrouter `eine mittlere Hähnchenbrust` key `medium` on *Hähnchenbrust, geschmort, Haut mitgegessen* [de, machine] = *Chicken breast, stewed, skin eaten* (2705965) → `1 medium breast` 150.0 g; **tie** with `1 mittlere Scheibe` (en `1 medium slice`) 60.0 g; **middle rung** decided (the first row anyway)
- openrouter `ein großer Apfel` key `large` on *Apfel, roh* [de, machine] = *Apple, raw* (2709215) → `1 groß` (en `1 large`) 242.0 g; **tie** with `1 extra large` 295.0 g
- openrouter `4 slices chicken breast` key `slice` on *Chicken breast, stewed, skin eaten* (2705965) → `1 medium slice` 60.0 g; **tie** with `1 small or thin slice` 30.0 g, `1 large or thick slice` 85.0 g; **middle rung** decided, moved off the first row
- openai `I had 1 slice of bacon` key `slice` on *Bacon, NS as to type of meat, cooked* (2705885) → `1 medium slice (yield after cooking)` 8.0 g; **tie** with `1 thin slice (yield after cooking)` 5.0 g, `1 thick slice (yield after cooking)` 12.0 g; **middle rung** decided, moved off the first row
- openai `6 Scheiben Käse` key `slice` on *Käse, NFS* [de, machine] = *Cheese, NFS* (2705704) → `1 Scheibe in Crackergröße` (en `1 cracker-size slice`) 9.0 g; **tie** with `1 Scheibe` (en `1 slice`) 21.0 g
- openai `a slice of chicken breast` key `slice` on *Chicken breast, stewed, skin eaten* (2705965) → `1 medium slice` 60.0 g; **tie** with `1 small or thin slice` 30.0 g, `1 large or thick slice` 85.0 g; **middle rung** decided, moved off the first row
- openai `ich hatte 2 Scheiben Brot` key `slice` on *Brot, Käse* [de, machine] = *Bread, cheese* (2707618) → `1 mittlere oder normale Scheibe` (en `1 medium or regular slice`) 28.0 g; **tie** with `1 kleine oder dünne/sehr dünne Scheibe` (en `1 small or thin/very thin slice`) 24.0 g, `1 große oder dicke Scheibe` (en `1 large or thick slice`) 43.0 g, `1 Scheibe, Rand nicht gegessen` (en `1 slice, crust not eaten`) 13.0 g, `1 Scheibe, Snackgröße` (en `1 slice, snack-size`) 10.0 g; **middle rung** decided, moved off the first row
- openai `1 mittlere Pizza` key `medium` on *Pizza, Käse, gefüllter Rand* [de, machine] = *Pizza, cheese, stuffed crust* (2708618) → `1 Stück, mittlere Pizza` (en `1 piece, medium pizza`) 100.0 g; **tie** with `1 mittlere Pizza (11-12" Durchmesser)` (en `1 medium pizza (11-12" diameter)`) 800.0 g; **middle rung** decided (the first row anyway)
- openai `3 kleine Wassermelone und Kaffee` key `small` on *Wassermelone, roh* [de, machine] = *Watermelon, raw* (2709270) → `1 small wedge/slice` 218.0 g; **tie** with `1 small melon` 3200.0 g
- openai `eine mittlere Hähnchenbrust` key `medium` on *Hähnchenbrust, geschmort, Haut mitgegessen* [de, machine] = *Chicken breast, stewed, skin eaten* (2705965) → `1 medium breast` 150.0 g; **tie** with `1 mittlere Scheibe` (en `1 medium slice`) 60.0 g; **middle rung** decided (the first row anyway)
- openai `ein großer Apfel` key `large` on *Apfel, roh* [de, machine] = *Apple, raw* (2709215) → `1 groß` (en `1 large`) 242.0 g; **tie** with `1 extra large` 295.0 g
- openai `4 slices chicken breast` key `slice` on *Chicken breast, stewed, skin eaten* (2705965) → `1 medium slice` 60.0 g; **tie** with `1 small or thin slice` 30.0 g, `1 large or thick slice` 85.0 g; **middle rung** decided, moved off the first row

## Key misses — a key on a resolved food that matched no row, and whether portionKeyMissed fires (#1159) (210)

- anthropic `a piece of salmon` key `piece` on *Salmon, sockeye, canned, total can contents* (175174) (has_portion false; 0 rows: ) → quiet: food has no rows
- anthropic `ich hatte 5 Stück Eier` key `piece` on *Eier, Klasse A, groß, ganz* [de, machine] = *Eggs, Grade A, Large, egg whole* (748967) (has_portion false; 0 rows: ) → quiet: food has no rows
- anthropic `pizza, 3 plátky` key `slice` on *Pizza, no cheese, thin crust* (2708674) [no cs translation hit; English search] (has_portion true; 10 rows: `1 piece, small pizza`, `1 piece, medium pizza`, `1 piece, large pizza`, `1 piece, extra-large pizza`, `1 personal size pizza (5-7" diameter)`, `1 small pizza (8-10" diameter)`, …) → quiet: query words hit `1 piece, medium pizza` 54.0 g
- anthropic `I had 2 teaspoons of olive oil` key `teaspoon` on *Olive oil* (2710186) (has_portion true; 2 rows: `1 cup`, `1 tablespoon`) → **portionKeyMissed**
- anthropic `ein Esslöffel Zucker` key `tablespoon` on *Zucker, NFS* [de, machine] = *Sugar, NFS* (2710257) (has_portion true; 4 rows: `1 Tasse` (en `1 cup`), `1 teaspoon`, `1 individual packet`, `1 cube`) → **portionKeyMissed**
- anthropic `cottage cheese, 2 tbsp` key `tablespoon` on *Cheese, cottage, NFS* (2705747) (has_portion true; 1 rows: `1 cup`) → **portionKeyMissed**
- anthropic `ich hatte 4 EL Honig` key `tablespoon` on *Honig* [de] = *Honey* (10000036) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- anthropic `ich hatte 2 TL Honig` key `teaspoon` on *Honig* [de] = *Honey* (10000036) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- anthropic `a tsp of peanut butter` key `teaspoon` on *Peanut butter* (2707537) (has_portion true; 2 rows: `1 tablespoon`, `1 single serving`) → **portionKeyMissed**
- anthropic `I had 4 glasses of milk` key `glass` on *Milk, NFS* (2705384) (has_portion true; 3 rows: `1 cup`, `1 fl oz`, `1 individual school container`) → **portionKeyMissed**
- anthropic `6 Gläser Kaffee` key `glass` on *Kaffee, Latte* [de, machine] = *Coffee, Latte* (2710386) (has_portion true; 5 rows: `1 Flüssigunze` (en `1 fl oz`), `1 Tasse (8 Flüssigunzen)` (en `1 cup (8 fl oz)`), `1 klein` (en `1 small`), `1 mittel` (en `1 medium`), `1 groß` (en `1 large`)) → **portionKeyMissed**
- anthropic `eine Schüssel Reis` key `bowl` on *Reis, gekocht, NFS* [de, machine] = *Rice, cooked, NFS* (2708402) (has_portion true; 1 rows: `1 Tasse, gegart` (en `1 cup, cooked`)) → quiet: no count
- anthropic `a bowl of lentil soup` key `bowl` on *Soup, lentil* (2707462) (has_portion true; 1 rows: `1 cup`) → quiet: no count
- anthropic `I had 4 handfuls of granola` key `handful` on *Cookie, granola* (2707933) (has_portion true; 4 rows: `1 miniature/bite size`, `1 small`, `1 medium`, `1 large`) → **portionKeyMissed**
- anthropic `Müsli, 3 Handvoll` key `handful` on *Müsli, Granola* [de, machine] = *Cereal, granola* (2708461) (has_portion true; 2 rows: `1 Tasse` (en `1 cup`), `1 abgepackte Einzelportion` (en `1 prepackaged single serving`)) → **portionKeyMissed**
- anthropic `2 small ham sandwich` key `small` on *Ham sandwich wrap* (2706970) (has_portion true; 1 rows: `1 sandwich, any size`) → quiet: query words hit `1 sandwich, any size` 135.0 g
- anthropic `1 kleine Pizza und Kaffee` key `small` on *Pizza, Käse, gefüllter Rand* [de, machine] = *Pizza, cheese, stuffed crust* (2708618) (has_portion true; 6 rows: `1 Stück, mittlere Pizza` (en `1 piece, medium pizza`), `1 Stück, große Pizza` (en `1 piece, large pizza`), `1 Pizza in Einzelgröße (5-7" Durchmesser)` (en `1 personal size pizza (5-7" diameter)`), `1 mittlere Pizza (11-12" Durchmesser)` (en `1 medium pizza (11-12" diameter)`), `1 große Pizza (13-15" Durchmesser)` (en `1 large pizza (13-15" diameter)`), `1 Quadratzoll` (en `1 surface inch`)) → quiet: query words hit `1 Stück, mittlere Pizza` (en `1 piece, medium pizza`) 100.0 g
- anthropic `3 medium cheddar` key `medium` on *Cheese, Cheddar* (2705709) (has_portion true; 8 rows: `1 cracker-size slice`, `1 slice`, `1 stick`, `1 cup, shredded`, `1 cup, diced`, `1 cup, melted`, …) → **portionKeyMissed**
- anthropic `ein mittleres Vollkornbrot` key `medium` on *Vollkornbrot* [de] = *Wholemeal bread* (10002122) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- anthropic `a large ham sandwich` key `large` on *Ham* (2705878) (has_portion true; 4 rows: `1 regular/thin slice`, `1 thick slice`, `1 cubic inch`, `1 cup`) → quiet: no count
- anthropic `6 pieces apple` key `piece` on *Apple, raw* (2709215) (has_portion true; 7 rows: `1 small`, `1 medium`, `1 large`, `1 extra large`, `1 slice`, `1 cup`, …) → **portionKeyMissed**
- anthropic `a teaspoon of peanut butter` key `teaspoon` on *Peanut butter* (2707537) (has_portion true; 2 rows: `1 tablespoon`, `1 single serving`) → **portionKeyMissed**
- anthropic `salmone, 3 pezzi` key `piece` on *Salmon salad* (2706826) [no it translation hit; English search] (has_portion true; 1 rows: `1 cup`) → **portionKeyMissed**
- anthropic `a tbsp of sugar` key `tablespoon` on *Sugar, NFS* (2710257) (has_portion true; 4 rows: `1 cup`, `1 teaspoon`, `1 individual packet`, `1 cube`) → **portionKeyMissed**
- anthropic `1 großes Rindersteak und Kaffee` key `large` on *Rindersteak gegrillt* [de] = *Beef steak grilled* (10002519) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- anthropic `granola, 1 bowl` key `bowl` on *Cookie, granola* (2707933) (has_portion true; 4 rows: `1 miniature/bite size`, `1 small`, `1 medium`, `1 large`) → **portionKeyMissed**
- anthropic `a glass of green tea` key `glass` on *Tea, hot, leaf, green* (2710490) (has_portion true; 5 rows: `1 fl oz`, `1 cup`, `1 small`, `1 medium`, `1 large`) → **portionKeyMissed**
- anthropic `a handful of granola` key `handful` on *Cookie, granola* (2707933) (has_portion true; 4 rows: `1 miniature/bite size`, `1 small`, `1 medium`, `1 large`) → quiet: no count
- anthropic `1 small eggs` key `small` on *Egg, creamed* (2707179) (has_portion true; 2 rows: `1 egg`, `1 cup`) → quiet: query words hit `1 egg` 145.0 g
- anthropic `5 Stück Apfel zum Frühstück` key `piece` on *Apfel, roh* [de, machine] = *Apple, raw* (2709215) (has_portion true; 7 rows: `1 klein` (en `1 small`), `1 mittel` (en `1 medium`), `1 groß` (en `1 large`), `1 extra large`, `1 Scheibe` (en `1 slice`), `1 Tasse` (en `1 cup`), …) → **portionKeyMissed**
- anthropic `6 tazze di porridge` key `cup` on *Porridge, roasted, with vegetable stock and egg* (10006934) [no it translation hit; English search] (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- anthropic `3 medium toast` key `medium` on *Melba toast* (2707702) (has_portion true; 3 rows: `1 cracker`, `1 melba toast`, `1 crostini`) → quiet: query words hit `1 melba toast` 5.0 g
- anthropic `a piece of chicken breast` key `piece` on *Chicken breast, stewed, skin eaten* (2705965) (has_portion true; 8 rows: `1 cup, cooked, diced`, `1 small breast`, `1 medium breast`, `1 large breast`, `1 small or thin slice`, `1 medium slice`, …) → quiet: query words hit `1 medium breast` 150.0 g
- anthropic `Olivenöl, 6 Teelöffel` key `teaspoon` on *Olivenöl* [de, machine] = *Olive oil* (2710186) (has_portion true; 2 rows: `1 Tasse` (en `1 cup`), `1 Esslöffel` (en `1 tablespoon`)) → **portionKeyMissed**
- anthropic `Kaffee, 6 Gläser` key `glass` on *Kaffee, Latte* [de, machine] = *Coffee, Latte* (2710386) (has_portion true; 5 rows: `1 Flüssigunze` (en `1 fl oz`), `1 Tasse (8 Flüssigunzen)` (en `1 cup (8 fl oz)`), `1 klein` (en `1 small`), `1 mittel` (en `1 medium`), `1 groß` (en `1 large`)) → **portionKeyMissed**
- anthropic `3 TL Olivenöl zum Frühstück` key `teaspoon` on *Olivenöl* [de, machine] = *Olive oil* (2710186) (has_portion true; 2 rows: `1 Tasse` (en `1 cup`), `1 Esslöffel` (en `1 tablespoon`)) → **portionKeyMissed**
- anthropic `2 EL Honig` key `tablespoon` on *Honig* [de] = *Honey* (10000036) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- anthropic `ich hatte 6 Schüsseln Nudeln` key `bowl` on *Nudeln, gekocht* [de, machine] = *Noodles, cooked* (2708352) (has_portion true; 1 rows: `1 Tasse, gegart` (en `1 cup, cooked`)) → **portionKeyMissed**
- anthropic `ich hatte 4 Handvoll Müsli` key `handful` on *Müsli, Granola* [de, machine] = *Cereal, granola* (2708461) (has_portion true; 2 rows: `1 Tasse` (en `1 cup`), `1 abgepackte Einzelportion` (en `1 prepackaged single serving`)) → **portionKeyMissed**
- anthropic `2 kleine Lachs` key `small` on *Lachs, Rotlachs, in Dosen, Gesamtinhalt der Dose* [de, machine] = *Salmon, sockeye, canned, total can contents* (175174) (has_portion false; 0 rows: ) → quiet: food has no rows
- anthropic `I had 1 teaspoon of olive oil` key `teaspoon` on *Olive oil* (2710186) (has_portion true; 2 rows: `1 cup`, `1 tablespoon`) → **portionKeyMissed**
- anthropic `ein großer Käse` key `large` on *Käse, NFS* [de, machine] = *Cheese, NFS* (2705704) (has_portion true; 6 rows: `1 Scheibe in Crackergröße` (en `1 cracker-size slice`), `1 Scheibe` (en `1 slice`), `1 Stange` (en `1 stick`), `1 Tasse` (en `1 cup`), `1 cup, melted`, `1 Kubikzoll` (en `1 cubic inch`)) → quiet: no count
- anthropic `4 glasses orange juice` key `glass` on *Orange juice, 100%, NFS* (2709186) (has_portion true; 5 rows: `1 fl oz (no ice)`, `1 fl oz (with ice)`, `1 fun size box (4.23 fl oz)`, `1 juice box/pouch (6.75 fl oz)`, `1 individual school container`) → quiet: query words hit `1 juice box/pouch (6.75 fl oz)` 209.0 g
- anthropic `5 bowls white rice` key `bowl` on *Rice, white, cooked, glutinous* (2708422) (has_portion true; 1 rows: `1 cup, cooked`) → **portionKeyMissed**
- anthropic `almonds, 6 handfuls` key `handful` on *Almonds, NFS* (2707485) (has_portion true; 5 rows: `1 nut`, `1 cup`, `1 package`, `1 100 calorie package`, `1 oz`) → **portionKeyMissed**
- anthropic `Orangensaft, 3 Tassen` key `cup` on *Orangensaft, 100 %, NFS* [de, machine] = *Orange juice, 100%, NFS* (2709186) (has_portion true; 5 rows: `1 Flüssigunze (ohne Eis)` (en `1 fl oz (no ice)`), `1 Flüssigunze (mit Eis)` (en `1 fl oz (with ice)`), `1 fun size box (4.23 fl oz)`, `1 juice box/pouch (6.75 fl oz)`, `1 individual school container`) → **portionKeyMissed**
- anthropic `a medium dark chocolate` key `medium` on *Dark chocolate* (10000881) (has_portion false; 0 rows: ) → quiet: food has no rows
- anthropic `3 small toast` key `small` on *Melba toast* (2707702) (has_portion true; 3 rows: `1 cracker`, `1 melba toast`, `1 crostini`) → quiet: query words hit `1 melba toast` 5.0 g
- anthropic `a large cake` key `large` on *Cake, cream* (2707872) (has_portion true; 3 rows: `1 cupcake, any size`, `1 piece/slice, any size`, `1 cup`) → quiet: no count
- anthropic `2 slices of toast` key `slice` on *Melba toast* (2707702) (has_portion true; 3 rows: `1 cracker`, `1 melba toast`, `1 crostini`) → quiet: query words hit `1 melba toast` 5.0 g
- anthropic `ein Teelöffel Erdnussbutter` key `teaspoon` on *Erdnussbutter* [de, machine] = *Peanut butter* (2707537) (has_portion true; 2 rows: `1 Esslöffel` (en `1 tablespoon`), `1 single serving`) → **portionKeyMissed**
- anthropic `a piece of ham sandwich` key `piece` on *Ham sandwich wrap* (2706970) (has_portion true; 1 rows: `1 sandwich, any size`) → quiet: query words hit `1 sandwich, any size` 135.0 g
- anthropic `3 TL Quark zum Frühstück` key `tablespoon` on *Quark-Plunder* [de] = *Danish pastry with quark* (10006718) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- anthropic `4 Gläser grüner Tee` key `cup` on *Tee, Eistee, in Flaschen, grüner Tee* [de, machine] = *Tea, iced, bottled, green* (2710533) (has_portion true; 11 rows: `1 Flüssigunze (ohne Eis)` (en `1 fl oz (no ice)`), `1 Flüssigunze (mit Eis)` (en `1 fl oz (with ice)`), `1 can or bottle (12 fl oz)`, `1 Snapple bottle (16 fl oz)`, `1 can or bottle (16.9 fl oz)`, `1 can or bottle (20 fl oz)`, …) → **portionKeyMissed**
- anthropic `3 Handvoll Müsli` key `handful` on *Müsli, Granola* [de, machine] = *Cereal, granola* (2708461) (has_portion true; 2 rows: `1 Tasse` (en `1 cup`), `1 abgepackte Einzelportion` (en `1 prepackaged single serving`)) → **portionKeyMissed**
- anthropic `3 Schüsseln Nudeln` key `bowl` on *Nudeln, gekocht* [de, machine] = *Noodles, cooked* (2708352) (has_portion true; 1 rows: `1 Tasse, gegart` (en `1 cup, cooked`)) → **portionKeyMissed**
- anthropic `I had 2 teaspoons of peanut butter` key `teaspoon` on *Peanut butter* (2707537) (has_portion true; 2 rows: `1 tablespoon`, `1 single serving`) → **portionKeyMissed**
- anthropic `Vollkornbrot, 2 Scheiben` key `slice` on *Vollkornbrot* [de] = *Wholemeal bread* (10002122) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- anthropic `6 glasses milk` key `glass` on *Milk, NFS* (2705384) (has_portion true; 3 rows: `1 cup`, `1 fl oz`, `1 individual school container`) → **portionKeyMissed**
- anthropic `3 miski spaghetti` key `bowl` on *Spaghetti, spinach, dry* (168911) [no pl translation hit; English search] (has_portion false; 0 rows: ) → quiet: food has no rows
- anthropic `I had 6 handfuls of almonds` key `handful` on *Almonds, NFS* (2707485) (has_portion true; 5 rows: `1 nut`, `1 cup`, `1 package`, `1 100 calorie package`, `1 oz`) → **portionKeyMissed**
- anthropic `1 small bacon and coffee` key `small` on *Bacon, NS as to type of meat, cooked* (2705885) (has_portion true; 6 rows: `1 thin slice (yield after cooking)`, `1 medium slice (yield after cooking)`, `1 thick slice (yield after cooking)`, `1 oz, raw (yield after cooking)`, `1 oz, cooked`, `1 cup, pieces`) → **portionKeyMissed**
- anthropic `eine Tasse grüner Tee` key `cup` on *Tee, Eistee, in Flaschen, grüner Tee* [de, machine] = *Tea, iced, bottled, green* (2710533) (has_portion true; 11 rows: `1 Flüssigunze (ohne Eis)` (en `1 fl oz (no ice)`), `1 Flüssigunze (mit Eis)` (en `1 fl oz (with ice)`), `1 can or bottle (12 fl oz)`, `1 Snapple bottle (16 fl oz)`, `1 can or bottle (16.9 fl oz)`, `1 can or bottle (20 fl oz)`, …) → **portionKeyMissed**
- anthropic `6 Esslöffel Quark zum Frühstück` key `tablespoon` on *Quark-Plunder* [de] = *Danish pastry with quark* (10006718) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- anthropic `1 medium dark chocolate and coffee` key `medium` on *Dark chocolate* (10000881) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- anthropic `2 malé steak` key `small` on *Steak, NS as to type of meat, NS as to fat eaten* (2705823) [no sk translation hit; English search] (has_portion true; 6 rows: `1 piece/slice, any size`, `1 thin`, `1 regular`, `1 thick`, `1 cubic inch`, `1 cup`) → **portionKeyMissed**
- anthropic `3 large cake and coffee` key `large` on *Cake, cream* (2707872) (has_portion true; 3 rows: `1 cupcake, any size`, `1 piece/slice, any size`, `1 cup`) → **portionKeyMissed**
- anthropic `tuna, 6 cups` key `cup` on *Tuna, ahi or yellowfin, frozen, wild caught* (2747673) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- anthropic `4 pieces of dark chocolate for breakfast` key `piece` on *Dark chocolate* (10000881) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- anthropic `Quark, 3 EL` key `tablespoon` on *Quark-Plunder* [de] = *Danish pastry with quark* (10006718) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- openrouter `ich hatte 5 Stück Eier` key `piece` on *Eier, Klasse A, groß, ganz* [de, machine] = *Eggs, Grade A, Large, egg whole* (748967) (has_portion false; 0 rows: ) → quiet: food has no rows
- openrouter `a piece of salmon` key `piece` on *Salmon, sockeye, canned, total can contents* (175174) (has_portion false; 0 rows: ) → quiet: food has no rows
- openrouter `pizza, 3 plátky` key `slice` on *Pizza, no cheese, thin crust* (2708674) [no cs translation hit; English search] (has_portion true; 10 rows: `1 piece, small pizza`, `1 piece, medium pizza`, `1 piece, large pizza`, `1 piece, extra-large pizza`, `1 personal size pizza (5-7" diameter)`, `1 small pizza (8-10" diameter)`, …) → quiet: query words hit `1 piece, medium pizza` 54.0 g
- openrouter `I had 2 teaspoons of olive oil` key `teaspoon` on *Olive oil* (2710186) (has_portion true; 2 rows: `1 cup`, `1 tablespoon`) → **portionKeyMissed**
- openrouter `ein Esslöffel Zucker` key `tablespoon` on *Zucker, NFS* [de, machine] = *Sugar, NFS* (2710257) (has_portion true; 4 rows: `1 Tasse` (en `1 cup`), `1 teaspoon`, `1 individual packet`, `1 cube`) → **portionKeyMissed**
- openrouter `ich hatte 4 EL Honig` key `tablespoon` on *Honig* [de] = *Honey* (10000036) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- openrouter `ich hatte 2 TL Honig` key `teaspoon` on *Honig* [de] = *Honey* (10000036) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- openrouter `cottage cheese, 2 tbsp` key `tablespoon` on *Cheese, cottage, NFS* (2705747) (has_portion true; 1 rows: `1 cup`) → **portionKeyMissed**
- openrouter `I had 4 glasses of milk` key `glass` on *Milk, NFS* (2705384) (has_portion true; 3 rows: `1 cup`, `1 fl oz`, `1 individual school container`) → **portionKeyMissed**
- openrouter `a tsp of peanut butter` key `teaspoon` on *Peanut butter* (2707537) (has_portion true; 2 rows: `1 tablespoon`, `1 single serving`) → **portionKeyMissed**
- openrouter `6 Gläser Kaffee` key `glass` on *Kaffee, Latte* [de, machine] = *Coffee, Latte* (2710386) (has_portion true; 5 rows: `1 Flüssigunze` (en `1 fl oz`), `1 Tasse (8 Flüssigunzen)` (en `1 cup (8 fl oz)`), `1 klein` (en `1 small`), `1 mittel` (en `1 medium`), `1 groß` (en `1 large`)) → **portionKeyMissed**
- openrouter `eine Schüssel Reis` key `bowl` on *Reis, gekocht, NFS* [de, machine] = *Rice, cooked, NFS* (2708402) (has_portion true; 1 rows: `1 Tasse, gegart` (en `1 cup, cooked`)) → **portionKeyMissed**
- openrouter `I had 4 handfuls of granola` key `handful` on *Cookie, granola* (2707933) (has_portion true; 4 rows: `1 miniature/bite size`, `1 small`, `1 medium`, `1 large`) → **portionKeyMissed**
- openrouter `a bowl of lentil soup` key `bowl` on *Soup, lentil* (2707462) (has_portion true; 1 rows: `1 cup`) → quiet: no count
- openrouter `Müsli, 3 Handvoll` key `handful` on *Müsli, Granola* [de, machine] = *Cereal, granola* (2708461) (has_portion true; 2 rows: `1 Tasse` (en `1 cup`), `1 abgepackte Einzelportion` (en `1 prepackaged single serving`)) → **portionKeyMissed**
- openrouter `2 small ham sandwich` key `small` on *Ham sandwich wrap* (2706970) (has_portion true; 1 rows: `1 sandwich, any size`) → quiet: query words hit `1 sandwich, any size` 135.0 g
- openrouter `1 kleine Pizza und Kaffee` key `small` on *Pizza, Käse, gefüllter Rand* [de, machine] = *Pizza, cheese, stuffed crust* (2708618) (has_portion true; 6 rows: `1 Stück, mittlere Pizza` (en `1 piece, medium pizza`), `1 Stück, große Pizza` (en `1 piece, large pizza`), `1 Pizza in Einzelgröße (5-7" Durchmesser)` (en `1 personal size pizza (5-7" diameter)`), `1 mittlere Pizza (11-12" Durchmesser)` (en `1 medium pizza (11-12" diameter)`), `1 große Pizza (13-15" Durchmesser)` (en `1 large pizza (13-15" diameter)`), `1 Quadratzoll` (en `1 surface inch`)) → quiet: query words hit `1 Stück, mittlere Pizza` (en `1 piece, medium pizza`) 100.0 g
- openrouter `3 medium cheddar` key `medium` on *Cheese, Cheddar* (2705709) (has_portion true; 8 rows: `1 cracker-size slice`, `1 slice`, `1 stick`, `1 cup, shredded`, `1 cup, diced`, `1 cup, melted`, …) → **portionKeyMissed**
- openrouter `ein mittleres Vollkornbrot` key `medium` on *Vollkornbrot* [de] = *Wholemeal bread* (10002122) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- openrouter `a large ham sandwich` key `large` on *Ham sandwich wrap* (2706970) (has_portion true; 1 rows: `1 sandwich, any size`) → quiet: no count
- openrouter `6 pieces apple` key `piece` on *Apple, raw* (2709215) (has_portion true; 7 rows: `1 small`, `1 medium`, `1 large`, `1 extra large`, `1 slice`, `1 cup`, …) → **portionKeyMissed**
- openrouter `a teaspoon of peanut butter` key `teaspoon` on *Peanut butter* (2707537) (has_portion true; 2 rows: `1 tablespoon`, `1 single serving`) → **portionKeyMissed**
- openrouter `salmone, 3 pezzi` key `piece` on *Salmon salad* (2706826) [no it translation hit; English search] (has_portion true; 1 rows: `1 cup`) → **portionKeyMissed**
- openrouter `a tbsp of sugar` key `tablespoon` on *Sugar, NFS* (2710257) (has_portion true; 4 rows: `1 cup`, `1 teaspoon`, `1 individual packet`, `1 cube`) → **portionKeyMissed**
- openrouter `1 großes Rindersteak und Kaffee` key `large` on *Rindersteak gegrillt* [de] = *Beef steak grilled* (10002519) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- openrouter `a glass of green tea` key `glass` on *Tea, hot, leaf, green* (2710490) (has_portion true; 5 rows: `1 fl oz`, `1 cup`, `1 small`, `1 medium`, `1 large`) → **portionKeyMissed**
- openrouter `granola, 1 bowl` key `bowl` on *Cookie, granola* (2707933) (has_portion true; 4 rows: `1 miniature/bite size`, `1 small`, `1 medium`, `1 large`) → **portionKeyMissed**
- openrouter `a handful of granola` key `handful` on *Cookie, granola* (2707933) (has_portion true; 4 rows: `1 miniature/bite size`, `1 small`, `1 medium`, `1 large`) → quiet: no count
- openrouter `1 small eggs` key `small` on *Egg, creamed* (2707179) (has_portion true; 2 rows: `1 egg`, `1 cup`) → quiet: query words hit `1 egg` 145.0 g
- openrouter `5 Stück Apfel zum Frühstück` key `piece` on *Apfel, roh* [de, machine] = *Apple, raw* (2709215) (has_portion true; 7 rows: `1 klein` (en `1 small`), `1 mittel` (en `1 medium`), `1 groß` (en `1 large`), `1 extra large`, `1 Scheibe` (en `1 slice`), `1 Tasse` (en `1 cup`), …) → **portionKeyMissed**
- openrouter `6 tazze di porridge` key `cup` on *Porridge, roasted, with vegetable stock and egg* (10006934) [no it translation hit; English search] (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- openrouter `3 medium toast` key `medium` on *Melba toast* (2707702) (has_portion true; 3 rows: `1 cracker`, `1 melba toast`, `1 crostini`) → quiet: query words hit `1 melba toast` 5.0 g
- openrouter `Olivenöl, 6 Teelöffel` key `teaspoon` on *Olivenöl* [de, machine] = *Olive oil* (2710186) (has_portion true; 2 rows: `1 Tasse` (en `1 cup`), `1 Esslöffel` (en `1 tablespoon`)) → **portionKeyMissed**
- openrouter `a piece of chicken breast` key `piece` on *Chicken breast, stewed, skin eaten* (2705965) (has_portion true; 8 rows: `1 cup, cooked, diced`, `1 small breast`, `1 medium breast`, `1 large breast`, `1 small or thin slice`, `1 medium slice`, …) → quiet: query words hit `1 medium breast` 150.0 g
- openrouter `3 TL Olivenöl zum Frühstück` key `teaspoon` on *Olivenöl* [de, machine] = *Olive oil* (2710186) (has_portion true; 2 rows: `1 Tasse` (en `1 cup`), `1 Esslöffel` (en `1 tablespoon`)) → **portionKeyMissed**
- openrouter `2 EL Honig` key `tablespoon` on *Honig* [de] = *Honey* (10000036) (has_portion false; 0 rows: ) → quiet: food has no rows (amountNeedsCheck still fires: no scalable serving)
- openrouter `Kaffee, 6 Gläser` key `glass` on *Kaffee, Latte* [de, machine] = *Coffee, Latte* (2710386) (has_portion true; 5 rows: `1 Flüssigunze` (en `1 fl oz`), `1 Tasse (8 Flüssigunzen)` (en `1 cup (8 fl oz)`), `1 klein` (en `1 small`), `1 mittel` (en `1 medium`), `1 groß` (en `1 large`)) → **portionKeyMissed**
- openrouter `ich hatte 6 Schüsseln Nudeln` key `bowl` on *Nudeln, gekocht* [de, machine] = *Noodles, cooked* (2708352) (has_portion true; 1 rows: `1 Tasse, gegart` (en `1 cup, cooked`)) → **portionKeyMissed**
- openrouter `ich hatte 4 Handvoll Müsli` key `handful` on *Müsli, Granola* [de, machine] = *Cereal, granola* (2708461) (has_portion true; 2 rows: `1 Tasse` (en `1 cup`), `1 abgepackte Einzelportion` (en `1 prepackaged single serving`)) → **portionKeyMissed**
- openrouter `2 kleine Lachs` key `small` on *Lachs, Rotlachs, in Dosen, Gesamtinhalt der Dose* [de, machine] = *Salmon, sockeye, canned, total can contents* (175174) (has_portion false; 0 rows: ) → quiet: food has no rows
- openrouter `I had 1 teaspoon of olive oil` key `teaspoon` on *Olive oil* (2710186) (has_portion true; 2 rows: `1 cup`, `1 tablespoon`) → **portionKeyMissed**
- openrouter `ein großer Käse` key `large` on *Käse, NFS* [de, machine] = *Cheese, NFS* (2705704) (has_portion true; 6 rows: `1 Scheibe in Crackergröße` (en `1 cracker-size slice`), `1 Scheibe` (en `1 slice`), `1 Stange` (en `1 stick`), `1 Tasse` (en `1 cup`), `1 cup, melted`, `1 Kubikzoll` (en `1 cubic inch`)) → quiet: no count
- openrouter `4 glasses orange juice` key `glass` on *Orange juice, 100%, NFS* (2709186) (has_portion true; 5 rows: `1 fl oz (no ice)`, `1 fl oz (with ice)`, `1 fun size box (4.23 fl oz)`, `1 juice box/pouch (6.75 fl oz)`, `1 individual school container`) → quiet: query words hit `1 juice box/pouch (6.75 fl oz)` 209.0 g
- openrouter `5 bowls white rice` key `bowl` on *Rice, white, cooked, glutinous* (2708422) (has_portion true; 1 rows: `1 cup, cooked`) → **portionKeyMissed**
- openrouter `Orangensaft, 3 Tassen` key `cup` on *Orangensaft, 100 %, NFS* [de, machine] = *Orange juice, 100%, NFS* (2709186) (has_portion true; 5 rows: `1 Flüssigunze (ohne Eis)` (en `1 fl oz (no ice)`), `1 Flüssigunze (mit Eis)` (en `1 fl oz (with ice)`), `1 fun size box (4.23 fl oz)`, `1 juice box/pouch (6.75 fl oz)`, `1 individual school container`) → **portionKeyMissed**
- openrouter `almonds, 6 handfuls` key `handful` on *Almonds, NFS* (2707485) (has_portion true; 5 rows: `1 nut`, `1 cup`, `1 package`, `1 100 calorie package`, `1 oz`) → **portionKeyMissed**
- openrouter `3 small toast` key `small` on *Melba toast* (2707702) (has_portion true; 3 rows: `1 cracker`, `1 melba toast`, `1 crostini`) → quiet: query words hit `1 melba toast` 5.0 g
- openrouter `a medium dark chocolate` key `medium` on *Dark chocolate* (10000881) (has_portion false; 0 rows: ) → quiet: food has no rows
- openrouter `a large cake` key `large` on *Cake, cream* (2707872) (has_portion true; 3 rows: `1 cupcake, any size`, `1 piece/slice, any size`, `1 cup`) → **portionKeyMissed**
- openrouter `ein Teelöffel Erdnussbutter` key `teaspoon` on *Erdnussbutter* [de, machine] = *Peanut butter* (2707537) (has_portion true; 2 rows: `1 Esslöffel` (en `1 tablespoon`), `1 single serving`) → **portionKeyMissed**

_… 90 more in the JSON_

## Keys on lines that named no measure (8)

- anthropic `一份苹果` item 0 `苹果` → key `serving`
- openrouter `1 medium dark chocolate and coffee` item 1 `coffee` → key `medium`
- openai `一份西兰花` item 0 `西兰花` → key `serving`
- openai `cottage cheese, 2 tbsp` item 1 `cottage cheese` → key `tablespoon`
- openai `куряче філе, 3 скибки` item 1 `скибки` → key `slice`
- openai `a piece of ham sandwich` item 1 `sandwich` → key `piece`
- openai `一份苹果` item 0 `苹果` → key `serving`
- openai `tuna, 6 cups` item 1 `cups` → key `cup`

## Keys that could not be checked (food unresolved, or the backend did not answer) (114)

- anthropic `na raňajky 2 plátky chlieb` `chlieb` → key `slice`
- anthropic `5 kromki pierś z kurczaka` `pierś z kurczaka` → key `slice`
- anthropic `biftek, 6 dilim` `biftek` → key `slice`
- anthropic `куряче філе, 3 скибки` `куряче філе` → key `slice`
- anthropic `4 fette di parmigiano` `parmigiano` → key `slice`
- anthropic `早餐4片披萨` `披萨` → key `slice`
- anthropic `3 kawałki awokado` `awokado` → key `piece`
- anthropic `na śniadanie 3 filiżanki sok pomarańczowy` `sok pomarańczowy` → key `cup`
- anthropic `banán, 6 kusy` `banán` → key `piece`
- anthropic `3 łyżki tuńczyk` `tuńczyk` → key `tablespoon`
- anthropic `na raňajky 2 šálky zelený čaj` `zelený čaj` → key `cup`
- anthropic `піца, 5 шматки` `піца` → key `piece`
- anthropic `tuńczyk, 4 łyżeczki` `tuńczyk` → key `teaspoon`
- anthropic `na śniadanie 3 szklanki mleko` `mleko` → key `cup`
- anthropic `3 Tassen Milchkaffee zum Frühstück` `Milchkaffee` → key `cup`
- anthropic `arašidové maslo, 5 lyžice` `arašidové maslo` → key `tablespoon`
- anthropic `зелений чай, 3 чашки` `зелений чай` → key `cup`
- anthropic `na raňajky 6 lyžičky cukor` `cukor` → key `teaspoon`
- anthropic `4 столові ложки оливкова олія` `оливкова олія` → key `tablespoon`
- anthropic `4 kusy slanina` `slanina` → key `piece`
- anthropic `na raňajky 1 pohár zelený čaj` `zelený čaj` → key `cup`
- anthropic `muz, 3 parça` `muz` → key `piece`
- anthropic `蜂蜜1汤匙` `蜂蜜` → key `tablespoon`
- anthropic `na raňajky 1 miska ovsená kaša` `ovsená kaša` → key `bowl`
- anthropic `řecký jogurt, 6 hrnky` `řecký jogurt` → key `cup`
- anthropic `1 fincan süt` `süt` → key `cup`
- anthropic `4 yemek kaşığı fıstık ezmesi` `fıstık ezmesi` → key `tablespoon`
- anthropic `6 чайні ложки тунець` `тунець` → key `teaspoon`
- anthropic `cukr, 4 lžíce` `cukr` → key `tablespoon`
- anthropic `1 склянка молоко` `молоко` → key `cup`
- anthropic `1 cucchiaio di olio d'oliva` `olio d'oliva` → key `tablespoon`
- anthropic `2 çay kaşığı bal` `bal` → key `teaspoon`
- anthropic `1茶匙蜂蜜` `蜂蜜` → key `teaspoon`
- anthropic `6 garście migdały` `migdały` → key `handful`
- anthropic `mandle, 6 hrste` `mandle` → key `piece`
- anthropic `4碗燕麦粥` `燕麦粥` → key `bowl`
- anthropic `yeşil çay, 1 bardak` `yeşil çay` → key `cup`
- anthropic `一份苹果` `苹果` → key `serving`
- openrouter `na raňajky 2 plátky chlieb` `chlieb` → key `slice`
- openrouter `5 kromki pierś z kurczaka` `pierś z kurczaka` → key `slice`
- openrouter `biftek, 6 dilim` `biftek` → key `slice`
- openrouter `куряче філе, 3 скибки` `куряче філе` → key `slice`
- openrouter `4 fette di parmigiano` `parmigiano` → key `slice`
- openrouter `早餐4片披萨` `披萨` → key `slice`
- openrouter `3 kawałki awokado` `awokado` → key `piece`
- openrouter `na śniadanie 3 filiżanki sok pomarańczowy` `sok pomarańczowy` → key `cup`
- openrouter `banán, 6 kusy` `banán` → key `piece`
- openrouter `3 łyżki tuńczyk` `tuńczyk` → key `tablespoon`
- openrouter `na raňajky 2 šálky zelený čaj` `zelený čaj` → key `cup`
- openrouter `піца, 5 шматки` `піца` → key `slice`
- openrouter `tuńczyk, 4 łyżeczki` `tuńczyk` → key `teaspoon`
- openrouter `早餐5杯杏仁` `杏仁` → key `cup`
- openrouter `na śniadanie 3 szklanki mleko` `mleko` → key `cup`
- openrouter `3 Tassen Milchkaffee zum Frühstück` `Milchkaffee` → key `cup`
- openrouter `arašidové maslo, 5 lyžice` `arašidové maslo` → key `tablespoon`
- openrouter `зелений чай, 3 чашки` `зелений чай` → key `cup`
- openrouter `na raňajky 6 lyžičky cukor` `cukor` → key `teaspoon`
- openrouter `4 столові ложки оливкова олія` `оливкова олія` → key `tablespoon`
- openrouter `4 kusy slanina` `slanina` → key `piece`
- openrouter `na raňajky 1 pohár zelený čaj` `zelený čaj` → key `cup`

_… 54 more in the JSON_

## Call failures (0)

_none_

## Backend failures (0)

_none_

## Invariant violations (3)

- anthropic `一份苹果` _zh_ — unit from the list in portion key "serving"
- openai `一份西兰花` _zh_ — unit from the list in portion key "serving"
- openai `一份苹果` _zh_ — unit from the list in portion key "serving"

## Disagreements with the deterministic parser (0)

_none_

## Unstable on repeat (5)

- anthropic `Avocado, 6 Stück` _de_
  - Avocado|6.0|null|piece
  - Avocado|6.0|null|null
  - Avocado|6.0|null|piece
- anthropic `піца, 5 шматки` _uk_
  - піца|5.0|null|piece
  - піца|5.0|null|piece
  - піца|5.0|null|slice
- openrouter `4 Gläser grüner Tee` _de_
  - grüner Tee|4.0|null|cup
  - grüner Tee|4.0|null|glass
  - grüner Tee|4.0|null|glass
- openrouter `早餐5杯杏仁` _zh_
  - 杏仁|5.0|null|null
  - 杏仁|5.0|null|cup
  - 杏仁|5.0|null|cup
- openai `4 Gläser grüner Tee` _de_
  - grüner Tee|4.0|null|glass
  - grüner Tee|4.0|null|glass
  - grüner Tee|4.0|null|Glas

## Backend

386 read-only RPC calls for 172 distinct queries; 0 failed.

## Appendix

Every item, raw reply included, is in `portion-corpus.items.json` beside this file.
