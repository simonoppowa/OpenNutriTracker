import 'dart:io';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/retry_util.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Searches the Supabase multi-source food backend (`food_summary` view,
/// see opennutritracker-backend/sql/schema.sql).
class SpFoodDataSource {
  final log = Logger('SpFoodDataSource');

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
  Future<List<String>?> _enabledSources() async {
    final toggles = await locator<ConfigDataSource>().getFoodSourceToggles();
    if (toggles == null) return null;
    final enabled = SPConst.foodSourceDisplayNames.keys
        .where((code) => toggles[code] ?? true)
        .toList();
    if (enabled.length == SPConst.foodSourceDisplayNames.length) return null;
    return enabled;
  }

  Future<List<SpFoodDTO>> _searchEnglish(
    SupabaseClient client,
    String searchString,
    List<String>? enabledSources,
  ) async {
    var query = client.from(SPConst.foodSummaryTable).select().textSearch(
          SPConst.foodName,
          searchString,
          config: SPConst.foodNameFtsConfig,
          type: TextSearchType.websearch,
        );
    if (enabledSources != null) {
      query = query.inFilter(SPConst.foodSource, enabledSources);
    }
    final response = await query.limit(SPConst.maxNumberOfItems);

    // PostgREST's `order` query parameter only accepts column references
    // (`.order('column')`), not computed expressions — `.order(ts_rank(...))`
    // is rejected outright with a parse error (PGRST100), so relevance has
    // to be ranked client-side instead of via Postgres ORDER BY.
    final foods = response.map((food) => SpFoodDTO.fromJson(food)).toList();
    mergeSort(foods,
        compare: (a, b) =>
            textRelevanceScore(b.name, searchString).compareTo(textRelevanceScore(a.name, searchString)));
    return foods;
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
    final unrankedRows = await client
        .from(SPConst.foodTranslationTable)
        .select(
          '${SPConst.translationFoodId}, ${SPConst.translationDescription}, '
          '${SPConst.translationSource}',
        )
        .eq(SPConst.translationLocale, locale)
        .textSearch(
          SPConst.translationDescription,
          searchString,
          config: SPConst.translationFtsConfig,
          type: TextSearchType.websearch,
        )
        .limit(SPConst.maxNumberOfItems);

    if (unrankedRows.isEmpty) return const [];

    // PostgREST's `order` query parameter only accepts column references,
    // not computed expressions — `.order(ts_rank(...))` is rejected outright
    // with a parse error (PGRST100), so translated-text relevance has to be
    // ranked client-side instead of via Postgres ORDER BY (same issue as
    // _searchEnglish).
    final translationRows = [...unrankedRows];
    mergeSort(translationRows,
        compare: (a, b) => textRelevanceScore(
                b[SPConst.translationDescription] as String?, searchString)
            .compareTo(textRelevanceScore(
                a[SPConst.translationDescription] as String?, searchString)));

    final nameByFoodId = {
      for (final row in translationRows)
        row[SPConst.translationFoodId] as int:
            row[SPConst.translationDescription] as String?,
    };
    final machineTranslatedFoodIds = {
      for (final row in translationRows)
        if (row[SPConst.translationSource] ==
            SPConst.translationSourceMachine)
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
    var query = client
        .from(SPConst.foodSummaryTable)
        .select()
        .inFilter(SPConst.foodId, nameByFoodId.keys.toList());
    if (enabledSources != null) {
      query = query.inFilter(SPConst.foodSource, enabledSources);
    }
    final response = await query;

    // A WHERE-IN fetch has no guaranteed relationship to its id list's
    // order, so re-sort onto the translation-relevance order captured above
    // rather than trusting food_summary's own (likely physical/PK) order.
    final foods = response.map((food) {
      final dto = SpFoodDTO.fromJson(food);
      dto.localizedName = nameByFoodId[dto.foodId];
      dto.localizedNameIsMachineTranslated =
          machineTranslatedFoodIds.contains(dto.foodId);
      return dto;
    }).toList();
    foods.sort((a, b) =>
        (rankByFoodId[a.foodId] ?? rankByFoodId.length)
            .compareTo(rankByFoodId[b.foodId] ?? rankByFoodId.length));
    return foods;
  }
}
