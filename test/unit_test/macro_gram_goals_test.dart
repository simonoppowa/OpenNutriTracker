import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/log_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_boundary_usecase.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/features/settings/domain/goal_settings_backup.dart';

import '../fixture/physical_activity_entity_fixtures.dart';
import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

class _FakeKcalGoal extends Fake implements GetKcalGoalUsecase {
  @override
  Future<double> getKcalGoal({
    dynamic userEntity,
    double? totalKcalActivitiesParam,
    double? kcalUserAdjustment,
  }) async => 2000;
}

/// Absolute macro goals in grams (#642).
void main() {
  group('MacroGramGoals.effective', () {
    MacroGrams? effective({
      bool? inGrams = true,
      double? carbs = 20,
      double? protein = 120,
      double? fat = 140,
    }) => MacroGramGoals.effective(
      inGrams: inGrams,
      carbs: carbs,
      protein: protein,
      fat: fat,
    );

    test('valid grams with gram mode on are in effect', () {
      expect(effective(), (carbs: 20.0, protein: 120.0, fat: 140.0));
    });

    test('gram mode off or never set means the split applies', () {
      expect(effective(inGrams: false), isNull);
      expect(effective(inGrams: null), isNull);
    });

    test('a missing, negative, too large or non-finite value falls back to '
        'the split', () {
      expect(effective(carbs: null), isNull);
      expect(effective(protein: -1), isNull);
      expect(effective(fat: MacroGramGoals.maxGrams + 1), isNull);
      expect(effective(carbs: double.nan), isNull);
      expect(effective(protein: double.infinity), isNull);
    });

    test('0 g for one macro is allowed, all three at 0 g is not', () {
      expect(effective(carbs: 0)?.carbs, 0);
      expect(effective(carbs: 0, protein: 0, fat: 0), isNull);
    });

    test('the bounds themselves are valid', () {
      expect(
        effective(carbs: MacroGramGoals.minGrams, fat: MacroGramGoals.maxGrams),
        isNotNull,
      );
    });
  });

  test('kcalOf uses 4 / 4 / 9 kcal per gram', () {
    expect(MacroGramGoals.kcalOf((carbs: 20, protein: 120, fat: 140)), 1820);
  });

  test('fromSplit starts the gram fields at the split of the goal, in whole '
      'grams', () {
    expect(
      MacroGramGoals.fromSplit(
        2000,
        carbsPct: 0.6,
        proteinPct: 0.15,
        fatPct: 0.25,
      ),
      (carbs: 300.0, protein: 75.0, fat: 56.0),
    );
    // A goal so large the split exceeds the field's maximum is clamped,
    // and a non-finite goal gives 0 instead of NaN.
    expect(MacroGramGoals.fromSplit(10000, carbsPct: 0.9).carbs, 1000);
    expect(MacroGramGoals.fromSplit(double.nan).carbs, 0);
  });

  test('an activity adds the default split to the macro goals, and nothing '
      'while gram goals are in effect', () {
    expect(MacroGramGoals.activityShare(400, gramGoals: false), (
      carbs: 60.0,
      protein: 15.0,
      fat: 400 * 0.25 / 9,
    ));
    expect(MacroGramGoals.activityShare(400, gramGoals: true), (
      carbs: 0.0,
      protein: 0.0,
      fat: 0.0,
    ));
  });

  group('stored per profile', () {
    late Box<ConfigDBO> appBox;
    late Box<ConfigDBO> profileBox;
    late ConfigDataSource config;
    late GetMacroGoalUsecase macroGoal;

    setUpAll(() {
      Hive.init('.');
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      final tag = DateTime.now().microsecondsSinceEpoch;
      appBox = await Hive.openBox<ConfigDBO>('gram_goals_app_$tag');
      profileBox = await Hive.openBox<ConfigDBO>('gram_goals_profile_$tag');
      config = ConfigDataSource(
        FakeHiveDBProvider(appConfigBox: appBox, configBox: profileBox),
      );
      await config.initializeConfig();
      macroGoal = GetMacroGoalUsecase(ConfigRepository(config));
    });

    tearDown(() async {
      await appBox.deleteFromDisk();
      await profileBox.deleteFromDisk();
    });

    test('gram goals do not depend on the calorie goal', () async {
      await config.setConfigMacroGoalGrams(20, 120, 140);

      for (final kcal in [1200.0, 2000.0, 3500.0]) {
        expect(await macroGoal.getCarbsGoal(kcal), 20);
        expect(await macroGoal.getProteinsGoal(kcal), 120);
        expect(await macroGoal.getFatsGoal(kcal), 140);
      }
      expect(await macroGoal.getActivityMacroShare(500), (
        carbs: 0.0,
        protein: 0.0,
        fat: 0.0,
      ));
    });

    test('switching back to percentages restores the split and keeps the '
        'grams for the next switch', () async {
      await config.setConfigCarbGoalPct(0.5);
      await config.setConfigProteinGoalPct(0.3);
      await config.setConfigFatGoalPct(0.2);
      await config.setConfigMacroGoalGrams(20, 120, 140);

      await config.setConfigMacroGoalsInGrams(false);

      expect(await macroGoal.getCarbsGoal(2000), 250);
      expect(await macroGoal.getProteinsGoal(2000), 150);
      expect(await macroGoal.getFatsGoal(2000), 2000 * 0.2 / 9);
      expect((await macroGoal.getActivityMacroShare(400)).carbs, 60);
      final stored = await config.getConfig();
      expect(stored.userCarbGoalGrams, 20);
      expect(stored.userProteinGoalGrams, 120);
      expect(stored.userFatGoalGrams, 140);

      await config.setConfigMacroGoalsInGrams(true);
      expect(await macroGoal.getCarbsGoal(2000), 20);
    });

    test('a corrupt stored gram goal falls back to the split', () async {
      await config.setConfigMacroGoalGrams(double.nan, 120, 140);

      expect(await macroGoal.getCarbsGoal(2000), 300);
      expect(await macroGoal.getProteinsGoal(2000), 75);
      expect((await macroGoal.getActivityMacroShare(400)).carbs, 60);
    });

    test('a profile reset clears the gram goals with the other personal '
        'goals', () async {
      await config.setConfigMacroGoalGrams(20, 120, 140);

      await profileBox.clear();

      final stored = await config.getConfig();
      expect(stored.userMacroGoalsInGrams, isNull);
      expect(stored.userCarbGoalGrams, isNull);
      expect(await macroGoal.getCarbsGoal(2000), 300);
    });

    test('the per-meal kcal split is unchanged by gram goals', () async {
      final before = ConfigEntity.fromConfigDBO(
        await config.getConfig(),
      ).targetKcalForMeal(ConfigEntity.mealKeyLunch, 2000);
      await config.setConfigMacroGoalGrams(20, 120, 140);

      final entity = ConfigEntity.fromConfigDBO(await config.getConfig());
      expect(entity.macroGramGoals, isNotNull);
      expect(entity.targetKcalForMeal(ConfigEntity.mealKeyLunch, 2000), before);
    });
  });

  group('activities and the day boundary', () {
    late Box<ConfigDBO> configBox;
    late Box<IntakeDBO> intakeBox;
    late Box<TrackedDayDBO> trackedDayBox;
    late Box<UserActivityDBO> activityBox;
    late FakeHiveDBProvider db;
    late ConfigDataSource config;
    late LogUserActivityUsecase logActivity;

    setUpAll(() {
      Hive.init('.');
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      final tag = DateTime.now().microsecondsSinceEpoch;
      configBox = await Hive.openBox<ConfigDBO>('gram_day_config_$tag');
      intakeBox = await Hive.openBox<IntakeDBO>('gram_day_intake_$tag');
      trackedDayBox = await Hive.openBox<TrackedDayDBO>('gram_day_day_$tag');
      activityBox = await Hive.openBox<UserActivityDBO>('gram_day_act_$tag');
      db = FakeHiveDBProvider(
        configBox: configBox,
        intakeBox: intakeBox,
        trackedDayBox: trackedDayBox,
        userActivityBox: activityBox,
      );
      config = ConfigDataSource(db);
      await config.initializeConfig();
      logActivity = LogUserActivityUsecase(
        AddUserActivityUsecase(
          UserActivityRepository(UserActivityDataSource(db)),
        ),
        AddTrackedDayUsecase(TrackedDayRepository(TrackedDayDataSource(db))),
        _FakeKcalGoal(),
        GetMacroGoalUsecase(ConfigRepository(config)),
      );
    });

    tearDown(() async {
      await configBox.deleteFromDisk();
      await intakeBox.deleteFromDisk();
      await trackedDayBox.deleteFromDisk();
      await activityBox.deleteFromDisk();
    });

    UserActivityEntity walkAt(DateTime at) => UserActivityEntity(
      'walk-${at.microsecondsSinceEpoch}',
      30,
      400,
      at,
      PhysicalActivityFixtures.moderateBicycling,
    );

    TrackedDayDBO? row(DateTime day) =>
        trackedDayBox.get(
          DateTime.utc(day.year, day.month, day.day).toString(),
        ) ??
        trackedDayBox.values
            .where(
              (r) =>
                  r.day.year == day.year &&
                  r.day.month == day.month &&
                  r.day.day == day.day,
            )
            .firstOrNull;

    test('logging an activity raises the calorie goal but not gram macro '
        'goals', () async {
      await config.setConfigMacroGoalGrams(20, 120, 140);
      final at = DateTime(2026, 10, 5, 9);

      await logActivity.logActivity(walkAt(at), day: at);

      final day = row(at)!;
      expect(day.calorieGoal, 2400);
      expect(day.carbsGoal, 20);
      expect(day.proteinGoal, 120);
      expect(day.fatGoal, 140);
    });

    test('with the split, an activity still raises the macro goals', () async {
      final at = DateTime(2026, 10, 5, 9);

      await logActivity.logActivity(walkAt(at), day: at);

      expect(row(at)!.carbsGoal, 300 + 60);
    });

    test('moving the day boundary moves an activity\'s calories but leaves '
        'gram macro goals alone', () async {
      await config.setConfigMacroGoalGrams(20, 120, 140);
      // Logged at 02:00, before a 04:00 boundary would file it under the
      // day before.
      final at = DateTime(2026, 10, 5, 2);
      await logActivity.logActivity(walkAt(at), day: at);

      await SetDayBoundaryUsecase(db, config).setDayBoundary(4, 0);

      final moved = row(DateTime(2026, 10, 4))!;
      final left = row(at)!;
      expect(moved.calorieGoal, 2400);
      expect(left.calorieGoal, 2000);
      for (final r in [moved, left]) {
        expect(r.carbsGoal, 20);
        expect(r.proteinGoal, 120);
        expect(r.fatGoal, 140);
      }
    });
  });

  group('goal_settings.json', () {
    Map<String, dynamic> json([Map<String, dynamic> extra = const {}]) => {
      'version': 1,
      'macroGoalsInGrams': true,
      'carbGoalGrams': 20.0,
      'proteinGoalGrams': 120.0,
      'fatGoalGrams': 140.0,
      ...extra,
    };

    test('gram goals survive a round trip', () {
      final config = ConfigDBO.empty()
        ..userMacroGoalsInGrams = true
        ..userCarbGoalGrams = 20
        ..userProteinGoalGrams = 120
        ..userFatGoalGrams = 140;

      final exported = GoalSettingsBackup.fromConfigDBO(config).toJson();
      final restored = GoalSettingsBackup.fromJson(exported)!;

      expect(exported, containsPair('macroGoalsInGrams', true));
      expect(restored.macroGoalsInGrams, isTrue);
      expect(restored.carbGoalGrams, 20);
      expect(restored.proteinGoalGrams, 120);
      expect(restored.fatGoalGrams, 140);
    });

    test('grams kept while the split is in use travel without gram mode', () {
      final config = ConfigDBO.empty()
        ..userMacroGoalsInGrams = false
        ..userCarbGoalGrams = 20
        ..userProteinGoalGrams = 120
        ..userFatGoalGrams = 140;

      final exported = GoalSettingsBackup.fromConfigDBO(config).toJson();

      expect(exported['macroGoalsInGrams'], isNull);
      expect(exported['carbGoalGrams'], 20);
      expect(GoalSettingsBackup.fromJson(exported)!.carbGoalGrams, 20);
    });

    test('a corrupt stored gram goal is exported as null, so the backup '
        'stays restorable', () {
      final config = ConfigDBO.empty()
        ..userMacroGoalsInGrams = true
        ..userCarbGoalGrams = double.nan
        ..userProteinGoalGrams = 120
        ..userFatGoalGrams = 140;

      final exported = GoalSettingsBackup.fromConfigDBO(config).toJson();

      expect(exported['macroGoalsInGrams'], isNull);
      expect(exported['carbGoalGrams'], isNull);
      expect(exported['proteinGoalGrams'], isNull);
      expect(GoalSettingsBackup.fromJson(exported), isNotNull);
    });

    test('a backup from before #642 restores the split', () {
      final restored = GoalSettingsBackup.fromJson({'version': 1})!;

      expect(restored.macroGoalsInGrams, isNull);
      expect(restored.carbGoalGrams, isNull);
    });

    for (final (name, extra) in [
      (
        'gram mode without grams',
        <String, dynamic>{
          'carbGoalGrams': null,
          'proteinGoalGrams': null,
          'fatGoalGrams': null,
        },
      ),
      ('only some of the grams', <String, dynamic>{'fatGoalGrams': null}),
      ('a negative gram goal', <String, dynamic>{'carbGoalGrams': -5}),
      (
        'a gram goal over the maximum',
        <String, dynamic>{'proteinGoalGrams': MacroGramGoals.maxGrams + 1},
      ),
      ('a non-numeric gram goal', <String, dynamic>{'fatGoalGrams': '140'}),
      ('a non-boolean gram mode', <String, dynamic>{'macroGoalsInGrams': 1}),
      (
        'gram mode with all goals at 0 g',
        <String, dynamic>{
          'carbGoalGrams': 0,
          'proteinGoalGrams': 0,
          'fatGoalGrams': 0,
        },
      ),
    ]) {
      test('$name rejects the file', () {
        expect(
          () => GoalSettingsBackup.fromJson(json(extra)),
          throwsFormatException,
        );
      });
    }
  });
}
