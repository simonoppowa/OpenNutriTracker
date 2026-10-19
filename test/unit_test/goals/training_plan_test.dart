import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';

void main() {
  const restTargets = GoalTargets(
    kcalMode: KcalGoalMode.fixed,
    fixedKcal: 2000,
  );
  const trainingTargets = GoalTargets(
    kcalMode: KcalGoalMode.fixed,
    fixedKcal: 2600,
  );
  final monday = DateTime(2026, 10, 19);
  final tuesday = DateTime(2026, 10, 20);
  final wednesday = DateTime(2026, 10, 21);

  const plan = TrainingPlan(
    trainingTargets: trainingTargets,
    trainingWeekdays: {DateTime.monday, DateTime.wednesday, DateTime.friday},
  );

  test('without a plan every day is a rest day with the normal goals', () {
    const none = TrainingPlan();

    expect(none.isEnabled, isFalse);
    expect(none.dayTypeOf(monday), DayType.rest);
    expect(none.targetsFor(monday, restTargets), restTargets);
  });

  test('the weekly plan makes its weekdays training days', () {
    expect(plan.dayTypeOf(monday), DayType.training);
    expect(plan.dayTypeOf(tuesday), DayType.rest);
    expect(plan.dayTypeOf(wednesday), DayType.training);
  });

  test(
    'a training day uses the training goals, a rest day the normal ones',
    () {
      expect(plan.targetsFor(monday, restTargets), trainingTargets);
      expect(plan.targetsFor(tuesday, restTargets), restTargets);
    },
  );

  test('a day set by hand wins over the weekly plan', () {
    final changed = plan
        .withDayType(monday, DayType.rest)
        .withDayType(tuesday, DayType.training);

    expect(changed.dayTypeOf(monday), DayType.rest);
    expect(changed.dayTypeOf(tuesday), DayType.training);
    expect(changed.isSetByHand(monday), isTrue);
    expect(changed.isSetByHand(wednesday), isFalse);
  });

  test('the time of day does not matter', () {
    expect(
      plan
          .withDayType(monday, DayType.rest)
          .dayTypeOf(DateTime(2026, 10, 19, 23, 30)),
      DayType.rest,
    );
  });

  test('a plan without training goals uses the normal goals every day', () {
    const weekdaysOnly = TrainingPlan(trainingWeekdays: {DateTime.monday});

    expect(weekdaysOnly.isEnabled, isFalse);
    expect(weekdaysOnly.targetsFor(monday, restTargets), restTargets);
  });

  test('round-trips through the config and JSON', () {
    final changed = plan.withDayType(tuesday, DayType.training);
    final dbo = ConfigDBO(false, false, false, AppThemeDBO.system);
    changed.applyTo(dbo);

    expect(
      TrainingPlan.fromConfigDBO(ConfigDBO.fromJson(dbo.toJson())),
      changed,
    );
    expect(TrainingPlan.fromJson(changed.toJson()), changed);
    expect(TrainingPlan.fromJson(const {}), const TrainingPlan());
  });

  test('rejects values no settings screen would store', () {
    expect(
      () => TrainingPlan.fromJson(const {
        'trainingWeekdays': [0],
      }),
      throwsFormatException,
    );
    expect(
      () => TrainingPlan.fromJson(const {
        'dayTypes': {'2026-10-19': 'party'},
      }),
      throwsFormatException,
    );
    expect(
      () => TrainingPlan.fromJson(const {
        'dayTypes': {'yesterday': 'rest'},
      }),
      throwsFormatException,
    );
  });

  test('unreadable stored values read as unset', () {
    final dbo = ConfigDBO(false, false, false, AppThemeDBO.system)
      ..trainingWeekdays = [9, 1]
      ..dayTypeOverrides = {'2026-10-19': 'party', '2026-10-20': 'training'}
      ..trainingGoalTargets = {'fixedKcal': 5};

    final read = TrainingPlan.fromConfigDBO(dbo);

    expect(read.trainingWeekdays, {DateTime.monday});
    expect(read.isSetByHand(monday), isFalse);
    expect(read.dayTypeOf(tuesday), DayType.training);
    expect(read.trainingTargets, isNull);
  });

  group('activity rule', () {
    const enabledPlan = TrainingPlan(
      trainingTargets: trainingTargets,
      autoTrainingDay: AutoTrainingDay.automatic,
    );

    test('off by default, so nothing happens', () {
      expect(const TrainingPlan().autoTrainingDay, AutoTrainingDay.off);
      expect(
        const TrainingPlan(
          trainingTargets: trainingTargets,
        ).decisionAfterActivity(tuesday),
        AutoTrainingDayDecision.none,
      );
    });

    test('automatic switches a rest day, suggest asks', () {
      expect(
        enabledPlan.decisionAfterActivity(tuesday),
        AutoTrainingDayDecision.switchToTraining,
      );
      expect(
        const TrainingPlan(
          trainingTargets: trainingTargets,
          autoTrainingDay: AutoTrainingDay.suggest,
        ).decisionAfterActivity(tuesday),
        AutoTrainingDayDecision.suggest,
      );
    });

    test('a day the user set by hand stays as set', () {
      expect(
        enabledPlan
            .withDayType(tuesday, DayType.rest)
            .decisionAfterActivity(tuesday),
        AutoTrainingDayDecision.none,
      );
    });

    test('a training day needs nothing', () {
      expect(
        enabledPlan
            .withTrainingWeekdays({DateTime.tuesday})
            .decisionAfterActivity(tuesday),
        AutoTrainingDayDecision.none,
      );
    });

    test('without training goals there is nothing to switch to', () {
      expect(
        const TrainingPlan(
          autoTrainingDay: AutoTrainingDay.automatic,
        ).decisionAfterActivity(tuesday),
        AutoTrainingDayDecision.none,
      );
    });

    test('the mode round-trips and rejects unknown values', () {
      final dbo = ConfigDBO(false, false, false, AppThemeDBO.system);
      enabledPlan.applyTo(dbo);

      expect(
        TrainingPlan.fromConfigDBO(
          ConfigDBO.fromJson(dbo.toJson()),
        ).autoTrainingDay,
        AutoTrainingDay.automatic,
      );
      expect(
        TrainingPlan.fromJson(enabledPlan.toJson()).autoTrainingDay,
        AutoTrainingDay.automatic,
      );
      expect(
        () => TrainingPlan.fromJson(const {'autoTrainingDay': 'sometimes'}),
        throwsFormatException,
      );
    });
  });
}
