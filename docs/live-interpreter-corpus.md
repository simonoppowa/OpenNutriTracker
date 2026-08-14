# Live interpreter corpus

1000 generated meal lines across 9 locales, model `claude-haiku-4-5`, 2026-08-14T09:13:00.985077Z.

Checked against invariants that must hold for *any* input, not per-case expectations, plus a differential against `parseMealText` and a repeat-stability sample.

## Summary

| | |
| :-- | --: |
| Lines | 1000 |
| Invariant violations | **5** |
| Call failures | 0 |
| Empty results | 29 |
| Parser disagreements | 0 |
| Unstable on repeat (of 40) | **1** |
| Latency median | 976ms |
| Latency p95 | 3387ms |
| Latency max | 9249ms |

### Units returned

- `(none)` × 1040
- `g` × 199
- `ml` × 179
- `oz` × 45
- `fl.oz` × 12
- `serving` × 3

## Invariant violations (5)

- `latte with protein shake` _en_ — nutrition word in query "protein shake"
- `akşam yemeği için protein tozu yedim` _tr_ — nutrition word in query "protein tozu"
- `süt, protein tozu, avokado` _tr_ — nutrition word in query "protein tozu"
- `semi skimmed milk and protein shake` _en_ — nutrition word in query "protein shake"
- `I had protein shake for breakfast` _en_ — nutrition word in query "protein shake"

## Disagreements with the deterministic parser (0)

_none_

## Unstable on repeat (1)

- `0.5l slanina a 1 ovsená kaša`
  - slanina|500.0|ml ~ ovsená kaša|1.0|null
  - slanina|500.0|ml ~ ovsená kaša|null|null
