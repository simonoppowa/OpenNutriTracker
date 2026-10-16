import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';

import '../../../../fixture/user_entity_fixtures.dart';

class _FakeGetUserUsecase extends Fake implements GetUserUsecase {
  final UserEntity user;

  _FakeGetUserUsecase(this.user);

  @override
  Future<UserEntity> getUserData() async => user;
}

class _FakeAddUserUsecase extends Fake implements AddUserUsecase {
  int addUserCalls = 0;

  @override
  Future<void> addUser(UserEntity userEntity) async => addUserCalls++;
}

class _FakeAddTrackedDayUsecase extends Fake implements AddTrackedDayUsecase {
  bool trackedDayExists = false;
  final List<double> updatedGoals = [];

  @override
  Future<bool> hasTrackedDay(DateTime day) async => trackedDayExists;

  @override
  Future<void> updateDayCalorieGoal(DateTime day, double calorieGoal) async =>
      updatedGoals.add(calorieGoal);
}

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async {
    return const ConfigEntity(false, false, false, AppThemeEntity.system);
  }
}

class _FakeGetKcalGoalUsecase extends Fake implements GetKcalGoalUsecase {
  UserEntity? goalFor;

  @override
  Future<double> getKcalGoal({
    UserEntity? userEntity,
    double? totalKcalActivitiesParam,
    double? kcalUserAdjustment,
  }) async {
    goalFor = userEntity;
    return 2345;
  }
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

class _FakeDiaryBloc extends Fake implements DiaryBloc {
  final List<DiaryEvent> addedEvents = [];

  @override
  void add(DiaryEvent event) => addedEvents.add(event);
}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {
  final List<CalendarDayEvent> addedEvents = [];

  @override
  void add(CalendarDayEvent event) => addedEvents.add(event);
}

class _FakeTrendsBloc extends Fake implements TrendsBloc {
  TrendsState currentState;
  final List<TrendsEvent> addedEvents = [];

  _FakeTrendsBloc(this.currentState);

  @override
  TrendsState get state => currentState;

  @override
  void add(TrendsEvent event) => addedEvents.add(event);
}

void main() {
  late _FakeTrendsBloc trendsBloc;

  ProfileBloc buildProfileBloc(UserEntity user) {
    return ProfileBloc(
      _FakeGetUserUsecase(user),
      _FakeAddUserUsecase(),
      _FakeAddTrackedDayUsecase(),
      _FakeGetConfigUsecase(),
      _FakeGetKcalGoalUsecase(),
    );
  }

  tearDown(() {
    GetIt.instance.reset();
  });

  test('updateUser refreshes TrendsBloc, preserving the currently selected '
      'range chip (regression: home weight chip did not update the Trends '
      'weight card)', () async {
    final user = UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
    trendsBloc = _FakeTrendsBloc(
      const TrendsLoaded(
        rangeDays: 30,
        windowDays: 30,
        days: <TrackedDayEntity>[],
        priorWeek: <TrackedDayEntity>[],
        weight: [],
        bodyWeightUnit: BodyWeightUnit.kg,
        targetWeightKg: null,
        waterByDay: {},
        waterGoalMl: 2000,
      ),
    );

    locator.registerSingleton<HomeBloc>(_FakeHomeBloc());
    locator.registerSingleton<DiaryBloc>(_FakeDiaryBloc());
    locator.registerSingleton<CalendarDayBloc>(_FakeCalendarDayBloc());
    locator.registerSingleton<TrendsBloc>(trendsBloc);

    final profileBloc = buildProfileBloc(user);
    addTearDown(profileBloc.close);

    await profileBloc.updateUser(user);

    expect(trendsBloc.addedEvents, hasLength(1));
    final event = trendsBloc.addedEvents.single as LoadTrendsEvent;
    expect(event.rangeDays, 30);
  });

  test('updateUser refreshes TrendsBloc with the default 7-day range when '
      'Trends has not loaded yet', () async {
    final user = UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
    trendsBloc = _FakeTrendsBloc(const TrendsInitial());

    locator.registerSingleton<HomeBloc>(_FakeHomeBloc());
    locator.registerSingleton<DiaryBloc>(_FakeDiaryBloc());
    locator.registerSingleton<CalendarDayBloc>(_FakeCalendarDayBloc());
    locator.registerSingleton<TrendsBloc>(trendsBloc);

    final profileBloc = buildProfileBloc(user);
    addTearDown(profileBloc.close);

    await profileBloc.updateUser(user);

    expect(trendsBloc.addedEvents, hasLength(1));
    final event = trendsBloc.addedEvents.single as LoadTrendsEvent;
    expect(event.rangeDays, 7);
  });

  test('reloadAfterWeightImport recalculates today\'s goal from the stored '
      'user and reloads Diary, Calendar and Trends, without saving the user '
      'again (a health import writes the weight itself)', () async {
    final user = UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
    trendsBloc = _FakeTrendsBloc(const TrendsInitial());
    final diaryBloc = _FakeDiaryBloc();
    final calendarDayBloc = _FakeCalendarDayBloc();
    final addUserUsecase = _FakeAddUserUsecase();
    final addTrackedDayUsecase = _FakeAddTrackedDayUsecase()
      ..trackedDayExists = true;
    final getKcalGoalUsecase = _FakeGetKcalGoalUsecase();

    locator.registerSingleton<HomeBloc>(_FakeHomeBloc());
    locator.registerSingleton<DiaryBloc>(diaryBloc);
    locator.registerSingleton<CalendarDayBloc>(calendarDayBloc);
    locator.registerSingleton<TrendsBloc>(trendsBloc);

    final profileBloc = ProfileBloc(
      _FakeGetUserUsecase(user),
      addUserUsecase,
      addTrackedDayUsecase,
      _FakeGetConfigUsecase(),
      getKcalGoalUsecase,
    );
    addTearDown(profileBloc.close);

    await profileBloc.reloadAfterWeightImport();

    expect(addUserUsecase.addUserCalls, 0);
    expect(getKcalGoalUsecase.goalFor, same(user));
    expect(addTrackedDayUsecase.updatedGoals, [2345]);
    expect(diaryBloc.addedEvents, hasLength(1));
    expect(calendarDayBloc.addedEvents, hasLength(1));
    expect(trendsBloc.addedEvents, hasLength(1));
  });
}
