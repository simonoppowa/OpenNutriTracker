import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
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

import '../../helpers/test_l10n.dart';

// The calorie and water charts' tooltips give the unit and the day after
// the number; a range with nothing logged says so instead of drawing a
// flat line; the water chart fits its period and marks each day up to a
// month.

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

final _now = DateTime.now();
final _today = DateTime(_now.year, _now.month, _now.day);
DateTime _daysAgo(int n) => DateTime(_today.year, _today.month, _today.day - n);

Future<void> _pump(
  WidgetTester tester, {
  int rangeDays = 7,
  List<TrackedDayEntity> days = const [],
  Map<DateTime, int> water = const {},
  bool imperial = false,
}) async {
  // The Trends list is lazy; a tall surface builds every card.
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  locator.registerSingleton<TrendsBloc>(
    _SeededTrendsBloc(
      TrendsLoaded(
        rangeDays: rangeDays,
        windowDays: rangeDays,
        days: days,
        priorWeek: const [],
        weight: const [],
        bodyWeightUnit: BodyWeightUnit.kg,
        targetWeightKg: null,
        waterByDay: water,
        waterGoalMl: 2000,
        usesImperialFoodUnits: imperial,
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

LineChartData _chart(WidgetTester tester, String label) => tester
    .widget<LineChart>(
      find.descendant(of: _card(label), matching: find.byType(LineChart)),
    )
    .data;

/// The touched spot's tooltip: the item's text and the span after it.
(String, String) _tooltip(LineChartData data, int index) {
  final bar = data.lineBarsData.first;
  final item = data.lineTouchData.touchTooltipData.getTooltipItems([
    LineBarSpot(bar, 0, bar.spots[index]),
  ]).single!;
  return (item.text, item.children!.single.toPlainText());
}

/// The chart's Semantics wrapper, which only the chart, not the empty
/// state, has.
Finder _card(String label) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
);

String _mmmd(DateTime day) => DateFormat.MMMd('en').format(day);

void main() {
  tearDown(() async => locator.reset());

  testWidgets('the calorie tooltip gives the unit and the day', (tester) async {
    await _pump(
      tester,
      days: [
        TrackedDayEntity(
          day: _daysAgo(2),
          calorieGoal: 2000,
          caloriesTracked: 1850,
        ),
      ],
    );
    final data = _chart(tester, l10nEn.trendsCaloriesLabel);
    expect(_tooltip(data, 4), ('1850', ' kcal\n${_mmmd(_daysAgo(2))}'));
    expect(data.lineTouchData.touchSpotThreshold, double.infinity);
  });

  testWidgets('the water tooltip gives the unit and the day', (tester) async {
    await _pump(tester, water: {_today: 1400});
    final data = _chart(tester, l10nEn.trendsWaterLabel);
    expect(_tooltip(data, 6), ('1400', ' ml\n${_mmmd(_today)}'));
  });

  testWidgets('with imperial units the water tooltip says fl.oz', (
    tester,
  ) async {
    await _pump(tester, water: {_today: 1400}, imperial: true);
    final data = _chart(tester, l10nEn.trendsWaterLabel);
    expect(_tooltip(data, 6).$2, ' ${l10nEn.flOzUnit}\n${_mmmd(_today)}');
  });

  testWidgets('a range with nothing logged says so', (tester) async {
    await _pump(tester);
    expect(find.text(l10nEn.trendsNoCaloriesInRange), findsOneWidget);
    expect(find.text(l10nEn.trendsNoWaterInRange), findsOneWidget);
    expect(
      find.descendant(
        of: _card(l10nEn.trendsWaterLabel),
        matching: find.byType(LineChart),
      ),
      findsNothing,
    );
  });

  testWidgets('the water chart runs from a little under its lowest day', (
    tester,
  ) async {
    await _pump(
      tester,
      water: {for (var i = 0; i < 7; i++) _daysAgo(i): 1500 + i * 100},
    );
    final data = _chart(tester, l10nEn.trendsWaterLabel);
    // 1500 to 2100 ml, padded by 15% of the 600 ml span.
    expect(data.minY, closeTo(1410, 1e-9));
    expect(data.maxY, closeTo(2190, 1e-9));
  });

  testWidgets('the water chart marks each day up to a month', (tester) async {
    await _pump(tester, rangeDays: 30, water: {_today: 1400});
    expect(
      _chart(tester, l10nEn.trendsWaterLabel).lineBarsData.single.dotData.show,
      isTrue,
    );
  });
}
