import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  group('TrackedDayDataSource getTrackedDaysInRange test', () {
    late Box<TrackedDayDBO> box;
    late TrackedDayDataSource dataSource;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      Hive.init('.');
      box = await Hive.openBox<TrackedDayDBO>('tracked_day_test');
      dataSource = TrackedDayDataSource(box);
    });

    tearDown(() async {
      await box.clear();
      await Hive.close();
      await Hive.deleteFromDisk();
    });

    test('returns tracked days within range inclusively', () async {
      final day1 = DateTime.utc(2024, 1, 1);
      final day2 = DateTime.utc(2024, 1, 2);
      final day3 = DateTime.utc(2024, 1, 3);
      final day4 = DateTime.utc(2024, 1, 4);
      final day5 = DateTime.utc(2024, 1, 5);

      await dataSource.saveTrackedDay(TrackedDayDBO(
        day: day1,
        calorieGoal: 2000,
        caloriesTracked: 1500,
        carbsGoal: 250,
        carbsTracked: 200,
        fatGoal: 65,
        fatTracked: 50,
        proteinGoal: 150,
        proteinTracked: 120,
      ));

      await dataSource.saveTrackedDay(TrackedDayDBO(
        day: day2,
        calorieGoal: 2000,
        caloriesTracked: 1800,
        carbsGoal: 250,
        carbsTracked: 220,
        fatGoal: 65,
        fatTracked: 60,
        proteinGoal: 150,
        proteinTracked: 140,
      ));

      await dataSource.saveTrackedDay(TrackedDayDBO(
        day: day3,
        calorieGoal: 2000,
        caloriesTracked: 2100,
        carbsGoal: 250,
        carbsTracked: 260,
        fatGoal: 65,
        fatTracked: 70,
        proteinGoal: 150,
        proteinTracked: 160,
      ));

      await dataSource.saveTrackedDay(TrackedDayDBO(
        day: day4,
        calorieGoal: 2000,
        caloriesTracked: 1900,
        carbsGoal: 250,
        carbsTracked: 240,
        fatGoal: 65,
        fatTracked: 62,
        proteinGoal: 150,
        proteinTracked: 145,
      ));

      await dataSource.saveTrackedDay(TrackedDayDBO(
        day: day5,
        calorieGoal: 2000,
        caloriesTracked: 1600,
        carbsGoal: 250,
        carbsTracked: 190,
        fatGoal: 65,
        fatTracked: 55,
        proteinGoal: 150,
        proteinTracked: 130,
      ));

      final result = await dataSource.getTrackedDaysInRange(day2, day4);

      expect(result.length, 3);
      expect(result.map((e) => e.day).toList(), containsAll([day2, day3, day4]));

      final resultDays = result.map((e) => e.day).toList();
      expect(resultDays.contains(day1), false);
      expect(resultDays.contains(day5), false);
    });

    test('includes boundary days in range query', () async {
      final startDay = DateTime.utc(2024, 1, 1);
      final endDay = DateTime.utc(2024, 1, 3);

      await dataSource.saveTrackedDay(TrackedDayDBO(
        day: startDay,
        calorieGoal: 2000,
        caloriesTracked: 1500,
      ));

      await dataSource.saveTrackedDay(TrackedDayDBO(
        day: endDay,
        calorieGoal: 2000,
        caloriesTracked: 1800,
      ));

      final result = await dataSource.getTrackedDaysInRange(startDay, endDay);

      expect(result.length, 2);
      expect(result.map((e) => e.day).toList(), containsAll([startDay, endDay]));
    });

    test('returns empty list when no days in range', () async {
      final day1 = DateTime.utc(2024, 1, 1);

      await dataSource.saveTrackedDay(TrackedDayDBO(
        day: day1,
        calorieGoal: 2000,
        caloriesTracked: 1500,
      ));

      final result = await dataSource.getTrackedDaysInRange(
        DateTime.utc(2024, 1, 20),
        DateTime.utc(2024, 1, 25),
      );

      expect(result.length, 0);
    });
  });

  group('TrackedDayDataSource mutations', () {
    late Box<TrackedDayDBO> box;
    late TrackedDayDataSource ds;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      Hive.init('.');
      box = await Hive.openBox<TrackedDayDBO>(
          'tracked_day_mut_test_${DateTime.now().microsecondsSinceEpoch}');
      ds = TrackedDayDataSource(box);
    });

    tearDown(() async {
      await box.deleteFromDisk();
    });

    final day = DateTime.utc(2024, 6, 15);
    TrackedDayDBO seed() => TrackedDayDBO(
          day: day,
          calorieGoal: 2000,
          caloriesTracked: 0,
          carbsGoal: 250,
          carbsTracked: 0,
          fatGoal: 65,
          fatTracked: 0,
          proteinGoal: 150,
          proteinTracked: 0,
        );

    test('hasTrackedDay reports false when day is missing, true after save',
        () async {
      expect(await ds.hasTrackedDay(day), isFalse);
      await ds.saveTrackedDay(seed());
      expect(await ds.hasTrackedDay(day), isTrue);
    });

    test('addDayCaloriesTracked accumulates additively', () async {
      await ds.saveTrackedDay(seed());
      await ds.addDayCaloriesTracked(day, 500);
      await ds.addDayCaloriesTracked(day, 250);

      final result = await ds.getTrackedDay(day);
      expect(result!.caloriesTracked, equals(750));
    });

    test('decreaseDayCaloriesTracked subtracts', () async {
      await ds.saveTrackedDay(seed());
      await ds.addDayCaloriesTracked(day, 500);
      await ds.decreaseDayCaloriesTracked(day, 200);

      final result = await ds.getTrackedDay(day);
      expect(result!.caloriesTracked, equals(300));
    });

    test('increase / reduceDayCalorieGoal adjust the goal', () async {
      await ds.saveTrackedDay(seed());
      await ds.increaseDayCalorieGoal(day, 100);
      var result = await ds.getTrackedDay(day);
      expect(result!.calorieGoal, equals(2100));

      await ds.reduceDayCalorieGoal(day, 50);
      result = await ds.getTrackedDay(day);
      expect(result!.calorieGoal, equals(2050));
    });

    test('updateDayMacroGoals updates only the named macros', () async {
      await ds.saveTrackedDay(seed());
      await ds.updateDayMacroGoals(day, carbsGoal: 300, proteinGoal: 200);

      final result = await ds.getTrackedDay(day);
      expect(result!.carbsGoal, equals(300));
      expect(result.fatGoal, equals(65), reason: 'fat goal not touched');
      expect(result.proteinGoal, equals(200));
    });

    test('addDayMacroTracked accumulates and removeDayMacroTracked subtracts',
        () async {
      await ds.saveTrackedDay(seed());

      await ds.addDayMacroTracked(day,
          carbsAmount: 30, fatAmount: 10, proteinAmount: 20);
      await ds.addDayMacroTracked(day, carbsAmount: 20);
      await ds.removeDayMacroTracked(day, fatAmount: 4);

      final result = await ds.getTrackedDay(day);
      expect(result!.carbsTracked, equals(50));
      expect(result.fatTracked, equals(6));
      expect(result.proteinTracked, equals(20));
    });

    test('reconcileCaloriesAndMacrosTracked sets the totals exactly',
        () async {
      await ds.saveTrackedDay(seed());
      await ds.addDayCaloriesTracked(day, 999);
      await ds.addDayMacroTracked(day,
          carbsAmount: 999, fatAmount: 999, proteinAmount: 999);

      await ds.reconcileCaloriesAndMacrosTracked(day, 1500, 200, 50, 100);

      final result = await ds.getTrackedDay(day);
      expect(result!.caloriesTracked, equals(1500));
      expect(result.carbsTracked, equals(200));
      expect(result.fatTracked, equals(50));
      expect(result.proteinTracked, equals(100));
    });

    test('all mutations are no-ops when the day has no tracked record',
        () async {
      await ds.addDayCaloriesTracked(day, 100);
      await ds.decreaseDayCaloriesTracked(day, 50);
      await ds.increaseDayCalorieGoal(day, 10);
      await ds.updateDayMacroGoals(day, carbsGoal: 1);
      await ds.addDayMacroTracked(day, carbsAmount: 5);
      await ds.removeDayMacroTracked(day, carbsAmount: 1);
      await ds.reconcileCaloriesAndMacrosTracked(day, 1, 1, 1, 1);

      expect(await ds.getTrackedDay(day), isNull);
      expect(await ds.hasTrackedDay(day), isFalse);
    });

    test('saveAllTrackedDays inserts every entry, keyed by day', () async {
      await ds.saveAllTrackedDays([
        TrackedDayDBO(
          day: DateTime.utc(2024, 6, 1),
          calorieGoal: 2000,
          caloriesTracked: 1000,
        ),
        TrackedDayDBO(
          day: DateTime.utc(2024, 6, 2),
          calorieGoal: 2000,
          caloriesTracked: 1100,
        ),
      ]);

      expect((await ds.getAllTrackedDays()).length, equals(2));
      expect(
          (await ds.getTrackedDay(DateTime.utc(2024, 6, 1)))!.caloriesTracked,
          equals(1000));
    });

    test('saveTrackedDay overwrites prior entry for the same day', () async {
      await ds.saveTrackedDay(seed());
      await ds.saveTrackedDay(TrackedDayDBO(
        day: day,
        calorieGoal: 2500,
        caloriesTracked: 800,
      ));

      final result = await ds.getTrackedDay(day);
      expect(result!.calorieGoal, equals(2500));
      expect(result.caloriesTracked, equals(800));
      expect((await ds.getAllTrackedDays()).length, equals(1));
    });

    // #173 (+follow-up): the dialog wires every nutrient goal through
    // `updateDayNutrientGoals`. These tests pin the persistence
    // contract — that each named field lands on the column it should,
    // and that omitted fields stay untouched.
    test(
        'updateDayNutrientGoals persists every nutrient goal independently',
        () async {
      await ds.saveTrackedDay(seed());
      await ds.updateDayNutrientGoals(
        day,
        fibreGoal: 35,
        satFatGoal: 18,
        sugarsGoal: 40,
        sodiumGoal: 1500,
        calciumGoal: 1200,
        ironGoal: 14,
        potassiumGoal: 4700,
        vitaminDGoal: 20,
        vitaminB12Goal: 5,
        magnesiumGoal: 420,
      );

      final result = await ds.getTrackedDay(day);
      expect(result, isNotNull);
      expect(result!.fibreGoal, equals(35));
      expect(result.satFatGoal, equals(18));
      expect(result.sugarsGoal, equals(40));
      expect(result.sodiumGoal, equals(1500));
      expect(result.calciumGoal, equals(1200));
      expect(result.ironGoal, equals(14));
      expect(result.potassiumGoal, equals(4700));
      expect(result.vitaminDGoal, equals(20));
      expect(result.vitaminB12Goal, equals(5));
      expect(result.magnesiumGoal, equals(420));
    });

    test('updateDayNutrientGoals leaves omitted fields untouched', () async {
      await ds.saveTrackedDay(seed());
      // First pass sets every column.
      await ds.updateDayNutrientGoals(
        day,
        fibreGoal: 30,
        sodiumGoal: 2000,
        ironGoal: 8,
      );
      // Second pass only updates fibre — sodium and iron must stay.
      await ds.updateDayNutrientGoals(day, fibreGoal: 40);

      final result = await ds.getTrackedDay(day);
      expect(result!.fibreGoal, equals(40), reason: 'fibre updated');
      expect(result.sodiumGoal, equals(2000), reason: 'sodium preserved');
      expect(result.ironGoal, equals(8), reason: 'iron preserved');
      // Untouched columns stay null.
      expect(result.calciumGoal, isNull);
      expect(result.potassiumGoal, isNull);
      expect(result.magnesiumGoal, isNull);
      expect(result.vitaminDGoal, isNull);
      expect(result.vitaminB12Goal, isNull);
    });

    test(
        'updateDayNutrientGoals is a no-op when the day has no tracked record',
        () async {
      await ds.updateDayNutrientGoals(
        day,
        fibreGoal: 30,
        sodiumGoal: 1500,
        ironGoal: 14,
      );

      expect(await ds.getTrackedDay(day), isNull);
    });
  });
}
