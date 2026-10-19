import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';

import '../../fixture/physical_activity_entity_fixtures.dart';

class _FakeUserRepository extends Fake implements UserRepository {
  final UserEntity user;

  _FakeUserRepository(this.user);

  @override
  Future<UserEntity> getUserData() async => user;
}

class _FakeConfigRepository extends Fake implements ConfigRepository {
  ConfigEntity config;

  _FakeConfigRepository(this.config);

  @override
  Future<ConfigEntity> getConfig() async => config;
}

class _FakeUserActivityRepository extends Fake
    implements UserActivityRepository {
  final List<UserActivityEntity> activities;

  _FakeUserActivityRepository(this.activities);

  @override
  Future<List<UserActivityEntity>> getAllUserActivityByDate(
    DateTime dateTime, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => activities;
}

void main() {
  final user = UserEntity(
    birthday: DateTime(1990, 5, 1),
    heightCM: 180,
    weightKG: 80,
    gender: UserGenderEntity.male,
    goal: UserWeightGoalEntity.maintainWeight,
    pal: UserPALEntity.active,
  );
  final activities = [
    UserActivityEntity(
      'a1',
      45,
      300,
      DateTime.now(),
      PhysicalActivityFixtures.moderateBicycling,
    ),
  ];

  ConfigEntity config(GoalTargets targets) => ConfigEntity(
    false,
    false,
    false,
    AppThemeEntity.system,
    userCarbGoalPct: 0.5,
    userFatGoalPct: 0.3,
    userProteinGoalPct: 0.2,
    goalTargets: targets,
  );

  late _FakeConfigRepository configRepository;
  late GetKcalGoalUsecase kcalGoal;
  late GetMacroGoalUsecase macroGoal;

  setUp(() {
    configRepository = _FakeConfigRepository(config(const GoalTargets()));
    kcalGoal = GetKcalGoalUsecase(
      _FakeUserRepository(user),
      configRepository,
      _FakeUserActivityRepository(activities),
    );
    macroGoal = GetMacroGoalUsecase(configRepository);
  });

  test('the calculated goal stays as before', () async {
    expect(
      await kcalGoal.getKcalGoal(),
      CalorieGoalCalc.getTotalKcalGoal(user, 300),
    );
  });

  test('a fixed goal plus the burned activity kcal', () async {
    configRepository.config = config(
      const GoalTargets(kcalMode: KcalGoalMode.fixed, fixedKcal: 2000),
    );

    expect(await kcalGoal.getKcalGoal(), 2300);
  });

  test('a fixed goal uses the activity kcal a caller passes', () async {
    configRepository.config = config(
      const GoalTargets(kcalMode: KcalGoalMode.fixed, fixedKcal: 2000),
    );

    expect(await kcalGoal.getKcalGoal(totalKcalActivitiesParam: 100), 2100);
  });

  test('percent macros split the goal as before', () async {
    expect(await macroGoal.getCarbsGoal(2000), 250);
    expect(await macroGoal.getFatsGoal(1800), 60);
    expect(await macroGoal.getProteinsGoal(2000), 100);
  });

  test('gram macros are returned as set', () async {
    configRepository.config = config(
      const GoalTargets(
        macroMode: MacroGoalMode.grams,
        carbsG: 220,
        fatG: 70,
        proteinG: 160,
      ),
    );

    expect(await macroGoal.getCarbsGoal(3000), 220);
    expect(await macroGoal.getFatsGoal(3000), 70);
    expect(await macroGoal.getProteinsGoal(3000), 160);
  });
}
