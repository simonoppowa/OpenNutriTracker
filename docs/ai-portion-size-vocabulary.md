# Which portion words a model can honestly say, and how many foods carry them

Research notes gathered 2026-09-11 against the live backend — `food_portion`,
`food_portion_translation`, `food`, `food_summary`, `measure_unit` and the two
portion RPCs — read with `psql` over the connection string in `SUPABASE_DB_URL`.
`SELECT` and `\d` only; nothing was written, and no issue was edited. Written
for [#1155](https://github.com/simonoppowa/OpenNutriTracker/issues/1155) on map
[#1154](https://github.com/simonoppowa/OpenNutriTracker/issues/1154). Every
figure below cites the query that produced it, with the result appended as a
comment, the way the corrections on
[#864](https://github.com/simonoppowa/OpenNutriTracker/issues/864) did.

**The question.** #864 counted the portion vocabulary by rows. The map needs
it counted by *foods*: which of the usable `portion_description` labels are
words a model could say about a food it is reading — a size, a container, a
piece — and how many distinct foods carry at least one of each, so a prompt is
steered toward words the table can answer.

**The answer.** The vocabulary is container-heavy and size-poor, and the app
sees less of it than the table holds. Of the 5,394 foods with a usable label,
4,002 (74%) carry a container word — almost entirely `1 cup` — 1,430 (27%)
carry a size word, and 1,130 (21%) a piece word, counted first-match in the
order size, container, piece; the container and piece figures are lower
bounds (4,011 and 1,318 counting every food with such a label, see [The
classes](#the-classes)). `handful`, `plate`, `mug`,
`pint`, `quart`, `tbsp`, `tsp`, `each`, `sheet` and `unit` appear in no
`portion_description` anywhere in the table — the abbreviations exist only in
SR Legacy `modifier`, which the RPC never reads; `bowl` exists only on
ready-to-heat pastas and four branded bowls, `glass` only on twelve records
that are wine by name. Every one of the
14,449 SR Legacy rows has a `NULL` description, so the size ladders on the
generic banana, apple and egg records are invisible to the matcher, and eight
of the twelve foods the AI paths produce carry no size word at all on the
record the app receives.

## Bottom line up front

1. **`cup` is the reach; size words are a quarter of it.** `1 cup` alone sits
   on 3,056 foods; the word `cup` in any label on 3,629. `large` reaches 1,281
   foods, `small` 1,023, `medium` 859, `slice` 594, `piece` 465, `miniature`
   448, `tablespoon` 310, `container` 241, `serving` 187, `package` 184, `can`
   175, `extra large` 157, `whole` 136, `bag` 123, `pouch` 121, `bottle` 117,
   `stick` 114; every other word in the [reach table](#reach-per-word) is
   under 100.
2. **The matcher only ever sees FNDDS survey labels, bar one Foundation row.**
   All 14,449 SR Legacy rows and 186 of 187 Foundation rows have `portion_description IS NULL`; the
   household text sits in `modifier`, which `portions_by_food_ids` never reads.
   The generic *Bananas, raw* carries `1 extra small` through `1 extra large`
   and the app receives none of it. The survey *Banana, raw* — the record the
   app can see — has no size word, so `banana, large` keeps `1 banana` 126 g.
3. **Five photo words are dead on arrival.** `handful` and `plate`: zero rows.
   `bowl`: 36 foods, 32 of them `1 large microwavable bowl` on ready-to-heat
   pasta dishes, the other four branded. `glass`: twelve foods, wine by name
   (ten in FDC's *Wine* category, plus *Glug* under *Liquor and cocktails*
   and *Wine, nonalcoholic* under *Fruit drinks*). `mug`: none. *A bowl of
   rice* and *a glass of milk* are the flat default, not a route.
4. **The tie the map hypothesised does not exist; a worse one does.** No food
   carries `1 cup` beside `1 cup, cooked` (cooked rice has exactly one cup
   row). Bare `1 cup` never loses a tie. But `slice` on white bread ties five
   rows and resolves to `1 small or thin/very thin slice` (24 g), not the 28 g
   regular slice — that label is the earliest slice row on 66 yeast breads,
   and its poultry-and-meat namesake `1 small or thin slice` (28–109 g) on 57
   more — and `large` on pizza resolves to one piece, never the pie, on 63
   foods.
5. **German is fully live for the head of the vocabulary; nowhere else is.**
   All 11,588 `de` translation rows are `verified`; the other seven seeded
   locales are `machine` only. 57 of the 416 size-or-container labels are
   seeded, all verified for `de`, and they reach 4,263 of the 4,577 foods that
   carry one (93%). For any other locale the RPC returns the English label with
   `localized = false`, never an empty set.
6. **The rest — 528 labels on 3,120 foods — is mostly units and nouns.** The
   largest block outside the three classes is mechanical FDC measure (`1 fl
   oz`, `1 cubic inch`, `1 surface inch`, `1 oz, cooked`: 1,434 foods) that no
   model would say about a photo, followed by the food's own noun as the unit
   (`1 egg`, `1 sandwich`, `1 bar`, `1 chip`) and FDC's alternative size
   grades (`regular`, `thick`, `thin`, `bite size`, `personal`, `child`) on
   593 foods.

## Method

**Connection.** `psql "$SUPABASE_DB_URL"` from the shell, the variable sourced
from the gitignored `.env`. The anon key the ticket names was not needed: the
database URL reaches the same public-read tables directly. Read-only.

**Schema, confirmed with `\d` before any figure was taken.**
`food_portion(id, food_id, amount, measure_unit_id, portion_description,
modifier, seq_num, gram_weight)`;
`food_portion_translation(food_portion_id, locale, portion_description,
modifier, source, ai_generated, updated_at)` with `source` checked in
`(native, machine, community, verified)`; `measure_unit(id, name)`.

**Exclusion predicate**, applied verbatim in every query. A `food_portion` row
is *not* usable when:

```sql
portion_description IS NULL
OR btrim(portion_description) = ''
OR portion_description ILIKE '%quantity not specified%'
OR portion_description ILIKE '%NFS%'
OR portion_description ILIKE '%yields%'
OR portion_description ILIKE '%NS as to size%'
```

Usable is the negation. `ILIKE '%quantity not specified%'` also catches the two
variants *Quantity not specified, if appetizer* / *…if main course in meal*
(one row each). `ILIKE '%NFS%'` and the word-boundary form `\mNFS\M` match the
same 482 rows. *NS as to shape* (8 rows) and *NS as to form* (14 rows) are not
excluded, because the ticket names only *NS as to size*; they land in OTHER.

**The four classes**, first match wins in the order SIZE > CONTAINER > PIECE >
OTHER. Each regex is a case-insensitive POSIX expression (`~*`) with `\m` /
`\M` word boundaries, applied to the label **with parentheticals removed** —
`regexp_replace(portion_description, '\([^)]*\)', ' ', 'g')` — because that is
exactly what `_termsOf` in
[`lib/features/add_meal/util/portion_match.dart`](../lib/features/add_meal/util/portion_match.dart)
does before matching, so a word inside `( … )` is invisible to the app.

```sql
-- SIZE
\m(small|medium|large|jumbo|mini|miniature)\M
-- CONTAINER
\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M
-- PIECE
\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M
-- OTHER
.*
```

Plurals are folded into each word (`cups?`, `box(es)?`) because `_matches`
is a prefix relation with a two-letter bound: `cups` starts with `cup` and is
one letter longer, `boxes` starts with `box` and is two longer, so the matcher
treats each pair as one word. `patty|patties` is wider than the matcher —
`patties` does not start with `patty`, so the code never matches one to the
other — but no usable label contains `patties`, so the alternation changes no
count:

```sql
SELECT count(*) AS rows_with_patties FROM food_portion WHERE portion_description ~* '\mpatties\M';
-- 0
```

Word boundaries mean `cup` does not match `cupcake` and `stick` does not match
`drumstick`, and the matcher agrees on both: it tokenises on non-letters, so
`drumstick` is one token that does not start with `stick`, and `cupcake` is
four letters longer than `cup`, outside `_matches`'s two-letter bound. So `1
drumstick` (8 foods) sits in OTHER. The regexes are **not** the matcher in
general, though: `_matches` accepts any label term that starts with the token
and is at most two letters longer, and the reverse, so `bag` matches `bagel`
and `piece` matches `pie`. Emulated over the 48 single words of the reach
table, that widens six words beyond the regex reach — `bag` 123 → 167 foods
(via `bagel`), `quart` 0 → 42 (`quarter`, as in `1 breast quarter`), `piece`
465 → 495 (`pie`, `pieces`), `patty` 60 → 68 (`pat`), `slice` 594 → 601
(`sliced`), `packet` 86 → 88 (`pack`) — and the other 42 count the same
either way. `extra large` is two tokens to the matcher, not a phrase; the
token `extra` on its own hits 157 foods, the same 157 the phrase regex finds,
because every usable label containing `extra` is an extra-large one. The
per-word tables below use the regex count; read those six with the matcher's
figure beside them.

```sql
WITH usable AS (
  SELECT fp.id, fp.food_id, regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g') AS stripped
  FROM food_portion fp
  WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%')),
terms AS (
  SELECT DISTINCT u.id, u.food_id, lower(t) AS term
  FROM usable u, regexp_split_to_table(u.stripped, '[^[:alpha:]]+') AS t WHERE length(t) >= 3),
words(word, rx) AS (VALUES
 ('small','\msmall\M'),('medium','\mmedium\M'),('large','\mlarge\M'),('jumbo','\mjumbo\M'),('mini','\mmini\M'),('miniature','\mminiature\M'),
 ('cup','\mcups?\M'),('bowl','\mbowls?\M'),('glass','\mglass(es)?\M'),('tbsp','\mtbsp\M'),('tablespoon','\mtablespoons?\M'),('tsp','\mtsp\M'),('teaspoon','\mteaspoons?\M'),('handful','\mhandfuls?\M'),('scoop','\mscoops?\M'),('can','\mcans?\M'),('bottle','\mbottles?\M'),('jar','\mjars?\M'),('packet','\mpackets?\M'),('package','\mpackages?\M'),('bag','\mbags?\M'),('box','\mbox(es)?\M'),('carton','\mcartons?\M'),('container','\mcontainers?\M'),('pouch','\mpouch(es)?\M'),('mug','\mmugs?\M'),('pint','\mpints?\M'),('quart','\mquarts?\M'),('plate','\mplates?\M'),('serving','\mservings?\M'),
 ('slice','\mslices?\M'),('piece','\mpieces?\M'),('whole','\mwhole\M'),('each','\meach\M'),('stick','\msticks?\M'),('wedge','\mwedges?\M'),('sheet','\msheets?\M'),('strip','\mstrips?\M'),('chunk','\mchunks?\M'),('link','\mlinks?\M'),('patty','\m(patty|patties)\M'),('fillet','\mfillets?\M'),('leg','\mlegs?\M'),('breast','\mbreasts?\M'),('wing','\mwings?\M'),('thigh','\mthighs?\M'),('unit','\munits?\M'),('item','\mitems?\M')),
matcher AS (
  SELECT w.word, t.food_id, t.term
  FROM words w JOIN terms t ON (t.term = w.word
       OR (t.term LIKE w.word || '%' AND length(t.term) - length(w.word) <= 2)
       OR (w.word LIKE t.term || '%' AND length(w.word) - length(t.term) <= 2))),
regex AS (SELECT w.word, u.food_id FROM words w JOIN usable u ON u.stripped ~* w.rx)
SELECT w.word,
       (SELECT count(DISTINCT food_id) FROM regex r WHERE r.word = w.word) AS foods_regex,
       (SELECT count(DISTINCT food_id) FROM matcher m WHERE m.word = w.word) AS foods_matcher,
       (SELECT string_agg(DISTINCT m.term, ', ') FROM matcher m WHERE m.word = w.word AND m.term <> m.word) AS extra_terms
FROM words w
WHERE (SELECT count(DISTINCT food_id) FROM matcher m WHERE m.word = w.word) <> (SELECT count(DISTINCT food_id) FROM regex r WHERE r.word = w.word)
ORDER BY (SELECT count(DISTINCT food_id) FROM matcher m WHERE m.word = w.word) - (SELECT count(DISTINCT food_id) FROM regex r WHERE r.word = w.word) DESC, w.word;
-- bag 123|167 bagel ; quart 0|42 quarter ; piece 465|495 pie, pieces ; patty 60|68 pat ;
-- slice 594|601 sliced ; packet 86|88 pack   (six rows; the other 42 words do not differ)

-- 'extra large' as the matcher sees it: the token 'extra' alone, against the phrase regex
WITH usable AS (
  SELECT fp.id, fp.food_id, regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g') AS stripped
  FROM food_portion fp
  WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%'))
SELECT count(DISTINCT food_id) FILTER (WHERE stripped ~* '\mextra\M') AS foods_extra_token,
       count(DISTINCT food_id) FILTER (WHERE stripped ~* '\mextra[ -]large\M') AS foods_extra_large,
       count(DISTINCT food_id) FILTER (WHERE stripped ~* '\mextra\M' AND stripped !~* '\mextra[ -]large\M') AS extra_without_large
FROM usable;
-- 157 | 157 | 0
```

**The base CTE.** Every classification query below starts with this text,
written once here and referred to as `<BASE>`:

```sql
WITH usable AS (
  SELECT id, food_id, seq_num, portion_description AS label,
         regexp_replace(portion_description, '\([^)]*\)', ' ', 'g') AS matchable
  FROM food_portion
  WHERE NOT (portion_description IS NULL
          OR btrim(portion_description) = ''
          OR portion_description ILIKE '%quantity not specified%'
          OR portion_description ILIKE '%NFS%'
          OR portion_description ILIKE '%yields%'
          OR portion_description ILIKE '%NS as to size%')
), classified AS (
  SELECT *,
    CASE
      WHEN matchable ~* '\m(small|medium|large|jumbo|mini|miniature)\M' THEN 'SIZE'
      WHEN matchable ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M' THEN 'CONTAINER'
      WHEN matchable ~* '\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M' THEN 'PIECE'
      ELSE 'OTHER'
    END AS class
  FROM usable
)
```

**Stripping the parenthetical moves five labels** against matching the raw
text, 57 rows in all — worth knowing because `1 sandwich (1 slice bread)` is
the one a reader would guess wrong:

```sql
WITH usable AS (
  SELECT id, food_id, seq_num, portion_description AS label
  FROM food_portion
  WHERE NOT (portion_description IS NULL OR btrim(portion_description) = ''
          OR portion_description ILIKE '%quantity not specified%'
          OR portion_description ILIKE '%NFS%'
          OR portion_description ILIKE '%yields%'
          OR portion_description ILIKE '%NS as to size%')
), cmp AS (
  SELECT label,
    CASE WHEN label ~* '\m(small|medium|large|jumbo|mini|miniature)\M' THEN 'SIZE'
         WHEN label ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M' THEN 'CONTAINER'
         WHEN label ~* '\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M' THEN 'PIECE'
         ELSE 'OTHER' END AS raw_class,
    CASE WHEN regexp_replace(label, '\([^)]*\)', ' ', 'g') ~* '\m(small|medium|large|jumbo|mini|miniature)\M' THEN 'SIZE'
         WHEN regexp_replace(label, '\([^)]*\)', ' ', 'g') ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M' THEN 'CONTAINER'
         WHEN regexp_replace(label, '\([^)]*\)', ' ', 'g') ~* '\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M' THEN 'PIECE'
         ELSE 'OTHER' END AS stripped_class,
    count(*) AS rows
  FROM usable GROUP BY label
)
SELECT label, raw_class, stripped_class, rows FROM cmp WHERE raw_class <> stripped_class ORDER BY rows DESC;
-- '1 sandwich (1 slice bread)'                       PIECE     -> OTHER   48
-- '1 shell (jumbo)'                                  SIZE      -> OTHER    6
-- '1 slice (15 per 8 oz package)'                    CONTAINER -> PIECE    1
-- '1 roll (1/2 breast with ham and sauce)'           PIECE     -> OTHER    1
-- '1 slice (4-1/8" dia x 1/8" thick) (10 per 8 oz package)' CONTAINER -> PIECE 1
```

## Baseline

| | |
| --- | ---: |
| Rows in `food_portion` | **36,682** |
| Usable rows | **15,775** |
| Distinct usable labels | **1,083** |
| Foods with at least one usable label | **5,394** |
| Foods with any portion row | 13,044 |
| Foods in `food` | 20,834 |

```sql
SELECT count(*) AS total_rows,
       count(*) FILTER (WHERE NOT (portion_description IS NULL OR btrim(portion_description) = '' OR portion_description ILIKE '%quantity not specified%' OR portion_description ILIKE '%NFS%' OR portion_description ILIKE '%yields%' OR portion_description ILIKE '%NS as to size%')) AS usable_rows,
       count(DISTINCT portion_description) FILTER (WHERE NOT (portion_description IS NULL OR btrim(portion_description) = '' OR portion_description ILIKE '%quantity not specified%' OR portion_description ILIKE '%NFS%' OR portion_description ILIKE '%yields%' OR portion_description ILIKE '%NS as to size%')) AS distinct_usable_labels,
       count(DISTINCT food_id) FILTER (WHERE NOT (portion_description IS NULL OR btrim(portion_description) = '' OR portion_description ILIKE '%quantity not specified%' OR portion_description ILIKE '%NFS%' OR portion_description ILIKE '%yields%' OR portion_description ILIKE '%NS as to size%')) AS foods_with_usable_label
FROM food_portion;
-- 36682 | 15775 | 1083 | 5394

SELECT (SELECT count(*) FROM food) AS foods_total,
       (SELECT count(DISTINCT food_id) FROM food_portion) AS foods_with_any_portion;
-- 20834 | 13044
```

7,790 foods have no portion row. 7,140 of them are the entire BLS source,
which is most of the gap between 20,834 and 13,044; the rest are 353
Foundation, 260 SR Legacy and 37 survey records:

```sql
SELECT f.source, count(*) AS foods,
       count(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM food_portion fp WHERE fp.food_id = f.id)) AS foods_without_portion_rows
FROM food f GROUP BY 1 ORDER BY 2 DESC;
-- fdc_sr_legacy 7793|260 ; bls 7140|7140 ; fdc_survey 5432|37 ; fdc_foundation 469|353   (7,790 without rows in all)
```

**Reconciling with #864's 1,134.** That figure reproduces exactly when only
`NULL`, empty and the exact string `Quantity not specified` are excluded, and
its row count (16,721 = 45.6%) matches #864's "45% carry a usable
description":

```sql
SELECT count(DISTINCT portion_description) AS distinct_labels_864_predicate,
       count(*) AS rows_864_predicate
FROM food_portion
WHERE portion_description IS NOT NULL AND btrim(portion_description) <> ''
  AND portion_description <> 'Quantity not specified';
-- 1134 | 16721
```

The tighter predicate additionally drops 2 *Quantity not specified* variants,
17 `NFS`, 24 `yields` and 8 *NS as to size* labels — 51 = 1,134 − 1,083 — and
946 rows (16,721 − 15,775; the four row groups below are disjoint and sum to
2 + 482 + 365 + 97):

```sql
SELECT count(DISTINCT portion_description) FILTER (WHERE portion_description ILIKE '%quantity not specified%' AND portion_description <> 'Quantity not specified') AS qns_variant_labels,
       count(DISTINCT portion_description) FILTER (WHERE portion_description ILIKE '%NFS%') AS nfs_labels,
       count(DISTINCT portion_description) FILTER (WHERE portion_description ILIKE '%yields%' AND portion_description NOT ILIKE '%NFS%') AS yields_labels,
       count(DISTINCT portion_description) FILTER (WHERE portion_description ILIKE '%NS as to size%' AND portion_description NOT ILIKE '%NFS%' AND portion_description NOT ILIKE '%yields%') AS ns_size_labels,
       count(*) FILTER (WHERE portion_description IS NULL) AS null_rows,
       count(*) FILTER (WHERE portion_description ILIKE '%quantity not specified%') AS qns_rows,
       count(*) FILTER (WHERE portion_description ILIKE '%NFS%') AS nfs_rows,
       count(*) FILTER (WHERE portion_description ILIKE '%yields%') AS yields_rows,
       count(*) FILTER (WHERE portion_description ILIKE '%NS as to size%') AS ns_size_rows
FROM food_portion;
-- 2 | 17 | 24 | 8 | 14635 | 5328 | 482 | 365 | 97

SELECT count(*) AS dropped_864_to_ticket FROM food_portion
WHERE portion_description IS NOT NULL AND btrim(portion_description) <> ''
  AND portion_description <> 'Quantity not specified'
  AND (portion_description ILIKE '%quantity not specified%' OR portion_description ILIKE '%NFS%'
       OR portion_description ILIKE '%yields%' OR portion_description ILIKE '%NS as to size%');
-- 946

SELECT count(*) FILTER (WHERE portion_description ILIKE '%NFS%' AND portion_description ILIKE '%yields%') AS nfs_and_yields,
       count(*) FILTER (WHERE portion_description ILIKE '%NFS%' AND portion_description ILIKE '%NS as to size%') AS nfs_and_ns,
       count(*) FILTER (WHERE portion_description ILIKE '%yields%' AND portion_description ILIKE '%NS as to size%') AS yields_and_ns
FROM food_portion;
-- 0 | 0 | 0
```

**No food carries the same label twice**, so for any single label the
distinct-food count equals the row count. Every per-label table below therefore
shows one number per label:

```sql
SELECT count(*) AS labels_repeated_within_a_food
FROM (SELECT food_id, portion_description FROM food_portion
      WHERE portion_description IS NOT NULL GROUP BY 1, 2 HAVING count(*) > 1) d;
-- 0
```

### Where the usable rows come from

Only FNDDS survey records carry a `portion_description`, bar a single
Foundation row. Every SR Legacy row
has it `NULL` (not empty), with the household text — `large (8" to 8-7/8"
long)`, `cup, mashed`, `jumbo` — in `modifier`:

| `food.source` | Rows | Usable rows | `NULL` description |
| --- | ---: | ---: | ---: |
| survey (FNDDS) | 22,046 | 15,774 | 0 |
| sr_legacy | 14,449 | 0 | 14,449 |
| foundation | 187 | 1 | 186 |

The 14,449 SR Legacy rows belong to 7,533 foods, none of which has a usable
row; the 14,635 `NULL` rows in the table are exactly those plus the 186
Foundation ones.

```sql
SELECT f.source, count(*) AS rows,
       count(*) FILTER (WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%')) AS usable_rows,
       count(DISTINCT fp.food_id) AS foods,
       count(DISTINCT fp.food_id) FILTER (WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%')) AS foods_usable,
       count(*) FILTER (WHERE fp.portion_description IS NULL) AS is_null,
       count(*) FILTER (WHERE fp.portion_description = '') AS is_empty,
       count(*) FILTER (WHERE fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '') AS has_modifier
FROM food_portion fp JOIN food f ON f.id = fp.food_id
GROUP BY 1 ORDER BY 2 DESC;
-- source | rows | foods | foods_usable | is_null :
-- fdc_survey 22046 | 5395 | 5393 | 0 ; fdc_sr_legacy 14449 | 7533 | 0 | 14449 ; fdc_foundation 187 | 116 | 1 | 186
```

Survey rows hold the FNDDS portion code in `modifier` (e.g. `62015`) and have
`amount` `NULL`; SR Legacy rows hold the household text there. Only
`food_summary` renders the SR Legacy modifier (as `serving_size = amount || ' '
|| modifier`), which is why an SR Legacy food still shows one sensible default
in the app while offering no portion list.

### What the app actually receives

`portions_by_food_ids` — the RPC `fetchPortions` in
[`sp_food_data_source.dart`](../lib/features/add_meal/data/data_sources/sp_food_data_source.dart)
calls — reads `portion_description` only, never `modifier`, and applies its
own filter, not the ticket's predicate:

```sql
SELECT pg_get_functiondef(p.oid) FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'portions_by_food_ids';
-- keeps a row when: portion_description IS NOT NULL
--   AND portion_description <> 'Quantity not specified'      (exact string)
--   AND gram_weight IS NOT NULL AND gram_weight > 0
--   AND portion_description !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount'
```

Against the ticket's predicate that removes 336 rows across 16 labels — the
314 `Guideline amount …` rows, 8 *NS as to shape* and 14 *NS as to form* —
and admits the two *Quantity not specified, if …* rows. 15,775 usable rows by
the ticket's count; 15,441 delivered:

```sql
WITH t AS (
  SELECT fp.*,
    NOT (portion_description IS NULL OR btrim(portion_description) = '' OR portion_description ILIKE '%quantity not specified%' OR portion_description ILIKE '%NFS%' OR portion_description ILIKE '%yields%' OR portion_description ILIKE '%NS as to size%') AS task_usable,
    (portion_description IS NOT NULL AND portion_description <> 'Quantity not specified' AND gram_weight IS NOT NULL AND gram_weight > 0 AND portion_description !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount') AS rpc_usable
  FROM food_portion fp)
SELECT count(*) FILTER (WHERE task_usable) AS task_usable,
       count(*) FILTER (WHERE rpc_usable) AS rpc_usable,
       count(*) FILTER (WHERE task_usable AND NOT rpc_usable) AS task_only,
       count(*) FILTER (WHERE rpc_usable AND NOT task_usable) AS rpc_only
FROM t;
-- 15775 | 15441 | 336 | 2

-- the 336 task-only rows, by label family (same CTE):
SELECT CASE WHEN portion_description ~* '^Guideline amount' THEN 'Guideline amount …'
            WHEN portion_description ~* 'NS as to shape' THEN 'NS as to shape'
            WHEN portion_description ~* 'NS as to form' THEN 'NS as to form' ELSE 'other' END AS family,
       count(*) AS rows, count(DISTINCT portion_description) AS labels
FROM t WHERE task_usable AND NOT rpc_usable GROUP BY 1 ORDER BY 2 DESC;
-- Guideline amount … 314 | 13 ; NS as to form 14 | 2 ; NS as to shape 8 | 1   (16 labels in all)
```

Every figure in this note uses the ticket's predicate unless it says
*delivered*. Where the difference matters — the `Guideline amount` family and
the photo-word counts — both numbers are given.

## The classes

| Class | Distinct labels | Rows | Distinct foods | Share of the 5,394 |
| --- | ---: | ---: | ---: | ---: |
| SIZE | 228 | 4,193 | **1,430** | 27% |
| CONTAINER | 188 | 5,392 | **4,002** | 74% |
| PIECE | 139 | 1,500 | **1,130** | 21% |
| OTHER | 528 | 4,690 | 3,120 | 58% |
| Total | 1,083 | 15,775 | | |

```sql
<BASE>
SELECT class, count(DISTINCT label) AS distinct_labels, count(*) AS portion_rows,
       count(DISTINCT food_id) AS distinct_foods
FROM classified GROUP BY class
ORDER BY array_position(ARRAY['SIZE','CONTAINER','PIECE','OTHER'], class);
-- SIZE 228|4193|1430 ; CONTAINER 188|5392|4002 ; PIECE 139|1500|1130 ; OTHER 528|4690|3120
```

Foods overlap between classes (a food with `1 large` and `1 cup` counts in
both), so the food column does not sum to 5,394. And because each label is
classified once, first match, the CONTAINER and PIECE food counts are lower
bounds: a food whose only container label is `1 large single serving bag`, or
whose only piece label is `1 large or thick slice`, is counted under SIZE.
Counting every food with any label matching a class regex, independent of the
order, SIZE stays 1,430 (it goes first), CONTAINER is 4,011 and PIECE 1,318
(24% of 5,394):

```sql
<BASE>
SELECT count(DISTINCT food_id) FILTER (WHERE matchable ~* '\m(small|medium|large|jumbo|mini|miniature)\M') AS size_any,
       count(DISTINCT food_id) FILTER (WHERE matchable ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M') AS container_any,
       count(DISTINCT food_id) FILTER (WHERE matchable ~* '\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M') AS piece_any,
       count(DISTINCT food_id) FILTER (WHERE class = 'SIZE') AS size_first,
       count(DISTINCT food_id) FILTER (WHERE class = 'CONTAINER') AS container_first,
       count(DISTINCT food_id) FILTER (WHERE class = 'PIECE') AS piece_first
FROM classified;
-- 1430 | 4011 | 1318 | 1430 | 4002 | 1130
```

The per-class label tables and the "Share of the 5,394" column use the
first-match figures; the per-word [reach table](#reach-per-word) is
order-independent.

### Top labels per class

The first twenty rows per class of:

```sql
<BASE>
SELECT class, label, count(DISTINCT food_id) AS foods, count(*) AS rows
FROM classified GROUP BY class, label
ORDER BY array_position(ARRAY['SIZE','CONTAINER','PIECE','OTHER'], class), foods DESC, rows DESC, label;
```

**SIZE** — 228 labels, 1,430 foods

| Label | Foods |
| --- | ---: |
| 1 large | 406 |
| 1 small | 265 |
| 1 medium | 247 |
| 1 large or thick slice | 136 |
| 1 miniature/bite size | 131 |
| 1 large single serving bag | 112 |
| 1 miniature | 112 |
| 1 miniature/slider | 107 |
| 1 medium or regular slice | 88 |
| 1 small or thin/very thin slice | 88 |
| 1 medium single serving bag | 87 |
| 1 small single serving bag | 87 |
| 1 large fillet | 84 |
| 1 small/regular fillet | 84 |
| 1 medium slice | 64 |
| 1 large pizza (13-15" diameter) | 63 |
| 1 medium pizza (11-12" diameter) | 63 |
| 1 piece, large pizza | 63 |
| 1 piece, medium pizza | 63 |
| 1 extra-large pizza (16-18" diameter) | 60 |

**CONTAINER** — 188 labels, 4,002 foods (first-match, a lower bound; 4,011
order-independent)

| Label | Foods |
| --- | ---: |
| 1 cup | **3,056** |
| 1 tablespoon | 310 |
| 1 cup, cooked, diced | 147 |
| 1 cup, cooked | 107 |
| 1 cup (8 fl oz) | 103 |
| 1 100 calorie package | 100 |
| 1 individual container | 94 |
| 1 can | 72 |
| 1 pouch | 68 |
| 1 package | 58 |
| 1 packet | 53 |
| 1 jar | 45 |
| 1 cup, mashed | 44 |
| 1 prepackaged single serving | 43 |
| 1 dipping-size container | 41 |
| 1 can (12 fl oz) | 38 |
| 1 cup, diced | 36 |
| 1 cup, pieces | 36 |
| 1 bottle (16.9 fl oz or 500 ml) | 35 |
| 1 cup, shredded | 33 |

**PIECE** — 139 labels, 1,130 foods (first-match, a lower bound; 1,318
order-independent)

| Label | Foods |
| --- | ---: |
| 1 piece | 198 |
| 1 slice | 173 |
| 1 slice, crust not eaten | 85 |
| 1 slice, snack-size | 74 |
| 1 whole fish, any size | 71 |
| 1 whole | 60 |
| 1 piece/slice, any size | 56 |
| 1 item, any size | 50 |
| 1 patty | 42 |
| 1 stick | 42 |
| 1 cracker-size slice | 37 |
| 1 slice, any size | 37 |
| 1 pretzel stick | 36 |
| Guideline amount per slice of bread/roll | 34 |
| 1 piece/slice | 29 |
| 1 breast quarter (yield after cooking, bone removed) | 25 |
| 1 slice/chunk | 24 |
| 1 cut piece | 19 |
| 1 breast | 16 |
| 1 bun-size or griller link | 15 |

**OTHER** — 528 labels, 3,120 foods; the top twenty are in
[What the taxonomy misses](#what-the-taxonomy-misses).

### Reach per word

The number that decides whether a prompt may steer toward a word: how many
distinct foods have a usable label containing it, independent of the
first-match order above. Counted by the regex; the matcher's prefix rule adds
`bagel` to `bag` (167 foods, not 123), `pie` to `piece` (495) and a few to
`patty`, `slice` and `packet`, as shown in [Method](#method).

```sql
<BASE>
, words(class, word, rx) AS (VALUES
 ('SIZE','small','\msmall\M'),('SIZE','medium','\mmedium\M'),('SIZE','large','\mlarge\M'),('SIZE','extra large','\mextra[ -]large\M'),('SIZE','jumbo','\mjumbo\M'),('SIZE','mini','\mmini\M'),('SIZE','miniature','\mminiature\M'),
 ('CONTAINER','cup','\mcups?\M'),('CONTAINER','bowl','\mbowls?\M'),('CONTAINER','glass','\mglass(es)?\M'),('CONTAINER','tbsp','\mtbsp\M'),('CONTAINER','tablespoon','\mtablespoons?\M'),('CONTAINER','tsp','\mtsp\M'),('CONTAINER','teaspoon','\mteaspoons?\M'),('CONTAINER','handful','\mhandfuls?\M'),('CONTAINER','scoop','\mscoops?\M'),('CONTAINER','can','\mcans?\M'),('CONTAINER','bottle','\mbottles?\M'),('CONTAINER','jar','\mjars?\M'),('CONTAINER','packet','\mpackets?\M'),('CONTAINER','package','\mpackages?\M'),('CONTAINER','bag','\mbags?\M'),('CONTAINER','box','\mbox(es)?\M'),('CONTAINER','carton','\mcartons?\M'),('CONTAINER','container','\mcontainers?\M'),('CONTAINER','pouch','\mpouch(es)?\M'),('CONTAINER','mug','\mmugs?\M'),('CONTAINER','pint','\mpints?\M'),('CONTAINER','quart','\mquarts?\M'),('CONTAINER','plate','\mplates?\M'),('CONTAINER','serving','\mservings?\M'),
 ('PIECE','slice','\mslices?\M'),('PIECE','piece','\mpieces?\M'),('PIECE','whole','\mwhole\M'),('PIECE','each','\meach\M'),('PIECE','stick','\msticks?\M'),('PIECE','wedge','\mwedges?\M'),('PIECE','sheet','\msheets?\M'),('PIECE','strip','\mstrips?\M'),('PIECE','chunk','\mchunks?\M'),('PIECE','link','\mlinks?\M'),('PIECE','patty','\m(patty|patties)\M'),('PIECE','fillet','\mfillets?\M'),('PIECE','leg','\mlegs?\M'),('PIECE','breast','\mbreasts?\M'),('PIECE','wing','\mwings?\M'),('PIECE','thigh','\mthighs?\M'),('PIECE','unit','\munits?\M'),('PIECE','item','\mitems?\M')
)
SELECT w.class, w.word, count(DISTINCT c.label) AS labels, count(c.id) AS rows, count(DISTINCT c.food_id) AS foods
FROM words w LEFT JOIN usable c ON c.matchable ~* w.rx
GROUP BY w.class, w.word
ORDER BY array_position(ARRAY['SIZE','CONTAINER','PIECE'], w.class), foods DESC, w.word;
```

| Class | Word | Labels | Rows | Foods |
| --- | --- | ---: | ---: | ---: |
| SIZE | large | 77 | 1,636 | **1,281** |
| SIZE | small | 70 | 1,151 | **1,023** |
| SIZE | medium | 53 | 968 | **859** |
| SIZE | miniature | 22 | 448 | 448 |
| SIZE | extra large | 10 | 217 | 157 |
| SIZE | mini | 10 | 46 | 46 |
| SIZE | jumbo | 3 | 13 | 13 |
| CONTAINER | cup | 52 | 3,856 | **3,629** |
| CONTAINER | tablespoon | 1 | 310 | 310 |
| CONTAINER | container | 11 | 271 | 241 |
| CONTAINER | serving | 20 | 387 | 187 |
| CONTAINER | package | 22 | 196 | 184 |
| CONTAINER | can | 37 | 258 | 175 |
| CONTAINER | bag | 8 | 332 | 123 |
| CONTAINER | pouch | 6 | 123 | 121 |
| CONTAINER | bottle | 36 | 213 | 117 |
| CONTAINER | packet | 6 | 88 | 86 |
| CONTAINER | jar | 4 | 54 | 54 |
| CONTAINER | bowl | 4 | 36 | 36 |
| CONTAINER | scoop | 7 | 31 | 28 |
| CONTAINER | box | 13 | 42 | 27 |
| CONTAINER | teaspoon | 2 | 25 | 25 |
| CONTAINER | glass | 1 | 12 | 12 |
| CONTAINER | carton | 2 | 2 | 2 |
| CONTAINER | handful, mug, pint, plate, quart, tbsp, tsp | 0 | 0 | **0** |
| PIECE | slice | 64 | 1,186 | **594** |
| PIECE | piece | 44 | 688 | **465** |
| PIECE | whole | 7 | 138 | 136 |
| PIECE | stick | 20 | 145 | 114 |
| PIECE | fillet | 4 | 180 | 96 |
| PIECE | patty | 12 | 78 | 60 |
| PIECE | item | 3 | 58 | 58 |
| PIECE | breast | 10 | 116 | 49 |
| PIECE | thigh | 13 | 82 | 40 |
| PIECE | leg | 11 | 81 | 37 |
| PIECE | wing | 13 | 38 | 34 |
| PIECE | chunk | 3 | 30 | 30 |
| PIECE | wedge | 8 | 26 | 20 |
| PIECE | link | 5 | 42 | 18 |
| PIECE | strip | 7 | 17 | 17 |
| PIECE | each, sheet, unit | 0 | 0 | **0** |

Three things in that table bear on the prompt:

- **Ten of the ticket's words have no usable row, and no `portion_description`
  row at all**: `handful`, `mug`, `pint`, `plate`, `quart`, `tbsp`, `tsp`,
  `each`, `sheet`, `unit`. Re-run without the usable filter, across all 36,682
  rows, each is still 0. Seven of them do occur in `modifier` — `tbsp` 628
  rows, `tsp` 210, `unit` 185, `quart` 32, `each` 13, `pint` 3, `sheet` 3 —
  every one on a `NULL`-labelled SR Legacy row the RPC never reads. In the
  label column the abbreviations exist only as the long forms — `tablespoon`
  on 310 foods, `teaspoon` on 25 — and the text prompt's example list of units
  that are not in its enum, *"(tbsp, tsp, cup, slice...)"*
  ([`model_meal_text_interpreter.dart`](../lib/features/add_meal/data/model_meal_text_interpreter.dart)
  line 41), names two words the table cannot answer. One caveat from the
  prefix rule: `quart` is 0 by regex, but the matcher lands it on `quarter`
  — 42 foods: `1 breast quarter (yield after cooking, bone removed)` 25, the
  two `1 leg quarter…` labels 16, `1 quarter lb patty` 1 — see
  [Method](#method).

  ```sql
  WITH words(word, rx) AS (VALUES ('handful','\mhandfuls?\M'),('plate','\mplates?\M'),('mug','\mmugs?\M'),('pint','\mpints?\M'),('quart','\mquarts?\M'),('tbsp','\mtbsp\M'),('tsp','\mtsp\M'),('each','\meach\M'),('sheet','\msheets?\M'),('unit','\munits?\M'))
  SELECT w.word,
         count(fp.id) FILTER (WHERE fp.portion_description ~* w.rx) AS label_rows_whole_table,
         count(fp.id) FILTER (WHERE fp.modifier ~* w.rx) AS modifier_rows_whole_table,
         count(fp.id) FILTER (WHERE fp.modifier ~* w.rx AND fp.portion_description IS NULL) AS modifier_rows_null_label
  FROM words w LEFT JOIN food_portion fp ON true GROUP BY w.word ORDER BY 3 DESC, w.word;
  -- label_rows_whole_table 0 on all ten ; modifier: tbsp 628, tsp 210, unit 185, quart 32, each 13, pint 3, sheet 3,
  -- handful / mug / plate 0 ; modifier_rows_null_label = modifier_rows_whole_table on every line

  SELECT f.source, count(*) AS modifier_rows FROM food_portion fp JOIN food f ON f.id = fp.food_id
  WHERE fp.modifier ~* '\m(tbsp|tsp|units?|quarts?|each|pints?|sheets?)\M' GROUP BY 1;
  -- fdc_sr_legacy | 1074   (= 628 + 210 + 185 + 32 + 13 + 3 + 3)

  WITH usable AS (
    SELECT fp.id, fp.food_id, fp.portion_description, regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g') AS stripped
    FROM food_portion fp
    WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%'))
  SELECT portion_description, count(DISTINCT food_id) AS foods FROM usable WHERE stripped ~* '\mquarter\M' GROUP BY 1 ORDER BY 2 DESC;
  -- '1 breast quarter (yield after cooking, bone removed)' 25 ; '1 leg quarter (yield after cooking, bone removed)' 15 ;
  -- '1 leg quarter (yield after cooking, bone and skin removed)' 1 ; '1 quarter lb patty' 1
  ```
- **`mini` is not `miniature` to the matcher.** The two-letter inflection bound
  lets `mini` match `1 mini ear` and not `1 miniature` (five extra letters), so
  a model saying `mini` reaches 46 foods, not 494.
- **`bowl`, `glass`, `scoop` and `carton` are illusory.** The four bowl labels
  are `1 large microwavable bowl` (32 foods), `1 KFC Bowl` (2), `1
  Jack-in-the-Box Bowl` (1) and `1 Uncle Ben's Rice Bowl (12 oz)` (1). The one
  glass label, `1 glass`, sits on twelve records that are wine by name: ten in
  FDC's *Wine* category (wines, two sangrias, a wine cooler and a spritzer),
  plus *Glug* — mulled wine, filed under *Liquor and cocktails* — and *Wine,
  nonalcoholic*, filed under *Fruit drinks*.
  `scoop` is seven labels on 28 foods, mostly protein-powder brands.

```sql
<BASE>
SELECT label, count(*) AS rows, count(DISTINCT food_id) AS foods
FROM usable WHERE matchable ~* '\m(bowl|glass)\M' GROUP BY label ORDER BY rows DESC;
-- '1 large microwavable bowl' 32 ; '1 glass' 12 ; '1 KFC Bowl' 2 ;
-- '1 Jack-in-the-Box Bowl' 1 ; "1 Uncle Ben's Rice Bowl (12 oz)" 1

SELECT fp.portion_description, fc.description AS category, count(DISTINCT fp.food_id) AS foods
FROM food_portion fp JOIN food f ON f.id = fp.food_id LEFT JOIN food_category fc ON fc.id = f.food_category_id
WHERE regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g') ~* '\mbowls?\M'
GROUP BY 1, 2 ORDER BY 3 DESC;
-- '1 large microwavable bowl'  Pasta mixed dishes, excludes macaroni and cheese  32
--   (every one a 'Pasta … ready-to-heat' record)
-- '1 KFC Bowl'  Poultry mixed dishes  2 ; '1 Jack-in-the-Box Bowl' 1 and
-- "1 Uncle Ben's Rice Bowl (12 oz)" 1, both Stir-fry and soy-based sauce mixtures

SELECT f.id, f.description, fc.description AS category, fp.seq_num, fp.gram_weight
FROM food_portion fp JOIN food f ON f.id = fp.food_id LEFT JOIN food_category fc ON fc.id = f.food_category_id
WHERE fp.portion_description ~* '\mglass\M' ORDER BY f.description;
-- 12 rows, seq_num 2 on every one. Category 'Wine' × 10: 2710695 Sangria, red ; 2710696 Sangria, white ;
--   2710694 Wine cooler ; 2710697 Wine spritzer ; 2710692 Wine, dessert, sweet ; 2710693 Wine, light ;
--   2710688 Wine, red ; 2710690 Wine, rose ; 2710687 Wine, sparkling ; 2710689 Wine, white
-- 2710698 Glug  'Liquor and cocktails' ; 2710609 Wine, nonalcoholic  'Fruit drinks'
```

The ticket's example `1 medium (7" to 7-7/8" long)` is an SR Legacy banana
label and does not exist as a `portion_description`; the usable vocabulary is
FNDDS-style. The only dimensioned-length size labels are `1 medium (8" long)`,
`1 large (11-1/2" long)` and `1 small (5-1/2" long)`, one row each; FDC's
dimensioned variants here are pizza diameters.

### Overlap the first-match order hides

A label matching two classes is counted once above, in the earlier class. The
matcher does not care about the order: it would hit these rows from either
word.

| Overlap | Labels | Rows | Foods | Examples |
| --- | ---: | ---: | ---: | --- |
| SIZE + PIECE | 64 | 1,196 | 398 | `1 large or thick slice` 136, `1 medium or regular slice` 88, `1 small or thin/very thin slice` 88, `1 piece, large pizza` 63 |
| SIZE + CONTAINER | 18 | 419 | 182 | `1 large single serving bag` 112, `1 large microwavable bowl` 32, `1 small can` 11 |
| CONTAINER + PIECE | 1 | 36 | 36 | `1 cup, pieces` |

```sql
<BASE>
, flags AS (
  SELECT *,
    (matchable ~* '\m(small|medium|large|jumbo|mini|miniature)\M')::int AS is_size,
    (matchable ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M')::int AS is_container,
    (matchable ~* '\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M')::int AS is_piece
  FROM usable)
SELECT CASE WHEN is_size=1 AND is_container=1 THEN 'SIZE+CONTAINER'
            WHEN is_size=1 AND is_piece=1 THEN 'SIZE+PIECE'
            WHEN is_container=1 AND is_piece=1 THEN 'CONTAINER+PIECE' END AS overlap,
       count(DISTINCT label) AS labels, count(*) AS rows, count(DISTINCT food_id) AS foods
FROM flags WHERE is_size + is_container + is_piece > 1
GROUP BY 1 ORDER BY foods DESC;
-- SIZE+PIECE 64|1196|398 ; SIZE+CONTAINER 18|419|182 ; CONTAINER+PIECE 1|36|36
```

The bread family is the one that matters: a model saying `slice` on bread hits
three sized slice rows at once and the tie goes to the earliest `seq_num`. See
[Ties](#ties-the-matcher-will-hit).

## The foods the AI paths produce

For each of the twelve foods the ticket names, the survey record the app can
see, with its portion rows in `seq_num` order, class, and whether the RPC
delivers the row. The generic SR Legacy or Foundation record — what a reader
would call "the banana" — is listed beside it, because for portion purposes it
is empty: every SR Legacy row has a `NULL` description and the RPC returns
nothing for it.

Which record the AI lands on is not decided by the database.
`search_food_summary` has no `ORDER BY` — it is a full-text `WHERE` plus
`LIMIT`; ranking is client-side text overlap in
[`meal_relevance_ranker.dart`](../lib/features/add_meal/util/meal_relevance_ranker.dart).
The records below were chosen by judgment — plainest description, most rows —
not by simulating the ranker. Near-identical candidates are named per food.

```sql
SELECT pg_get_functiondef(p.oid) FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'search_food_summary';
-- LANGUAGE sql STABLE, RETURNS SETOF food_summary:
--   select fs.* from food_summary fs
--   where to_tsvector('english', fs.name) @@ websearch_to_tsquery('english', term)
--     and (sources is null or fs.source = any (sources))
--   limit greatest(max_rows, 0)
-- no ORDER BY clause
```

The rows come from one query over the chosen ids:

```sql
WITH r AS (
  SELECT fp.food_id, f.source, fp.seq_num, fp.id, fp.amount, mu.name AS unit,
         fp.portion_description, fp.modifier, fp.gram_weight,
         regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g') AS stripped,
         (fp.portion_description IS NOT NULL AND fp.portion_description <> 'Quantity not specified' AND fp.gram_weight > 0 AND fp.portion_description !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount') AS rpc_visible
  FROM food_portion fp JOIN food f ON f.id = fp.food_id JOIN measure_unit mu ON mu.id = fp.measure_unit_id
  WHERE fp.food_id IN (2709224,173944,2709215,171688,2708408,168878,2705956,171477,331960,2709789,2709792,169248,2707598,325871,2707152,171287,2705385,171265,2710375,171890,2708357,169737,2705418,171284,2707486,170567))
SELECT food_id, source, seq_num, portion_description, modifier, gram_weight, rpc_visible,
  CASE WHEN stripped ~* '\m(small|medium|large|jumbo|mini|miniature)\M' THEN 'SIZE'
       WHEN stripped ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M' THEN 'CONTAINER'
       WHEN stripped ~* '\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M' THEN 'PIECE'
       WHEN portion_description IS NULL THEN 'OTHER (label NULL; app receives nothing)'
       ELSE 'OTHER' END AS class
FROM r ORDER BY food_id, seq_num NULLS LAST, id;
```

and the flat default — the row `food_summary` picks, `ORDER BY seq_num, id
LIMIT 1` with no usability filter — from:

```sql
SELECT food_id, source, name, serving_quantity, serving_unit, serving_size, serving_gram_weight
FROM food_summary
WHERE food_id IN (2709224,173944,2709215,171688,2708408,168878,2705956,171477,2709789,2709792,169248,2707598,325871,2707152,171287,2705385,171265,2710375,171890,2708357,169737,2705418,171284,2707486,170567)
ORDER BY name;
```

In all twelve the *Quantity not specified* row sorts last, so it never becomes
the default. Rows marked *dropped* pass or fail the RPC's filter as noted; a
row marked *task-usable, dropped* passes the ticket's predicate and the RPC
still withholds it.

### Banana — `Banana, raw` (survey, 2709224)

| seq | Label | g | Class |
| ---: | --- | ---: | --- |
| 1 | 1 banana | 126 | OTHER |
| 2 | 1 slice | 6 | PIECE |
| 3 | 1 cup | 150 | CONTAINER |
| 4 | 1 cup, mashed | 225 | CONTAINER |
| 5 | 1 linear inch | 15 | OTHER |
| 6 | Quantity not specified | 126 | dropped |

No size word. `large` matches nothing and the row keeps the flat default `1
banana` 126 g. `cup` ties rows 3 and 4 on the same three-letter term and the
earlier row wins: 150 g. The other survey bananas are composites (`Banana,
baked` 2709225: `1 banana` 140 / `1 cup` 140; banana split, nectar, pudding).

The generic **`Bananas, raw` (SR Legacy, 173944)** holds the full ladder in
`modifier` — `1 cup, mashed` 225, `1 cup, sliced` 150, `1 extra small (less
than 6" long)` 81, `1 small (6" to 6-7/8" long)` 101, `1 medium (7" to 7-7/8"
long)` 118, `1 large (8" to 8-7/8" long)` 136, `1 extra large (9" or longer)`
152, `1 NLEA serving` 126 — with `portion_description` `NULL` on every row.
The app receives zero portions for it. Foundation has only *overripe* and
*ripe and slightly ripe* bananas (790774, 1105073, 790991, 1105314), one
`NULL`-labelled row each.

### Apple — `Apple, raw` (survey, 2709215)

| seq | Label | g | Class |
| ---: | --- | ---: | --- |
| 1 | 1 small | 165 | SIZE |
| 2 | 1 medium | 200 | SIZE |
| 3 | 1 large | 242 | SIZE |
| 4 | 1 extra large | 295 | SIZE |
| 5 | 1 slice | 25 | PIECE |
| 6 | 1 cup | 125 | CONTAINER |
| 7 | 1 single serving package | 34 | CONTAINER |
| 8 | Quantity not specified | 200 | dropped |

The full ladder, visible. `large` ties `1 large` (seq 3) and `1 extra large`
(seq 4) on the same five-letter term and resolves to seq 3, 242 g. The flat
default is `1 small` 165 g: an un-sized apple logs as small. The only other
survey apple is `Apple, candied` (2709294).

The generic **`Apples, raw, with skin` (SR Legacy, 171688)** carries `1 cup,
quartered or chopped` 125, `1 cup slices` 109, `1 large (3-1/4" dia)` 223, `1
medium (3" dia)` 182, `1 small (2-3/4" dia)` 149, `1 extra small (2-1/2" dia)`
101, `1 NLEA serving` 242 — all `NULL`-labelled, none delivered. The ten
Foundation per-variety apples (fuji, gala, granny smith, honeycrisp, red
delicious — two ids each) have no portion rows at all, and neither do the
three Foundation apple juice and applesauce records:

```sql
SELECT f.id, f.description,
       (SELECT count(*) FROM food_portion fp WHERE fp.food_id = f.id) AS portion_rows
FROM food f WHERE f.source = 'fdc_foundation' AND f.description ILIKE 'apple%'
ORDER BY f.description, f.id;
-- 13 rows, portion_rows = 0 on every one: 10 'Apples, <variety>, with skin, raw'
-- (1105430, 1105547, 1105664, 1105781, 1105897, 1750339, 1750340, 1750341, 1750342, 1750343),
-- 1 apple juice (2003590), 2 applesauce (2263892, 2346414)
```

### Cooked rice — `Rice, white, cooked, no added fat` (survey, 2708408)

| seq | Label | g | Class |
| ---: | --- | ---: | --- |
| 1 | 1 cup, cooked | 158 | CONTAINER |
| 2 | Quantity not specified | 118 | dropped |

One visible row. No size word, no bowl, no plate. `cup` resolves to `1 cup,
cooked` 158 g, which is also the flat default. `Rice, white, cooked, NS as to
fat` (2708403, 163 g) and `…fat added` (2708407) have the same single row;
`…as ingredient` (2710788) has none.

The generic **`Rice, white, long-grain, regular, enriched, cooked` (SR Legacy,
168878)** has one `NULL`-labelled row, `1 cup` 158 g; eight sibling SR records
differ only by grain, enrichment or parboiling and have the same single row.

### Chicken breast — `Chicken breast, baked, broiled, or roasted, skin not eaten, from raw` (survey, 2705956)

| seq | Label | g | Class |
| ---: | --- | ---: | --- |
| 1 | 1 cup, cooked, diced | 135 | CONTAINER |
| 2 | 1 small breast | 105 | SIZE |
| 3 | 1 medium breast | 120 | SIZE |
| 4 | 1 large breast | 135 | SIZE |
| 5 | 1 small or thin slice | 30 | SIZE |
| 6 | 1 medium slice | 60 | SIZE |
| 7 | 1 large or thick slice | 85 | SIZE |
| 8 | 1 oz, cooked | 28.35 | OTHER |
| 9 | 1 breast quarter (yield after cooking, bone removed) | 155 | PIECE |
| 10 | Quantity not specified | 120 | dropped |

`large` ties `1 large breast` (seq 4) and `1 large or thick slice` (seq 7) and
resolves to the breast, 135 g; `small` and `medium` likewise. With no portion
word at all, the fallback match on the query text `chicken breast` hits the
six-letter `breast` in rows 2, 3, 4 and 9 — a longer term than any size word
— and resolves to the earliest, `1 small breast` 105 g. The flat default is
`1 cup, cooked, diced` 135 g. Seven near-identical survey variants (2705955
skin eaten, 2705957/2705958 from pre-cooked, 2705961/2705962 with marinade,
2705971/2705972 sautéed) carry the same ladder at slightly different grams;
the two fast-food records (2705959/2705960) carry a bare `1 breast` in place
of the small/medium/large breast rows and keep only the slice sizes.

The generic **`Chicken, broilers or fryers, breast, meat only, cooked, roasted`
(SR Legacy, 171477)** has `1 cup, chopped or diced` 140, `1 unit (yield from 1
lb ready-to-cook chicken)` 52, `0.5 breast, bone and skin removed` 86 — all
`NULL`-labelled. Foundation `…skinless, boneless, meat only, cooked, braised`
(331960) has one row with `NULL` description **and** `NULL` modifier.

### Mixed salad — `Lettuce, raw` (survey, 2709789) and `Mixed salad greens, raw` (survey, 2709792)

`Lettuce, raw`:

| seq | Label | g | Class |
| ---: | --- | ---: | --- |
| 1 | 1 leaf | 8 | OTHER |
| 2 | 1 head | 539 | OTHER |
| 3 | 1 cup | 35 | CONTAINER |
| 4 | Guideline amount in salad | 70 | OTHER — task-usable, dropped |
| 5 | Quantity not specified | 18 | dropped |

`Mixed salad greens, raw`:

| seq | Label | g | Class |
| ---: | --- | ---: | --- |
| 1 | 1 cup | 35 | CONTAINER |
| 2 | Guideline amount in salad | 70 | OTHER — task-usable, dropped |
| 3 | Quantity not specified | 18 | dropped |

No size word, no bowl, no plate on either. Flat defaults `1 leaf` 8 g and `1
cup` 35 g. The generic **`Lettuce, iceberg (includes crisphead types), raw`
(SR Legacy, 169248)** has head and leaf each in large / medium / small — nine
rows, all `NULL`-labelled, all invisible.

### Bread — `Bread, white` (survey, 2707598)

| seq | Label | g | Class |
| ---: | --- | ---: | --- |
| 1 | 1 small or thin/very thin slice | 24 | SIZE |
| 2 | 1 medium or regular slice | 28 | SIZE |
| 3 | 1 large or thick slice | 43 | SIZE |
| 4 | 1 slice, crust not eaten | 13 | PIECE |
| 5 | 1 slice, snack-size | 10 | PIECE |
| 6 | 1 cup | 40 | CONTAINER |
| 7 | 1 cubic inch | 2.8 | OTHER |
| 8 | Quantity not specified | 28 | dropped |

**The tie the matcher hits.** `slice` matches rows 1 to 5 on the same
five-letter term; the earliest wins, so `slice` of bread is the 24 g thin
slice, not the 28 g regular one. `large`, `medium` and `small` each hit exactly
one row. The flat default is the same thin slice. `Bread, white, made from home
recipe or purchased at a bakery` (2707600) has the same ladder at 33/44/55 g.

The generic **`Bread, white, commercially prepared` (Foundation, 325871)** has
a single row — measure unit `slice`, amount 1.0, 27.3 g — with `NULL`
description and `NULL` modifier. Nothing textual exists for the matcher even
in principle.

### Egg — `Egg, whole, raw` (survey, 2707152)

| seq | Label | g | Class |
| ---: | --- | ---: | --- |
| 1 | 1 egg | 50 | OTHER |
| 2 | 1 cup | 245 | CONTAINER |
| 3 | Quantity not specified | 50 | dropped |

No size word. `large egg` matches nothing and keeps `1 egg` 50 g, which happens
to equal SR Legacy's large. `Egg, whole, boiled or poached` (2707154: `1 egg`
50 / `1 cup` 135 / `1 slice` 5) and `…cooked, NS as to cooking method`
(2707153) have the same shape.

The generic **`Egg, whole, raw, fresh` (SR Legacy, 171287)** carries the whole
ladder in `modifier`: `1 large` 50, `1 extra large` 56, `1 jumbo` 63, `1 cup
(4.86 large eggs)` 243, `1 medium` 44, `1 small` 38 (seq 4 is missing in the
source). All invisible.

### Milk — `Milk, whole` (survey, 2705385)

| seq | Label | g | Class |
| ---: | --- | ---: | --- |
| 1 | 1 cup | 244 | CONTAINER |
| 2 | 1 fl oz | 30.5 | OTHER |
| 3 | 1 individual school container | 244 | CONTAINER |
| 4 | Guideline amount per fl oz of beverage | 2.5 | OTHER — task-usable, dropped |
| 5 | Guideline amount per cup of hot cereal | 61 | CONTAINER — task-usable, dropped |
| 6 | Quantity not specified | 244 | dropped |

No glass row — the only `1 glass` rows in the table are the twelve
wine-by-name records in [Reach per word](#reach-per-word). `cup` gives
244 g, also the flat default. `Milk, reduced fat (2%)` (2705386) is identical
in shape. The generic **`Milk, whole, 3.25% milkfat, with added vitamin D`
(SR Legacy, 171265)** has `1 cup` 244, `1 fl oz` 30.5, `1 tbsp` 15, `1 quart`
976 — `NULL`-labelled.

### Coffee — `Coffee, brewed` (survey, 2710375)

| seq | Label | g | Class |
| ---: | --- | ---: | --- |
| 1 | 1 fl oz | 30 | OTHER |
| 2 | 1 cup (8 fl oz) | 240 | CONTAINER |
| 3 | 1 small | 360 | SIZE |
| 4 | 1 medium | 480 | SIZE |
| 5 | 1 large | 600 | SIZE |
| 6 | 1 small pot (20 FO, 4 servings) | 600 | SIZE |
| 7 | 1 large pot (60 FO, 12 servings) | 1,800 | SIZE |
| 8 | Quantity not specified | 360 | dropped |

A coffee-shop ladder: `small` is 12 fl oz. `large` ties `1 large` (seq 5) and
`1 large pot` (seq 7) and resolves to 600 g; `small` likewise to 360 g, not to
a cup. `1 cup (8 fl oz)` strips to `1 cup`, so `cup` gives 240 g. No mug row.
**The flat default is `1 fl oz` 30 g** — a coffee logged with no word is one
fluid ounce. `Coffee, NS as to type` (2710373) and `…NS as to brewed or
instant` (2710374) carry the identical seven visible rows. The generic
**`Beverages, coffee, brewed, prepared with tap water` (SR Legacy, 171890)**
has `1 fl oz`, `6 fl oz`, `1 cup (8 fl oz)` — `NULL`-labelled.

### Pasta — `Pasta, cooked` (survey, 2708357)

| seq | Label | g | Class |
| ---: | --- | ---: | --- |
| 1 | 1 cup, cooked | 140 | CONTAINER |
| 2 | 1 oz, dry, yields | 80 | dropped (yields) |
| 3 | Quantity not specified | 140 | dropped |

The only plain survey pasta. One visible row; `cup` gives 140 g, the flat
default. The generic **`Pasta, cooked, enriched, without added salt` (SR
Legacy, 169737)** has nine per-shape cup rows (spaghetti packed / not packed,
elbows, penne, farfalle, rotini, shells, lasagne), all `NULL`-labelled.

### Yoghurt — `Yogurt, whole milk, plain` (survey, 2705418)

| seq | Label | g | Class |
| ---: | --- | ---: | --- |
| 1 | 1 4 oz container | 113 | CONTAINER |
| 2 | 1 6 oz container | 170 | CONTAINER |
| 3 | 1 container, NFS | 170 | dropped (NFS) |
| 4 | 1 cup | 245 | CONTAINER |
| 5 | Quantity not specified | 170 | dropped |

No size word, no bowl. `container` ties rows 1 and 2 and resolves to `1 4 oz
container` 113 g, the flat default. Seven survey siblings (2705417 to 2705424;
the Greek ones say `1 5.3 oz container`) have the same three visible rows. The
generic **`Yogurt, plain, whole milk` (SR Legacy, 171284)** has 6 oz / 8 oz /
half a 4 oz container and `1 cup (8 fl oz)` — `NULL`-labelled.

### Almonds — `Almonds, unroasted` (survey, 2707486)

| seq | Label | g | Class |
| ---: | --- | ---: | --- |
| 1 | 1 nut | 1.2 | OTHER |
| 2 | 1 cup | 141 | CONTAINER |
| 3 | 1 package | 50 | CONTAINER |
| 4 | 1 100 calorie package | 18 | CONTAINER |
| 5 | 1 oz | 28.35 | OTHER |
| 15 | Quantity not specified | 28 | dropped |

No handful row — `handful` has zero rows in the whole table, see [Reach per
word](#reach-per-word) — so a photograph
of a handful keeps the flat default **`1 nut` 1.2 g**. `package` ties rows 3
and 4 and resolves to `1 package` 50 g. `Almonds, NFS` (2707485) has identical
rows; the `NFS` is in the food name, not the label, so it is not excluded. The
generic **`Nuts, almonds` (SR Legacy, 170567)** has whole / sliced / slivered
/ ground cups, `1 oz (23 whole kernels)` and `1 almond` — `NULL`-labelled.

### Summary across the twelve

| Food | Size words on the visible record | Container words | Flat default |
| --- | --- | --- | --- |
| Banana | none | cup, cup mashed | 1 banana 126 g |
| Apple | small, medium, large, extra large | cup, single serving package | 1 small 165 g |
| Rice | none | cup, cooked | 1 cup, cooked 158 g |
| Chicken breast | small, medium, large (breast and slice) | cup, cooked, diced | 1 cup, cooked, diced 135 g |
| Lettuce / salad greens | none | cup | 1 leaf 8 g / 1 cup 35 g |
| Bread | small, medium, large (as slice) | cup | thin slice 24 g |
| Egg | none | cup | 1 egg 50 g |
| Milk | none | cup, individual school container | 1 cup 244 g |
| Coffee | small, medium, large (+ pots) | cup | 1 fl oz 30 g |
| Pasta | none | cup, cooked | 1 cup, cooked 140 g |
| Yoghurt | none | 4 oz / 6 oz container, cup | 1 4 oz container 113 g |
| Almonds | none | cup, package, 100 calorie package | 1 nut 1.2 g |

Four of the twelve — apple, chicken breast, bread, coffee — carry a size word
the model could say. Eight do not, and for banana, egg and lettuce the size
ladder exists on the generic record the app cannot read.

### The words a model reaches for from a photograph

Distinct foods with a usable label containing the word, on the
parenthetical-stripped label, exact word (no plural tolerance, which is why
`piece` reads 430 here and 465 in the reach table above); and the same count
restricted to rows the RPC delivers.

| Word | Foods (ticket predicate) | Rows | Foods (RPC-delivered) | Rows |
| --- | ---: | ---: | ---: | ---: |
| cup | 3,629 | 3,856 | 3,613 | 3,814 |
| large | 1,281 | 1,636 | 1,224 | 1,579 |
| small | 1,023 | 1,151 | 1,023 | 1,151 |
| medium | 859 | 968 | 859 | 968 |
| slice | 594 | 1,186 | 560 | 1,152 |
| piece | 430 | 652 | 427 | 649 |
| bowl | 36 | 36 | 36 | 36 |
| glass | 12 | 12 | 12 | 12 |
| handful | **0** | 0 | 0 | 0 |
| plate | **0** | 0 | 0 | 0 |

```sql
WITH u AS (
  SELECT fp.food_id, fp.portion_description AS raw,
         regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g') AS stripped
  FROM food_portion fp
  WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%')),
w(word) AS (VALUES ('large'),('medium'),('small'),('bowl'),('plate'),('handful'),('glass'),('cup'),('slice'),('piece'))
SELECT w.word,
       count(DISTINCT u.food_id) FILTER (WHERE u.stripped ~* ('\m' || w.word || '\M')) AS foods_stripped,
       count(u.*) FILTER (WHERE u.stripped ~* ('\m' || w.word || '\M')) AS rows_stripped,
       count(DISTINCT u.food_id) FILTER (WHERE u.raw ~* ('\m' || w.word || '\M')) AS foods_raw,
       count(DISTINCT u.food_id) FILTER (WHERE u.stripped ~* ('\m' || w.word || '(s|es)?\M')) AS foods_plural_ok
FROM w LEFT JOIN u ON true GROUP BY w.word ORDER BY foods_stripped DESC;

-- the same, restricted to rows the RPC delivers:
WITH u AS (
  SELECT fp.food_id, regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g') AS stripped
  FROM food_portion fp
  WHERE fp.portion_description IS NOT NULL AND fp.portion_description <> 'Quantity not specified'
    AND fp.gram_weight > 0
    AND fp.portion_description !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount'),
w(word) AS (VALUES ('large'),('medium'),('small'),('bowl'),('plate'),('handful'),('glass'),('cup'),('slice'),('piece'))
SELECT w.word, count(DISTINCT u.food_id) FILTER (WHERE u.stripped ~* ('\m' || w.word || '\M')) AS foods_rpc_visible,
       count(u.*) FILTER (WHERE u.stripped ~* ('\m' || w.word || '\M')) AS rows_rpc_visible
FROM w LEFT JOIN u ON true GROUP BY w.word ORDER BY 2 DESC;
-- cup 3613/3814, large 1224/1579, small 1023/1151, medium 859/968, slice 560/1152,
-- piece 427/649, bowl 36/36, glass 12/12, handful 0, plate 0
```

The difference between the two `large` and `slice` columns is the `Guideline
amount on large sandwich` / `…per slice of bread/roll` rows, which pass the
ticket's predicate and the RPC drops. On the raw label `slice` reads 642 foods
rather than 594: the extra 48 are `1 sandwich (1 slice bread)`, where the word
sits inside the parenthetical the matcher strips.

```sql
WITH u AS (
  SELECT fp.food_id, fp.portion_description AS raw,
         regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g') AS stripped
  FROM food_portion fp
  WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%'))
SELECT raw, count(*) AS rows FROM u
WHERE raw ~* '\mslice\M' AND stripped !~* '\mslice\M'
GROUP BY raw ORDER BY rows DESC;
-- '1 sandwich (1 slice bread)' 48
```

## Ties the matcher will hit

`matchPortionToQuery` scores a portion by the length of the longest label
term a query token matched, and on equal scores the earlier portion wins. A
tie is therefore any food with two or more usable labels sharing a term.

**The pair the map hypothesised does not exist.** No food carries `1 cup`
together with `1 cup, cooked…`; cooked rice and pasta have exactly one cup row
each, so `cup` on them is not a tie:

```sql
SELECT count(DISTINCT a.food_id) AS foods_with_1cup_and_1cup_cooked
FROM food_portion a JOIN food_portion b ON a.food_id = b.food_id
WHERE a.portion_description ILIKE '1 cup' AND b.portion_description ILIKE '1 cup, cooked%';
-- 0
```

`1 cup, cooked` exists on 107 rows and `1 cup, cooked, diced` on 147, never
together with each other or with a bare `1 cup`.

### Counted the way the matcher matches

The matcher matches a token against **any** term of a label, not only the
first, so the faithful count groups labels by every term of three or more
letters they contain. 1,533 foods carry a tie on some term; per taxonomy word:

| Term | Foods with two or more labels carrying it |
| --- | ---: |
| slice | **232** |
| large | **226** |
| cup | 165 |
| small | 123 |
| serving | 113 |
| medium | 104 |
| piece | 85 |
| bottle | 52 |
| can | 42 |
| stick | 12 |
| scoop | 3 |
| whole | 1 |
| bowl, glass, handful, plate, tbsp, tsp, each | 0 |

```sql
WITH usable AS (
  SELECT fp.id, fp.food_id, fp.seq_num, fp.portion_description,
         regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g') AS stripped
  FROM food_portion fp
  WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%')),
terms AS (
  SELECT DISTINCT u.id, u.food_id, u.seq_num, lower(t) AS term
  FROM usable u, regexp_split_to_table(u.stripped, '[^[:alpha:]]+') AS t
  WHERE length(t) >= 3),
groups AS (SELECT food_id, term, count(*) AS n FROM terms GROUP BY 1, 2 HAVING count(*) >= 2)
SELECT (SELECT count(DISTINCT food_id) FROM groups) AS foods_with_any_term_tie, term, count(*) AS foods
FROM groups
WHERE term IN ('cup','slice','piece','large','small','medium','serving','bottle','can','stick','scoop','whole','bowl','glass','handful','plate','tbsp','tsp','each')
GROUP BY term ORDER BY foods DESC;
-- 1533 ; slice 232, large 226, cup 165, small 123, serving 113, medium 104, piece 85,
-- bottle 52, can 42, stick 12, scoop 3, whole 1
```

Grouping on the **leading** word only — what the ticket's wording suggests —
undercounts: 806 foods, of which 155 tie on `fl` (from `1 fl oz`) and 45 on
`oz`, tokens under the matcher's three-letter minimum that it can never hit:

```sql
-- the `usable` CTE below with '[[:alpha:]]+' in place of '[[:alpha:]]{3,}'
SELECT (SELECT count(DISTINCT food_id) FROM groups) AS foods_with_any_tie,
       count(*) FILTER (WHERE word = 'fl') AS fl_foods,
       count(*) FILTER (WHERE word = 'oz') AS oz_foods
FROM groups;
-- 806 | 155 | 45
```

Restricted to three-letter tokens the leading-word count is 680 foods, and 823
usable rows (`1 fl oz`, `1 oz`) contain no matchable term at all:

```sql
WITH usable AS (
  SELECT fp.id, fp.food_id, fp.seq_num, fp.portion_description,
         lower((regexp_match(regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g'), '[[:alpha:]]{3,}'))[1]) AS lead
  FROM food_portion fp
  WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%')),
groups AS (SELECT food_id, lead AS word, count(*) AS n FROM usable WHERE lead IS NOT NULL GROUP BY 1, 2 HAVING count(*) >= 2)
SELECT (SELECT count(DISTINCT food_id) FROM groups) AS foods_with_any_tie,
       (SELECT count(*) FROM usable WHERE lead IS NULL) AS usable_rows_with_no_matchable_term,
       word, count(*) AS foods
FROM groups GROUP BY word ORDER BY foods DESC, word LIMIT 15;
-- 680 ; 823 ; guideline 107, cup 83, slice 80, regular 79, piece 73, large 70, small 49,
-- medium 41, bottle 34, container 30, can 27, sandwich 23, frozen 13, surface 12, ring 10
```

### Cup

Bare `1 cup` never loses. Under the any-term rule 165 foods carry two or more
cup-bearing labels; in 110 the earliest is the bare `1 cup`, in 55 there is no
bare row at all, and in none does a bare `1 cup` sit later than a qualified
one:

```sql
WITH usable AS (
  SELECT fp.id, fp.food_id, fp.seq_num, fp.portion_description,
         regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g') AS stripped
  FROM food_portion fp
  WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%')),
terms AS (
  SELECT DISTINCT u.id, u.food_id, u.seq_num, lower(t) AS term
  FROM usable u, regexp_split_to_table(u.stripped, '[^[:alpha:]]+') AS t WHERE length(t) >= 3),
cupfoods AS (SELECT food_id FROM terms WHERE term = 'cup' GROUP BY 1 HAVING count(*) >= 2),
ranked AS (
  SELECT t.food_id, u.portion_description, row_number() OVER (PARTITION BY t.food_id ORDER BY t.seq_num) AS rn
  FROM terms t JOIN cupfoods c USING (food_id) JOIN usable u ON u.id = t.id WHERE t.term = 'cup')
SELECT count(DISTINCT food_id) AS foods_with_2plus_cup_term_labels,
       count(*) FILTER (WHERE rn = 1 AND portion_description ILIKE '1 cup') AS bare_cup_first,
       count(*) FILTER (WHERE rn = 1 AND portion_description NOT ILIKE '1 cup') AS other_first,
       count(*) FILTER (WHERE rn > 1 AND portion_description ILIKE '1 cup') AS bare_cup_present_but_later
FROM ranked;
-- 165 | 110 | 55 | 0
```

On the leading word alone it is 83 foods — 38 bare-first, 45 qualified-first,
0 bare-but-later — and the earliest cup row across those 83 is `1 cup` 38, `1
cup, shredded` 20, `1 cup, diced` 9, `1 cup, pieces` 4, then `1 cup, bite size`,
`1 cup, boneless` and `1 cup, dry type` at 2 each, then six singletons. The
extra 82 foods under the any-term rule come from `1 microwavable cup` (32),
`Guideline amount per cup of hot cereal` (25), an ice-cream-cup trio (14),
`1 Keurig cup` / `1 microwave cup, prepared` on ten oatmeals, and `Guideline
amount per cup of french fries` on one:

```sql
WITH usable AS (
  SELECT fp.id, fp.food_id, fp.seq_num, fp.portion_description,
         regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g') AS stripped,
         lower((regexp_match(regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g'), '[[:alpha:]]{3,}'))[1]) AS lead
  FROM food_portion fp
  WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%')),
terms AS (
  SELECT DISTINCT u.id, u.food_id, u.seq_num, u.portion_description, lower(t) AS term
  FROM usable u, regexp_split_to_table(u.stripped, '[^[:alpha:]]+') AS t WHERE length(t) >= 3),
any_term AS (SELECT food_id FROM terms WHERE term = 'cup' GROUP BY 1 HAVING count(*) >= 2),
leadword AS (SELECT food_id FROM usable WHERE lead = 'cup' GROUP BY 1 HAVING count(*) >= 2),
extra AS (SELECT food_id FROM any_term EXCEPT SELECT food_id FROM leadword)
SELECT (SELECT count(*) FROM extra) AS extra_foods, t.portion_description, count(DISTINCT t.food_id) AS foods
FROM terms t JOIN extra USING (food_id)
WHERE t.term = 'cup' AND t.portion_description NOT ILIKE '1 cup%'
GROUP BY 2 ORDER BY foods DESC, 2;
-- 82 ; '1 microwavable cup' 32, 'Guideline amount per cup of hot cereal' 25,
-- '1 large / medium / small ice cream cup' 14 each, '1 Keurig cup' 10,
-- '1 microwave cup, prepared' 10, 'Guideline amount per cup of french fries' 1
```

The real cup ties are (i) `1 cup` beside a mashed cup on 35 fruit and
vegetable foods — `1 cup, mashed` on 34 (*Carrots* 17, *Other vegetables and
combinations* 13, one each of banana, mango, starchy and red/orange
vegetables) plus Avocado's `1 cup, mashed or pureed` — where
the bare row is always earlier and wins; the other three bare-first foods pair
`1 cup` with `1 cup, melted` (*Cheese, NFS*), `1 cup, diced` (*Cheese spread*)
and `1 cup ice` (*Water, tap*); and (ii) the 45 foods with no bare row, where
`cup` resolves to whatever the earliest cup row says. On 30 of them that is
shredded, diced or melted cheese — `1 cup, shredded` 20, `1 cup, diced` 9,
`1 cup, melted` 1, all in the *Cheese* category — so `cup` is a shredded cup
whatever was on the plate. The other 15 are `1 cup, sliced` on one more
cheese, `1 cup, dry type` on two cottage/ricotta records, and twelve
non-cheese foods (`1 cup, pieces` 4, `1 cup, bite size` 2, `1 cup, boneless`
2, four singletons).

```sql
WITH usable AS (
  SELECT fp.id, fp.food_id, fp.seq_num, fp.portion_description,
         lower((regexp_match(regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g'), '[[:alpha:]]{3,}'))[1]) AS lead
  FROM food_portion fp
  WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%')),
cupfoods AS (SELECT food_id FROM usable WHERE lead = 'cup' GROUP BY 1 HAVING count(*) >= 2),
ranked AS (
  SELECT u.food_id, u.portion_description, row_number() OVER (PARTITION BY u.food_id ORDER BY u.seq_num) AS rn
  FROM usable u JOIN cupfoods c USING (food_id) WHERE u.lead = 'cup'),
bare AS (SELECT food_id FROM ranked WHERE rn = 1 AND portion_description ILIKE '1 cup')
SELECT (SELECT count(*) FROM bare) AS bare_cup_first, r.portion_description, count(DISTINCT r.food_id) AS foods,
       string_agg(DISTINCT f.id || ' ' || f.description, '; ') FILTER (WHERE r.portion_description <> '1 cup, mashed') AS foods_named
FROM ranked r JOIN bare b USING (food_id) JOIN food f ON f.id = r.food_id
WHERE r.rn > 1 GROUP BY 2 ORDER BY foods DESC;
-- 38 ; '1 cup, mashed' 34 ; '1 cup ice' 1 (2710707 Water, tap) ;
-- '1 cup, diced' 1 (2705773 Cheese spread, American or Cheddar cheese base) ;
-- '1 cup, mashed or pureed' 1 (2709223 Avocado, raw) ; '1 cup, melted' 1 (2705704 Cheese, NFS)

-- the same CTEs, the mashed labels by food category:
SELECT r.portion_description, fc.description AS category, count(DISTINCT r.food_id) AS foods
FROM ranked r JOIN bare b USING (food_id) JOIN food f ON f.id = r.food_id LEFT JOIN food_category fc ON fc.id = f.food_category_id
WHERE r.rn > 1 AND r.portion_description ILIKE '1 cup, mashed%' GROUP BY 1, 2 ORDER BY 1, 3 DESC;
-- '1 cup, mashed': Carrots 17, Other vegetables and combinations 13, Bananas 1, Other starchy vegetables 1,
--   Other red and orange vegetables 1, Mango and papaya 1 ; '1 cup, mashed or pureed': Other vegetables and combinations 1

-- the 45 qualified-first foods, by their earliest cup label:
WITH usable AS (
  SELECT fp.id, fp.food_id, fp.seq_num, fp.portion_description,
         lower((regexp_match(regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g'), '[[:alpha:]]{3,}'))[1]) AS lead
  FROM food_portion fp
  WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%')),
cupfoods AS (SELECT food_id FROM usable WHERE lead = 'cup' GROUP BY 1 HAVING count(*) >= 2),
ranked AS (
  SELECT u.food_id, u.portion_description, row_number() OVER (PARTITION BY u.food_id ORDER BY u.seq_num) AS rn
  FROM usable u JOIN cupfoods c USING (food_id) WHERE u.lead = 'cup'),
qual AS (SELECT food_id, portion_description FROM ranked WHERE rn = 1 AND portion_description NOT ILIKE '1 cup')
SELECT q.portion_description AS earliest_cup_label, count(*) AS foods,
       count(*) FILTER (WHERE f.description ILIKE '%cheese%') AS cheese_in_name,
       string_agg(DISTINCT fc.description, '; ') AS categories
FROM qual q JOIN food f ON f.id = q.food_id LEFT JOIN food_category fc ON fc.id = f.food_category_id
GROUP BY 1 ORDER BY 2 DESC, 1;
-- '1 cup, shredded' 20 (20 cheese in name; Cheese) ; '1 cup, diced' 9 (8; Cheese) ; '1 cup, pieces' 4 (0; Other red and
--   orange vegetables; Soy and meat-alternative products) ; '1 cup, bite size' 2 (0; Crackers, excludes saltines) ;
--   '1 cup, boneless' 2 (0; Meat mixed dishes; Poultry mixed dishes) ; '1 cup, dry type' 2 (2; Cottage/ricotta cheese) ;
--   '1 cup, beef flavor' 1 ; '1 cup, canned' 1 ; '1 cup, coarse grain' 1 ; '1 cup, melted' 1 (1; Cheese) ;
--   '1 cup, sliced' 1 (1; Cheese) ; '1 cup, with bone (yield after bone removed)' 1
-- 45 foods in all; 32 have 'cheese' in the food name, 33 are in a cheese category, 30 have shredded / diced / melted first
```

### Examples, with the grams at stake

```sql
SELECT f.id, f.description,
       string_agg(fp.seq_num || ':' || coalesce(fp.portion_description, '<null>') || '=' || fp.gram_weight || 'g', ' | ' ORDER BY fp.seq_num) AS rows
FROM food f JOIN food_portion fp ON fp.food_id = f.id
WHERE f.id IN (2707598, 2705709, 2709224, 2708387, 2705957, 2708614, 2709215)
GROUP BY f.id, f.description ORDER BY f.description;
```

- **Bread, white (2707598)** — `slice` ties `1 small or thin/very thin slice`
  24 g, `1 medium or regular slice` 28 g, `1 large or thick slice` 43 g, `1
  slice, crust not eaten` 13 g, `1 slice, snack-size` 10 g, and picks the
  first: 24 g. That label is the earliest `slice` row on 66 foods, all in the
  *Yeast breads* category at 9–33 g (26 of them exactly 24 g). The
  similarly-worded `1 small or thin slice` is earliest on 57 more, but those
  are poultry and meat — *Chicken, whole pieces* 29, *Turkey, duck, other
  poultry* 17, *Meat mixed dishes* 9, *Poultry mixed dishes* 2 — at 28–109 g,
  not breads.
- **Chicken breast, from pre-cooked, skin eaten (2705957)** — `large` ties `1
  large breast` 145 g and `1 large or thick slice` 85 g and resolves to the
  whole breast; 21 chicken-breast foods share this. The tie goes the right way
  only because FDC lists the breast before the slice.
- **Pizza, cheese, restaurant, NS as to crust (2708614)** — `large` ties `1
  piece, large pizza` 119 g (seq 4) and `1 large pizza (13-15" diameter)` 954
  g (seq 9) and resolves to the single piece; earliest `large` row on 63 pizza
  foods. The same food has `1 piece, NFS` at seq 1, which the RPC withholds.
- **Cheese, Cheddar (2705709)** — `1 cup, shredded` 113 g, `1 cup, diced` 132
  g, `1 cup, melted` 244 g, `1 cup, cubed` 132 g, no bare cup; `cup` is
  shredded.
- **Oatmeal, instant, plain (2708387)** — `1 cup, cooked` 240 g, `1 Keurig
  cup` 170 g, `1 microwave cup, prepared` 210 g; all carry `cup`, seq 1 wins.
- **Banana (2709224)** and **Apple (2709215)** — `1 cup` beats `1 cup,
  mashed`; `1 large` beats `1 extra large`. Benign.

The 66 / 57 / 21 / 63 figures are the earliest row, in `seq_num` order, among
the labels that tie on a term, grouped by which label comes first:

```sql
WITH usable AS (
  SELECT fp.id, fp.food_id, fp.seq_num, fp.portion_description, fp.gram_weight,
         regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g') AS stripped
  FROM food_portion fp
  WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%')),
terms AS (
  SELECT DISTINCT u.id, u.food_id, u.seq_num, u.portion_description, u.gram_weight, lower(t) AS term
  FROM usable u, regexp_split_to_table(u.stripped, '[^[:alpha:]]+') AS t WHERE length(t) >= 3),
tied AS (SELECT food_id, term FROM terms GROUP BY 1, 2 HAVING count(*) >= 2),
earliest AS (
  SELECT t.food_id, t.term, t.portion_description, t.gram_weight,
         row_number() OVER (PARTITION BY t.food_id, t.term ORDER BY t.seq_num, t.id) AS rn
  FROM terms t JOIN tied USING (food_id, term))
SELECT e.term, e.portion_description, count(*) AS foods,
       min(e.gram_weight) AS min_g, max(e.gram_weight) AS max_g
FROM earliest e
WHERE e.rn = 1 AND e.term IN ('slice', 'large', 'breast')
GROUP BY 1, 2 ORDER BY 1, 3 DESC, 2;
-- slice : '1 small or thin/very thin slice' 66 (9–33 g) ; '1 small or thin slice' 57 (28–109 g) ;
--         '1 cracker-size slice' 37 ; '1 large or thick slice' 11 ; ...
-- large : '1 piece, large pizza' 63 (75–173 g) ; '1 large drink' 49 ; '1 large breast' 21 (135–195 g) ; ...
-- breast: '1 small breast' 21 (105–150 g) ; '1 breast' 8

-- the same CTEs, the two thin-slice labels by food category:
SELECT e.portion_description, fc.description AS category, count(*) AS foods,
       min(e.gram_weight) AS min_g, max(e.gram_weight) AS max_g,
       count(*) FILTER (WHERE e.gram_weight = 24) AS at_24g
FROM earliest e JOIN food f ON f.id = e.food_id LEFT JOIN food_category fc ON fc.id = f.food_category_id
WHERE e.rn = 1 AND e.term = 'slice'
  AND e.portion_description IN ('1 small or thin/very thin slice', '1 small or thin slice')
GROUP BY 1, 2 ORDER BY 1, 3 DESC;
-- '1 small or thin slice'           Chicken, whole pieces 29 (30 g) ; Turkey, duck, other poultry 17 (28–30 g) ;
--                                   Meat mixed dishes 9 (86–109 g) ; Poultry mixed dishes 2 (86–109 g)   -- none at 24 g
-- '1 small or thin/very thin slice' Yeast breads 66 (9–33 g, 26 of them 24 g)
```

Two quirks a reader of `portion_match.dart` should know. The score is the
**label** term's length, so a query `cup` against a label containing `cups`
scores 4 and beats a `cup` row regardless of `seq_num`; no food carries both
today, and the only singular/plural coexistence among the taxonomy words is
`piece` / `pieces` on three foods. On two of them (the *Graham crackers*
records) both words sit in the one label, so no cross-row quirk arises; on
the third, *Chicken, meatless, breaded, fried*, `1 cup, pieces` is already
the earlier row, so the score and the order agree:

```sql
WITH usable AS (
  SELECT fp.id, fp.food_id, fp.seq_num, fp.portion_description,
         regexp_replace(fp.portion_description, '\([^)]*\)', ' ', 'g') AS stripped
  FROM food_portion fp
  WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%')),
terms AS (
  SELECT DISTINCT u.id, u.food_id, lower(t) AS term
  FROM usable u, regexp_split_to_table(u.stripped, '[^[:alpha:]]+') AS t WHERE length(t) >= 3),
pairs(sing, plur) AS (VALUES ('cup','cups'),('piece','pieces'),('slice','slices'),('stick','sticks'),('strip','strips'),('can','cans'),('bag','bags'),('box','boxes'),('bottle','bottles'),('jar','jars'),('packet','packets'),('package','packages'),('pouch','pouches'),('serving','servings'),('wedge','wedges'),('chunk','chunks'),('link','links'),('fillet','fillets'),('leg','legs'),('breast','breasts'),('wing','wings'),('thigh','thighs'),('item','items'),('scoop','scoops'),('container','containers'),('tablespoon','tablespoons'),('teaspoon','teaspoons'))
SELECT p.sing, p.plur, count(DISTINCT s.food_id) AS foods_with_both, string_agg(DISTINCT s.food_id::text, ',') AS food_ids
FROM pairs p JOIN terms s ON s.term = p.sing JOIN terms q ON q.term = p.plur AND q.food_id = s.food_id
GROUP BY 1, 2 ORDER BY 3 DESC;
-- piece | pieces | 3 | 2707469,2708133,2708138   (the only pair returned)

SELECT f.id, f.description, string_agg(fp.seq_num || ':' || fp.portion_description, ' | ' ORDER BY fp.seq_num) AS piece_rows
FROM food f JOIN food_portion fp ON fp.food_id = f.id
WHERE f.id IN (2707469, 2708133, 2708138) AND fp.portion_description ~* '\mpieces?\M' GROUP BY 1, 2;
-- 2707469 Chicken, meatless, breaded, fried   1:1 cup, pieces | 2:1 piece
-- 2708133 Graham crackers                     1 large rectangular piece or 2 squares or 4 small rectangular pieces
-- 2708138 Graham crackers, reduced fat        (the same single label)
```

`portion_match` breaks a tie on *list position*, not on `seq_num` — but the
list the app receives is the RPC's, and `portions_by_food_ids` ends
`order by fp.food_id, fp.seq_num nulls last, fp.id` (read with
`pg_get_functiondef`). `seq_num` is never `NULL` and unique per food across
usable rows, so "earlier in the list" and "earlier `seq_num`" are the same
thing and the ordering behind every tie above is unambiguous:

```sql
SELECT count(*) AS rows_total, count(*) FILTER (WHERE seq_num IS NULL) AS seq_null,
       (SELECT count(*) FROM (SELECT food_id, seq_num FROM food_portion GROUP BY 1, 2 HAVING count(*) > 1) d) AS dup_food_seq_pairs
FROM food_portion;
-- 36682 | 0 | 2   (both duplicates are NULL-labelled rows on foods 323444 and 746766)
```

## Translation reach

`food_portion_translation` is keyed `(food_portion_id, locale)`, not by label,
so "seeded" means a distinct English `portion_description` whose rows have a
translation. 11,588 portion rows × 8 locales = 92,704 rows, all
`ai_generated = true`:

```sql
SELECT count(*) AS rows, count(DISTINCT food_portion_id) AS distinct_portions, count(DISTINCT locale) AS locales
FROM food_portion_translation;
-- 92704 | 11588 | 8
```

### Verified rows by locale

| Locale | `verified` | `machine` |
| --- | ---: | ---: |
| cs | 0 | 11,588 |
| **de** | **11,588** | 0 |
| it | 0 | 11,588 |
| pl | 0 | 11,588 |
| sk | 0 | 11,588 |
| tr | 0 | 11,588 |
| uk | 0 | 11,588 |
| zh | 0 | 11,588 |

```sql
SELECT locale,
       count(*) FILTER (WHERE source = 'verified') AS verified,
       count(*) FILTER (WHERE source = 'machine') AS machine,
       count(*) FILTER (WHERE source NOT IN ('verified','machine')) AS other
FROM food_portion_translation GROUP BY locale ORDER BY locale;
```

`de` is fully verified, not partially: every seeded row is verified for German,
so "seeded" and "verified for de" are the same set for every label. The app
ships nine locales (`lib/l10n/intl_*.arb`: cs, de, en, it, pl, sk, tr, uk,
zh); the eight seeded are all but `en`.

### Seeded labels

109 distinct English labels, all usable under the ticket's predicate, present
in all eight locales; by class SIZE 32, CONTAINER 25, PIECE 14, OTHER 38:

```sql
SELECT count(DISTINCT fp.portion_description) AS seeded_distinct_labels,
       count(DISTINCT fp.portion_description) FILTER (WHERE fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%') AS seeded_not_usable
FROM food_portion fp
WHERE EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = fp.id);
-- 109 | 0

<BASE>
SELECT class, count(DISTINCT label) AS seeded_labels
FROM classified c
WHERE EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = c.id)
GROUP BY class ORDER BY class;
-- CONTAINER 25 ; OTHER 38 ; PIECE 14 ; SIZE 32
```

### Size and container reach, seeded versus not

| | Labels | Rows | Foods |
| --- | ---: | ---: | ---: |
| SIZE ∪ CONTAINER, all usable | 416 | 9,585 | 4,577 |
| …seeded (= verified `de`) | **57** | 7,662 | **4,263** (93%) |
| SIZE, all / verified `de` | 228 / 32 | 4,193 / — | 1,430 / 1,032 |
| CONTAINER, all / verified `de` | 188 / 25 | 5,392 / — | 4,002 / 3,786 |
| Whole usable vocabulary, all / seeded | 1,083 / 109 | 15,775 / 11,588 | 5,394 / 4,949 |

The first two rows are the union of the SIZE and CONTAINER regexes,
order-independent. The per-class rows are first-match, so the CONTAINER food
figures are lower bounds (4,011 order-independent, see [The
classes](#the-classes)).

```sql
WITH usable AS (
  SELECT fp.* FROM food_portion fp
  WHERE NOT (fp.portion_description IS NULL OR btrim(fp.portion_description) = '' OR fp.portion_description ILIKE '%quantity not specified%' OR fp.portion_description ILIKE '%NFS%' OR fp.portion_description ILIKE '%yields%' OR fp.portion_description ILIKE '%NS as to size%')),
sc AS (
  SELECT u.*,
    EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = u.id) AS seeded,
    EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = u.id AND t.locale = 'de' AND t.source = 'verified') AS verified_de
  FROM usable u
  WHERE regexp_replace(u.portion_description, '\([^)]*\)', ' ', 'g') ~* '\m(small|medium|large|jumbo|mini|miniature)\M'
     OR regexp_replace(u.portion_description, '\([^)]*\)', ' ', 'g') ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M')
SELECT count(DISTINCT portion_description) AS sc_labels_total,
       count(DISTINCT portion_description) FILTER (WHERE seeded) AS sc_labels_seeded,
       count(DISTINCT portion_description) FILTER (WHERE verified_de) AS sc_labels_verified_de,
       count(DISTINCT food_id) AS sc_foods_total,
       count(DISTINCT food_id) FILTER (WHERE seeded) AS sc_foods_seeded,
       count(DISTINCT food_id) FILTER (WHERE verified_de) AS sc_foods_verified_de,
       count(*) AS sc_rows, count(*) FILTER (WHERE verified_de) AS sc_rows_verified_de
FROM sc;
-- 416 | 57 | 57 | 4577 | 4263 | 4263 | 9585 | 7662
```

The per-class split, and the whole-vocabulary line, come from the same CTE
grouped by class with `ROLLUP`:

```sql
<BASE>
, flagged AS (
  SELECT c.*,
    EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = c.id) AS seeded,
    EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = c.id AND t.locale = 'de' AND t.source = 'verified') AS verified_de
  FROM classified c)
SELECT class,
       count(DISTINCT label) AS labels_total, count(DISTINCT label) FILTER (WHERE seeded) AS labels_seeded,
       count(*) AS rows, count(*) FILTER (WHERE seeded) AS rows_seeded,
       count(DISTINCT food_id) AS foods, count(DISTINCT food_id) FILTER (WHERE verified_de) AS foods_verified_de
FROM flagged GROUP BY ROLLUP(class) ORDER BY class NULLS LAST;
-- SIZE 228/32, 1430 foods / 1032 ; CONTAINER 188/25, 4002 / 3786 ; total 1083/109, 15775/11588, 5394/4949
```

**The 57 seeded size and container labels**, every one verified for `de`
(the `verified_de` flag was `true` on all 57 rows of the query, and
`rows_seeded = portion_rows` for each, so coverage per label is complete, not
sampled):

```sql
<BASE>
SELECT c.class, c.label, count(*) AS portion_rows,
       count(*) FILTER (WHERE EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = c.id)) AS rows_seeded,
       count(DISTINCT c.food_id) AS foods,
       bool_or(EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = c.id AND t.locale = 'de' AND t.source = 'verified')) AS verified_de
FROM classified c
WHERE c.class IN ('SIZE','CONTAINER')
  AND EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = c.id)
GROUP BY c.class, c.label ORDER BY c.class, portion_rows DESC, label;
-- 57 rows; rows_seeded = portion_rows = foods and verified_de = t on every one. portion_rows per label:
-- CONTAINER (25): '1 cup' 3056, '1 tablespoon' 310, '1 cup, cooked, diced' 147, '1 cup, cooked' 107, '1 cup (8 fl oz)' 103,
--   '1 100 calorie package' 100, '1 individual container' 94, '1 can' 72, '1 pouch' 68, '1 package' 58, '1 packet' 53,
--   '1 jar' 45, '1 cup, mashed' 44, '1 prepackaged single serving' 43, '1 dipping-size container' 41, '1 can (12 fl oz)' 38,
--   '1 cup, diced' 36, '1 cup, pieces' 36, '1 bottle (16.9 fl oz or 500 ml)' 35, '1 cup, shredded' 33, '1 microwavable cup' 32,
--   '1 pouch/regular size' 31, '1 6 oz container' 30, '1 snack size container' 30, '1 bottle (20 fl oz)' 28
-- SIZE (32): '1 large' 406, '1 small' 265, '1 medium' 247, '1 large or thick slice' 136, '1 miniature/bite size' 131,
--   '1 large single serving bag' 112, '1 miniature' 112, '1 miniature/slider' 107, '1 medium or regular slice' 88,
--   '1 small or thin/very thin slice' 88, '1 medium single serving bag' 87, '1 small single serving bag' 87,
--   '1 large fillet' 84, '1 small/regular fillet' 84, '1 medium slice' 64, '1 large pizza (13-15" diameter)' 63,
--   '1 medium pizza (11-12" diameter)' 63, '1 piece, large pizza' 63, '1 piece, medium pizza' 63,
--   '1 extra-large pizza (16-18" diameter)' 60, '1 piece, extra-large pizza' 60, '1 piece, small pizza' 60,
--   '1 small pizza (8-10" diameter)' 60, '1 small or thin slice' 57, '1 extra large drink' 49, '1 large drink' 49,
--   '1 medium drink' 49, '1 small drink' 49, '1 large sandwich' 45, '1 small/regular' 41, '1 large microwavable bowl' 32,
--   '1 large/king size' 31
```

SIZE (32): `1 large`, `1 small`, `1 medium`, `1 large or thick slice`, `1
miniature/bite size`, `1 large single serving bag`, `1 miniature`, `1
miniature/slider`, `1 medium or regular slice`, `1 small or thin/very thin
slice`, `1 medium single serving bag`, `1 small single serving bag`, `1 large
fillet`, `1 small/regular fillet`, `1 medium slice`, `1 large pizza (13-15"
diameter)`, `1 medium pizza (11-12" diameter)`, `1 piece, large pizza`, `1
piece, medium pizza`, `1 extra-large pizza (16-18" diameter)`, `1 piece,
extra-large pizza`, `1 piece, small pizza`, `1 small pizza (8-10" diameter)`,
`1 small or thin slice`, `1 extra large drink`, `1 large drink`, `1 medium
drink`, `1 small drink`, `1 large sandwich`, `1 small/regular`, `1 large
microwavable bowl`, `1 large/king size`.

CONTAINER (25): `1 cup`, `1 tablespoon`, `1 cup, cooked, diced`, `1 cup,
cooked`, `1 cup (8 fl oz)`, `1 100 calorie package`, `1 individual container`,
`1 can`, `1 pouch`, `1 package`, `1 packet`, `1 jar`, `1 cup, mashed`, `1
prepackaged single serving`, `1 dipping-size container`, `1 can (12 fl oz)`,
`1 cup, diced`, `1 cup, pieces`, `1 bottle (16.9 fl oz or 500 ml)`, `1 cup,
shredded`, `1 microwavable cup`, `1 pouch/regular size`, `1 6 oz container`,
`1 snack size container`, `1 bottle (20 fl oz)`.

Nothing with `bowl` (other than the microwavable one), `plate`, `handful`,
`glass` or `tsp` is seeded, because nothing usable carries those words.

**The gap** is a long tail: 359 size-or-container labels are unseeded, but
they hold 1,923 rows and only **314 foods** reachable solely through an
unseeded label. The top of the unseeded ranking, by rows: `Guideline amount
on large sandwich` (57 — and the RPC drops it anyway), `1 large slice`, `1
small or medium single serving bag` and `Guideline amount per cup of hot
cereal` (25 each), `1 individual school container` (24), `1 cup, nuggets` and
`1 medium/regular` (23 each), `1 cup, melted` and `1 scoop` (22 each), `1
individual packet` and `1 large` / `medium` / `small breast` (21 each), then
`1 bottle (12 fl oz)` and `1 can or bottle (12 fl oz)` (20 each):

```sql
<BASE>
SELECT class, label, count(*) AS rows, count(DISTINCT food_id) AS foods
FROM classified c
WHERE class IN ('SIZE','CONTAINER')
  AND NOT EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = c.id)
GROUP BY 1, 2 ORDER BY rows DESC, label LIMIT 15;
-- SIZE 'Guideline amount on large sandwich' 57 ; SIZE '1 large slice' 25 ; SIZE '1 small or medium single serving bag' 25 ;
-- CONTAINER 'Guideline amount per cup of hot cereal' 25 ; CONTAINER '1 individual school container' 24 ;
-- CONTAINER '1 cup, nuggets' 23 ; SIZE '1 medium/regular' 23 ; CONTAINER '1 cup, melted' 22 ; CONTAINER '1 scoop' 22 ;
-- CONTAINER '1 individual packet' 21 ; SIZE '1 large breast' 21 ; SIZE '1 medium breast' 21 ; SIZE '1 small breast' 21 ;
-- CONTAINER '1 bottle (12 fl oz)' 20 ; CONTAINER '1 can or bottle (12 fl oz)' 20   (rows = foods on every line)
```

### What the German words are

One distinct `de` string per English label:

```sql
<BASE>
SELECT c.class, c.label, count(DISTINCT t.portion_description) AS distinct_de,
       string_agg(DISTINCT t.portion_description, ' || ') AS de_labels
FROM classified c JOIN food_portion_translation t ON t.food_portion_id = c.id AND t.locale = 'de' AND t.source = 'verified'
WHERE c.class IN ('SIZE','CONTAINER')
GROUP BY c.class, c.label ORDER BY c.class, c.label;
-- 57 rows, distinct_de = 1 on every one. CONTAINER:
-- '1 100 calorie package' → '1 100-Kalorien-Packung' ; '1 6 oz container' → '1 Becher mit 6 Unzen' ;
-- '1 bottle (16.9 fl oz or 500 ml)' → '1 Flasche (16,9 Flüssigunzen oder 500 ml)' ; '1 bottle (20 fl oz)' → '1 Flasche (20 Flüssigunzen)' ;
-- '1 can' → '1 Dose' ; '1 can (12 fl oz)' → '1 Dose (12 Flüssigunzen)' ; '1 cup' → '1 Tasse' ; '1 cup (8 fl oz)' → '1 Tasse (8 Flüssigunzen)' ;
-- '1 cup, cooked' → '1 Tasse, gegart' ; '1 cup, cooked, diced' → '1 Tasse, gegart, gewürfelt' ; '1 cup, diced' → '1 Tasse, gewürfelt' ;
-- '1 cup, mashed' → '1 Tasse, gestampft' ; '1 cup, pieces' → '1 Tasse, Stücke' ; '1 cup, shredded' → '1 Tasse, gerieben' ;
-- '1 dipping-size container' → '1 Dip-Becher' ; '1 individual container' → '1 Einzelbehälter' ; '1 jar' → '1 Glas' ;
-- '1 microwavable cup' → '1 Mikrowellenbecher' ; '1 package' → '1 Packung' ; '1 packet' → '1 Päckchen' ; '1 pouch' → '1 Beutel' ;
-- '1 pouch/regular size' → '1 Beutel/normale Größe' ; '1 prepackaged single serving' → '1 abgepackte Einzelportion' ;
-- '1 snack size container' → '1 Snackbecher' ; '1 tablespoon' → '1 Esslöffel'
-- SIZE:
-- '1 extra large drink' → '1 sehr großes Getränk' ; '1 extra-large pizza (16-18" diameter)' → '1 sehr große Pizza (16-18" Durchmesser)' ;
-- '1 large' → '1 groß' ; '1 large drink' → '1 großes Getränk' ; '1 large fillet' → '1 großes Filet' ;
-- '1 large microwavable bowl' → '1 große Mikrowellenschüssel' ; '1 large or thick slice' → '1 große oder dicke Scheibe' ;
-- '1 large pizza (13-15" diameter)' → '1 große Pizza (13-15" Durchmesser)' ; '1 large sandwich' → '1 großes Sandwich' ;
-- '1 large single serving bag' → '1 große Einzelportionstüte' ; '1 large/king size' → '1 groß/King Size' ;
-- '1 medium' → '1 mittel' ; '1 medium drink' → '1 mittleres Getränk' ; '1 medium or regular slice' → '1 mittlere oder normale Scheibe' ;
-- '1 medium pizza (11-12" diameter)' → '1 mittlere Pizza (11-12" Durchmesser)' ; '1 medium single serving bag' → '1 mittlere Einzelportionstüte' ;
-- '1 medium slice' → '1 mittlere Scheibe' ; '1 miniature' → '1 Mini' ; '1 miniature/bite size' → '1 Mini-/Häppchengröße' ;
-- '1 miniature/slider' → '1 Mini/Slider' ; '1 piece, extra-large pizza' → '1 Stück, sehr große Pizza' ;
-- '1 piece, large pizza' → '1 Stück, große Pizza' ; '1 piece, medium pizza' → '1 Stück, mittlere Pizza' ;
-- '1 piece, small pizza' → '1 Stück, kleine Pizza' ; '1 small' → '1 klein' ; '1 small drink' → '1 kleines Getränk' ;
-- '1 small or thin slice' → '1 kleine oder dünne Scheibe' ; '1 small or thin/very thin slice' → '1 kleine oder dünne/sehr dünne Scheibe' ;
-- '1 small pizza (8-10" diameter)' → '1 kleine Pizza (8-10" Durchmesser)' ; '1 small single serving bag' → '1 kleine Einzelportionstüte' ;
-- '1 small/regular' → '1 kleine/normale Portion' ; '1 small/regular fillet' → '1 kleines/normales Filet'
```

Facts that matter to a German model word meeting the two-letter inflection
bound. `_words` splits on `[^\p{L}]+`, so `ß`, `ö` and `ü` are letters, and a
hyphen or slash is a break:

- `1 large` → `1 groß`, `1 small` → `1 klein`, `1 medium` → `1 mittel`. The
  inflected forms in longer labels — `große` / `großes` (`1 große oder dicke
  Scheibe`, `1 großes Getränk`) and `kleine` / `kleines` — sit within two
  letters of the base and match. **`mittlere` does not start with `mittel`**
  (mitt-l-ere), so `mittel` cannot match `1 mittlere Scheibe`, `1 mittleres
  Getränk` or `1 mittlere Pizza…`, and `mittlere` cannot match `1 mittel`;
  `1 medium` is the only label whose German contains `mittel`.
- `cup` is `Tasse` on all nine `1 cup…` labels and `Mikrowellenbecher` on `1
  microwavable cup`; `container` is `Becher` on `1 6 oz container` (`1 Becher
  mit 6 Unzen`), `Dip-Becher` on `1 dipping-size container`, `Snackbecher` on
  `1 snack size container` and `Einzelbehälter` on `1 individual container`.
  To the matcher `Mikrowellenbecher`, `Snackbecher` and `Einzelbehälter` are
  single tokens that a model's `Becher` cannot reach; `Dip-Becher` splits on
  the hyphen and can.
- `1 jar` → `1 Glas`, the same word a German speaker uses for a drinking glass.
  `Glas` from a model would land on jar rows.
- `1 miniature` → `1 Mini`, and `Mini-/Häppchengröße` / `Mini/Slider` split so
  that `mini` is a token of its own on those two as well; `1 tablespoon` → `1
  Esslöffel`; `extra large` → `sehr groß…`.

### What the RPC does for an unverified locale

`portions_by_food_ids(ids, loc)` `LEFT JOIN`s `food_portion_translation` on
`locale = loc AND source = 'verified'` and non-blank, and selects
`coalesce(t.portion_description, fp.portion_description) AS label,
(t.portion_description IS NOT NULL) AS localized`. For any locale with no
verified row — the seven machine-only locales, `en`, and an unknown locale
such as `fr` — it returns the **English** `food_portion.portion_description`
with `localized = false`. Never an empty set; never the machine translation.

```sql
SELECT pg_get_functiondef(p.oid) FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname IN ('portions_by_food_ids', 'portion_labels_by_food_ids') AND n.nspname = 'public';

SELECT 'de' AS loc, * FROM portions_by_food_ids(ARRAY[2705508]::bigint[], 'de')
UNION ALL SELECT 'it', * FROM portions_by_food_ids(ARRAY[2705508]::bigint[], 'it')
UNION ALL SELECT 'en', * FROM portions_by_food_ids(ARRAY[2705508]::bigint[], 'en')
UNION ALL SELECT 'fr', * FROM portions_by_food_ids(ARRAY[2705508]::bigint[], 'fr')
ORDER BY 1, 3;
-- de: '1 klein' / '1 mittel' / '1 groß' / '1 Flüssigunze' / '1 Tasse'   localized = t
-- it, en, fr: '1 small' / '1 medium' / '1 large' / '1 fl oz' / '1 cup'   localized = f
```

The sibling `portion_labels_by_food_ids` (one label per food, first by
`seq_num`) does an **inner** join on verified rows and therefore returns
nothing for an unverified locale (`de` → `1 klein`; `it` and `en` → zero
rows). It is not on the matcher's path.

None of the 16 labels the RPC drops against the ticket's predicate is seeded,
so the 57 / 4,263 figures are the same as the app sees them.

## What the taxonomy misses

OTHER is 528 labels, 4,690 rows, 3,120 foods: 49% of usable labels, 30% of
usable rows, and it touches 58% of the 5,394 foods that have any usable
label. It is long-tailed — 267 labels carry one food, 365 carry three or fewer
— and every OTHER label appears at most once per food:

```sql
<BASE>
SELECT count(*) FILTER (WHERE foods = 1) AS one_food_labels,
       count(*) FILTER (WHERE foods <= 3) AS le3_food_labels,
       count(*) FILTER (WHERE rows <> foods) AS labels_with_repeat_rows
FROM (SELECT label, count(DISTINCT food_id) AS foods, count(*) AS rows
      FROM classified WHERE class = 'OTHER' GROUP BY label) t;
-- 267 | 365 | 0
```

### The top of OTHER

```sql
<BASE>
SELECT label, count(DISTINCT food_id) AS foods, count(*) AS rows
FROM classified WHERE class = 'OTHER'
GROUP BY label ORDER BY foods DESC, rows DESC, label LIMIT 40;
```

| Label | Foods | | Label | Foods |
| --- | ---: | --- | --- | ---: |
| 1 fl oz | 464 | | 1 submarine | 43 |
| 1 cubic inch | 374 | | 1 oz | 39 |
| 1 surface inch | 166 | | 1 tub | 39 |
| 1 fl oz (no ice) | 165 | | 1 cracker | 38 |
| 1 oz, cooked | 165 | | 1 Spaghettio's snack size microwavable tray | 32 |
| 1 fl oz (with ice) | 155 | | 1 nut | 32 |
| 1 regular | 153 | | 1 regular sandwich | 32 |
| 1 egg | 109 | | 1 steak | 31 |
| 1 sandwich | 75 | | 1 fun/snack size | 30 |
| 1 personal size pizza (5-7" diameter) | 72 | | 1 sharing/movie theater size | 30 |
| Guideline amount per fl oz of beverage | 72 | | 1 French bread | 29 |
| 1 drink | 70 | | 1 baby potato | 29 |
| Guideline amount on regular sandwich | 68 | | 1 new potato | 29 |
| 1 regular or 6" submarine | 60 | | 1/2 English muffin | 29 |
| 1 bar | 59 | | 1/2 bagel | 29 |
| 1 chip | 57 | | 1 spear | 28 |
| 1 child/senior drink | 49 | | 1 fruit | 26 |
| 1 sandwich (1 slice bread) | 48 | | 1 individual pie | 26 |
| 1 sandwich, any size | 46 | | 1 kernel | 26 |
| | | | 1 thick / 1 thin | 26 each |

The first seven are mechanical FDC units, not words anyone says about a
plate. Where they attach:

```sql
<BASE>
SELECT fc.description AS category, count(DISTINCT c.food_id) AS foods
FROM classified c JOIN food f ON f.id = c.food_id LEFT JOIN food_category fc ON fc.id = f.food_category_id
WHERE c.label = '1 regular' GROUP BY 1 ORDER BY 2 DESC LIMIT 5;
-- and the same for '1 fl oz', '1 cubic inch', '1 surface inch', '1 oz, cooked', '1 egg'
-- '1 fl oz'        Coffee 109, Liquor and cocktails 58, Formula prepared from powder 50, Smoothies and grain drinks 25
-- '1 cubic inch'   Fish 96, Cheese 49, Yeast breads 34, Beef 28, Cakes and pies 27
-- '1 surface inch' Pizza 84, Pancakes/waffles/French toast 32, Cakes and pies 22
-- '1 oz, cooked'   Chicken, whole pieces 128, Sausages 12, Oatmeal 10, Bacon 8
-- '1 regular'      Deli/cured meat sandwiches 43, Egg/breakfast sandwiches 38, Beef 20, Bagels 14
-- '1 egg'          Eggs and omelets 109
```

### Classes large enough to matter

Each regex counted independently within OTHER (they overlap, so they do not
sum):

| Sub-class | Regex (case-insensitive, on the stripped label) | Labels | Rows | Foods |
| --- | --- | ---: | ---: | ---: |
| SIZE_EXT — FDC's other size grades | `\m(regular\|thick\|thin\|personal\|child\|senior\|kids?\|footlong\|foot long\|fun\|sharing\|king size\|tiny\|individual\|baby\|snack size\|bite size\|movie theater)\M` | 42 | 856 | **661** |
| VOLUME_UNIT | `\m(fl oz\|fluid ounces?\|ml\|millilit(er\|re)s?\|lit(er\|re)s?\|shots?\|jiggers?\|drops?)\M` | 8 | 888 | 659 |
| DIMENSION | `\m(cubic\|surface\|linear\|square) inch(es)?\M\|\d-inch\M` | 9 | 570 | 558 |
| BAKED_SNACK — self-named baked unit | `\m(cookies?\|crackers?\|chips?\|bars?\|muffins?\|waffles?\|pancakes?\|doughnuts?\|donuts?\|cupcakes?\|cakes?\|pies?\|biscuits?\|pastr(y\|ies)\|tarts?\|rolls?\|buns?\|bagels?\|loaf\|loaves\|toast\|wafers?\|pretzels?\|croissants?\|crepes?)\M` | 129 | 627 | 473 |
| SANDWICH_BURGER | `\m(sandwich(es)?\|submarines?\|hamburgers?\|cheeseburgers?\|chiliburgers?\|burgers?(?! king)\|hot dogs?\|frankfurters?\|Big Mac\|Grand Mac\|Mac Jr)\M` | 27 | 477 | 398 |
| PRODUCE_UNIT — one natural item | `\m(fruits?\|berry\|berries\|cherry\|cherries\|grapes?\|potato(es)?\|carrots?\|floweret\|florets?\|spears?\|beans?\|peas?\|corn\|kernels?\|nuts?\|leaf\|leaves\|head\|cloves?\|stalks?\|sprigs?\|pods?\|olives?\|apples?\|bananas?\|mango(es)?\|apricots?\|figs?\|dates?\|prunes?\|raisins?\|lychee\|tamarind\|peppers?\|tomato(es)?\|onions?\|bulb\|sprouts?)\M` | 53 | 365 | 307 |
| COOKING_STATE — a qualifier, not a noun | `\m(cooked\|raw\|dry\|boneless\|skinless\|prepared\|frozen\|without shell\|skin only\|yield after cooking\|with sauce\|with gravy\|with filling\|stuffed)\M` | 34 | 319 | 296 |
| WEIGHT_UNIT | `(?<!fl )\m(oz\|ounces?\|lbs?\|pounds?\|grams?\|g\|kg)\M` | 10 | 289 | 275 |
| MEAL_ORDER | `\m(meals?\|dinners?\|entrees?\|orders?\|menu\|salads?\|pizzas?)\M` | 61 | 212 | 174 |
| GUIDELINE_RATE | `^(Guideline amount\|Topping per\|Juice of)\M` | 12 | 193 | 173 |
| DRINK | `\m(drinks?\|sodas?\|milkshakes?\|snow cone\|sundaes?\|banana split\|parfait)\M` | 8 | 132 | 132 |
| EGG | `\m(eggs?\|egg whites?)\M` | 3 | 131 | 131 |
| ANY_SIZE | `\many (size\|cut)\M` | 15 | 126 | 126 |
| DISH_UNIT — sandwich + baked + egg + drink + meal merged | the union of those regexes | 222 | 1,555 | 1,241 |

(The `\|` in the table is a Markdown escape; the regexes use a plain `|`.)

```sql
<BASE>
SELECT v.name, count(DISTINCT label) AS distinct_labels, count(*) AS rows, count(DISTINCT food_id) AS distinct_foods
FROM classified, LATERAL (VALUES
  ('VOLUME_UNIT', '\m(fl oz|fluid ounces?|ml|millilit(er|re)s?|lit(er|re)s?|shots?|jiggers?|drops?)\M'),
  ('SIZE_EXT', '\m(regular|thick|thin|personal|child|senior|kids?|footlong|foot long|fun|sharing|king size|tiny|individual|baby|snack size|bite size|movie theater)\M'),
  ('DIMENSION', '\m(cubic|surface|linear|square) inch(es)?\M|\d-inch\M'),
  ('BAKED_SNACK', '\m(cookies?|crackers?|chips?|bars?|muffins?|waffles?|pancakes?|doughnuts?|donuts?|cupcakes?|cakes?|pies?|biscuits?|pastr(y|ies)|tarts?|rolls?|buns?|bagels?|loaf|loaves|toast|wafers?|pretzels?|croissants?|crepes?)\M'),
  ('SANDWICH_BURGER', '\m(sandwich(es)?|submarines?|hamburgers?|cheeseburgers?|chiliburgers?|burgers?(?! king)|hot dogs?|frankfurters?|Big Mac|Grand Mac|Mac Jr)\M'),
  ('PRODUCE_UNIT', '\m(fruits?|berry|berries|cherry|cherries|grapes?|potato(es)?|carrots?|floweret|florets?|spears?|beans?|peas?|corn|kernels?|nuts?|leaf|leaves|head|cloves?|stalks?|sprigs?|pods?|olives?|apples?|bananas?|mango(es)?|apricots?|figs?|dates?|prunes?|raisins?|lychee|tamarind|peppers?|tomato(es)?|onions?|bulb|sprouts?)\M'),
  ('COOKING_STATE', '\m(cooked|raw|dry|boneless|skinless|prepared|frozen|without shell|skin only|yield after cooking|with sauce|with gravy|with filling|stuffed)\M'),
  ('WEIGHT_UNIT', '(?<!fl )\m(oz|ounces?|lbs?|pounds?|grams?|g|kg)\M'),
  ('GUIDELINE_RATE', '^(Guideline amount|Topping per|Juice of)\M'),
  ('MEAL_ORDER', '\m(meals?|dinners?|entrees?|orders?|menu|salads?|pizzas?)\M'),
  ('DRINK', '\m(drinks?|sodas?|milkshakes?|snow cone|sundaes?|banana split|parfait)\M'),
  ('EGG', '\m(eggs?|egg whites?)\M'),
  ('ANY_SIZE', '\many (size|cut)\M')) AS v(name, rx)
WHERE class = 'OTHER' AND matchable ~* v.rx
GROUP BY v.name ORDER BY distinct_foods DESC;
```

Cut as an **ordered, exclusive partition** (GUIDELINE_RATE > VOLUME_UNIT >
WEIGHT_UNIT > DIMENSION > SIZE_EXT > ANY_SIZE > SANDWICH_BURGER > BAKED_SNACK
> PRODUCE_UNIT > EGG > DRINK > MEAL_ORDER > RESIDUAL) it sums back to
528 / 4,690 / 3,120:

| Subclass | Labels | Rows | Foods |
| --- | ---: | ---: | ---: |
| VOLUME_UNIT | 7 | 816 | 634 |
| SIZE_EXT | 41 | 788 | 593 |
| DIMENSION | 8 | 566 | 554 |
| RESIDUAL | 207 | 628 | 534 |
| BAKED_SNACK | 105 | 442 | 361 |
| WEIGHT_UNIT | 10 | 289 | 275 |
| PRODUCE_UNIT | 42 | 287 | 268 |
| SANDWICH_BURGER | 19 | 245 | 206 |
| GUIDELINE_RATE | 12 | 193 | 173 |
| EGG | 2 | 127 | 127 |
| ANY_SIZE | 15 | 126 | 126 |
| DRINK | 6 | 82 | 82 |
| MEAL_ORDER | 54 | 101 | 70 |

```sql
<BASE>
, sub AS (
  SELECT *, CASE
    WHEN matchable ~* '^(Guideline amount|Topping per|Juice of)\M' THEN 'GUIDELINE_RATE'
    WHEN matchable ~* '\m(fl oz|fluid ounces?|ml|millilit(er|re)s?|lit(er|re)s?|shots?|jiggers?|drops?)\M' THEN 'VOLUME_UNIT'
    WHEN matchable ~* '(?<!fl )\m(oz|ounces?|lbs?|pounds?|grams?|g|kg)\M' THEN 'WEIGHT_UNIT'
    WHEN matchable ~* '\m(cubic|surface|linear|square) inch(es)?\M|\d-inch\M' THEN 'DIMENSION'
    WHEN matchable ~* '\m(regular|thick|thin|personal|child|senior|kids?|footlong|foot long|fun|sharing|king size|tiny|individual|baby|snack size|bite size|movie theater)\M' THEN 'SIZE_EXT'
    WHEN matchable ~* '\many (size|cut)\M' THEN 'ANY_SIZE'
    WHEN matchable ~* '\m(sandwich(es)?|submarines?|hamburgers?|cheeseburgers?|chiliburgers?|burgers?(?! king)|hot dogs?|frankfurters?|Big Mac|Grand Mac|Mac Jr)\M' THEN 'SANDWICH_BURGER'
    WHEN matchable ~* '\m(cookies?|crackers?|chips?|bars?|muffins?|waffles?|pancakes?|doughnuts?|donuts?|cupcakes?|cakes?|pies?|biscuits?|pastr(y|ies)|tarts?|rolls?|buns?|bagels?|loaf|loaves|toast|wafers?|pretzels?|croissants?|crepes?)\M' THEN 'BAKED_SNACK'
    WHEN matchable ~* '\m(fruits?|berry|berries|cherry|cherries|grapes?|potato(es)?|carrots?|floweret|florets?|spears?|beans?|peas?|corn|kernels?|nuts?|leaf|leaves|head|cloves?|stalks?|sprigs?|pods?|olives?|apples?|bananas?|mango(es)?|apricots?|figs?|dates?|prunes?|raisins?|lychee|tamarind|peppers?|tomato(es)?|onions?|bulb|sprouts?)\M' THEN 'PRODUCE_UNIT'
    WHEN matchable ~* '\m(eggs?|egg whites?)\M' THEN 'EGG'
    WHEN matchable ~* '\m(drinks?|sodas?|milkshakes?|snow cone|sundaes?|banana split|parfait)\M' THEN 'DRINK'
    WHEN matchable ~* '\m(meals?|dinners?|entrees?|orders?|menu|salads?|pizzas?)\M' THEN 'MEAL_ORDER'
    ELSE 'RESIDUAL' END AS subclass
  FROM classified WHERE class = 'OTHER')
SELECT subclass, count(DISTINCT label) AS distinct_labels, count(*) AS rows, count(DISTINCT food_id) AS distinct_foods
FROM sub GROUP BY subclass ORDER BY distinct_foods DESC;
```

The seven named subclasses at or above 200 foods (RESIDUAL aside) cover 232
labels / 3,433 rows / 2,430 foods of OTHER, leaving 296 labels / 1,257 rows /
1,085 foods. The three purely mechanical ones — VOLUME_UNIT, WEIGHT_UNIT,
DIMENSION — are 25 labels, 1,671 rows, **1,434 foods** on their own: the
largest block after `cup`, and not a word a model would say about a
photograph. Labels and rows add across subclasses because the partition is
exclusive per row; foods do not (634 + 275 + 554 = 1,463 double-counts a food
that carries, say, both `1 fl oz` and `1 cubic inch`), so the food figures
are distinct counts over the union:

```sql
<BASE><the sub CTE above>
SELECT (subclass IN ('VOLUME_UNIT','SIZE_EXT','DIMENSION','BAKED_SNACK','WEIGHT_UNIT','PRODUCE_UNIT','SANDWICH_BURGER')) AS in_seven,
       count(DISTINCT label) AS labels, count(*) AS rows, count(DISTINCT food_id) AS foods
FROM sub GROUP BY 1 ORDER BY 1 DESC;
-- t 232|3433|2430 ; f 296|1257|1085

<BASE><the sub CTE above>
SELECT count(DISTINCT label) AS labels, count(*) AS rows, count(DISTINCT food_id) AS foods
FROM sub WHERE subclass IN ('VOLUME_UNIT','WEIGHT_UNIT','DIMENSION');
-- 25 | 1671 | 1434
```

### SIZE_EXT is FDC's own synonym set

The alternative size grades are not a new idea: FDC pairs them with a
canonical size inside 22 SIZE labels (801 rows, 510 foods):

```sql
<BASE>
SELECT class, label, count(DISTINCT food_id) AS foods
FROM classified
WHERE class IN ('SIZE','CONTAINER','PIECE')
  AND matchable ~* '\m(regular|thick|thin|personal|child|senior|kids?|footlong|foot long|fun|sharing|king size|tiny|individual|baby|snack size|bite size|movie theater)\M'
GROUP BY 1, 2 ORDER BY 1, 3 DESC, 2;
-- SIZE: '1 large or thick slice' 136, '1 miniature/bite size' 131, '1 medium or regular slice' 88,
--   '1 small or thin/very thin slice' 88, '1 small/regular fillet' 84, '1 small or thin slice' 57,
--   '1 small/regular' 41, '1 large/king size' 31, '1 medium/regular' 23, '1 regular/large' 18,
--   '1 small/individual' 18 ...
-- CONTAINER (17 labels, 248 foods): '1 individual container' 94, '1 pouch/regular size' 31,
--   '1 snack size container' 30, '1 individual school container' 24, '1 individual packet' 21 ...
-- PIECE (8 labels, 29 foods): '1 regular slice' 9, '1 thick slice (yield after cooking)' 8 ...
```

Read off those pairings: *regular* ≈ medium (once ≈ small, once ≈ large),
*thick* ≈ large, *thin* ≈ small, *bite size* ≈ miniature, *king size* ≈ large,
*individual* ≈ small. `1 regular` alone is 153 foods — 97 of them in the
sandwich categories (*Deli and cured meat* 43, *Egg/breakfast* 38, *Meat and
BBQ* 5, *Seafood* 4, *Vegetable sandwiches/burgers* 4, *Chicken fillet* 2,
*Frankfurter* 1), where FDC's ladder is regular / large rather than small /
medium / large.

```sql
<BASE>
SELECT count(DISTINCT c.food_id) AS foods_total,
       count(DISTINCT c.food_id) FILTER (WHERE fc.description ILIKE '%sandwich%') AS in_sandwich_categories
FROM classified c JOIN food f ON f.id = c.food_id LEFT JOIN food_category fc ON fc.id = f.food_category_id
WHERE c.label = '1 regular';
-- 153 | 97   (16 categories in all; the per-category query is in "The top of OTHER" above, without its LIMIT)
```

### COOKING_STATE cuts across every class

79 labels, 755 rows, 446 foods across all classes carry a cooking-state
qualifier, 316 of those foods in CONTAINER (`1 cup, cooked, diced` 147, `1
cup, cooked` 107, `1 cup, diced, cooked` 20, `1 cup, without shell` 11) — the
family the ties question was about, and the reason a cup tie does not arise on
cooked rice: the qualifier is on the only cup row.

```sql
<BASE>
SELECT count(DISTINCT label) AS distinct_labels, count(*) AS rows, count(DISTINCT food_id) AS distinct_foods
FROM classified
WHERE matchable ~* '\m(cooked|raw|dry|boneless|skinless|prepared|frozen|without shell|skin only|yield after cooking|with sauce|with gravy|with filling|stuffed)\M';
-- 79 | 755 | 446
```

### The residual

Of the 207 RESIDUAL labels on 534 foods: container-like words the CONTAINER
regex lacks — `1 tub` 39, `1 cone` 18, `1 sleeve` 9, `1 shell (jumbo)` 6, `1
tray` 5, `1 envelope` 2, `1 tube` 1 — nine labels on 88 foods; meat-cut,
whole-bird and seafood words (`1 steak` 31, `1 drummette` 23, `1 nugget` 13,
`1 cocktail meatball` 9, `1 drumstick` 8, chops, ribs, clams, oysters, prawns,
scallops…) 58 labels on 192 foods under the regex printed below; and fry
shapes — six labels, 43 rows, but only 11 foods, because `crinkle cut`,
`shoestring`, `spiral or curly`, `straight cut` and `fry, NS as to shape` all
sit on the same eight french-fry records (2709456–2709463) and `1 chicken fry`
on three others.

```sql
<BASE><the sub CTE above>
SELECT label, count(DISTINCT food_id) AS foods FROM sub WHERE subclass = 'RESIDUAL'
GROUP BY label ORDER BY foods DESC, label LIMIT 60;
-- '1 tub' 39, '1 steak' 31, '1 French bread' 29, '1 drummette' 23, '1 cone' 18, '1 half' 13,
-- '1 nugget' 13, '1 rod' 11, '1 baguette (about 22" long)' 9, '1 cocktail meatball' 9, ...

<BASE><the sub CTE above>
SELECT v.name, count(DISTINCT label) AS labels, count(*) AS rows, count(DISTINCT food_id) AS foods
FROM sub, LATERAL (VALUES
  ('CONTAINER_LIKE', '\m(tubs?|trays?|sleeves?|cones?|envelopes?|tubes?|shells?)\M'),
  ('MEAT_SEAFOOD', '\m(steaks?|chops?|ribs?|drumsticks?|drummettes?|nuggets?|tenders?|cutlets?|meatballs?|sausages?|necks?|neckbones?|back|tails?|gizzards?|livers?|kidneys?|ham hock|claws?|clams?|oysters?|prawns?|scallops?|shrimps?|crabs?|crayfish|lobsters?|mussels?|anchov(y|ies)|sardines?|snails?|chicken|duck|hen|dove|quail|turkey)\M'),
  ('FRY_SHAPE', '\m(crinkle cut|shoestring|spiral or curly|straight cut|fry)\M')) AS v(name, rx)
WHERE subclass = 'RESIDUAL' AND matchable ~* v.rx
GROUP BY v.name ORDER BY foods DESC;
-- MEAT_SEAFOOD 58|202|192 ; CONTAINER_LIKE 9|88|88 ; FRY_SHAPE 6|43|11

<BASE><the sub CTE above>
SELECT label, count(DISTINCT food_id) AS foods, string_agg(DISTINCT food_id::text, ',') AS food_ids FROM sub
WHERE subclass = 'RESIDUAL' AND matchable ~* '\m(crinkle cut|shoestring|spiral or curly|straight cut|fry)\M'
GROUP BY label ORDER BY foods DESC, label;
-- '1 crinkle cut', '1 fry, NS as to shape', '1 shoestring', '1 spiral or curly', '1 straight cut':
--   8 each, the same ids 2709456,2709457,2709458,2709459,2709460,2709461,2709462,2709463
-- '1 chicken fry' 3 (2706098,2706099,2706102)
```

The MEAT_SEAFOOD regex is this note's own list of cut, bird and shellfish
words; it is not FDC's grouping, and `1 chicken fry` and `1 popcorn chicken`
fall in it through `chicken`.

### Regex caveats a checker should see

- PRODUCE_UNIT catches six brand or product labels on six foods (`1 Fig bar
  (2 square halves)`, `1 Kudos Crunchy Nut Snack`, `1 banana split`, …).
- SIZE_EXT's `baby` catches `1 baby corn` (18 foods), a variety rather than a
  size. `king size` rather than `king`, and `burgers?(?! king)`, keep `1
  Burger King salad` out of both classes.
- DIMENSION's `\d-inch` branch matches only `1 1-inch stack` (5 foods).
- No label contains `ml`, `litre`, `lb`, `gram` or `kg`; VOLUME_UNIT is fl oz
  plus shot / jigger / drop, and WEIGHT_UNIT is `oz` alone.
- `yield after cooking` (singular) survives the `%yields%` exclusion: 48
  usable labels carry it on the raw text, 15 of them OTHER (`1 oz dry, yield
  after cooking` 23, `1 oz, raw (yield after cooking)` 23, `1/2 chicken (yield
  after cooking, bone removed)` 7, …), 11 PIECE and 22 SIZE. Only two of the
  OTHER labels keep the phrase after the parenthetical strip — `1 oz dry,
  yield after cooking` and `1 oz, yield after cooking` — so COOKING_STATE's
  `yield after cooking` branch sees those two and nothing else.

  ```sql
  <BASE>
  SELECT class, count(DISTINCT label) AS labels_raw,
         count(DISTINCT label) FILTER (WHERE matchable ~* 'yield after cooking') AS labels_in_matchable,
         count(*) AS rows, count(DISTINCT food_id) AS foods
  FROM classified WHERE label ILIKE '%yield after cooking%' GROUP BY 1 ORDER BY 1;
  -- OTHER 15|2|72|72 ; PIECE 11|0|75|58 ; SIZE 22|0|36|18
  ```
- The parenthetical strip moves labels here too: `1 shell (jumbo)` (6) is
  OTHER not SIZE; `1 fun size box (4.23 fl oz)` (14) stays CONTAINER not
  VOLUME; every `(N oz)` meal label is MEAL_ORDER rather than WEIGHT_UNIT.

## What this means for the map

Facts and their implications, for the three tickets that read this note.
None of the following is a decision; each ticket makes its own.

### Code facts that bound everything above

Read on `origin/develop` at `fedaab1f`:

- The matcher runs only inside `if (parsed.quantity != null)` in
  [`bulk_add_bloc.dart`](../lib/features/add_meal/presentation/bloc/bulk_add_bloc.dart)
  (`matchPortionToQuery(parsed.portion ?? '', …) ?? matchPortionToQuery(parsed.query, …)`).
  An item with no count never reaches it on either path, and a photo item that
  `_countsOnly` strips (a unit, or a fraction) is rebuilt as `(query, quantity:
  null, unit: null)` — without the `portion` key. A whole count with no unit
  keeps both and does reach the matcher.
- The second call matches the **query text** against the labels, so the food's
  own noun is a portion word whenever it appears in a label: `chicken breast`
  with no portion word resolves to `1 small breast`, and `1 egg`, `1 sandwich`,
  `1 bar` behave the same way.
- `search_food_summary` has no `ORDER BY`; which record a query lands on is
  decided client-side, so "the banana" is whichever survey or SR Legacy record
  the ranker prefers — and the SR Legacy one delivers no portions.
- The RPC already returns a `localized` boolean per row, so the app can tell
  an English label from a translated one today without a schema change.

### #1156 — size of one, or a count

- The "size of one" shape depends on size rows existing on countable foods.
  They exist on 1,430 foods (27%), but on the twelve named foods only apple,
  chicken breast, bread and coffee have one. `banana, 1, large` and `egg, 2,
  large` — the shape's own examples — match nothing on the records the app can
  see and keep `1 banana` 126 g and `1 egg` 50 g. The size ladders for both
  sit on SR Legacy records with `NULL` labels.
- The "visible containers, count fixed at one" shape has one word to work
  with: `cup`, on 3,629 foods. `bowl` (36: 32 ready-to-heat pastas under `1
  large microwavable bowl`, 4 branded), `glass` (12, wine), `plate` and
  `handful` (0) cannot pin a row on
  rice, salad, milk or nuts. For rice and pasta the only visible row is `1
  cup, cooked`.
- Coffee's size ladder is coffee-shop sizes (`1 small` = 360 g) and its flat
  default is `1 fl oz` 30 g; almonds default to `1 nut` 1.2 g. A photo with no
  matched word lands there.
- The matcher is unreachable for a photo item that arrives with no count, so
  whatever #1156 allows, an item the model did not count keeps the flat
  default regardless of its portion word, as the call site stands.

### #1157 — the language of the key

- In German, every seeded label is verified: 57 size-or-container labels
  reaching 4,263 foods (93% of the foods carrying one), and 109 labels
  reaching 4,949 of the 5,394 foods overall. A German word is live for the head
  of the vocabulary today. The unseeded tail is 314 foods.
- In the other seven locales and `en`, the RPC returns English with
  `localized = false`. `Scheibe`, `fetta`, `plátek` match nothing there; `slice`
  matches 594 foods.
- German matching is not uniform under the inflection bound: `groß` and
  `klein` cover their inflections, `mittel` does not cover `mittlere`
  (`1 mittlere Scheibe`); `cup` is `Tasse` on the `1 cup…` labels and
  `Mikrowellenbecher` on `1 microwavable cup`, and `container` is `Becher`,
  `Dip-Becher`, `Snackbecher` or `Einzelbehälter` by label; `Glas` is the
  translation of `jar`. All from the listing in [What the German words
  are](#what-the-german-words-are).
- The "English, matched against both" shape needs the English label beside the
  translation. The RPC computes `coalesce(t.portion_description,
  fp.portion_description)` today, so both strings exist inside it, and only
  the coalesced one is returned.

### #1158 — closed vocabulary or free text

- The reach table is the steering list's evidence. Words the table can answer
  at scale: `cup` 3,629 foods, `large` 1,281, `small` 1,023, `medium` 859,
  `slice` 594, `piece` 465, `tablespoon` 310, `container` 241, `package` 184,
  `can` 175, `whole` 136, `bag` 123 (167 under the matcher's prefix rule, via
  `bagel`), `pouch` 121, `bottle` 117, `stick` 114. Words on #1158's draft
  list the table cannot answer: `glass` (12, wine), `bowl` (36, microwavable
  or branded), `handful` (0).
- Abbreviations do not match: `tbsp` and `tsp` have no rows; `tablespoon`
  and `teaspoon` do. The text prompt's own example of units outside its enum,
  *"(tbsp, tsp, cup, slice...)"*, names two words that would land nowhere as a
  portion key. `quart` has no rows either, but the prefix rule lands it on
  `quarter` — 42 foods: 25 `1 breast quarter…`, 16 `1 leg quarter…`, one `1
  quarter lb patty` — which is a wrong row, not a miss.
- `mini` reaches 46 foods; `miniature` 448. The inflection bound keeps them
  apart.
- FDC's own alternative grades are honest photo words the four classes leave
  in OTHER: `regular` (153 foods bare, plus the paired labels), `thick`,
  `thin`, `bite size`, `personal`, `child`, `individual` — 593 foods in the
  exclusive partition. Any list drawn only from small / medium / large misses
  them, and the pairings above (`1 medium or regular slice`) mean a model
  saying `regular` on bread already hits the 28 g row.
- A steering word hits ties: `slice` ties on 232 foods and resolves to `1
  small or thin/very thin slice` on 66 yeast breads (9–33 g; 24 g on white
  bread) and to the poultry-and-meat `1 small or thin slice` (28–109 g) on 57
  more; `large` ties on 226 and resolves to one piece on 63 pizzas. A list
  does not create those ties, but it concentrates traffic on them.
- Free text has reach a list does not: the food's own noun is the unit on the
  168 OTHER labels in the partition's four noun subclasses — SANDWICH_BURGER,
  BAKED_SNACK, PRODUCE_UNIT, EGG (`1 egg` 109, `1 sandwich` 75, `1 bar` 59, `1
  chip` 57, `1 cracker` 38, `1 nut` 32) — on 956 foods, plus the meat-cut,
  bird and seafood words in RESIDUAL (`1 steak` 31, among 58 labels on 192
  foods under the regex in [The residual](#the-residual)); a model that
  repeats the noun hits them, and the query-text fallback already does.

  ```sql
  <BASE><the sub CTE above>
  SELECT count(DISTINCT label) AS labels, count(*) AS rows, count(DISTINCT food_id) AS foods
  FROM sub WHERE subclass IN ('SANDWICH_BURGER','BAKED_SNACK','PRODUCE_UNIT','EGG');
  -- 168 | 1101 | 956
  SELECT label, subclass, count(DISTINCT food_id) AS foods FROM sub
  WHERE label IN ('1 egg','1 sandwich','1 bar','1 chip','1 cracker','1 nut','1 steak') GROUP BY 1, 2 ORDER BY 3 DESC;
  -- '1 egg' EGG 109 ; '1 sandwich' SANDWICH_BURGER 75 ; '1 bar' BAKED_SNACK 59 ; '1 chip' BAKED_SNACK 57 ;
  -- '1 cracker' BAKED_SNACK 38 ; '1 nut' PRODUCE_UNIT 32 ; '1 steak' RESIDUAL 31
  ```

## Reproducing

1. Source the gitignored `.env` and connect: `psql "$SUPABASE_DB_URL"`. The
   variable is named in this file and never valued; its value must not be
   pasted into a note or a commit.
2. Every query is complete as printed. Where a block begins with `<BASE>`,
   paste the base CTE from [Method](#method) in front of it; where it says
   `<the sub CTE above>`, append the `sub` CTE from
   [What the taxonomy misses](#what-the-taxonomy-misses) after `<BASE>`.
3. Results are appended as `--` comments and were taken on 2026-09-11. They
   will move when the backend's `food_portion` or `food_portion_translation`
   is reseeded; the row counts in [Baseline](#baseline) are the first thing to
   re-check.
4. The classification is deterministic given the predicate and regexes in
   Method. The per-food tables use the ids listed in the query; the choice of
   those ids is the one judgment call in this note and is explained beside each
   food.

## Not verified

- **Which record the ranker picks** for `banana`, `egg`, `rice` and the rest.
  The per-food tables assume the survey record; if the ranker prefers the SR
  Legacy record the app receives no portions at all. Not simulated.
- **Whether the two `Quantity not specified, if …` rows** (one each) ever
  reach a user; the RPC delivers them, the ticket's predicate excludes them.
- **The German translations beyond the 57 size and container labels** were
  read for the words above but not reviewed for correctness; #1093 owns that.
- **The MEAT_SEAFOOD and FRY_SHAPE regexes** in [The residual](#the-residual)
  are this note's word lists, chosen by reading the 207 RESIDUAL labels; a
  different list gives a different count.
