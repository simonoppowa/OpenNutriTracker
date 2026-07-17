import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';

import '../helpers/hive_test_setup.dart';
import '../helpers/fake_hive_db_provider.dart';

MealNutrimentsDBO _emptyNutriments({double? kcal}) => MealNutrimentsDBO(
      energyKcal100: kcal,
      carbohydrates100: null,
      fat100: null,
      proteins100: null,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    );

MealDBO _meal({
  String? code,
  String? name,
  double? kcal,
  String? brands,
}) =>
    MealDBO(
      code: code,
      name: name,
      brands: brands,
      thumbnailImageUrl: null,
      mainImageUrl: null,
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: null,
      nutriments: _emptyNutriments(kcal: kcal),
      source: MealSourceDBO.custom,
    );

void main() {
  group('CustomMealDataSource', () {
    late Box<MealDBO> box;
    late CustomMealDataSource ds;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Hive.init('.');
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      box = await Hive.openBox<MealDBO>(
          'custom_meal_test_${DateTime.now().microsecondsSinceEpoch}');
      ds = CustomMealDataSource(FakeHiveDBProvider(customMealBox: box));
    });

    tearDown(() async {
      await box.deleteFromDisk();
    });

    test('saveCustomMeal adds a new meal', () async {
      await ds.saveCustomMeal(_meal(code: '1', name: 'Apple', kcal: 52));
      expect(ds.getAllCustomMeals(), hasLength(1));
      expect(ds.getAllCustomMeals().single.name, equals('Apple'));
    });

    test('saveCustomMeal dedups by barcode (regression for re-import)',
        () async {
      await ds.saveCustomMeal(_meal(code: '1234', name: 'Apple v1', kcal: 52));
      await ds.saveCustomMeal(_meal(code: '1234', name: 'Apple v2', kcal: 60));

      expect(ds.getAllCustomMeals(), hasLength(1));
      final saved = ds.getAllCustomMeals().single;
      expect(saved.name, equals('Apple v2'));
      expect(saved.nutriments.energyKcal100, equals(60));
    });

    test('saveCustomMeal dedups by name when barcode is null', () async {
      await ds.saveCustomMeal(_meal(code: null, name: 'Banana', kcal: 89));
      await ds.saveCustomMeal(_meal(code: null, name: 'Banana', kcal: 95));
      await ds.saveCustomMeal(_meal(code: null, name: 'Apple', kcal: 52));

      expect(ds.getAllCustomMeals(), hasLength(2));
      final names = ds.getAllCustomMeals().map((m) => m.name).toSet();
      expect(names, equals({'Banana', 'Apple'}));
      final banana = ds.getAllCustomMeals().firstWhere((m) => m.name == 'Banana');
      expect(banana.nutriments.energyKcal100, equals(95),
          reason: 'most-recent save should win on dedup');
    });

    test(
        'when a new no-barcode meal shares a name with a barcoded meal, '
        'dedup matches by name and overwrites (documented quirk)', () async {
      await ds.saveCustomMeal(_meal(code: '1', name: 'Apple', kcal: 52));
      await ds.saveCustomMeal(_meal(code: null, name: 'Apple', kcal: 60));

      expect(ds.getAllCustomMeals(), hasLength(1));
      final stored = ds.getAllCustomMeals().single;
      expect(stored.code, isNull);
      expect(stored.nutriments.energyKcal100, equals(60));
    });

    test(
        'a new barcoded meal does NOT match an existing name-only meal: '
        'dedup is keyed on barcode when present', () async {
      await ds.saveCustomMeal(_meal(code: null, name: 'Apple', kcal: 52));
      await ds.saveCustomMeal(_meal(code: '1', name: 'Apple', kcal: 60));

      expect(ds.getAllCustomMeals(), hasLength(2),
          reason: 'incoming meal has a barcode, so it does not match the '
              'name-only entry; both are kept');
    });

    test('deleteCustomMeal removes a meal by its barcode', () async {
      await ds.saveCustomMeal(_meal(code: '1', name: 'Apple'));
      await ds.saveCustomMeal(_meal(code: '2', name: 'Banana'));

      await ds.deleteCustomMeal('1');

      expect(ds.getAllCustomMeals(), hasLength(1));
      expect(ds.getAllCustomMeals().single.code, equals('2'));
    });

    test('deleteCustomMeal removes a name-keyed meal when barcode is null',
        () async {
      await ds.saveCustomMeal(_meal(code: null, name: 'Apple'));
      await ds.saveCustomMeal(_meal(code: null, name: 'Banana'));

      await ds.deleteCustomMeal('Apple');

      expect(ds.getAllCustomMeals(), hasLength(1));
      expect(ds.getAllCustomMeals().single.name, equals('Banana'));
    });

    test('deleteCustomMeal is a no-op for unknown keys', () async {
      await ds.saveCustomMeal(_meal(code: '1', name: 'Apple'));

      await ds.deleteCustomMeal('does-not-exist');

      expect(ds.getAllCustomMeals(), hasLength(1));
    });

    test('getAllCustomMeals returns an empty list initially', () {
      expect(ds.getAllCustomMeals(), isEmpty);
    });
  });
}
