import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_ingredient_dbo.dart';
import 'package:opennutritracker/core/utils/csv_data_exporter.dart';
import 'package:opennutritracker/core/utils/off_micronutrient_repair.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

// Every value is what Open Food Facts sends for a real product — grams,
// whatever the label used — and what a build before #775 therefore wrote.
// The expectations are the app's units, the same pairs #775's own test
// reads in both directions.
MealNutrimentsDBO _offGramsAsStoredBefore775() => MealNutrimentsDBO(
  energyKcal100: 250,
  carbohydrates100: 30,
  fat100: 10,
  proteins100: 8,
  sugars100: 12,
  saturatedFat100: 4,
  fiber100: 2,
  monounsaturatedFat100: 1.1,
  polyunsaturatedFat100: 2.2,
  transFat100: 0.5,
  cholesterol100: 0.055,
  sodium100: 0.12,
  potassium100: 0.3,
  magnesium100: 0.025,
  calcium100: 0.1,
  iron100: 0.002,
  zinc100: 0.001,
  phosphorus100: 0.15,
  vitaminA100: 0.00009,
  vitaminC100: 0.045,
  vitaminD100: 0.000005,
  vitaminB6100: 0.0003,
  vitaminB12100: 0.0000015,
  niacin100: 0.008,
);

void _expectAppUnits(MealNutrimentsDBO n) {
  // Macros and the three lipid fields are grams on both sides.
  expect(n.energyKcal100, 250);
  expect(n.carbohydrates100, 30);
  expect(n.fat100, 10);
  expect(n.proteins100, 8);
  expect(n.sugars100, 12);
  expect(n.saturatedFat100, 4);
  expect(n.fiber100, 2);
  expect(n.monounsaturatedFat100, 1.1);
  expect(n.polyunsaturatedFat100, 2.2);
  expect(n.transFat100, 0.5);
  // Milligrams from here down.
  expect(n.cholesterol100, closeTo(55, 1e-9));
  expect(n.sodium100, closeTo(120, 1e-9));
  expect(n.potassium100, closeTo(300, 1e-9));
  expect(n.magnesium100, closeTo(25, 1e-9));
  expect(n.calcium100, closeTo(100, 1e-9));
  expect(n.iron100, closeTo(2, 1e-9));
  expect(n.zinc100, closeTo(1, 1e-9));
  expect(n.phosphorus100, closeTo(150, 1e-9));
  expect(n.vitaminC100, closeTo(45, 1e-9));
  expect(n.vitaminB6100, closeTo(0.3, 1e-9));
  expect(n.niacin100, closeTo(8, 1e-9));
  // Micrograms for A, D and B12.
  expect(n.vitaminA100, closeTo(90, 1e-9));
  expect(n.vitaminD100, closeTo(5, 1e-9));
  expect(n.vitaminB12100, closeTo(1.5, 1e-9));
}

MealDBO _meal({
  required MealSourceDBO source,
  MealNutrimentsDBO? nutriments,
  int? dataVersion,
  String? code = '3017620422003',
  String name = 'Nutella',
  bool? detailed,
}) => MealDBO(
  code: code,
  name: name,
  brands: 'Ferrero',
  thumbnailImageUrl: 'https://example.test/thumb.jpg',
  mainImageUrl: null,
  url: 'https://world.openfoodfacts.org/product/3017620422003',
  mealQuantity: '400',
  mealUnit: 'g',
  servingQuantity: 15,
  servingUnit: 'g',
  servingSize: '15 g',
  source: source,
  nutriments: nutriments ?? _offGramsAsStoredBefore775(),
  detailed: detailed,
  dataVersion: dataVersion,
);

/// A row the way a build carrying #775 writes it: the entity mapping has
/// already converted, and [MealDBO.fromMealEntity] stamps the version.
MealDBO _mealWrittenAfter775({
  MealSourceEntity source = MealSourceEntity.off,
}) => MealDBO.fromMealEntity(
  MealEntity(
    code: '3168930010265',
    name: 'Muesli',
    brands: 'Bjorg',
    url: null,
    thumbnailImageUrl: null,
    mainImageUrl: null,
    mealQuantity: '500',
    mealUnit: 'g',
    servingQuantity: 50,
    servingUnit: 'g',
    servingSize: '50 g',
    nutriments: const MealNutrimentsEntity(
      energyKcal100: 380,
      carbohydrates100: 60,
      fat100: 8,
      proteins100: 10,
      sugars100: 15,
      saturatedFat100: 1.5,
      fiber100: 9,
      sodium100: 42.8,
      iron100: 2.1,
      vitaminD100: 5,
    ),
    source: source,
  ),
);

IntakeDBO _intake(String id, MealDBO meal, {double amount = 100}) => IntakeDBO(
  id: id,
  unit: 'g',
  amount: amount,
  type: IntakeTypeDBO.breakfast,
  meal: meal,
  dateTime: DateTime.utc(2026, 8, 20, 8, 15),
);

RecipeDBO _recipe(String id, List<RecipeIngredientDBO> ingredients) {
  final total = ingredients.fold<double>(0, (s, i) => s + i.convertedAmountG);
  return RecipeDBO(
    id: id,
    name: 'Recipe $id',
    description: null,
    ingredients: ingredients,
    totalWeightG: total,
    // Whatever the old build aggregated; the repair recomputes it.
    aggregatedNutrimentsPer100: MealNutrimentsDBO(
      energyKcal100: 0,
      carbohydrates100: 0,
      fat100: 0,
      proteins100: 0,
      sugars100: 0,
      saturatedFat100: 0,
      fiber100: 0,
      sodium100: 0.06,
    ),
    createdAt: DateTime.utc(2026, 7, 1),
    updatedAt: DateTime.utc(2026, 7, 2),
    servingsCount: 4,
    tags: const ['test'],
    imagePath: null,
  );
}

RecipeIngredientDBO _ingredient(MealDBO meal, double grams) =>
    RecipeIngredientDBO(
      snapshotMeal: meal,
      amount: grams,
      unit: 'g',
      convertedAmountG: grams,
    );

/// The row as the JSON exporter writes it — a byte-for-byte fingerprint for
/// "this row was not touched".
String _json(Map<String, dynamic> json) => jsonEncode(json);

/// What `user_intake.json` holds for [intake], decoded the way the importer
/// decodes it: nested objects become plain maps.
Map<String, dynamic> _exported(IntakeDBO intake) =>
    jsonDecode(_json(intake.toJson())) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OffMicronutrientRepair.repairMeal', () {
    test(
      'scales an unstamped Open Food Facts row by the factors #775 added',
      () {
        final repaired = OffMicronutrientRepair.repairMeal(
          _meal(source: MealSourceDBO.off),
        );

        _expectAppUnits(repaired.nutriments);
        expect(
          repaired.dataVersion,
          MealDBO.dataVersionOffMicronutrientsInAppUnits,
        );
        // Everything that is not a micronutrient comes across untouched.
        expect(repaired.code, '3017620422003');
        expect(repaired.name, 'Nutella');
        expect(repaired.brands, 'Ferrero');
        expect(repaired.source, MealSourceDBO.off);
        expect(repaired.servingQuantity, 15);
        expect(repaired.servingSize, '15 g');
        expect(repaired.thumbnailImageUrl, 'https://example.test/thumb.jpg');
      },
    );

    test('leaves a row a build carrying #775 wrote exactly as it is', () {
      final meal = _mealWrittenAfter775();
      expect(meal.dataVersion, MealDBO.currentDataVersion);

      expect(identical(OffMicronutrientRepair.repairMeal(meal), meal), isTrue);
      expect(meal.nutriments.sodium100, 42.8);
      expect(meal.nutriments.vitaminD100, 5);
    });

    test('never touches a row from another source, stamped or not', () {
      for (final source in [
        MealSourceDBO.custom,
        MealSourceDBO.fdc,
        MealSourceDBO.recipe,
        MealSourceDBO.unknown,
      ]) {
        final meal = _meal(source: source);
        expect(
          identical(OffMicronutrientRepair.repairMeal(meal), meal),
          isTrue,
          reason: '$source rows already hold app units',
        );
        expect(meal.dataVersion, isNull);
      }
    });

    test('keeps a null micronutrient null and a declared zero zero', () {
      final repaired = OffMicronutrientRepair.repairMeal(
        _meal(
          source: MealSourceDBO.off,
          nutriments: MealNutrimentsDBO(
            energyKcal100: 100,
            carbohydrates100: null,
            fat100: null,
            proteins100: null,
            sugars100: null,
            saturatedFat100: null,
            fiber100: null,
            sodium100: 0,
            vitaminD100: 0.0,
          ),
        ),
      );

      expect(repaired.nutriments.sodium100, 0);
      expect(repaired.nutriments.vitaminD100, 0);
      expect(repaired.nutriments.iron100, isNull);
      expect(repaired.nutriments.vitaminB12100, isNull);
      expect(repaired.nutriments.energyKcal100, 100);
    });

    test('is a no-op the second time', () {
      final once = OffMicronutrientRepair.repairMeal(
        _meal(source: MealSourceDBO.off),
      );
      final twice = OffMicronutrientRepair.repairMeal(once);

      expect(identical(twice, once), isTrue);
      expect(twice.nutriments.sodium100, closeTo(120, 1e-9));
    });
  });

  group('OffMicronutrientRepair on Hive boxes', () {
    late Box<IntakeDBO> intakeBox;
    late Box<MealDBO> cacheBox;
    late Box<MealDBO> customMealBox;
    late Box<RecipeDBO> recipeBox;

    setUpAll(() {
      Hive.init('.');
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      final tag = DateTime.now().microsecondsSinceEpoch;
      intakeBox = await Hive.openBox<IntakeDBO>('off_repair_intake_$tag');
      cacheBox = await Hive.openBox<MealDBO>('off_repair_cache_$tag');
      customMealBox = await Hive.openBox<MealDBO>('off_repair_custom_$tag');
      recipeBox = await Hive.openBox<RecipeDBO>('off_repair_recipe_$tag');
    });

    tearDown(() async {
      await intakeBox.deleteFromDisk();
      await cacheBox.deleteFromDisk();
      await customMealBox.deleteFromDisk();
      await recipeBox.deleteFromDisk();
    });

    test('repairs only the pre-#775 Open Food Facts intakes in a mixed box, '
        'and a second run changes nothing', () async {
      await intakeBox.addAll([
        _intake('old-off', _meal(source: MealSourceDBO.off)),
        _intake('new-off', _mealWrittenAfter775()),
        _intake('custom', _meal(source: MealSourceDBO.custom)),
        _intake('fdc', _meal(source: MealSourceDBO.fdc)),
        _intake('recipe', _meal(source: MealSourceDBO.recipe)),
        _intake('old-off-2', _meal(source: MealSourceDBO.off), amount: 42),
      ]);
      final before = {
        for (final i in intakeBox.values) i.id: _json(i.toJson()),
      };

      final rewritten = await OffMicronutrientRepair.repairIntakeBox(intakeBox);

      expect(rewritten, 2);
      final byId = {for (final i in intakeBox.values) i.id: i};
      _expectAppUnits(byId['old-off']!.meal.nutriments);
      _expectAppUnits(byId['old-off-2']!.meal.nutriments);
      // The intake's own fields survive the rewrite.
      expect(byId['old-off-2']!.amount, 42);
      expect(byId['old-off-2']!.unit, 'g');
      expect(byId['old-off-2']!.type, IntakeTypeDBO.breakfast);
      expect(byId['old-off-2']!.dateTime, DateTime.utc(2026, 8, 20, 8, 15));
      // Everything else is byte-for-byte what was seeded.
      for (final id in ['new-off', 'custom', 'fdc', 'recipe']) {
        expect(
          _json(byId[id]!.toJson()),
          before[id],
          reason: '$id must be untouched',
        );
      }
      expect(intakeBox.length, 6);

      final after = {for (final i in intakeBox.values) i.id: _json(i.toJson())};
      final secondRun = await OffMicronutrientRepair.repairIntakeBox(intakeBox);

      expect(secondRun, 0);
      expect({
        for (final i in intakeBox.values) i.id: _json(i.toJson()),
      }, after);
    });

    test('a pass that stopped part-way leaves nothing scaled twice', () async {
      await intakeBox.addAll([
        _intake('a', _meal(source: MealSourceDBO.off)),
        _intake('b', _meal(source: MealSourceDBO.off)),
        _intake('c', _meal(source: MealSourceDBO.off)),
      ]);
      // The app was killed after the first row had been written back —
      // each row is repaired and stamped in the same write, so that is the
      // only shape a partial pass can leave behind.
      final firstKey = intakeBox.keys.first;
      await intakeBox.put(
        firstKey,
        OffMicronutrientRepair.repairIntake(intakeBox.get(firstKey)!),
      );
      expect(
        intakeBox.get(firstKey)!.meal.nutriments.sodium100,
        closeTo(120, 1e-9),
      );

      final rewritten = await OffMicronutrientRepair.repairIntakeBox(intakeBox);

      expect(rewritten, 2);
      for (final intake in intakeBox.values) {
        _expectAppUnits(intake.meal.nutriments);
      }
    });

    test(
      'repairs the cached Open Food Facts products a re-scan would read',
      () async {
        await cacheBox.addAll([
          _meal(source: MealSourceDBO.off, detailed: true),
          _meal(
            source: MealSourceDBO.off,
            code: '1',
            name: 'thin',
            detailed: false,
          ),
          _meal(source: MealSourceDBO.fdc, code: '2', name: 'fdc'),
          _mealWrittenAfter775(),
        ]);

        final rewritten = await OffMicronutrientRepair.repairMealBox(cacheBox);

        expect(rewritten, 2);
        final byName = {for (final m in cacheBox.values) m.name: m};
        _expectAppUnits(byName['Nutella']!.nutriments);
        expect(byName['Nutella']!.detailed, isTrue);
        _expectAppUnits(byName['thin']!.nutriments);
        expect(byName['thin']!.detailed, isFalse);
        expect(byName['fdc']!.nutriments.sodium100, 0.12);
        expect(byName['fdc']!.dataVersion, isNull);
        expect(byName['Muesli']!.nutriments.sodium100, 42.8);
        expect(await OffMicronutrientRepair.repairMealBox(cacheBox), 0);
      },
    );

    test('repairs an unstamped Open Food Facts row in the saved-meals box, '
        'and a second run changes nothing', () async {
      // Nothing in the app writes an `off` row here — the edit screen saves
      // a meal for reuse only when its source is `custom` — but the box is
      // typed for any MealDBO and only that screen-level check keeps such a
      // row out, so the pass covers it and this test pins that. Seed the
      // shape such a row would have: the cache row's, in a box whose name
      // says nothing about Open Food Facts.
      await customMealBox.addAll([
        _meal(source: MealSourceDBO.off),
        _mealWrittenAfter775(),
        _meal(source: MealSourceDBO.custom, code: null, name: 'Homemade'),
        _meal(source: MealSourceDBO.fdc, code: '2', name: 'fdc'),
      ]);
      final before = {
        for (final m in customMealBox.values) m.name: _json(m.toJson()),
      };

      final rewritten = await OffMicronutrientRepair.repairMealBox(
        customMealBox,
      );

      expect(rewritten, 1);
      final byName = {for (final m in customMealBox.values) m.name: m};
      _expectAppUnits(byName['Nutella']!.nutriments);
      expect(byName['Nutella']!.source, MealSourceDBO.off);
      expect(
        byName['Nutella']!.dataVersion,
        MealDBO.dataVersionOffMicronutrientsInAppUnits,
      );
      for (final name in ['Muesli', 'Homemade', 'fdc']) {
        expect(
          _json(byName[name]!.toJson()),
          before[name],
          reason: '$name must be untouched',
        );
      }
      expect(customMealBox.length, 4);

      // Picking a saved meal and logging it goes through the entity and
      // back through `fromMealEntity`, which stamps whatever it is given.
      // Logged unrepaired, such a row would have stamped raw grams onto a
      // fresh intake no later pass could tell apart; repaired, it carries
      // the app units through.
      final logged = MealDBO.fromMealEntity(
        MealEntity.fromMealDBO(byName['Nutella']!),
      );
      _expectAppUnits(logged.nutriments);
      expect(logged.dataVersion, MealDBO.currentDataVersion);
      expect(
        identical(OffMicronutrientRepair.repairMeal(logged), logged),
        isTrue,
      );

      // The second run neither returns nor performs a write.
      final after = {
        for (final m in customMealBox.values) m.name: _json(m.toJson()),
      };
      final events = <BoxEvent>[];
      final subscription = customMealBox.watch().listen(events.add);
      addTearDown(subscription.cancel);

      expect(await OffMicronutrientRepair.repairMealBox(customMealBox), 0);
      await pumpEventQueue();

      expect(events, isEmpty);
      expect({
        for (final m in customMealBox.values) m.name: _json(m.toJson()),
      }, after);
    });

    test('repairs Open Food Facts ingredient snapshots and recomputes the '
        'recipe aggregate, leaving recipes without one alone', () async {
      // 100 g of the pre-#775 OFF product (120 mg sodium once repaired) plus
      // 100 g of a custom food declaring 80 mg: 200 mg over 200 g is
      // 100 mg per 100 g.
      final custom = _meal(
        source: MealSourceDBO.custom,
        code: null,
        name: 'Homemade',
        nutriments: MealNutrimentsDBO(
          energyKcal100: 50,
          carbohydrates100: 5,
          fat100: 1,
          proteins100: 2,
          sugars100: 1,
          saturatedFat100: 0,
          fiber100: 1,
          sodium100: 80,
          vitaminD100: 1,
        ),
      );
      await recipeBox.addAll([
        _recipe('mixed', [
          _ingredient(_meal(source: MealSourceDBO.off), 100),
          _ingredient(custom, 100),
        ]),
        _recipe('custom-only', [_ingredient(custom, 150)]),
        _recipe('new-off', [_ingredient(_mealWrittenAfter775(), 100)]),
        // A recipe picked off the builder's recent tab as an ingredient of
        // another recipe is a recipe-sourced snapshot: a blended aggregate
        // no single factor applies to, left as it is (see the class doc).
        _recipe('nested', [
          _ingredient(
            _meal(source: MealSourceDBO.recipe, code: 'mixed', name: 'Mixed'),
            100,
          ),
        ]),
      ]);
      final before = {
        for (final r in recipeBox.values) r.id: _json(r.toJson()),
      };

      final rewritten = await OffMicronutrientRepair.repairRecipeBox(recipeBox);

      expect(rewritten, 1);
      final byId = {for (final r in recipeBox.values) r.id: r};
      final mixed = byId['mixed']!;
      _expectAppUnits(mixed.ingredients.first.snapshotMeal.nutriments);
      expect(mixed.ingredients.first.convertedAmountG, 100);
      expect(mixed.ingredients.last.snapshotMeal.nutriments.sodium100, 80);
      expect(mixed.ingredients.last.snapshotMeal.dataVersion, isNull);
      expect(mixed.aggregatedNutrimentsPer100.sodium100, closeTo(100, 1e-9));
      expect(mixed.aggregatedNutrimentsPer100.vitaminD100, closeTo(3, 1e-9));
      expect(
        mixed.aggregatedNutrimentsPer100.energyKcal100,
        closeTo(150, 1e-9),
      );
      expect(mixed.totalWeightG, 200);
      expect(mixed.createdAt, DateTime.utc(2026, 7, 1));
      expect(mixed.updatedAt, DateTime.utc(2026, 7, 2));
      expect(mixed.servingsCount, 4);
      expect(mixed.tags, ['test']);
      expect(_json(byId['custom-only']!.toJson()), before['custom-only']);
      expect(_json(byId['new-off']!.toJson()), before['new-off']);
      expect(_json(byId['nested']!.toJson()), before['nested']);
      expect(
        byId['nested']!.ingredients.single.snapshotMeal.dataVersion,
        isNull,
      );

      expect(await OffMicronutrientRepair.repairRecipeBox(recipeBox), 0);
    });

    test('a box with nothing to repair is not written to', () async {
      await intakeBox.addAll([
        _intake('new-off', _mealWrittenAfter775()),
        _intake('custom', _meal(source: MealSourceDBO.custom)),
      ]);
      final before = {
        for (final i in intakeBox.values) i.id: _json(i.toJson()),
      };
      // Every put reaches a watcher — a re-put of identical content
      // included — so an empty event list is what "not written to" means.
      final events = <BoxEvent>[];
      final subscription = intakeBox.watch().listen(events.add);
      addTearDown(subscription.cancel);

      expect(await OffMicronutrientRepair.repairIntakeBox(intakeBox), 0);
      await pumpEventQueue();

      expect(events, isEmpty);
      expect({
        for (final i in intakeBox.values) i.id: _json(i.toJson()),
      }, before);

      // The watcher is live: a real put is seen, so the empty list above
      // was not a subscription that never delivered.
      await intakeBox.add(_intake('control', _meal(source: MealSourceDBO.fdc)));
      await pumpEventQueue();
      expect(events.map((e) => (e.value as IntakeDBO).id), ['control']);
    });

    test('ensureOffMicronutrientsRepaired covers all four boxes', () async {
      await intakeBox.add(_intake('old-off', _meal(source: MealSourceDBO.off)));
      await cacheBox.add(_meal(source: MealSourceDBO.off, detailed: true));
      await customMealBox.add(_meal(source: MealSourceDBO.off));
      await recipeBox.add(
        _recipe('r', [_ingredient(_meal(source: MealSourceDBO.off), 50)]),
      );
      final db = FakeHiveDBProvider(
        intakeBox: intakeBox,
        cachedOffMealBox: cacheBox,
        customMealBox: customMealBox,
        recipeBox: recipeBox,
      );

      await ensureOffMicronutrientsRepaired(db);

      _expectAppUnits(intakeBox.values.single.meal.nutriments);
      _expectAppUnits(cacheBox.values.single.nutriments);
      _expectAppUnits(customMealBox.values.single.nutriments);
      _expectAppUnits(
        recipeBox.values.single.ingredients.single.snapshotMeal.nutriments,
      );

      // And again, to prove the second launch is a no-op on every box.
      final after = [
        _json(intakeBox.values.single.toJson()),
        _json(cacheBox.values.single.toJson()),
        _json(customMealBox.values.single.toJson()),
        _json(recipeBox.values.single.toJson()),
      ];
      await ensureOffMicronutrientsRepaired(db);
      expect([
        _json(intakeBox.values.single.toJson()),
        _json(cacheBox.values.single.toJson()),
        _json(customMealBox.values.single.toJson()),
        _json(recipeBox.values.single.toJson()),
      ], after);
    });
  });

  group('OffMicronutrientRepair on imported bundles', () {
    test('a user_intake.json row from a build before #775 is scaled', () {
      // Exactly what the 2.3.0 exporter wrote: no dataVersion key at all.
      final legacy = _exported(
        _intake('old', _meal(source: MealSourceDBO.off)),
      );
      (legacy['meal'] as Map<String, dynamic>).remove('dataVersion');

      final repaired = OffMicronutrientRepair.repairIntake(
        IntakeDBO.fromJson(legacy),
      );

      _expectAppUnits(repaired.meal.nutriments);
      expect(repaired.id, 'old');
    });

    test('a user_intake.json row from a repaired build passes through', () {
      final exported = _exported(_intake('new', _mealWrittenAfter775()));
      expect((exported['meal'] as Map)['dataVersion'], 1);

      final decoded = IntakeDBO.fromJson(exported);
      final repaired = OffMicronutrientRepair.repairIntake(decoded);

      expect(identical(repaired, decoded), isTrue);
      expect(repaired.meal.nutriments.sodium100, 42.8);
    });

    test('a user_intake.csv without the version column is scaled', () {
      final legacyColumns = CsvDataExporter.intakeColumns
          .where((c) => c != 'meal_data_version')
          .toList();
      final csv = CsvDataExporter.intakesToCsv([
        _intake('old', _meal(source: MealSourceDBO.off)),
      ]);
      // Drop the trailing column the old exporter did not have.
      final legacyCsv = csv
          .split('\n')
          .map(
            (line) =>
                line.isEmpty ? line : line.substring(0, line.lastIndexOf(',')),
          )
          .join('\n');
      expect(legacyCsv.split('\n').first, legacyColumns.join(','));

      final parsed = CsvDataExporter.parseIntakesFromCsv(legacyCsv).single;
      expect(parsed.meal.dataVersion, isNull);

      _expectAppUnits(
        OffMicronutrientRepair.repairIntake(parsed).meal.nutriments,
      );
    });

    test('a user_intake.csv from a repaired build round-trips the version', () {
      final csv = CsvDataExporter.intakesToCsv([
        _intake('new', _mealWrittenAfter775()),
      ]);
      expect(csv.split('\n').first, endsWith(',meal_data_version'));

      final parsed = CsvDataExporter.parseIntakesFromCsv(csv).single;

      expect(parsed.meal.dataVersion, 1);
      expect(
        identical(OffMicronutrientRepair.repairIntake(parsed), parsed),
        isTrue,
      );
      expect(parsed.meal.nutriments.sodium100, 42.8);
    });
  });
}
