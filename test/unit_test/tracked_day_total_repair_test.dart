import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/utils/tracked_day_total_repair.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

MealDBO _meal({
  required double? kcal,
  required double? carbs,
  required double? fat,
  required double? protein,
}) => MealDBO(
  code: null,
  name: 'Custom',
  brands: null,
  thumbnailImageUrl: null,
  mainImageUrl: null,
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: 100,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsDBO(
    energyKcal100: kcal,
    carbohydrates100: carbs,
    fat100: fat,
    proteins100: protein,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceDBO.custom,
);

/// What a custom meal saved with a base quantity of 0 stored (#1254).
MealDBO _nanMeal() => _meal(
  kcal: double.nan,
  carbs: double.nan,
  fat: double.nan,
  protein: double.nan,
);

/// 200 kcal, 20 g carbs, 10 g fat and 5 g protein per 100 g.
MealDBO _okMeal() => _meal(kcal: 200, carbs: 20, fat: 10, protein: 5);

IntakeDBO _intake(String id, MealDBO meal, DateTime at, {double amount = 50}) =>
    IntakeDBO(
      id: id,
      unit: 'g',
      amount: amount,
      type: IntakeTypeDBO.breakfast,
      meal: meal,
      dateTime: at,
    );

TrackedDayDBO _day(
  DateTime day, {
  required double kcal,
  double? carbs,
  double? fat,
  double? protein,
}) => TrackedDayDBO(
  day: day,
  calorieGoal: 2000,
  caloriesTracked: kcal,
  carbsGoal: 250,
  carbsTracked: carbs,
  fatGoal: 70,
  fatTracked: fat,
  proteinGoal: 100,
  proteinTracked: protein,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('hasNonFiniteTrackedTotal', () {
    final day = DateTime(2026, 9, 24);

    test('is false for finite and unset totals', () {
      expect(hasNonFiniteTrackedTotal(_day(day, kcal: 0)), isFalse);
      expect(
        hasNonFiniteTrackedTotal(
          _day(day, kcal: 1500, carbs: 100, fat: 50, protein: 80),
        ),
        isFalse,
      );
    });

    test('is true when any one total is NaN or infinite', () {
      expect(hasNonFiniteTrackedTotal(_day(day, kcal: double.nan)), isTrue);
      expect(
        hasNonFiniteTrackedTotal(_day(day, kcal: 0, carbs: double.nan)),
        isTrue,
      );
      expect(
        hasNonFiniteTrackedTotal(_day(day, kcal: 0, fat: double.infinity)),
        isTrue,
      );
      expect(
        hasNonFiniteTrackedTotal(
          _day(day, kcal: 0, protein: double.negativeInfinity),
        ),
        isTrue,
      );
    });
  });

  group('ensureTrackedDayTotalsFinite (#1254)', () {
    late Box<TrackedDayDBO> trackedDayBox;
    late Box<IntakeDBO> intakeBox;
    late Box<ConfigDBO> configBox;
    late FakeHiveDBProvider db;

    final broken = DateTime(2026, 9, 24);
    final nextDay = DateTime(2026, 9, 25);

    setUpAll(() {
      Hive.init('.');
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      final tag = DateTime.now().microsecondsSinceEpoch;
      trackedDayBox = await Hive.openBox<TrackedDayDBO>('nan_repair_day_$tag');
      intakeBox = await Hive.openBox<IntakeDBO>('nan_repair_intake_$tag');
      configBox = await Hive.openBox<ConfigDBO>('nan_repair_config_$tag');
      db = FakeHiveDBProvider(
        trackedDayBox: trackedDayBox,
        intakeBox: intakeBox,
        configBox: configBox,
      );
    });

    tearDown(() async {
      await trackedDayBox.deleteFromDisk();
      await intakeBox.deleteFromDisk();
      await configBox.deleteFromDisk();
    });

    Future<int> repair() =>
        ensureTrackedDayTotalsFinite(db, ConfigDataSource(db));

    test('rebuilds a NaN day from its intakes, the NaN entry counting as 0, '
        'and a second run changes nothing', () async {
      await intakeBox.addAll([
        _intake('nan', _nanMeal(), DateTime(2026, 9, 24, 8)),
        _intake('ok', _okMeal(), DateTime(2026, 9, 24, 13)),
      ]);
      await trackedDayBox.put(
        'broken',
        _day(
          broken,
          kcal: double.nan,
          carbs: double.nan,
          fat: double.nan,
          protein: double.nan,
        ),
      );

      expect(await repair(), 1);

      final day = trackedDayBox.get('broken')!;
      // 50 g of the 200 kcal / 20 / 10 / 5 per 100 g meal.
      expect(day.caloriesTracked, 100);
      expect(day.carbsTracked, 10);
      expect(day.fatTracked, 5);
      expect(day.proteinTracked, 2.5);
      // Goals are not touched.
      expect(day.calorieGoal, 2000);
      expect(day.carbsGoal, 250);

      expect(await repair(), 0);
      expect(trackedDayBox.get('broken')!.caloriesTracked, 100);
    });

    test('rebuilds every total when only one of them is broken', () async {
      await intakeBox.add(_intake('ok', _okMeal(), DateTime(2026, 9, 24, 13)));
      await trackedDayBox.put(
        'broken',
        _day(broken, kcal: 100, carbs: 10, fat: double.infinity, protein: 2.5),
      );

      expect(await repair(), 1);

      final day = trackedDayBox.get('broken')!;
      expect(day.caloriesTracked, 100);
      expect(day.carbsTracked, 10);
      expect(day.fatTracked, 5);
      expect(day.proteinTracked, 2.5);
    });

    test('counts only the intakes logged on that day', () async {
      await intakeBox.addAll([
        _intake('same-day', _okMeal(), DateTime(2026, 9, 24, 13)),
        _intake('next-day', _okMeal(), DateTime(2026, 9, 25, 13)),
      ]);
      await trackedDayBox.put('broken', _day(broken, kcal: double.nan));

      await repair();

      expect(trackedDayBox.get('broken')!.caloriesTracked, 100);
    });

    test('follows the configured day-start boundary', () async {
      // With the day starting at 04:00, an entry at 02:00 on the 25th
      // belongs to the 24th — as the diary lists it.
      await configBox.put(
        'ConfigKey',
        ConfigDBO(false, false, false, AppThemeDBO.system)
          ..dayStartOffsetHours = 4,
      );
      await intakeBox.addAll([
        _intake('after-midnight', _okMeal(), DateTime(2026, 9, 25, 2)),
        _intake('next-day', _okMeal(), DateTime(2026, 9, 25, 13)),
      ]);
      await trackedDayBox.put('broken', _day(broken, kcal: double.nan));

      await repair();

      expect(trackedDayBox.get('broken')!.caloriesTracked, 100);
    });

    test('leaves finite days alone, even when they disagree with their '
        'intakes', () async {
      await intakeBox.add(_intake('ok', _okMeal(), DateTime(2026, 9, 25, 13)));
      await trackedDayBox.put(
        'fine',
        _day(nextDay, kcal: 1234, carbs: 1, fat: 2, protein: 3),
      );

      expect(await repair(), 0);

      final day = trackedDayBox.get('fine')!;
      expect(day.caloriesTracked, 1234);
      expect(day.carbsTracked, 1);
      expect(day.fatTracked, 2);
      expect(day.proteinTracked, 3);
    });

    test('a broken day with no intakes left is rebuilt to zero', () async {
      await trackedDayBox.put(
        'broken',
        _day(broken, kcal: double.nan, carbs: double.nan),
      );

      expect(await repair(), 1);

      final day = trackedDayBox.get('broken')!;
      expect(day.caloriesTracked, 0);
      expect(day.carbsTracked, 0);
      expect(day.fatTracked, 0);
      expect(day.proteinTracked, 0);
    });
  });
}
