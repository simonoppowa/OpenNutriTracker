import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/search/search_ordering.dart';

MealEntity _meal(
  String code,
  String name, {
  String? brands,
  MealSourceEntity source = MealSourceEntity.off,
  String? backendSource,
}) => MealEntity(
  code: code,
  name: name,
  brands: brands,
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: source,
  backendSource: backendSource,
);

void main() {
  final own = _meal(
    'own',
    'Mango-Maracuja Smoothie',
    source: MealSourceEntity.custom,
  );
  final albi = _meal('albi', 'Albi Mangosaft', brands: 'Albi');
  final kaufland = _meal('kaufland', 'Mango Nektar', brands: 'Kaufland');
  final paradiso = _meal(
    '28410768',
    'Mango-Maracuja Nektar',
    brands: 'Paradiso',
  );

  test('products of a named brand come right after the own entries', () {
    expect(
      SearchOrdering.brandFirst([
        own,
        albi,
        kaufland,
        paradiso,
      ], 'Paradiso Mango-Maracuja').map((m) => m.code),
      ['own', '28410768', 'albi', 'kaufland'],
    );
  });

  test('without a named brand the order stays', () {
    expect(
      SearchOrdering.brandFirst([
        albi,
        paradiso,
        kaufland,
      ], 'Mango Nektar').map((m) => m.code),
      ['albi', '28410768', 'kaufland'],
    );
  });

  test('a store name prefers its own brands', () {
    final naturgut = _meal('ng', 'Bio Studenten-Futter', brands: 'Natur Gut');
    final dm = _meal('dm', 'Studenten Futter', brands: 'dm Bio');

    expect(
      SearchOrdering.brandFirst([
        dm,
        naturgut,
      ], 'Penny Studentenfutter').map((m) => m.code),
      ['ng', 'dm'],
    );
  });

  group('the merged list', () {
    final bls = _meal(
      'bls',
      'Haferflocken',
      source: MealSourceEntity.fdc,
      backendSource: SPConst.blsSourceCode,
    );
    final offGeneric = _meal('off', 'Haferflocken', brands: 'Kölln');
    final offBetter = _meal('off2', 'Haferflocken zart', brands: 'ja!');

    test('a BLS food goes ahead of an Open Food Facts product of equal '
        'relevance', () {
      expect(
        SearchOrdering.rankMerged([
          offGeneric,
          bls,
        ], 'Haferflocken').map((m) => m.code),
        ['bls', 'off'],
      );
    });

    test('but not ahead of a clearly better match', () {
      final blsWorse = _meal(
        'bls2',
        'Hafer Flocken Vollkorn kernig',
        source: MealSourceEntity.fdc,
        backendSource: SPConst.blsSourceCode,
      );

      expect(
        SearchOrdering.rankMerged([
          offGeneric,
          blsWorse,
        ], 'Haferflocken').map((m) => m.code),
        ['off', 'bls2'],
      );
    });

    test('own entries and a named brand still lead', () {
      expect(
        SearchOrdering.rankMerged([
          own,
          offGeneric,
          bls,
          offBetter,
        ], 'ja Haferflocken').first.code,
        'own',
      );
      expect(
        SearchOrdering.rankMerged([
          offGeneric,
          bls,
          offBetter,
        ], 'ja! Haferflocken').first.code,
        'off2',
      );
    });
  });
}
