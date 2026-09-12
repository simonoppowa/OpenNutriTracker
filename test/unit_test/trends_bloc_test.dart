import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/entity/water_intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Records the (start, end) ranges it is asked for so the bloc's date-window
/// arithmetic can be asserted, and returns a canned list. The bloc calls this
/// twice per load — first for the selected window, then for the prior week —
/// so [rangeCalls] holds both in order.
class _FakeGetTrackedDayUsecase implements GetTrackedDayUsecase {
  final List<({DateTime start, DateTime end})> rangeCalls = [];
  List<TrackedDayEntity> result = [];
  bool throws = false;

  @override
  Future<List<TrackedDayEntity>> getTrackedDaysByRange(
    DateTime start,
    DateTime end,
  ) async {
    rangeCalls.add((start: start, end: end));
    if (throws) throw Exception('boom');
    return result;
  }

  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async => null;
}

/// The bloc pulls the full weight history (getAllEntries) and windows it in
/// the UI, mirroring the weight-history screen.
class _FakeGetWeightLogUsecase implements GetWeightLogUsecase {
  List<WeightLogEntity> result = [];
  int getAllCalls = 0;

  @override
  Future<List<WeightLogEntity>> getAllEntries() async {
    getAllCalls++;
    return List.of(result);
  }

  @override
  Future<List<WeightLogEntity>> getEntriesInRange(
    DateTime start,
    DateTime end,
  ) async =>
      List.of(result);
}

class _FakeGetUserUsecase implements GetUserUsecase {
  double? targetWeightKg;

  @override
  Future<UserEntity> getUserData() async => UserEntity(
        birthday: DateTime(1990, 1, 1),
        heightCM: 175,
        weightKG: 75,
        gender: UserGenderEntity.female,
        goal: UserWeightGoalEntity.maintainWeight,
        pal: UserPALEntity.active,
        targetWeightKg: targetWeightKg,
      );

  @override
  Future<bool> hasUserData() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  bool usesImperialUnits = false;
  int dayStartOffsetHours = 0;
  int dayStartOffsetMinutes = 0;

  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
        true,
        true,
        false,
        AppThemeEntity.system,
        usesImperialUnits: usesImperialUnits,
        bodyWeightUnit:
            usesImperialUnits ? BodyWeightUnit.lb : BodyWeightUnit.kg,
        dayStartOffsetHours: dayStartOffsetHours,
        dayStartOffsetMinutes: dayStartOffsetMinutes,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _FakeGetWaterIntakeUsecase implements GetWaterIntakeUsecase {
  List<WaterIntakeEntity> result = [];

  @override
  Future<List<WaterIntakeEntity>> getAllEntries() async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

WeightLogEntity _wl(DateTime date, double kg) =>
    WeightLogEntity(date: date, weightKg: kg);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  // The bloc anchors every window on midnight-today; mirror that here so the
  // expected ranges line up with what the bloc computes.
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // The bloc ends ranges at the close of the day so a time-stamped tracked
  // day (today's) isn't excluded.
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final endOfPriorWeek =
      DateTime(now.year, now.month, now.day - 7, 23, 59, 59);

  group('TrendsBloc', () {
    late _FakeGetTrackedDayUsecase trackedDay;
    late _FakeGetWeightLogUsecase weightLog;
    late _FakeGetUserUsecase user;
    late _FakeGetConfigUsecase config;
    late _FakeGetWaterIntakeUsecase water;
    late TrendsBloc bloc;

    setUp(() {
      trackedDay = _FakeGetTrackedDayUsecase();
      weightLog = _FakeGetWeightLogUsecase();
      user = _FakeGetUserUsecase();
      config = _FakeGetConfigUsecase();
      water = _FakeGetWaterIntakeUsecase();
      bloc = TrendsBloc(trackedDay, weightLog, user, config, water);
    });

    tearDown(() async {
      await bloc.close();
    });

    Future<List<TrendsState>> load(LoadTrendsEvent event) async {
      final emitted = <TrendsState>[];
      final sub = bloc.stream.listen(emitted.add);
      bloc.add(event);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();
      return emitted;
    }

    test('initial state is TrendsInitial', () {
      expect(bloc.state, isA<TrendsInitial>());
    });

    test('default load emits Loading then Loaded with rangeDays 7', () async {
      final emitted = await load(const LoadTrendsEvent());
      expect(emitted.map((s) => s.runtimeType), [TrendsLoading, TrendsLoaded]);
      expect((emitted.last as TrendsLoaded).rangeDays, 7);
    });

    test('7-day window spans today-6..today, prior week today-13..today-7',
        () async {
      await load(const LoadTrendsEvent());
      // First call is the selected window, second is the prior week.
      expect(trackedDay.rangeCalls.first.start,
          today.subtract(const Duration(days: 6)));
      expect(trackedDay.rangeCalls.first.end, endOfToday);
      expect(trackedDay.rangeCalls[1].start,
          today.subtract(const Duration(days: 13)));
      expect(trackedDay.rangeCalls[1].end, endOfPriorWeek);
    });

    test('a 90-day window pulls 90 days of calories', () async {
      final emitted = await load(const LoadTrendsEvent(rangeDays: 90));
      expect((emitted.last as TrendsLoaded).rangeDays, 90);
      expect(trackedDay.rangeCalls.first.start,
          today.subtract(const Duration(days: 89)));
    });

    test('weight uses the full history, not a windowed range', () async {
      await load(const LoadTrendsEvent());
      expect(weightLog.getAllCalls, 1);
    });

    test('weight entries are sorted ascending by date', () async {
      weightLog.result = [
        _wl(today.subtract(const Duration(days: 1)), 70),
        _wl(today.subtract(const Duration(days: 3)), 72),
        _wl(today.subtract(const Duration(days: 2)), 71),
      ];
      final emitted = await load(const LoadTrendsEvent());
      final dates = (emitted.last as TrendsLoaded).weight.map((e) => e.date);
      expect(
        dates.toList(),
        [
          today.subtract(const Duration(days: 3)),
          today.subtract(const Duration(days: 2)),
          today.subtract(const Duration(days: 1)),
        ],
      );
    });

    test('carries the units and target weight through to the loaded state',
        () async {
      config.usesImperialUnits = true;
      user.targetWeightKg = 68;
      final emitted = await load(const LoadTrendsEvent());
      final loaded = emitted.last as TrendsLoaded;
      expect(loaded.bodyWeightUnit, BodyWeightUnit.lb);
      expect(loaded.targetWeightKg, 68);
    });

    test('a fixed range sets windowDays equal to the chip', () async {
      final emitted = await load(const LoadTrendsEvent(rangeDays: 30));
      expect((emitted.last as TrendsLoaded).windowDays, 30);
    });

    test('midnight day start preserves normal food and water dates',
        () async {
      DayBoundaryCalc.clock = () => DateTime(2026, 8, 12, 0, 30);
      addTearDown(() => DayBoundaryCalc.clock = DateTime.now);
      trackedDay.result = [
        TrackedDayEntity(
          day: DateTime(2026, 8, 12),
          calorieGoal: 2000,
          caloriesTracked: 500,
        ),
      ];
      water.result = [
        WaterIntakeEntity(
          id: 'before-midnight',
          dateTime: DateTime(2026, 8, 11, 23, 59, 59),
          amountMl: 100,
        ),
        WaterIntakeEntity(
          id: 'at-midnight',
          dateTime: DateTime(2026, 8, 12),
          amountMl: 200,
        ),
        WaterIntakeEntity(
          id: 'after-midnight',
          dateTime: DateTime(2026, 8, 12, 0, 0, 1),
          amountMl: 300,
        ),
      ];

      final emitted = await load(const LoadTrendsEvent());
      final loaded = emitted.last as TrendsLoaded;

      expect(loaded.today, DateTime(2026, 8, 12));
      expect(
        trackedDay.rangeCalls.first,
        (
          start: DateTime(2026, 8, 6),
          end: DateTime(2026, 8, 12, 23, 59, 59),
        ),
      );
      expect(loaded.days, trackedDay.result);
      expect(loaded.waterByDay, {
        DateTime(2026, 8, 11): 100,
        DateTime(2026, 8, 12): 500,
      });
    });

    test('08:00 day start keeps pre-boundary food and water on the prior day',
        () async {
      DayBoundaryCalc.clock = () => DateTime(2026, 8, 12, 7, 30);
      addTearDown(() => DayBoundaryCalc.clock = DateTime.now);
      config.dayStartOffsetHours = 8;
      trackedDay.result = [
        TrackedDayEntity(
          day: DateTime(2026, 8, 11, 23),
          calorieGoal: 2000,
          caloriesTracked: 500,
        ),
      ];
      water.result = [
        WaterIntakeEntity(
          id: 'before-midnight',
          dateTime: DateTime(2026, 8, 11, 23, 59),
          amountMl: 100,
        ),
        WaterIntakeEntity(
          id: 'after-midnight',
          dateTime: DateTime(2026, 8, 12, 0, 1),
          amountMl: 200,
        ),
        WaterIntakeEntity(
          id: 'before-boundary',
          dateTime: DateTime(2026, 8, 12, 7, 59, 59),
          amountMl: 300,
        ),
        WaterIntakeEntity(
          id: 'at-boundary',
          dateTime: DateTime(2026, 8, 12, 8),
          amountMl: 400,
        ),
        WaterIntakeEntity(
          id: 'after-boundary',
          dateTime: DateTime(2026, 8, 12, 8, 0, 1),
          amountMl: 500,
        ),
      ];

      final emitted = await load(const LoadTrendsEvent());
      final loaded = emitted.last as TrendsLoaded;

      expect(loaded.today, DateTime(2026, 8, 11));
      expect(
        trackedDay.rangeCalls.first,
        (
          start: DateTime(2026, 8, 5),
          end: DateTime(2026, 8, 11, 23, 59, 59),
        ),
      );
      expect(loaded.days, trackedDay.result);
      expect(loaded.waterByDay, {
        DateTime(2026, 8, 11): 600,
        DateTime(2026, 8, 12): 900,
      });
    });

    test('08:00 day start follows local wall time across spring DST',
        () async {
      final newYork = tz.getLocation('America/New_York');
      DayBoundaryCalc.clock = () => tz.TZDateTime(
            newYork,
            2026,
            3,
            8,
            7,
            30,
          );
      addTearDown(() => DayBoundaryCalc.clock = DateTime.now);
      config.dayStartOffsetHours = 8;
      water.result = [
        WaterIntakeEntity(
          id: 'before-midnight',
          dateTime: tz.TZDateTime(newYork, 2026, 3, 7, 23, 59),
          amountMl: 100,
        ),
        WaterIntakeEntity(
          id: 'before-spring-forward',
          dateTime: tz.TZDateTime(newYork, 2026, 3, 8, 1, 59),
          amountMl: 200,
        ),
        WaterIntakeEntity(
          id: 'after-spring-forward',
          dateTime: tz.TZDateTime(newYork, 2026, 3, 8, 3),
          amountMl: 300,
        ),
        WaterIntakeEntity(
          id: 'before-boundary',
          dateTime: tz.TZDateTime(newYork, 2026, 3, 8, 7, 59, 59),
          amountMl: 400,
        ),
        WaterIntakeEntity(
          id: 'at-boundary',
          dateTime: tz.TZDateTime(newYork, 2026, 3, 8, 8),
          amountMl: 500,
        ),
        WaterIntakeEntity(
          id: 'after-boundary',
          dateTime: tz.TZDateTime(newYork, 2026, 3, 8, 8, 0, 1),
          amountMl: 600,
        ),
      ];

      final emitted = await load(const LoadTrendsEvent());
      final loaded = emitted.last as TrendsLoaded;

      expect(loaded.today, DateTime(2026, 3, 7));
      expect(loaded.waterByDay, {
        DateTime(2026, 3, 7): 1000,
        DateTime(2026, 3, 8): 1100,
      });
    });

    test('the "All" range (0) spans back to the earliest data', () async {
      // Earliest signal is a weight reading 50 days ago.
      weightLog.result = [_wl(today.subtract(const Duration(days: 50)), 80)];
      final emitted = await load(const LoadTrendsEvent(rangeDays: 0));
      final loaded = emitted.last as TrendsLoaded;
      expect(loaded.rangeDays, 0); // the selector still shows "All"
      expect(loaded.windowDays, 51); // 50 days back, inclusive of today
    });

    test('"All" starts at the first entry, not a padded floor', () async {
      // Only a few days of history: the window is the exact span, so the
      // charts begin at the first entry instead of showing blank days before.
      weightLog.result = [_wl(today.subtract(const Duration(days: 5)), 80)];
      final emitted = await load(const LoadTrendsEvent(rangeDays: 0));
      expect((emitted.last as TrendsLoaded).windowDays, 6); // not floored to 30
    });

    test('"All" with no data falls back to a 30-day window', () async {
      final emitted = await load(const LoadTrendsEvent(rangeDays: 0));
      expect((emitted.last as TrendsLoaded).windowDays, 30);
    });

    test('a failing data source surfaces TrendsFailed', () async {
      trackedDay.throws = true;
      final emitted = await load(const LoadTrendsEvent());
      expect(emitted.map((s) => s.runtimeType), [TrendsLoading, TrendsFailed]);
    });
  });
}
