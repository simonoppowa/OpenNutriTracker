import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/trends_page.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

// #1224: the Trends calorie and water cards plot one point per calendar day
// and the streak card's week starts on the right calendar day, in every zone.
//
// `today.subtract(Duration(days: n))` from a local midnight lands at 23:00 the
// evening before once a spring-forward sits between the two, so a day key is
// skipped and the window starts a day early. Dart's DateTime only knows the
// process zone and UTC, so the DST groups run under `just test_dst`
// (TZ=Europe/Berlin) and skip with a reason elsewhere.

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {}

class _FakeGetWeightLogUsecase extends Fake implements GetWeightLogUsecase {}

class _FakeGetUserUsecase extends Fake implements GetUserUsecase {}

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {}

class _FakeGetWaterIntakeUsecase extends Fake
    implements GetWaterIntakeUsecase {}

/// A TrendsBloc pinned to one loaded state: the page's LoadTrendsEvent is
/// ignored so the test controls exactly what the cards plot.
class _SeededTrendsBloc extends TrendsBloc {
  _SeededTrendsBloc(TrendsLoaded seeded)
    : super(
        _FakeGetTrackedDayUsecase(),
        _FakeGetWeightLogUsecase(),
        _FakeGetUserUsecase(),
        _FakeGetConfigUsecase(),
        _FakeGetWaterIntakeUsecase(),
      ) {
    emit(seeded);
  }

  @override
  void add(TrendsEvent event) {}
}

const _windowDays = 30;
const _goalKcal = 2000.0;
const _waterGoalMl = 1500;

int _hoursIn(DateTime day) =>
    DateTime(day.year, day.month, day.day + 1).difference(day).inHours;

String? _skipUnless(DateTime day, int hours, String what) =>
    _hoursIn(day) == hours
    ? null
    : 'no $what on $day in zone ${day.timeZoneName}; '
          'run `just test_dst` (TZ=Europe/Berlin)';

DateTime _plus(DateTime day, int n) =>
    DateTime(day.year, day.month, day.day + n);

/// Every calendar day of the window tracked and on track, at goal + i kcal,
/// with 100 + i ml of water, so each point names the day it came from.
TrendsLoaded _everyDay(DateTime windowStart, DateTime today) {
  final days = [for (var i = 0; i < _windowDays; i++) _plus(windowStart, i)];
  expect(days.last, today, reason: 'the fixture covers the whole window');
  return TrendsLoaded(
    rangeDays: _windowDays,
    windowDays: _windowDays,
    days: [
      for (var i = 0; i < days.length; i++)
        TrackedDayEntity(
          day: days[i],
          calorieGoal: _goalKcal,
          caloriesTracked: _goalKcal + i,
        ),
    ],
    // Seven on-track days the week before, so the week-over-week chip shows
    // only when this week counts more or fewer than seven.
    priorWeek: [
      for (var i = 7; i < 14; i++)
        TrackedDayEntity(
          day: _plus(today, -i),
          calorieGoal: _goalKcal,
          caloriesTracked: _goalKcal,
        ),
    ],
    weight: const [],
    bodyWeightUnit: BodyWeightUnit.kg,
    targetWeightKg: null,
    waterByDay: {for (var i = 0; i < days.length; i++) days[i]: 100 + i},
    waterGoalMl: _waterGoalMl,
  );
}

Future<void> _pump(WidgetTester tester, TrendsLoaded state) async {
  // The Trends list is lazy; a tall surface builds the water card too.
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  locator.registerSingleton<TrendsBloc>(_SeededTrendsBloc(state));
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => EnergyUnitProvider(usesKilojoules: false),
      child: const MaterialApp(
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: TrendsPage()),
      ),
    ),
  );
  await tester.pump();
}

/// The calorie card is the first line chart on the page.
List<double> _calorieYs(WidgetTester tester) => tester
    .widgetList<LineChart>(find.byType(LineChart))
    .first
    .data
    .lineBarsData
    .first
    .spots
    .map((s) => s.y)
    .toList();

/// The water card's chart is the one whose goal line is the water goal.
List<double> _waterYs(WidgetTester tester) => tester
    .widgetList<LineChart>(find.byType(LineChart))
    .firstWhere(
      (c) =>
          c.data.extraLinesData.horizontalLines.any((l) => l.y == _waterGoalMl),
    )
    .data
    .lineBarsData
    .first
    .spots
    .map((s) => s.y)
    .toList();

void _expectEveryDayOnce(WidgetTester tester) {
  expect(
    _calorieYs(tester),
    [for (var i = 0; i < _windowDays; i++) _goalKcal + i],
    reason: 'one calorie point per calendar day, none skipped or doubled',
  );
  expect(
    _waterYs(tester),
    [for (var i = 0; i < _windowDays; i++) 100.0 + i],
    reason: 'one water point per calendar day, none skipped or doubled',
  );
  // Every window day is on track: the streak runs the whole window, and this
  // week holds exactly seven days, level with the prior week (no chip).
  expect(find.text('$_windowDays'), findsOneWidget);
  expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
  expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
}

void main() {
  tearDown(() async {
    TrendsPage.clock = DateTime.now;
    await locator.reset();
  });

  testWidgets('an empty range still plots a zero for every day', (
    tester,
  ) async {
    TrendsPage.clock = () => DateTime(2026, 6, 15, 9);
    await _pump(
      tester,
      const TrendsLoaded(
        rangeDays: _windowDays,
        windowDays: _windowDays,
        days: [],
        priorWeek: [],
        weight: [],
        bodyWeightUnit: BodyWeightUnit.kg,
        targetWeightKg: null,
        waterByDay: {},
        waterGoalMl: _waterGoalMl,
      ),
    );
    expect(_calorieYs(tester), List.filled(_windowDays, 0.0));
    expect(_waterYs(tester), List.filled(_windowDays, 0.0));
    expect(find.text('0'), findsOneWidget, reason: 'no streak');
  });

  group(
    'window spanning an autumn fall-back',
    () {
      // Europe/Berlin fell back on 2025-10-26: 2025-10-01 .. 2025-10-30, with
      // the week 2025-10-24 .. 2025-10-30 across it too.
      testWidgets('plots every calendar day once and starts the week right', (
        tester,
      ) async {
        TrendsPage.clock = () => DateTime(2025, 10, 30, 9);
        await _pump(
          tester,
          _everyDay(DateTime(2025, 10, 1), DateTime(2025, 10, 30)),
        );
        _expectEveryDayOnce(tester);
      });
    },
    skip: _skipUnless(DateTime(2025, 10, 26), 25, 'autumn fall-back'),
  );

  group(
    'window spanning a spring-forward',
    () {
      // Europe/Berlin springs forward on 2026-03-29: 2026-03-04 .. 2026-04-02,
      // with the week 2026-03-27 .. 2026-04-02 across it too. The 24-hour
      // form skips Mar 28's key, starts the week on Mar 26 (eight days) and
      // cuts the streak a day short.
      testWidgets('plots every calendar day once and starts the week right', (
        tester,
      ) async {
        TrendsPage.clock = () => DateTime(2026, 4, 2, 9);
        await _pump(
          tester,
          _everyDay(DateTime(2026, 3, 4), DateTime(2026, 4, 2)),
        );
        _expectEveryDayOnce(tester);
      });
    },
    skip: _skipUnless(DateTime(2026, 3, 29), 23, 'spring-forward'),
  );
}
