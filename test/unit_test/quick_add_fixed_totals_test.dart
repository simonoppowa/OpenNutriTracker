import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/csv_data_exporter.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

import '../helpers/hive_test_setup.dart';

// #705: a Quick Add entry without a weight is a fixed total. It is stored
// as before (per 100 g/ml, logged at 100), plus a flag on the meal that
// says so, so the card can hide the synthetic 100 g/ml and refuse to
// rescale it. These tests pin that the flag survives every place the meal
// is stored or carried: the entity, Hive, the JSON backup and the CSV one.

MealEntity _meal({bool fixedTotals = false}) => MealEntity(
  code: 'quick-add-705',
  name: 'Canteen lunch',
  url: null,
  mealQuantity: '100',
  mealUnit: 'gml',
  servingQuantity: null,
  servingUnit: 'gml',
  servingSize: '',
  nutriments: MealNutrimentsEntity(
    energyKcal100: 640,
    carbohydrates100: 70,
    fat100: 22,
    proteins100: 31,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.custom,
  fixedTotals: fixedTotals,
);

IntakeEntity _intake(MealEntity meal, {double amount = 100}) => IntakeEntity(
  id: 'intake-705',
  unit: 'g',
  amount: amount,
  type: IntakeTypeEntity.lunch,
  meal: meal,
  dateTime: DateTime(2026, 11, 9, 12),
);

void main() {
  group('IntakeEntity.hasFixedTotals', () {
    test('a flagged Quick Add at its 100 basis is a fixed total', () {
      final intake = _intake(_meal(fixedTotals: true));
      expect(intake.hasFixedTotals, isTrue);
      expect(intake.totalKcal, 640);
      expect(intake.totalCarbsGram, 70);
      expect(intake.totalFatsGram, 22);
      expect(intake.totalProteinsGram, 31);
    });

    test('an entry stored before #705 keeps its values and its 100 g/ml', () {
      // No flag: indistinguishable from a custom meal logged at 100 g, so
      // it is left exactly as it was rather than guessed at.
      final intake = _intake(_meal());
      expect(intake.meal.fixedTotals, isFalse);
      expect(intake.hasFixedTotals, isFalse);
      expect(intake.totalKcal, 640);
      expect(intake.totalCarbsGram, 70);
      expect(intake.totalFatsGram, 22);
      expect(intake.totalProteinsGram, 31);
    });

    test('a flagged meal logged at another amount is not a fixed total', () {
      // Re-logged from Recents at 250 g/ml: the totals are scaled, so the
      // amount must stay visible next to them.
      final intake = _intake(_meal(fixedTotals: true), amount: 250);
      expect(intake.hasFixedTotals, isFalse);
      expect(intake.totalKcal, 1600);
    });
  });

  group('MealEntity keeps the flag', () {
    test('through the DBO and back', () {
      final back = MealEntity.fromMealDBO(
        IntakeDBO.fromIntakeEntity(_intake(_meal(fixedTotals: true))).meal,
      );
      expect(back.fixedTotals, isTrue);
    });

    test('through withName, withServingLabel and withPortions', () {
      final meal = _meal(fixedTotals: true);
      expect(meal.withName('Renamed').fixedTotals, isTrue);
      expect(meal.withServingLabel('1 plate').fixedTotals, isTrue);
      expect(meal.withPortions(const []).fixedTotals, isTrue);
      expect(meal.withPortionsUnavailable().fixedTotals, isTrue);
    });
  });

  group('JSON backup', () {
    test('a fixed-total Quick Add round-trips', () {
      final dbo = IntakeDBO.fromIntakeEntity(_intake(_meal(fixedTotals: true)));
      final json = jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>;
      expect((json['meal'] as Map)['fixedTotals'], isTrue);

      final back = IntakeEntity.fromIntakeDBO(IntakeDBO.fromJson(json));
      expect(back.hasFixedTotals, isTrue);
      expect(back.totalKcal, 640);
      expect(back.amount, 100);
    });

    test('a backup written before #705 imports as an ordinary entry', () {
      final dbo = IntakeDBO.fromIntakeEntity(_intake(_meal()));
      final json = jsonDecode(jsonEncode(dbo.toJson())) as Map<String, dynamic>;
      (json['meal'] as Map).remove('fixedTotals');

      final back = IntakeEntity.fromIntakeDBO(IntakeDBO.fromJson(json));
      expect(back.meal.fixedTotals, isFalse);
      expect(back.hasFixedTotals, isFalse);
      expect(back.totalKcal, 640);
    });
  });

  group('CSV backup', () {
    test('a fixed-total Quick Add round-trips', () {
      final dbo = IntakeDBO.fromIntakeEntity(_intake(_meal(fixedTotals: true)));
      final csv = CsvDataExporter.intakesToCsv([dbo]);
      expect(csv.split('\n').first.split(',').last, 'meal_fixed_totals');

      final back = IntakeEntity.fromIntakeDBO(
        CsvDataExporter.parseIntakesFromCsv(csv).single,
      );
      expect(back.hasFixedTotals, isTrue);
      expect(back.totalKcal, 640);
    });

    test('an ordinary entry writes an empty cell and reads back unflagged', () {
      final dbo = IntakeDBO.fromIntakeEntity(_intake(_meal()));
      final csv = CsvDataExporter.intakesToCsv([dbo]);
      final row = csv.split('\n')[1];
      expect(row.endsWith(','), isTrue);

      final back = CsvDataExporter.parseIntakesFromCsv(csv).single;
      expect(back.meal.fixedTotals, isNull);
    });

    test('a CSV written before #705 has no column and still parses', () {
      final dbo = IntakeDBO.fromIntakeEntity(_intake(_meal(fixedTotals: true)));
      final lines = CsvDataExporter.intakesToCsv([dbo]).trim().split('\n');
      String dropLastCell(String line) =>
          line.substring(0, line.lastIndexOf(','));
      final old = lines.map(dropLastCell).join('\n');

      final back = CsvDataExporter.parseIntakesFromCsv(old).single;
      expect(back.meal.fixedTotals, isNull);
      expect(back.meal.nutriments.energyKcal100, 640);
    });
  });

  group('Hive', () {
    late Directory dir;

    setUp(() async {
      registerHiveAdaptersOnce();
      dir = await Directory.systemTemp.createTemp('quick_add_705_');
      Hive.init(dir.path);
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('the flag is stored and read back', () async {
      final box = await Hive.openBox<IntakeDBO>('intakes705');
      await box.put(
        'a',
        IntakeDBO.fromIntakeEntity(_intake(_meal(fixedTotals: true))),
      );
      await box.put('b', IntakeDBO.fromIntakeEntity(_intake(_meal())));
      await box.close();

      final reopened = await Hive.openBox<IntakeDBO>('intakes705');
      final a = IntakeEntity.fromIntakeDBO(reopened.get('a')!);
      final b = IntakeEntity.fromIntakeDBO(reopened.get('b')!);
      expect(a.hasFixedTotals, isTrue);
      expect(b.hasFixedTotals, isFalse);
      expect(a.totalKcal, b.totalKcal);
    });
  });
}
