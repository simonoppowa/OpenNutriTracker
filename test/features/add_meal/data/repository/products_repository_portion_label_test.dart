import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_word_response_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';

SpFoodDTO _food(
  int id,
  String name, {
  String? servingSize,
  double carbs = 40,
  double sugars = 5,
}) => SpFoodDTO(
  foodId: id,
  source: 'fdc_survey',
  sourceCode: '$id',
  name: name,
  servingGramWeight: 38,
  servingSize: servingSize,
  energyKcal100: 250,
  carbohydrates100: carbs,
  sugars100: sugars,
  fat100: 4,
  proteins100: 8,
);

class _FakeSp extends SpFoodDataSource {
  _FakeSp(this.foods, this.labels);

  final List<SpFoodDTO> foods;
  final Map<int, String> labels;
  List<int>? askedFor;

  @override
  Future<List<SpFoodDTO>> fetchSearchWordResults(String searchString) async =>
      foods;

  @override
  Future<Map<int, String>> fetchPortionLabels(List<int> foodIds) async {
    askedFor = foodIds;
    return labels;
  }
}

class _FakeOff extends OFFDataSource {
  @override
  Future<OFFWordResponseDTO> fetchSearchWordResults(String searchString) async =>
      OFFWordResponseDTO(
        count: 0, page: 1, page_count: 1, page_size: 0,
        products: const <OFFProductDTO>[],
      );
}

void main() {
  group('a verified portion label reaches the meal (#864)', () {
    test('replaces the English label and marks it localized', () async {
      final sp = _FakeSp(
        [_food(1, 'Bread', servingSize: '1 slice (38 g)')],
        {1: '1 Scheibe (38 g)'},
      );
      final meals =
          await ProductsRepository(_FakeOff(), sp).getSupabaseFoodsByString('bread');

      expect(meals, hasLength(1));
      expect(meals.single.servingSize, '1 Scheibe (38 g)');
      expect(meals.single.servingSizeIsLocalized, isTrue);
    });

    test('a food with no verified label keeps the English one', () async {
      // Partial coverage is the normal case: 109 seeded strings do not cover
      // every food, so the two must be able to sit side by side in one page
      // of results.
      final sp = _FakeSp(
        [
          _food(1, 'Bread', servingSize: '1 slice (38 g)'),
          _food(2, 'Cheese', servingSize: '1 cubic inch (17 g)'),
        ],
        {1: '1 Scheibe (38 g)'},
      );
      final meals =
          await ProductsRepository(_FakeOff(), sp).getSupabaseFoodsByString('x');

      final byName = {for (final m in meals) m.name: m};
      expect(byName['Bread']!.servingSizeIsLocalized, isTrue);
      expect(byName['Cheese']!.servingSize, '1 cubic inch (17 g)');
      expect(byName['Cheese']!.servingSizeIsLocalized, isFalse);
    });

    test('asks only for the foods that survived the consistency filter',
        () async {
      // The lookup runs after filtering, so nothing is fetched for rows that
      // were just dropped.
      //
      // The dropped food has to be genuinely implausible — more sugar than
      // carbohydrate, which #222 rejects — or this passes whether the fetch
      // happens before or after the filter, and pins nothing. An earlier
      // version made exactly that mistake.
      final sp = _FakeSp([
        _food(7, 'Bread', servingSize: '1 slice'),
        _food(8, 'Impossible', servingSize: '1 slice', carbs: 5, sugars: 40),
      ], {});
      final meals =
          await ProductsRepository(_FakeOff(), sp).getSupabaseFoodsByString('b');

      expect(meals.map((m) => m.name), ['Bread'],
          reason: 'the implausible food should have been dropped');
      expect(sp.askedFor, [7],
          reason: 'a dropped food must not be looked up');
    });

    test('an empty label map changes nothing', () async {
      // What every English build gets, and every locale nobody has reviewed:
      // the lookup returns nothing and the results are exactly as before.
      final sp = _FakeSp([_food(1, 'Bread', servingSize: '1 slice (38 g)')], {});
      final meals =
          await ProductsRepository(_FakeOff(), sp).getSupabaseFoodsByString('b');
      expect(meals.single.servingSize, '1 slice (38 g)');
      expect(meals.single.servingSizeIsLocalized, isFalse);
    });
  });
}
