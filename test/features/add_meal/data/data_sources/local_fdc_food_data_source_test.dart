import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_fdc_catalog.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_fdc_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

void main() {
  final catalog = LocalFdcCatalog.decode(
    File('assets/fdc/fdc.json.gz').readAsBytesSync(),
  );

  LocalFdcFoodDataSource source({
    Set<String> enabled = const {
      SPConst.fdcFoundationSourceCode,
      SPConst.fdcSrLegacySourceCode,
    },
  }) => LocalFdcFoodDataSource(
    loadCatalog: () async => catalog,
    enabledDatasets: () async => enabled,
  );

  group('the asset', () {
    test('holds both datasets with their FDC ids', () {
      final datasets = {for (final food in catalog.foods) food.dataset};

      expect(datasets, {
        SPConst.fdcFoundationSourceCode,
        SPConst.fdcSrLegacySourceCode,
      });
      expect(catalog.foods.length, greaterThan(8000));
      expect(catalog.foods.every((food) => food.fdcId > 0), isTrue);
    });

    test('every food has an energy value', () {
      expect(
        catalog.foods.where((food) => food.values['energyKcal100'] == null),
        isEmpty,
      );
    });
  });

  group('search', () {
    List<String> top3(String query) => [
      for (final food in catalog.search(query, limit: 3)) food.name,
    ];

    const everyday = <String, String>{
      'banana': 'Bananas, raw',
      'apple': 'Apples, raw, with skin',
      'egg': 'Egg, whole, raw, fresh',
      'oats': 'Oats',
      'quinoa': 'Quinoa, cooked',
      'chicken breast': 'Chicken, breast, boneless, skinless, raw',
    };
    for (final entry in everyday.entries) {
      test('"${entry.key}" finds ${entry.value}', () {
        expect(top3(entry.key), contains(entry.value));
      });
    }

    test('the English plural of a name counts like its singular', () {
      expect(top3('banana').first, 'Bananas, raw');
    });

    test('names carry no USDA program note', () {
      expect(
        catalog.foods.where(
          (food) => food.name.contains('Food Distribution Program'),
        ),
        isEmpty,
      );
    });
  });

  test('finds foods by their English name as FDC records', () async {
    final results = await source(
      enabled: {SPConst.fdcSrLegacySourceCode},
    ).fetchSearchWordResults('apples raw with skin');

    final apple = results.first;
    expect(apple.source, SPConst.fdcSrLegacySourceCode);
    expect(apple.displayName, startsWith('Apples, raw, with skin'));
    expect(apple.energyKcal100, 52);
    expect(apple.vitaminC100, closeTo(4.6, 1e-9));
    expect(apple.selenium100, isNotNull);
    expect(apple.isFdc, isTrue);
  });

  test(
    'turns into a meal linking to its FDC page, with a stable code',
    () async {
      final first = (await source().fetchSearchWordResults('quinoa')).first;
      final again = (await source().fetchSearchWordResults('quinoa')).first;

      final meal = MealEntity.fromSpFood(first);
      expect(meal.backendSource, first.source);
      expect(meal.url, contains(first.sourceCode));
      expect(meal.mealUnit, 'g');
      expect(first.foodId, again.foodId);
    },
  );

  test('only searches the datasets switched on', () async {
    final foundationOnly = await source(
      enabled: {SPConst.fdcFoundationSourceCode},
    ).fetchSearchWordResults('cheese');

    expect(foundationOnly, isNotEmpty);
    expect(foundationOnly.map((dto) => dto.source).toSet(), {
      SPConst.fdcFoundationSourceCode,
    });
    expect(await source(enabled: {}).fetchSearchWordResults('cheese'), isEmpty);
  });

  test('loads the catalog once and not at all while switched off', () async {
    var loads = 0;
    var enabled = <String>{};
    final counting = LocalFdcFoodDataSource(
      loadCatalog: () async {
        loads++;
        return catalog;
      },
      enabledDatasets: () async => enabled,
    );

    await counting.fetchSearchWordResults('apple');
    expect(loads, 0);

    enabled = {SPConst.fdcSrLegacySourceCode};
    await counting.fetchSearchWordResults('apple');
    await counting.fetchSearchWordResults('pear');
    expect(loads, 1);
  });

  test('portion lookups answer empty', () async {
    expect(await source().fetchPortionLabels([1]), isEmpty);
    expect(await source().fetchPortions([1]), isEmpty);
  });
}
