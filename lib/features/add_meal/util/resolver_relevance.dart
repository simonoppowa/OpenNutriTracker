/// Relevance scoring for the bulk-add resolver (#601), deliberately kept
/// separate from `meal_relevance_ranker.dart`.
///
/// **Why a second scorer instead of fixing the first one.** The shared
/// ranker compares token *sets* for exact equality, so a query and a record
/// that differ only by an inflectional suffix do not intersect at all:
/// `eggs` against a record named `Egg` scores exactly 0.0, while
/// `Cadbury Creme Eggs` — which contains the literal plural — scores well
/// above it. Typed search hides this because the user sees the list and
/// picks; the resolver does not, because it auto-selects the top candidate,
/// so the same flaw turns into a silently wrong food in the diary.
///
/// The shared ranker is used by the live search screen, where its current
/// behaviour is what people already rely on. #601 therefore fixes the
/// ordering *here*, for the resolver only, and leaves that file alone.
///
/// The text agreement itself — soft prefix matching, and which of a
/// backend record's qualifiers a query names by it — lives in
/// `soft_text_score.dart`, because the data source's cut of the backend's
/// hundred rows to the twenty this scorer sees must apply the same rule
/// (#1170). What is here is the entity: brand, the quality tie-breakers,
/// the no-portions penalty, and the order among equals.
library;

import 'package:collection/collection.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/util/soft_text_score.dart';

/// Quality tie-breakers, matching the shared ranker so that near-equal text
/// matches resolve the same way in both places.
const _detailedBonus = 0.03;
const _machineTranslatedPenalty = 0.03;

/// Taken off a backend record that carries no labelled portion — here and
/// nowhere else (#1164).
///
/// The resolver's output is logged with an amount, and at that point a
/// record that can scale one is worth more than one that cannot. The case
/// this is for is an exact title with nothing behind it: the BLS record
/// "Orange juice" matches the query letter for letter and wins outright
/// over the survey records that actually carry fl-oz and juice-box rows.
/// The Food tab's plain search is untouched — `scoreMealRelevance` knows
/// nothing of this — because a German reader browsing the list wants the
/// native BLS record where it is, and the portionless record stays in the
/// candidate list either way.
///
/// The size is the one #1164 decided, and it works because both records
/// are scored on their title (`MealEntity.scoringName`): the survey's
/// "Orange juice, 100%, NFS" — its plain record; there is no row named
/// just "Orange juice, 100%" — is titled "Orange juice" and scores 1.0
/// exactly as the BLS record does, so at 0.85 the BLS record drops behind
/// it. Scored on its description it would sit at 0.667, this scorer being
/// harder on extra tokens than the shared ranker, and the penalty would
/// not reach: that was the measured order for one revision of this
/// branch. The test pins the order, so a change to the size is a
/// deliberate one and not a side effect.
///
/// "No labelled portion" is read off `MealEntity.portions`, which only a
/// fresh backend result carries: `MealDBO` does not persist portions. On
/// the resolver's real path `SearchProductsUseCase` lists cached copies
/// ahead of fresh ones, and for a record this search's page returned it
/// puts the fresh entity in the cached copy's place, so the penalty and
/// the portions key see the page as the backend sent it. A record held
/// only in the cache — from an earlier search, or the whole pool when the
/// remote is down — has no portions to show and is penalised whatever the
/// backend has for it. It is still scored on its title, which derives
/// from the name the cache does keep, so a cached sibling trails the
/// fresh ones by this penalty alone: 0.85 against 1.0, above the
/// confidence floor. That is a gap between this rule and the data it is
/// given, not something the rule can see; #1164's review records it.
///
/// A fresh result with no portions is read one more way. The page's
/// portions come from a second call after the search itself, and when
/// that call fails the page arrives whole and every record on it is bare
/// — not because the backend has no portion for any of them, but because
/// nobody could ask. Penalising the whole page for that reported a search
/// that succeeded as a guess (a 0.5 match at 0.35, under the floor) and
/// put a bare backend record behind an OFF product it had outscored
/// (#1170 review). `ProductsRepository` marks those entities
/// `MealEntity.portionsUnavailable`, and this penalty stands down for
/// them: the record is scored on its text alone, as if the question had
/// not been asked, which is the truth of it. The flag is not persisted
/// either, so a cached copy is never "unavailable" — it is penalised as
/// above, and the entity's comment says why that is the right answer for
/// a row the page did not return.
const _noPortionsPenalty = 0.15;

/// Scores [meal] against [query] on a 0.0-1.0 scale, tolerant of
/// inflectional suffixes. Brand-only matches count for less than the same
/// match on the name, as in the shared ranker.
///
/// As in the shared ranker, a backend record is scored on its title
/// rather than the description it shows (`MealEntity.scoringName`), plus
/// whichever of its qualifiers the query names. The title is what makes
/// the tie-break in [_sorted] reachable at all: every token past the one
/// that matched costs, so scored on descriptions "Egg, creamed" (two
/// tokens) beat "Egg, whole, boiled or poached" (five) on `egg` outright,
/// and the tie-break never saw the family (#1164). The named qualifiers
/// are what keep the tie-break out of a query that has already chosen:
/// on `dried apple` the title alone scored every "Apple" at 0.667 and the
/// tie-break logged "Apple, raw"; with `dried` read off "Apple, dried"
/// that record is 1.0 and its siblings stay at 0.667. The
/// soft agreement covers the qualifier too — `egg yolks` reads `yolk` —
/// and a qualifier the query does not name is never read, so a title
/// that scores 1.0 still scores 1.0 whatever follows it.
///
/// Unlike the shared ranker, a backend record with no labelled portion
/// loses [_noPortionsPenalty] — see there for why this is the only place.
double scoreMealForResolution(MealEntity meal, String query) {
  final queryTokens = tokenize(query);
  if (queryTokens.isEmpty) return 0.0;

  final nameScore = scoreText(
    meal.scoringName,
    queryTokens,
    qualifiers: meal.scoringQualifiers,
  );
  final brandScore = scoreText(meal.brands, queryTokens);
  var score = nameScore >= brandScore ? nameScore : brandScore * 0.6;

  if (meal.detailed) score += _detailedBonus;
  if (meal.machineTranslatedName) score -= _machineTranslatedPenalty;

  // Backend records only. `MealEntity.portions` is filled from the
  // backend's portion lookup and from nowhere else, so an Open Food Facts
  // product never carries any — penalising on emptiness alone would demote
  // every OFF product in the pool, which is not what #1164 decided. The
  // `fdc` source tag covers every backend source (see
  // `MealEntity.backendSource`), so BLS and INDB records are in scope.
  // And only where the emptiness is the backend's answer: a record whose
  // lookup failed is bare for a reason that says nothing about it (see
  // [_noPortionsPenalty]).
  if (meal.source == MealSourceEntity.fdc &&
      meal.portions.isEmpty &&
      !meal.portionsUnavailable) {
    score -= _noPortionsPenalty;
  }

  return score.clamp(0.0, 1.0);
}

/// Re-orders [meals] for the resolver, **preserving the own-content tier**
/// that `mergeAndRankMeals` established — the user's own custom meals and
/// recipes stay ahead of remote results regardless of score, and only the
/// order *within* each tier is recomputed.
///
/// Equal scores are broken by the length of the description, then by the
/// number of labelled portions, and then the sort is stable, so what is
/// left of a tie keeps the order the shared ranker left it in — see
/// [_sorted].
List<MealEntity> rankForResolution(List<MealEntity> meals, String query) {
  final own = <MealEntity>[];
  final rest = <MealEntity>[];
  for (final meal in meals) {
    final isOwn =
        meal.source == MealSourceEntity.custom ||
        meal.source == MealSourceEntity.recipe;
    (isOwn ? own : rest).add(meal);
  }
  return [..._sorted(own, query), ..._sorted(rest, query)];
}

/// Highest score first; among equal scores, the shortest description
/// first, then the most labelled portions; stable after that.
///
/// The tie-break exists because the text score cannot tell siblings apart
/// on a query that names only their family. Backend records are scored on
/// their title (#1164), and a family of FDC survey records — "Apple, raw",
/// "Apple, dried", "Apple, baked", all titled "Apple" — scores identically
/// on the query `apple`, so whichever the pool happened to list first was
/// logged. The resolver auto-selects, so that order has to mean something.
/// A query that names a qualifier — `dried apple` — is not a tie: the
/// record carrying it scores above its siblings and the keys are never
/// consulted (see [scoreMealForResolution]).
///
/// The description's length is the first key because among siblings the
/// shorter description is the less qualified one, and the less qualified
/// one is the everyday form: "Potato, NFS" before "Potato, baked, NFS"
/// before "Potato, baked, peel not eaten". Siblings that reach this key
/// share a title — every "Milk" is "Milk" — so it is the name that is
/// measured, not the title that was scored. The decision first put the
/// portions ahead of it, on the theory that FNDDS gives its everyday form
/// the most ways to count it, and on the small families that was so:
/// "Apple, raw" carries 7 deliverable portions to 2 for dried and baked.
/// Measured over the 39 survey families with more than twenty members it
/// was not: FDC measures a dish in more ways than its ingredient, so
/// "most portions, then shortest" picked a specific dish over the generic
/// record in most of them — Potato → "Potato, french fries, fast food",
/// Beef → "Beef, ground, patty", Bread → "Bread, French or Vienna, whole
/// wheat", Pasta → "Pasta, whole grain, with cream sauce, ready-to-heat",
/// Cheese → Cheddar, Tea → "Tea, iced, bottled, black". "Shortest
/// description, then most portions" lands on the generic record — Potato,
/// NFS; Beef, NFS; Pasta, cooked; Cheese, NFS; Pork, NFS; Turkey, NFS;
/// Soup, NFS; Crackers, NFS; Muffin, NFS; Pretzels, NFS; Milk, NFS; Apple,
/// raw; Banana, raw; Orange juice, 100%, NFS — and misses egg ("Egg,
/// creamed", 12 characters, over "Egg, whole, raw", 15), coffee ("Coffee,
/// Latte" over "Coffee, brewed"), tea ("Tea, ginger") and bread ("Bread,
/// rye", 10, over "Bread, white", 12). That was measured family by
/// family, and since Backend#10 (applied 2026-09-13) it is what the app
/// does on the pool it is handed: the backend orders its hundred by
/// deliverable portion, then title equal to the term, then length, so a
/// family the query names arrives whole and shortest-first — `potato` is
/// handed a hundred rows titled "Potato", where the order before it
/// (portion, then id) handed it beef stews and left the family at ranks
/// 128 to 488, and `bread` is handed "Bread, rye" first, where it was rank
/// 157 and never arrived. The pinned known misses on the real pools are
/// egg and rice ("Rice, fried, NFS", 16 characters, over "Rice, cooked,
/// NFS", 17 — a dish, as creamed egg is); the siblings are one tap away
/// on the review screen. The portions key is second for the case the
/// length cannot settle: "Milk, whole" and "Milk, human" are eleven
/// characters each, and whole carries 3 deliverable portions to human's
/// 2. Declined: reading FNDDS's own markers (`NFS`, `raw`) as a rule — a
/// word list about FDC naming living in the ranker, and only 143 of the
/// 555 short-title groups have an NFS record at all.
///
/// The keys only act on a tie, and they are only as good as the tie they
/// are handed. "Bread, rice" and "Chips, rice" are in the live pool for
/// `rice`, titled "Bread" and "Chips"; the query names the `rice` they
/// carry past the title, so they score 0.667 on it — what an OFF product
/// called "Bread rice" scores — and never tie the plain record's 1.0.
/// Scored on their descriptions they were two-token names that outscored
/// the three-token plain record, which is the miss the title scoring
/// removed; and "Pie, apple", titled "Pie", scores 0.667 on `apple` under
/// the plain record's 1.0. The same title derivation, the same scorer
/// ([scoreText], qualifiers named by [namedQualifiers]) and the same
/// tie-break cut the backend's hundred to the twenty the resolver sees
/// (`rankAndTruncateFoodsByName`): the survivors and this sort apply one
/// rule, so the record this sort would pick from the hundred is inside
/// the twenty — up to what the cut does not read. It runs before any
/// portion is fetched, where this sort's second key and
/// [_noPortionsPenalty] read them, and the translation cut is handed the
/// row's source and does not read it, where [_machineTranslatedPenalty]
/// does; its comment says exactly what that leaves open and where it
/// bites — `muffins`, where the penalty inverts the 0.143 between an
/// exact plural title and the soft singular — and
/// `resolver_sibling_selection_test` pins it.
///
/// Every record that is not a fresh backend result has no portions, so
/// among OFF products or cached meals the portions key is always a tie and
/// what decides after the length is the order the shared ranker left. The
/// length key acts on OFF too — two equal-scoring OFF products used to keep
/// their popularity order — and that is the decision's "shortest
/// description", which was not limited to backend records. The portions
/// key is bounded on the resolver's real path: `MealDBO` does not persist
/// portions, so a backend record the search cache holds and this search's
/// page did not return ties on it with everything, whatever the backend has
/// for it — see [_noPortionsPenalty]. (A record the page did return reaches
/// here as the fresh entity, portions and all.)
List<MealEntity> _sorted(List<MealEntity> meals, String query) {
  // Parallel (meal, score) records rather than a map: MealEntity's Equatable
  // props are just [code, name], so two rows from different sources can
  // compare equal and would collide on a map key.
  final decorated = [
    for (final meal in meals)
      (meal: meal, score: scoreMealForResolution(meal, query)),
  ];
  mergeSort(decorated, compare: (a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    // The name, not the title that was scored. Siblings that reach this key
    // share a title — every "Milk" is "Milk" — so its length says nothing;
    // the description is where they differ, and the shorter one is the
    // less qualified: "Milk, NFS" before "Milk, whole".
    final byLength = (a.meal.name ?? '').length.compareTo(
      (b.meal.name ?? '').length,
    );
    if (byLength != 0) return byLength;
    return b.meal.portions.length.compareTo(a.meal.portions.length);
  });
  return [for (final entry in decorated) entry.meal];
}
