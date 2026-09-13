import 'dart:io';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/retry_util.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/util/backend_title.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Searches the Supabase multi-source food backend (`food_summary` view,
/// see opennutritracker-backend/sql/schema.sql).
class SpFoodDataSource {
  final log = Logger('SpFoodDataSource');

  /// Rows fetched from Postgres before ranking and truncating down to
  /// [SPConst.maxNumberOfItems]. Postgres has no `ORDER BY` available here
  /// (see [rankAndTruncateFoodsByName]), so a plain `.limit(20)` would hand
  /// back an arbitrary (physical/PK-order) 20-row slice of all matches —
  /// truncating *before* ranking could silently drop the single best match
  /// if it happened to be row 21+. Casting a wider net first and truncating
  /// only after ranking fixes that, at the cost of a larger (still bounded)
  /// fetch.
  ///
  /// The net is still a cut, and the backend makes it before any code here
  /// runs: `search_food_summary` orders its matches by
  /// `food_has_deliverable_portion(food_id) desc, food_id` and stops at
  /// this many. For a term where more matches than that carry a portion,
  /// the hundred are the lowest-id of those, and a family of siblings can
  /// lie entirely outside them. Measured on the live backend (2026-09-13):
  /// `potato` matches 712 rows, "Potato, NFS" is rank 128 and the whole
  /// "Potato" family 128 to 488, so the hundred are all dishes and the
  /// resolver logs a beef stew; `bread` matches 540, and "Bread, rye" is
  /// rank 157. Nothing below can rank a row it was not sent — see the
  /// #1170 review — so the twenty kept are the twenty best of the
  /// backend's hundred, not of the backend.
  static const _candidatePoolSize = SPConst.maxNumberOfItems * 5;

  Future<List<SpFoodDTO>> fetchSearchWordResults(String searchString) async {
    try {
      return await withRetry(() async {
        log.fine('Fetching Supabase food results');
        final enabledSources = await _enabledSources();
        if (enabledSources != null && enabledSources.isEmpty) {
          log.fine('All Supabase food sources disabled; skipping search');
          return const <SpFoodDTO>[];
        }

        final supaBaseClient = locator<SupabaseClient>();
        final locale = SPConst.translationLocaleOf(
          SupportedLanguage.fromCode(Platform.localeName),
        );

        if (locale != null) {
          final localized = await _searchByTranslation(
            supaBaseClient,
            locale,
            searchString,
            enabledSources,
          );
          // Foods without a translation for this locale are only findable
          // by their English name, so an empty localized result set falls
          // through to the English search instead of returning nothing.
          if (localized.isNotEmpty) {
            log.fine('Successful localized ($locale) response from Supabase');
            return localized;
          }
        }

        final results = await _searchEnglish(
          supaBaseClient,
          searchString,
          enabledSources,
        );
        log.fine('Successful response from Supabase');
        return results;
      });
    } catch (exception, stacktrace) {
      log.severe('Exception while getting Supabase food search $exception');
      Sentry.captureException(exception, stackTrace: stacktrace);
      return Future.error(exception);
    }
  }

  /// Source codes the user allows in search results (Settings → Food
  /// databases), or null when everything is enabled and no filter is
  /// needed. An empty list means every backend source is disabled.
  /// A verified portion label per food id, in the reader's language.
  ///
  /// Empty rather than throwing on anything unusual — no locale, no verified
  /// translations, a backend that refused. The caller's fallback is the
  /// English label it already has, which is what it shows today, so a failure
  /// here costs nothing and must never cost a search.
  ///
  /// Resolves the locale here rather than taking one, because this class
  /// already owns that decision for the search itself and two answers would
  /// eventually disagree.
  Future<Map<int, String>> fetchPortionLabels(List<int> foodIds) async {
    if (foodIds.isEmpty) return const {};
    final locale = SPConst.translationLocaleOf(
      SupportedLanguage.fromCode(Platform.localeName),
    );
    // English needs no lookup: the stored description is already English.
    if (locale == null) return const {};

    try {
      final rows = await _rpcRows(
        locator<SupabaseClient>(),
        SPConst.portionLabelsByFoodIdsFn,
        {'ids': foodIds, 'loc': locale},
      );
      return {
        for (final row in rows)
          if (row['food_id'] is int && row['label'] is String)
            row['food_id'] as int: row['label'] as String,
      };
    } catch (e) {
      log.fine('No portion labels for $locale: $e');
      return const {};
    }
  }

  /// Every usable portion per food id, in the backend's order.
  ///
  /// Same failure policy as [fetchPortionLabels]: empty for anything unusual,
  /// because the caller's fallback is the single serving it already has, and
  /// a portion list is not worth costing anyone a search.
  ///
  /// Unlike the label lookup this runs for English too — the choice between a
  /// food's cup, slice and ounce is worth offering whether or not the words
  /// needed translating.
  Future<Map<int, List<MealPortionEntity>>> fetchPortions(
    List<int> foodIds,
  ) async {
    if (foodIds.isEmpty) return const {};
    final locale = SPConst.translationLocaleOf(
      SupportedLanguage.fromCode(Platform.localeName),
    );

    try {
      final rows = await _rpcRows(
        locator<SupabaseClient>(),
        SPConst.portionsByFoodIdsFn,
        // English has no translations to look for, and the function treats an
        // unmatched locale as "none verified", so passing 'en' asks the same
        // question without a special case here.
        {'ids': foodIds, 'loc': locale ?? 'en'},
      );

      final byFood = <int, List<MealPortionEntity>>{};
      for (final row in rows) {
        final id = row['food_id'];
        final label = row['label'];
        final grams = row['gram_weight'];
        if (id is! int || label is! String || grams == null) continue;
        final weight = grams is num ? grams.toDouble() : null;
        if (weight == null || weight <= 0) continue;
        byFood.putIfAbsent(id, () => []).add(
          MealPortionEntity(
            label: label,
            gramWeight: weight,
            localized: row['localized'] == true,
          ),
        );
      }
      return byFood;
    } catch (e) {
      log.fine('No portions fetched: $e');
      return const {};
    }
  }

  Future<List<String>?> _enabledSources() async {
    final toggles = await locator<ConfigDataSource>().getFoodSourceToggles();
    if (toggles == null) return null;
    final enabled = SPConst.foodSourceDisplayNames.keys
        .where((code) => toggles[code] ?? true)
        .toList();
    if (enabled.length == SPConst.foodSourceDisplayNames.length) return null;
    return enabled;
  }

  /// Calls [fn] and hands back its rows.
  ///
  /// `rpc` posts [params] as the request body and leaves the URL as a bare
  /// `/rest/v1/rpc/<fn>` — which is the entire point of routing search this
  /// way — but it is typed `dynamic`, where `select()` handed back a typed
  /// list. One cast in one place rather than three.
  Future<List<Map<String, dynamic>>> _rpcRows(
    SupabaseClient client,
    String fn,
    Map<String, dynamic> params,
  ) async {
    final response = await client.rpc(fn, params: params);
    // A set-returning function with no matches answers with an empty array,
    // never null; null would mean the function itself returned NULL, which
    // none of these can.
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<SpFoodDTO>> _searchEnglish(
    SupabaseClient client,
    String searchString,
    List<String>? enabledSources,
  ) async {
    // An RPC rather than a filtered select on the view, so the term travels
    // in the POST body instead of the query string — see [SPConst
    // .searchFoodSummaryFn]. The function returns `setof food_summary`, so
    // the rows arrive in exactly the shape `select()` produced and
    // [SpFoodDTO.fromJson] is unchanged. The source filter and the row cap
    // move into the call because a filter chained onto an RPC would go back
    // into the URL, which is the thing being removed.
    final response = await _rpcRows(client, SPConst.searchFoodSummaryFn, {
      'term': searchString,
      'sources': enabledSources,
      'max_rows': _candidatePoolSize,
    });

    // PostgREST's `order` query parameter only accepts column references
    // (`.order('column')`), not computed expressions — `.order(ts_rank(...))`
    // is rejected outright with a parse error (PGRST100), so relevance has
    // to be ranked client-side instead of via Postgres ORDER BY.
    final foods = response.map((food) => SpFoodDTO.fromJson(food)).toList();
    return rankAndTruncateFoodsByName(foods, searchString);
  }

  /// Two-step localized search: `food_summary` is a materialized view, so
  /// PostgREST cannot embed `food_translation` into it (no FK to follow).
  /// Match the translated descriptions first, then fetch the summary rows
  /// for the matched food ids and carry the translated name over.
  Future<List<SpFoodDTO>> _searchByTranslation(
    SupabaseClient client,
    String locale,
    String searchString,
    List<String>? enabledSources,
  ) async {
    final unrankedRows = await _rpcRows(
      client,
      SPConst.searchFoodTranslationFn,
      {'term': searchString, 'loc': locale, 'max_rows': _candidatePoolSize},
    );

    if (unrankedRows.isEmpty) return const [];

    // PostgREST's `order` query parameter only accepts column references,
    // not computed expressions — `.order(ts_rank(...))` is rejected outright
    // with a parse error (PGRST100), so translated-text relevance has to be
    // ranked client-side instead of via Postgres ORDER BY (same issue as
    // _searchEnglish). Rank the whole candidate pool, then truncate — see
    // _candidatePoolSize for why truncating first would be wrong.
    final translationRows = rankAndTruncateTranslationRows([
      ...unrankedRows,
    ], searchString);

    final nameByFoodId = {
      for (final row in translationRows)
        row[SPConst.translationFoodId] as int:
            row[SPConst.translationDescription] as String?,
    };
    final machineTranslatedFoodIds = {
      for (final row in translationRows)
        if (row[SPConst.translationSource] == SPConst.translationSourceMachine)
          row[SPConst.translationFoodId] as int,
    };
    // nameByFoodId's key order mirrors translationRows (a LinkedHashMap
    // keeps first-insertion order), which is now the client-computed
    // relevance order — capture it here so the summary rows fetched below
    // can be put back in that order.
    final rankByFoodId = {
      for (final (rank, foodId) in nameByFoodId.keys.indexed) foodId: rank,
    };

    // The source filter is applied on the summary fetch rather than the
    // translation match: food_translation has no source column.
    //
    // An RPC for the same reason the search above is one, and it is worth
    // being explicit about why: these ids are *derived from the search
    // term*, so an `in.(...)` filter would put a fingerprint of what the
    // user typed straight back into the URL the gateway logs. Removing the
    // term while leaving its shadow behind would not be worth doing.
    final response = await _rpcRows(client, SPConst.foodSummaryByIdsFn, {
      'ids': nameByFoodId.keys.toList(),
      'sources': enabledSources,
    });

    // A WHERE-IN fetch has no guaranteed relationship to its id list's
    // order, so re-sort onto the translation-relevance order captured above
    // rather than trusting food_summary's own (likely physical/PK) order.
    final foods = response.map((food) {
      final dto = SpFoodDTO.fromJson(food);
      dto.localizedName = nameByFoodId[dto.foodId];
      dto.localizedNameIsMachineTranslated = machineTranslatedFoodIds.contains(
        dto.foodId,
      );
      return dto;
    }).toList();
    mergeSort(
      foods,
      compare: (a, b) => (rankByFoodId[a.foodId] ?? rankByFoodId.length)
          .compareTo(rankByFoodId[b.foodId] ?? rankByFoodId.length),
    );
    return foods;
  }
}

/// Ranks [foods] by [textRelevanceScore] against [searchString] and
/// truncates to [SPConst.maxNumberOfItems]. This is the actual client-side
/// replacement for the Postgres `ts_rank` ordering that PostgREST rejects
/// (see [SpFoodDataSource._searchEnglish]) — kept as a standalone top-level
/// function, rather than inlined private logic, so it's directly
/// unit-testable without mocking the Supabase client.
///
/// What is scored is the row's title plus the qualifiers the query names —
/// `deriveTitle` and `deriveQualifiers` of [SpFoodDTO.name], the same
/// derivation `MealEntity.scoringName` and `scoringQualifiers` make of the
/// entity built from this row (#1170). Scored on the whole description, it
/// was not. This scorer charges every token past the one that matched, so
/// on `potato` a family of same-titled survey records did not tie: the
/// twenty with the fewest tokens survived, in backend order among equals,
/// and the record the resolver would pick among the family — the shortest
/// description, or the one carrying the qualifier the query named — could
/// be cut before it was ever scored. Scored on the title, a family ties
/// here as it ties there, and the tie breaks as it breaks there: the
/// shorter description first, then the backend's order, stable. So when a
/// family reaches this cut, its shortest-described member is inside the
/// twenty, and so is a member whose qualifier the query names by the exact
/// token. No portion lookup happens before this cut; the twenty are
/// decorated with theirs afterwards.
///
/// That is one derivation and one tie-break, not one rule, and c78b5a38
/// overstated it as "the resolver's pick is inside the twenty by
/// construction" (#1170 review). Three things stand between this cut and
/// the resolver's whole-pool pick, each pinned in
/// `resolver_sibling_selection_test`:
///
/// * The backend cuts first. Its hundred are the first hundred matches by
///   deliverable portion, then id (see `_candidatePoolSize`), and for
///   `potato` none of the "Potato" family is among them: the app resolves
///   `potato` to "Stewed, seasoned, ground beef with potatoes, Mexican
///   style" at 0.5, above the confidence floor. The 106-row family
///   fixture that was measured here is real rows, but not the pool this
///   function is handed. Of the eighteen families the tie-break decision
///   listed, sixteen resolve on their real pool as listed; potato and
///   bread ("Bread, pita", rye being rank 157) do not.
/// * A qualifier named by prefix alone. [textRelevanceScore] reads a
///   qualifier as named when the query holds the exact token; the
///   resolver's `_namedQualifiers` reads it by soft prefix, so `cheesy`
///   names `cheese` there and not here. On `cheesy potato` the resolver
///   over the whole family picks "Potato, french fries, with cheese"
///   (0.917); here every row scores 0.667 on the title and the twenty
///   shortest survive, that record is cut at 33 characters, and the
///   resolver logs "Potato, NFS" at 0.667.
/// * The no-portions penalty. No portion is known here, so a family whose
///   twenty shortest members carry none keeps those, and the resolver —
///   which takes 0.15 off each — logs one at 0.85 while the member it
///   would have picked from the whole pool, the shortest with portions at
///   1.0, was cut.
@visibleForTesting
List<SpFoodDTO> rankAndTruncateFoodsByName(
  List<SpFoodDTO> foods,
  String searchString,
) => _rankAndTruncate(foods, searchString, (food) => food.name);

/// Same idea as [rankAndTruncateFoodsByName], but for raw `food_translation`
/// rows — ranked by [SPConst.translationDescription] — before they're mapped
/// into [SpFoodDTO] (see [SpFoodDataSource._searchByTranslation]). A
/// translated description follows the same comma convention — "Milch, NFS"
/// is titled "Milch" — and derives its title the way the entity's
/// localized name will.
@visibleForTesting
List<Map<String, dynamic>> rankAndTruncateTranslationRows(
  List<Map<String, dynamic>> rows,
  String searchString,
) => _rankAndTruncate(
  rows,
  searchString,
  (row) => row[SPConst.translationDescription] as String?,
);

/// [items] by the score of their description — [describe] — against
/// [searchString], highest first; among equal scores the shorter
/// description; and the sort is stable, so what is left of a tie keeps the
/// backend's order. The first [SPConst.maxNumberOfItems] of that.
///
/// `mergeSort` rather than `List.sort` for the stability: Dart's sort is an
/// insertion sort under 32 elements, which happens to be stable, and a
/// dual-pivot quicksort above, which is not — and the pool here is a
/// hundred rows. The forty-row tie in `sp_food_data_source_ranking_test`
/// is what pins it; a two-row tie cannot.
List<T> _rankAndTruncate<T>(
  List<T> items,
  String searchString,
  String? Function(T item) describe,
) {
  final decorated = [
    for (final item in items)
      (
        item: item,
        score: _backendScore(describe(item), searchString),
        length: describe(item)?.length ?? 0,
      ),
  ];
  mergeSort(decorated, compare: (a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return a.length.compareTo(b.length);
  });
  return [
    for (final entry in decorated.take(SPConst.maxNumberOfItems)) entry.item,
  ];
}

/// [description] scored as its entity will be: the title, plus whichever
/// of its qualifiers [searchString] names.
double _backendScore(String? description, String searchString) {
  if (description == null) return textRelevanceScore(null, searchString);
  return textRelevanceScore(
    deriveTitle(description),
    searchString,
    qualifiers: deriveQualifiers(description),
  );
}
