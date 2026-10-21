import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';

/// The fork's reference food search: the local sources in their order, the
/// BLS first, then FoodData Central (#80). Each source applies its own
/// switch; none has portions. A source that fails adds no results instead
/// of failing the search.
class LocalReferenceFoodDataSource extends SpFoodDataSource {
  final List<SpFoodDataSource> _sources;

  LocalReferenceFoodDataSource(this._sources);

  @override
  Future<List<SpFoodDTO>> fetchSearchWordResults(
    String searchString, {
    bool forResolution = false,
  }) async {
    final results = await Future.wait([
      for (final source in _sources)
        source
            .fetchSearchWordResults(searchString, forResolution: forResolution)
            .catchError((Object e) {
              log.warning('Local food source failed: $e');
              return const <SpFoodDTO>[];
            }),
    ]);
    return [for (final list in results) ...list];
  }

  @override
  Future<Map<int, String>> fetchPortionLabels(List<int> foodIds) async =>
      const {};

  @override
  Future<Map<int, List<MealPortionEntity>>?> fetchPortions(
    List<int> foodIds,
  ) async => const {};
}
