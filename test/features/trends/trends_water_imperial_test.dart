import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
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

import '../../helpers/test_l10n.dart';

// #1306: the Trends water card follows the food unit preference, the way
// the calorie card follows the energy unit (#1362).

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

const _todayMl = 1400;
const _goalMl = 2000;

TrendsLoaded _loaded({required bool imperial}) {
  final now = DateTime.now();
  return TrendsLoaded(
    rangeDays: 7,
    windowDays: 7,
    days: const [],
    priorWeek: const [],
    weight: const [],
    bodyWeightUnit: BodyWeightUnit.kg,
    targetWeightKg: null,
    waterByDay: {DateTime(now.year, now.month, now.day): _todayMl},
    waterGoalMl: _goalMl,
    usesImperialFoodUnits: imperial,
  );
}

Future<void> _pump(WidgetTester tester, {required bool imperial}) async {
  // The Trends list is lazy; a tall surface builds the water card too.
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  locator.registerSingleton<TrendsBloc>(
    _SeededTrendsBloc(_loaded(imperial: imperial)),
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

/// The water card's chart is the only one with today's water as its last
/// spot.
LineChart _waterChart(WidgetTester tester, double todayY) => tester
    .widgetList<LineChart>(find.byType(LineChart))
    .firstWhere((c) => c.data.lineBarsData.first.spots.last.y == todayY);

void main() {
  tearDown(() async => locator.reset());

  testWidgets('imperial: header, points and goal line are in fl oz', (
    tester,
  ) async {
    await _pump(tester, imperial: true);

    // 7-day average 200 ml = 6.8 fl oz, goal 2000 ml = 67.6 fl oz.
    expect(find.text(l10nEn.waterChipLabelFlOz(7, 68)), findsOneWidget);

    final chart = _waterChart(tester, UnitCalc.mlToFlOz(_todayMl.toDouble()));
    expect(
      chart.data.extraLinesData.horizontalLines.single.y,
      closeTo(UnitCalc.mlToFlOz(_goalMl.toDouble()), 0.001),
    );
  });

  testWidgets('metric: header, points and goal line stay in ml', (
    tester,
  ) async {
    await _pump(tester, imperial: false);

    expect(find.text(l10nEn.waterChipLabel(200, _goalMl)), findsOneWidget);

    final chart = _waterChart(tester, _todayMl.toDouble());
    expect(chart.data.extraLinesData.horizontalLines.single.y, _goalMl);
  });
}
