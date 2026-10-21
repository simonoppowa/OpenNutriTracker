import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_reference_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';

class _Source extends SpFoodDataSource {
  final List<SpFoodDTO> results;
  final bool fails;
  final queries = <String>[];

  _Source(this.results, {this.fails = false});

  @override
  Future<List<SpFoodDTO>> fetchSearchWordResults(
    String searchString, {
    bool forResolution = false,
  }) async {
    queries.add(searchString);
    if (fails) throw StateError('catalog failed to load');
    return results;
  }

  @override
  Future<Map<int, String>> fetchPortionLabels(List<int> foodIds) async =>
      const {};

  @override
  Future<Map<int, List<MealPortionEntity>>?> fetchPortions(
    List<int> foodIds,
  ) async => const {};
}

void main() {
  SpFoodDTO dto(int id, String source) => SpFoodDTO(
    foodId: id,
    source: source,
    sourceCode: '$id',
    name: 'food $id',
  );

  test('asks every source and keeps their order, BLS first', () async {
    final bls = _Source([dto(1, 'bls'), dto(2, 'bls')]);
    final fdc = _Source([dto(3, 'fdc_sr_legacy')]);

    final results = await LocalReferenceFoodDataSource([
      bls,
      fdc,
    ]).fetchSearchWordResults('apple');

    expect([for (final r in results) r.foodId], [1, 2, 3]);
    expect(bls.queries, ['apple']);
    expect(fdc.queries, ['apple']);
  });

  test('a failing source does not take the others down', () async {
    final results = await LocalReferenceFoodDataSource([
      _Source([dto(1, 'bls')]),
      _Source(const [], fails: true),
    ]).fetchSearchWordResults('apple');

    expect([for (final r in results) r.foodId], [1]);
  });

  test('portion lookups answer empty', () async {
    final source = LocalReferenceFoodDataSource([_Source(const [])]);

    expect(await source.fetchPortionLabels([1]), isEmpty);
    expect(await source.fetchPortions([1]), isEmpty);
  });
}
