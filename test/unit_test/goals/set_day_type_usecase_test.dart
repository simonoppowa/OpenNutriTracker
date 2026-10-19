import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_type_usecase.dart';

class _FakeConfigRepository extends Fake implements ConfigRepository {
  TrainingPlan plan;

  _FakeConfigRepository(this.plan);

  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
    false,
    false,
    false,
    AppThemeEntity.system,
    goalTargets: const GoalTargets(
      kcalMode: KcalGoalMode.fixed,
      fixedKcal: 2000,
      macroMode: MacroGoalMode.grams,
      carbsG: 200,
      fatG: 70,
      proteinG: 120,
    ),
    trainingPlan: plan,
  );

  @override
  Future<void> setTrainingPlan(TrainingPlan plan) async => this.plan = plan;
}

class _FakeUserRepository extends Fake implements UserRepository {
  @override
  Future<UserEntity> getUserData() async => UserEntity(
    birthday: DateTime(1990),
    heightCM: 180,
    weightKG: 80,
    gender: UserGenderEntity.male,
    goal: UserWeightGoalEntity.maintainWeight,
    pal: UserPALEntity.active,
  );
}

class _FakeUserActivityRepository extends Fake
    implements UserActivityRepository {
  final requestedDays = <DateTime>[];

  @override
  Future<List<UserActivityEntity>> getAllUserActivityByDate(
    DateTime dateTime, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async {
    requestedDays.add(dateTime);
    return const [];
  }
}

class _FakeAddTrackedDayUsecase extends Fake implements AddTrackedDayUsecase {
  final bool exists;
  double? calorieGoal;
  ({double? carbs, double? fat, double? protein})? macroGoals;

  _FakeAddTrackedDayUsecase({required this.exists});

  @override
  Future<bool> hasTrackedDay(DateTime day) async => exists;

  @override
  Future<void> updateDayCalorieGoal(DateTime day, double calorieGoal) async =>
      this.calorieGoal = calorieGoal;

  @override
  Future<void> updateDayMacroGoals(
    DateTime day, {
    double? carbsGoal,
    double? fatGoal,
    double? proteinGoal,
  }) async =>
      macroGoals = (carbs: carbsGoal, fat: fatGoal, protein: proteinGoal);
}

void main() {
  final tuesday = DateTime(2026, 10, 20);
  const plan = TrainingPlan(
    trainingTargets: GoalTargets(
      kcalMode: KcalGoalMode.fixed,
      fixedKcal: 2600,
      macroMode: MacroGoalMode.grams,
      carbsG: 320,
      fatG: 75,
      proteinG: 150,
    ),
    trainingWeekdays: {DateTime.monday},
  );

  late _FakeConfigRepository config;
  late _FakeUserActivityRepository activities;

  SetDayTypeUsecase usecase(_FakeAddTrackedDayUsecase trackedDays) {
    config = _FakeConfigRepository(plan);
    activities = _FakeUserActivityRepository();
    return SetDayTypeUsecase(
      config,
      GetKcalGoalUsecase(_FakeUserRepository(), config, activities),
      GetMacroGoalUsecase(config),
      trackedDays,
    );
  }

  test('a rest day made a training day gets the training goals', () async {
    final trackedDays = _FakeAddTrackedDayUsecase(exists: true);

    await usecase(trackedDays).setDayType(tuesday, DayType.training);

    expect(config.plan.dayTypeOf(tuesday), DayType.training);
    expect(trackedDays.calorieGoal, 2600);
    expect(trackedDays.macroGoals, (carbs: 320.0, fat: 75.0, protein: 150.0));
    expect(activities.requestedDays, [tuesday]);
  });

  test('back to a rest day restores the normal goals', () async {
    final trackedDays = _FakeAddTrackedDayUsecase(exists: true);
    final setDayType = usecase(trackedDays);

    await setDayType.setDayType(tuesday, DayType.training);
    await setDayType.setDayType(tuesday, DayType.rest);

    expect(trackedDays.calorieGoal, 2000);
    expect(trackedDays.macroGoals, (carbs: 200.0, fat: 70.0, protein: 120.0));
  });

  test('a day without a tracked day only records the choice', () async {
    final trackedDays = _FakeAddTrackedDayUsecase(exists: false);

    await usecase(trackedDays).setDayType(tuesday, DayType.training);

    expect(config.plan.isSetByHand(tuesday), isTrue);
    expect(trackedDays.calorieGoal, isNull);
  });
}
