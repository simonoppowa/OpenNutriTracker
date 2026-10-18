import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';

/// Stands in for [SpFoodDataSource] in this fork, which has no Supabase food
/// backend: every lookup answers empty and nothing touches the network, so
/// the Food searches fall back to saved meals and recipes until the local
/// BLS source replaces this class.
class OfflineSpFoodDataSource extends SpFoodDataSource {
  @override
  Future<List<SpFoodDTO>> fetchSearchWordResults(
    String searchString, {
    bool forResolution = false,
  }) async => const [];

  @override
  Future<Map<int, String>> fetchPortionLabels(List<int> foodIds) async =>
      const {};

  @override
  Future<Map<int, List<MealPortionEntity>>?> fetchPortions(
    List<int> foodIds,
  ) async => const {};
}
