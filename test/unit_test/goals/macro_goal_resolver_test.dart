import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/core/utils/calc/macro_goal_resolver.dart';

void main() {
  group('kcal goal', () {
    test('calculated mode keeps the calculated goal', () {
      expect(
        MacroGoalResolver.kcalGoal(
          const GoalTargets(),
          calculatedKcal: 2450,
          activityKcal: 300,
        ),
        2450,
      );
    });

    test('a fixed goal still gets the burned activity kcal added', () {
      expect(
        MacroGoalResolver.kcalGoal(
          const GoalTargets(kcalMode: KcalGoalMode.fixed, fixedKcal: 2000),
          calculatedKcal: 2450,
          activityKcal: 300,
        ),
        2300,
      );
    });

    test('fixed mode without a value falls back to the calculated goal', () {
      expect(
        MacroGoalResolver.kcalGoal(
          const GoalTargets(kcalMode: KcalGoalMode.fixed),
          calculatedKcal: 2450,
          activityKcal: 300,
        ),
        2450,
      );
    });
  });

  group('macro goals', () {
    test('percent mode splits the kcal goal (4/9/4 kcal per gram)', () {
      final goals = MacroGoalResolver.macros(
        const GoalTargets(),
        kcalGoal: 2000,
        carbsPct: 0.5,
        fatPct: 0.3,
        proteinPct: 0.2,
      );

      expect(goals.carbsG, 250);
      expect(goals.fatG, closeTo(66.67, 0.01));
      expect(goals.proteinG, 100);
    });

    test('percent mode without a split uses the app default 60/25/15', () {
      final goals = MacroGoalResolver.macros(
        const GoalTargets(),
        kcalGoal: 2000,
      );

      expect(goals.carbsG, 300);
      expect(goals.fatG, closeTo(55.56, 0.01));
      expect(goals.proteinG, 75);
    });

    test('gram mode returns the grams as set, whatever the kcal goal', () {
      const targets = GoalTargets(
        macroMode: MacroGoalMode.grams,
        carbsG: 200,
        fatG: 70,
        proteinG: 150,
      );

      final goals = MacroGoalResolver.macros(targets, kcalGoal: 3000);

      expect([goals.carbsG, goals.fatG, goals.proteinG], [200, 70, 150]);
    });

    test('gram mode with a missing value falls back to the split', () {
      const targets = GoalTargets(
        macroMode: MacroGoalMode.grams,
        carbsG: 200,
        proteinG: 150,
      );

      final goals = MacroGoalResolver.macros(targets, kcalGoal: 2000);

      expect(goals.carbsG, 300);
      expect(goals.proteinG, 75);
    });

    test('grams convert to kcal and back to a split', () {
      expect(
        MacroGoalResolver.kcalOfGrams(carbsG: 200, fatG: 70, proteinG: 150),
        200 * 4 + 70 * 9 + 150 * 4,
      );
      final split = MacroGoalResolver.percentOfGrams(
        carbsG: 250,
        fatG: 66.67,
        proteinG: 100,
      )!;
      expect(split.carbs, closeTo(0.5, 0.001));
      expect(split.fat, closeTo(0.3, 0.001));
      expect(split.protein, closeTo(0.2, 0.001));
    });

    test('no grams give no split', () {
      expect(
        MacroGoalResolver.percentOfGrams(carbsG: 0, fatG: 0, proteinG: 0),
        isNull,
      );
    });
  });

  group('GoalTargets', () {
    ConfigDBO config() => ConfigDBO(false, false, false, AppThemeDBO.system);

    test('an existing user without the new fields keeps the old behaviour', () {
      final targets = GoalTargets.fromConfigDBO(config());

      expect(targets.kcalMode, KcalGoalMode.calculated);
      expect(targets.macroMode, MacroGoalMode.percent);
      expect(targets, const GoalTargets());
    });

    test('round-trips through the config', () {
      const targets = GoalTargets(
        kcalMode: KcalGoalMode.fixed,
        fixedKcal: 2100,
        macroMode: MacroGoalMode.grams,
        carbsG: 220,
        fatG: 70,
        proteinG: 160,
      );
      final dbo = config();
      targets.applyTo(dbo);

      expect(
        GoalTargets.fromConfigDBO(ConfigDBO.fromJson(dbo.toJson())),
        targets,
      );
    });

    test('round-trips through JSON', () {
      const targets = GoalTargets(
        kcalMode: KcalGoalMode.fixed,
        fixedKcal: 2100,
        macroMode: MacroGoalMode.grams,
        carbsG: 220,
        fatG: 70,
        proteinG: 160,
      );

      expect(GoalTargets.fromJson(targets.toJson()), targets);
      expect(GoalTargets.fromJson(const {}), const GoalTargets());
    });

    test('rejects values no settings screen would store', () {
      expect(
        () => GoalTargets.fromJson(const {'fixedKcal': 50}),
        throwsFormatException,
      );
      expect(
        () => GoalTargets.fromJson(const {'proteinG': -1}),
        throwsFormatException,
      );
      expect(
        () => GoalTargets.fromJson(const {'kcalMode': 'banana'}),
        throwsFormatException,
      );
    });

    test('unreadable stored values read as unset', () {
      final dbo = config()
        ..kcalGoalMode = 'banana'
        ..fixedKcalGoal = double.nan
        ..proteinGoalG = -5;

      final targets = GoalTargets.fromConfigDBO(dbo);

      expect(targets.kcalMode, KcalGoalMode.calculated);
      expect(targets.fixedKcal, isNull);
      expect(targets.proteinG, isNull);
    });
  });
}
