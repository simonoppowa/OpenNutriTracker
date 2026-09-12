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
  @override
  Future<void> addUser(UserEntity userEntity) async {}
}

class _FakeAddTrackedDayUsecase extends Fake implements AddTrackedDayUsecase {
  @override
  Future<bool> hasTrackedDay(DateTime day) async => false;
}

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async {
    return const ConfigEntity(false, false, false, AppThemeEntity.system);
  }
}

class _FakeGetKcalGoalUsecase extends Fake implements GetKcalGoalUsecase {}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

class _FakeDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
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
      TrendsLoaded(
        rangeDays: 30,
        windowDays: 30,
        today: DateTime(2026, 1, 1),
        days: const <TrackedDayEntity>[],
        priorWeek: const <TrackedDayEntity>[],
        weight: const [],
        bodyWeightUnit: BodyWeightUnit.kg,
        targetWeightKg: null,
        waterByDay: const {},
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
}
