import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';
import 'package:opennutritracker/features/add_meal/util/portion_unit.dart';
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart';

/// Below this the top candidate is a guess rather than an answer, and the
/// review screen (#602) should say so instead of presenting it as settled.
///
/// The value is a judgement, not a measurement: it sits above what an
/// unrelated long product name scores on a short query (`eggs` → `Cadbury
/// Creme Eggs Multipack 5 Pack` is 0.29) and below what a
/// same-word-different-inflection match scores against a one-word name
/// (`eggs` → `Egg` is 0.75).
///
/// It was set while backend records were shown by their short title, and
/// #1164 changed what they show to the full description without moving
/// it. That did not move the scores either: a backend record is still
/// scored on its title (`MealEntity.scoringName`), so `eggs` → "Egg,
/// whole, raw" is the `eggs` → `Egg` match above, 0.75, and clears the
/// floor as it always did. Scored on the description it would be 0.375 —
/// every token past the one that matched costs — and the #601 case this
/// scorer exists for would have been flagged as a guess.
const kResolutionConfidenceFloor = 0.45;

/// One parsed item and what the food search made of it.
///
/// [candidates] is ranked best-first and may be empty — an item the search
/// could not resolve is returned unresolved rather than dropped, so the
/// review screen can show it and let the user fix or skip it. A silent drop
/// is the one failure mode that loses data without telling anyone.
class ResolvedMealItem {
  final ParsedMealItem parsed;
  final List<MealEntity> candidates;
  final int selectedIndex;

  /// Score of the selected candidate, 0.0-1.0. Zero when unresolved.
  final double confidence;

  const ResolvedMealItem({
    required this.parsed,
    required this.candidates,
    required this.selectedIndex,
    required this.confidence,
  });

  bool get isResolved => candidates.isNotEmpty;

  MealEntity? get selected => isResolved ? candidates[selectedIndex] : null;

  /// True when a match was found but is weak enough that the review screen
  /// should flag it rather than presenting it as settled.
  bool get isLowConfidence =>
      isResolved && confidence < kResolutionConfidenceFloor;

  @override
  String toString() =>
      'ResolvedMealItem(query: ${parsed.query}, candidates: ${candidates.length}, '
      'confidence: ${confidence.toStringAsFixed(2)})';
}

/// Turns the parser's search intents into real food-database entries,
/// reusing the existing search stack rather than adding a new one.
///
/// Both tiers of #599 converge here: the tier-0 parser emits
/// `(query, quantity, unit)` and never a nutrient estimate, and a future
/// model client would emit the same shape plus a fallback macro payload
/// consulted **only** on a database miss. This class deliberately has no
/// fallback path yet — tier 1 is not scoped — but the unresolved item is
/// the seam where one would attach.
class ResolveParsedMealsUseCase {
  /// How many thin Open Food Facts hits one counted item may look up in
  /// full — see [_withFullOffRecords]. Enough to get past a few products
  /// that tie on the name and carry no serving; few enough that a
  /// two-item meal costs about as many product reads as tapping + on a
  /// handful of search results.
  static const _maxOffLookups = 5;

  final _log = Logger('ResolveParsedMealsUseCase');

  final SearchProductsUseCase _searchProductsUseCase;

  ResolveParsedMealsUseCase(this._searchProductsUseCase);

  /// Resolves every item concurrently. The two sources are independent and
  /// each already degrades to local-only results on failure inside
  /// `SearchProductsUseCase`, so one source being down does not fail the
  /// batch — it just narrows the candidate list.
  Future<List<ResolvedMealItem>> resolve(List<ParsedMealItem> items) async {
    if (items.isEmpty) return const [];
    return Future.wait(items.map(_resolveOne));
  }

  /// A source that fails contributes nothing instead of failing the item.
  Future<List<MealEntity>> _search(
    Future<SearchProductsResult> Function() run,
  ) async {
    try {
      return (await run()).meals;
    } catch (e, stackTrace) {
      _log.warning(
        'A food source failed during bulk resolution',
        e,
        stackTrace,
      );
      return const [];
    }
  }

  Future<ResolvedMealItem> _resolveOne(ParsedMealItem item) async {
    final query = item.query;

    // Both entry points run in parallel. `searchFDCFoodByString` queries
    // Supabase despite the name, and `forResolution` asks for the page
    // this class auto-selects from: cut with the row's `has_portion`
    // column read, so a portion-bearing record the ranking below would
    // pick is not lost before it is scored (#1190). The Food tab's page
    // is the same search cut without it (#1164).
    //
    // Each is guarded separately rather than wrapped in a single
    // `Future.wait`, which fails fast: one source erroring must narrow the
    // candidate list, never fail the item or the batch. `SearchProductsUseCase`
    // already degrades internally via `_safeRemoteCall`, so this should not
    // trigger today — it is here so that a future change there cannot turn a
    // transient network error into a lost row.
    final results = await Future.wait([
      _search(() => _searchProductsUseCase.searchOFFProductsByString(query)),
      _search(
        () => _searchProductsUseCase.searchFDCFoodByString(
          query,
          forResolution: true,
        ),
      ),
    ]);

    // mergeAndRankMeals still does the work only it does: dedup across
    // sources, near-duplicate collapsing, and keeping the user's own
    // content in a tier above remote results.
    final merged = mergeAndRankMeals(results[0], results[1], query);

    // Then re-order within those tiers with the inflection-tolerant score.
    // The shared ranker scores `eggs` against `Egg` at exactly 0.0, and
    // this class auto-selects the top candidate, so its ordering alone is
    // not safe to log from. See resolver_relevance.dart.
    final counted = _isCounted(item);
    var ranked = rankForResolution(merged, query, counted: counted);
    if (counted) {
      ranked = rankForResolution(
        await _withFullOffRecords(ranked, query),
        query,
        counted: true,
      );
    }

    if (ranked.isEmpty) {
      return ResolvedMealItem(
        parsed: item,
        candidates: const [],
        selectedIndex: 0,
        confidence: 0.0,
      );
    }

    return ResolvedMealItem(
      parsed: item,
      candidates: ranked,
      selectedIndex: 0,
      confidence: scoreMealForResolution(ranked.first, query),
    );
  }

  /// True when [item]'s number is a count rather than a weight: no unit at
  /// all (`2 Eier`), or a serving (`3 serving`, a model's answer to "three
  /// slices"). Those are the rows `BulkAddRow.amountNeedsCheck` holds back
  /// on a food with no `servingQuantity`.
  static bool _isCounted(ParsedMealItem item) {
    final unit = item.unit;
    return item.quantity != null && (unit == null || isPortionUnit(unit));
  }

  /// [ranked] with the full Open Food Facts record in place of each thin
  /// text-search hit that could still win once its serving is known.
  ///
  /// A text-search hit carries no serving fields — the Search-a-licious
  /// index does not hold them (`MealEntity.detailed`) — so under a count
  /// every Open Food Facts candidate looked uncountable, and the row was
  /// held back on a product that may well declare one: "2 Eier" matched
  /// "Eier / Lidl" and ended at "Add 0 items" (#1472). Meal detail and the
  /// + on a search result already swap the full record in before they
  /// pick a default; this does the same before the resolver picks.
  ///
  /// The serving comes from the product record, never from the model,
  /// which only ever said "2". A product whose full record has no serving
  /// either stays uncountable, and its row is held back exactly as before.
  ///
  /// Only hits that could overtake the current first candidate are looked
  /// up. A full record that declares a serving sorts at its text score
  /// plus [detailedBonus], capped at 1.0 ([_scoreOnceDetailed]), so a hit
  /// that does not beat the first candidate's sort score even then cannot
  /// move it. Without the bonus the bound skipped a winner: a detailed
  /// "Apple" with no serving sorts at 0.85 on `apple`, and thin "Apples"
  /// at 0.833 is 0.863 once detailed. None when the first candidate is
  /// the user's own, which no remote record outranks. A lookup that fails
  /// leaves the thin hit where it was.
  Future<List<MealEntity>> _withFullOffRecords(
    List<MealEntity> ranked,
    String query,
  ) async {
    if (ranked.isEmpty) return ranked;
    final first = ranked.first;
    if (first.source == MealSourceEntity.custom ||
        first.source == MealSourceEntity.recipe) {
      return ranked;
    }
    final bar = rankScoreForResolution(first, query, counted: true);
    final thin = ranked
        .where(
          (meal) =>
              meal.source == MealSourceEntity.off &&
              !meal.detailed &&
              cannotHonourCount(meal) &&
              _scoreOnceDetailed(meal, query) > bar,
        )
        .take(_maxOffLookups)
        .toList();
    if (thin.isEmpty) return ranked;

    final full = await Future.wait(thin.map(_fullOffRecord));
    final replacements = Map<MealEntity, MealEntity?>.identity();
    for (var i = 0; i < thin.length; i++) {
      replacements[thin[i]] = full[i];
    }
    return [for (final meal in ranked) replacements[meal] ?? meal];
  }

  /// What [meal] would score as a full record, which is what the resolver
  /// clamps it to: one already at 1.0 gains nothing from the bonus.
  static double _scoreOnceDetailed(MealEntity meal, String query) =>
      (scoreMealForResolution(meal, query) + detailedBonus).clamp(0.0, 1.0);

  Future<MealEntity?> _fullOffRecord(MealEntity meal) async {
    try {
      return await _searchProductsUseCase.fetchFullOffRecord(meal);
    } catch (e, stackTrace) {
      _log.warning(
        'Could not fetch the full Open Food Facts record for ${meal.code}',
        e,
        stackTrace,
      );
      return null;
    }
  }
}
