import 'dart:io';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/retry_util.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_fdc_food_dto.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpFdcDataSource {
  final log = Logger('SPBackendDataSource');

  Future<List<SpFdcFoodDTO>> fetchSearchWordResults(String searchString) async {
    try {
      return await withRetry(() async {
        log.fine('Fetching Supabase FDC results');
        final supaBaseClient = locator<SupabaseClient>();
        final queryDescriptionColumn = SPConst.getFdcFoodDescriptionColumnName(
          SupportedLanguage.fromCode(Platform.localeName),
        );
        final selectClause =
            'fdc_id, $queryDescriptionColumn, fdc_portions ( measure_unit_id, amount, gram_weight ), fdc_nutrients ( nutrient_id, amount )';

        var response = await supaBaseClient
            .from(SPConst.fdcFoodTableName)
            .select(selectClause)
            .textSearch(
              queryDescriptionColumn,
              searchString,
              type: TextSearchType.websearch,
            )
            .limit(SPConst.maxNumberOfItems);

        // Full-text search can miss inflected forms (e.g. "Tomate" vs
        // "Tomaten"). Fall back to a substring match when it returns nothing.
        if (response.isEmpty) {
          log.fine('FTS returned no results, falling back to ilike search');
          response = await supaBaseClient
              .from(SPConst.fdcFoodTableName)
              .select(selectClause)
              .ilike(queryDescriptionColumn, '%$searchString%')
              .limit(SPConst.maxNumberOfItems);
        }

        final fdcFoodItems =
            response.map((fdcFood) => SpFdcFoodDTO.fromJson(fdcFood)).toList();

        log.fine('Successful response from Supabase');
        return fdcFoodItems;
      });
    } catch (exception, stacktrace) {
      log.severe('Exception while getting FDC word search $exception');
      Sentry.captureException(exception, stackTrace: stacktrace);
      return Future.error(exception);
    }
  }
}
