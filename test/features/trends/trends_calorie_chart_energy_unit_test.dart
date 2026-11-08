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
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/trends_page.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

// #1362: the Trends calorie chart and its tooltip must follow the energy
// unit setting, as the rest of the app does.

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {}

class _FakeGetWeightLogUsecase extends Fake implements GetWeightLogUsecase {}

class _FakeGetUserUsecase extends Fake implements GetUserUsecase {}

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {}

class _FakeGetWaterIntakeUsecase extends Fake
    implements GetWaterIntakeUsecase {}

/// A TrendsBloc pinned to one loaded state: the page's LoadTrendsEvent is
/// ignored so the test controls exactly what the chart plots.
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

const _trackedKcal = 1039.0;
const _goalKcal = 2000.0;

TrendsLoaded _loadedToday() {
  final now = DateTime.now();
  return TrendsLoaded(
    rangeDays: 7,
    windowDays: 7,
    days: [
      TrackedDayEntity(
        day: DateTime(now.year, now.month, now.day),
        calorieGoal: _goalKcal,
        caloriesTracked: _trackedKcal,
      ),
    ],
    priorWeek: const [],
    weight: const [],
    bodyWeightUnit: BodyWeightUnit.kg,
    targetWeightKg: null,
    waterByDay: const {},
    waterGoalMl: 0,
  );
}

Future<LineChart> _pumpCaloriesChart(
  WidgetTester tester, {
  required bool usesKilojoules,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => EnergyUnitProvider(usesKilojoules: usesKilojoules),
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
  // The calorie card is the first line chart on the page.
  return tester.widgetList<LineChart>(find.byType(LineChart)).first;
}

String _tooltipFor(LineChart chart, FlSpot spot) {
  final bar = chart.data.lineBarsData.first;
  final items = chart.data.lineTouchData.touchTooltipData.getTooltipItems([
    LineBarSpot(bar, 0, spot),
  ]);
  return items.single!.text;
}

void main() {
  setUp(() {
    locator.registerSingleton<TrendsBloc>(_SeededTrendsBloc(_loadedToday()));
  });

  tearDown(() async => locator.reset());

  testWidgets('kJ: today\'s point, tooltip and goal line are in kJ', (
    tester,
  ) async {
    final chart = await _pumpCaloriesChart(tester, usesKilojoules: true);
    final today = chart.data.lineBarsData.first.spots.last;

    expect(today.y, closeTo(UnitCalc.kcalToKj(_trackedKcal), 0.001));
    expect(_tooltipFor(chart, today), '4347');
    expect(
      chart.data.extraLinesData.horizontalLines.single.y,
      closeTo(UnitCalc.kcalToKj(_goalKcal), 0.001),
    );
  });

  testWidgets('kcal: today\'s point, tooltip and goal line stay in kcal', (
    tester,
  ) async {
    final chart = await _pumpCaloriesChart(tester, usesKilojoules: false);
    final today = chart.data.lineBarsData.first.spots.last;

    expect(today.y, _trackedKcal);
    expect(_tooltipFor(chart, today), '1039');
    expect(chart.data.extraLinesData.horizontalLines.single.y, _goalKcal);
  });
}
