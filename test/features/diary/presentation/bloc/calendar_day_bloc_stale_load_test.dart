import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_user_activity_usecase.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';

/// #1360: saving a day boundary refreshes the day the Diary shows and then,
/// once the Diary has resolved the new "today", loads that day. Both run
/// at once; whichever finishes last is what the Diary shows, so a slow
/// load of the old day must not overwrite the new one.

/// Holds each day's activity read until the test releases it, so the
/// test decides which load finishes first.
class _GatedActivities extends Fake implements GetUserActivityUsecase {
  final Map<DateTime, Completer<List<UserActivityEntity>>> gates = {};

  @override
  Future<List<UserActivityEntity>> getUserActivityByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) => gates.putIfAbsent(day, Completer.new).future;
}

class _NoIntakes extends Fake implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getBreakfastIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];

  @override
  Future<List<IntakeEntity>> getLunchIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];

  @override
  Future<List<IntakeEntity>> getDinnerIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];

  @override
  Future<List<IntakeEntity>> getSnackIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];
}

/// Names the day each load read, so the emitted state says which it is.
class _DayNamingTrackedDays extends Fake implements GetTrackedDayUsecase {
  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async =>
      TrackedDayEntity(day: day, calorieGoal: 2000, caloriesTracked: 0);
}

class _Config extends Fake implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);
}

class _Unused1 extends Fake implements DeleteIntakeUsecase {}

class _Unused2 extends Fake implements DeleteUserActivityUsecase {}

class _Unused3 extends Fake implements AddTrackedDayUsecase {}

class _Unused4 extends Fake implements UpdateIntakeUsecase {}

class _Unused5 extends Fake implements UpdateUserActivityUsecase {}

class _Unused6 extends Fake implements AddConfigUsecase {}

void main() {
  final oldDay = DateTime(2026, 10, 11);
  final newDay = DateTime(2026, 10, 10);

  test(
    'a load for a day the Diary has left does not overwrite the new one',
    () async {
      final activities = _GatedActivities();
      final bloc = CalendarDayBloc(
        activities,
        _NoIntakes(),
        _Unused1(),
        _Unused2(),
        _DayNamingTrackedDays(),
        _Unused3(),
        _Unused4(),
        _Unused5(),
        _Config(),
        _Unused6(),
      );
      addTearDown(bloc.close);
      final shown = <DateTime>[];
      final sub = bloc.stream.listen((state) {
        if (state is CalendarDayLoaded) shown.add(state.trackedDayEntity!.day);
      });
      addTearDown(sub.cancel);

      bloc.add(LoadCalendarDayEvent(oldDay));
      await pumpEventQueue();
      bloc.add(LoadCalendarDayEvent(newDay));
      await pumpEventQueue();

      // The new day's load finishes first, the old one last.
      activities.gates[newDay]!.complete([]);
      await pumpEventQueue();
      activities.gates[oldDay]!.complete([]);
      await pumpEventQueue();

      expect(shown, [newDay]);
      expect((bloc.state as CalendarDayLoaded).trackedDayEntity!.day, newDay);
    },
  );
}
