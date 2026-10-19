import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_type_usecase.dart';
import 'package:opennutritracker/features/goals/domain/auto_training_day_usecase.dart';
import 'package:opennutritracker/features/goals/domain/training_aware_log_user_activity_usecase.dart';

import '../../../fixture/physical_activity_entity_fixtures.dart';

class _FakeConfigRepository extends Fake implements ConfigRepository {
  TrainingPlan plan;

  _FakeConfigRepository(this.plan);

  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
    false,
    false,
    false,
    AppThemeEntity.system,
    trainingPlan: plan,
  );
}

class _FakeSetDayTypeUsecase extends Fake implements SetDayTypeUsecase {
  final calls = <(DateTime, DayType)>[];

  @override
  Future<void> setDayType(DateTime day, DayType type) async =>
      calls.add((day, type));
}

class _FakeAddUserActivityUsecase extends Fake
    implements AddUserActivityUsecase {
  final added = <UserActivityEntity>[];

  @override
  Future<void> addUserActivity(UserActivityEntity activity) async =>
      added.add(activity);
}

class _FakeAddTrackedDayUsecase extends Fake implements AddTrackedDayUsecase {
  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;

  @override
  Future<void> increaseDayCalorieGoal(DateTime day, double amount) async {}

  @override
  Future<void> increaseDayMacroGoals(
    DateTime day, {
    double? carbsAmount,
    double? fatAmount,
    double? proteinAmount,
  }) async {}
}

void main() {
  final tuesday = DateTime(2026, 10, 20);
  const trainingTargets = GoalTargets(
    kcalMode: KcalGoalMode.fixed,
    fixedKcal: 2600,
  );

  late _FakeSetDayTypeUsecase setDayType;
  late int switched;

  AutoTrainingDayUsecase usecase(AutoTrainingDay mode) {
    setDayType = _FakeSetDayTypeUsecase();
    switched = 0;
    return AutoTrainingDayUsecase(
      _FakeConfigRepository(
        TrainingPlan(trainingTargets: trainingTargets, autoTrainingDay: mode),
      ),
      setDayType,
      onSwitched: () => switched++,
    );
  }

  test('automatic switches the day and says so', () async {
    final auto = usecase(AutoTrainingDay.automatic);

    expect(await auto.applyAutomatic(tuesday), isTrue);
    expect(setDayType.calls, [(tuesday, DayType.training)]);
    expect(switched, 1);
  });

  test('suggest leaves the day to the screen that asks', () async {
    final auto = usecase(AutoTrainingDay.suggest);

    expect(await auto.decide(tuesday), AutoTrainingDayDecision.suggest);
    expect(await auto.applyAutomatic(tuesday), isFalse);
    expect(setDayType.calls, isEmpty);
  });

  test('off does nothing', () async {
    final auto = usecase(AutoTrainingDay.off);

    expect(await auto.applyAutomatic(tuesday), isFalse);
    expect(setDayType.calls, isEmpty);
  });

  test('logging through the app applies automatic training days', () async {
    final auto = usecase(AutoTrainingDay.automatic);
    final added = _FakeAddUserActivityUsecase();
    final log = TrainingAwareLogUserActivityUsecase(
      added,
      _FakeAddTrackedDayUsecase(),
      _UnusedKcalGoal(),
      _UnusedMacroGoal(),
      auto,
    );

    await log.logActivity(
      UserActivityEntity(
        'run',
        30,
        320,
        tuesday,
        PhysicalActivityFixtures.moderateBicycling,
      ),
      day: tuesday,
    );

    expect(added.added, hasLength(1));
    expect(setDayType.calls, [(tuesday, DayType.training)]);
  });

  test('a failed switch does not fail the saved activity', () async {
    final added = _FakeAddUserActivityUsecase();
    final log = TrainingAwareLogUserActivityUsecase(
      added,
      _FakeAddTrackedDayUsecase(),
      _UnusedKcalGoal(),
      _UnusedMacroGoal(),
      AutoTrainingDayUsecase(
        _FakeConfigRepository(
          const TrainingPlan(
            trainingTargets: trainingTargets,
            autoTrainingDay: AutoTrainingDay.automatic,
          ),
        ),
        _FailingSetDayTypeUsecase(),
        onSwitched: () {},
      ),
    );

    await log.logActivity(
      UserActivityEntity(
        'run',
        30,
        320,
        tuesday,
        PhysicalActivityFixtures.moderateBicycling,
      ),
      day: tuesday,
    );

    expect(added.added, hasLength(1));
  });
}

class _FailingSetDayTypeUsecase extends Fake implements SetDayTypeUsecase {
  @override
  Future<void> setDayType(DateTime day, DayType type) async =>
      throw StateError('disk full');
}

class _UnusedKcalGoal extends Fake implements GetKcalGoalUsecase {}

class _UnusedMacroGoal extends Fake implements GetMacroGoalUsecase {}
