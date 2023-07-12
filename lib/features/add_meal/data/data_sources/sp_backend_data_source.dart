import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc_sp/sp_fdc_food_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SPBackendDataSource {
  final log = Logger('SPBackendDataSource');

  Future<List<SpFdcFoodDTO>> fetchSearchWordResults(String searchString) async {
    try {
      log.fine('Fetching Supabase FDC results');
      final supaBaseClient = locator<SupabaseClient>();

      final response = await supaBaseClient
          .from(SPConst.fdcFoodTableName)
          .select<List<Map<String, dynamic>>>(
              '''fdc_id, description_en,  fdc_portions ( measure_unit_id, amount, gram_weight ), fdc_nutrients ( nutrient_id, amount )''')
          .textSearch(SPConst.fdcFoodDescriptionEn, searchString,
              config: 'english', type: TextSearchType.websearch)
          .limit(SPConst.maxNumberOfItems);

      final fdcFoodItems =
          response.map((fdcFood) => SpFdcFoodDTO.fromJson(fdcFood)).toList();

      log.fine('Successful response from Supabase');
      return fdcFoodItems;
    } catch (error) {
      log.severe('Exception while getting FDC word search $error');
      return Future.error(error);
    }
  }
}
