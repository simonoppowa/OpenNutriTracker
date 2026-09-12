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
/// **Why prefixes rather than plural rules.** Stripping a trailing `s`
/// works in one of the nine supported locales and reintroduces exactly the
/// per-language word lists `parseMealText` was designed to avoid. Comparing
/// how far two tokens agree from the front is locale-independent, because
/// suffix inflection is how most of these languages inflect:
///
/// | | query → record | shared prefix |
/// |---|---|---|
/// | en | `eggs` → `Egg` | `egg` |
/// | de | `Eier` → `Ei` | `Ei` |
/// | it | `uova` → `uovo` | `uov` |
/// | tr | `yumurtalar` → `yumurta` | `yumurta` |
library;

import 'package:collection/collection.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// Shortest prefix agreement that counts as a partial match at all, unless
/// one of the tokens is shorter than this — `Ei`/`Eier` must still match,
/// while `apple`/`apricot` (which agree on `ap`) must not.
const _minPrefix = 3;

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
const _noPortionsPenalty = 0.15;

/// Characters from scripts that do not separate words with spaces. A
/// Unicode script property rather than a vocabulary list, so it does not
/// grow when a language is added.
final _unspacedScript = RegExp(
  r'[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}'
  r'\p{Script=Hangul}]',
  unicode: true,
);

/// The character pairs in [text], or the text itself when it is too short
/// to have any.
Set<String> _bigrams(String text) {
  if (text.length < 2) return {text};
  return {for (var i = 0; i < text.length - 1; i++) text.substring(i, i + 2)};
}

/// How far [a] and [b] agree, 0.0-1.0. 1.0 only for an exact match; a
/// suffix difference costs a little rather than everything.
double _tokenSimilarity(String a, String b) {
  if (a == b) return 1.0;

  // Chinese, Japanese and Korean write without spaces, so `_tokenize`
  // hands the whole phrase over as one token and the shared-prefix rule
  // below reads it as a single long word. That scored `鸡蛋` against
  // `土鸡蛋` — a superstring of the query — at exactly 0.0, and it is why
  // a `zh` search could miss the product it was looking at.
  //
  // Character bigrams compare these the way whitespace tokens compare in
  // Latin scripts: `鸡蛋` and `土鸡蛋` share one pair out of three, so they
  // agree rather than disagree. It also makes a leading counter harmless —
  // `个鸡蛋` still matches `鸡蛋` — which is what removes any need for a
  // list of measure words.
  if (_unspacedScript.hasMatch(a) || _unspacedScript.hasMatch(b)) {
    final aGrams = _bigrams(a);
    final bGrams = _bigrams(b);
    final shared = aGrams.intersection(bGrams).length;
    if (shared == 0) return 0.0;
    return 2 * shared / (aGrams.length + bGrams.length);
  }

  final shorter = a.length < b.length ? a.length : b.length;
  final longer = a.length > b.length ? a.length : b.length;

  var shared = 0;
  while (shared < shorter && a.codeUnitAt(shared) == b.codeUnitAt(shared)) {
    shared++;
  }

  // The guard relaxes for tokens shorter than [_minPrefix] so genuinely
  // short words ("Ei", "ox") are not excluded by their own length.
  final required = _minPrefix < shorter ? _minPrefix : shorter;
  if (shared < required) return 0.0;

  return shared / longer;
}

/// [token]'s best agreement with any of [against]; 0.0 when there is none.
double _bestAgreement(String token, Set<String> against) =>
    against.fold(0.0, (best, other) {
      final similarity = _tokenSimilarity(token, other);
      return similarity > best ? similarity : best;
    });

/// Soft Dice: every token on each side contributes its best agreement with
/// the other side, over the total token count.
///
/// The symmetry is what keeps a long branded name from winning on a short
/// query. Scoring only the query's tokens would rank `Cadbury Creme Eggs`
/// (which contains `eggs` exactly, 1.0) above `Egg` (0.75) — the opposite
/// of what the user meant. Counting the record's unmatched tokens too
/// drops the branded name to 0.5 and puts the plain food first.
double _softDice(Set<String> textTokens, Set<String> queryTokens) {
  if (textTokens.isEmpty || queryTokens.isEmpty) return 0.0;

  double bestSum(Set<String> from, Set<String> against) => from.fold(
    0.0,
    (sum, token) => sum + _bestAgreement(token, against),
  );

  final matched =
      bestSum(queryTokens, textTokens) + bestSum(textTokens, queryTokens);
  return matched / (queryTokens.length + textTokens.length);
}

String _normalize(String? text) =>
    text?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ?? '';

Set<String> _tokenize(String normalized) => normalized
    .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
    .where((token) => token.isNotEmpty)
    .toSet();

double _textScore(String? text, Set<String> queryTokens) {
  final normalized = _normalize(text);
  if (normalized.isEmpty) return 0.0;
  return _softDice(_tokenize(normalized), queryTokens);
}

/// The qualifier tokens the query names: each one that some query token
/// agrees with better than it agrees with any title token.
///
/// "Better than the title", not merely "at all", because the soft
/// agreement reaches three letters in: on `rice`, "Puerto Rican" agrees
/// with the query at 0.6 through `ric`, and read as named it would join
/// the scored text and cost its record — 0.867 against the plain record's
/// 1.0 — for a word the user never typed. The title already accounts for
/// `rice` at 1.0, so the qualifier stays out and the two records tie on
/// the title, as siblings should.
Set<String> _namedQualifiers(
  Set<String> titleTokens,
  Set<String> qualifierTokens,
  Set<String> queryTokens,
) => {
  for (final qualifier in qualifierTokens)
    if (queryTokens.any(
      (token) =>
          _tokenSimilarity(token, qualifier) >
          _bestAgreement(token, titleTokens),
    ))
      qualifier,
};

/// [meal]'s name score: its title's tokens, plus whichever of its
/// qualifiers the query names (see [_namedQualifiers]), against the query.
/// A meal with no title (`MealEntity.scoringName`) scores nothing here,
/// as a meal with no name always did.
double _nameScore(MealEntity meal, Set<String> queryTokens) {
  final titleTokens = _tokenize(_normalize(meal.scoringName));
  if (titleTokens.isEmpty) return 0.0;
  final qualifierTokens = _tokenize(_normalize(meal.scoringQualifiers));
  return _softDice({
    ...titleTokens,
    ..._namedQualifiers(titleTokens, qualifierTokens, queryTokens),
  }, queryTokens);
}

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
/// and the portions key never saw the family (#1164). The named
/// qualifiers are what keep the tie-break out of a query that has already
/// chosen: on `dried apple` the title alone scored every "Apple" at
/// 0.667 and the portions key logged "Apple, raw"; with `dried` read off
/// "Apple, dried" that record is 1.0 and its siblings stay at 0.667. The
/// soft agreement covers the qualifier too — `egg yolks` reads `yolk` —
/// and a qualifier the query does not name is never read, so a title
/// that scores 1.0 still scores 1.0 whatever follows it.
///
/// Unlike the shared ranker, a backend record with no labelled portion
/// loses [_noPortionsPenalty] — see there for why this is the only place.
double scoreMealForResolution(MealEntity meal, String query) {
  final queryTokens = _tokenize(_normalize(query));
  if (queryTokens.isEmpty) return 0.0;

  final nameScore = _nameScore(meal, queryTokens);
  final brandScore = _textScore(meal.brands, queryTokens);
  var score = nameScore >= brandScore ? nameScore : brandScore * 0.6;

  if (meal.detailed) score += _detailedBonus;
  if (meal.machineTranslatedName) score -= _machineTranslatedPenalty;

  // Backend records only. `MealEntity.portions` is filled from the
  // backend's portion lookup and from nowhere else, so an Open Food Facts
  // product never carries any — penalising on emptiness alone would demote
  // every OFF product in the pool, which is not what #1164 decided. The
  // `fdc` source tag covers every backend source (see
  // `MealEntity.backendSource`), so BLS and INDB records are in scope.
  if (meal.source == MealSourceEntity.fdc && meal.portions.isEmpty) {
    score -= _noPortionsPenalty;
  }

  return score.clamp(0.0, 1.0);
}

/// Re-orders [meals] for the resolver, **preserving the own-content tier**
/// that `mergeAndRankMeals` established — the user's own custom meals and
/// recipes stay ahead of remote results regardless of score, and only the
/// order *within* each tier is recomputed.
///
/// Equal scores are broken by the number of labelled portions, then by
/// name length, and then the sort is stable, so what is left of a tie
/// keeps the order the shared ranker left it in — see [_sorted].
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

/// Highest score first; among equal scores, most labelled portions first,
/// then the shortest name; stable after that.
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
/// "Most labelled portions" is the data-driven proxy for the canonical
/// record: FNDDS gives its everyday form the most ways to count it, and no
/// naming rule is needed to find it. Measured against the backend's
/// deliverable portions (the rows `portions_by_food_ids` returns): Apple,
/// raw carries 7 against 2 for dried and baked; Banana, raw 5 against 2;
/// Milk, NFS — FNDDS's own generic — 3, tied with Milk, whole, where the
/// shorter name settles it. The name-length rule is the second key for the
/// same reason: among siblings the shorter description is the less
/// qualified one. Declined: reading FNDDS's own markers (`NFS`, `raw`) as
/// a rule — a word list about FDC naming living in the ranker, and only
/// 143 of the 555 short-title groups have an NFS record at all.
///
/// The keys only act on a tie, and they are only as good as the tie they
/// are handed. The decision named rice as the known miss — a Puerto Rican
/// variant beating "Rice, cooked, NFS" on portions — and that particular
/// miss does not form: each carries one deliverable portion, so the tie
/// falls through to name length and the plain record's 17 characters beat
/// the variant's 48. "Bread, rice" and "Chips, rice" are in the live pool
/// too, titled "Bread" and "Chips"; the query names the `rice` they carry
/// past the title, so they score 0.667 on it — what an OFF product called
/// "Bread rice" scores — and never tie the plain record's 1.0. Scored on
/// their descriptions they were two-token names that outscored the
/// three-token plain record, which is the miss the title scoring removed.
/// The proxy's known counterexample went the same way: "Pie, apple" (8
/// portions) took the tie from "Apple, raw" (7) on the live pool while
/// descriptions were scored, and titled "Pie" it scores 0.667 on `apple`
/// under the plain record's 1.0. What the keys cannot do is see past the
/// query: on `apple` a same-titled sibling with more portions than the
/// everyday form takes the tie, and that is a matter for the decision,
/// not for this sort; the review screen is where the plain record is one
/// tap away.
///
/// Every record that is not a fresh backend result has no portions, so
/// among OFF products or cached meals the portions key is always a tie and
/// the shorter name decides before the order the shared ranker left. That
/// is a change for OFF too — two equal-scoring OFF products used to keep
/// their popularity order — and it is the decision's "then shortest name",
/// which was not limited to backend records. It also bounds what the
/// portions key can do on the resolver's real path: `MealDBO` does not
/// persist portions, so a backend record the search cache holds and this
/// search's page did not return ties with everything, whatever the
/// backend has for it — see [_noPortionsPenalty]. (A record the page did
/// return reaches here as the fresh entity, portions and all.)
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
    final byPortions = b.meal.portions.length.compareTo(
      a.meal.portions.length,
    );
    if (byPortions != 0) return byPortions;
    // The name, not the title that was scored. Siblings that reach this key
    // share a title — every "Milk" is "Milk" — so its length says nothing;
    // the description is where they differ, and the shorter one is the
    // less qualified: "Milk, NFS" before "Milk, whole".
    return (a.meal.name ?? '').length.compareTo((b.meal.name ?? '').length);
  });
  return [for (final entry in decorated) entry.meal];
}
