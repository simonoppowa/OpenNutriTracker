import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/weight_trend_chart.dart';
import 'package:opennutritracker/generated/l10n.dart';

// #1119: rolling-mean overlay on the weight-trend chart. The primary line
// stays on every raw reading; the moving-average line is drawn behind it
// and hides day-to-day noise.

WeightLogEntity _entry(DateTime date, double weightKg) =>
    WeightLogEntity(date: date, weightKg: weightKg);

Future<LineChartData> _pumpChart(
  WidgetTester tester, {
  required List<WeightLogEntity> entries,
  int windowDays = 30,
  int? movingAverageWindowDays = 7,
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
      home: Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(size: Size(400, 400)),
          child: WeightTrendChart(
            entries: entries,
            bodyWeightUnit: BodyWeightUnit.kg,
            targetWeightKg: null,
            windowDays: windowDays,
            movingAverageWindowDays: movingAverageWindowDays,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.widget<LineChart>(find.byType(LineChart)).data;
}

void main() {
  testWidgets(
    'adds a dashed moving-average line beside the raw line when there are '
    'enough entries to smooth',
    (tester) async {
      final today = DateTime.now();
      final today0 = DateTime(today.year, today.month, today.day);
      // Ten daily readings covering the last ten days. The chart windows
      // 30 days by default; the moving-average overlay looks 7 days back.
      final entries = [
        for (var i = 0; i < 10; i++)
          _entry(today0.subtract(Duration(days: 9 - i)), 80 + (i.isEven ? 0.5 : -0.5)),
      ];

      final data = await _pumpChart(tester, entries: entries);

      // Two lines: the raw daily line, and the moving-average overlay.
      expect(data.lineBarsData, hasLength(2));
      final raw = data.lineBarsData[0];
      final ma = data.lineBarsData[1];
      expect(raw.dashArray, isNull, reason: 'primary line stays solid');
      expect(raw.dotData.show, isTrue, reason: 'primary line keeps its dots');
      expect(ma.dashArray, isNotNull, reason: 'MA line is dashed');
      expect(ma.dotData.show, isFalse, reason: 'MA line has no dots');
      // MA line has one point per entry once smoothing has kicked in (i.e.
      // ≥ 2 samples in the trailing 7-day window). Entry #0 alone falls
      // short so the line starts on entry #1.
      expect(ma.spots.length, greaterThanOrEqualTo(entries.length - 1));
      // MA point on the last entry: mean of the trailing seven days (entries
      // 3..9), one point every day, alternating +/-0.5 around 80. Every raw
      // point sits inside a padded y-range, and the MA sits inside the raw
      // envelope.
      final rawYs = raw.spots.map((s) => s.y).toList();
      final maYs = ma.spots.map((s) => s.y).toList();
      expect(
        maYs.every((y) => y >= rawYs.reduce((a, b) => a < b ? a : b) &&
            y <= rawYs.reduce((a, b) => a > b ? a : b)),
        isTrue,
        reason: 'MA never escapes the raw envelope on this data',
      );
    },
  );

  testWidgets(
    'omits the moving-average line entirely when movingAverageWindowDays is null',
    (tester) async {
      final today = DateTime.now();
      final today0 = DateTime(today.year, today.month, today.day);
      final entries = [
        for (var i = 0; i < 10; i++)
          _entry(today0.subtract(Duration(days: 9 - i)), 80.0 + i * 0.1),
      ];

      final data = await _pumpChart(
        tester,
        entries: entries,
        movingAverageWindowDays: null,
      );

      expect(data.lineBarsData, hasLength(1));
      expect(data.lineBarsData.single.dashArray, isNull);
    },
  );

  testWidgets(
    'does not render an MA line when smoothing has no data to work with '
    '(≤ 1 sample in every window)',
    (tester) async {
      final today = DateTime.now();
      final today0 = DateTime(today.year, today.month, today.day);
      // Two entries a month apart: the 7-day window on either never picks up
      // more than one sample, so the MA has nothing to smooth.
      final entries = [
        _entry(today0.subtract(const Duration(days: 29)), 82),
        _entry(today0, 80),
      ];

      final data = await _pumpChart(tester, entries: entries);

      expect(data.lineBarsData, hasLength(1),
          reason: 'primary line only — MA has no points that meet minSamples');
    },
  );
}
