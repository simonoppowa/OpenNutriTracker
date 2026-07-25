import 'package:collection/collection.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// Scores [meal] against [query] on a 0.0-1.0 scale that is comparable
/// across sources (OFF, Supabase backend, FDC, custom meals, ...). Existing
/// per-source ranking signals (OFF's popularity/relevance fusion, Postgres
/// ts_rank) are dropped by the time results reach [MealEntity] and aren't on
/// a common scale anyway, so this recomputes relevance purely from text
/// overlap between the query and the meal's name/brand, plus small quality
/// tie-breakers.
///
/// Returns 0.0 for an empty query. A meal with no name can still receive a
/// non-zero score when the query matches the brand (weighted at 60% of the
/// equivalent name match).
double scoreMealRelevance(MealEntity meal, String query) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) return 0.0;

  final nameScore = _textScore(meal.name, normalizedQuery);
  final brandScore = _textScore(meal.brands, normalizedQuery);
  // Brand-only matches (e.g. searching "nestle") still surface the product,
  // but count for less than the same match on the name itself.
  var score = nameScore >= brandScore ? nameScore : brandScore * 0.6;

  // Small, non-decisive tie-breakers so that among near-equal text matches,
  // the more trustworthy/complete result edges ahead.
  if (meal.detailed) score += 0.03;
  if (meal.machineTranslatedName) score -= 0.03;

  return score.clamp(0.0, 1.0);
}

/// Stable sort of [meals] by [scoreMealRelevance] against [query], highest
/// first. Meals that score equally keep their relative order from [meals]
/// (e.g. the order their own source already ranked them in), so this only
/// reorders across, not within, near-identical relevance tiers.
///
/// Scores are computed once per meal into a parallel (meal, score) record
/// list rather than a `Map<MealEntity, double>` — [MealEntity]'s [Equatable]
/// props are just `[code, name]`, so two distinct entries from different
/// sources (e.g. a not-yet-deduplicated OFF/Supabase pair) can compare equal
/// and would otherwise collide onto the same map key.
List<MealEntity> rankMealsByRelevance(List<MealEntity> meals, String query) {
  final decorated = [for (final meal in meals) (meal: meal, score: scoreMealRelevance(meal, query))];
  mergeSort(decorated, compare: (a, b) => b.score.compareTo(a.score));
  return [for (final entry in decorated) entry.meal];
}

/// Combines the independently-searched OFF ([a]) and Supabase backend ([b])
/// result lists shown by the "All" tab into one list.
///
/// Each input already carries its own local matches (custom meals, recipes,
/// cached/recent history — see `SearchProductsUseCase._buildResult`) ahead
/// of that source's fresh remote results, but since both lists are built
/// independently: (1) the same custom meal or recipe appears in both — the
/// local lookups aren't filtered by source — and (2) the two lists are
/// simply concatenated by the caller, so results are ordered by source
/// first rather than by relevance to [query]. This dedupes across sources,
/// then keeps the user's own content (custom meals, recipes) as a tier
/// above everything else, relevance-sorting within each tier rather than
/// leaving the arbitrary per-source order.
///
/// Beyond exact-key duplicates, the same real-world food frequently exists
/// as *separate* records in more than one backend (e.g. "Whole Milk" in
/// both OFF and the Supabase/FDC mirror) — those have different codes, so
/// the exact-key dedup above doesn't catch them. [_collapseNearDuplicates]
/// handles that within the non-own tier only: your own custom meals/recipes
/// are never merged away, even if a remote result happens to share a name.
List<MealEntity> mergeAndRankMeals(List<MealEntity> a, List<MealEntity> b, String query) {
  final own = <MealEntity>[];
  final rest = <MealEntity>[];
  for (final meal in _deduplicateAcrossSources([...a, ...b])) {
    final isOwn = meal.source == MealSourceEntity.custom || meal.source == MealSourceEntity.recipe;
    (isOwn ? own : rest).add(meal);
  }
  final collapsedRest = _collapseNearDuplicates(rest, query);
  return [...rankMealsByRelevance(own, query), ...rankMealsByRelevance(collapsedRest, query)];
}

/// Same dedup key as `SearchProductsUseCase._deduplicateMeals` (source +
/// code, falling back to name) so a custom meal or recipe that independently
/// surfaced in both the OFF and Food lists collapses to a single entry here.
List<MealEntity> _deduplicateAcrossSources(List<MealEntity> meals) {
  final seenKeys = <String>{};
  final uniqueMeals = <MealEntity>[];
  for (final meal in meals) {
    final key = '${meal.source.name}:${meal.code ?? meal.name ?? ''}';
    if (seenKeys.add(key)) uniqueMeals.add(meal);
  }
  return uniqueMeals;
}

/// Collapses meals that share a normalized name — and, when both sides
/// declare one, the same normalized brand — keeping only the highest
/// [scoreMealRelevance]d entry from each group (ties keep the first-seen
/// one). That score already favors the more complete/trustworthy record
/// (see the `detailed`/`machineTranslatedName` tie-breakers), so "highest
/// score" and "best copy to keep" are the same thing here.
///
/// Matching is exact-normalized-text equality, not edit-distance/fuzzy
/// similarity — deliberately conservative so two distinctly-named foods
/// that merely look alike ("Chicken Breast" vs "Chicken Breast Grilled")
/// are never silently merged. A branded entry only merges with another
/// entry that names the *same* brand; an unbranded entry only merges with
/// another unbranded entry — a bare "Milk" never absorbs a branded
/// "Milk (Horizon)", since those aren't reliably the same product.
List<MealEntity> _collapseNearDuplicates(List<MealEntity> meals, String query) {
  final groupOrder = <String>[];
  final groups = <String, List<MealEntity>>{};
  for (final meal in meals) {
    final key = _nearDuplicateKey(meal);
    if (!groups.containsKey(key)) groupOrder.add(key);
    groups.putIfAbsent(key, () => []).add(meal);
  }
  return [for (final key in groupOrder) _highestScoring(groups[key]!, query)];
}

String _nearDuplicateKey(MealEntity meal) {
  final name = _normalize(meal.name);
  // No name to match on — key on identity instead of an empty string, which
  // would otherwise collapse every unrelated nameless meal into one.
  // meal.code is nullable: fall back to identityHashCode so two distinct
  // nameless meals without codes don't share the same key.
  if (name.isEmpty) {
    return 'noname:${meal.source.name}:${meal.code ?? identityHashCode(meal)}';
  }
  final brand = _normalize(meal.brands);
  return brand.isEmpty ? name : '$name|$brand';
}

MealEntity _highestScoring(List<MealEntity> group, String query) {
  var best = group.first;
  var bestScore = scoreMealRelevance(best, query);
  for (final meal in group.skip(1)) {
    final score = scoreMealRelevance(meal, query);
    if (score > bestScore) {
      best = meal;
      bestScore = score;
    }
  }
  return best;
}

/// Standalone text-relevance score (0.0-1.0) between [text] and [query] —
/// the same name-matching logic [scoreMealRelevance] uses, exposed for
/// ranking raw source rows before they're mapped into a [MealEntity] at
/// all (e.g. Supabase query results: PostgREST's `order` parameter only
/// accepts column references, not computed `ts_rank(...)` expressions, so
/// text-search relevance has to be ranked client-side instead — see
/// `SpFoodDataSource`).
double textRelevanceScore(String? text, String query) {
  final normalizedQuery = _normalize(query);
  if (normalizedQuery.isEmpty) return 0.0;
  return _textScore(text, normalizedQuery);
}

double _textScore(String? text, String normalizedQuery) {
  final normalizedText = _normalize(text);
  if (normalizedText.isEmpty) return 0.0;
  if (normalizedText == normalizedQuery) return 1.0;

  final textTokens = _tokenize(normalizedText);
  final queryTokens = _tokenize(normalizedQuery);
  final overlap = _diceCoefficient(textTokens, queryTokens);

  final containsBonus = normalizedText.contains(normalizedQuery) ? 0.2 : 0.0;
  final prefixBonus = normalizedText.startsWith(normalizedQuery) ? 0.15 : 0.0;

  // Capped below 1.0 (not just at it): dice + contains + prefix can sum
  // past 1.0 for a short, close-but-not-exact name (e.g. "Milk & hazelnut"
  // against "milk" hits ~1.02), which used to saturate at the same 1.0
  // ceiling as a real exact match and then tie-break on the meal's
  // original (e.g. OFF popularity) order instead of losing outright. The
  // 0.9 cap leaves enough headroom below the exact-match floor (1.0, or
  // 0.97 with the worst-case machineTranslatedName penalty in
  // [scoreMealRelevance]) that no non-exact match — even boosted by the
  // best-case `detailed` bonus (0.9 + 0.03 = 0.93) — can outrank one.
  return (overlap + containsBonus + prefixBonus).clamp(0.0, 0.9);
}

String _normalize(String? text) => text?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ?? '';

Set<String> _tokenize(String normalizedText) =>
    normalizedText.split(RegExp(r'[^\p{L}\p{N}]+', unicode: true)).where((token) => token.isNotEmpty).toSet();

/// 2 * |intersection| / (|a| + |b|), the standard token-set similarity
/// measure — cheap to compute and, unlike edit distance, order-independent
/// so "milk chocolate" and "chocolate milk" score identically.
double _diceCoefficient(Set<String> a, Set<String> b) {
  if (a.isEmpty || b.isEmpty) return 0.0;
  final intersectionSize = a.intersection(b).length;
  return 2 * intersectionSize / (a.length + b.length);
}
