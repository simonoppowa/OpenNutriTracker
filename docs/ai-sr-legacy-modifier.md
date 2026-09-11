# What the SR Legacy `modifier` column holds, and what reading it would expose

Research notes gathered 2026-09-11 against the live backend — `food_portion`,
`food_portion_translation`, `food`, `food_summary`, `measure_unit` and the
five RPCs the app calls — read with `psql` over the connection string in
`SUPABASE_DB_URL`. `SELECT`, `EXPLAIN`, `\d`, `pg_get_functiondef` and
`pg_get_viewdef` only; nothing was written, and no issue was edited. Written
for [#1163](https://github.com/simonoppowa/OpenNutriTracker/issues/1163) on
map [#1154](https://github.com/simonoppowa/OpenNutriTracker/issues/1154), as
the sequel to the vocabulary note for
[#1155](https://github.com/simonoppowa/OpenNutriTracker/issues/1155) on
[`research/portion-size-vocabulary`](https://github.com/simonoppowa/OpenNutriTracker/blob/research/portion-size-vocabulary/docs/ai-portion-size-vocabulary.md).
Every figure below cites the query that produced it, with the result appended
as a comment. Code is read on `origin/develop` at `df6d54c8`.

**The question.** #1155 found that all 14,449 SR Legacy rows and 186 of 187
Foundation rows in `food_portion` have `portion_description IS NULL`, and that
the household text for those rows sits in `modifier`, a column
`portions_by_food_ids` never reads. Before a prompt or matcher decision leans
on "the size ladders are invisible", four things need settling: what
`modifier` actually holds on those rows; what `COALESCE(portion_description,
modifier)` in the RPC would expose and what it would cost; whether the app
would ever receive an SR Legacy record for the twelve foods the AI paths
produce, or always the survey one #1155 tabulated; and whether any exposed
label would be translated.

**The answer.** `modifier` is the FNDDS household phrase with its leading
count removed: survey *Banana, raw* says `1 cup, mashed`, SR Legacy *Bananas,
raw* says `cup, mashed` with `amount = 1`. No SR Legacy modifier starts with a
digit; 173 of the 1,906 distinct values equal a survey label once `1 ` is
prepended, and those 173 cover 8,266 of the 14,543 rows. A COALESCE under the
RPC's existing filter would deliver 14,341 rows on 7,529 of the 7,533 SR
Legacy foods, plus 94 qualifier fragments (`raw`, `sifted`, `Peeled`) on 53
Foundation foods whose unit lives in `measure_unit` instead. What it exposes
is not mostly size ladders: a size word reaches 245 SR Legacy foods (3.3%,
against 27% of survey foods in #1155), `cup` reaches 1,691 rows, and the
largest single block is the bare units: 3,951 rows on 3,494 foods whose
whole label is `oz`, `fl oz`, `lb`, `ml`, `liter` or `g`, and 4,028 rows on
3,569 foods that yield no term once the matcher strips parentheticals (`oz
(3 oz)` and `lb 16 oz` join, `liter` leaves) — labels the matcher cannot
tokenise at all, since it drops terms under three letters. The label alone
carries no count: 3,458 deliverable rows have `amount <> 1`, so the bare
label `oz` stands for 85 g on 1,431 rows and 113 g on 638, and 307 foods
would list the same label twice. The RPC's own regex catches all 108 `NFS`
/ `yields` / `NS as to` rows but passes 626 `(yield from 1 lb …)` rows,
because those say `yield`, not `yields`. On which record the app receives:
`search_food_summary` has no `ORDER BY` and returns the materialized view
in heap order, survey rows first, so for seven of the twelve terms no SR
Legacy record can enter the 100-row pool at all; the Dart ranker, run on
the exported pools in the backend's order, lands every one of the eleven
terms that return anything on a survey record, and on the record #1155
tabulated in only four cases (banana, bread, coffee, pasta), and `yoghurt`
returns nothing because every record is spelled *Yogurt*. Which sibling
wins among records with the same shown name is decided by the order the
search cache hands back, which the harness did not model; for ten of the
eleven terms every such sibling is a survey record, for `chicken breast`
one is SR Legacy (174608). On the AI path an SR Legacy record sits at #2 in
the candidate list for banana, chicken breast and almonds, carrying
portions and selectable on the review screen. Translation: zero
`food_portion_translation` rows point at any NULL-description portion; 39
of the 109 seeded labels equal a modifier with `1 ` prepended, which is
honest on the 4,387 rows (3,580 foods) at `amount = 1`; every exposed label
would otherwise be English with `localized = false` in all nine locales.

## Method

**Connection.** `psql "$SUPABASE_DB_URL"` from the shell, the variable
sourced from the gitignored `.env`. Read-only: `SELECT`, `EXPLAIN (COSTS
OFF)`, `\d`, `pg_get_functiondef`, `pg_get_viewdef`.

**Scope.** "NULL-description rows" means `food_portion.portion_description IS
NULL`: 14,635 rows, of which 14,449 are SR Legacy on 7,533 foods and 186 are
Foundation on 116 foods. The SR Legacy figures match #1155's baseline exactly.
Everything in [What `modifier` holds](#what-modifier-holds) counts those rows;
everything in [What a COALESCE would expose](#what-a-coalesce-would-expose)
counts the subset the RPC's own filter would keep.

**The RPC filter**, reproduced verbatim from `pg_get_functiondef` and applied
to `coalesce(fp.portion_description, fp.modifier)` in every simulation:

```sql
label IS NOT NULL
AND label <> 'Quantity not specified'
AND gram_weight IS NOT NULL AND gram_weight > 0
AND label !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount'
```

The ticket's predicate from #1155 (`ILIKE '%quantity not specified%' /
'%NFS%' / '%yields%' / '%NS as to size%'`, plus `NULL` and blank) is applied
beside it where the two differ, and they differ on exactly one row.

**The four classes** are #1155's, unchanged: case-insensitive POSIX regexes
with `\m` / `\M` word boundaries, first match wins in the order SIZE >
CONTAINER > PIECE > OTHER.

```sql
-- SIZE
\m(small|medium|large|jumbo|mini|miniature)\M
-- CONTAINER
\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M
-- PIECE
\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M
```

In [What `modifier` holds](#what-modifier-holds) they run on the **raw**
modifier, because the question there is what the column contains. In [What a
COALESCE would expose](#what-a-coalesce-would-expose) they run on the label
**with parentheticals removed** — `regexp_replace(label, '\([^)]*\)', ' ',
'g')` — because that is what `_termsOf` in
[`lib/features/add_meal/util/portion_match.dart`](../lib/features/add_meal/util/portion_match.dart)
does before matching. The two differ by a few dozen foods (`oz (23 whole
kernels)` is PIECE raw and OTHER stripped) and both numbers are given where
it matters.

**Case.** Distinct-value counts are case-sensitive unless a query says
`lower(btrim(...))`: 1,906 distinct modifiers case-sensitively, 1,892
case-folded. The one place it shows in a headline figure is `tbsp`, 548 rows
exact and 553 with five `Tbsp` rows folded in; the translation section counts
case-folded because the seeded labels are compared that way. Spot-checked:

```sql
SELECT count(*) FILTER (WHERE fp.modifier = 'tbsp') AS rows_exact,
       count(DISTINCT fp.food_id) FILTER (WHERE fp.modifier = 'tbsp') AS foods_exact,
       count(*) FILTER (WHERE lower(btrim(fp.modifier)) = 'tbsp') AS rows_ci,
       count(DISTINCT fp.food_id) FILTER (WHERE lower(btrim(fp.modifier)) = 'tbsp') AS foods_ci,
       string_agg(DISTINCT fp.modifier, ' | ') FILTER (WHERE lower(btrim(fp.modifier)) = 'tbsp' AND fp.modifier <> 'tbsp') AS variants
FROM food_portion fp WHERE fp.portion_description IS NULL;
-- 548 | 548 | 553 | 553 | Tbsp
```

**Code** was read with `git show origin/develop:<path>` at `df6d54c8`:
[`portion_match.dart`](../lib/features/add_meal/util/portion_match.dart),
[`sp_food_data_source.dart`](../lib/features/add_meal/data/data_sources/sp_food_data_source.dart),
[`meal_relevance_ranker.dart`](../lib/features/add_meal/util/meal_relevance_ranker.dart),
[`resolver_relevance.dart`](../lib/features/add_meal/util/resolver_relevance.dart),
[`resolve_parsed_meals_usecase.dart`](../lib/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart),
[`search_products_usecase.dart`](../lib/features/add_meal/domain/usecase/search_products_usecase.dart),
[`products_repository.dart`](../lib/features/add_meal/data/repository/products_repository.dart),
[`sp_food_dto.dart`](../lib/features/add_meal/data/dto/sp/sp_food_dto.dart),
[`meal_entity.dart`](../lib/features/add_meal/domain/entity/meal_entity.dart),
[`sp_const.dart`](../lib/features/add_meal/data/dto/sp/sp_const.dart),
[`bulk_add_bloc.dart`](../lib/features/add_meal/presentation/bloc/bulk_add_bloc.dart).

**The Dart ranker was run, not reasoned about.** The per-term 100-row pools
were exported from `search_food_summary` in the order the RPC emits them and
fed through the real `rankAndTruncateFoodsByName` →
`MealEntity.fromSpFood` → `validateNutriments` → `mergeAndRankMeals(const
[], fdc, term)` → `rankForResolution` by a throwaway `flutter test` file in a
worktree whose `lib/` and `test/` are byte-identical to `origin/develop`
(`git diff --stat 6ab618a8 origin/develop -- lib test` is empty). Assumptions
the harness fixes: the OFF list empty; no custom meals, recipes or intake
history; English locale; every source toggle on (`sources = NULL`); the
query is the bare term; and the list handed to `mergeAndRankMeals` is the
one `getSupabaseFoodsByString` returns, in that order. The last is not a
state the app is ever in: `searchFDCFoodByString` writes the 20 rows to the
search cache and `_buildResult` reads them back sorted by cache timestamp
before the ranker sees them (see [step 3](#the-app-side-re-ranking-as-read-from-the-code)),
so the harness's order is the app's only when that sort preserves it. The
test file and the copied generated files were removed from the worktree
afterwards; the file and its output are printed in full in [The harness
run](#the-harness-run).


## What `modifier` holds

### Baseline

| `food.source` | NULL-description rows | Foods | Rows with a modifier | Foods with a modifier | Modifier `NULL` | Distinct modifiers |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| sr_legacy | 14,449 | 7,533 | 14,449 | 7,533 | 0 | 1,867 |
| foundation | 186 | 116 | 94 | 53 | 92 | 49 |

Every SR Legacy row carries a non-blank modifier; half the Foundation rows
carry none. Across both sources there are 1,906 distinct values
case-sensitively (1,867 + 49 − 10 shared), 1,892 case-folded.

```sql
SELECT f.source, count(*) AS rows, count(DISTINCT fp.food_id) AS foods,
       count(*) FILTER (WHERE fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '') AS rows_with_modifier,
       count(DISTINCT fp.food_id) FILTER (WHERE fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '') AS foods_with_modifier,
       count(*) FILTER (WHERE fp.modifier IS NULL) AS modifier_null,
       count(*) FILTER (WHERE fp.modifier IS NOT NULL AND btrim(fp.modifier) = '') AS modifier_blank,
       count(DISTINCT fp.modifier) FILTER (WHERE fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '') AS distinct_modifiers
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE fp.portion_description IS NULL
GROUP BY 1 ORDER BY 2 DESC;
-- fdc_sr_legacy 14449 | 7533 | 14449 | 7533 | 0 | 0 | 1867
-- fdc_foundation  186 |  116 |    94 |   53 | 92 | 0 |   49

SELECT count(DISTINCT fp.modifier) FILTER (WHERE fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '') AS distinct_modifiers_all_null_desc,
       count(DISTINCT btrim(fp.modifier)) FILTER (WHERE fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '') AS distinct_trimmed,
       count(DISTINCT lower(btrim(fp.modifier))) FILTER (WHERE fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '') AS distinct_lower_trimmed,
       count(*) FILTER (WHERE fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '') AS rows_with_modifier
FROM food_portion fp
WHERE fp.portion_description IS NULL;
-- 1906 | 1906 | 1892 | 14543

SELECT count(*) AS shared_values FROM (
  SELECT fp.modifier FROM food_portion fp JOIN food f ON f.id = fp.food_id
  WHERE fp.portion_description IS NULL AND f.source = 'fdc_sr_legacy' AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> ''
  INTERSECT
  SELECT fp.modifier FROM food_portion fp JOIN food f ON f.id = fp.food_id
  WHERE fp.portion_description IS NULL AND f.source = 'fdc_foundation' AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> ''
) s;
-- 10
```

`measure_unit_id` is 9999 (`undetermined`) on every one of the 14,449 SR
Legacy rows, the same as on every survey row. The 186 Foundation rows are the
exception in the table: they carry a named unit (`cup` 50, `each` 19, `slice`
12, `link` 10, `tablespoon` 10, `wedge` 6, `steak` 6, `roast` 6, `teaspoon`
5, …) and use `modifier` for a qualifier, which is why they are treated
separately in [Foundation rows](#foundation-rows).

```sql
SELECT mu.id, mu.name, count(*) AS rows FROM food_portion fp LEFT JOIN measure_unit mu ON mu.id = fp.measure_unit_id
WHERE fp.portion_description IS NULL GROUP BY 1, 2 ORDER BY 3 DESC LIMIT 10;
-- 9999 undetermined 14449 ; 1000 cup 50 ; 1071 each 19 ; 1050 slice 12 ; 1033 link 10 ; 1001 tablespoon 10 ; 1060 wedge 6 ; 1054 steak 6 ; 1046 roast 6 ; 1002 teaspoon 5
```

### The phrasing: survey text minus its count

The SR Legacy modifier is the FNDDS household phrase with the leading count
removed and moved to `food_portion.amount`. Survey *Banana, raw* (2709224)
says `1 cup, mashed` with `amount NULL`; SR Legacy *Bananas, raw* (173944)
says `cup, mashed` with `amount = 1`. No SR Legacy modifier starts with a
digit; the seven digit-leading rows in the NULL-description set are all
Foundation dimensions (`2-1/2" dia`, `5.3 oz`, `1/2 cup`), never counts.

```sql
SELECT count(*) AS rows_modifier_starts_with_digit,
       count(DISTINCT fp.modifier) AS distinct_starting_with_digit
FROM food_portion fp
WHERE fp.portion_description IS NULL AND fp.modifier ~ '^\s*[0-9]';
-- 7 | 6

SELECT f.source, f.description, fp.amount, fp.modifier, fp.gram_weight
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE fp.portion_description IS NULL AND fp.modifier ~ '^\s*[0-9]'
ORDER BY 1, 2;
-- 7 rows, all fdc_foundation, all amount 1: Nectarines, raw 2-1/2" dia / 2-3/4" dia / 2-1/3" dia ;
-- Oranges, raw, navels 2-7/8" dia (two foods) ; Sauce, pasta … 1/2 cup ; Yogurt, Greek, strawberry, nonfat 5.3 oz
```

Against the survey vocabulary, no modifier value equals a survey
`portion_description` verbatim, and 171 (173 case-insensitively) equal one
once `1 ` is prepended. Those 173 values are the common core — `cup`, `tbsp`,
`slice`, `medium`, `large`, `small`, `cup, chopped`, `cup, sliced` — and they
cover 8,266 of the 14,543 rows and 6,019 foods:

```sql
WITH sv AS (SELECT DISTINCT fp.portion_description AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_survey' AND fp.portion_description IS NOT NULL),
     md AS (SELECT DISTINCT fp.modifier FROM food_portion fp WHERE fp.portion_description IS NULL AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '')
SELECT (SELECT count(*) FROM md WHERE modifier IN (SELECT label FROM sv)) AS verbatim_equal,
       (SELECT count(*) FROM md WHERE ('1 ' || modifier) IN (SELECT label FROM sv)) AS equal_with_1_prefix,
       (SELECT count(*) FROM md WHERE lower('1 ' || modifier) IN (SELECT lower(label) FROM sv)) AS equal_with_1_prefix_ci,
       (SELECT count(*) FROM md) AS distinct_modifiers;
-- 0 | 171 | 173 | 1906

SELECT count(*) AS rows, count(DISTINCT fp.food_id) AS foods
FROM food_portion fp
WHERE fp.portion_description IS NULL AND fp.modifier IS NOT NULL
  AND lower('1 ' || fp.modifier) IN (SELECT DISTINCT lower(x.portion_description) FROM food_portion x JOIN food f ON f.id = x.food_id WHERE f.source = 'fdc_survey' AND x.portion_description IS NOT NULL);
-- 8266 | 6019
```

The remaining 1,733 values fall into six families:

- **Dimension-qualified sizes in parentheses** — `large (8" to 8-7/8" long)`,
  `medium (3" dia)`, `extra small (less than 6" long)`: 75 distinct values on
  48 foods. Only 7 values are a bare size word — `medium` (66 rows), `large`
  (60), `small` (51), `extra large` (4), `jumbo` (2), `mini` (2), `miniature`
  (1); `extra small` never occurs bare — 186 rows on 94 foods.
- **A bare weight or volume unit as the whole label** — `oz` on 3,041 foods,
  `fl oz` 440, `lb` 281, `cubic inch` 51, `ml` 8, `liter` 3, `g` 1: 4,002 rows
  on 3,512 foods, and 1,026 foods have nothing else (1,024 counting only
  `oz`, `fl oz`, `lb`, `g` and `ml`).
- **The yield family** — `piece, cooked, excluding refuse (yield from 1 lb raw
  meat with refuse)`, `unit (yield from 1 lb ready-to-cook chicken)`: 709 rows
  on 685 foods.
- **`NLEA serving`** as the whole label on 37 foods (32 in that exact case,
  five as `NLEA Serving`); the word `NLEA` reaches 197 foods, mostly through
  `cup (1 NLEA serving)` (98) and `packet (1 NLEA serving)` (17).
- **Food noun before the size** — `potato large`, `head, large`, `leaf,
  medium`, `slice, large`, `strip medium`.
- **Container with capacity** — `container (6 oz)`, `cup (8 fl oz)`, `can (303
  x 406)`.

```sql
SELECT count(DISTINCT fp.modifier) FILTER (WHERE fp.modifier ~* '^\s*(extra )?(small|medium|large|jumbo|mini|miniature)\s*$') AS bare_size_values,
       count(*) FILTER (WHERE fp.modifier ~* '^\s*(extra )?(small|medium|large|jumbo|mini|miniature)\s*$') AS bare_size_rows,
       count(DISTINCT fp.food_id) FILTER (WHERE fp.modifier ~* '^\s*(extra )?(small|medium|large|jumbo|mini|miniature)\s*$') AS bare_size_foods,
       count(DISTINCT fp.modifier) FILTER (WHERE fp.modifier ~* '^\s*(extra )?(small|medium|large|jumbo|mini|miniature)\s*\(') AS size_with_dimension_values,
       count(DISTINCT fp.food_id) FILTER (WHERE fp.modifier ~* '^\s*(extra )?(small|medium|large|jumbo|mini|miniature)\s*\(') AS size_with_dimension_foods
FROM food_portion fp WHERE fp.portion_description IS NULL AND fp.modifier IS NOT NULL;
-- 7 | 186 | 94 | 75 | 48

SELECT fp.modifier, count(*) AS rows, count(DISTINCT fp.food_id) AS foods
FROM food_portion fp WHERE fp.portion_description IS NULL AND fp.modifier ~* '^\s*(extra )?(small|medium|large|jumbo|mini|miniature)\s*$'
GROUP BY 1 ORDER BY 2 DESC, 1;
-- medium 66 | 66 ; large 60 | 60 ; small 51 | 51 ; extra large 4 | 4 ; jumbo 2 | 2 ; mini 2 | 2 ; miniature 1 | 1   (no bare "extra small")

SELECT fp.modifier, count(*) AS rows, count(DISTINCT fp.food_id) AS foods, count(*) FILTER (WHERE fp.amount = 1) AS rows_amount_1
FROM food_portion fp
WHERE fp.portion_description IS NULL AND fp.modifier ~* '^\s*(oz|fl oz|lb|g|kg|ml|l|liter|litre|gram|grams|ounce|ounces|pound|pounds|cubic inch|inch|inches|cubic centimeter)\s*$'
GROUP BY 1 ORDER BY 2 DESC;
-- oz 3166 | 3041 | 999 ; fl oz 492 | 440 | 364 ; lb 281 | 281 | 271 ; cubic inch 51 | 51 | 51 ; ml 8 | 8 | 3 ; liter 3 | 3 | 3 ; g 1 | 1 | 0

SELECT count(*) AS bare_unit_rows, count(DISTINCT fp.food_id) AS bare_unit_foods,
       count(DISTINCT fp.food_id) FILTER (WHERE NOT EXISTS (
         SELECT 1 FROM food_portion x WHERE x.food_id = fp.food_id AND x.portion_description IS NULL
           AND x.modifier IS NOT NULL AND x.modifier !~* '^\s*(oz|fl oz|lb|g|kg|ml|l|liter|litre|gram|grams|ounce|ounces|pound|pounds|cubic inch|inch|inches|cubic centimeter)\s*$')) AS foods_with_only_bare_units
FROM food_portion fp
WHERE fp.portion_description IS NULL AND fp.modifier ~* '^\s*(oz|fl oz|lb|g|kg|ml|l|liter|litre|gram|grams|ounce|ounces|pound|pounds|cubic inch|inch|inches|cubic centimeter)\s*$';
-- 4002 | 3512 | 1026

WITH per_food AS (
  SELECT fp.food_id,
         bool_and(fp.modifier ~* '^\s*(oz|fl oz|lb|g|kg|ml|l|liter|litre|gram|grams|ounce|ounces|pound|pounds|cubic inch|inch|inches|cubic centimeter)\s*$') AS only_units_incl_cubic_inch,
         bool_and(fp.modifier ~* '^\s*(oz|fl oz|lb|g|ml)\s*$') AS only_five_bare_units
  FROM food_portion fp JOIN food f ON f.id = fp.food_id
  WHERE fp.portion_description IS NULL AND f.source = 'fdc_sr_legacy' AND fp.modifier IS NOT NULL GROUP BY 1)
SELECT count(*) FILTER (WHERE only_units_incl_cubic_inch) AS foods_only_bare_units_with_cubic_inch,
       count(*) FILTER (WHERE only_five_bare_units) AS foods_only_five_bare_units
FROM per_food;
-- 1026 | 1024

SELECT count(*) AS yield_rows, count(DISTINCT fp.food_id) AS yield_foods
FROM food_portion fp WHERE fp.portion_description IS NULL AND fp.modifier ~* '\myields?\M';
-- 709 | 685

SELECT fp.modifier, count(*) AS rows FROM food_portion fp
WHERE fp.portion_description IS NULL AND fp.modifier ~* '\myields?\M'
GROUP BY 1 ORDER BY 2 DESC LIMIT 8;
-- piece, cooked, excluding refuse (yield from 1 lb raw meat with refuse) 212 ; unit (yield from 1 lb ready-to-cook chicken) 106 ;
-- unit, cooked (yield from 1 lb raw meat) 33 ; package (10 oz) yields 32 ; piece, cooked (yield from 1 lb raw meat, boneless) 20 ;
-- chop, excluding refuse (yield from 1 raw chop, with refuse, weighing 113 g) 11 ; unit (yield from 1 lb ready-to-cook duck) 11 ; package yield (2 cups) 10

SELECT count(DISTINCT fp.food_id) FILTER (WHERE fp.modifier = 'NLEA serving') AS nlea_serving_exact_foods,
       count(DISTINCT fp.food_id) FILTER (WHERE lower(btrim(fp.modifier)) = 'nlea serving') AS nlea_serving_ci_foods,
       count(DISTINCT fp.food_id) FILTER (WHERE fp.modifier ~* '\mNLEA\M') AS any_nlea_foods,
       count(*) FILTER (WHERE fp.modifier ~* '\mNLEA\M') AS any_nlea_rows
FROM food_portion fp WHERE fp.portion_description IS NULL;
-- 32 | 37 | 197 | 198

SELECT fp.modifier, count(DISTINCT fp.food_id) AS foods, count(*) AS rows
FROM food_portion fp WHERE fp.portion_description IS NULL AND fp.modifier ~* '\mNLEA\M'
GROUP BY 1 ORDER BY 2 DESC, 1 LIMIT 6;
-- cup (1 NLEA serving) 98 ; NLEA serving 32 ; packet (1 NLEA serving) 17 ; tbsp (1 NLEA serving) 12 ; NLEA Serving 5 ; package (1 NLEA serving) 5
```

### The top values

The forty most common modifiers by distinct food, with how many of their rows
sit at `amount = 1` — the column that decides whether the bare text is an
honest label (see [The count lives in `amount`](#the-count-lives-in-amount)).

| Modifier | Foods | Rows | Rows at `amount = 1` |
| --- | ---: | ---: | ---: |
| `oz` | 3,041 | 3,166 | 999 |
| `cup` | 1,643 | 1,691 | 1,469 |
| `tbsp` | 548 | 548 | 505 |
| `fl oz` | 440 | 492 | 364 |
| `lb` | 281 | 281 | 271 |
| `steak` | 280 | 280 | 280 |
| `serving` | 265 | 265 | 265 |
| `piece, cooked, excluding refuse (yield from 1 lb raw meat with refuse)` | 212 | 212 | 212 |
| `slice` | 185 | 186 | 185 |
| `roast` | 185 | 185 | 185 |
| `tsp` | 163 | 171 | 157 |
| `fillet` | 162 | 162 | 121 |
| `piece` | 146 | 147 | 146 |
| `jar` | 130 | 131 | 131 |
| `unit (yield from 1 lb ready-to-cook chicken)` | 106 | 106 | 98 |
| `cup (1 NLEA serving)` | 98 | 98 | 31 |
| `tablespoon` | 91 | 91 | 84 |
| `cup (8 fl oz)` | 90 | 90 | 90 |
| `cup, chopped` | 71 | 71 | 63 |
| `cup slices` | 67 | 68 | 46 |
| `medium` | 66 | 66 | 59 |
| `bar` | 61 | 66 | 65 |
| `large` | 60 | 60 | 56 |
| `can` | 58 | 58 | 56 |
| `cup, chopped or diced` | 58 | 58 | 46 |
| `chop` | 57 | 57 | 57 |
| `package` | 54 | 56 | 40 |
| `item` | 53 | 53 | 53 |
| `cup, shredded` | 52 | 52 | 46 |
| `cubic inch` | 51 | 51 | 51 |
| `cup, sliced` | 51 | 51 | 51 |
| `small` | 51 | 51 | 48 |
| `cup, diced` | 46 | 46 | 42 |
| `scoop` | 46 | 46 | 42 |
| `cup, cubes` | 40 | 43 | 39 |
| `pieces` | 39 | 46 | 0 |
| `package (10 oz)` | 37 | 50 | 37 |
| `pizza` | 36 | 37 | 36 |
| `can (303 x 406)` | 36 | 36 | 36 |
| `jar Gerber Second Food (4 oz)` | 36 | 36 | 36 |

Thirteen of the forty sit below 90% at `amount = 1`: `pieces` (0 of 46),
`oz` (31.6%), `cup (1 NLEA serving)` (31.6%), `cup slices` (67.6%),
`package` (71.4%), `fl oz` and `package (10 oz)` (74.0%), `fillet` (74.7%),
`cup, chopped or diced` (79.3%), `cup` (86.9%), `cup, shredded` (88.5%),
`cup, chopped` (88.7%) and `medium` (89.4%); the other twenty-seven are at
90–100%, twelve of them at exactly 100%.

```sql
SELECT fp.modifier AS value, count(DISTINCT fp.food_id) AS foods, count(*) AS rows,
       count(*) FILTER (WHERE fp.amount = 1) AS rows_amount_1,
       round(100.0 * count(*) FILTER (WHERE fp.amount = 1) / count(*), 1) AS pct_amount_1
FROM food_portion fp
WHERE fp.portion_description IS NULL AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> ''
GROUP BY 1 ORDER BY 2 DESC, 3 DESC, 1 LIMIT 40;
-- oz 3041 | 3166 | 999 | 31.6 ; cup 1643 | 1691 | 1469 | 86.9 ; tbsp 548 | 548 | 505 | 92.2 ; fl oz 440 | 492 | 364 | 74.0 ; lb 281 | 281 | 271 | 96.4 ;
-- steak 280 | 280 | 280 | 100 ; serving 265 | 265 | 265 | 100 ; piece, cooked … 212 | 212 | 212 | 100 ; slice 185 | 186 | 185 | 99.5 ; roast 185 | 185 | 185 | 100 ;
-- tsp 163 | 171 | 157 | 91.8 ; fillet 162 | 162 | 121 | 74.7 ; piece 146 | 147 | 146 | 99.3 ; jar 130 | 131 | 131 | 100 ; unit (yield …) 106 | 106 | 98 | 92.5 ;
-- cup (1 NLEA serving) 98 | 98 | 31 | 31.6 ; tablespoon 91 | 91 | 84 | 92.3 ; cup (8 fl oz) 90 | 90 | 90 | 100 ; cup, chopped 71 | 71 | 63 | 88.7 ; cup slices 67 | 68 | 46 | 67.6 ;
-- medium 66 | 66 | 59 | 89.4 ; bar 61 | 66 | 65 | 98.5 ; large 60 | 60 | 56 | 93.3 ; can 58 | 58 | 56 | 96.6 ; cup, chopped or diced 58 | 58 | 46 | 79.3 ;
-- chop 57 | 57 | 57 | 100 ; package 54 | 56 | 40 | 71.4 ; item 53 | 53 | 53 | 100 ; cup, shredded 52 | 52 | 46 | 88.5 ; cubic inch 51 | 51 | 51 | 100 ;
-- cup, sliced 51 | 51 | 51 | 100 ; small 51 | 51 | 48 | 94.1 ; cup, diced 46 | 46 | 42 | 91.3 ; scoop 46 | 46 | 42 | 91.3 ; cup, cubes 40 | 43 | 39 | 90.7 ;
-- pieces 39 | 46 | 0 | 0 ; package (10 oz) 37 | 50 | 37 | 74.0 ; pizza 36 | 37 | 36 | 97.3 ; can (303 x 406) 36 | 36 | 36 | 100 ; jar Gerber Second Food (4 oz) 36 | 36 | 36 | 100
```

Compared with the survey vocabulary in #1155, the head is the same words in
a different form: `1 cup` was 3,056 survey foods, `cup` is 1,643 SR Legacy
foods; `1 tablespoon` was 310 survey foods, and `tbsp` — which has no
`portion_description` anywhere — is 548 here, with `tablespoon` on 91 more.
`oz` at the top has no survey counterpart at all: the survey's mechanical
measure is `1 fl oz` / `1 oz, cooked` / `1 cubic inch` on 1,434 foods, and it
never leads.

### The classes

The four regexes from #1155 on the **raw** modifier, first match wins:

| Class | Distinct values | Rows | Foods |
| --- | ---: | ---: | ---: |
| SIZE | 270 | 596 | 256 |
| CONTAINER | 708 | 5,916 | 3,985 |
| PIECE | 261 | 1,695 | 1,494 |
| OTHER | 667 | 6,336 | 4,487 |

The classes sum to the 14,543 rows that carry a modifier and to the 1,906
distinct values. OTHER is the largest class, and it is mostly the bare units
(`oz`, `lb`, `fl oz`), the meat cuts (`steak`, `roast`, `chop`), the yield
family and `NLEA serving` — words no class regex names, though the matcher
would still see `steak`, `roast`, `chop`, `bar`, `pizza`, `taco` and
`almond` as terms.

```sql
WITH m AS (
  SELECT fp.food_id, fp.modifier,
    CASE WHEN fp.modifier ~* '\m(small|medium|large|jumbo|mini|miniature)\M' THEN 'SIZE'
         WHEN fp.modifier ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M' THEN 'CONTAINER'
         WHEN fp.modifier ~* '\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M' THEN 'PIECE'
         ELSE 'OTHER' END AS class
  FROM food_portion fp
  WHERE fp.portion_description IS NULL AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '')
SELECT class, count(DISTINCT modifier) AS distinct_values, count(*) AS rows, count(DISTINCT food_id) AS foods
FROM m GROUP BY 1 ORDER BY 3 DESC;
-- OTHER 667 | 6336 | 4487 ; CONTAINER 708 | 5916 | 3985 ; PIECE 261 | 1695 | 1494 ; SIZE 270 | 596 | 256
```

Counted per SR Legacy food and per class independently (a food counts in
every class it hits, not only the first), size words reach 247 of the 7,533
foods (3.3%), container words 3,990 (53%), piece words 1,687, any of the
three 5,289; 2,244 foods hit none of them. Only 13 foods carry an `extra
small` or `extra large` row. #1155's survey figures for comparison, from
its class table: size 1,430 foods (27%), container 4,002 (74%), piece 1,130
(21%) of the 5,394 foods with a usable label.

```sql
SELECT
  count(DISTINCT fp.food_id) AS sr_legacy_foods_with_null_desc_rows,
  count(DISTINCT fp.food_id) FILTER (WHERE fp.modifier ~* '\m(small|medium|large|jumbo|mini|miniature)\M') AS foods_with_size,
  count(DISTINCT fp.food_id) FILTER (WHERE fp.modifier ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M') AS foods_with_container,
  count(DISTINCT fp.food_id) FILTER (WHERE fp.modifier ~* '\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M') AS foods_with_piece,
  count(DISTINCT fp.food_id) FILTER (WHERE fp.modifier ~* '\m(small|medium|large|jumbo|mini|miniature)\M' OR fp.modifier ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M' OR fp.modifier ~* '\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M') AS foods_with_any_class,
  count(DISTINCT fp.food_id) FILTER (WHERE fp.modifier ~* '\mextra (small|large)\M') AS foods_with_extra_size
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE fp.portion_description IS NULL AND f.source = 'fdc_sr_legacy' AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '';
-- 7533 | 247 | 3990 | 1687 | 5289 | 13
```

The SIZE class is thin at the top and long in the tail: `medium` 66 foods,
`large` 60, `small` 51, then bagel and cookie sizes with their diameters.

```sql
SELECT fp.modifier, count(DISTINCT fp.food_id) AS foods, count(*) AS rows
FROM food_portion fp
WHERE fp.portion_description IS NULL AND fp.modifier ~* '\m(small|medium|large|jumbo|mini|miniature)\M'
GROUP BY 1 ORDER BY 2 DESC, 1 LIMIT 25;
-- medium 66 ; large 60 ; small 51 ; mini bagel (2-1/2" dia) 9 ; slice, large 8 ; small bagel (3" dia) 8 ; large bagel (4-1/2" dia) 7 ;
-- medium bagel (3-1/2" to 4" dia) 7 ; cookie, medium (2-1/4" dia) 5 ; medium (2-1/2" dia) 5 ; … extra large 4 ; drink, extra large (44 fl oz) 3
```

### The count lives in `amount`

The leading count is never in the text. On SR Legacy `amount` is never
`NULL`; 10,985 of 14,449 rows (76%) have `amount = 1`, on 6,614 foods, and
3,464 rows have another value — 2,786 above 1, 660 fractions, 18 exactly 0.
There are 63 distinct amounts.

| `amount` | Rows | Foods | What it mostly is |
| ---: | ---: | ---: | --- |
| 1 | 10,985 | 6,614 | everything |
| 3 | 1,556 | 1,554 | `oz` (1,431) |
| 4 | 669 | 669 | `oz` (638) |
| 0.5 | 467 | 462 | `cup` 148, `oz` 44, `fillet` 41 |
| 2 | 160 | 157 | `tbsp` 37, `oz` 30 |
| 10 | 106 | 98 | |
| 8 | 77 | 76 | `fl oz` (59) |
| 0.25 | 69 | 69 | `cup` (46) |
| 0.75 | 58 | 58 | `cup (1 NLEA serving)` (47) |
| 6 | 55 | 55 | `inch sub` (22) |
| 5 | 37 | 34 | |
| 12 | 37 | 37 | `inch sub` (22) |
| 0.33 | 31 | 31 | |
| 0 | 18 | 18 | see below |
| 1.5 | 17 | 17 | |
| 0.2 | 14 | 14 | |
| 16 | 11 | 11 | |

```sql
SELECT f.source,
  count(*) AS rows,
  count(*) FILTER (WHERE fp.amount IS NULL) AS amount_null,
  count(*) FILTER (WHERE fp.amount = 1) AS amount_1,
  count(*) FILTER (WHERE fp.amount IS NOT NULL AND fp.amount <> 1) AS amount_other,
  count(*) FILTER (WHERE fp.amount > 0 AND fp.amount < 1) AS amount_fraction,
  count(*) FILTER (WHERE fp.amount > 1) AS amount_gt_1,
  count(*) FILTER (WHERE fp.amount = 0) AS amount_zero,
  count(DISTINCT fp.amount) AS distinct_amounts
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE fp.portion_description IS NULL
GROUP BY 1 ORDER BY 2 DESC;
-- fdc_sr_legacy 14449 | 0 | 10985 | 3464 | 660 | 2786 | 18 | 63
-- fdc_foundation 186 | 0 | 169 | 17 | 4 | 13 | 0 | 8

SELECT fp.amount, count(*) AS rows, count(DISTINCT fp.food_id) AS foods
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE fp.portion_description IS NULL AND f.source = 'fdc_sr_legacy'
GROUP BY 1 ORDER BY 2 DESC LIMIT 20;
-- 1 10985 | 6614 ; 3 1556 | 1554 ; 4 669 | 669 ; 0.5 467 | 462 ; 2 160 | 157 ; 10 106 | 98 ; 8 77 | 76 ; 0.25 69 | 69 ; 0.75 58 | 58 ;
-- 6 55 | 55 ; 5 37 | 34 ; 12 37 | 37 ; 0.33 31 | 31 ; 0 18 | 18 ; 1.5 17 | 17 ; 0.2 14 | 14 ; 16 11 | 11 ; 0.08 5 | 5 ; 0.16 5 | 5 ; 1.25 5 | 5

SELECT fp.amount, fp.modifier, count(*) AS rows
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE fp.portion_description IS NULL AND f.source = 'fdc_sr_legacy' AND fp.amount <> 1
GROUP BY 1, 2 ORDER BY 3 DESC LIMIT 15;
-- 3 oz 1431 ; 4 oz 638 ; 0.5 cup 148 ; 8 fl oz 59 ; 0.75 cup (1 NLEA serving) 47 ; 0.25 cup 46 ; 0.5 oz 44 ; 0.5 fillet 41 ;
-- 2 tbsp 37 ; 3 oz (3 oz) 35 ; 2 oz 30 ; 6 inch sub 22 ; 0.5 cup (4 fl oz) 22 ; 0.5 cup slices 22 ; 12 inch sub 22
```

The 18 `amount = 0` rows all have a positive `gram_weight` (7–864 g): seven
`cup` rows on babyfood, flan and rennin desserts, chicken `back, bone and
skin removed` / `breast …` / `skin only` parts, kale `package (10 oz)` and
yogurt `container (4 oz)`.

```sql
SELECT f.source, f.description, fp.amount, fp.modifier, fp.gram_weight
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE fp.portion_description IS NULL AND fp.amount = 0
ORDER BY 1, 2 LIMIT 18;
-- 18 SR Legacy rows, gram_weight 7..864: cup (x7 babyfood/flan/rennin), back/breast/chicken bone removed, chicken skin only, package (10 oz), container (4 oz)
```

The backend already synthesises the count in one place. `food_summary`,
the view the search reads, composes `serving_size` as the description or,
failing that, `amount` and `modifier` joined with a space — which is how an
SR Legacy food shows one sensible default (`3 oz`, `0.5 cup`) in the app
today while offering no portion list. `amount::text` renders `1`, `3`,
`0.5`, `0.33` on SR Legacy with no trailing `.0`, and puts a leading `0` on
the 18 zero rows (`0 cup`, `0 container (4 oz)`).

```sql
SELECT pg_get_viewdef('food_summary'::regclass, true);
-- serving_size = COALESCE(NULLIF(p.portion_description, ''),
--                         CASE WHEN NULLIF(p.modifier, '') IS NOT NULL THEN TRIM(concat_ws(' ', p.amount::text, p.modifier)) END)

WITH sr AS (SELECT fp.amount FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_sr_legacy')
SELECT amount::text AS rendered, count(*) FROM sr GROUP BY 1 ORDER BY 2 DESC LIMIT 12;
-- 1, 3, 4, 0.5, 2, 10, 8, 0.25, 0.75, 6, 5, 12 — no trailing .0 (Foundation amounts render 1.0)
```

### A modifier can repeat within a food

Survey rows never carry the same label twice on one food (#1155). SR Legacy
rows do: 309 food/modifier pairs on 630 rows, distinguished by `amount` or,
failing that, by grams alone. *Veal, ground, raw* (175290) has `oz` three times at amounts 3, 1,
4 = 85 g, 28.35 g, 113 g; *Bread, white, commercially prepared* (174924) has
`slice` at `seq_num` 1 = 29 g and `seq_num` 6 = 25 g; a fast-food boneless
chicken record has `pieces` at 6, 4, 10 and 20.

```sql
SELECT count(*) AS food_modifier_pairs_repeated, sum(n) AS rows_involved, count(DISTINCT food_id) AS foods
FROM (SELECT food_id, modifier, count(*) AS n FROM food_portion
      WHERE portion_description IS NULL AND modifier IS NOT NULL GROUP BY 1, 2 HAVING count(*) > 1) d;
-- 309 | 630 | 309

SELECT fp.food_id, f.description, fp.modifier, count(*) AS n, array_agg(fp.amount ORDER BY fp.seq_num) AS amounts, array_agg(fp.gram_weight ORDER BY fp.seq_num) AS grams
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE fp.portion_description IS NULL AND fp.modifier IS NOT NULL
GROUP BY 1, 2, 3 HAVING count(*) > 1 ORDER BY 4 DESC, 1 LIMIT 12;
-- e.g. 175290 Veal, ground, raw | oz | 3 | {3,1,4} | {85,28.35,113} ; 170718 Fast foods, chicken … boneless pieces | pieces | 4 | {6,4,10,20} | {96,64,160,320}
```

### Examples on recognisable foods

Each line is an SR Legacy record's NULL-description rows as `amount`,
`modifier`, `gram_weight`, with the survey record #1155 tabulated beside it
where one exists.

- **Bananas, raw** (173944): `1 cup, mashed` 225 g; `1 cup, sliced` 150 g;
  `1 extra small (less than 6" long)` 81 g; `1 small (6" to 6-7/8" long)`
  101 g; `1 medium (7" to 7-7/8" long)` 118 g; `1 large (8" to 8-7/8" long)`
  136 g; `1 extra large (9" or longer)` 152 g; `1 NLEA serving` 126 g. Survey
  *Banana, raw* (2709224) has `1 cup, mashed` 225 g and `1 banana` 126 g, and
  no size word.
- **Apples, raw, with skin** (171688): `1 medium (3" dia)` 182 g; `1 large
  (3-1/4" dia)` 223 g; `1 extra small (2-1/2" dia)` 101 g. Survey *Apple,
  raw* (2709215) says `1 medium` 200 g, `1 large` 242 g.
- **Egg, whole, raw, fresh** (171287): `1 large` 50 g; `1 extra large` 56 g;
  `1 jumbo` 63 g; `1 medium` 44 g; `1 small` 38 g; `1 cup (4.86 large eggs)`
  243 g. Survey *Egg, whole, raw* (2707152) has only `1 egg` 50 g and `1 cup`
  245 g.
- **Bread, white, commercially prepared (includes soft bread crumbs)**
  (174924): `slice` twice (29 g at seq 1, 25 g at seq 6); `slice, large` 30
  g; `slice, thin` 20 g; `slice, very thin` 15 g; `slice crust not eaten` 12
  g; `oz` 28.35 g. Survey *Bread, white* (2707598) says `1 small or thin/very
  thin slice` 24 g, `1 medium or regular slice` 28 g.
- **Milk, whole, 3.25% milkfat, with added vitamin D** (171265): `1 cup` 244
  g; `1 fl oz` 30.5 g; `1 tbsp` 15 g; `1 quart` 976 g.
- **Chicken, broilers or fryers, breast, meat only, cooked, roasted**
  (171477): `1 cup, chopped or diced` 140 g; `1 unit (yield from 1 lb
  ready-to-cook chicken)` 52 g; `0.5 breast, bone and skin removed` 86 g.
- **Lettuce, iceberg (includes crisphead types), raw** (169248): `1 head,
  large` 755 g; `1 head, medium (6" dia)` 539 g; `1 head, small` 324 g; `1
  leaf, large` 15 g; `1 leaf, medium` 8 g; `1 leaf, small` 5 g; `1 cup
  shredded` 72 g; `1 NLEA Serving` 89 g.
- **Onions, raw** (170000): `10 rings` 60 g — the count only in `amount`;
  `1 slice, large (1/4" thick)` 38 g; `1 medium (2-1/2" dia)` 110 g; `1
  slice, thin` 9 g.
- **Potatoes, baked, flesh and skin, without salt** (170093): `1 potato
  large` 299 g; `1 potato medium` 173 g; `1 potato small` 138 g; `1 NLEA
  serving` 148 g — the noun before the size.
- **Pasta, cooked, enriched, without added salt** (169737): `1 cup spaghetti
  not packed` 124 g; `1 cup spaghetti packed` 151 g; `1 cup penne` 107 g; `1
  cup lasagne` 116 g.
- **Yogurt, plain, whole milk** (171284): `1 container (6 oz)` 170 g; `1
  container (8 oz)` 227 g; `0.5 container (4 oz)` 113 g; `1 cup (8 fl oz)`
  245 g.
- **Nuts, almonds** (170567): `1 oz (23 whole kernels)` 28.35 g; `1 almond`
  1.2 g; `1 cup, whole` 143 g; `1 cup, slivered` 108 g.
- **Cheese, cheddar** (173414): `1 cubic inch` 17 g; `1 slice (1 oz)` 28 g;
  `1 cup, shredded` 113 g; `1 cup, melted` 244 g; `1 oz` 28.35 g.
- **Pizza, cheese topping, regular crust, frozen, cooked** (170317): `1
  serving 9 servings per 24 oz package` 81 g; `1 package 24 oz pizza` 727 g —
  no `slice` row.
- **Babyfood, dinner, chicken and rice**: `1 jar NFS` 113 g, one of 24 `NFS`
  rows; **Avocados, raw, all commercial varieties**: `1 avocado, NS as to
  Florida or California` 201 g, the single `NS as to` row.
- **Nectarines, raw** (Foundation): `1` with modifier `2-1/2" dia` 142 g and
  `2-3/4" dia` 156 g — the digit-leading modifiers are dimensions.

```sql
SELECT f.id, f.source, f.description, fp.seq_num, fp.amount, fp.modifier, fp.gram_weight
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE fp.portion_description IS NULL AND f.source = 'fdc_sr_legacy'
  AND f.description IN ('Bananas, raw', 'Apples, raw, with skin', 'Egg, whole, raw, fresh', 'Bread, white, commercially prepared',
                        'Rice, white, long-grain, regular, enriched, cooked', 'Milk, whole, 3.25% milkfat, with added vitamin D',
                        'Chicken, broilers or fryers, breast, meat only, cooked, roasted', 'Almonds', 'Coffee, brewed from grounds, prepared with tap water',
                        'Lettuce, iceberg (includes crisphead types), raw', 'Yogurt, plain, whole milk', 'Pasta, cooked, enriched, without added salt',
                        'Pizza, cheese topping, regular crust, frozen, cooked', 'Carrots, raw', 'Cheese, cheddar', 'Onions, raw', 'Potatoes, baked, flesh and skin, without salt')
ORDER BY f.description, fp.seq_num NULLS LAST, fp.id;
-- 75 rows; 173944 Bananas, raw: 1 cup, mashed 225 ; 1 cup, sliced 150 ; 1 extra small (less than 6" long) 81 ; 1 small (6" to 6-7/8" long) 101 ;
-- 1 medium (7" to 7-7/8" long) 118 ; 1 large (8" to 8-7/8" long) 136 ; 1 extra large (9" or longer) 152 ; 1 NLEA serving 126

SELECT f.id, f.description, fp.seq_num, fp.amount, fp.modifier, fp.gram_weight
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE fp.portion_description IS NULL AND f.source = 'fdc_sr_legacy'
  AND (f.description LIKE 'Apples, raw, with skin%' OR f.description LIKE 'Bread, white, commercially prepared%' OR f.description = 'Nuts, almonds'
       OR f.description LIKE 'Coffee, brewed from grounds%' OR f.description LIKE 'Cheese, cheddar%')
ORDER BY f.description, fp.seq_num NULLS LAST, fp.id;
-- 51 rows; 174924 Bread, white, commercially prepared (includes soft bread crumbs): seq 1 slice 29 ; seq 6 slice 25 ; slice, very thin 15 ; oz 28.35

SELECT f.id, f.description, fp.seq_num, fp.amount, fp.portion_description, fp.modifier, fp.gram_weight
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE f.source = 'fdc_survey' AND f.id IN (2709224, 2709215, 2707152, 2707598)
ORDER BY f.description, fp.seq_num NULLS LAST, fp.id;
-- 25 rows; Banana, raw: 1 banana | 60343 | 126 ; 1 cup, mashed | 10118 | 225 ; Apple, raw: 1 small 165, 1 medium 200, 1 large 242, 1 extra large 295 ;
-- Egg, whole, raw: 1 egg 50, 1 cup 245   (survey amount is NULL; the FNDDS code sits in modifier)

SELECT f.source, f.description, fp.amount, fp.modifier, fp.gram_weight
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE fp.portion_description IS NULL AND (fp.modifier ~* '\mNFS\M' OR fp.modifier ~* '\mNS as to\M')
ORDER BY fp.modifier LIMIT 30;
-- 25 rows, all fdc_sr_legacy, amount 1: 1 avocado, NS as to Florida or California ; 7 bottle NFS ; 16 jar NFS (babyfood) ; 1 slice NFS (deli turkey)
```

## What a COALESCE would expose

### The RPC as it is

`portions_by_food_ids(ids bigint[], loc text)` returns `(food_id, seq, label,
localized, gram_weight)`. Its label is `coalesce(t.portion_description,
fp.portion_description)`, where `t` is a `LEFT JOIN food_portion_translation`
on `locale = loc AND source = 'verified'` with a non-blank description;
`localized` is `t.portion_description IS NOT NULL`; `seq` is `row_number()
over (partition by fp.food_id order by fp.seq_num nulls last, fp.id)`; and
the output is ordered the same way. `fp.modifier` is not read anywhere in
the body. All 14,449 SR Legacy rows have `seq_num` set, so the order a
COALESCE would deliver them in is FDC's own.

```sql
SELECT pg_get_functiondef(p.oid) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'portions_by_food_ids';
-- label = coalesce(t.portion_description, fp.portion_description)
-- where fp.portion_description is not null and fp.portion_description <> 'Quantity not specified'
--   and fp.gram_weight is not null and fp.gram_weight > 0
--   and fp.portion_description !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount'
-- order by fp.food_id, fp.seq_num nulls last, fp.id

SELECT count(*) FILTER (WHERE fp.seq_num IS NULL) AS seq_null, count(*) FILTER (WHERE fp.seq_num IS NOT NULL) AS seq_set
FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_sr_legacy';
-- 0 | 14449
```

On the app side, `fetchPortions` in
[`sp_food_data_source.dart`](../lib/features/add_meal/data/data_sources/sp_food_data_source.dart)
keeps `label`, `gram_weight` and `localized` from each row and nothing else;
`amount` does not travel. Whatever the RPC puts in `label` is what the user
reads and what the matcher tokenises.

### The simulation

Substituting `coalesce(fp.portion_description, fp.modifier)` for the label
and keeping the RPC's filter otherwise unchanged:

| | Rows | Foods |
| --- | ---: | ---: |
| SR Legacy rows with a non-blank coalesced label | 14,449 | 7,533 |
| … passing the RPC filter | **14,341** | **7,529** |
| … passing the #1155 predicate instead | 14,342 | 7,529 |
| Foundation rows passing the RPC filter | 94 | 53 |
| Foundation rows with a `NULL` label (dropped) | 92 | — |

```sql
WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_sr_legacy')
SELECT count(*) AS sr_rows, count(DISTINCT food_id) AS sr_foods,
       count(*) FILTER (WHERE label IS NOT NULL AND btrim(label) <> '') AS label_nonblank,
       count(DISTINCT food_id) FILTER (WHERE label IS NOT NULL AND btrim(label) <> '') AS foods_label_nonblank,
       count(*) FILTER (WHERE label IS NOT NULL AND label <> 'Quantity not specified' AND gram_weight IS NOT NULL AND gram_weight > 0 AND label !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount') AS rpc_pass_rows,
       count(DISTINCT food_id) FILTER (WHERE label IS NOT NULL AND label <> 'Quantity not specified' AND gram_weight IS NOT NULL AND gram_weight > 0 AND label !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount') AS rpc_pass_foods
FROM sr;
-- 14449 | 7533 | 14449 | 7533 | 14341 | 7529

WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_sr_legacy')
SELECT count(*) FILTER (WHERE NOT (label IS NULL OR btrim(label) = '' OR label ILIKE '%quantity not specified%' OR label ILIKE '%NFS%' OR label ILIKE '%yields%' OR label ILIKE '%NS as to size%')) AS usable_rows_ticket,
       count(DISTINCT food_id) FILTER (WHERE NOT (label IS NULL OR btrim(label) = '' OR label ILIKE '%quantity not specified%' OR label ILIKE '%NFS%' OR label ILIKE '%yields%' OR label ILIKE '%NS as to size%')) AS usable_foods_ticket
FROM sr;
-- 14342 | 7529

WITH c AS (
  SELECT fp.food_id, f.source, COALESCE(fp.portion_description, fp.modifier) AS label, fp.gram_weight
  FROM food_portion fp JOIN food f ON f.id = fp.food_id
  WHERE fp.portion_description IS NULL)
SELECT source,
  count(*) FILTER (WHERE label IS NOT NULL AND label <> 'Quantity not specified' AND gram_weight IS NOT NULL AND gram_weight > 0
                     AND label !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount') AS rows_delivered,
  count(DISTINCT food_id) FILTER (WHERE label IS NOT NULL AND label <> 'Quantity not specified' AND gram_weight IS NOT NULL AND gram_weight > 0
                     AND label !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount') AS foods_delivered,
  count(*) FILTER (WHERE label ~* '\myields\M') AS dropped_by_yields_regex,
  count(*) FILTER (WHERE label ~* '\myield\M' AND label !~* '\myields\M') AS yield_singular_not_dropped
FROM c GROUP BY 1 ORDER BY 2 DESC;
-- fdc_sr_legacy 14341 | 7529 | 83 | 626 ; fdc_foundation 94 | 53 | 0 | 0
```

The four SR Legacy foods that gain nothing are the ones whose only rows are
bookkeeping. The 108 SR Legacy rows the RPC filter drops are, by reason:

| Reason | Rows |
| --- | ---: |
| `gram_weight` `NULL` or ≤ 0 | 0 |
| `= 'Quantity not specified'` | 0 |
| `\mNFS\M` | 24 |
| `\mNS as to\M` | 1 |
| `\myields\M` | 83 |
| `^Guideline amount` | 0 |
| **Dropped** | **108** |

```sql
WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_sr_legacy')
SELECT count(*) FILTER (WHERE gram_weight IS NULL) AS gw_null, count(*) FILTER (WHERE gram_weight <= 0) AS gw_nonpositive,
       count(*) FILTER (WHERE label = 'Quantity not specified') AS qns_exact,
       count(*) FILTER (WHERE label ~* '\mNFS\M') AS nfs, count(*) FILTER (WHERE label ~* '\mNS as to\M') AS ns_as_to,
       count(*) FILTER (WHERE label ~* '\myields\M') AS yields, count(*) FILTER (WHERE label ~* '^Guideline amount') AS guideline,
       count(*) FILTER (WHERE NOT (label IS NOT NULL AND label <> 'Quantity not specified' AND gram_weight IS NOT NULL AND gram_weight > 0 AND label !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount')) AS dropped_total
FROM sr;
-- 0 | 0 | 0 | 24 | 1 | 83 | 0 | 108
```

### Bookkeeping

The RPC's regex and #1155's `ILIKE` predicate agree on every `NFS` and
`yields` row (24 and 83) and differ on one: `avocado, NS as to Florida or
California`, which `\mNS as to\M` drops and `ILIKE '%NS as to size%'` keeps.
There is no `Quantity not specified`, no blank and no `Guideline amount`
anywhere in the SR Legacy modifier.

```sql
WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_sr_legacy')
SELECT count(*) FILTER (WHERE label IS NULL OR btrim(label) = '') AS blank,
       count(*) FILTER (WHERE label ILIKE '%quantity not specified%') AS qns_ilike,
       count(*) FILTER (WHERE label ILIKE '%NFS%') AS nfs_ilike, count(*) FILTER (WHERE label ~* '\mNFS\M') AS nfs_regex,
       count(*) FILTER (WHERE label ILIKE '%yields%') AS yields_ilike, count(*) FILTER (WHERE label ~* '\myields\M') AS yields_regex,
       count(*) FILTER (WHERE label ILIKE '%NS as to size%') AS ns_size_ilike, count(*) FILTER (WHERE label ~* '\mNS as to\M') AS ns_as_to_regex,
       count(*) FILTER (WHERE label ~* '^Guideline amount') AS guideline,
       count(*) FILTER (WHERE label IS NULL OR btrim(label) = '' OR label ILIKE '%quantity not specified%' OR label ILIKE '%NFS%' OR label ILIKE '%yields%' OR label ILIKE '%NS as to size%') AS ticket_bookkeeping,
       count(*) FILTER (WHERE label = 'Quantity not specified' OR label ~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount') AS rpc_bookkeeping
FROM sr;
-- 0 | 0 | 24 | 24 | 83 | 83 | 0 | 1 | 0 | 107 | 108

WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_sr_legacy')
SELECT label, gram_weight, count(*) AS rows FROM sr
WHERE NOT (label IS NOT NULL AND label <> 'Quantity not specified' AND gram_weight IS NOT NULL AND gram_weight > 0 AND label !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount')
GROUP BY 1,2 ORDER BY 3 DESC, 1 LIMIT 40;
-- jar NFS (13 rows at one weight, 16 in all) ; package (10 oz) yields (32 rows across weights) ; ear, yields (9) ; bottle NFS (7) ;
-- package (9 oz), yields ; cup, fluid (yields 2 cups whipped) ; avocado, NS as to Florida or California (1) ; slice NFS (1)
```

What neither filter catches is the singular. 626 deliverable rows on 613
foods say `yield from` or `yield` inside a parenthetical — `piece, cooked,
excluding refuse (yield from 1 lb raw meat with refuse)` 212 rows, `unit
(yield from 1 lb ready-to-cook chicken)` 106, `unit, cooked (yield from 1 lb
raw meat)` 33, `piece, cooked (yield from 1 lb raw meat, boneless)` 20,
`chop, excluding refuse (yield from 1 raw chop, with refuse, weighing 113
g)` 11, `unit (yield from 1 lb ready-to-cook duck)` 11, `package yield (2
cups)` 10, `recipe yield` 9. 593 of the 626 have the word only inside the
parenthetical, so after `_termsOf` strips it they read as `piece, cooked,
excluding refuse`, `unit`, `unit, cooked`, `chop, excluding refuse`. Beside
them, 307 rows say `refuse`, 196 say `NLEA` and 58 say `approx`.

```sql
WITH sr AS (SELECT fp.id, fp.food_id, fp.modifier AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND fp.gram_weight > 0 AND fp.modifier !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount')
SELECT count(*) FILTER (WHERE label ~* '\myield\M') AS yield_singular_rows,
       count(DISTINCT food_id) FILTER (WHERE label ~* '\myield\M') AS yield_singular_foods,
       count(*) FILTER (WHERE label ~* '\myield\M' AND regexp_replace(label, '\([^)]*\)', ' ', 'g') !~* '\myield\M') AS yield_only_inside_parenthetical,
       count(*) FILTER (WHERE label ~* '\mrefuse\M') AS refuse_rows,
       count(*) FILTER (WHERE label ~* '\mNLEA\M') AS nlea_rows,
       count(*) FILTER (WHERE label ~* '\mapprox') AS approx_rows,
       count(*) FILTER (WHERE label ~* 'not specified|unspecified|undetermined|\mNS\M') AS ns_family_rows
FROM sr;
-- 626 | 613 | 593 | 307 | 196 | 58 | 0

WITH sr AS (SELECT fp.id, fp.food_id, fp.modifier AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND fp.gram_weight > 0 AND fp.modifier !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount')
SELECT label, count(*) AS rows FROM sr WHERE label ~* '\myield\M' GROUP BY 1 ORDER BY 2 DESC LIMIT 12;
-- piece, cooked, excluding refuse (yield from 1 lb raw meat with refuse) 212 ; unit (yield from 1 lb ready-to-cook chicken) 106 ;
-- unit, cooked (yield from 1 lb raw meat) 33 ; piece, cooked (yield from 1 lb raw meat, boneless) 20 ;
-- chop, excluding refuse (yield from 1 raw chop, with refuse, weighing 113 g) 11 ; unit (yield from 1 lb ready-to-cook duck) 11 ;
-- package yield (2 cups) 10 ; recipe yield 9
```

### Bare units

No deliverable label is a bare number, and none is a number followed by a
unit — the count is never in the text. But 3,951 rows on 3,494 foods are a
bare weight or volume unit and nothing else (`oz` 3,166, `fl oz` 492, `lb`
281, `ml` 8, `liter` 3, `g` 1); after the matcher's parenthetical strip, 79
more join them (`oz (3 oz)`, `oz (1 serving)`, `oz (28 almonds)`), 4,030
rows on 3,569 foods — 80 labels open a parenthesis right after a unit, but
`lb (with shell), yield after shell removed` keeps its tail once the
parenthetical is gone and is not one of the 79. Of the 4,030, 4,027 have no
run of three or more letters left; the 3 `liter` rows are the only bare
unit that tokenises. `lb 16 oz`, not a bare unit, has no such run either,
so 4,028 rows on 3,569 foods yield no term: `_termsOf` finds nothing, the
matcher can never pick them, and `fetchPortions` would still list them.
Counting `cubic inch` as a unit too, 1,026 SR Legacy
foods have nothing but bare units in `modifier`. On the deliverable rows,
1,028 of the 7,529 foods carry only the five bare units `oz`, `fl oz`, `lb`,
`g` and `ml`, and 1,042 have no row at all that yields a term — the food
would list portions and the matcher could never pick one.

| Label | Rows | Foods | `amount` range | `gram_weight` range |
| --- | ---: | ---: | --- | --- |
| `oz` | 3,166 | 3,041 | 0.35–8 | 9.9–227 g |
| `fl oz` | 492 | 440 | 1–20 | |
| `lb` | 281 | 281 | 0.25–1 | |
| `ml` | 8 | 8 | 1–240 | |
| `liter` | 3 | 3 | | |
| `g` | 1 | 1 | 45 | |

```sql
WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label,
                   btrim(regexp_replace(coalesce(fp.portion_description, fp.modifier), '\([^)]*\)', ' ', 'g')) AS stripped
            FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND coalesce(fp.portion_description, fp.modifier) IS NOT NULL
              AND coalesce(fp.portion_description, fp.modifier) <> 'Quantity not specified' AND fp.gram_weight IS NOT NULL AND fp.gram_weight > 0
              AND coalesce(fp.portion_description, fp.modifier) !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount')
SELECT count(*) AS delivered_rows, count(DISTINCT food_id) AS delivered_foods,
       count(*) FILTER (WHERE label ~ '^\s*[0-9][0-9./ -]*\s*$') AS bare_number_raw,
       count(*) FILTER (WHERE stripped ~ '^[0-9][0-9./ -]*$') AS bare_number_stripped,
       count(*) FILTER (WHERE btrim(label) ~* '^(oz|fl oz|fl\.? ?oz\.?|lb|lbs|g|kg|mg|ml|l|gram|grams|ounce|ounces|pound|pounds|liter|liters|litre|litres|gallon|gallons)$') AS bare_unit_raw,
       count(DISTINCT food_id) FILTER (WHERE btrim(label) ~* '^(oz|fl oz|fl\.? ?oz\.?|lb|lbs|g|kg|mg|ml|l|gram|grams|ounce|ounces|pound|pounds|liter|liters|litre|litres|gallon|gallons)$') AS bare_unit_raw_foods,
       count(*) FILTER (WHERE stripped ~* '^(oz|fl oz|fl\.? ?oz\.?|lb|lbs|g|kg|mg|ml|l|gram|grams|ounce|ounces|pound|pounds|liter|liters|litre|litres|gallon|gallons)$') AS bare_unit_stripped,
       count(DISTINCT food_id) FILTER (WHERE stripped ~* '^(oz|fl oz|fl\.? ?oz\.?|lb|lbs|g|kg|mg|ml|l|gram|grams|ounce|ounces|pound|pounds|liter|liters|litre|litres|gallon|gallons)$') AS bare_unit_stripped_foods,
       count(*) FILTER (WHERE btrim(label) ~* '^[0-9][0-9./ -]*\s*(oz|fl oz|fl\.? ?oz\.?|lb|lbs|g|kg|mg|ml|l|gram|grams|ounce|ounces|pound|pounds|liter|liters|litre|litres|gallon|gallons|cups?|tbsp|tsp|tablespoons?|teaspoons?|pints?|quarts?)\.?$') AS number_unit_raw,
       count(*) FILTER (WHERE stripped ~* '^[0-9][0-9./ -]*\s*(oz|fl oz|fl\.? ?oz\.?|lb|lbs|g|kg|mg|ml|l|gram|grams|ounce|ounces|pound|pounds|liter|liters|litre|litres|gallon|gallons|cups?|tbsp|tsp|tablespoons?|teaspoons?|pints?|quarts?)\.?$') AS number_unit_stripped,
       count(*) FILTER (WHERE btrim(label) ~* '^(oz|fl oz|lb|g|ml|kg)\s*\(') AS unit_then_parenthetical
FROM sr;
-- 14341 | 7529 | 0 | 0 | 3951 | 3494 | 4030 | 3569 | 0 | 0 | 80

WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label,
                   btrim(regexp_replace(coalesce(fp.portion_description, fp.modifier), '\([^)]*\)', ' ', 'g')) AS stripped
            FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND coalesce(fp.portion_description, fp.modifier) IS NOT NULL
              AND coalesce(fp.portion_description, fp.modifier) <> 'Quantity not specified' AND fp.gram_weight IS NOT NULL AND fp.gram_weight > 0
              AND coalesce(fp.portion_description, fp.modifier) !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount')
SELECT count(*) AS joined_by_strip, count(DISTINCT food_id) AS joined_foods, string_agg(DISTINCT label, ' ; ') AS labels
FROM sr WHERE stripped ~* '^(oz|fl oz|fl\.? ?oz\.?|lb|lbs|g|kg|mg|ml|l|gram|grams|ounce|ounces|pound|pounds|liter|liters|litre|litres|gallon|gallons)$'
  AND btrim(label) !~* '^(oz|fl oz|fl\.? ?oz\.?|lb|lbs|g|kg|mg|ml|l|gram|grams|ounce|ounces|pound|pounds|liter|liters|litre|litres|gallon|gallons)$';
-- 79 | 79 | fl oz (1 NLEA serving) ; fl oz (1 serving) ; fl oz (approximate weight, 1 serving) ; oz ( 1 serving  ) ; oz ( 1 serving ) ; oz ( 1serving ) ;
-- oz (1 serving) ; oz (10-12 kernels) ; oz (14 halves) ; oz (14 kernels) ; oz (15 halves) ; oz (15 kernels) ; oz (167 kernels) ; oz (18 kernels) ;
-- oz (19 halves) ; oz (21 whole kernels) ; oz (22 whole kernels) ; oz (23 whole kernels) ; oz (28 almonds) ; oz (3 oz) ; oz (4 oz) ;
-- oz (42 medium seeds) ; oz (49 kernels) ; oz (6 kernels) ; oz (60 raisins) ; oz (8-14 seeds) ; oz (85 seeds) ;
-- oz (Yield from 1 cooked roast, with refuse, weighing 1515g) ; oz (approx 2/3 cup) ; oz (approx 60 pcs)

WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label,
                   btrim(regexp_replace(coalesce(fp.portion_description, fp.modifier), '\([^)]*\)', ' ', 'g')) AS stripped
            FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND coalesce(fp.portion_description, fp.modifier) IS NOT NULL
              AND coalesce(fp.portion_description, fp.modifier) <> 'Quantity not specified' AND fp.gram_weight IS NOT NULL AND fp.gram_weight > 0
              AND coalesce(fp.portion_description, fp.modifier) !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount')
SELECT label, stripped, count(*) AS rows FROM sr
WHERE btrim(label) ~* '^(oz|fl oz|lb|g|ml|kg)\s*\('
  AND stripped !~* '^(oz|fl oz|fl\.? ?oz\.?|lb|lbs|g|kg|mg|ml|l|gram|grams|ounce|ounces|pound|pounds|liter|liters|litre|litres|gallon|gallons)$'
GROUP BY 1,2;
-- lb (with shell), yield after shell removed | lb  , yield after shell removed | 1

WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND fp.gram_weight > 0 AND coalesce(fp.portion_description, fp.modifier) !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount')
SELECT label, count(*) AS rows, count(DISTINCT food_id) AS foods, min(amount) AS min_amount, max(amount) AS max_amount, min(gram_weight) AS min_g, max(gram_weight) AS max_g
FROM sr WHERE btrim(label) ~* '^(oz|fl oz|fl\.? ?oz\.?|lb|lbs|g|kg|mg|ml|l|gram|grams|ounce|ounces|pound|pounds|liter|liters|litre|litres|gallon|gallons)$'
GROUP BY 1 ORDER BY 2 DESC;
-- oz 3166 | 3041 | 0.35 | 8 | 9.9 | 227 ; fl oz 492 | 440 | 1 | 20 ; lb 281 | 281 | 0.25 | 1 ; ml 8 | 8 | 1 | 240 ; liter 3 | 3 ; g 1 | 1 | 45

WITH sr AS (SELECT fp.id, fp.food_id, fp.modifier AS label, regexp_replace(fp.modifier, '\([^)]*\)', ' ', 'g') AS matchable
            FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND fp.gram_weight > 0 AND fp.modifier !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount')
SELECT count(*) AS rows_no_term, count(DISTINCT food_id) AS foods_no_term, string_agg(DISTINCT label, ' ; ' ORDER BY label) AS labels
FROM sr WHERE NOT EXISTS (SELECT 1 FROM regexp_split_to_table(matchable, '[^[:alpha:]]+') t WHERE length(t) >= 3);
-- 4028 | 3569 | oz ; fl oz ; lb ; g ; ml ; lb 16 oz ; oz (3 oz) ; oz (1 serving) ; oz (28 almonds) ; …

WITH sr AS (SELECT fp.id, fp.food_id, fp.modifier AS label, btrim(regexp_replace(fp.modifier, '\([^)]*\)', ' ', 'g')) AS stripped,
                   EXISTS (SELECT 1 FROM regexp_split_to_table(regexp_replace(fp.modifier, '\([^)]*\)', ' ', 'g'), '[^[:alpha:]]+') t WHERE length(t) >= 3) AS has_term
            FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND fp.gram_weight > 0 AND fp.modifier !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount'),
     bu AS (SELECT *, stripped ~* '^(oz|fl oz|fl\.? ?oz\.?|lb|lbs|g|kg|mg|ml|l|gram|grams|ounce|ounces|pound|pounds|liter|liters|litre|litres|gallon|gallons)$' AS bare_unit_stripped FROM sr)
SELECT count(*) FILTER (WHERE bare_unit_stripped) AS bare_unit_stripped_rows,
       count(DISTINCT food_id) FILTER (WHERE bare_unit_stripped) AS bare_unit_stripped_foods,
       count(*) FILTER (WHERE bare_unit_stripped AND NOT has_term) AS of_those_no_term,
       count(*) FILTER (WHERE NOT has_term) AS no_term_rows,
       count(DISTINCT food_id) FILTER (WHERE NOT has_term) AS no_term_foods,
       count(*) FILTER (WHERE NOT has_term AND NOT bare_unit_stripped) AS no_term_but_not_bare_unit,
       string_agg(DISTINCT label, ' ; ') FILTER (WHERE NOT has_term AND NOT bare_unit_stripped) AS those_labels,
       string_agg(DISTINCT label, ' ; ') FILTER (WHERE bare_unit_stripped AND has_term) AS bare_units_with_term
FROM bu;
-- 4030 | 3569 | 4027 | 4028 | 3569 | 1 | lb 16 oz | liter

WITH sr AS (SELECT fp.food_id, fp.modifier AS label,
                   EXISTS (SELECT 1 FROM regexp_split_to_table(regexp_replace(fp.modifier, '\([^)]*\)', ' ', 'g'), '[^[:alpha:]]+') t WHERE length(t) >= 3) AS has_term
            FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND fp.gram_weight > 0 AND fp.modifier !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount'),
     per_food AS (SELECT food_id, bool_or(has_term) AS any_term, bool_and(btrim(label) ~* '^(oz|fl oz|lb|g|ml)$') AS only_five_bare_units FROM sr GROUP BY 1)
SELECT count(*) AS delivered_foods,
       count(*) FILTER (WHERE NOT any_term) AS foods_with_no_term_row,
       count(*) FILTER (WHERE only_five_bare_units) AS foods_with_only_five_bare_units
FROM per_food;
-- 7529 | 1042 | 1028
```

### The missing count

A COALESCE that returns the modifier alone returns a label without its
count. On the 14,341 deliverable SR Legacy rows, `amount` is never `NULL`,
10,883 rows are `1`, and 3,458 rows on 3,233 foods are not — 2,786 above 1,
654 fractions between 0 and 1, 18 exactly 0 (672 below 1 in all). Without
the count, the app would show `oz — 85 g` for
`3 oz` (1,431 rows) and `oz — 113 g` for `4 oz` (638 rows), both reading as
one ounce; `cup` for half a cup (148 rows, 10–202 g); `inch sub` twice on
22 foods, once at 148–237 g and once at 296–474 g. *Snacks, banana chips*
(168849) would list `oz` at 28.35 g, 85 g and 42 g.

| `amount` | Label | Rows | `gram_weight` range |
| ---: | --- | ---: | --- |
| 3 | `oz` | 1,431 | 84–117 g |
| 4 | `oz` | 638 | 112–114 g |
| 0.5 | `cup` | 148 | 10–202 g |
| 8 | `fl oz` | 59 | |
| 0.75 | `cup (1 NLEA serving)` | 47 | |
| 0.25 | `cup` | 46 | |
| 0.5 | `oz` | 44 | |
| 0.5 | `fillet` | 41 | |
| 2 | `tbsp` | 37 | |
| 3 | `oz (3 oz)` | 35 | 85 g |
| 2 | `oz` | 30 | |
| 6 | `inch sub` | 22 | 148–237 g |
| 0.5 | `cup (4 fl oz)` | 22 | |
| 0.5 | `cup slices` | 22 | |
| 12 | `inch sub` | 22 | 296–474 g |

```sql
WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND fp.gram_weight > 0 AND coalesce(fp.portion_description, fp.modifier) !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount')
SELECT count(*) AS rows, count(*) FILTER (WHERE amount IS NULL) AS amount_null, count(*) FILTER (WHERE amount = 1) AS amount_one,
       count(*) FILTER (WHERE amount <> 1) AS amount_not_one, count(DISTINCT food_id) FILTER (WHERE amount <> 1) AS foods_amount_not_one,
       count(*) FILTER (WHERE amount > 1) AS amount_gt_one, count(*) FILTER (WHERE amount < 1) AS amount_lt_one,
       count(*) FILTER (WHERE amount > 0 AND amount < 1) AS amount_fraction, count(*) FILTER (WHERE amount = 0) AS amount_zero,
       count(*) FILTER (WHERE amount <> 1 AND label ~ '[0-9]') AS not_one_and_digit_in_label
FROM sr;
-- 14341 | 0 | 10883 | 3458 | 3233 | 2786 | 672 | 654 | 18 | 288

WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND fp.gram_weight > 0 AND coalesce(fp.portion_description, fp.modifier) !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount')
SELECT amount, label, count(*) AS rows, min(gram_weight) AS min_g, max(gram_weight) AS max_g
FROM sr WHERE amount <> 1 GROUP BY 1,2 ORDER BY 3 DESC, 1 LIMIT 30;
-- 3 oz 1431 84–117 ; 4 oz 638 112–114 ; 0.5 cup 148 10–202 ; 8 fl oz 59 ; 0.75 cup (1 NLEA serving) 47 ; 0.25 cup 46 ; 0.5 oz 44 ; 0.5 fillet 41 ;
-- 2 tbsp 37 ; 3 oz (3 oz) 35 85 ; 2 oz 30 ; 6 inch sub 22 148–237 ; 0.5 cup (4 fl oz) 22 ; 0.5 cup slices 22 ; 12 inch sub 22 296–474

SELECT f.id AS food_id, f.description, fp.seq_num, fp.amount, fp.modifier, fp.gram_weight
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE f.source = 'fdc_sr_legacy' AND f.id = (SELECT fp2.food_id FROM food_portion fp2 JOIN food f2 ON f2.id = fp2.food_id
                                              WHERE f2.source = 'fdc_sr_legacy' AND fp2.modifier = 'oz' GROUP BY fp2.food_id HAVING count(*) >= 3 ORDER BY fp2.food_id LIMIT 1)
ORDER BY fp.seq_num NULLS LAST, fp.id;
-- 168849 Snacks, banana chips: 1 oz 28.35 ; 3 oz 85 ; 1.5 oz 42
```

Dropping the count also makes labels collide inside a food. Of the
deliverable rows, 307 food/label pairs (626 rows, 307 foods) are identical
within one food; 290 of them differ by `amount` (`oz` on 119 foods, `fl oz`
49, `cup` 48, `inch sub` 22, `package (10 oz)` 13, `tsp` 8) and 17 share
the amount too and differ only in grams (`oz` on 4 foods, `bar` 3, `fl oz`
1, and white bread's `slice`). The matcher scores terms, not rows, so on
any of these it returns the earlier row — on white bread (174924) the 29 g
`slice` at `seq_num` 1, never the 25 g one at 6.

```sql
WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND fp.gram_weight > 0 AND coalesce(fp.portion_description, fp.modifier) !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount'),
     dup AS (SELECT food_id, label, count(*) AS n, count(DISTINCT amount) AS amounts, count(DISTINCT gram_weight) AS grams FROM sr GROUP BY 1,2 HAVING count(*) > 1)
SELECT count(*) AS food_label_pairs_repeated, sum(n) AS rows_involved, count(DISTINCT food_id) AS foods_with_a_repeated_label,
       count(*) FILTER (WHERE amounts > 1) AS pairs_differing_by_amount, count(*) FILTER (WHERE amounts = 1) AS pairs_same_amount
FROM dup;
-- 307 | 626 | 307 | 290 | 17

WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND fp.gram_weight > 0 AND coalesce(fp.portion_description, fp.modifier) !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount'),
     dup AS (SELECT food_id, label, count(*) AS n, count(DISTINCT amount) AS amounts FROM sr GROUP BY 1,2 HAVING count(*) > 1)
SELECT label, count(*) AS foods_all_pairs, count(*) FILTER (WHERE amounts > 1) AS foods_differing_by_amount, count(*) FILTER (WHERE amounts = 1) AS foods_same_amount
FROM dup GROUP BY 1 ORDER BY 2 DESC LIMIT 8;
-- oz 123 | 119 | 4 ; fl oz 50 | 49 | 1 ; cup 48 | 48 | 0 ; inch sub 22 | 22 | 0 ; package (10 oz) 13 | 13 | 0 ; tsp 8 | 8 | 0 ; pieces 4 | 4 | 0 ; bar 4 | 1 | 3

WITH sr AS (SELECT fp.*, coalesce(fp.portion_description, fp.modifier) AS label FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND fp.gram_weight > 0 AND coalesce(fp.portion_description, fp.modifier) !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount'),
     dup AS (SELECT food_id, label, count(*) AS n, count(DISTINCT amount) AS amounts, array_agg(gram_weight ORDER BY seq_num) AS grams FROM sr GROUP BY 1,2 HAVING count(*) > 1)
SELECT food_id, label, n, grams FROM dup WHERE amounts = 1 ORDER BY label, food_id;
-- 17 rows: bar 167542 {21,25}, 168862 {37,37,38}, 173136 {55,44} ; biscuit 171371, 172668 ; cookie 172717 ; cookie Pepperidge Farm Chocolate Chunk Pecan 172716 ;
-- fl oz 169789 {30,152} ; jar 173497 ; jar (5 oz) 171254 ; oz 167536 {28.35,28.35}, 167537, 168853, 169677 {28,28.35} ; pancake 172771 ; piece 169004 ; slice 174924 {29,25}
```

Synthesising the count the way `food_summary` does — `concat_ws(' ',
amount::text, modifier)` — gives the banana ladder as `1 cup, mashed` 225 g,
`1 cup, sliced` 150 g, `1 extra small (less than 6" long)` 81 g, `1 small
(6" to 6-7/8" long)` 101 g, `1 medium (7" to 7-7/8" long)` 118 g, `1 large
(8" to 8-7/8" long)` 136 g, `1 extra large (9" or longer)` 152 g, `1 NLEA
serving` 126 g, in `seq_num` order; it gives `3 oz`, `0.5 cup`, `0 cup`.
For the matcher the count is irrelevant either way: `_words` keeps only runs
of letters of three or more, so `3 oz` and `oz` both yield no term and `0.5
cup` and `cup` both yield `cup`. Synthesis changes what the user sees, not
what matches.

```sql
SELECT f.id AS food_id, f.description, fp.seq_num, fp.amount, fp.modifier, fp.gram_weight, concat_ws(' ', fp.amount::text, fp.modifier) AS synthesised
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE f.source = 'fdc_sr_legacy' AND f.description = 'Bananas, raw' ORDER BY fp.seq_num NULLS LAST, fp.id;
-- 173944: 1 cup, mashed 225 ; 1 cup, sliced 150 ; 1 extra small (less than 6" long) 81 ; 1 small (6" to 6-7/8" long) 101 ;
-- 1 medium (7" to 7-7/8" long) 118 ; 1 large (8" to 8-7/8" long) 136 ; 1 extra large (9" or longer) 152 ; 1 NLEA serving 126
```

### `gram_weight`

The column is `numeric NOT NULL` by schema, and on the NULL-description
rows it is positive everywhere — 14,449 SR Legacy rows in 0.1–5,717 g, 186
Foundation rows in 3.2–980 g — so the RPC's `gram_weight IS NOT NULL AND
gram_weight > 0` clause removes none of them. Table-wide exactly one
`food_portion` row has `gram_weight <= 0`, and it is a survey row the RPC
already drops.

```sql
\d food_portion
-- gram_weight numeric not null ; seq_num nullable

SELECT f.source, count(*) AS rows, count(*) FILTER (WHERE fp.portion_description IS NULL) AS null_desc_rows,
       count(*) FILTER (WHERE fp.portion_description IS NULL AND fp.gram_weight IS NULL) AS gw_null,
       count(*) FILTER (WHERE fp.portion_description IS NULL AND fp.gram_weight <= 0) AS gw_nonpositive,
       count(*) FILTER (WHERE fp.portion_description IS NULL AND fp.gram_weight > 0) AS gw_positive,
       min(fp.gram_weight) FILTER (WHERE fp.portion_description IS NULL) AS min_gw,
       max(fp.gram_weight) FILTER (WHERE fp.portion_description IS NULL) AS max_gw
FROM food_portion fp JOIN food f ON f.id = fp.food_id GROUP BY 1 ORDER BY 2 DESC;
-- fdc_sr_legacy 14449 | 14449 | 0 | 0 | 14449 | 0.1 | 5717 ; fdc_foundation 187 | 186 | 0 | 0 | 186 | 3.2 | 980 ; fdc_survey … | 0 | …

SELECT count(*) FILTER (WHERE gram_weight IS NULL) AS gw_null_all, count(*) FILTER (WHERE gram_weight <= 0) AS gw_nonpositive_all FROM food_portion;
-- 0 | 1
```

### The classes, as the matcher would see them

The same four regexes on the 14,341 deliverable SR Legacy labels **after**
the parenthetical strip, which is what `_termsOf` matches on:

| Class | Distinct labels | Rows | Foods |
| --- | ---: | ---: | ---: |
| SIZE | 254 | 559 | 245 |
| CONTAINER | 668 | 5,798 | 3,949 |
| PIECE | 255 | 1,682 | 1,482 |
| OTHER | 663 | 6,302 | 4,456 |

Size-word reach by food, each word independently: `large` 178, `medium`
168, `small` 147, `extra large` 12, `jumbo` 3, `extra small` 2; any size
word 245, any container word 3,955, any piece word 1,647. The SR Legacy
size ladders are on about 245 foods, not thousands.

```sql
WITH sr AS (SELECT fp.id, fp.food_id, fp.amount, fp.gram_weight, coalesce(fp.portion_description, fp.modifier) AS label,
                   regexp_replace(coalesce(fp.portion_description, fp.modifier), '\([^)]*\)', ' ', 'g') AS matchable
            FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND coalesce(fp.portion_description, fp.modifier) IS NOT NULL
              AND coalesce(fp.portion_description, fp.modifier) <> 'Quantity not specified' AND fp.gram_weight IS NOT NULL AND fp.gram_weight > 0
              AND coalesce(fp.portion_description, fp.modifier) !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount'),
     classified AS (SELECT *, CASE WHEN matchable ~* '\m(small|medium|large|jumbo|mini|miniature)\M' THEN 'SIZE'
                                   WHEN matchable ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M' THEN 'CONTAINER'
                                   WHEN matchable ~* '\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M' THEN 'PIECE'
                                   ELSE 'OTHER' END AS class FROM sr)
SELECT class, count(DISTINCT label) AS distinct_labels, count(*) AS rows, count(DISTINCT food_id) AS foods
FROM classified GROUP BY class ORDER BY array_position(ARRAY['SIZE','CONTAINER','PIECE','OTHER'], class);
-- SIZE 254 | 559 | 245 ; CONTAINER 668 | 5798 | 3949 ; PIECE 255 | 1682 | 1482 ; OTHER 663 | 6302 | 4456

WITH sr AS (SELECT fp.food_id, regexp_replace(fp.modifier, '\([^)]*\)', ' ', 'g') AS matchable FROM food_portion fp JOIN food f ON f.id = fp.food_id
            WHERE f.source = 'fdc_sr_legacy' AND fp.gram_weight > 0 AND fp.modifier !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount')
SELECT count(DISTINCT food_id) FILTER (WHERE matchable ~* '\msmall\M') AS small,
       count(DISTINCT food_id) FILTER (WHERE matchable ~* '\mmedium\M') AS medium,
       count(DISTINCT food_id) FILTER (WHERE matchable ~* '\mlarge\M') AS large,
       count(DISTINCT food_id) FILTER (WHERE matchable ~* '\mextra[ -]large\M') AS extra_large,
       count(DISTINCT food_id) FILTER (WHERE matchable ~* '\mextra[ -]small\M') AS extra_small,
       count(DISTINCT food_id) FILTER (WHERE matchable ~* '\mjumbo\M') AS jumbo,
       count(DISTINCT food_id) FILTER (WHERE matchable ~* '\m(small|medium|large|jumbo|mini|miniature)\M') AS any_size,
       count(DISTINCT food_id) FILTER (WHERE matchable ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M') AS any_container,
       count(DISTINCT food_id) FILTER (WHERE matchable ~* '\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M') AS any_piece
FROM sr;
-- 147 | 168 | 178 | 12 | 2 | 3 | 245 | 3955 | 1647
```

### Foundation rows

The 186 NULL-description Foundation rows (116 foods) are shaped differently.
The household unit is `measure_unit.name` — `cup` 50, `each` 19, `slice` 12,
`tablespoon` 10, `link` 10, `wedge` 6, `steak` 6, `roast` 6, `oz` 5, `piece`
5, `teaspoon` 5, `Banana` 4, `quart` 4, `milliliter` 4 (the per-source
listing below counts 51 cups because it includes the one described row) —
and `modifier` is a qualifier or nothing. 92 rows have `modifier IS NULL`
(none empty, none whitespace), so a COALESCE yields `NULL` there and the
RPC's `IS NOT NULL` drops them; 63 of the 116 foods have nothing else. The other 94 rows (53
foods, 49 distinct values) would pass the filter carrying only the
qualifier: `Peeled` (4 rows, unit `Banana`), `medium` (4, unit `link`),
`raw` (8, unit `steak` / `roast`), `sifted` (3, `cup`), `slices` (3,
`cup`), `Edible` (unit `Onion`), `NLEA` (unit `serving`), `balls` (10
`pieces`), `1/2 cup` (unit `serving`), `5.3 oz` (unit `container`),
`drained solids` (unit `can`), `extra large (3" dia)` (unit `fruit`),
`chopped`, `cooked`, `crumbles`, `cubes`, `diced`, `grated`, `ground`,
`regular`, `thin`. 17 of the 186 have `amount <> 1` (`100 milliliter`, `2
tablespoon`, `0.2` / `0.5 cup`, `10` / `3 pieces`). The one Foundation row
that does have a description (id 119620, food 328637) reads `shredded` with
`modifier NULL` and unit `cup`, 105 g — the same qualifier-only shape.

Classified on the modifier alone, the 94 rows are SIZE 26, CONTAINER 2,
PIECE 7; classified on `concat_ws(' ', unit, modifier)` they are CONTAINER
30, PIECE 42. A Foundation label needs `measure_unit.name` to make sense,
and SR Legacy rows cannot use that column.

```sql
SELECT fp.modifier, fp.amount, mu.name AS unit, count(*) AS rows, count(DISTINCT fp.food_id) AS foods, min(fp.gram_weight) AS min_g, max(fp.gram_weight) AS max_g
FROM food_portion fp JOIN food f ON f.id = fp.food_id LEFT JOIN measure_unit mu ON mu.id = fp.measure_unit_id
WHERE f.source = 'fdc_foundation' AND fp.portion_description IS NULL
GROUP BY 1,2,3 ORDER BY 4 DESC, 1 LIMIT 60;
-- NULL | 1 | cup 40+ … ; raw | 1 | steak/roast 8 ; Peeled | 1 | Banana 4 ; medium | 1 | link 4 ; sifted | 1 | cup 3 ; slices | 1 | cup 3 ; …

SELECT count(*) AS rows, count(DISTINCT fp.modifier) AS distinct_modifiers,
       count(*) FILTER (WHERE fp.modifier IS NULL OR btrim(fp.modifier) = '') AS blank_modifier,
       count(DISTINCT fp.food_id) AS foods, count(*) FILTER (WHERE fp.amount <> 1) AS amount_not_one
FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_foundation' AND fp.portion_description IS NULL;
-- 186 | 49 | 92 | 116 | 17

SELECT fp.id, fp.food_id, fp.amount, fp.portion_description, fp.modifier, fp.gram_weight
FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_foundation' AND fp.portion_description IS NOT NULL;
-- 119620 | 328637 | 1 | shredded | NULL | 105

WITH fd AS (SELECT fp.*, mu.name AS unit, coalesce(fp.portion_description, fp.modifier) AS label
            FROM food_portion fp JOIN food f ON f.id = fp.food_id LEFT JOIN measure_unit mu ON mu.id = fp.measure_unit_id
            WHERE f.source = 'fdc_foundation' AND fp.portion_description IS NULL)
SELECT count(*) AS rows, count(*) FILTER (WHERE modifier IS NULL) AS modifier_null, count(*) FILTER (WHERE modifier = '') AS modifier_empty,
       count(*) FILTER (WHERE modifier IS NOT NULL AND btrim(modifier) = '' AND modifier <> '') AS modifier_whitespace,
       count(*) FILTER (WHERE label IS NOT NULL AND label <> 'Quantity not specified' AND gram_weight > 0 AND label !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount') AS rpc_would_keep,
       count(DISTINCT food_id) FILTER (WHERE label IS NOT NULL AND btrim(label) <> '' AND gram_weight > 0 AND label !~* '\mNFS\M|\mNS as to\M|\myields\M|^Guideline amount') AS foods_gaining_nonblank_label,
       count(*) FILTER (WHERE unit = 'undetermined') AS unit_undetermined
FROM fd;
-- 186 | 92 | 0 | 0 | 94 | 53 | 0

WITH fd AS (SELECT fp.*, mu.name AS unit, regexp_replace(fp.modifier, '\([^)]*\)', ' ', 'g') AS m_stripped,
                   regexp_replace(concat_ws(' ', mu.name, fp.modifier), '\([^)]*\)', ' ', 'g') AS um_stripped
            FROM food_portion fp JOIN food f ON f.id = fp.food_id LEFT JOIN measure_unit mu ON mu.id = fp.measure_unit_id
            WHERE f.source = 'fdc_foundation' AND fp.portion_description IS NULL AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '')
SELECT count(*) AS nonblank_rows,
       count(*) FILTER (WHERE m_stripped ~* '\m(small|medium|large|jumbo|mini|miniature)\M') AS size_in_modifier,
       count(*) FILTER (WHERE m_stripped ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M') AS container_in_modifier,
       count(*) FILTER (WHERE m_stripped ~* '\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M') AS piece_in_modifier,
       count(*) FILTER (WHERE um_stripped ~* '\m(cups?|bowls?|glass(es)?|tbsp|tablespoons?|tsp|teaspoons?|handfuls?|scoops?|cans?|bottles?|jars?|packets?|packages?|bags?|box(es)?|cartons?|containers?|pouch(es)?|mugs?|pints?|quarts?|plates?|servings?)\M') AS container_in_unit_plus_modifier,
       count(*) FILTER (WHERE um_stripped ~* '\m(slices?|pieces?|whole|each|sticks?|wedges?|sheets?|strips?|chunks?|links?|patty|patties|fillets?|legs?|breasts?|wings?|thighs?|units?|items?)\M') AS piece_in_unit_plus_modifier
FROM fd;
-- 94 | 26 | 2 | 7 | 30 | 42

SELECT f.source, mu.name AS unit, count(*) AS rows FROM food_portion fp JOIN food f ON f.id = fp.food_id LEFT JOIN measure_unit mu ON mu.id = fp.measure_unit_id
WHERE f.source IN ('fdc_sr_legacy','fdc_foundation') GROUP BY 1,2 ORDER BY 1, 3 DESC LIMIT 25;
-- fdc_foundation: cup 51, each 19, slice 12, tablespoon 10, link 10, wedge 6, steak 6, roast 6, oz 5, piece 5, teaspoon 5, Banana 4, quart 4, milliliter 4, … ; fdc_sr_legacy: undetermined 14449
```

## Which record the app receives

The per-food tables in #1155 assumed the app lands on the survey record.
This section measures it: the backend order, the app-side re-ranking as read
from the code, and the Dart ranker run on the real pools.

### The backend order

The English search path calls `search_food_summary(term, sources, max_rows)`
with `max_rows = 100` (`SPConst.maxNumberOfItems * 5`,
[`sp_food_data_source.dart`](../lib/features/add_meal/data/data_sources/sp_food_data_source.dart)
line 30) and `sources = NULL` when every source toggle is on. The function
body is `select fs.* from food_summary fs where to_tsvector('english',
fs.name) @@ websearch_to_tsquery('english', term) and (sources is null or
fs.source = any(sources)) limit greatest(max_rows, 0)` — **no `ORDER BY`**.
`EXPLAIN` shows `Limit -> Bitmap Heap Scan on idx_food_summary_name_fts`,
so rows come back in heap order, and the materialized view's heap is laid
out by source: survey first, then Foundation, SR Legacy, BLS.

| `food_summary.source` | Rows | First ctid | Last ctid |
| --- | ---: | --- | --- |
| fdc_survey | 5,432 | (0,1) | (195,10) |
| fdc_foundation | 469 | (195,11) | (208,30) |
| fdc_sr_legacy | 7,793 | (205,12) | (497,2) |
| bls | 7,140 | (363,28) | (714,10) |

Whenever a term matches 100 or more survey names, the 100-row pool is
entirely survey and no SR Legacy record can enter it. This is a fact about
today's layout: a `REFRESH MATERIALIZED VIEW` can reorder the heap.

```sql
SELECT pg_get_functiondef(p.oid) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname IN ('search_food_summary','search_food_translation','food_summary_by_ids','portions_by_food_ids','portion_labels_by_food_ids') ORDER BY p.proname;
-- search_food_summary: … where to_tsvector('english', fs.name) @@ websearch_to_tsquery('english', term) and (sources is null or fs.source = any(sources)) limit greatest(max_rows, 0)
-- search_food_translation / food_summary_by_ids: LIMIT only, no ORDER BY (translation path, not exercised for English)
-- portions_by_food_ids: order by fp.food_id, fp.seq_num nulls last, fp.id

EXPLAIN (COSTS OFF) SELECT fs.* FROM food_summary fs WHERE to_tsvector('english', fs.name) @@ websearch_to_tsquery('english', 'banana') LIMIT 100;
-- Limit -> Bitmap Heap Scan on food_summary fs -> Bitmap Index Scan on idx_food_summary_name_fts

SELECT source, count(*) AS rows, min(ctid) AS first_ctid, max(ctid) AS last_ctid, min(food_id) AS min_id, max(food_id) AS max_id
FROM food_summary GROUP BY source ORDER BY min(ctid);
-- fdc_survey 5432 (0,1)–(195,10) ; fdc_foundation 469 (195,11)–(208,30) ; fdc_sr_legacy 7793 (205,12)–(497,2) ; bls 7140 (363,28)–(714,10)
```

### The pools, per term

The twelve terms from #1155, each run as the app runs it —
`search_food_summary(term, NULL, 100)` — with the row order captured by
`WITH ORDINALITY`:

| Term | Pool rows | Survey / SR Legacy / other | #1155's survey record, rank in pool | First SR Legacy rank | All matches (no limit) |
| --- | ---: | --- | ---: | ---: | ---: |
| banana | 91 | 11 / 58 / 22 | 6 | 17 | 91 |
| apple | 100 | 20 / 69 / 11 | 8 | 32 | 244 |
| rice | 100 | 100 / 0 / 0 | absent (heap 101) | — | 552 |
| chicken breast | 98 | 30 / 33 / 35 | 4 | 35 | 98 |
| salad | 100 | 100 / 0 / 0 | absent (`Lettuce, raw` does not match; 2709792 at heap 137) | — | 412 |
| bread | 100 | 100 / 0 / 0 | 77 | — | 540 |
| egg | 100 | 100 / 0 / 0 | 10 | — | 604 |
| milk | 100 | 100 / 0 / 0 | 3 | — | 622 |
| coffee | 100 | 100 / 0 / 0 | 20 | — | 219 |
| pasta | 100 | 100 / 0 / 0 | 5 | — | 319 |
| yoghurt | 0 | — | — | — | 0 |
| almonds | 100 | 23 / 41 / 36 | 7 | 31 | 138 |

Seven of the twelve pools are 100% survey. `yoghurt` returns nothing: the
`english` configuration stems `yoghurt` to `yoghurt` and `yogurt` to
`yogurt`, no `food_summary.name` contains `yoghurt`, and every record is
spelled *Yogurt* (251 matches; 2705418 would be heap rank 5 of those). For
`bread`, the 540 matches are 199 survey, 181 SR Legacy, 7 Foundation and
153 BLS, and only the first 100 survey rows are seen.

```sql
WITH terms(term, survey_id) AS (VALUES
  ('banana',2709224),('apple',2709215),('rice',2708408),('chicken breast',2705956),('salad',2709789),('bread',2707598),
  ('egg',2707152),('milk',2705385),('coffee',2710375),('pasta',2708357),('yoghurt',2705418),('almonds',2707486)),
pool AS (
  SELECT t.term, t.survey_id, s.food_id, s.source, s.ord
  FROM terms t
  CROSS JOIN LATERAL search_food_summary(t.term, NULL, 100) WITH ORDINALITY AS s(food_id, source, source_code, name, short_title, brands, barcode, category, serving_quantity, serving_unit, serving_size, serving_gram_weight, thumbnail_url, main_image_url, tags, energy_kcal_100, carbohydrates_100, fat_100, proteins_100, sugars_100, saturated_fat_100, fiber_100, monounsaturated_fat_100, polyunsaturated_fat_100, trans_fat_100, cholesterol_100, sodium_100, potassium_100, magnesium_100, calcium_100, iron_100, zinc_100, phosphorus_100, vitamin_a_100, vitamin_c_100, vitamin_d_100, vitamin_b6_100, vitamin_b12_100, niacin_100, ord)),
total AS (
  SELECT t.term, count(*) AS all_matches,
         count(*) FILTER (WHERE fs.source = 'fdc_survey') AS all_survey,
         count(*) FILTER (WHERE fs.source = 'fdc_sr_legacy') AS all_sr_legacy,
         count(*) FILTER (WHERE fs.source = 'fdc_foundation') AS all_foundation,
         count(*) FILTER (WHERE fs.source = 'bls') AS all_bls
  FROM terms t JOIN food_summary fs ON to_tsvector('english', fs.name) @@ websearch_to_tsquery('english', t.term)
  GROUP BY t.term)
SELECT t.term, t.survey_id,
       (SELECT count(*) FROM pool p WHERE p.term = t.term) AS pool_rows,
       (SELECT count(*) FROM pool p WHERE p.term = t.term AND p.source = 'fdc_survey') AS pool_survey,
       (SELECT count(*) FROM pool p WHERE p.term = t.term AND p.source = 'fdc_sr_legacy') AS pool_sr_legacy,
       (SELECT count(*) FROM pool p WHERE p.term = t.term AND p.source NOT IN ('fdc_survey','fdc_sr_legacy')) AS pool_other,
       (SELECT min(p.ord) FROM pool p WHERE p.term = t.term AND p.food_id = t.survey_id) AS survey_rank_in_pool,
       (SELECT min(p.ord) FROM pool p WHERE p.term = t.term AND p.source = 'fdc_sr_legacy') AS first_sr_legacy_rank,
       tot.all_matches, tot.all_survey, tot.all_sr_legacy, tot.all_foundation, tot.all_bls
FROM terms t LEFT JOIN total tot ON tot.term = t.term
ORDER BY t.term;
-- almonds 100 = 23/41/36, survey rank 7, first SR 31, 138 matches ; apple 100 = 20/69/11, 8, 32, 244 ; banana 91 = 11/58/22, 6, 17, 91 ;
-- bread 100 = 100/0/0, 77, none, 540 (199 survey / 181 SR / 7 fnd / 153 bls) ; chicken breast 98 = 30/33/35, 4, 35, 98 ; coffee 100/0/0, 20, 219 ;
-- egg 100/0/0, 10, 604 ; milk 100/0/0, 3, 622 ; pasta 100/0/0, 5, 319 ; rice 100/0/0, survey ABSENT, 552 (309 survey) ; salad 100/0/0, ABSENT, 412 ; yoghurt 0 rows

WITH m AS (SELECT fs.food_id, fs.source, fs.name, fs.ctid, row_number() OVER (ORDER BY fs.ctid) AS heap_rank
           FROM food_summary fs WHERE to_tsvector('english', fs.name) @@ websearch_to_tsquery('english', 'rice'))
SELECT 'rice' AS term, food_id, source, name, heap_rank, (SELECT count(*) FROM m) AS all_matches FROM m WHERE food_id IN (2708408, 2708402)
UNION ALL
(WITH m AS (SELECT fs.food_id, fs.source, fs.name, fs.ctid, row_number() OVER (ORDER BY fs.ctid) AS heap_rank
            FROM food_summary fs WHERE to_tsvector('english', fs.name) @@ websearch_to_tsquery('english', 'salad'))
 SELECT 'salad', food_id, source, name, heap_rank, (SELECT count(*) FROM m) FROM m WHERE food_id IN (2709789, 2709792))
UNION ALL
SELECT 'salad (does Lettuce, raw match?)', fs.food_id, fs.source, fs.name,
       CASE WHEN to_tsvector('english', fs.name) @@ websearch_to_tsquery('english', 'salad') THEN 1 ELSE 0 END, NULL
FROM food_summary fs WHERE fs.food_id = 2709789;
-- rice 2708402 Rice, cooked, NFS heap 95 of 552 ; rice 2708408 heap 101 of 552 ; salad 2709792 Mixed salad greens, raw heap 137 of 412 ; Lettuce, raw does not match 'salad'

SELECT to_tsvector('english', 'yoghurt') AS ts_yoghurt, to_tsvector('english', 'yogurt') AS ts_yogurt,
       (SELECT count(*) FROM food_summary fs WHERE to_tsvector('english', fs.name) @@ websearch_to_tsquery('english', 'yoghurt')) AS matches_yoghurt,
       (SELECT count(*) FROM food_summary fs WHERE to_tsvector('english', fs.name) @@ websearch_to_tsquery('english', 'yogurt')) AS matches_yogurt,
       (SELECT count(*) FROM food_summary fs WHERE fs.name ILIKE '%yoghurt%') AS names_containing_yoghurt,
       (SELECT name FROM food_summary WHERE food_id = 2705418) AS survey_yoghurt_name,
       (SELECT row_number FROM (SELECT fs.food_id, row_number() OVER (ORDER BY fs.ctid) FROM food_summary fs WHERE to_tsvector('english', fs.name) @@ websearch_to_tsquery('english', 'yogurt')) x WHERE x.food_id = 2705418) AS heap_rank_2705418_for_yogurt;
-- 'yoghurt':1 | 'yogurt':1 | 0 | 251 | 0 | Yogurt, whole milk, plain | 5
```

The first five rows of each pool, in the order the RPC emits them:

| Term | #1 | #2 | #3 | #4 | #5 |
| --- | --- | --- | --- | --- | --- |
| banana | Banana split | Banana pudding | Cake or cupcake, banana | Pie, banana cream | Banana chips |
| apple | Cake or cupcake, apple | Pie, apple | Pie, apple, fast food | Cobbler, apple | Crisp, apple |
| rice | Rice milk | Infant formula, store brand, added rice | Pudding, rice | Beef curry with rice | Chicken curry with rice |
| chicken breast | Chicken breast, NS as to cooking method, skin eaten | …skin not eaten | …baked, broiled, or roasted, skin eaten, from raw | …skin not eaten, from raw | …baked or broiled, skin eaten, from pre-cooked |
| salad | Chicken salad spread | Ham salad spread | Beef salad | Ham or pork salad | Chicken or turkey salad, made with mayonnaise |
| bread | Pudding, bread | Cheese sandwich, American cheese, on white bread | …on wheat bread | Cheese sandwich, cheddar cheese, on white bread | …on wheat bread |
| egg | Egg, whole, fried with oil | Beef, ground, with egg and onion | Chicken or turkey salad with egg | Tuna salad with egg | Shrimp garden salad, … |
| milk | Milk, human | Milk, NFS | Milk, whole | Milk, reduced fat (2%) | Milk, low fat (1%) |
| coffee | Coffee creamer, NFS | Coffee creamer, liquid | …liquid, flavored | …liquid, fat free | …liquid, fat free, flavored |
| pasta | Stew, pork, with pasta | Stew, beef, with pasta | Stew, chicken, with pasta | Pasta, vegetable, cooked | Pasta, cooked |
| almonds | Almond milk, sweetened | Almond milk, chocolate | Almond milk, unsweetened | Almond milk, NFS | Almond chicken |

All fifty-five are survey records.

```sql
WITH terms(term, survey_id) AS (VALUES
  ('banana',2709224),('apple',2709215),('rice',2708408),('chicken breast',2705956),('salad',2709789),('bread',2707598),
  ('egg',2707152),('milk',2705385),('coffee',2710375),('pasta',2708357),('yoghurt',2705418),('almonds',2707486)),
r AS (
  SELECT t.term, t.survey_id, s.food_id, s.source, s.name, s.short_title, s.serving_size, s.serving_gram_weight, s.ord
  FROM terms t
  CROSS JOIN LATERAL search_food_summary(t.term, NULL, 100) WITH ORDINALITY AS s(food_id, source, source_code, name, short_title, brands, barcode, category, serving_quantity, serving_unit, serving_size, serving_gram_weight, thumbnail_url, main_image_url, tags, energy_kcal_100, carbohydrates_100, fat_100, proteins_100, sugars_100, saturated_fat_100, fiber_100, monounsaturated_fat_100, polyunsaturated_fat_100, trans_fat_100, cholesterol_100, sodium_100, potassium_100, magnesium_100, calcium_100, iron_100, zinc_100, phosphorus_100, vitamin_a_100, vitamin_c_100, vitamin_d_100, vitamin_b6_100, vitamin_b12_100, niacin_100, ord))
SELECT term, ord AS backend_rank, food_id, source, name, short_title, serving_size, serving_gram_weight
FROM r WHERE ord <= 5
ORDER BY (SELECT min(ord) FROM r r2 WHERE r2.term = r.term), term, ord;
-- 55 rows, 11 terms x 5, every source fdc_survey (the table above); yoghurt returns none
```

### The app-side re-ranking, as read from the code

The backend hands the app an unordered 100-row pool. Everything after that
is client-side, in four steps; line numbers are on `origin/develop` at
`df6d54c8`.

1. **`SpFoodDataSource._searchEnglish` → `rankAndTruncateFoodsByName`**
   ([`sp_food_data_source.dart`](../lib/features/add_meal/data/data_sources/sp_food_data_source.dart)
   194–218, 306–318). Scores `food_summary.name` — the full description, not
   `short_title` — with `textRelevanceScore`
   ([`meal_relevance_ranker.dart`](../lib/features/add_meal/util/meal_relevance_ranker.dart)
   149–177): normalized exact equality is 1.0; otherwise Dice over token
   sets, +0.2 if the name contains the query, +0.15 if it starts with it,
   clamped to 0.9. Stable `mergeSort` descending, take
   `SPConst.maxNumberOfItems = 20`. Shorter names win (`Milk, human` scores
   0.9; `Chicken breast, baked, broiled, or roasted, skin not eaten, from
   raw` 0.658); equal scores keep heap order; `source` is never read;
   portions are never read — they are fetched afterwards
   ([`products_repository.dart`](../lib/features/add_meal/data/repository/products_repository.dart)
   117–133) and only attached.
2. **`ProductsRepository.getSupabaseFoodsByString`** (100–134).
   `MealEntity.fromSpFood`
   ([`meal_entity.dart`](../lib/features/add_meal/domain/entity/meal_entity.dart)
   314–339) sets the shown name to `SpFoodDTO.displayName = localizedName ??
   short_title ?? name`
   ([`sp_food_dto.dart`](../lib/features/add_meal/data/dto/sp/sp_food_dto.dart)
   106), so every `Milk, …` survey record is shown as *Milk*; `detailed`
   stays false for all backend foods; `_keepIfConsistent` (171–192) drops
   implausible nutriments (none of the twelve top-20s lost a row).
3. **`SearchProductsUseCase.searchFDCFoodByString` → `_buildResult`**
   ([`search_products_usecase.dart`](../lib/features/add_meal/domain/usecase/search_products_usecase.dart)
   77–92, 125–221). Before building anything it awaits
   `_cacheRemoteResults(remote)` (89, 94–103), which writes the 20 rows into
   the search cache — new entries stamped with one `now` per call, existing
   entries keeping their timestamp
   ([`remote_search_cache_data_source.dart`](../lib/core/data/data_source/remote_search_cache_data_source.dart)
   81–105). `_buildResult` then reads the whole cache back through
   `getAllByMostRecentlyTouched()` (195–196), keeps the rows whose `source` is
   the tab's and whose `backendSource` the user has enabled (198–201), and
   the rows whose shown name contains the query (202), and puts them ahead
   of the remote list (211–217), deduplicated by `source:code` with the
   first occurrence kept (229–241). So on every call the 20 fresh rows
   re-enter through the cache: their order is the cache's timestamp order —
   `List.sort` (158–166), which Dart documents as not stable and which, in
   the pinned SDK's `lib/internal/sort.dart`, is an insertion sort only for
   33 elements or fewer (`_doSort(a, 0, a.length - 1)` takes that branch
   when `right - left <= 32`), so the 20 equal timestamps keep their order
   only while the box is that small — and
   a fresh row whose shown name lacks the query word (`Nuts` for `almonds`,
   `Candies`) falls behind every cached match. No scoring. This is what the
   Food tab shows
   ([`food_bloc.dart`](../lib/features/add_meal/presentation/bloc/food_bloc.dart)
   43, 86).
4. **AI path, `ResolveParsedMealsUseCase._resolveOne`**
   ([`resolve_parsed_meals_usecase.dart`](../lib/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart)
   93–136): OFF and Supabase searched in parallel (105–108), each through
   the use case above, so the Supabase list is step 3's output, cache order
   included; then `mergeAndRankMeals(off, supabase, query)` (113;
   [`meal_relevance_ranker.dart`](../lib/features/add_meal/util/meal_relevance_ranker.dart)
   69–78) concatenates `[...OFF, ...Supabase]`, dedupes by `source:code`
   (83–91), puts custom meals and recipes in a tier above everything, and
   `_collapseNearDuplicates` (107–116) groups the rest by the normalized
   **shown** name — plus `|brand` only when the entry has a brand (118–127);
   FDC foods have none — keeping the single highest `scoreMealRelevance` per
   group with a strict `>`, so ties keep the first seen (129–140).
   `scoreMealRelevance` (15–31) is the same text score on the shown name
   (`milk` against *Milk* is exactly 1.0), +0.03 for `detailed`, −0.03 for a
   machine-translated name. Then stable `rankMealsByRelevance` (43–47), then
   `rankForResolution` (119;
   [`resolver_relevance.dart`](../lib/features/add_meal/util/resolver_relevance.dart)
   164–186) re-sorts within tiers by `scoreMealForResolution` (143–155): a
   soft Dice with shared-prefix token similarity (62–98, minimum prefix 3,
   so `salmon` and `salad` share `sal` at 0.5), same tie-breakers, stable.
   `selectedIndex` is always 0 (130–135); `kResolutionConfidenceFloor` 0.45
   (line 14) only flags, never re-picks.

Does the ranker favour a backend? No scorer reads `backendSource`. `source`
is read to put custom meals and recipes in their own tier
(`mergeAndRankMeals` 73, `rankForResolution` 168–170), as the prefix of the
`source:code` dedup keys (`_deduplicateAcrossSources` 87,
`_deduplicateMeals` in `search_products_usecase.dart` 234, and
`_nearDuplicateKey` 124 for nameless meals only) and, in step 3, to keep
the intake-history hits that are custom meals (175) and to filter the cache
to the tab and, with `backendSource`, to the user's source toggles
(198–201). None of those reads separates one backend from another:
`MealEntity.fromSpFood` gives every Supabase record `source =
MealSourceEntity.fdc` and keeps the origin in `backendSource`
(`meal_entity.dart` 335–336). An exact
title? Yes: an exact normalized shown name scores 1.0 and, under the 0.9
cap, beats every non-exact one. Shorter names? Yes, through Dice and the
contains / prefix bonuses. Records with portions? No scorer reads
portions, `servingSize` or gram weights. Ties? Decided by order: the
near-duplicate collapse keeps the first seen, both sorts are stable, and
the order they see is step 3's.

### The harness run

The exported pools were fed through those exact functions by a throwaway
`flutter test` file (see [Method](#method)), in the order
`getSupabaseFoodsByString` returns them — step 3's cache round-trip was
not modelled. What the AI path lands on in that order when OFF returns
nothing, against the record #1155 tabulated:

| Term | Lands on | #1155 assumed | Why |
| --- | --- | --- | --- |
| banana | 2709224 *Banana, raw* | same | — |
| apple | 2709196 *Apple, dried* | 2709215 *Apple, raw* | both shown as *Apple*; the collapse keeps the first seen, and *Apple, dried* is earlier in heap order among the 0.9 ties |
| rice | 2708402 *Rice, cooked, NFS* | 2708408 | 2708408 is heap rank 101 of 552, never in the pool |
| chicken breast | 2705963 *Chicken breast, rotisserie, skin eaten* | 2705956 | 2705956's long name scores 0.658; the 20th-best in the pool is 0.850, so step 1 truncates it |
| salad | 2706826 *Salmon salad* | 2709789 / 2709792 | *Lettuce, raw* does not match `salad`; *Mixed salad greens, raw* is heap rank 137, outside the pool; `sal` prefix rule |
| bread | 2707598 *Bread, white* | same | — |
| egg | 2707179 *Egg, creamed* | 2707152 *Egg, whole, raw* | 2707152 scores 0.850 on its full name behind the 0.9 of *Egg, creamed* / *Benedict* / *deviled*, then collapses into *Egg* |
| milk | 2705383 *Milk, human* | 2705385 *Milk, whole* | thirteen `Milk, …` records collapse into one *Milk*; the first seen wins |
| coffee | 2710375 *Coffee, brewed* | same | — |
| pasta | 2708357 *Pasta, cooked* | same | — |
| yoghurt | nothing | 2705418 | 0 backend rows |
| almonds | 2707485 *Almonds, NFS* | 2707486 *Almonds, unroasted* | collapse into *Almonds*, first seen |

Every winner is a survey record in this order, and the record #1155
tabulated is the winner in four cases (banana, bread, coffee, pasta). How
much of that is the order: the winner's group — the records in the 20 that
share its shown name and so collapse into one — has more than one member
for ten of the eleven terms (banana 2, apple 4, rice 4, chicken breast 9,
bread 18, egg 15, milk 13, coffee 16, pasta 5, almonds 8; salad 1), every
member scores the same 1.0 on the shown name, and the collapse keeps the
first seen. So for those ten the "Lands on" row above, and the matching row
in [What the winner delivers](#what-the-winner-delivers), is the harness's
input order speaking — heap order among equal step-1 scores — which is the
app's order only while the cache sort preserves it. What survives any
order: the winner's group is fixed, because only the shown name equal to
the query scores 1.0; for ten of the eleven terms every record in that
group is survey, so those ten land on a survey record whatever the cache
does; for `chicken breast` the group holds SR Legacy 174608 *Chicken
breast, roll, oven-roasted* and BLS 10001201 and 10003393 beside six survey
records, so which of the nine the app lands on is the cache's call. Salad
is decided by score alone.

SR Legacy records reach the 20-row list (the harness's Food tab, before
step 3 reorders it) only for banana (#15 167629, #16 168849, #17 169394,
#18 173945), apple (#13 168816, #14 170959, #20 167729), chicken breast
(#4 171515, #5 174608, #20 171514) and almonds (ten of twenty: #6 170567,
#10 170568, #12 169060, #13 170656, #14 168592, #15 168754, #16 168602,
#18 168596, #19 169419, #20 170158); for the other eight the pool holds no
SR Legacy record (seven are 100% survey, `yoghurt` is empty), so none can,
and step 3 can only reorder the 20, not add to them. On the AI path after
collapse and resolution the best an SR Legacy record does in this order is
#2: banana (173945 *Bananas, dehydrated*, 0.857), chicken breast (171515
*Chicken breast tenders*, 0.800) and almonds (170567 *Nuts, almonds*, 0.000
— only because everything else collapsed). Those three score strictly
below the winner, so no reordering lifts them to #1; but they are in the
candidate list, `getSupabaseFoodsByString` attaches portions to every
candidate ([`products_repository.dart`](../lib/features/add_meal/data/repository/products_repository.dart)
117–133), and the review screen lists every candidate for the user to
pick ([`bulk_add_screen.dart`](../lib/features/add_meal/presentation/screens/bulk_add_screen.dart)
1449–1458, [`bulk_add_bloc.dart`](../lib/features/add_meal/presentation/bloc/bulk_add_bloc.dart)
607–628). The generic *Bananas, raw* 173944, *Apples, raw, with skin*
171688 and *Egg, whole, raw, fresh* 171287 that #1155 named never appear in
any top 20.

The per-term table below is read off the harness output, which is printed
in full after the harness; it is what [What this means for the
map](#what-this-means-for-the-map) cites. "Sources in the 20" and the SR
Legacy ranks come from the output's `SR Legacy rows in the app's top 20`
line, the group from its `records sharing the winner's shown name` line,
and the #2 from its `after rankForResolution` block; the source of each
group member is from the SQL under the table.

| Term | Sources in the 20 | SR Legacy in the 20 (rank: code) | Rows after collapse | Winner's group | Non-survey in the group | #2 after resolution |
| --- | --- | --- | ---: | --- | --- | --- |
| banana | survey 8, BLS 8, SR Legacy 4 | #15 167629, #16 168849, #17 169394, #18 173945 | 18 | 2: 2709224, 2709225 | none | 173945 SR Legacy, 0.857 |
| apple | survey 17, SR Legacy 3 | #13 168816, #14 170959, #20 167729 | 14 | 4: 2709196, 2709215, 2709220, 2709294 | none | 2709319 survey, 0.667 |
| rice | survey 20 | none | 15 | 4: 2708402, 2708404, 2708405, 2708406 | none | 2705411 survey, 0.667 |
| chicken breast | survey 6, BLS 10, SR Legacy 3, Foundation 1 | #4 171515, #5 174608, #20 171514 | 6 | 9: 2705963, 2705965, 2705971, 174608, 10001201, 10003393, 2705964, 2705966, 2705972 | 174608 SR Legacy; 10001201, 10003393 BLS | 171515 SR Legacy, 0.800 |
| salad | survey 20 | none | 20 | 1: 2706826 | none | 2706749 survey, 0.667 |
| bread | survey 20 | none | 3 | 18 (codes in the output) | none | 2707626 survey, 0.667 |
| egg | survey 20 | none | 6 | 15 (codes in the output) | none | 2707182 survey, 0.667 |
| milk | survey 20 | none | 8 | 13 (codes in the output) | none | 2705510 survey, 0.667 |
| coffee | survey 20 | none | 2 | 16 (codes in the output) | none | 2705599 survey, 0.667 |
| pasta | survey 20 | none | 10 | 5: 2708357, 2708351, 2708359, 2708358, 2708903 | none | 2708828 survey, 0.500 |
| yoghurt | empty pool | none | 0 | — | — | — |
| almonds | survey 8, SR Legacy 10, Foundation 2 | #6 170567, #10 170568, #12 169060, #13 170656, #14 168592, #15 168754, #16 168602, #18 168596, #19 169419, #20 170158 | 3 | 8: 2707485, 2707486, 2707487, 2707489, 2707490, 2707488, 2707491, 2710326 | none | 170567 SR Legacy, 0.000 |

```sql
WITH g(term, food_id) AS (VALUES
  ('banana',2709224),('banana',2709225),
  ('apple',2709196),('apple',2709215),('apple',2709220),('apple',2709294),
  ('rice',2708402),('rice',2708404),('rice',2708405),('rice',2708406),
  ('chicken breast',2705963),('chicken breast',2705965),('chicken breast',2705971),('chicken breast',174608),('chicken breast',10001201),('chicken breast',10003393),('chicken breast',2705964),('chicken breast',2705966),('chicken breast',2705972),
  ('salad',2706826),
  ('bread',2707598),('bread',2707604),('bread',2707613),('bread',2707616),('bread',2707618),('bread',2707620),('bread',2707599),('bread',2707605),('bread',2707619),('bread',2707621),('bread',2707625),('bread',2707610),('bread',2707614),('bread',2707617),('bread',2707622),('bread',2707608),('bread',2707611),('bread',2707615),
  ('egg',2707179),('egg',2707180),('egg',2707181),('egg',2707152),('egg',2707167),('egg',2707168),('egg',2707172),('egg',2707158),('egg',2707154),('egg',2707157),('egg',2707159),('egg',2707166),('egg',2707171),('egg',2707156),('egg',2707161),
  ('milk',2705383),('milk',2705384),('milk',2705385),('milk',2705501),('milk',2705399),('milk',2705402),('milk',2705386),('milk',2705387),('milk',2705388),('milk',2705392),('milk',2705396),('milk',2705397),('milk',2705585),
  ('coffee',2710375),('coffee',2710377),('coffee',2710378),('coffee',2710381),('coffee',2710382),('coffee',2710386),('coffee',2710379),('coffee',2710380),('coffee',2710383),('coffee',2710387),('coffee',2710389),('coffee',2710392),('coffee',2710410),('coffee',2710431),('coffee',2710449),('coffee',2710452),
  ('pasta',2708357),('pasta',2708351),('pasta',2708359),('pasta',2708358),('pasta',2708903),
  ('almonds',2707485),('almonds',2707486),('almonds',2707487),('almonds',2707489),('almonds',2707490),('almonds',2707488),('almonds',2707491),('almonds',2710326))
SELECT g.term, count(*) AS members,
       count(*) FILTER (WHERE f.source = 'fdc_survey') AS survey,
       string_agg(f.id::text || ' ' || f.source, ', ' ORDER BY f.id) FILTER (WHERE f.source <> 'fdc_survey') AS non_survey
FROM g JOIN food f ON f.id = g.food_id
GROUP BY g.term
ORDER BY array_position(ARRAY['banana','apple','rice','chicken breast','salad','bread','egg','milk','coffee','pasta','almonds'], g.term);
-- banana 2 | 2 ; apple 4 | 4 ; rice 4 | 4 ; chicken breast 9 | 6 | 174608 fdc_sr_legacy, 10001201 bls, 10003393 bls ; salad 1 | 1 ;
-- bread 18 | 18 ; egg 15 | 15 ; milk 13 | 13 ; coffee 16 | 16 ; pasta 5 | 5 ; almonds 8 | 8
```

The harness input is the exact export below, followed by the harness
itself and the output it wrote.

```sql
WITH terms(term) AS (VALUES ('banana'),('apple'),('rice'),('chicken breast'),('salad'),('bread'),('egg'),('milk'),('coffee'),('pasta'),('yoghurt'),('almonds'))
SELECT json_object_agg(term, rows)
FROM (
  SELECT t.term, coalesce((SELECT json_agg(row_to_json(s) ORDER BY s.ord)
          FROM search_food_summary(t.term, NULL, 100) WITH ORDINALITY AS s(food_id, source, source_code, name, short_title, brands, barcode, category, serving_quantity, serving_unit, serving_size, serving_gram_weight, thumbnail_url, main_image_url, tags, energy_kcal_100, carbohydrates_100, fat_100, proteins_100, sugars_100, saturated_fat_100, fiber_100, monounsaturated_fat_100, polyunsaturated_fat_100, trans_fat_100, cholesterol_100, sodium_100, potassium_100, magnesium_100, calcium_100, iron_100, zinc_100, phosphorus_100, vitamin_a_100, vitamin_c_100, vitamin_d_100, vitamin_b6_100, vitamin_b12_100, niacin_100, ord)), '[]'::json) AS rows
  FROM terms t) x;
-- pool.json: 91 / 100 / 100 / 98 / 100 / 100 / 100 / 100 / 100 / 100 / 0 / 100 rows
```

The harness, verbatim as run (`poolPath` and `outPath` are the only lines
to change to re-run it elsewhere):

```dart
// Throwaway harness for #1163: replays the app's client-side ranking over the
// exact 100-row pools search_food_summary(term, NULL, 100) returned, in the
// backend's order. Not committed. Uses the real functions from lib/.
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart';

const poolPath =
    '/tmp/claude-1000/-home-simon-Documents-OpenNutriTracker/0432813e-4e04-4656-9928-de37c0feaf90/scratchpad/q1163b/pool.json';
const outPath =
    '/tmp/claude-1000/-home-simon-Documents-OpenNutriTracker/0432813e-4e04-4656-9928-de37c0feaf90/scratchpad/q1163b/ranker_out.txt';

const surveyIds = <String, int>{
  'banana': 2709224, 'apple': 2709215, 'rice': 2708408, 'chicken breast': 2705956,
  'salad': 2709789, 'bread': 2707598, 'egg': 2707152, 'milk': 2705385,
  'coffee': 2710375, 'pasta': 2708357, 'yoghurt': 2705418, 'almonds': 2707486,
};

String fmt(MealEntity m, Map<String, Map<String, dynamic>> byCode) {
  final row = byCode[m.code];
  return '${m.code} ${m.backendSource} "${row?['name']}" (name shown: "${m.name}")';
}

int rankOf(List<MealEntity> list, int id) {
  final i = list.indexWhere((m) => m.code == '$id');
  return i < 0 ? -1 : i + 1;
}

void main() {
  test('replay app ranking over backend pools', () {
    final pools = jsonDecode(File(poolPath).readAsStringSync()) as Map<String, dynamic>;
    final out = StringBuffer();
    for (final term in surveyIds.keys) {
      final rows = (pools[term] as List).cast<Map<String, dynamic>>();
      final byCode = {for (final r in rows) '${r['food_id']}': r};
      final dtos = rows.map(SpFoodDTO.fromJson).toList();
      // Step 1: SpFoodDataSource._searchEnglish -> rankAndTruncateFoodsByName (score on full name, take 20).
      final truncated = rankAndTruncateFoodsByName(dtos, term);
      // Step 2: ProductsRepository.getSupabaseFoodsByString -> MealEntity.fromSpFood + _keepIfConsistent.
      final foodTab = truncated
          .map(MealEntity.fromSpFood)
          .where((m) => validateNutriments(m.nutriments).isConsistent)
          .toList();
      final dropped = truncated.length - foodTab.length;
      // Step 3 (All tab and AI path): mergeAndRankMeals(off, fdc, query) with OFF empty.
      final allTab = mergeAndRankMeals(const [], foodTab, term);
      // Step 4 (AI path only): rankForResolution.
      final resolved = rankForResolution(allTab, term);
      final sid = surveyIds[term]!;
      // Pre-truncation: where the survey record sits once the whole pool is scored on full name.
      final scoredPool = [for (final d in dtos) (d: d, s: textRelevanceScore(d.name, term))];
      final sortedPool = [...scoredPool]..sort((a, b) => b.s.compareTo(a.s)); // tie order irrelevant for the threshold
      final surveyDto = dtos.where((d) => d.foodId == sid).firstOrNull;
      final surveyScore = surveyDto == null ? null : textRelevanceScore(surveyDto.name, term);
      final twentieth = sortedPool.length >= 20 ? sortedPool[19].s : null;
      out.writeln('=== $term  pool=${rows.length} truncated=${truncated.length} consistencyDropped=$dropped foodTab=${foodTab.length} afterCollapse=${allTab.length}');
      out.writeln('-- survey $sid in pool: ${surveyDto != null}; its full-name score=${surveyScore?.toStringAsFixed(3)}; 20th-best score in pool=${twentieth?.toStringAsFixed(3)}; pool rows scoring > survey: ${surveyScore == null ? 'n/a' : scoredPool.where((e) => e.s > surveyScore).length}, == survey: ${surveyScore == null ? 'n/a' : scoredPool.where((e) => e.s == surveyScore).length}');
      final srInTop20 = [for (final (i, m) in foodTab.indexed) if (m.backendSource == 'fdc_sr_legacy') '#${i + 1}:${m.code}'];
      out.writeln('-- SR Legacy rows in the app\'s top 20 (Food tab): ${srInTop20.isEmpty ? 'none' : srInTop20.join(' ')}; sources in top 20: ${ {for (final m in foodTab) m.backendSource: foodTab.where((x) => x.backendSource == m.backendSource).length} }');
      out.writeln('-- Food tab order (rankAndTruncateFoodsByName, scored on food_summary.name), top 5; survey $sid rank=${rankOf(foodTab, sid)}');
      for (final m in foodTab.take(5)) {
        final d = truncated.firstWhere((x) => '${x.foodId}' == m.code);
        out.writeln('   score=${textRelevanceScore(d.name, term).toStringAsFixed(3)} ${fmt(m, byCode)}');
      }
      out.writeln('-- All tab / AI path after mergeAndRankMeals (OFF empty), top 5; survey $sid rank=${rankOf(allTab, sid)}');
      for (final m in allTab.take(5)) {
        out.writeln('   score=${scoreMealRelevance(m, term).toStringAsFixed(3)} ${fmt(m, byCode)}');
      }
      out.writeln('-- AI path after rankForResolution, top 5; survey $sid rank=${rankOf(resolved, sid)}');
      for (final m in resolved.take(5)) {
        out.writeln('   score=${scoreMealForResolution(m, term).toStringAsFixed(3)} ${fmt(m, byCode)}');
      }
      // Which records collapsed into the winner's near-duplicate group?
      if (resolved.isNotEmpty) {
        final winnerName = resolved.first.name?.trim().toLowerCase();
        final group = foodTab.where((m) => m.name?.trim().toLowerCase() == winnerName).map((m) => m.code).toList();
        out.writeln('-- records sharing the winner\'s shown name "${resolved.first.name}" in the Food-tab list (collapsed to one): $group');
      }
      out.writeln();
    }
    File(outPath).writeAsStringSync(out.toString());
    // ignore: avoid_print
    print(out);
  });
}
```

Its output, verbatim; every figure in this section and in [What this means
for the map](#what-this-means-for-the-map) that is not a database figure
is read from these lines:

```text
=== banana  pool=91 truncated=20 consistencyDropped=0 foodTab=20 afterCollapse=18
-- survey 2709224 in pool: true; its full-name score=0.900; 20th-best score in pool=0.636; pool rows scoring > survey: 0, == survey: 11
-- SR Legacy rows in the app's top 20 (Food tab): #15:167629 #16:168849 #17:169394 #18:173945; sources in top 20: {fdc_survey: 8, bls: 8, fdc_sr_legacy: 4}
-- Food tab order (rankAndTruncateFoodsByName, scored on food_summary.name), top 5; survey 2709224 rank=4
   score=0.900 2705660 fdc_survey "Banana split" (name shown: "Banana split")
   score=0.900 2705697 fdc_survey "Banana pudding" (name shown: "Banana pudding")
   score=0.900 2709200 fdc_survey "Banana chips" (name shown: "Banana chips")
   score=0.900 2709224 fdc_survey "Banana, raw" (name shown: "Banana")
   score=0.900 2709225 fdc_survey "Banana, baked" (name shown: "Banana")
-- All tab / AI path after mergeAndRankMeals (OFF empty), top 5; survey 2709224 rank=1
   score=1.000 2709224 fdc_survey "Banana, raw" (name shown: "Banana")
   score=0.900 2705660 fdc_survey "Banana split" (name shown: "Banana split")
   score=0.900 2705697 fdc_survey "Banana pudding" (name shown: "Banana pudding")
   score=0.900 2709200 fdc_survey "Banana chips" (name shown: "Banana chips")
   score=0.900 2709342 fdc_survey "Banana nectar" (name shown: "Banana nectar")
-- AI path after rankForResolution, top 5; survey 2709224 rank=1
   score=1.000 2709224 fdc_survey "Banana, raw" (name shown: "Banana")
   score=0.857 173945 fdc_sr_legacy "Bananas, dehydrated, or banana powder" (name shown: "Bananas")
   score=0.667 2705660 fdc_survey "Banana split" (name shown: "Banana split")
   score=0.667 2705697 fdc_survey "Banana pudding" (name shown: "Banana pudding")
   score=0.667 2709200 fdc_survey "Banana chips" (name shown: "Banana chips")
-- records sharing the winner's shown name "Banana" in the Food-tab list (collapsed to one): [2709224, 2709225]

=== apple  pool=100 truncated=20 consistencyDropped=0 foodTab=20 afterCollapse=14
-- survey 2709215 in pool: true; its full-name score=0.900; 20th-best score in pool=0.600; pool rows scoring > survey: 0, == survey: 5
-- SR Legacy rows in the app's top 20 (Food tab): #13:168816 #14:170959 #20:167729; sources in top 20: {fdc_survey: 17, fdc_sr_legacy: 3}
-- Food tab order (rankAndTruncateFoodsByName, scored on food_summary.name), top 5; survey 2709215 rank=2
   score=0.900 2709196 fdc_survey "Apple, dried" (name shown: "Apple")
   score=0.900 2709215 fdc_survey "Apple, raw" (name shown: "Apple")
   score=0.900 2709220 fdc_survey "Apple, baked" (name shown: "Apple")
   score=0.900 2709294 fdc_survey "Apple, candied" (name shown: "Apple")
   score=0.900 2709319 fdc_survey "Apple cider" (name shown: "Apple cider")
-- All tab / AI path after mergeAndRankMeals (OFF empty), top 5; survey 2709215 rank=-1
   score=1.000 2709196 fdc_survey "Apple, dried" (name shown: "Apple")
   score=0.900 2709319 fdc_survey "Apple cider" (name shown: "Apple cider")
   score=0.900 2709320 fdc_survey "Apple juice, 100%" (name shown: "Apple juice")
   score=0.850 2709219 fdc_survey "Apple pie filling" (name shown: "Apple pie filling")
   score=0.850 2710591 fdc_survey "Apple juice beverage, 40-50% juice, light" (name shown: "Apple juice beverage")
-- AI path after rankForResolution, top 5; survey 2709215 rank=-1
   score=1.000 2709196 fdc_survey "Apple, dried" (name shown: "Apple")
   score=0.667 2709319 fdc_survey "Apple cider" (name shown: "Apple cider")
   score=0.667 2709320 fdc_survey "Apple juice, 100%" (name shown: "Apple juice")
   score=0.500 2709219 fdc_survey "Apple pie filling" (name shown: "Apple pie filling")
   score=0.500 2710591 fdc_survey "Apple juice beverage, 40-50% juice, light" (name shown: "Apple juice beverage")
-- records sharing the winner's shown name "Apple" in the Food-tab list (collapsed to one): [2709196, 2709215, 2709220, 2709294]

=== rice  pool=100 truncated=20 consistencyDropped=0 foodTab=20 afterCollapse=15
-- survey 2708408 in pool: false; its full-name score=null; 20th-best score in pool=0.600; pool rows scoring > survey: n/a, == survey: n/a
-- SR Legacy rows in the app's top 20 (Food tab): none; sources in top 20: {fdc_survey: 20}
-- Food tab order (rankAndTruncateFoodsByName, scored on food_summary.name), top 5; survey 2708408 rank=-1
   score=0.900 2705411 fdc_survey "Rice milk" (name shown: "Rice milk")
   score=0.900 2708162 fdc_survey "Rice cake" (name shown: "Rice cake")
   score=0.900 2708166 fdc_survey "Rice paper" (name shown: "Rice paper")
   score=0.867 2705685 fdc_survey "Pudding, rice" (name shown: "Pudding")
   score=0.867 2707794 fdc_survey "Bread, rice" (name shown: "Bread")
-- All tab / AI path after mergeAndRankMeals (OFF empty), top 5; survey 2708408 rank=-1
   score=1.000 2708402 fdc_survey "Rice, cooked, NFS" (name shown: "Rice")
   score=0.900 2705411 fdc_survey "Rice milk" (name shown: "Rice milk")
   score=0.900 2708162 fdc_survey "Rice cake" (name shown: "Rice cake")
   score=0.900 2708166 fdc_survey "Rice paper" (name shown: "Rice paper")
   score=0.900 2708356 fdc_survey "Rice noodles, cooked" (name shown: "Rice noodles")
-- AI path after rankForResolution, top 5; survey 2708408 rank=-1
   score=1.000 2708402 fdc_survey "Rice, cooked, NFS" (name shown: "Rice")
   score=0.667 2705411 fdc_survey "Rice milk" (name shown: "Rice milk")
   score=0.667 2708162 fdc_survey "Rice cake" (name shown: "Rice cake")
   score=0.667 2708166 fdc_survey "Rice paper" (name shown: "Rice paper")
   score=0.667 2708356 fdc_survey "Rice noodles, cooked" (name shown: "Rice noodles")
-- records sharing the winner's shown name "Rice" in the Food-tab list (collapsed to one): [2708402, 2708404, 2708405, 2708406]

=== chicken breast  pool=98 truncated=20 consistencyDropped=0 foodTab=20 afterCollapse=6
-- survey 2705956 in pool: true; its full-name score=0.658; 20th-best score in pool=0.850; pool rows scoring > survey: 52, == survey: 6
-- SR Legacy rows in the app's top 20 (Food tab): #4:171515 #5:174608 #20:171514; sources in top 20: {fdc_survey: 6, fdc_sr_legacy: 3, bls: 10, fdc_foundation: 1}
-- Food tab order (rankAndTruncateFoodsByName, scored on food_summary.name), top 5; survey 2705956 rank=-1
   score=0.900 2705963 fdc_survey "Chicken breast, rotisserie, skin eaten" (name shown: "Chicken breast")
   score=0.900 2705965 fdc_survey "Chicken breast, stewed, skin eaten" (name shown: "Chicken breast")
   score=0.900 2705971 fdc_survey "Chicken breast, sauteed, skin eaten" (name shown: "Chicken breast")
   score=0.900 171515 fdc_sr_legacy "Chicken breast tenders, breaded, uncooked" (name shown: "Chicken breast tenders")
   score=0.900 174608 fdc_sr_legacy "Chicken breast, roll, oven-roasted" (name shown: "Chicken breast")
-- All tab / AI path after mergeAndRankMeals (OFF empty), top 5; survey 2705956 rank=-1
   score=1.000 2705963 fdc_survey "Chicken breast, rotisserie, skin eaten" (name shown: "Chicken breast")
   score=0.900 171515 fdc_sr_legacy "Chicken breast tenders, breaded, uncooked" (name shown: "Chicken breast tenders")
   score=0.900 10000950 bls "Chicken breast fillet, raw" (name shown: "Chicken breast fillet")
   score=0.900 10002565 bls "Chicken breast fillet fried" (name shown: "Chicken breast fillet fried")
   score=0.900 10006428 bls "Chicken breast fillet breaded, fried" (name shown: "Chicken breast fillet breaded")
-- AI path after rankForResolution, top 5; survey 2705956 rank=-1
   score=1.000 2705963 fdc_survey "Chicken breast, rotisserie, skin eaten" (name shown: "Chicken breast")
   score=0.800 171515 fdc_sr_legacy "Chicken breast tenders, breaded, uncooked" (name shown: "Chicken breast tenders")
   score=0.800 10000950 bls "Chicken breast fillet, raw" (name shown: "Chicken breast fillet")
   score=0.762 10006428 bls "Chicken breast fillet breaded, fried" (name shown: "Chicken breast fillet breaded")
   score=0.667 10002565 bls "Chicken breast fillet fried" (name shown: "Chicken breast fillet fried")
-- records sharing the winner's shown name "Chicken breast" in the Food-tab list (collapsed to one): [2705963, 2705965, 2705971, 174608, 10001201, 10003393, 2705964, 2705966, 2705972]

=== salad  pool=100 truncated=20 consistencyDropped=0 foodTab=20 afterCollapse=20
-- survey 2709789 in pool: false; its full-name score=null; 20th-best score in pool=0.533; pool rows scoring > survey: n/a, == survey: n/a
-- SR Legacy rows in the app's top 20 (Food tab): none; sources in top 20: {fdc_survey: 20}
-- Food tab order (rankAndTruncateFoodsByName, scored on food_summary.name), top 5; survey 2709789 rank=-1
   score=0.867 2706749 fdc_survey "Beef salad" (name shown: "Beef salad")
   score=0.867 2706824 fdc_survey "Crab salad" (name shown: "Crab salad")
   score=0.867 2706825 fdc_survey "Lobster salad" (name shown: "Lobster salad")
   score=0.867 2706826 fdc_survey "Salmon salad" (name shown: "Salmon salad")
   score=0.867 2706837 fdc_survey "Shrimp salad" (name shown: "Shrimp salad")
-- All tab / AI path after mergeAndRankMeals (OFF empty), top 5; survey 2709789 rank=-1
   score=0.867 2706749 fdc_survey "Beef salad" (name shown: "Beef salad")
   score=0.867 2706824 fdc_survey "Crab salad" (name shown: "Crab salad")
   score=0.867 2706825 fdc_survey "Lobster salad" (name shown: "Lobster salad")
   score=0.867 2706826 fdc_survey "Salmon salad" (name shown: "Salmon salad")
   score=0.867 2706837 fdc_survey "Shrimp salad" (name shown: "Shrimp salad")
-- AI path after rankForResolution, top 5; survey 2709789 rank=-1
   score=0.833 2706826 fdc_survey "Salmon salad" (name shown: "Salmon salad")
   score=0.667 2706749 fdc_survey "Beef salad" (name shown: "Beef salad")
   score=0.667 2706824 fdc_survey "Crab salad" (name shown: "Crab salad")
   score=0.667 2706825 fdc_survey "Lobster salad" (name shown: "Lobster salad")
   score=0.667 2706837 fdc_survey "Shrimp salad" (name shown: "Shrimp salad")
-- records sharing the winner's shown name "Salmon salad" in the Food-tab list (collapsed to one): [2706826]

=== bread  pool=100 truncated=20 consistencyDropped=0 foodTab=20 afterCollapse=3
-- survey 2707598 in pool: true; its full-name score=0.900; 20th-best score in pool=0.683; pool rows scoring > survey: 0, == survey: 6
-- SR Legacy rows in the app's top 20 (Food tab): none; sources in top 20: {fdc_survey: 20}
-- Food tab order (rankAndTruncateFoodsByName, scored on food_summary.name), top 5; survey 2707598 rank=1
   score=0.900 2707598 fdc_survey "Bread, white" (name shown: "Bread")
   score=0.900 2707604 fdc_survey "Bread, Cuban" (name shown: "Bread")
   score=0.900 2707613 fdc_survey "Bread, naan" (name shown: "Bread")
   score=0.900 2707616 fdc_survey "Bread, pita" (name shown: "Bread")
   score=0.900 2707618 fdc_survey "Bread, cheese" (name shown: "Bread")
-- All tab / AI path after mergeAndRankMeals (OFF empty), top 5; survey 2707598 rank=1
   score=1.000 2707598 fdc_survey "Bread, white" (name shown: "Bread")
   score=0.867 2707626 fdc_survey "Garlic bread, NFS" (name shown: "Garlic bread")
   score=0.000 2705680 fdc_survey "Pudding, bread" (name shown: "Pudding")
-- AI path after rankForResolution, top 5; survey 2707598 rank=1
   score=1.000 2707598 fdc_survey "Bread, white" (name shown: "Bread")
   score=0.667 2707626 fdc_survey "Garlic bread, NFS" (name shown: "Garlic bread")
   score=0.000 2705680 fdc_survey "Pudding, bread" (name shown: "Pudding")
-- records sharing the winner's shown name "Bread" in the Food-tab list (collapsed to one): [2707598, 2707604, 2707613, 2707616, 2707618, 2707620, 2707599, 2707605, 2707619, 2707621, 2707625, 2707610, 2707614, 2707617, 2707622, 2707608, 2707611, 2707615]

=== egg  pool=100 truncated=20 consistencyDropped=0 foodTab=20 afterCollapse=6
-- survey 2707152 in pool: true; its full-name score=0.850; 20th-best score in pool=0.636; pool rows scoring > survey: 3, == survey: 2
-- SR Legacy rows in the app's top 20 (Food tab): none; sources in top 20: {fdc_survey: 20}
-- Food tab order (rankAndTruncateFoodsByName, scored on food_summary.name), top 5; survey 2707152 rank=4
   score=0.900 2707179 fdc_survey "Egg, creamed" (name shown: "Egg")
   score=0.900 2707180 fdc_survey "Egg, Benedict" (name shown: "Egg")
   score=0.900 2707181 fdc_survey "Egg, deviled" (name shown: "Egg")
   score=0.850 2707152 fdc_survey "Egg, whole, raw" (name shown: "Egg")
   score=0.850 2707167 fdc_survey "Egg, whole, pickled" (name shown: "Egg")
-- All tab / AI path after mergeAndRankMeals (OFF empty), top 5; survey 2707152 rank=-1
   score=1.000 2707179 fdc_survey "Egg, creamed" (name shown: "Egg")
   score=0.900 2707182 fdc_survey "Egg salad, made with mayonnaise" (name shown: "Egg salad")
   score=0.867 2707176 fdc_survey "Duck egg, cooked" (name shown: "Duck egg")
   score=0.867 2707177 fdc_survey "Goose egg, cooked" (name shown: "Goose egg")
   score=0.867 2707178 fdc_survey "Quail egg, canned" (name shown: "Quail egg")
-- AI path after rankForResolution, top 5; survey 2707152 rank=-1
   score=1.000 2707179 fdc_survey "Egg, creamed" (name shown: "Egg")
   score=0.667 2707182 fdc_survey "Egg salad, made with mayonnaise" (name shown: "Egg salad")
   score=0.667 2707176 fdc_survey "Duck egg, cooked" (name shown: "Duck egg")
   score=0.667 2707177 fdc_survey "Goose egg, cooked" (name shown: "Goose egg")
   score=0.667 2707178 fdc_survey "Quail egg, canned" (name shown: "Quail egg")
-- records sharing the winner's shown name "Egg" in the Food-tab list (collapsed to one): [2707179, 2707180, 2707181, 2707152, 2707167, 2707168, 2707172, 2707158, 2707154, 2707157, 2707159, 2707166, 2707171, 2707156, 2707161]

=== milk  pool=100 truncated=20 consistencyDropped=0 foodTab=20 afterCollapse=8
-- survey 2705385 in pool: true; its full-name score=0.900; 20th-best score in pool=0.700; pool rows scoring > survey: 0, == survey: 4
-- SR Legacy rows in the app's top 20 (Food tab): none; sources in top 20: {fdc_survey: 20}
-- Food tab order (rankAndTruncateFoodsByName, scored on food_summary.name), top 5; survey 2705385 rank=3
   score=0.900 2705383 fdc_survey "Milk, human" (name shown: "Milk")
   score=0.900 2705384 fdc_survey "Milk, NFS" (name shown: "Milk")
   score=0.900 2705385 fdc_survey "Milk, whole" (name shown: "Milk")
   score=0.900 2705501 fdc_survey "Milk, malted" (name shown: "Milk")
   score=0.867 2705395 fdc_survey "Goat milk" (name shown: "Goat milk")
-- All tab / AI path after mergeAndRankMeals (OFF empty), top 5; survey 2705385 rank=-1
   score=1.000 2705383 fdc_survey "Milk, human" (name shown: "Milk")
   score=0.900 2705510 fdc_survey "Milk shake, bottled, chocolate" (name shown: "Milk shake")
   score=0.867 2705395 fdc_survey "Goat milk" (name shown: "Goat milk")
   score=0.867 2705411 fdc_survey "Rice milk" (name shown: "Rice milk")
   score=0.867 2705412 fdc_survey "Oat milk" (name shown: "Oat milk")
-- AI path after rankForResolution, top 5; survey 2705385 rank=-1
   score=1.000 2705383 fdc_survey "Milk, human" (name shown: "Milk")
   score=0.667 2705510 fdc_survey "Milk shake, bottled, chocolate" (name shown: "Milk shake")
   score=0.667 2705395 fdc_survey "Goat milk" (name shown: "Goat milk")
   score=0.667 2705411 fdc_survey "Rice milk" (name shown: "Rice milk")
   score=0.667 2705412 fdc_survey "Oat milk" (name shown: "Oat milk")
-- records sharing the winner's shown name "Milk" in the Food-tab list (collapsed to one): [2705383, 2705384, 2705385, 2705501, 2705399, 2705402, 2705386, 2705387, 2705388, 2705392, 2705396, 2705397, 2705585]

=== coffee  pool=100 truncated=20 consistencyDropped=0 foodTab=20 afterCollapse=2
-- survey 2710375 in pool: true; its full-name score=0.900; 20th-best score in pool=0.750; pool rows scoring > survey: 0, == survey: 6
-- SR Legacy rows in the app's top 20 (Food tab): none; sources in top 20: {fdc_survey: 20}
-- Food tab order (rankAndTruncateFoodsByName, scored on food_summary.name), top 5; survey 2710375 rank=1
   score=0.900 2710375 fdc_survey "Coffee, brewed" (name shown: "Coffee")
   score=0.900 2710377 fdc_survey "Coffee, Turkish" (name shown: "Coffee")
   score=0.900 2710378 fdc_survey "Coffee, espresso" (name shown: "Coffee")
   score=0.900 2710381 fdc_survey "Coffee, Cuban" (name shown: "Coffee")
   score=0.900 2710382 fdc_survey "Coffee, macchiato" (name shown: "Coffee")
-- All tab / AI path after mergeAndRankMeals (OFF empty), top 5; survey 2710375 rank=1
   score=1.000 2710375 fdc_survey "Coffee, brewed" (name shown: "Coffee")
   score=0.900 2705599 fdc_survey "Coffee creamer, NFS" (name shown: "Coffee creamer")
-- AI path after rankForResolution, top 5; survey 2710375 rank=1
   score=1.000 2710375 fdc_survey "Coffee, brewed" (name shown: "Coffee")
   score=0.667 2705599 fdc_survey "Coffee creamer, NFS" (name shown: "Coffee creamer")
-- records sharing the winner's shown name "Coffee" in the Food-tab list (collapsed to one): [2710375, 2710377, 2710378, 2710381, 2710382, 2710386, 2710379, 2710380, 2710383, 2710387, 2710389, 2710392, 2710410, 2710431, 2710449, 2710452]

=== pasta  pool=100 truncated=20 consistencyDropped=0 foodTab=20 afterCollapse=10
-- survey 2708357 in pool: true; its full-name score=0.900; 20th-best score in pool=0.600; pool rows scoring > survey: 0, == survey: 1
-- SR Legacy rows in the app's top 20 (Food tab): none; sources in top 20: {fdc_survey: 20}
-- Food tab order (rankAndTruncateFoodsByName, scored on food_summary.name), top 5; survey 2708357 rank=1
   score=0.900 2708357 fdc_survey "Pasta, cooked" (name shown: "Pasta")
   score=0.850 2708351 fdc_survey "Pasta, vegetable, cooked" (name shown: "Pasta")
   score=0.850 2708359 fdc_survey "Pasta, gluten free" (name shown: "Pasta")
   score=0.750 2708358 fdc_survey "Pasta, whole grain, cooked" (name shown: "Pasta")
   score=0.750 2708828 fdc_survey "Pasta with sauce, NFS" (name shown: "Pasta with sauce")
-- All tab / AI path after mergeAndRankMeals (OFF empty), top 5; survey 2708357 rank=1
   score=1.000 2708357 fdc_survey "Pasta, cooked" (name shown: "Pasta")
   score=0.850 2708828 fdc_survey "Pasta with sauce, NFS" (name shown: "Pasta with sauce")
   score=0.850 2708827 fdc_survey "Pasta with vegetables, no sauce or dressing" (name shown: "Pasta with vegetables")
   score=0.750 2708855 fdc_survey "Pasta with cream sauce, restaurant" (name shown: "Pasta with cream sauce")
   score=0.683 2708830 fdc_survey "Pasta with tomato-based sauce, restaurant" (name shown: "Pasta with tomato-based sauce")
-- AI path after rankForResolution, top 5; survey 2708357 rank=1
   score=1.000 2708357 fdc_survey "Pasta, cooked" (name shown: "Pasta")
   score=0.500 2708828 fdc_survey "Pasta with sauce, NFS" (name shown: "Pasta with sauce")
   score=0.500 2708827 fdc_survey "Pasta with vegetables, no sauce or dressing" (name shown: "Pasta with vegetables")
   score=0.400 2708855 fdc_survey "Pasta with cream sauce, restaurant" (name shown: "Pasta with cream sauce")
   score=0.333 2708830 fdc_survey "Pasta with tomato-based sauce, restaurant" (name shown: "Pasta with tomato-based sauce")
-- records sharing the winner's shown name "Pasta" in the Food-tab list (collapsed to one): [2708357, 2708351, 2708359, 2708358, 2708903]

=== yoghurt  pool=0 truncated=0 consistencyDropped=0 foodTab=0 afterCollapse=0
-- survey 2705418 in pool: false; its full-name score=null; 20th-best score in pool=null; pool rows scoring > survey: n/a, == survey: n/a
-- SR Legacy rows in the app's top 20 (Food tab): none; sources in top 20: {}
-- Food tab order (rankAndTruncateFoodsByName, scored on food_summary.name), top 5; survey 2705418 rank=-1
-- All tab / AI path after mergeAndRankMeals (OFF empty), top 5; survey 2705418 rank=-1
-- AI path after rankForResolution, top 5; survey 2705418 rank=-1

=== almonds  pool=100 truncated=20 consistencyDropped=0 foodTab=20 afterCollapse=3
-- survey 2707486 in pool: true; its full-name score=0.900; 20th-best score in pool=0.450; pool rows scoring > survey: 0, == survey: 5
-- SR Legacy rows in the app's top 20 (Food tab): #6:170567 #10:170568 #12:169060 #13:170656 #14:168592 #15:168754 #16:168602 #18:168596 #19:169419 #20:170158; sources in top 20: {fdc_survey: 8, fdc_sr_legacy: 10, fdc_foundation: 2}
-- Food tab order (rankAndTruncateFoodsByName, scored on food_summary.name), top 5; survey 2707486 rank=2
   score=0.900 2707485 fdc_survey "Almonds, NFS" (name shown: "Almonds")
   score=0.900 2707486 fdc_survey "Almonds, unroasted" (name shown: "Almonds")
   score=0.900 2707487 fdc_survey "Almonds, salted" (name shown: "Almonds")
   score=0.900 2707489 fdc_survey "Almonds, unsalted" (name shown: "Almonds")
   score=0.900 2707490 fdc_survey "Almonds, flavored" (name shown: "Almonds")
-- All tab / AI path after mergeAndRankMeals (OFF empty), top 5; survey 2707486 rank=-1
   score=1.000 2707485 fdc_survey "Almonds, NFS" (name shown: "Almonds")
   score=0.000 170567 fdc_sr_legacy "Nuts, almonds" (name shown: "Nuts")
   score=0.000 169060 fdc_sr_legacy "Candies, nougat, with almonds" (name shown: "Candies")
-- AI path after rankForResolution, top 5; survey 2707486 rank=-1
   score=1.000 2707485 fdc_survey "Almonds, NFS" (name shown: "Almonds")
   score=0.000 170567 fdc_sr_legacy "Nuts, almonds" (name shown: "Nuts")
   score=0.000 169060 fdc_sr_legacy "Candies, nougat, with almonds" (name shown: "Candies")
-- records sharing the winner's shown name "Almonds" in the Food-tab list (collapsed to one): [2707485, 2707486, 2707487, 2707489, 2707490, 2707488, 2707491, 2710326]
```

### What the winner delivers

`portions_by_food_ids(ids, 'en')` for the record the harness lands on
(in its input order — see above for which rows that order decides) against
the one #1155 tabulated:

| Term | Lands on | Delivered portions | #1155's record delivered |
| --- | --- | --- | --- |
| banana | 2709224 | `1 banana` 126, `1 slice` 6, `1 cup` 150, `1 cup, mashed` 225, `1 linear inch` 15 | same |
| apple | 2709196 *Apple, dried* | `1 slice/chunk` 8, `1 cup` 90 | `1 small` 165, `1 medium` 200, `1 large` 242, `1 extra large` 295, `1 slice` 25, `1 cup` 125, `1 single serving package` 34 |
| rice | 2708402 | `1 cup, cooked` 158 | `1 cup, cooked` 158 |
| chicken breast | 2705963 | `1 cup, cooked, diced` 135, `1 breast` 130, `1 small or thin slice` 30, `1 medium slice` 60, `1 large or thick slice` 85, `1 oz, cooked` 28.35, `1 breast quarter (…)` 155 | adds `1 small breast` 105, `1 medium breast` 120, `1 large breast` 135 |
| salad | 2706826 *Salmon salad* | `1 cup` 208 | `1 leaf` 8, `1 head` 539, `1 cup` 35 |
| bread | 2707598 | as in #1155 | same |
| egg | 2707179 *Egg, creamed* | `1 egg` 145, `1 cup` 135 | `1 egg` 50, `1 cup` 245 |
| milk | 2705383 *Milk, human* | `1 cup` 246, `1 fl oz` 30.8 | `1 cup` 244, `1 fl oz` 30.5, `1 individual school container` 244 |
| coffee | 2710375 | as in #1155 | same |
| pasta | 2708357 | as in #1155 | same |
| yoghurt | — | nothing | `1 4 oz container` 113, `1 6 oz container` 170, `1 cup` 245 (from #1155) |
| almonds | 2707485 | the same five labels as 2707486 | same |

Apple loses its whole size ladder; egg's `1 egg` becomes 145 g; milk's cup
is human milk at 246 g rather than whole milk at 244 g; the rest deliver
the same labels either way.

```sql
WITH w(term, role, food_id) AS (VALUES
  ('banana','app lands on = assumed',2709224),
  ('apple','app lands on',2709196),('apple','assumed',2709215),
  ('rice','app lands on',2708402),('rice','assumed',2708408),
  ('chicken breast','app lands on',2705963),('chicken breast','assumed',2705956),
  ('salad','app lands on',2706826),('salad','assumed',2709789),
  ('bread','app lands on = assumed',2707598),
  ('egg','app lands on',2707179),('egg','assumed',2707152),
  ('milk','app lands on',2705383),('milk','assumed',2705385),
  ('coffee','app lands on = assumed',2710375),
  ('pasta','app lands on = assumed',2708357),
  ('yoghurt','app lands on: nothing (0 rows)',NULL),('yoghurt','assumed',2705418),
  ('almonds','app lands on',2707485),('almonds','assumed',2707486))
SELECT w.term, w.role, w.food_id, f.description,
       (SELECT string_agg(p.label || ' ' || p.gram_weight || 'g', ' | ' ORDER BY p.seq) FROM portions_by_food_ids(ARRAY[w.food_id], 'en') p) AS delivered_portions
FROM w LEFT JOIN food f ON f.id = w.food_id
ORDER BY array_position(ARRAY['banana','apple','rice','chicken breast','salad','bread','egg','milk','coffee','pasta','yoghurt','almonds'], w.term), w.role;
-- (the table above)
```

### Where OFF sits in the merge

OFF is not a tier above Supabase, but it is first-seen. The typed search's
*All* tab
([`add_meal_screen.dart`](../lib/features/add_meal/presentation/add_meal_screen.dart)
345) and the AI path both call `mergeAndRankMeals(products = OFF, foods =
Supabase, query)`, which concatenates `[...OFF, ...Supabase]` before
deduplicating. Only custom meals and recipes form a higher tier; OFF and
Supabase records interleave purely by score. Two order effects favour OFF
anyway: an OFF product with no brand whose normalized name equals a
Supabase `short_title` (*Milk*, *Banana*) lands in the same near-duplicate
group and, at equal score, is kept as first seen while the Supabase record
is dropped — a branded OFF product never merges with an unbranded Supabase
one; and both sorts are stable, so equal scores keep OFF ahead. The OFF list
itself is ordered in
[`products_repository.dart`](../lib/features/add_meal/data/repository/products_repository.dart)
36–98: OFF's relevance position fused with `popularity_key` by reciprocal
rank fusion (k = 10), ×1.3 for products sold in the user's country,
Atwater-inconsistent products demoted, top 25. OFF was not called for this
note; the harness ran with the OFF list empty, so the winners above hold
for a query where OFF returns nothing or nothing sharing a shown name. The
Food tab shows the Supabase list alone, without OFF and without either
re-ranker.

## Translation

### Nothing points at a NULL-description portion

`food_portion_translation` is keyed by `(food_portion_id, locale)`. All
92,704 of its rows — 11,588 portions × 8 locales (`cs`, `de`, `it`, `pl`,
`sk`, `tr`, `uk`, `zh`), every row `ai_generated`, `source = 'verified'` on
the 11,588 `de` rows and `machine` elsewhere per #1155 — sit on survey
portions. Zero rows key to an SR Legacy or Foundation portion; the table's
own `modifier` column is `NULL` on every row. A COALESCEd label would
therefore be English with `localized = false` in all nine locales,
including `de`, which is what the RPC already returns for any row without a
verified translation.

```sql
SELECT count(*) AS translation_rows_on_null_desc FROM food_portion_translation t JOIN food_portion fp ON fp.id = t.food_portion_id WHERE fp.portion_description IS NULL;
-- 0

SELECT f.source, t.locale, count(*) AS rows, count(DISTINCT t.food_portion_id) AS portions
FROM food_portion_translation t JOIN food_portion fp ON fp.id = t.food_portion_id JOIN food f ON f.id = fp.food_id
GROUP BY 1,2 ORDER BY 1,2;
-- fdc_survey x {cs,de,it,pl,sk,tr,uk,zh}: 11588 rows / 11588 portions each; no other source

SELECT count(*) AS rows, count(DISTINCT food_portion_id) AS portions, count(DISTINCT locale) AS locales, count(*) FILTER (WHERE ai_generated) AS ai_generated FROM food_portion_translation;
-- 92704 | 11588 | 8 | 92704

SELECT count(*) AS rows_with_modifier, count(*) FILTER (WHERE btrim(modifier) <> '') AS nonblank_modifier,
       count(*) FILTER (WHERE portion_description IS NULL) AS null_desc, count(*) FILTER (WHERE btrim(portion_description) = '') AS blank_desc
FROM food_portion_translation WHERE modifier IS NOT NULL OR portion_description IS NULL OR btrim(portion_description) = '';
-- 0 | 0 | 0 | 0

SELECT count(DISTINCT m.modifier) AS modifier_values_equal_to_a_translated_survey_label, count(DISTINCT m.food_id) AS foods
FROM food_portion m
WHERE m.portion_description IS NULL AND m.modifier IN (
  SELECT DISTINCT fp.portion_description FROM food_portion fp
  JOIN food_portion_translation t ON t.food_portion_id = fp.id AND t.source = 'verified'
  WHERE fp.portion_description IS NOT NULL);
-- 0 | 0
```

### Overlap with the 109 seeded labels

The seeded set is the 109 distinct English `portion_description` values
that have a translation row (case-folded, trimmed). Every one of them begins
with `1 ` (two with `1/2 `), so the exact overlap with the 1,892 distinct
NULL-description modifiers is zero. With `1 ` prepended, 39 modifiers match:

`bar`, `can`, `can (12 fl oz)`, `chip`, `cracker`, `cubic inch`, `cup`,
`cup (8 fl oz)`, `cup, cooked`, `cup, diced`, `cup, mashed`, `cup, pieces`,
`cup, shredded`, `egg`, `fl oz`, `fruit`, `jar`, `kernel`, `large`,
`medium`, `miniature`, `nut`, `oz`, `package`, `packet`, `patty`, `piece`,
`pouch`, `regular`, `sandwich`, `slice`, `slice, snack-size`, `small`,
`spear`, `steak`, `stick`, `tablespoon`, `thin`, `whole`.

37 of the 39 occur on SR Legacy; `thin` and `whole` only on Foundation
rows. On SR Legacy the 37 cover 6,967 rows on 5,495 foods (73% of 7,533)
by modifier alone — but only 4,387 rows on 3,580 foods (48%) have
`amount = 1`, where a prepended `1 ` is the honest label. Matching
`amount::text || ' ' || modifier` against the seeded set gives exactly
those 4,387 rows, 3,580 foods and 37 modifiers, and zero rows at any other
amount. `oz` is the
extreme: 999 of its 3,166 rows are `1 oz`; `cup` is 1,469 of 1,691; `fl
oz` 364 of 492; `steak`, `jar`, `slice` and `piece` are at or near 100%.
Every seeded label has exactly one translation string per locale, so a
copy-by-label would be unambiguous; but nothing exists for any SR Legacy
portion id until rows are inserted (14,449 × 8 = 115,592 for parity; 4,387
× 8 = 35,096 for the honest overlap).

| | Rows | Foods | Modifiers |
| --- | ---: | ---: | ---: |
| SR Legacy rows whose modifier is a seeded label minus `1 ` | 6,967 | 5,495 | 37 |
| … of those, `amount = 1` | 4,387 | 3,580 | 37 |
| `amount::text || ' ' || modifier` equal to a seeded label | 4,387 | 3,580 | 37 |
| Foundation rows, same test | 15 | 9 | — |

```sql
WITH seeded AS (SELECT DISTINCT lower(btrim(fp.portion_description)) AS label FROM food_portion fp WHERE EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = fp.id)),
nullmod AS (SELECT DISTINCT lower(btrim(fp.modifier)) AS m FROM food_portion fp WHERE fp.portion_description IS NULL AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '')
SELECT (SELECT count(*) FROM seeded) AS seeded_labels,
       (SELECT count(*) FROM nullmod) AS distinct_null_desc_modifiers,
       (SELECT count(*) FROM nullmod n WHERE EXISTS (SELECT 1 FROM seeded s WHERE s.label = n.m)) AS exact_overlap,
       (SELECT count(*) FROM nullmod n WHERE EXISTS (SELECT 1 FROM seeded s WHERE s.label = '1 ' || n.m)) AS leading_one_overlap,
       (SELECT count(*) FROM nullmod n WHERE EXISTS (SELECT 1 FROM seeded s WHERE s.label = n.m OR s.label = '1 ' || n.m)) AS either_overlap;
-- 109 | 1892 | 0 | 39 | 39

WITH seeded AS (SELECT DISTINCT lower(btrim(fp.portion_description)) AS label FROM food_portion fp WHERE EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = fp.id)),
nullmod AS (SELECT DISTINCT lower(btrim(fp.modifier)) AS m FROM food_portion fp WHERE fp.portion_description IS NULL AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '')
SELECT n.m AS modifier, (EXISTS (SELECT 1 FROM seeded s WHERE s.label = n.m)) AS exact, (EXISTS (SELECT 1 FROM seeded s WHERE s.label = '1 ' || n.m)) AS with_leading_one
FROM nullmod n WHERE EXISTS (SELECT 1 FROM seeded s WHERE s.label = n.m OR s.label = '1 ' || n.m) ORDER BY 1;
-- 39 rows, all exact = f, with_leading_one = t (the list above)

SELECT string_agg(label, ' ; ' ORDER BY label) FROM (SELECT DISTINCT fp.portion_description AS label FROM food_portion fp WHERE EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = fp.id)) s;
-- 109 labels, every one beginning '1 ' or '1/2 '

WITH seeded AS (SELECT DISTINCT lower(btrim(fp.portion_description)) AS label FROM food_portion fp WHERE EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = fp.id))
SELECT f.source, count(*) AS null_desc_rows, count(DISTINCT fp.food_id) AS foods,
       count(*) FILTER (WHERE EXISTS (SELECT 1 FROM seeded s WHERE s.label = '1 ' || lower(btrim(fp.modifier)))) AS overlap_rows,
       count(DISTINCT fp.food_id) FILTER (WHERE EXISTS (SELECT 1 FROM seeded s WHERE s.label = '1 ' || lower(btrim(fp.modifier)))) AS overlap_foods,
       count(*) FILTER (WHERE fp.amount = 1 AND EXISTS (SELECT 1 FROM seeded s WHERE s.label = '1 ' || lower(btrim(fp.modifier)))) AS overlap_rows_amount_1,
       count(DISTINCT fp.food_id) FILTER (WHERE fp.amount = 1 AND EXISTS (SELECT 1 FROM seeded s WHERE s.label = '1 ' || lower(btrim(fp.modifier)))) AS overlap_foods_amount_1
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE fp.portion_description IS NULL
GROUP BY 1 ORDER BY 1;
-- fdc_foundation 186 | 116 | 15 | 9 | 15 | 9 ; fdc_sr_legacy 14449 | 7533 | 6967 | 5495 | 4387 | 3580

WITH seeded AS (SELECT DISTINCT lower(btrim(fp.portion_description)) AS label FROM food_portion fp WHERE EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = fp.id))
SELECT count(*) AS rows_amount_modifier_matches_seeded, count(DISTINCT fp.food_id) AS foods, count(DISTINCT lower(btrim(fp.modifier))) AS distinct_modifiers,
       count(*) FILTER (WHERE fp.amount <> 1) AS rows_amount_not_1
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE f.source = 'fdc_sr_legacy' AND fp.portion_description IS NULL
  AND EXISTS (SELECT 1 FROM seeded s WHERE s.label = lower(btrim(fp.amount::text || ' ' || fp.modifier)));
-- 4387 | 3580 | 37 | 0

SELECT lower(btrim(fp.modifier)) AS m, count(*) AS rows, count(*) FILTER (WHERE fp.amount = 1) AS rows_amount_1, count(*) FILTER (WHERE fp.amount <> 1) AS rows_amount_not_1, count(DISTINCT fp.food_id) FILTER (WHERE fp.amount = 1) AS foods_amount_1
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE f.source = 'fdc_sr_legacy' AND fp.portion_description IS NULL AND lower(btrim(fp.modifier)) IN ('oz','cup','fl oz','steak','slice','piece','jar') GROUP BY 1 ORDER BY 2 DESC;
-- oz 3166 | 999 | 2167 | 995 ; cup 1691 | 1469 | 222 | 1469 ; fl oz 492 | 364 | 128 | 364 ; steak 280 | 280 | 0 | 280 ; slice 186 | 185 | 1 | 184 ; piece 147 | 146 | 1 | 145 ; jar 131 | 131 | 0 | 130

WITH lab AS (SELECT lower(btrim(fp.portion_description)) AS label, t.locale, t.portion_description AS tr FROM food_portion fp JOIN food_portion_translation t ON t.food_portion_id = fp.id)
SELECT locale, count(DISTINCT label) AS labels, count(DISTINCT label) FILTER (WHERE n > 1) AS labels_with_multiple_translations, sum(n) AS distinct_translation_strings
FROM (SELECT label, locale, count(DISTINCT tr) AS n FROM lab GROUP BY 1,2) x GROUP BY locale ORDER BY locale;
-- every locale: 109 | 0 | 109

WITH seeded AS (SELECT DISTINCT lower(btrim(fp.portion_description)) AS label FROM food_portion fp WHERE EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = fp.id)),
nullmod AS (SELECT lower(btrim(fp.modifier)) AS m, f.source FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE fp.portion_description IS NULL AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> '')
SELECT m, string_agg(DISTINCT source, ',') AS sources FROM nullmod n WHERE EXISTS (SELECT 1 FROM seeded s WHERE s.label = '1 ' || n.m) GROUP BY m HAVING bool_and(source <> 'fdc_sr_legacy') ORDER BY 1;
-- thin fdc_foundation ; whole fdc_foundation

\d food_portion_translation
-- (food_portion_id, locale, portion_description, modifier, source, ai_generated, updated_at); PK (food_portion_id, locale); FK cascade
```

### The top unseeded modifiers

The twenty modifiers with no seeded equivalent, exact or with `1 `
prepended, by distinct foods. All twenty are SR Legacy only.

| Modifier | Foods | Rows | Distinct amounts | `amount` range |
| --- | ---: | ---: | ---: | --- |
| `tbsp` | 553 | 553 | 6 | 1–5 |
| `lb` | 281 | 281 | | 0.25–1 |
| `serving` | 265 | 265 | 1 | 1 |
| `piece, cooked, excluding refuse (yield from 1 lb raw meat with refuse)` | 212 | 212 | 1 | 1 |
| `roast` | 185 | 185 | 1 | 1 |
| `tsp` | 163 | 171 | | 0.25–4 |
| `fillet` | 162 | 162 | | 0.5–1 |
| `unit (yield from 1 lb ready-to-cook chicken)` | 106 | 106 | | 0.5–1 |
| `cup (1 nlea serving)` | 98 | 98 | 9 | 0.25–1.5 |
| `cup, chopped` | 71 | 71 | | |
| `cup slices` | 67 | 68 | | |
| `cup, chopped or diced` | 58 | 58 | | |
| `chop` | 57 | 57 | | |
| `item` | 53 | 53 | | |
| `cup, sliced` | 51 | 51 | | |
| `scoop` | 46 | 46 | | 1–3 |
| `cup, cubes` | 40 | 43 | | |
| `pieces` | 39 | 46 | 16 | 2–27 |
| `package (10 oz)` | 37 | 50 | | 0–1 |
| `nlea serving` | 37 | 37 | | |

`tbsp` and `tsp` are unseeded while the survey spelling `1 tablespoon` is
seeded; `lb`, `serving`, `nlea serving` and the two `(yield from 1 lb …)`
strings are FDC measure or bookkeeping rather than household names.

```sql
WITH seeded AS (SELECT DISTINCT lower(btrim(fp.portion_description)) AS label FROM food_portion fp WHERE EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = fp.id))
SELECT lower(btrim(fp.modifier)) AS modifier, count(DISTINCT fp.food_id) AS foods, count(*) AS rows,
       count(DISTINCT fp.food_id) FILTER (WHERE f.source = 'fdc_sr_legacy') AS sr_legacy_foods,
       count(DISTINCT fp.amount) AS distinct_amounts, min(fp.amount) AS min_amount, max(fp.amount) AS max_amount
FROM food_portion fp JOIN food f ON f.id = fp.food_id
WHERE fp.portion_description IS NULL AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> ''
  AND NOT EXISTS (SELECT 1 FROM seeded s WHERE s.label = lower(btrim(fp.modifier)) OR s.label = '1 ' || lower(btrim(fp.modifier)))
GROUP BY 1 ORDER BY 2 DESC, 3 DESC, 1 LIMIT 20;
-- tbsp 553 ; lb 281 ; serving 265 ; piece, cooked, excluding refuse (yield from 1 lb raw meat with refuse) 212 ; roast 185 ; tsp 163 ; fillet 162 ;
-- unit (yield from 1 lb ready-to-cook chicken) 106 ; cup (1 nlea serving) 98 ; cup, chopped 71 ; cup slices 67 ; cup, chopped or diced 58 ; chop 57 ;
-- item 53 ; cup, sliced 51 ; scoop 46 ; cup, cubes 40 ; pieces 39 ; package (10 oz) 37 ; nlea serving 37   (all SR Legacy)
```

### The coverage curve

Ranking the 1,853 case-folded SR Legacy modifiers by distinct foods and
assigning each food to its best-ranked modifier: **16 modifiers cover 75%**
of the 7,533 foods (5,660, 75.1%) and **120 cover 90%** (6,789, 90.1%). Of
the 16, seven are already seeded via the `1 ` prefix; of the 120, 26 are.
Counted by rows instead, the way #864 counted the survey vocabulary, 109
modifiers cover 75% of the 14,449 rows (75.07% at rank 109, `stick`) and 601
cover 90% — the same 109 as #864's survey figure, which is a coincidence
checked against the curve at ranks 107–111.

| Rank | Modifier | Foods | Cumulative foods | Cumulative % | Seeded with `1 ` |
| ---: | --- | ---: | ---: | ---: | --- |
| 1 | `oz` | 3,041 | 3,041 | 40.4 | yes |
| 2 | `cup` | 1,643 | 4,550 | 60.4 | yes |
| 3 | `tbsp` | 553 | | | |
| 4 | `fl oz` | 440 | | | yes |
| 5 | `lb` | 281 | | | |
| 6 | `steak` | 280 | | | yes |
| 7 | `serving` | 265 | | | |
| 8 | `piece, cooked, excluding refuse (yield from 1 lb raw meat with refuse)` | 212 | | | |
| 9 | `roast` | 185 | | | |
| 10 | `slice` | 185 | | | yes |
| 11 | `tsp` | 163 | | | |
| 12 | `fillet` | 162 | | | |
| 13 | `piece` | 146 | | | yes |
| 14 | `jar` | 130 | | | yes |
| 15 | `unit (yield from 1 lb ready-to-cook chicken)` | 106 | | | |
| 16 | `cup (1 nlea serving)` | 98 | 5,660 | 75.1 | |
| 17 | `tablespoon` | 91 | | | yes |
| 18 | `cup (8 fl oz)` | 90 | | | yes |
| 19 | `cup, chopped` | 71 | | | |
| 20 | `cup slices` | 67 | | 78.0 | |

```sql
WITH sr AS (SELECT fp.food_id, lower(btrim(fp.modifier)) AS m FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_sr_legacy' AND fp.portion_description IS NULL AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> ''),
total AS (SELECT count(DISTINCT food_id) AS foods FROM sr),
ranked AS (SELECT m, count(DISTINCT food_id) AS foods, row_number() OVER (ORDER BY count(DISTINCT food_id) DESC, m) AS rnk FROM sr GROUP BY m),
food_rank AS (SELECT sr.food_id, min(r.rnk) AS first_rank FROM sr JOIN ranked r ON r.m = sr.m GROUP BY sr.food_id),
curve AS (SELECT r.rnk, r.m, r.foods, sum(fr.n) OVER (ORDER BY r.rnk) AS cum_foods FROM ranked r LEFT JOIN (SELECT first_rank, count(*) AS n FROM food_rank GROUP BY 1) fr ON fr.first_rank = r.rnk)
SELECT (SELECT foods FROM total) AS sr_foods_nonblank_modifier,
       (SELECT count(*) FROM ranked) AS distinct_modifiers,
       (SELECT min(rnk) FROM curve, total WHERE cum_foods >= 0.75 * total.foods) AS values_for_75pct_foods,
       (SELECT min(rnk) FROM curve, total WHERE cum_foods >= 0.90 * total.foods) AS values_for_90pct_foods,
       (SELECT cum_foods FROM curve WHERE rnk = (SELECT min(rnk) FROM curve, total WHERE cum_foods >= 0.75 * total.foods)) AS cum_foods_at_75,
       (SELECT cum_foods FROM curve WHERE rnk = (SELECT min(rnk) FROM curve, total WHERE cum_foods >= 0.90 * total.foods)) AS cum_foods_at_90;
-- 7533 | 1853 | 16 | 120 | 5660 | 6789

WITH sr AS (SELECT fp.food_id, lower(btrim(fp.modifier)) AS m FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_sr_legacy' AND fp.portion_description IS NULL AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> ''),
seeded AS (SELECT DISTINCT lower(btrim(fp.portion_description)) AS label FROM food_portion fp WHERE EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = fp.id)),
ranked AS (SELECT m, count(DISTINCT food_id) AS foods, count(*) AS rows, row_number() OVER (ORDER BY count(DISTINCT food_id) DESC, m) AS rnk FROM sr GROUP BY m),
food_rank AS (SELECT sr.food_id, min(r.rnk) AS first_rank FROM sr JOIN ranked r ON r.m = sr.m GROUP BY sr.food_id),
curve AS (SELECT r.rnk, r.m, r.foods, r.rows, sum(coalesce(fr.n,0)) OVER (ORDER BY r.rnk) AS cum_foods FROM ranked r LEFT JOIN (SELECT first_rank, count(*) AS n FROM food_rank GROUP BY 1) fr ON fr.first_rank = r.rnk)
SELECT rnk, m, foods, rows, cum_foods, round(100.0 * cum_foods / 7533, 1) AS cum_pct, EXISTS (SELECT 1 FROM seeded s WHERE s.label = '1 ' || c.m) AS seeded_with_leading_one
FROM curve c WHERE rnk <= 20 ORDER BY rnk;
-- (the table above; rank 1 oz -> 3041 = 40.4% ; rank 2 cup -> 4550 = 60.4% ; rank 16 cup (1 nlea serving) -> 5660 = 75.1% ; rank 20 cup slices -> 78.0%)

WITH sr AS (SELECT fp.food_id, lower(btrim(fp.modifier)) AS m FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_sr_legacy' AND fp.portion_description IS NULL AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> ''),
seeded AS (SELECT DISTINCT lower(btrim(fp.portion_description)) AS label FROM food_portion fp WHERE EXISTS (SELECT 1 FROM food_portion_translation t WHERE t.food_portion_id = fp.id)),
ranked AS (SELECT m, count(DISTINCT food_id) AS foods, row_number() OVER (ORDER BY count(DISTINCT food_id) DESC, m) AS rnk FROM sr GROUP BY m)
SELECT count(*) FILTER (WHERE rnk <= 16) AS top16, count(*) FILTER (WHERE rnk <= 16 AND EXISTS (SELECT 1 FROM seeded s WHERE s.label = '1 ' || r.m)) AS top16_seeded,
       count(*) FILTER (WHERE rnk <= 120) AS top120, count(*) FILTER (WHERE rnk <= 120 AND EXISTS (SELECT 1 FROM seeded s WHERE s.label = '1 ' || r.m)) AS top120_seeded,
       count(*) FILTER (WHERE EXISTS (SELECT 1 FROM seeded s WHERE s.label = '1 ' || r.m OR s.label = r.m)) AS sr_modifiers_seeded_any
FROM ranked r;
-- 16 | 7 | 120 | 26 | 37

WITH sr AS (SELECT fp.food_id, lower(btrim(fp.modifier)) AS m FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_sr_legacy' AND fp.portion_description IS NULL AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> ''),
ranked AS (SELECT m, count(*) AS rows, row_number() OVER (ORDER BY count(*) DESC, m) AS rnk FROM sr GROUP BY m),
curve AS (SELECT rnk, sum(rows) OVER (ORDER BY rnk) AS cum_rows FROM ranked)
SELECT (SELECT count(*) FROM sr) AS sr_rows, (SELECT count(*) FROM ranked) AS distinct_modifiers,
       (SELECT min(rnk) FROM curve WHERE cum_rows >= 0.75 * (SELECT count(*) FROM sr)) AS values_for_75pct_rows,
       (SELECT min(rnk) FROM curve WHERE cum_rows >= 0.90 * (SELECT count(*) FROM sr)) AS values_for_90pct_rows;
-- 14449 | 1853 | 109 | 601

WITH sr AS (SELECT fp.food_id, lower(btrim(fp.modifier)) AS m FROM food_portion fp JOIN food f ON f.id = fp.food_id WHERE f.source = 'fdc_sr_legacy' AND fp.portion_description IS NULL AND fp.modifier IS NOT NULL AND btrim(fp.modifier) <> ''),
ranked AS (SELECT m, count(*) AS rows, row_number() OVER (ORDER BY count(*) DESC, m) AS rnk FROM sr GROUP BY m),
curve AS (SELECT rnk, m, rows, sum(rows) OVER (ORDER BY rnk) AS cum_rows FROM ranked)
SELECT rnk, m, rows, cum_rows, round(100.0 * cum_rows / 14449, 2) AS cum_pct FROM curve WHERE rnk BETWEEN 107 AND 111 ORDER BY rnk;
-- 107 pepper 13 10821 74.89 ; 108 serving (3 oz) 13 10834 74.98 ; 109 stick 13 10847 75.07 ; 110 thigh 13 10860 75.16 ; 111 can (12 fl oz) 12 10872 75.24
```

## What this means for the map

Facts and their implications, for the tickets that read this note. None of
the following is a decision; whether the RPC changes is a later ticket's.

### Code facts that bound everything above

Read on `origin/develop` at `df6d54c8`:

- `portions_by_food_ids` computes its label from `portion_description` and
  the verified translation only; `modifier` and `amount` are not read, and
  `fetchPortions` keeps `label`, `gram_weight` and `localized` from each row
  and nothing else. A COALESCE without a count in the label leaves the app
  no way to recover the count, because `amount` never travels.
- `_termsOf` in [`portion_match.dart`](../lib/features/add_meal/util/portion_match.dart)
  strips parentheticals and keeps runs of three or more letters. The
  missing `1 ` is invisible to it; `oz`, `lb`, `fl oz`, `g` and `ml` yield
  no term at all; `large (8" to 8-7/8" long)` matches exactly as `1 large`
  would.
- `search_food_summary` has no `ORDER BY`; the pool is heap order, survey
  first. No scorer in the client-side chain reads `backendSource`, portions
  or gram weights; `source` is read to tier custom meals and recipes above
  the rest (`mergeAndRankMeals`, `rankForResolution`), as the prefix of the
  `source:code` dedup keys (`_deduplicateAcrossSources`,
  `_deduplicateMeals`, `_nearDuplicateKey`) and, with `backendSource`, to
  filter cached rows to the tab and to the user's source toggles
  (`_buildResult`); every Supabase record carries `source = fdc`, so none
  of those reads tells survey from SR Legacy. The shown name
  (`short_title`) decides the near-duplicate collapse on the AI path, and
  the order the search cache hands back decides which same-named sibling
  survives it.
- `food_summary.serving_size` already renders `amount || ' ' || modifier`
  for SR Legacy foods, so the count-synthesis expression exists in the
  backend and produces `3 oz`, `0.5 cup` and `0 cup` today.

### The premise the map states

"The size ladders are invisible" holds for the twelve foods, and for the
auto-selected record it would largely go on holding after a COALESCE, for a
reason #1155 did not have: for seven of the twelve no SR Legacy record can
enter the pool while the materialized view keeps its layout, and for ten of
the eleven that return anything every record that can win the AI path's
collapse is survey (the "Non-survey in the group" column of the per-term
table in [The harness run](#the-harness-run)). The exception is `chicken
breast`, where SR Legacy 174608 shares the winning shown name and the
search cache's order decides whether it is the one auto-selected. What a
COALESCE would change today, with no change to the ranker or the pool: the
portions on the SR Legacy candidates the AI path already hands the review
screen — #2 for banana (173945), chicken breast (171515) and almonds
(170567), plus 174608 for chicken breast (the table's "#2 after
resolution" and group columns) — since every candidate carries its
portions and the user can select any of them; the Food tab for banana,
apple, chicken breast and almonds, where SR Legacy records sit in the top
20 (its "SR Legacy in the 20" column); and every typed or AI search that
lands on one of the 7,529 SR Legacy foods that gain labels.

Separately, #1155's per-food tables describe the record the app receives
in four of twelve cases. The other survey siblings the app lands on are in
[What the winner delivers](#what-the-winner-delivers); apple's ladder is
on 2709215 and the app lands on 2709196, which has none.

### #1158 — the prompt vocabulary

- A COALESCE would not make size words common. They reach 245 SR Legacy
  foods after the strip (3.3%), against 1,430 survey foods (27%) in #1155's
  class table (quoted in [The classes](#the-classes)); `large` 178,
  `medium` 168, `small` 147. The generic ladders — banana,
  apple, egg, lettuce heads and leaves, potatoes — are real but few.
- It would make `cup` reach 1,643 more foods and, for the first time, give
  `tbsp` (548 foods) and `tsp` (163) a row; `tablespoon` gains 91 more. The
  sibling note found `tbsp` and `tsp` in no `portion_description`; the text
  prompt names both as non-units.
- The largest single addition would be unmatchable: 3,951 deliverable rows
  on 3,494 foods whose whole label is `oz`, `fl oz`, `lb`, `ml`, `liter` or
  `g`, and 4,028 rows on 3,569 foods that yield no term after the
  parenthetical strip (`oz (3 oz)`, `lb 16 oz` included, `liter` not);
  1,028 foods carry only the five bare units and 1,042 have no deliverable
  row that yields a term at all ([Bare units](#bare-units)). A model word
  can never select those rows; they would appear in the portion list and
  in the flat default only.
- Meat cuts (`steak` 280 foods, `roast` 185, `chop` 57) and
  the food's own noun (`potato large`, `almond`, `pizza`, `bar`) are terms
  the matcher sees though no class names them; the query-text fallback
  would hit them, as it hits `1 egg` and `1 sandwich` on survey rows today.
- `handful`, `plate`, `mug`, `bowl` and `glass`: the five photo words #1155
  found dead on survey rows are as good as dead in `modifier` too — `glass`
  on 2 rows (`glass (3.5 fl oz)`), `bowl` on 1, `handful`, `mug` and
  `plate` on none (#1155 had already counted those three at 0 table-wide).
  A COALESCE would not give the model those words.

  ```sql
  WITH words(word, rx) AS (VALUES ('bowl','\mbowls?\M'),('glass','\mglass(es)?\M'),('handful','\mhandfuls?\M'),('plate','\mplates?\M'),('mug','\mmugs?\M'))
  SELECT w.word,
         count(fp.id) FILTER (WHERE fp.modifier ~* w.rx) AS modifier_rows_null_desc,
         count(DISTINCT fp.food_id) FILTER (WHERE fp.modifier ~* w.rx) AS modifier_foods_null_desc,
         string_agg(DISTINCT fp.modifier, ' ; ') FILTER (WHERE fp.modifier ~* w.rx) AS values
  FROM words w LEFT JOIN food_portion fp ON fp.portion_description IS NULL AND fp.modifier ~* w.rx
  GROUP BY w.word ORDER BY 2 DESC, w.word;
  -- glass 2 | 2 | glass (3.5 fl oz) ; bowl 1 | 1 | bowl ; handful 0 ; mug 0 ; plate 0
  ```

### #1157 — the language of the key

- Every label a COALESCE exposes is English, `localized = false`, in all
  nine locales — `de` included, since zero translation rows key to any SR
  Legacy portion. An "app language" key would match nothing on those rows
  anywhere; an "always English" key would match them everywhere.
- The overlap with the seeded set is by label text, not by id: 39 of the
  109 seeded labels equal a modifier with `1 ` prepended, honest on 4,387
  rows (3,580 foods, 48% of SR Legacy foods) at `amount = 1`, and on none
  of the 3,458 deliverable rows at another amount. `food_portion_translation`
  is keyed by `food_portion_id`, so reusing those translations means new
  rows (35,096 for the honest overlap, 115,592 for parity), not a lookup.
- `tbsp`, `tsp`, `lb`, `serving`, `roast`, `fillet` head the unseeded
  list; the seeded set has `1 tablespoon` but no abbreviation.

### #1162 — the tie rule

- SR Legacy labels repeat within a food. On the 14,341 deliverable rows, 307
  food/label pairs are identical inside one food (626 rows); 290 differ in
  `amount`, 17 share it and differ only in grams. The earlier-row rule picks the
  first silently: `oz` on 123 foods (`3 oz` at 85 g before or after `1 oz`
  at 28.35 g, by `seq_num`), white bread's `slice` 29 g over 25 g. Survey
  rows never repeat a label (#1155), so this class of tie is new.
- Read off the matcher, not run: because `_words` splits `extra large` into
  two five-letter tokens and scores by the longest matched term, the SR
  Legacy banana ladder in `seq_num` order (`extra small`, `small`, `medium`,
  `large`, `extra large`) resolves `small` to `extra small` (81 g, not 101
  g) and `extra large` to `extra small` (81 g, not 152 g), since `extra
  small` is the earliest row carrying either term; `large` and `medium`
  resolve correctly. #1155 found the same shape on survey apple (`large`
  beats `1 extra large`); the SR Legacy order puts the extra-small row
  first and so turns the benign case into a wrong one.
- The dimension parentheticals (`(8" to 8-7/8" long)`, `(3" dia)`) are
  stripped before matching, so they never break a tie and never help one;
  they reach the user's eye only.

### The "not yet specified" item — a portion word steering the food match

- No scorer in the chain reads portions, so a portion word cannot today
  steer toward a record that carries labels. The measurement here says how
  often that would matter for the auto-selected record on the AI path for
  the twelve foods: for eight no SR Legacy record is in the pool (seven
  pools are 100% survey, `yoghurt` is empty); for banana, apple and almonds
  SR Legacy records are in the 20 but none shares the winning shown name,
  so every record that can win is survey; for `chicken breast` the winner
  is already order-dependent among survey, SR Legacy and BLS records shown
  as *Chicken breast* (the per-term table in [The harness
  run](#the-harness-run)). It says nothing about foods outside the twelve.

## Reproducing

1. Source the gitignored `.env` and connect: `psql "$SUPABASE_DB_URL"`. The
   variable is named in this file and never valued; its value must not be
   pasted into a note or a commit.
2. Every query is complete as printed. The `sr` CTE in [What a COALESCE
   would expose](#what-a-coalesce-would-expose) is repeated in full where
   it is used.
3. Results are appended as `--` comments and were taken on 2026-09-11. They
   move when `food_portion` or `food_portion_translation` is reseeded, and
   the pool figures in [Which record the app receives](#which-record-the-app-receives)
   move on any `REFRESH MATERIALIZED VIEW food_summary`; the baseline
   counts and the heap layout are the first things to re-check.
4. The Dart harness: create a worktree on `origin/develop`, run `flutter
   pub get` with the pinned SDK, copy the gitignored generated files
   (`lib/core/utils/env.g.dart`, `lib/generated/`) from a built checkout,
   export the pools with the `json_object_agg` query above, and feed them
   through `rankAndTruncateFoodsByName` → `MealEntity.fromSpFood` →
   `validateNutriments` → `mergeAndRankMeals(const [], fdc, term)` →
   `rankForResolution` in a `flutter test` file, printing per term: the
   pool, truncated and post-collapse sizes; the survey record's full-name
   score against the 20th-best; every SR Legacy row in the 20-row list with
   its rank (`#15:167629 …`) and the source mix; the top five at each of
   the three stages with scores; and the codes sharing the winner's shown
   name. The Food-tab ranks and the collapse groups cited above come from
   the third and last of those lines, not from the top fives. The file is
   printed verbatim in [The harness run](#the-harness-run) with the output
   it wrote; save it under `test/`, point `poolPath` at the exported JSON
   and `outPath` at a writable file, and `flutter test test/<file>` prints
   the same listing. Re-run once more on 2026-09-11 in the worktree
   [Method](#method) describes, with the generated files copied back in,
   before this note was finalised; the output was byte-identical.

## Not verified

- **The matcher outcomes on the SR Legacy ladders** in [#1162](#1162--the-tie-rule)
  are read off `portion_match.dart`, not run; the harness ran the search
  ranker, not the portion matcher.
- **OFF.** Not called. The AI-path winners hold for an empty OFF list or one
  sharing no shown name with a Supabase record; a live OFF response can
  replace any of them through the near-duplicate collapse.
- **The search cache's order.** The harness fed `mergeAndRankMeals` the
  list `getSupabaseFoodsByString` returns; the app feeds it `_buildResult`'s,
  which has been through the cache (step 3). The ten order-decided winners
  in [The harness run](#the-harness-run) are the fresh-install, first-search
  outcome with OFF empty (20 cache entries, insertion sort, order kept) and
  were not confirmed
  on a device with a populated cache; for `chicken breast` the auto-selected
  record could be survey, SR Legacy 174608 or BLS. The per-term
  survey-versus-SR-Legacy conclusions do not depend on it except there.
- **The other assumptions the harness fixes** — no custom meals, recipes,
  intake history or previously cached hits; English locale; all source
  toggles on; the bare term as the query. A previously cached record with
  the same shown name, or one whose timestamp a logged intake bumped, is
  first seen and wins ties.
- **The translation path** (`search_food_translation`,
  `food_summary_by_ids`, `portion_labels_by_food_ids`) is not exercised
  for English and was read for its `ORDER BY` only.
- **Foods outside the twelve.** Which record the app lands on for any other
  term was not measured; the heap-order argument bounds it (an SR Legacy
  record enters the pool only when fewer than 100 survey names match) but
  does not decide it.
- **Whether `NFS` / `yield` rows in the SR Legacy modifier ever reach a
  user** through `food_summary.serving_size`. The expression carries no such
  filter; the view's row selection was not read for one. Not counted.
