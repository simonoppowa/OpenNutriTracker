# Live portion corpus — text path (#1160)

240 generated lines (seed `20260911`), 143 of them naming a household measure, across 9 locales; 2026-09-12T05:42:43.140106Z.

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
- *Resolved* is the record the app's AI path lands on for the model's query, searched as the app searches for a user of the line's locale: `search_food_summary` for an English line; for any other, `search_food_translation` in that locale, the hits ranked and cut, `food_summary_by_ids` for them, re-sorted onto the translation order and shown under the translated name — and only when the translation search finds nothing, the English search on the same words. Then the AI path's ranking. *Via translation* counts the resolved measure lines that came through the translation search; the JSON's `resolvedVia` says `english`, `translation` or `englishFallback` per item, and every hit or miss line below names the translated description the app showed. Portions are fetched with `loc = en` on every path.
- *Matched* is `matchPortionToQuery(key, portions) != null`; *tie* means another row scored the same and the earlier one won; *not literal* means the hit came through the matcher's two-letter inflection bound and no word of the key is a word of the winning label as written. Together those are the *false-match surface* #1160 asks for — the hits where a wrong row is possible; whether one *is* wrong is for the reader, and every one is listed with the row it picked.
- *Key miss* is a key on a resolved food that matched nothing. *amountNeedsCheck fires* is the subset #1159's rule would flag, as the getter is gated: the row has a count, and the query words miss too — `_initialUnit` tries `matchPortionToQuery(query, portions)` before defaulting, against the labels of the line's own locale, so a key miss whose query words hit a row is not flagged, and a row with no count is outside the getter. A key miss on a food with no rows always fires.

## Summary per provider

| provider | model | lines | failed | empty | measure lines | key emitted | steering word | English | own word | key = expected | resolved (of keyed) | matched (of resolved) | tie (of matched) | not literal (of matched) | false-match surface (of matched) | key miss (of resolved) | of which: food has no rows | of which: query words hit a row | of which: no count | amountNeedsCheck fires (of resolved) | abbreviation expanded | unit substituted | key on plain line | invariant violations | parser disagreements | unstable | latency p50 / p95 / max |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| anthropic | `claude-haiku-4-5` | 240 | 0 | 3 | 143 | 142/143 (99.3%) | 119/142 (83.8%) | 142/142 (100.0%) | 0/142 (0.0%) | 134/142 (94.4%) | 105/143 (73.4%) | 21/105 (20.0%) | 3/21 (14.3%) | 0/21 (0.0%) | 3/21 (14.3%) | 84/105 (80.0%) | 54/84 (64.3%) | 8/84 (9.5%) | 7/84 (8.3%) | 70/105 (66.7%) | 13/15 (86.7%) (kept 0, other 2, no key 0) | 0 | 1 | 0 | 0 | 2/20 (key alone: 2) | 948 / 1252 / 2866 ms |
| openrouter | `anthropic/claude-haiku-4.5` | 240 | 0 | 3 | 143 | 141/143 (98.6%) | 117/141 (83.0%) | 141/141 (100.0%) | 0/141 (0.0%) | 135/141 (95.7%) | 104/142 (73.2%) | 21/104 (20.2%) | 3/21 (14.3%) | 0/21 (0.0%) | 3/21 (14.3%) | 83/104 (79.8%) | 53/83 (63.9%) | 8/83 (9.6%) | 7/83 (8.4%) | 69/104 (66.3%) | 14/15 (93.3%) (kept 0, other 1, no key 0) | 0 | 1 | 0 | 0 | 2/20 (key alone: 1) | 1004 / 1377 / 2621 ms |
| openai | `gpt-5.6-luna` | 240 | 0 | 3 | 143 | 133/143 (93.0%) | 114/133 (85.7%) | 130/133 (97.7%) | 3/133 (2.3%) | 125/133 (94.0%) | 100/138 (72.5%) | 20/100 (20.0%) | 3/20 (15.0%) | 0/20 (0.0%) | 3/20 (15.0%) | 80/100 (80.0%) | 50/80 (62.5%) | 7/80 (8.8%) | 0/80 (0.0%) | 73/100 (73.0%) | 14/15 (93.3%) (kept 0, other 0, no key 1) | 0 | 5 | 1 | 0 | 3/20 (key alone: 3) | 1200 / 2261 / 8929 ms |

## Per locale

| provider | locale | lines | measure lines | key emitted | steering | own word | key = expected | resolved | via translation | matched | key miss | amountNeedsCheck fires |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| anthropic | en | 77 | 55 | 55/55 (100.0%) | 44/55 (80.0%) | 0/55 (0.0%) | 55/55 (100.0%) | 55/55 (100.0%) | – | 19/55 (34.5%) | 36/55 (65.5%) | 26/55 (47.3%) |
| anthropic | de | 65 | 45 | 45/45 (100.0%) | 37/45 (82.2%) | 0/45 (0.0%) | 42/45 (93.3%) | 44/45 (97.8%) | 44/44 (100.0%) | 1/44 (2.3%) | 43/44 (97.7%) | 40/44 (90.9%) |
| anthropic | cs | 12 | 4 | 4/4 (100.0%) | 4/4 (100.0%) | 0/4 (0.0%) | 4/4 (100.0%) | 1/4 (25.0%) | 0/1 (0.0%) | 0/1 (0.0%) | 1/1 (100.0%) | 0/1 (0.0%) |
| anthropic | it | 10 | 4 | 4/4 (100.0%) | 4/4 (100.0%) | 0/4 (0.0%) | 4/4 (100.0%) | 2/4 (50.0%) | 0/2 (0.0%) | 0/2 (0.0%) | 2/2 (100.0%) | 2/2 (100.0%) |
| anthropic | pl | 13 | 8 | 8/8 (100.0%) | 6/8 (75.0%) | 0/8 (0.0%) | 7/8 (87.5%) | 1/8 (12.5%) | 0/1 (0.0%) | 0/1 (0.0%) | 1/1 (100.0%) | 1/1 (100.0%) |
| anthropic | sk | 13 | 9 | 9/9 (100.0%) | 8/9 (88.9%) | 0/9 (0.0%) | 7/9 (77.8%) | 1/9 (11.1%) | 0/1 (0.0%) | 0/1 (0.0%) | 1/1 (100.0%) | 1/1 (100.0%) |
| anthropic | tr | 14 | 6 | 6/6 (100.0%) | 6/6 (100.0%) | 0/6 (0.0%) | 5/6 (83.3%) | 0/6 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| anthropic | uk | 17 | 6 | 6/6 (100.0%) | 6/6 (100.0%) | 0/6 (0.0%) | 5/6 (83.3%) | 0/6 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| anthropic | zh | 19 | 6 | 5/6 (83.3%) | 4/5 (80.0%) | 0/5 (0.0%) | 5/5 (100.0%) | 0/5 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| openrouter | en | 77 | 55 | 55/55 (100.0%) | 44/55 (80.0%) | 0/55 (0.0%) | 55/55 (100.0%) | 55/55 (100.0%) | – | 19/55 (34.5%) | 36/55 (65.5%) | 26/55 (47.3%) |
| openrouter | de | 65 | 45 | 44/45 (97.8%) | 35/44 (79.5%) | 0/44 (0.0%) | 43/44 (97.7%) | 43/44 (97.7%) | 43/43 (100.0%) | 1/43 (2.3%) | 42/43 (97.7%) | 39/43 (90.7%) |
| openrouter | cs | 12 | 4 | 4/4 (100.0%) | 4/4 (100.0%) | 0/4 (0.0%) | 4/4 (100.0%) | 1/4 (25.0%) | 0/1 (0.0%) | 0/1 (0.0%) | 1/1 (100.0%) | 0/1 (0.0%) |
| openrouter | it | 10 | 4 | 4/4 (100.0%) | 4/4 (100.0%) | 0/4 (0.0%) | 4/4 (100.0%) | 2/4 (50.0%) | 0/2 (0.0%) | 0/2 (0.0%) | 2/2 (100.0%) | 2/2 (100.0%) |
| openrouter | pl | 13 | 8 | 8/8 (100.0%) | 6/8 (75.0%) | 0/8 (0.0%) | 7/8 (87.5%) | 1/8 (12.5%) | 0/1 (0.0%) | 0/1 (0.0%) | 1/1 (100.0%) | 1/1 (100.0%) |
| openrouter | sk | 13 | 9 | 9/9 (100.0%) | 8/9 (88.9%) | 0/9 (0.0%) | 7/9 (77.8%) | 1/9 (11.1%) | 0/1 (0.0%) | 0/1 (0.0%) | 1/1 (100.0%) | 1/1 (100.0%) |
| openrouter | tr | 14 | 6 | 6/6 (100.0%) | 6/6 (100.0%) | 0/6 (0.0%) | 5/6 (83.3%) | 0/6 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| openrouter | uk | 17 | 6 | 6/6 (100.0%) | 6/6 (100.0%) | 0/6 (0.0%) | 5/6 (83.3%) | 0/6 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| openrouter | zh | 19 | 6 | 5/6 (83.3%) | 4/5 (80.0%) | 0/5 (0.0%) | 5/5 (100.0%) | 0/5 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| openai | en | 77 | 55 | 50/55 (90.9%) | 43/50 (86.0%) | 0/50 (0.0%) | 49/50 (98.0%) | 50/50 (100.0%) | – | 19/50 (38.0%) | 31/50 (62.0%) | 27/50 (54.0%) |
| openai | de | 65 | 45 | 43/45 (95.6%) | 36/43 (83.7%) | 3/43 (7.0%) | 39/43 (90.7%) | 42/43 (97.7%) | 42/42 (100.0%) | 1/42 (2.4%) | 41/42 (97.6%) | 39/42 (92.9%) |
| openai | cs | 12 | 4 | 3/4 (75.0%) | 3/3 (100.0%) | 0/3 (0.0%) | 3/3 (100.0%) | 1/3 (33.3%) | 0/1 (0.0%) | 0/1 (0.0%) | 1/1 (100.0%) | 0/1 (0.0%) |
| openai | it | 10 | 4 | 4/4 (100.0%) | 4/4 (100.0%) | 0/4 (0.0%) | 4/4 (100.0%) | 2/4 (50.0%) | 0/2 (0.0%) | 0/2 (0.0%) | 2/2 (100.0%) | 2/2 (100.0%) |
| openai | pl | 13 | 8 | 8/8 (100.0%) | 6/8 (75.0%) | 0/8 (0.0%) | 7/8 (87.5%) | 1/8 (12.5%) | 0/1 (0.0%) | 0/1 (0.0%) | 1/1 (100.0%) | 1/1 (100.0%) |
| openai | sk | 13 | 9 | 8/9 (88.9%) | 6/8 (75.0%) | 0/8 (0.0%) | 8/8 (100.0%) | 1/8 (12.5%) | 0/1 (0.0%) | 0/1 (0.0%) | 1/1 (100.0%) | 1/1 (100.0%) |
| openai | tr | 14 | 6 | 6/6 (100.0%) | 6/6 (100.0%) | 0/6 (0.0%) | 5/6 (83.3%) | 0/6 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| openai | uk | 17 | 6 | 5/6 (83.3%) | 5/5 (100.0%) | 0/5 (0.0%) | 4/5 (80.0%) | 0/5 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |
| openai | zh | 19 | 6 | 6/6 (100.0%) | 5/6 (83.3%) | 0/6 (0.0%) | 6/6 (100.0%) | 0/6 (0.0%) | 0/0 (–) | 0/0 (–) | 0/0 (–) | 0/0 (–) |

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
| anthropic | de | Stück | `piece` | `piece` ×4 |
| anthropic | de | TL | `teaspoon` | `tablespoon` ×2, `teaspoon` ×1 |
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
| anthropic | zh | 杯 | `cup` | `cup` ×1 |
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
| openrouter | de | Stück | `piece` | `piece` ×3, (none) ×1 |
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
| openrouter | sk | hrste | `handful` | `piece` ×1 |
| openrouter | sk | kusy | `piece` | `piece` ×1 |
| openrouter | sk | lyžice | `tablespoon` | `tablespoon` ×1 |
| openrouter | sk | lyžičky | `teaspoon` | `teaspoon` ×1 |
| openrouter | sk | malé | `small` | `small` ×1 |
| openrouter | sk | miska | `bowl` | `bowl` ×1 |
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
| openrouter | uk | шматки | `piece` | `piece` ×1 |
| openrouter | zh | 块 | `piece` | (none) ×1 |
| openrouter | zh | 杯 | `cup` | `cup` ×1 |
| openrouter | zh | 汤匙 | `tablespoon` | `tablespoon` ×1 |
| openrouter | zh | 片 | `slice` | `slice` ×1 |
| openrouter | zh | 碗 | `bowl` | `bowl` ×1 |
| openrouter | zh | 茶匙 | `teaspoon` | `teaspoon` ×1 |
| openai | cs | hrnky | `cup` | (none) ×1 |
| openai | cs | kusy | `piece` | `piece` ×1 |
| openai | cs | lžíce | `tablespoon` | `tablespoon` ×1 |
| openai | cs | plátky | `slice` | `slice` ×1 |
| openai | de | EL | `tablespoon` | `tablespoon` ×4 |
| openai | de | Esslöffel | `tablespoon` | `tablespoon` ×4 |
| openai | de | Gläser | `glass` | `glass` ×1, `Glas` ×1, (none) ×1 |
| openai | de | Handvoll | `handful` | `handvoll` ×2, `piece` ×1 |
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
| openai | en | glasses | `glass` | `glass` ×2, (none) ×1 |
| openai | en | handful | `handful` | (none) ×1 |
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
| openai | tr | parça | `piece` | `piece` ×1 |
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
- anthropic `2 EL Honig` → key `tablespoon` expanded
- anthropic `3 TL Olivenöl zum Frühstück` → key `tablespoon` **other key**
- anthropic `I had 3 tbsp of peanut butter` → key `tablespoon` expanded
- anthropic `5 tsp of sugar` → key `teaspoon` expanded
- anthropic `Butter, 6 EL` → key `tablespoon` expanded
- anthropic `3 TL Quark zum Frühstück` → key `tablespoon` **other key**
- anthropic `1 tbsp butter` → key `tablespoon` expanded
- anthropic `4 tsp of sugar` → key `teaspoon` expanded
- anthropic `Quark, 3 EL` → key `tablespoon` expanded
- openrouter `cottage cheese, 2 tbsp` → key `tablespoon` expanded
- openrouter `ich hatte 2 TL Honig` → key `teaspoon` expanded
- openrouter `ich hatte 4 EL Honig` → key `tablespoon` expanded
- openrouter `a tsp of peanut butter` → key `teaspoon` expanded
- openrouter `a tbsp of sugar` → key `tablespoon` expanded
- openrouter `3 tsp of sugar` → key `teaspoon` expanded
- openrouter `3 TL Olivenöl zum Frühstück` → key `teaspoon` expanded
- openrouter `2 EL Honig` → key `tablespoon` expanded
- openrouter `I had 3 tbsp of peanut butter` → key `tablespoon` expanded
- openrouter `5 tsp of sugar` → key `teaspoon` expanded
- openrouter `Butter, 6 EL` → key `tablespoon` expanded
- openrouter `3 TL Quark zum Frühstück` → key `tablespoon` **other key**
- openrouter `1 tbsp butter` → key `tablespoon` expanded
- openrouter `4 tsp of sugar` → key `teaspoon` expanded
- openrouter `Quark, 3 EL` → key `tablespoon` expanded
- openai `cottage cheese, 2 tbsp` → key – **no key**
- openai `ich hatte 4 EL Honig` → key `tablespoon` expanded
- openai `ich hatte 2 TL Honig` → key `teaspoon` expanded
- openai `a tsp of peanut butter` → key `teaspoon` expanded
- openai `a tbsp of sugar` → key `tablespoon` expanded
- openai `3 tsp of sugar` → key `teaspoon` expanded
- openai `3 TL Olivenöl zum Frühstück` → key `teaspoon` expanded
- openai `2 EL Honig` → key `tablespoon` expanded
- openai `I had 3 tbsp of peanut butter` → key `tablespoon` expanded
- openai `5 tsp of sugar` → key `teaspoon` expanded
- openai `Butter, 6 EL` → key `tablespoon` expanded
- openai `3 TL Quark zum Frühstück` → key `teaspoon` expanded
- openai `1 tbsp butter` → key `tablespoon` expanded
- openai `4 tsp of sugar` → key `teaspoon` expanded
- openai `Quark, 3 EL` → key `tablespoon` expanded

## Unit substitutions (the prompt forbids them) (0)

_none_

## Ties (a hit decided by row order — #1162) (9)

- anthropic `a slice of chicken breast` key `slice` on *Chicken breast, rotisserie, skin eaten* (2705963) → `1 small or thin slice` 30.0 g; **tie** with `1 medium slice` 60.0 g, `1 large or thick slice` 85.0 g
- anthropic `eine mittlere Hähnchenbrust` key `medium` on *Hähnchenbrust, geschmort, Haut mitgegessen* [de, machine] = *Chicken breast, stewed, skin eaten* (2705965) → `1 medium breast` 150.0 g; **tie** with `1 medium slice` 60.0 g
- anthropic `4 slices chicken breast` key `slice` on *Chicken breast, rotisserie, skin eaten* (2705963) → `1 small or thin slice` 30.0 g; **tie** with `1 medium slice` 60.0 g, `1 large or thick slice` 85.0 g
- openrouter `a slice of chicken breast` key `slice` on *Chicken breast, rotisserie, skin eaten* (2705963) → `1 small or thin slice` 30.0 g; **tie** with `1 medium slice` 60.0 g, `1 large or thick slice` 85.0 g
- openrouter `eine mittlere Hähnchenbrust` key `medium` on *Hähnchenbrust, geschmort, Haut mitgegessen* [de, machine] = *Chicken breast, stewed, skin eaten* (2705965) → `1 medium breast` 150.0 g; **tie** with `1 medium slice` 60.0 g
- openrouter `4 slices chicken breast` key `slice` on *Chicken breast, rotisserie, skin eaten* (2705963) → `1 small or thin slice` 30.0 g; **tie** with `1 medium slice` 60.0 g, `1 large or thick slice` 85.0 g
- openai `a slice of chicken breast` key `slice` on *Chicken breast, rotisserie, skin eaten* (2705963) → `1 small or thin slice` 30.0 g; **tie** with `1 medium slice` 60.0 g, `1 large or thick slice` 85.0 g
- openai `eine mittlere Hähnchenbrust` key `medium` on *Hähnchenbrust, geschmort, Haut mitgegessen* [de, machine] = *Chicken breast, stewed, skin eaten* (2705965) → `1 medium breast` 150.0 g; **tie** with `1 medium slice` 60.0 g
- openai `4 slices chicken breast` key `slice` on *Chicken breast, rotisserie, skin eaten* (2705963) → `1 small or thin slice` 30.0 g; **tie** with `1 medium slice` 60.0 g, `1 large or thick slice` 85.0 g

## False-match surface — every hit decided by row order or by an inflection, with the row it picked (#1160) (9)

- anthropic `a slice of chicken breast` key `slice` on *Chicken breast, rotisserie, skin eaten* (2705963) → `1 small or thin slice` 30.0 g; **tie** with `1 medium slice` 60.0 g, `1 large or thick slice` 85.0 g
- anthropic `eine mittlere Hähnchenbrust` key `medium` on *Hähnchenbrust, geschmort, Haut mitgegessen* [de, machine] = *Chicken breast, stewed, skin eaten* (2705965) → `1 medium breast` 150.0 g; **tie** with `1 medium slice` 60.0 g
- anthropic `4 slices chicken breast` key `slice` on *Chicken breast, rotisserie, skin eaten* (2705963) → `1 small or thin slice` 30.0 g; **tie** with `1 medium slice` 60.0 g, `1 large or thick slice` 85.0 g
- openrouter `a slice of chicken breast` key `slice` on *Chicken breast, rotisserie, skin eaten* (2705963) → `1 small or thin slice` 30.0 g; **tie** with `1 medium slice` 60.0 g, `1 large or thick slice` 85.0 g
- openrouter `eine mittlere Hähnchenbrust` key `medium` on *Hähnchenbrust, geschmort, Haut mitgegessen* [de, machine] = *Chicken breast, stewed, skin eaten* (2705965) → `1 medium breast` 150.0 g; **tie** with `1 medium slice` 60.0 g
- openrouter `4 slices chicken breast` key `slice` on *Chicken breast, rotisserie, skin eaten* (2705963) → `1 small or thin slice` 30.0 g; **tie** with `1 medium slice` 60.0 g, `1 large or thick slice` 85.0 g
- openai `a slice of chicken breast` key `slice` on *Chicken breast, rotisserie, skin eaten* (2705963) → `1 small or thin slice` 30.0 g; **tie** with `1 medium slice` 60.0 g, `1 large or thick slice` 85.0 g
- openai `eine mittlere Hähnchenbrust` key `medium` on *Hähnchenbrust, geschmort, Haut mitgegessen* [de, machine] = *Chicken breast, stewed, skin eaten* (2705965) → `1 medium breast` 150.0 g; **tie** with `1 medium slice` 60.0 g
- openai `4 slices chicken breast` key `slice` on *Chicken breast, rotisserie, skin eaten* (2705963) → `1 small or thin slice` 30.0 g; **tie** with `1 medium slice` 60.0 g, `1 large or thick slice` 85.0 g

## Key misses — a key on a resolved food that matched no row, and whether amountNeedsCheck fires (#1159) (247)

- anthropic `I had 1 slice of bacon` key `slice` on *Bacon, meatless* (172439) (0 rows: ) → **fires**
- anthropic `6 Scheiben Käse` key `slice` on *Käse-Grießnockerl* [de] = *Cheese-semolina dumplings* (10001953) (0 rows: ) → **fires**
- anthropic `a piece of salmon` key `piece` on *Salmon salad* (2706826) (1 rows: `1 cup`) → quiet: no count
- anthropic `ich hatte 5 Stück Eier` key `piece` on *Eier gekocht* [de] = *Eggs boiled* (10003161) (0 rows: ) → **fires**
- anthropic `pizza, 3 plátky` key `slice` on *Pizza, cheese, stuffed crust* (2708618) [no cs translation hit; English search] (6 rows: `1 piece, medium pizza`, `1 piece, large pizza`, `1 personal size pizza (5-7" diameter)`, `1 medium pizza (11-12" diameter)`, `1 large pizza (13-15" diameter)`, `1 surface inch`) → quiet: query words hit `1 piece, medium pizza` 100.0 g
- anthropic `ich hatte 6 Tassen Salat` key `cup` on *Griechischer Salat* [de] = *Greek salad* (10004448) (0 rows: ) → **fires**
- anthropic `I had 2 teaspoons of olive oil` key `teaspoon` on *Olive oil* (2710186) (2 rows: `1 cup`, `1 tablespoon`) → **fires**
- anthropic `5 Teelöffel Zucker` key `teaspoon` on *Zucker, braun* [de, machine] = *Sugars, brown* (168833) (0 rows: ) → **fires**
- anthropic `ein Esslöffel Zucker` key `tablespoon` on *Zucker, braun* [de, machine] = *Sugars, brown* (168833) (0 rows: ) → **fires**
- anthropic `cottage cheese, 2 tbsp` key `tablespoon` on *Cottage cheese, farmer's* (2705749) (1 rows: `1 cup`) → **fires**
- anthropic `ich hatte 4 EL Honig` key `tablespoon` on *Honig* [de] = *Honey* (10000036) (0 rows: ) → **fires**
- anthropic `ich hatte 2 TL Honig` key `teaspoon` on *Honig* [de] = *Honey* (10000036) (0 rows: ) → **fires**
- anthropic `I had 4 glasses of milk` key `glass` on *Milk, human* (2705383) (2 rows: `1 cup`, `1 fl oz`) → **fires**
- anthropic `6 Gläser Kaffee` key `glass` on *Kaffee (Getränk)* [de] = *Coffee (infusion)* (10000365) (0 rows: ) → **fires**
- anthropic `a tsp of peanut butter` key `teaspoon` on *Peanut butter* (2707537) (2 rows: `1 tablespoon`, `1 single serving`) → **fires**
- anthropic `eine Schüssel Reis` key `bowl` on *Reis Mehl* [de] = *Rice flour* (10000071) (0 rows: ) → **fires**
- anthropic `a bowl of lentil soup` key `bowl` on *Lentil soup with vegetables* (10006062) (0 rows: ) → quiet: no count
- anthropic `I had 4 handfuls of granola` key `handful` on *Granola bar, soft, milk chocolate coated, peanut butter* (168095) (0 rows: ) → **fires**
- anthropic `2 small ham sandwich` key `small` on *Ham sandwich wrap* (2706970) (1 rows: `1 sandwich, any size`) → quiet: query words hit `1 sandwich, any size` 135.0 g
- anthropic `Müsli, 3 Handvoll` key `handful` on *Müsli-Riegel* [de] = *Muesli bar* (10003929) (0 rows: ) → **fires**
- anthropic `1 kleine Pizza und Kaffee` key `small` on *Dessert-Pizza* [de, machine] = *Dessert pizza* (2708008) (3 rows: `1 piece`, `1 surface inch`, `1 pizza (12" dia)`) → quiet: query words hit `1 pizza (12" dia)` 1188.0 g
- anthropic `a large ham sandwich` key `large` on *Ham sandwich wrap* (2706970) (1 rows: `1 sandwich, any size`) → quiet: no count
- anthropic `3 medium cheddar` key `medium` on *Cheese, Cheddar* (2705709) (8 rows: `1 cracker-size slice`, `1 slice`, `1 stick`, `1 cup, shredded`, `1 cup, diced`, `1 cup, melted`, …) → **fires**
- anthropic `ein mittleres Vollkornbrot` key `medium` on *Vollkornbrot* [de] = *Wholemeal bread* (10002122) (0 rows: ) → **fires**
- anthropic `6 pieces apple` key `piece` on *Apple, dried* (2709196) (2 rows: `1 slice/chunk`, `1 cup`) → **fires**
- anthropic `a teaspoon of peanut butter` key `teaspoon` on *Peanut butter* (2707537) (2 rows: `1 tablespoon`, `1 single serving`) → **fires**
- anthropic `salmone, 3 pezzi` key `piece` on *Salmon salad* (2706826) [no it translation hit; English search] (1 rows: `1 cup`) → **fires**
- anthropic `a tbsp of sugar` key `tablespoon` on *Sugar, NFS* (2710257) (4 rows: `1 cup`, `1 teaspoon`, `1 individual packet`, `1 cube`) → **fires**
- anthropic `1 großes Rindersteak und Kaffee` key `large` on *Rindersteak gegrillt* [de] = *Beef steak grilled* (10002519) (0 rows: ) → **fires**
- anthropic `granola, 1 bowl` key `bowl` on *Granola bar, soft, milk chocolate coated, peanut butter* (168095) (0 rows: ) → **fires**
- anthropic `a glass of green tea` key `glass` on *Green tea (infusion)* (10000369) (0 rows: ) → **fires**
- anthropic `a handful of granola` key `handful` on *Granola bar, soft, milk chocolate coated, peanut butter* (168095) (0 rows: ) → quiet: no count
- anthropic `ich hatte 2 Scheiben Brot` key `slice` on *Brot, Weißbrot* [de, machine] = *Bread, white wheat* (167532) (0 rows: ) → **fires**
- anthropic `1 small eggs` key `small` on *Egg, whole, fried with oil* (2707158) (2 rows: `1 egg`, `1 cup`) → quiet: query words hit `1 egg` 55.0 g
- anthropic `5 Stück Apfel zum Frühstück` key `piece` on *Apfel roh* [de] = *Apple raw* (10000236) (0 rows: ) → **fires**
- anthropic `6 tazze di porridge` key `cup` on *Porridge, roasted, with vegetable stock and egg* (10006934) [no it translation hit; English search] (0 rows: ) → **fires**
- anthropic `3 medium toast` key `medium` on *Shrimp toast* (2706567) (2 rows: `1/2 slice`, `1 cubic inch`) → **fires**
- anthropic `5 Esslöffel Butter` key `tablespoon` on *Butter gesalzen* [de] = *Butter salted* (10003079) (0 rows: ) → **fires**
- anthropic `Olivenöl, 6 Teelöffel` key `teaspoon` on *Olivenöl* [de] = *Olive oil* (10000829) (0 rows: ) → **fires**
- anthropic `a piece of chicken breast` key `piece` on *Chicken breast, rotisserie, skin eaten* (2705963) (7 rows: `1 cup, cooked, diced`, `1 breast`, `1 small or thin slice`, `1 medium slice`, `1 large or thick slice`, `1 oz, cooked`, …) → quiet: query words hit `1 breast` 130.0 g
- anthropic `Kaffee, 6 Gläser` key `glass` on *Kaffee (Getränk)* [de] = *Coffee (infusion)* (10000365) (0 rows: ) → **fires**
- anthropic `2 EL Honig` key `tablespoon` on *Honig* [de] = *Honey* (10000036) (0 rows: ) → **fires**
- anthropic `3 TL Olivenöl zum Frühstück` key `tablespoon` on *Olivenöl* [de] = *Olive oil* (10000829) (0 rows: ) → **fires**
- anthropic `ich hatte 6 Schüsseln Nudeln` key `bowl` on *Trocken-Nudeln, angereichert* [de, machine] = *Pasta, dry, enriched* (169736) (0 rows: ) → **fires**
- anthropic `ich hatte 4 Handvoll Müsli` key `handful` on *Müsli-Riegel* [de] = *Muesli bar* (10003929) (0 rows: ) → **fires**
- anthropic `2 kleine Lachs` key `small` on *Lachs roh* [de] = *Salmon raw* (10000445) (0 rows: ) → **fires**
- anthropic `I had 1 teaspoon of olive oil` key `teaspoon` on *Olive oil* (2710186) (2 rows: `1 cup`, `1 tablespoon`) → **fires**
- anthropic `1 mittlere Pizza` key `medium` on *Dessert-Pizza* [de, machine] = *Dessert pizza* (2708008) (3 rows: `1 piece`, `1 surface inch`, `1 pizza (12" dia)`) → quiet: query words hit `1 pizza (12" dia)` 1188.0 g
- anthropic `ein großer Käse` key `large` on *Käse-Grießnockerl* [de] = *Cheese-semolina dumplings* (10001953) (0 rows: ) → quiet: no count
- anthropic `4 glasses orange juice` key `glass` on *Orange juice* (10000266) (0 rows: ) → **fires**
- anthropic `5 bowls white rice` key `bowl` on *Beans and white rice* (2708990) (1 rows: `1 cup`) → **fires**
- anthropic `1 Scheibe Avocado` key `slice` on *Avocado roh* [de] = *Avocado raw* (10000247) (0 rows: ) → **fires**
- anthropic `Orangensaft, 3 Tassen` key `cup` on *Orangensaft* [de] = *Orange juice* (10000266) (0 rows: ) → **fires**
- anthropic `almonds, 6 handfuls` key `handful` on *Almonds, NFS* (2707485) (5 rows: `1 nut`, `1 cup`, `1 package`, `1 100 calorie package`, `1 oz`) → **fires**
- anthropic `ein Stück Kuchen` key `piece` on *Kuchen, Pfirsich* [de, machine] = *Pie, peach* (175020) (0 rows: ) → **fires**
- anthropic `3 small toast` key `small` on *Shrimp toast* (2706567) (2 rows: `1/2 slice`, `1 cubic inch`) → **fires**
- anthropic `a medium dark chocolate` key `medium` on *Dark chocolate* (10000881) (0 rows: ) → quiet: no count
- anthropic `4 Esslöffel Butter zum Frühstück` key `tablespoon` on *Butter gesalzen* [de] = *Butter salted* (10003079) (0 rows: ) → **fires**
- anthropic `a large cake` key `large` on *Cake, cream* (2707872) (3 rows: `1 cupcake, any size`, `1 piece/slice, any size`, `1 cup`) → quiet: no count
- anthropic `ein Teelöffel Erdnussbutter` key `teaspoon` on *Erdnussbutter* [de, machine] = *Peanut butter* (2707537) (2 rows: `1 tablespoon`, `1 single serving`) → **fires**
- anthropic `Butter, 6 EL` key `tablespoon` on *Butter gesalzen* [de] = *Butter salted* (10003079) (0 rows: ) → **fires**
- anthropic `a piece of ham sandwich` key `piece` on *Ham sandwich wrap* (2706970) (1 rows: `1 sandwich, any size`) → quiet: query words hit `1 sandwich, any size` 135.0 g
- anthropic `3 TL Quark zum Frühstück` key `tablespoon` on *Quark-Vollkornplunder* [de] = *Wholemeal Danish pastry with quark* (10006484) (0 rows: ) → **fires**
- anthropic `4 Gläser grüner Tee` key `cup` on *Getränke, Tee, grüner Tee, trinkfertig, kalorienarm* [de, machine] = *Beverages, tea, green, ready-to-drink, diet* (171885) (0 rows: ) → **fires**
- anthropic `3 Schüsseln Nudeln` key `bowl` on *Trocken-Nudeln, angereichert* [de, machine] = *Pasta, dry, enriched* (169736) (0 rows: ) → **fires**
- anthropic `3 Handvoll Müsli` key `handful` on *Müsli-Riegel* [de] = *Muesli bar* (10003929) (0 rows: ) → **fires**
- anthropic `I had 2 teaspoons of peanut butter` key `teaspoon` on *Peanut butter* (2707537) (2 rows: `1 tablespoon`, `1 single serving`) → **fires**
- anthropic `3 kleine Wassermelone und Kaffee` key `small` on *Wassermelone roh* [de] = *Watermelon raw* (10000604) (0 rows: ) → **fires**
- anthropic `ein großer Apfel` key `large` on *Apfel roh* [de] = *Apple raw* (10000236) (0 rows: ) → **fires**
- anthropic `Vollkornbrot, 2 Scheiben` key `slice` on *Vollkornbrot* [de] = *Wholemeal bread* (10002122) (0 rows: ) → **fires**
- anthropic `6 glasses milk` key `glass` on *Milk, human* (2705383) (2 rows: `1 cup`, `1 fl oz`) → **fires**
- anthropic `3 miski spaghetti` key `bowl` on *Spaghetti, spinach, dry* (168911) [no pl translation hit; English search] (0 rows: ) → **fires**
- anthropic `Avocado, 6 Stück` key `piece` on *Avocado roh* [de] = *Avocado raw* (10000247) (0 rows: ) → **fires**
- anthropic `eine Tasse grüner Tee` key `cup` on *Getränke, Tee, grüner Tee, trinkfertig, kalorienarm* [de, machine] = *Beverages, tea, green, ready-to-drink, diet* (171885) (0 rows: ) → **fires**
- anthropic `I had 6 handfuls of almonds` key `handful` on *Almonds, NFS* (2707485) (5 rows: `1 nut`, `1 cup`, `1 package`, `1 100 calorie package`, `1 oz`) → **fires**
- anthropic `1 small bacon and coffee` key `small` on *Bacon, meatless* (172439) (0 rows: ) → **fires**
- anthropic `Zucker, 4 Teelöffel` key `teaspoon` on *Zucker, braun* [de, machine] = *Sugars, brown* (168833) (0 rows: ) → **fires**
- anthropic `6 Esslöffel Quark zum Frühstück` key `tablespoon` on *Quark-Vollkornplunder* [de] = *Wholemeal Danish pastry with quark* (10006484) (0 rows: ) → **fires**
- anthropic `1 medium dark chocolate and coffee` key `medium` on *Dark chocolate* (10000881) (0 rows: ) → **fires**
- anthropic `2 malé steak` key `small` on *Steak teriyaki* (2706387) [no sk translation hit; English search] (1 rows: `1 cup`) → **fires**
- anthropic `3 large cake and coffee` key `large` on *Cake, cream* (2707872) (3 rows: `1 cupcake, any size`, `1 piece/slice, any size`, `1 cup`) → **fires**
- anthropic `4 pieces of dark chocolate for breakfast` key `piece` on *Dark chocolate* (10000881) (0 rows: ) → **fires**
- anthropic `tuna, 6 cups` key `cup` on *Tuna raw* (10000887) (0 rows: ) → **fires**
- anthropic `Quark, 3 EL` key `tablespoon` on *Quark-Vollkornplunder* [de] = *Wholemeal Danish pastry with quark* (10006484) (0 rows: ) → **fires**
- openrouter `I had 1 slice of bacon` key `slice` on *Bacon, meatless* (172439) (0 rows: ) → **fires**
- openrouter `6 Scheiben Käse` key `slice` on *Käse-Grießnockerl* [de] = *Cheese-semolina dumplings* (10001953) (0 rows: ) → **fires**
- openrouter `ich hatte 5 Stück Eier` key `piece` on *Eier gekocht* [de] = *Eggs boiled* (10003161) (0 rows: ) → **fires**
- openrouter `a piece of salmon` key `piece` on *Salmon salad* (2706826) (1 rows: `1 cup`) → quiet: no count
- openrouter `pizza, 3 plátky` key `slice` on *Pizza, cheese, stuffed crust* (2708618) [no cs translation hit; English search] (6 rows: `1 piece, medium pizza`, `1 piece, large pizza`, `1 personal size pizza (5-7" diameter)`, `1 medium pizza (11-12" diameter)`, `1 large pizza (13-15" diameter)`, `1 surface inch`) → quiet: query words hit `1 piece, medium pizza` 100.0 g
- openrouter `ich hatte 6 Tassen Salat` key `cup` on *Griechischer Salat* [de] = *Greek salad* (10004448) (0 rows: ) → **fires**
- openrouter `I had 2 teaspoons of olive oil` key `teaspoon` on *Olive oil* (2710186) (2 rows: `1 cup`, `1 tablespoon`) → **fires**
- openrouter `5 Teelöffel Zucker` key `teaspoon` on *Zucker, braun* [de, machine] = *Sugars, brown* (168833) (0 rows: ) → **fires**
- openrouter `ein Esslöffel Zucker` key `tablespoon` on *Zucker, braun* [de, machine] = *Sugars, brown* (168833) (0 rows: ) → **fires**
- openrouter `cottage cheese, 2 tbsp` key `tablespoon` on *Cottage cheese, farmer's* (2705749) (1 rows: `1 cup`) → **fires**
- openrouter `ich hatte 2 TL Honig` key `teaspoon` on *Honig* [de] = *Honey* (10000036) (0 rows: ) → **fires**
- openrouter `ich hatte 4 EL Honig` key `tablespoon` on *Honig* [de] = *Honey* (10000036) (0 rows: ) → **fires**
- openrouter `I had 4 glasses of milk` key `glass` on *Milk, human* (2705383) (2 rows: `1 cup`, `1 fl oz`) → **fires**
- openrouter `a tsp of peanut butter` key `teaspoon` on *Peanut butter* (2707537) (2 rows: `1 tablespoon`, `1 single serving`) → **fires**
- openrouter `6 Gläser Kaffee` key `glass` on *Kaffee (Getränk)* [de] = *Coffee (infusion)* (10000365) (0 rows: ) → **fires**
- openrouter `eine Schüssel Reis` key `bowl` on *Reis Mehl* [de] = *Rice flour* (10000071) (0 rows: ) → **fires**
- openrouter `I had 4 handfuls of granola` key `handful` on *Granola bar, soft, milk chocolate coated, peanut butter* (168095) (0 rows: ) → **fires**
- openrouter `a bowl of lentil soup` key `bowl` on *Lentil soup with vegetables* (10006062) (0 rows: ) → quiet: no count
- openrouter `Müsli, 3 Handvoll` key `handful` on *Müsli-Riegel* [de] = *Muesli bar* (10003929) (0 rows: ) → **fires**
- openrouter `2 small ham sandwich` key `small` on *Ham sandwich wrap* (2706970) (1 rows: `1 sandwich, any size`) → quiet: query words hit `1 sandwich, any size` 135.0 g
- openrouter `1 kleine Pizza und Kaffee` key `small` on *Dessert-Pizza* [de, machine] = *Dessert pizza* (2708008) (3 rows: `1 piece`, `1 surface inch`, `1 pizza (12" dia)`) → quiet: query words hit `1 pizza (12" dia)` 1188.0 g
- openrouter `3 medium cheddar` key `medium` on *Cheese, Cheddar* (2705709) (8 rows: `1 cracker-size slice`, `1 slice`, `1 stick`, `1 cup, shredded`, `1 cup, diced`, `1 cup, melted`, …) → **fires**
- openrouter `ein mittleres Vollkornbrot` key `medium` on *Vollkornbrot* [de] = *Wholemeal bread* (10002122) (0 rows: ) → **fires**
- openrouter `a large ham sandwich` key `large` on *Ham sandwich wrap* (2706970) (1 rows: `1 sandwich, any size`) → quiet: no count
- openrouter `6 pieces apple` key `piece` on *Apple, dried* (2709196) (2 rows: `1 slice/chunk`, `1 cup`) → **fires**
- openrouter `salmone, 3 pezzi` key `piece` on *Salmon salad* (2706826) [no it translation hit; English search] (1 rows: `1 cup`) → **fires**
- openrouter `a teaspoon of peanut butter` key `teaspoon` on *Peanut butter* (2707537) (2 rows: `1 tablespoon`, `1 single serving`) → **fires**
- openrouter `a tbsp of sugar` key `tablespoon` on *Sugar, NFS* (2710257) (4 rows: `1 cup`, `1 teaspoon`, `1 individual packet`, `1 cube`) → **fires**
- openrouter `1 großes Rindersteak und Kaffee` key `large` on *Rindersteak gegrillt* [de] = *Beef steak grilled* (10002519) (0 rows: ) → **fires**
- openrouter `a glass of green tea` key `glass` on *Green tea (infusion)* (10000369) (0 rows: ) → **fires**
- openrouter `granola, 1 bowl` key `bowl` on *Granola bar, soft, milk chocolate coated, peanut butter* (168095) (0 rows: ) → **fires**
- openrouter `ich hatte 2 Scheiben Brot` key `slice` on *Brot, Weißbrot* [de, machine] = *Bread, white wheat* (167532) (0 rows: ) → **fires**
- openrouter `a handful of granola` key `handful` on *Granola bar, soft, milk chocolate coated, peanut butter* (168095) (0 rows: ) → quiet: no count
- openrouter `1 small eggs` key `small` on *Egg, whole, fried with oil* (2707158) (2 rows: `1 egg`, `1 cup`) → quiet: query words hit `1 egg` 55.0 g
- openrouter `5 Stück Apfel zum Frühstück` key `piece` on *Apfel roh* [de] = *Apple raw* (10000236) (0 rows: ) → **fires**
- openrouter `6 tazze di porridge` key `cup` on *Porridge, roasted, with vegetable stock and egg* (10006934) [no it translation hit; English search] (0 rows: ) → **fires**

_… 127 more in the JSON_

## Keys on lines that named no measure (7)

- anthropic `1 medium dark chocolate and coffee` item 1 `coffee` → key `medium`
- openrouter `1 medium dark chocolate and coffee` item 1 `coffee` → key `medium`
- openai `一份西兰花` item 0 `西兰花` → key `serving`
- openai `cottage cheese, 2 tbsp` item 1 `cottage cheese` → key `tablespoon`
- openai `куряче філе, 3 скибки` item 1 `скибки` → key `slice`
- openai `a piece of ham sandwich` item 1 `sandwich` → key `piece`
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
- anthropic `早餐5杯杏仁` `杏仁` → key `cup`
- anthropic `tuńczyk, 4 łyżeczki` `tuńczyk` → key `teaspoon`
- anthropic `піца, 5 шматки` `піца` → key `piece`
- anthropic `na śniadanie 3 szklanki mleko` `mleko` → key `cup`
- anthropic `arašidové maslo, 5 lyžice` `arašidové maslo` → key `tablespoon`
- anthropic `3 Tassen Milchkaffee zum Frühstück` `Milchkaffee` → key `cup`
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
- openrouter `早餐5杯杏仁` `杏仁` → key `cup`
- openrouter `tuńczyk, 4 łyżeczki` `tuńczyk` → key `teaspoon`
- openrouter `піца, 5 шматки` `піца` → key `piece`
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

## Invariant violations (1)

- openai `一份西兰花` _zh_ — unit from the list in portion key "serving"

## Disagreements with the deterministic parser (0)

_none_

## Unstable on repeat (7)

- anthropic `早餐5杯杏仁` _zh_
  - 杏仁|5.0|null|cup
  - 杏仁|5.0|null|cup
  - 杏仁|5.0|null|null
- anthropic `eine Schüssel Reis` _de_
  - Reis|1.0|null|bowl
  - Reis|1.0|null|cup
  - Reis|1.0|null|bowl
- openrouter `早餐5杯杏仁` _zh_
  - 杏仁|5.0|null|cup
  - 杏仁|5.0|null|null
  - 杏仁|5.0|null|cup
- openrouter `ein mittleres Vollkornbrot` _de_
  - Vollkornbrot|1.0|null|medium
  - Vollkornbrot|1.0|null|medium
  - Vollkornbrot|null|null|medium
- openai `4 Gläser grüner Tee` _de_
  - grüner Tee|4.0|null|null
  - grüner Tee|4.0|null|glass
  - grüner Tee|4.0|null|null
- openai `eine Schüssel Reis` _de_
  - Reis|1.0|null|null
  - Reis|1.0|null|Schüssel
  - Reis|1.0|null|bowl
- openai `піца, 5 шматки` _uk_
  - піца|5.0|null|piece
  - піца|5.0|null|piece
  - піца|5.0|null|slice

## Backend

400 read-only RPC calls for 172 distinct queries; 0 failed.

## Appendix

Every item, raw reply included, is in `portion-corpus.items.json` beside this file.
