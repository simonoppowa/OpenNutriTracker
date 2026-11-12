import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/weight_trend_chart.dart';
import 'package:opennutritracker/generated/l10n.dart';

// A touch on the weight chart names each number at one decimal with its
// unit, and the y axis fits the period: fl_chart's default tooltip printed
// the moving average unrounded and unlabelled.

final _today = DateTime(2026, 10, 22);

Future<LineChartData> _pumpChart(
  WidgetTester tester, {
  required List<WeightLogEntity> entries,
  BodyWeightUnit unit = BodyWeightUnit.kg,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: WeightTrendChart(
          entries: entries,
          bodyWeightUnit: unit,
          targetWeightKg: null,
          windowDays: 30,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.widget<LineChart>(find.byType(LineChart)).data;
}

/// Ten daily weigh-ins ending today, zig-zagging so the moving average
/// lands off the one-decimal grid.
List<WeightLogEntity> _tenDays() => [
  for (var i = 0; i < 10; i++)
    WeightLogEntity(
      date: DateTime(_today.year, _today.month, _today.day - 9 + i),
      weightKg: 96 - i * 0.13 + (i.isEven ? 0.4 : 0),
    ),
];

/// The tooltip's lines for a touch at spot [index] of every bar.
List<String> _tooltip(LineChartData data, int index) => [
  for (final item in data.lineTouchData.touchTooltipData.getTooltipItems([
    for (final (i, bar) in data.lineBarsData.indexed)
      if (index < bar.spots.length) LineBarSpot(bar, i, bar.spots[index]),
  ]))
    item!.text,
];

void main() {
  setUp(
    () => WeightTrendChart.clock = () => _today.add(const Duration(hours: 9)),
  );
  tearDown(() => WeightTrendChart.clock = DateTime.now);

  testWidgets('the tooltip names the weigh-in and the moving average', (
    tester,
  ) async {
    final data = await _pumpChart(tester, entries: _tenDays());
    expect(data.lineBarsData, hasLength(2));

    final lines = _tooltip(data, 3);
    expect(lines, hasLength(2));
    expect(lines[0], matches(RegExp(r'^Weighed \d+\.\d kg$')));
    expect(lines[1], matches(RegExp(r'^7-day average \d+\.\d kg$')));
  });

  testWidgets('the tooltip follows the body-weight unit', (tester) async {
    final data = await _pumpChart(
      tester,
      entries: _tenDays(),
      unit: BodyWeightUnit.lb,
    );
    expect(_tooltip(data, 0).first, matches(RegExp(r'^Weighed \d+\.\d lbs$')));
  });

  testWidgets('a touch marks the point with a dot, not a line to the axis', (
    tester,
  ) async {
    final data = await _pumpChart(tester, entries: _tenDays());
    final indicator = data.lineTouchData.getTouchedSpotIndicator(
      data.lineBarsData.first,
      [3],
    ).single!;
    expect(indicator.indicatorBelowLine.strokeWidth, 0);
  });

  testWidgets('a flat week fills the chart: the padding floor is 0.1', (
    tester,
  ) async {
    final data = await _pumpChart(
      tester,
      entries: [
        WeightLogEntity(date: DateTime(2026, 10, 20), weightKg: 80),
        WeightLogEntity(date: DateTime(2026, 10, 21), weightKg: 80),
      ],
    );
    expect(data.minY, closeTo(79.9, 1e-9));
    expect(data.maxY, closeTo(80.1, 1e-9));
  });

  testWidgets('large text widens the axes and thins the dates', (tester) async {
    final normal = await _pumpChart(tester, entries: _tenDays());
    final large = await _pumpChart(tester, entries: _tenDays(), textScale: 2);
    final n = normal.titlesData, l = large.titlesData;
    expect(
      l.leftTitles.sideTitles.reservedSize,
      n.leftTitles.sideTitles.reservedSize * 2,
    );
    expect(
      l.bottomTitles.sideTitles.reservedSize,
      n.bottomTitles.sideTitles.reservedSize * 2,
    );
    // 30 days: a date every 6 days, every 10 at large text.
    expect(n.bottomTitles.sideTitles.interval, 6);
    expect(l.bottomTitles.sideTitles.interval, 10);
  });
}
