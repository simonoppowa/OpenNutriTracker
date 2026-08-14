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
    (sum, token) =>
        sum +
        against.fold<double>(0.0, (best, other) {
          final similarity = _tokenSimilarity(token, other);
          return similarity > best ? similarity : best;
        }),
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

/// Scores [meal] against [query] on a 0.0-1.0 scale, tolerant of
/// inflectional suffixes. Brand-only matches count for less than the same
/// match on the name, as in the shared ranker.
double scoreMealForResolution(MealEntity meal, String query) {
  final queryTokens = _tokenize(_normalize(query));
  if (queryTokens.isEmpty) return 0.0;

  final nameScore = _textScore(meal.name, queryTokens);
  final brandScore = _textScore(meal.brands, queryTokens);
  var score = nameScore >= brandScore ? nameScore : brandScore * 0.6;

  if (meal.detailed) score += _detailedBonus;
  if (meal.machineTranslatedName) score -= _machineTranslatedPenalty;

  return score.clamp(0.0, 1.0);
}

/// Re-orders [meals] for the resolver, **preserving the own-content tier**
/// that `mergeAndRankMeals` established — the user's own custom meals and
/// recipes stay ahead of remote results regardless of score, and only the
/// order *within* each tier is recomputed.
///
/// Stable, so equally-scored meals keep the order the shared ranker left
/// them in.
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

List<MealEntity> _sorted(List<MealEntity> meals, String query) {
  // Parallel (meal, score) records rather than a map: MealEntity's Equatable
  // props are just [code, name], so two rows from different sources can
  // compare equal and would collide on a map key.
  final decorated = [
    for (final meal in meals)
      (meal: meal, score: scoreMealForResolution(meal, query)),
  ];
  mergeSort(decorated, compare: (a, b) => b.score.compareTo(a.score));
  return [for (final entry in decorated) entry.meal];
}
