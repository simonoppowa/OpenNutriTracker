import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_bls_catalog.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_bls_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

void main() {
  final catalog = LocalBlsCatalog.decode(
    File('assets/bls/bls_4_0.json.gz').readAsBytesSync(),
  );

  LocalBlsFoodDataSource source({
    bool enabled = true,
    String locale = 'de_DE',
  }) => LocalBlsFoodDataSource(
    loadCatalog: () async => catalog,
    isEnabled: () async => enabled,
    localeName: () => locale,
  );

  test('finds BLS foods and hands them on as BLS records', () async {
    final results = await source().fetchSearchWordResults('Haferflocken');

    final oats = results.first;
    expect(oats.source, 'bls');
    expect(oats.sourceCode, 'C133000');
    expect(oats.displayName, 'Hafer Flocken');
    expect(oats.energyKcal100, 348);
    expect(oats.vitaminB6100, closeTo(0.098, 1e-9));
    expect(oats.transFat100, isNull);
  });

  test('names foods in English outside German', () async {
    final results = await source(
      locale: 'en_US',
    ).fetchSearchWordResults('Haferflocken');

    expect(results.first.displayName, isNot('Hafer Flocken'));
    expect(results.first.displayName, isNotEmpty);
  });

  test('turns into a meal the app can log, with a stable code', () async {
    final first = (await source().fetchSearchWordResults('Banane')).first;
    final again = (await source().fetchSearchWordResults('Banane roh')).first;

    final meal = MealEntity.fromSpFood(first);
    expect(meal.backendSource, 'bls');
    expect(meal.mealUnit, 'g');
    expect(meal.nutriments.energyKcal100, 79);
    expect(first.foodId, again.foodId);
    expect(first.foodId, isNotNull);
  });

  test('soft drinks (BLS group N) are measured in millilitres', () async {
    final cola = (await source().fetchSearchWordResults('Cola')).first;

    expect(cola.sourceCode, startsWith('N'));
    expect(MealEntity.fromSpFood(cola).mealUnit, 'ml');
  });

  test('switched off in the food sources it finds nothing', () async {
    expect(
      await source(enabled: false).fetchSearchWordResults('Banane'),
      isEmpty,
    );
  });

  test('portion lookups answer empty', () async {
    expect(await source().fetchPortionLabels([1]), isEmpty);
    expect(await source().fetchPortions([1]), isEmpty);
  });

  test('loads the catalog once', () async {
    var loads = 0;
    final counting = LocalBlsFoodDataSource(
      loadCatalog: () async {
        loads++;
        return catalog;
      },
      isEnabled: () async => true,
      localeName: () => 'de_DE',
    );

    await counting.fetchSearchWordResults('Apfel');
    await counting.fetchSearchWordResults('Birne');

    expect(loads, 1);
  });
}
