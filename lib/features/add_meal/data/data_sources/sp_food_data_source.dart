import 'dart:io';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/retry_util.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
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
    // Order by text-search relevance so the best matches land in the
    // top 20 rather than an arbitrary physical order.
    if (enabledSources != null) {
      query = query.inFilter(SPConst.foodSource, enabledSources);
    }
    final response = await query
        .order(
          "ts_rank(to_tsvector('english', \"$SPConst.foodName\"), "
          "plainto_tsquery('english', '${searchString.replaceAll("'", "''")}'))",
          ascending: false,
        )
        .limit(SPConst.maxNumberOfItems);

    return response.map((food) => SpFoodDTO.fromJson(food)).toList();
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
    final translationRows = await client
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

    if (translationRows.isEmpty) return const [];

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

    return response.map((food) {
      final dto = SpFoodDTO.fromJson(food);
      dto.localizedName = nameByFoodId[dto.foodId];
      dto.localizedNameIsMachineTranslated =
          machineTranslatedFoodIds.contains(dto.foodId);
      return dto;
    }).toList();
  }
}
