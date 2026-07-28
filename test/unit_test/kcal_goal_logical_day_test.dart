import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_breakdown_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';

import '../fixture/physical_activity_entity_fixtures.dart';

/// #586: the activity query takes a day *label*, so both kcal-goal reads
/// have to resolve the boundary before asking. Handing them a raw
/// `DateTime.now()` asks for the wall-clock date, which between midnight
/// and the boundary is a different day than the one Home's activity list
/// shows — the goal would drop those burned calories while the list right
/// below it still displayed them.
///
/// The clock is pinned inside that window on purpose: outside it the two
/// spellings of "today" coincide and this test would pass either way.
class _FakeUserRepository extends Fake implements UserRepository {
  final UserEntity user;

  _FakeUserRepository(this.user);

  @override
  Future<UserEntity> getUserData() async => user;
}

class _FakeConfigRepository extends Fake implements ConfigRepository {
  final ConfigEntity config;

  _FakeConfigRepository(this.config);

  @override
  Future<ConfigEntity> getConfig() async => config;
}

/// Records the day it was asked for, so the test can assert on the value
/// the usecase resolved rather than on a number further downstream.
class _RecordingUserActivityRepository extends Fake
    implements UserActivityRepository {
  final List<UserActivityEntity> activities;
  DateTime? requestedDay;

  _RecordingUserActivityRepository(this.activities);

  @override
  Future<List<UserActivityEntity>> getAllUserActivityByDate(
    DateTime dateTime, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async {
    requestedDay = dateTime;
    return activities
        .where(
          (activity) => DayBoundaryCalc.isMomentInLogicalDayMinutes(
            dateTime,
            activity.date,
            DayBoundaryCalc.totalMinutesOf(
              dayStartOffsetHours,
              dayStartOffsetMinutes,
            ),
          ),
        )
        .toList();
  }
}

void main() {
  // 02:00 — after midnight, before the 06:00 boundary, so the logical day
  // is still the 19th while the wall-clock date is the 20th.
  final beforeBoundary = DateTime(2026, 7, 20, 2, 0);
  final logicalToday = DateTime(2026, 7, 19);

  final user = UserEntity(
    birthday: DateTime(1984, 3, 2),
    heightCM: 172.0,
    weightKG: 74.5,
    gender: UserGenderEntity.female,
    goal: UserWeightGoalEntity.loseWeight,
    pal: UserPALEntity.lowActive,
    weeklyWeightGoalKg: -0.25,
    targetWeightKg: 70.0,
    caloriesTaperEnabled: false,
  );

  const config = ConfigEntity(
    false,
    false,
    false,
    AppThemeEntity.system,
    dayStartOffsetHours: 6,
  );

  // Both belong to the logical 19th: the second was logged after midnight
  // but before the 06:00 boundary.
  final activities = [
    UserActivityEntity(
      'evening-of-the-19th',
      45,
      312.5,
      DateTime(2026, 7, 19, 20, 0),
      PhysicalActivityFixtures.moderateBicycling,
    ),
    UserActivityEntity(
      'small-hours-of-the-20th',
      20,
      87.25,
      DateTime(2026, 7, 20, 1, 0),
      PhysicalActivityFixtures.lightDancing,
    ),
  ];

  late _RecordingUserActivityRepository activityRepo;
  late GetKcalGoalUsecase kcalGoalUsecase;
  late GetKcalGoalBreakdownUsecase breakdownUsecase;

  setUp(() {
    DayBoundaryCalc.clock = () => beforeBoundary;
    addTearDown(() => DayBoundaryCalc.clock = DateTime.now);

    final userRepo = _FakeUserRepository(user);
    final configRepo = _FakeConfigRepository(config);
    activityRepo = _RecordingUserActivityRepository(activities);
    kcalGoalUsecase = GetKcalGoalUsecase(userRepo, configRepo, activityRepo);
    breakdownUsecase = GetKcalGoalBreakdownUsecase(
      userRepo,
      configRepo,
      activityRepo,
    );
  });

  test('the kcal goal asks for the logical day, not the wall-clock one',
      () async {
    await kcalGoalUsecase.getKcalGoal();

    expect(activityRepo.requestedDay, logicalToday);
  });

  test('the breakdown asks for the same logical day', () async {
    await breakdownUsecase.getBreakdown();

    expect(activityRepo.requestedDay, logicalToday);
  });

  test('activities from before the boundary still count toward the goal',
      () async {
    final breakdown = await breakdownUsecase.getBreakdown();

    expect(breakdown.activityKcal, closeTo(312.5 + 87.25, 0.0001));
  });

  test('goal and breakdown agree on the activity contribution', () async {
    final breakdown = await breakdownUsecase.getBreakdown();
    final goal = await kcalGoalUsecase.getKcalGoal();

    expect(breakdown.totalKcalGoal, goal);
  });
}
