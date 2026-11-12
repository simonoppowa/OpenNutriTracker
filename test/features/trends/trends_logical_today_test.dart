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
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/trends_page.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

// #139: the Trends cards end their windows on the Diary's logical today.
// With the day starting at 04:00, 02:00 on Tuesday the 15th is still
// Monday the 14th.

final _wallClock = DateTime(2026, 9, 15, 2);
final _logicalToday = DateTime(2026, 9, 14);
const _dayStartMinutes = 4 * 60;

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {}

class _FakeGetWeightLogUsecase extends Fake implements GetWeightLogUsecase {}

class _FakeGetUserUsecase extends Fake implements GetUserUsecase {}

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {}

class _FakeGetWaterIntakeUsecase extends Fake
    implements GetWaterIntakeUsecase {}

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

TrackedDayEntity _onTrack(DateTime day, double kcal) =>
    TrackedDayEntity(day: day, calorieGoal: kcal, caloriesTracked: kcal);

Future<void> _pump(
  WidgetTester tester, {
  List<TrackedDayEntity> days = const [],
  Map<DateTime, int> water = const {},
}) async {
  // The Trends list is lazy; a tall surface builds every card.
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  locator.registerSingleton<TrendsBloc>(
    _SeededTrendsBloc(
      TrendsLoaded(
        rangeDays: 7,
        windowDays: 7,
        days: days,
        priorWeek: const [],
        weight: const [],
        bodyWeightUnit: BodyWeightUnit.kg,
        targetWeightKg: null,
        waterByDay: water,
        waterGoalMl: 2000,
        dayStartMinutes: _dayStartMinutes,
      ),
    ),
  );
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

/// The last spot of every chart on the page: each chart's window ends there.
Iterable<double> _lastSpots(WidgetTester tester) => tester
    .widgetList<LineChart>(find.byType(LineChart))
    .map((c) => c.data.lineBarsData.first.spots.last.y);

void main() {
  setUp(() => DayBoundaryCalc.clock = () => _wallClock);
  tearDown(() async {
    DayBoundaryCalc.clock = DateTime.now;
    await locator.reset();
  });

  testWidgets('the calorie chart ends on the logical today', (tester) async {
    await _pump(
      tester,
      days: [_onTrack(_logicalToday, 1800), _onTrack(_wallClock, 900)],
    );
    expect(_lastSpots(tester), contains(1800));
    expect(_lastSpots(tester), isNot(contains(900)));
  });

  testWidgets('the water chart ends on the logical today', (tester) async {
    await _pump(
      tester,
      water: {_logicalToday: 500, DateTime(2026, 9, 15): 900},
    );
    expect(_lastSpots(tester), contains(500));
    expect(_lastSpots(tester), isNot(contains(900)));
  });

  testWidgets('the streak runs to the logical today', (tester) async {
    // On track on the 13th and the 14th: two days, though the wall clock's
    // 15th has nothing logged yet.
    await _pump(
      tester,
      days: [
        _onTrack(DateTime(2026, 9, 13), 2000),
        _onTrack(_logicalToday, 2000),
      ],
    );
    expect(find.text('2'), findsOneWidget);
  });
}
