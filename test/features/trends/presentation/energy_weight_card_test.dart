import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/trends/domain/energy_weight_series.dart';
import 'package:opennutritracker/features/trends/presentation/widgets/energy_weight_card.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/test_l10n.dart';

final _series = EnergyWeightSeries(
  days: [
    EnergyWeightDay(day: DateTime(2026, 10, 19), kcal: 1800, kcalGoal: 2000),
    EnergyWeightDay(day: DateTime(2026, 10, 20)),
    EnergyWeightDay(day: DateTime(2026, 10, 21), kcal: 2200, kcalGoal: 2000),
  ],
  weightSegments: [
    [
      (day: DateTime(2026, 10, 19), kg: 80.0),
      (day: DateTime(2026, 10, 21), kg: 79.5),
    ],
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  EnergyWeightSeries? series,
  bool kilojoules = false,
  BodyWeightUnit unit = BodyWeightUnit.kg,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => EnergyUnitProvider(usesKilojoules: kilojoules),
      child: MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: SingleChildScrollView(
            child: EnergyWeightCard(
              series: series ?? _series,
              bodyWeightUnit: unit,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a bar per tracked day, none on a day without entries', (
    tester,
  ) async {
    await _pump(tester);

    final groups = tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .barGroups;
    expect(groups, hasLength(3));
    expect(groups.map((g) => g.barRods.length), [1, 0, 1]);
    expect(groups.first.barRods.single.toY, 1800);
  });

  testWidgets('the weight trend is a line per segment', (tester) async {
    await _pump(tester);

    final bars = tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .lineBarsData;
    expect(bars, hasLength(1));
    expect(bars.single.spots.map((s) => (s.x, s.y)), [
      (0.0, 80.0),
      (2.0, 79.5),
    ]);
  });

  testWidgets('energy in kJ and weight in pounds when set so', (tester) async {
    await _pump(tester, kilojoules: true, unit: BodyWeightUnit.lb);

    final groups = tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .barGroups;
    expect(groups.first.barRods.single.toY, closeTo(1800 * 4.184, 1e-6));
    final spot = tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .lineBarsData
        .single
        .spots
        .first;
    expect(spot.y, closeTo(UnitCalc.kgToLbs(80), 1e-9));
    expect(find.textContaining('kJ'), findsWidgets);
    expect(find.textContaining('lb'), findsWidgets);
  });

  testWidgets('without energy or weight it says there is nothing', (
    tester,
  ) async {
    await _pump(
      tester,
      series: EnergyWeightSeries(
        days: [EnergyWeightDay(day: DateTime(2026, 10, 19))],
        weightSegments: const [],
      ),
    );

    expect(find.text(l10nEn.trendsNoEntriesLabel), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });
}
