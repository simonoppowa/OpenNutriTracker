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
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart'
    show noPortionsPenalty;
import 'package:opennutritracker/features/add_meal/util/soft_text_score.dart';
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
  /// runs: `search_food_summary` stops at this many rows, ordered — since
  /// Backend#10, applied 2026-09-13 — by `food_has_deliverable_portion
  /// (food_id) desc`, then whether the row's title (its name up to the
  /// first comma) equals the term, then `length(name)`, then `food_id`.
  /// The rows with a portion come first; among them a family the term
  /// names by its title, shortest description first; `search_food
  /// _translation` orders the translated descriptions the same way. So a
  /// family reaches [rankAndTruncateFoodsByName] whole and in the order
  /// its tie-break would put it in: `potato` matches 712 rows and the
  /// hundred are a hundred rows titled "Potato", "Potato, NFS" first. The
  /// order before it — portion, then id — handed the hundred lowest-id
  /// matches with a portion, which for `potato` were all beef stews and
  /// shish kabobs, the family sitting at ranks 128 to 488, and the
  /// resolver logged a stew (#1170 review). Nothing below can rank a row
  /// it was not sent, so the twenty kept are the twenty best of the
  /// backend's hundred; the backend's order is what makes those the
  /// twenty best of the backend.
  static const _candidatePoolSize = SPConst.maxNumberOfItems * 5;

  /// The twenty rows the app keeps of the backend's hundred for
  /// [searchString], cut by the resolver's rule (see
  /// [rankAndTruncateFoodsByName]). [forResolution] says whose twenty they
  /// are: the resolver's, and the cut reads each row's `has_portion`
  /// column; or the Food tab's — the default — and it does not (#1164,
  /// #1190; the cut's comment says why the two differ).
  Future<List<SpFoodDTO>> fetchSearchWordResults(
    String searchString, {
    bool forResolution = false,
  }) async {
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
            forResolution: forResolution,
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
          forResolution: forResolution,
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
  /// here costs nothing and must never cost a search. Unlike [fetchPortions]
  /// it does not say whether it failed: nothing downstream scores a label,
  /// and "no verified label" and "could not ask" both leave the English one
  /// where it was.
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

  /// Every usable portion per food id, in the backend's order — or null when
  /// the backend could not be asked.
  ///
  /// Never throws, as [fetchPortionLabels] never throws: the caller's
  /// fallback is the single serving it already has, and a portion list is
  /// not worth costing anyone a search. But a failure here is not an empty
  /// answer, and the two are told apart because something downstream reads
  /// the difference: the resolver takes 0.15 off a backend record with no
  /// portion ([noPortionsPenalty] in `resolver_relevance.dart`), and after
  /// a transient failure of this one call every record on a page the search
  /// itself answered would have taken it — a 0.5 match reported at 0.35,
  /// under the confidence floor, for a fault in a lookup the record never
  /// had a say in (#1170 review). So: a map, with no entry for a food the
  /// backend has no portion for, when the backend answered; null when it
  /// did not. `ProductsRepository` marks the page's entities
  /// `portionsUnavailable` on null, and the penalty stands down for them.
  ///
  /// Unlike the label lookup this runs for English too — the choice between a
  /// food's cup, slice and ounce is worth offering whether or not the words
  /// needed translating.
  Future<Map<int, List<MealPortionEntity>>?> fetchPortions(
    List<int> foodIds,
  ) async {
    // Nothing to ask about is not a failure: an empty page has no record to
    // penalise or to spare.
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
      log.fine('Portions unavailable: $e');
      return null;
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
    List<String>? enabledSources, {
    required bool forResolution,
  }) async {
    // An RPC rather than a filtered select on the view, so the term travels
    // in the POST body instead of the query string — see [SPConst
    // .searchFoodSummaryFn]. The function returns `setof food_summary`, so
    // the rows arrive in exactly the shape `select()` produced and
    // [SpFoodDTO.fromJson] reads them as it reads the view — including
    // `has_portion`, which the view carries once the backend's
    // `2026-09-13_food_summary_has_portion` migration is applied and the
    // DTO reads as null until then. The source filter and the row cap
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
    return rankAndTruncateFoodsByName(
      foods,
      searchString,
      forResolution: forResolution,
    );
  }

  /// Two-step localized search: `food_summary` is a materialized view, so
  /// PostgREST cannot embed `food_translation` into it (no FK to follow).
  /// Match the translated descriptions first, then fetch the summary rows
  /// for the matched food ids and carry the translated name over.
  Future<List<SpFoodDTO>> _searchByTranslation(
    SupabaseClient client,
    String locale,
    String searchString,
    List<String>? enabledSources, {
    required bool forResolution,
  }) async {
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
    final translationRows = rankAndTruncateTranslationRows(
      [...unrankedRows],
      searchString,
      forResolution: forResolution,
    );

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

/// Ranks [foods] by [scoreText] against [searchString] and truncates to
/// [SPConst.maxNumberOfItems]. This is the actual client-side replacement
/// for the Postgres `ts_rank` ordering that PostgREST rejects (see
/// [SpFoodDataSource._searchEnglish]) — kept as a standalone top-level
/// function, rather than inlined private logic, so it's directly
/// unit-testable without mocking the Supabase client.
///
/// The twenty rows kept here are the resolver's whole world for the
/// query, and the resolver auto-selects among them unread, so they are
/// chosen by the resolver's own rule: what is scored is the row's title
/// plus the qualifiers the query names — `deriveTitle` and
/// `deriveQualifiers` of [SpFoodDTO.name], the derivation
/// `MealEntity.scoringName` and `scoringQualifiers` make of the entity
/// built from this row — with the scorer `scoreMealForResolution` scores
/// that entity with, `scoreText`, which names a qualifier by soft prefix
/// (`namedQualifiers`); [forResolution], a row the backend says has no
/// portion takes [noPortionsPenalty] off, as the entity will there; and
/// ties break as they break there: the shorter description first, then —
/// [forResolution] — the row with a portion, then the backend's order,
/// stable (#1170, #1190). Scored on
/// the whole description, a family of same-titled survey records did not
/// tie here as it tied there, and the record the resolver would pick was
/// cut before it was scored; scored on the title but with the Food tab's
/// ranker, which names a qualifier by the exact token, `cheesy potato`
/// named `cheese` in the resolver and not here, and "Potato, french
/// fries, with cheese" was cut the same way. The survivors and the
/// resolver now apply one rule, so the resolver's pick is inside the
/// twenty by construction — up to what this cut does not read, which is
/// two things:
///
/// * The portions themselves. They are fetched for the twenty after this
///   cut, so the resolver's penalty and its "most portions" key read a
///   list this cut never has; what it has instead is the row's
///   `has_portion` column, `food_has_deliverable_portion(food_id)` —
///   the predicate `portions_by_food_ids` filters on, so the column is
///   true exactly where the fetched list will not be empty (the backend's
///   `2026-09-13_food_summary_has_portion` migration). It is the boolean
///   shadow of the count: enough for the penalty,
///   which asks whether there is a portion, and enough to put a row with
///   one before a row without among equal scores and lengths — the
///   resolver's key collapsed to whether there are any, which is all the
///   column can say, and applied in the same direction. So a
///   portion-bearing record the resolver would pick is inside the twenty
///   unless twenty rows tie it on score, length and the flag and carry
///   fewer portions each, which is the one key this cut cannot rank, and
///   the case that bit is closed. `muffins` is the exact title of the
///   twenty SR Legacy "Muffins, …" rows at 1.0 and a soft match for the
///   survey's "Muffin" family at 0.857 (`muffins` → `muffin`, six letters
///   of seven); read without the flag, the twenty were kept, "Muffin,
///   NFS" was twenty-first, and the resolver logged "Muffins, oat bran"
///   at 0.85 with nothing to scale the amount with. Read with it, none of
///   the twenty has a portion and they fall to 0.85 behind the
///   thirty-three survey rows that carry one, the twenty shortest of
///   those are kept with "Muffin, NFS" first, and the resolver picks
///   what it picks from the whole pool. `puddings` and `ice creams` go
///   the same way.
///
///   Where the backend does not send the column — every backend before
///   that migration is applied, which the live one is at this writing —
///   the flag is null on every row, and this cut applies no penalty and no
///   key: the twenty are the twenty it kept before the column existed,
///   and `muffins` is lost as above. Null is the absence of an answer and
///   is never read as "no portion"; [SpFoodDTO.hasPortion] says why.
///   `resolver_sibling_selection_test` pins the miss without the flag
///   and its closure with it, on the real muffins pool and on a
///   synthetic family, and re-pins every other pool with the flag set as
///   the backend will set it.
///
/// * [rankAndTruncateTranslationRows] is handed each row's translation
///   `source` and does not read it, where the resolver takes 0.03 off a
///   machine translation. A native row the resolver would pick is lost
///   behind twenty machine rows scoring at least what it scores and less
///   than 0.03 above it, no longer than it. On the live German
///   translations (2026-09-13) that changes no pick: every native row is
///   a BLS row and none of the 7,140 carries a deliverable portion, so
///   wherever a portion-bearing machine sibling scores within 0.12 of a
///   native row the resolver never picked the native row to begin with —
///   `cracker`, the one title with a native row and twenty machine rows
///   titled the same, has forty-nine portion-bearing ones. The same test
///   pins it on a synthetic family.
///
/// The Food tab's twenty are cut by the same rule with the flag unread —
/// [forResolution] false, the default, which is what `FoodBloc`'s search
/// asks for through `SearchProductsUseCase.searchFDCFoodByString`: no
/// penalty on a row without a portion, no key on the one with. #1164
/// decided the penalty for the resolver "and nowhere else" — a person
/// browsing the list is not logging an amount yet, a German reader wants
/// the native BLS record where it is and none of the 7,140 carries a
/// portion, and the portionless record stays in the candidate list — and
/// #1190 asked this cut to apply it because the resolver's page is cut
/// here; the cut is one function on both paths, so it reads the column
/// only for the page #1190 is about. Read for the Food tab too, the
/// column cut seven BLS rows from `apple`'s twenty — "Apple raw", "Apple
/// juice", "Apple sauce" among them — for "Crisp, apple", "Cobbler,
/// apple" and a "Carrots, raw, salad with apples" scoring nothing, and
/// every BLS, SR Legacy and Foundation raw record from `chicken breast`'s
/// for twenty survey dishes. `sp_food_data_source_ranking_test` pins the
/// Food tab's twenty as the same twenty with the column as without.
///
/// The Food tab ranks its twenty for display with `scoreMealRelevance`,
/// which matches exactly and adds contains and prefix bonuses; where it
/// disagrees with the soft score it reorders the twenty for a list the
/// user reads, and nothing the user could have scrolled to is lost by
/// choosing them this way.
@visibleForTesting
List<SpFoodDTO> rankAndTruncateFoodsByName(
  List<SpFoodDTO> foods,
  String searchString, {
  bool forResolution = false,
}) => _rankAndTruncate(
  foods,
  searchString,
  describe: (food) => food.name,
  hasPortion: forResolution ? (food) => food.hasPortion : (_) => null,
);

/// Same idea as [rankAndTruncateFoodsByName], but for raw `food_translation`
/// rows — ranked by [SPConst.translationDescription] — before they're mapped
/// into [SpFoodDTO] (see [SpFoodDataSource._searchByTranslation]). A
/// translated description follows the same comma convention — "Milch, NFS"
/// is titled "Milch" — and derives its title the way the entity's
/// localized name will. [forResolution] as there: the row's
/// [SPConst.translationHasPortion] is read for the resolver's page and not
/// for the Food tab's. Read, it is a boolean where the backend sent one
/// and null — no penalty, no key — where it did not, or sent something
/// else: this reader has a raw map and no schema, so it declines an odd
/// value rather than throw on it, where [SpFoodDTO.fromJson] casts the
/// column as it casts every other and would throw. Neither path is
/// reachable from Postgres, whose boolean is JSON's; the two differ only
/// in what they would do with a backend that sent something else.
@visibleForTesting
List<Map<String, dynamic>> rankAndTruncateTranslationRows(
  List<Map<String, dynamic>> rows,
  String searchString, {
  bool forResolution = false,
}) => _rankAndTruncate(
  rows,
  searchString,
  describe: (row) => row[SPConst.translationDescription] as String?,
  hasPortion: forResolution
      ? (row) {
          final flag = row[SPConst.translationHasPortion];
          return flag is bool ? flag : null;
        }
      : (_) => null,
);

/// [items] by the score of their description — [describe], as its title
/// plus the qualifiers [searchString] names, less [noPortionsPenalty]
/// where [hasPortion] is false — highest first; among equal scores the
/// shorter description; among those, a row with a portion before a row
/// without; and the sort is stable, so what is left of a tie keeps the
/// backend's order. The first [SPConst.maxNumberOfItems] of that.
///
/// The portion key ranks the flag as the resolver's key ranks the count
/// it shadows (`_sorted` in `resolver_relevance.dart`, portions
/// descending): true before false. Between a row with a portion and a
/// row without, it is reached at any equal score, which after the
/// penalty means one of two things: a base gap of exactly 0.15 — the
/// unflagged row at 1.0 and the flagged one at 0.85, `1.0 - 0.15 ==
/// 0.85` in Dart — or a clamp at 0.0 holding a penalised row; either
/// way the flagged row goes first, as its entity does there. It is here
/// so that the two sorts are the same sort, not because a live pool
/// turns on it. Null — the backend did not send the column — is not a third
/// value but the absence of one, and ranks with false so that a pool
/// with no flags at all has no key at all and is ordered as it was
/// before the column existed; the same pool with the column is ordered
/// as the resolver will order its entities, whose portion lists are
/// empty where the flag is false. Every row here is a backend row — the
/// entity built from it is `MealSourceEntity.fdc` whatever its `source`
/// — so the penalty needs no guard on the source here where the
/// resolver, which also sees Open Food Facts products, needs one.
///
/// `mergeSort` rather than `List.sort` for the stability: Dart's sort is an
/// insertion sort under 32 elements, which happens to be stable, and a
/// dual-pivot quicksort above, which is not — and the pool here is a
/// hundred rows. The forty-row ties in `sp_food_data_source_ranking_test`
/// are what pin it, with the flag and without; a two-row tie cannot.
List<T> _rankAndTruncate<T>(
  List<T> items,
  String searchString, {
  required String? Function(T item) describe,
  required bool? Function(T item) hasPortion,
}) {
  final queryTokens = tokenize(searchString);
  final decorated = [
    for (final item in items)
      (
        item: item,
        score: _backendScore(describe(item), queryTokens, hasPortion(item)),
        length: describe(item)?.length ?? 0,
        portioned: hasPortion(item) == true ? 1 : 0,
      ),
  ];
  mergeSort(decorated, compare: (a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byLength = a.length.compareTo(b.length);
    if (byLength != 0) return byLength;
    return b.portioned.compareTo(a.portioned);
  });
  return [
    for (final entry in decorated.take(SPConst.maxNumberOfItems)) entry.item,
  ];
}

/// [description] scored as its entity will be: the title, plus whichever
/// of its qualifiers the query names — [scoreText], the resolver's own —
/// less [noPortionsPenalty] when the backend says there is no portion,
/// clamped as the resolver clamps. Null [hasPortion] costs nothing: the
/// backend did not say.
double _backendScore(
  String? description,
  Set<String> queryTokens,
  bool? hasPortion,
) {
  if (description == null) return 0.0;
  final score = scoreText(
    deriveTitle(description),
    queryTokens,
    qualifiers: deriveQualifiers(description),
  );
  if (hasPortion == false) return (score - noPortionsPenalty).clamp(0.0, 1.0);
  return score;
}
