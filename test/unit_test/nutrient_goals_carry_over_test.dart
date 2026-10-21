import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/nutrient_panel_rows.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

void main() {
  const boxName = 'nutrient_goals_carry_over_test';
  late Box<TrackedDayDBO> box;
  late TrackedDayDataSource dataSource;
  late TrackedDayRepository repository;
  final yesterday = DateTime(2026, 10, 18);
  final today = DateTime(2026, 10, 19);
  final tomorrow = DateTime(2026, 10, 20);

  Future<void> addDay(DateTime day) =>
      repository.addNewTrackedDay(day, 2000, 250, 70, 100);

  Future<TrackedDayEntity> entity(DateTime day) async =>
      (await repository.getTrackedDay(day))!;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    Hive.init('.');
    box = await Hive.openBox<TrackedDayDBO>(boxName);
    dataSource = TrackedDayDataSource(FakeHiveDBProvider(trackedDayBox: box));
    repository = TrackedDayRepository(dataSource);
  });

  tearDown(() => Hive.deleteFromDisk());

  group('saving goals', () {
    test(
      'applies to the day and every later day, not to earlier ones',
      () async {
        await addDay(yesterday);
        await addDay(today);
        await addDay(tomorrow);

        await repository.setNutrientGoalsFrom(
          today,
          fibreGoal: 35,
          extraGoals: {NutrientPanelKeys.zinc: 12},
        );

        for (final day in [today, tomorrow]) {
          final d = await entity(day);
          expect(d.fibreGoal, 35);
          expect(d.extraNutrientGoals, {NutrientPanelKeys.zinc: 12.0});
        }
        final before = await entity(yesterday);
        expect(before.fibreGoal, isNull);
        expect(before.extraNutrientGoals, isEmpty);
      },
    );

    test('replaces every goal, so a reset clears all of them', () async {
      await addDay(today);
      await repository.setNutrientGoalsFrom(
        today,
        fibreGoal: 35,
        satFatGoal: 15,
        sugarsGoal: 40,
        sodiumGoal: 2000,
        calciumGoal: 1200,
        ironGoal: 12,
        potassiumGoal: 4000,
        vitaminDGoal: 25,
        vitaminB12Goal: 5,
        magnesiumGoal: 380,
        extraGoals: {NutrientPanelKeys.zinc: 12},
      );

      await repository.setNutrientGoalsFrom(today);

      final d = await entity(today);
      expect([
        d.fibreGoal,
        d.satFatGoal,
        d.sugarsGoal,
        d.sodiumGoal,
        d.calciumGoal,
        d.ironGoal,
        d.potassiumGoal,
        d.vitaminDGoal,
        d.vitaminB12Goal,
        d.magnesiumGoal,
      ], everyElement(isNull));
      expect(d.extraNutrientGoals, isEmpty);
      expect(
        NutrientPanelRow.ownGoal(NutrientPanelKeys.fiber, d),
        isNull,
        reason: 'the panel falls back to the reference value',
      );
    });

    test('keeps the calorie and macro goals of each day', () async {
      await addDay(today);

      await repository.setNutrientGoalsFrom(today, fibreGoal: 35);

      final d = await entity(today);
      expect(d.calorieGoal, 2000);
      expect(d.carbsGoal, 250);
    });

    test('creates no row for a day without one', () async {
      await repository.setNutrientGoalsFrom(today, fibreGoal: 35);

      expect(await repository.getTrackedDay(today), isNull);
    });
  });

  group('a new day', () {
    test('takes over the goals of the latest earlier day', () async {
      await addDay(yesterday);
      await addDay(today);
      await repository.setNutrientGoalsFrom(
        yesterday,
        ironGoal: 15,
        extraGoals: {NutrientPanelKeys.vitaminC: 120},
      );
      await repository.setNutrientGoalsFrom(today, ironGoal: 18);

      await addDay(tomorrow);

      final d = await entity(tomorrow);
      expect(d.ironGoal, 18);
      expect(d.extraNutrientGoals, isEmpty);
      expect(NutrientPanelRow.ownGoal(NutrientPanelKeys.iron, d), 18);
      expect(d.caloriesTracked, 0);
    });

    test('logged after a gap still takes over the goals', () async {
      await addDay(yesterday);
      await repository.setNutrientGoalsFrom(yesterday, fibreGoal: 35);
      final nextWeek = DateTime(2026, 10, 25);

      await addDay(nextWeek);

      expect((await entity(nextWeek)).fibreGoal, 35);
    });

    test('before any day with goals has none', () async {
      await addDay(today);
      await repository.setNutrientGoalsFrom(today, fibreGoal: 35);

      await addDay(yesterday);

      expect((await entity(yesterday)).fibreGoal, isNull);
    });

    test('keeps the goals in its backup JSON', () async {
      await addDay(today);
      await repository.setNutrientGoalsFrom(
        today,
        fibreGoal: 35,
        extraGoals: {NutrientPanelKeys.zinc: 12},
      );
      await addDay(tomorrow);

      final json = (await dataSource.getTrackedDay(tomorrow))!.toJson();
      final restored = TrackedDayDBO.fromJson(json);

      expect(restored.fibreGoal, 35);
      expect(restored.extraNutrientGoals, {NutrientPanelKeys.zinc: 12.0});
    });
  });

  group('the goals that apply to a day', () {
    test('come from the latest day up to it', () async {
      await addDay(yesterday);
      await repository.setNutrientGoalsFrom(yesterday, fibreGoal: 35);

      final goals = await repository.getNutrientGoalsDay(today);

      expect(goals!.fibreGoal, 35);
      expect(await repository.getTrackedDay(today), isNull);
    });

    test('are null without any earlier day', () async {
      await addDay(tomorrow);

      expect(await repository.getNutrientGoalsDay(today), isNull);
    });
  });

  test('goals stored on disk survive reopening the box', () async {
    await addDay(today);
    await repository.setNutrientGoalsFrom(
      today,
      extraGoals: {NutrientPanelKeys.zinc: 12, NutrientPanelKeys.vitaminC: 100},
    );
    await box.close();
    box = await Hive.openBox<TrackedDayDBO>(boxName);
    repository = TrackedDayRepository(
      TrackedDayDataSource(FakeHiveDBProvider(trackedDayBox: box)),
    );

    expect((await entity(today)).extraNutrientGoals, {
      NutrientPanelKeys.zinc: 12.0,
      NutrientPanelKeys.vitaminC: 100.0,
    });
  });
}
