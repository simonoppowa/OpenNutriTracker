import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_word_response_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart';

SpFoodDTO _food(int id, String name) => SpFoodDTO(
  foodId: id,
  source: 'fdc_survey',
  sourceCode: '$id',
  name: name,
  servingGramWeight: 38,
  servingSize: '1 slice',
  energyKcal100: 250,
  carbohydrates100: 40,
  sugars100: 5,
  fat100: 4,
  proteins100: 8,
);

MealPortionEntity _portion(String label) =>
    MealPortionEntity(label: label, gramWeight: 38, localized: false);

/// The backend as the repository sees it: a page of foods, a label map, and
/// a portion lookup that either answers ([portions]) or fails (null).
class _FakeSp extends SpFoodDataSource {
  _FakeSp(this.foods, {this.labels = const {}, required this.portions});

  final List<SpFoodDTO> foods;
  final Map<int, String> labels;
  final Map<int, List<MealPortionEntity>>? portions;

  @override
  Future<List<SpFoodDTO>> fetchSearchWordResults(String searchString) async =>
      foods;

  @override
  Future<Map<int, String>> fetchPortionLabels(List<int> foodIds) async =>
      labels;

  @override
  Future<Map<int, List<MealPortionEntity>>?> fetchPortions(
    List<int> foodIds,
  ) async => portions;
}

class _NoOff extends OFFDataSource {
  @override
  Future<OFFWordResponseDTO> fetchSearchWordResults(
    String searchString,
  ) async => OFFWordResponseDTO(
    count: 0,
    page: 1,
    page_count: 1,
    page_size: 0,
    products: const <OFFProductDTO>[],
  );
}

Future<Map<String, MealEntity>> _search(_FakeSp sp) async {
  final meals = await ProductsRepository(
    _NoOff(),
    sp,
  ).getSupabaseFoodsByString('bread');
  return {for (final meal in meals) meal.name!: meal};
}

void main() {
  // The portion lookup is a second call after the search itself, and it can
  // fail on its own. Before #1170's review a failure came back as an empty
  // map, indistinguishable from a backend that has no portion for any food
  // on the page, and every record then took the resolver's no-portions
  // penalty for a search that had succeeded: 1.0 reported as 0.85, a 0.5
  // match at 0.35 and under the confidence floor.
  group('a portion lookup that failed is not a backend with no portions', () {
    test(
      'a failed lookup marks every entity and costs no confidence',
      () async {
        final byName = await _search(
          _FakeSp([
            _food(1, 'Bread, rye'),
            _food(2, 'Bread, white'),
          ], portions: null),
        );

        for (final meal in byName.values) {
          expect(meal.portionsUnavailable, isTrue);
          expect(meal.portions, isEmpty);
        }
        // Scored on the text alone, as if the question had not been asked.
        expect(scoreMealForResolution(byName['Bread, rye']!, 'bread'), 1.0);
        expect(scoreMealForResolution(byName['Bread, white']!, 'bread'), 1.0);
      },
    );

    test(
      'a lookup that answered with nothing for a food is confirmed empty',
      () async {
        // The backend was asked and had no row: that is the case the penalty
        // was made for, and it applies.
        final byName = await _search(
          _FakeSp([_food(1, 'Bread, rye')], portions: const {}),
        );

        final meal = byName['Bread, rye']!;
        expect(meal.portionsUnavailable, isFalse);
        expect(meal.portions, isEmpty);
        expect(scoreMealForResolution(meal, 'bread'), closeTo(0.85, 1e-9));
      },
    );

    test(
      'an answered lookup tells the portioned from the bare, per food',
      () async {
        // One page, one answer: the food the backend has portions for gets
        // them, the food it has none for is bare and penalised, and neither
        // is "unavailable" — the lookup worked.
        final byName = await _search(
          _FakeSp(
            [_food(1, 'Bread, rye'), _food(2, 'Bread, white')],
            portions: {
              1: [_portion('1 slice'), _portion('1 loaf')],
            },
          ),
        );

        final rye = byName['Bread, rye']!;
        final white = byName['Bread, white']!;
        expect(rye.portions, hasLength(2));
        expect(rye.portionsUnavailable, isFalse);
        expect(scoreMealForResolution(rye, 'bread'), 1.0);
        expect(white.portions, isEmpty);
        expect(white.portionsUnavailable, isFalse);
        expect(scoreMealForResolution(white, 'bread'), closeTo(0.85, 1e-9));
      },
    );

    test('the flag survives the rest of the decoration', () async {
      // The label lookup answered and the portion lookup did not: the
      // entity carries the verified label and is still marked, whichever
      // order the two are applied in.
      final byName = await _search(
        _FakeSp(
          [_food(1, 'Bread, rye')],
          labels: {1: '1 Scheibe (38 g)'},
          portions: null,
        ),
      );

      final meal = byName['Bread, rye']!;
      expect(meal.servingSize, '1 Scheibe (38 g)');
      expect(meal.servingSizeIsLocalized, isTrue);
      expect(meal.portionsUnavailable, isTrue);
      expect(scoreMealForResolution(meal, 'bread'), 1.0);
    });

    test('the flag does not survive the search cache', () async {
      // `MealDBO` has no column for it, as it has none for the portions, so
      // a copy read back is neither flagged nor portioned and is penalised
      // as every cached copy is — the cache cannot say what the backend has
      // for the row, and a cached copy cannot scale an amount either way.
      final byName = await _search(
        _FakeSp([_food(1, 'Bread, rye')], portions: null),
      );
      final fresh = byName['Bread, rye']!;
      expect(fresh.portionsUnavailable, isTrue);

      final dbo = MealDBO.fromMealEntity(fresh);
      final cached = MealEntity.fromMealDBO(dbo);

      expect(dbo.toJson().keys, isNot(contains('portionsUnavailable')));
      expect(cached.portionsUnavailable, isFalse);
      expect(cached.portions, isEmpty);
      expect(scoreMealForResolution(cached, 'bread'), closeTo(0.85, 1e-9));
    });
  });
}
