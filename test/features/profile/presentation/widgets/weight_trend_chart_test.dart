import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/weight_trend_chart.dart';
import 'package:opennutritracker/generated/l10n.dart';

// #1207: the chart's window is `windowDays` calendar days ending today, and
// one calendar day is one x unit. Entries are stored at local midnight, so
// a window built from `Duration(days: N)` lands an hour off midnight when a
// DST transition sits inside it — dropping that day's entry and shifting
// the earlier dots one step left of their labels.
//
// Dart's DateTime only knows the process zone and UTC — there is no way to
// build a local date in a zone the test picks — so the DST groups below can
// only exercise the transition under a zone that has one on the pinned
// dates. `just test` runs in the process zone (UTC on CI), where they skip
// with a reason rather than pass without proving anything; `just test_dst`
// reruns this file under Europe/Berlin, on CI too, so they execute. The
// first group runs everywhere.

WeightLogEntity _entry(DateTime date, double weightKg) =>
    WeightLogEntity(date: date, weightKg: weightKg);

/// One entry per calendar day from [first] to [last] inclusive, built with
/// the y/m/d constructor (the form every user-facing write site uses; the
/// demo seeder still subtracts a Duration) so the data itself never depends
/// on a day's length.
List<WeightLogEntity> _dailyEntries(DateTime first, DateTime last) {
  final entries = <WeightLogEntity>[];
  for (var i = 0; ; i++) {
    final day = DateTime(first.year, first.month, first.day + i);
    if (day.isAfter(last)) break;
    entries.add(_entry(day, 80 + (i % 3) * 0.5));
  }
  return entries;
}

/// Hours in the local calendar day that starts at [day]'s midnight: 24
/// normally, 25 on an autumn fall-back day, 23 on a spring-forward day.
int _hoursIn(DateTime day) =>
    DateTime(day.year, day.month, day.day + 1).difference(day).inHours;

String? _skipUnless(DateTime day, int hours, String what) =>
    _hoursIn(day) == hours
    ? null
    : 'no $what on $day in zone ${day.timeZoneName}; '
          'run `just test_dst` (TZ=Europe/Berlin)';

Future<LineChartData> _pumpChart(
  WidgetTester tester, {
  required List<WeightLogEntity> entries,
  required int windowDays,
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
        body: WeightTrendChart(
          entries: entries,
          bodyWeightUnit: BodyWeightUnit.kg,
          targetWeightKg: null,
          windowDays: windowDays,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.widget<LineChart>(find.byType(LineChart)).data;
}

/// The date label the chart renders for x-axis value [x].
String _bottomLabel(LineChartData data, int x) {
  final titles = data.titlesData.bottomTitles.sideTitles;
  final widget = titles.getTitlesWidget(
    x.toDouble(),
    TitleMeta(
      min: data.minX,
      max: data.maxX,
      parentAxisSize: 400,
      axisPosition: 0,
      appliedInterval: titles.interval ?? 1,
      sideTitles: titles,
      formattedValue: '$x',
      axisSide: AxisSide.bottom,
      rotationQuarterTurns: 0,
    ),
  );
  return ((widget as Padding).child! as Text).data!;
}

String _mmmd(DateTime day) => DateFormat.MMMd('en').format(day);

/// Asserts the chart drew exactly the entries from [windowStart] through
/// [today], one x unit per calendar day with no gap, and that the labels
/// on the window's edges and on [checkDay] name the calendar days they
/// sit under.
void _expectCalendarWindow(
  LineChartData data, {
  required DateTime windowStart,
  required DateTime today,
  required int windowDays,
  required DateTime checkDay,
  required int checkX,
}) {
  final spots = data.lineBarsData.single.spots;
  expect(
    spots,
    hasLength(windowDays),
    reason: 'every entry in the last $windowDays calendar days is drawn',
  );
  expect(
    spots.map((s) => s.x).toList(),
    [for (var i = 0; i < windowDays; i++) i.toDouble()],
    reason: 'one integer x per calendar day, no gap and no doubled day',
  );
  expect(data.minX, 0);
  expect(data.maxX, (windowDays - 1).toDouble());
  expect(_bottomLabel(data, 0), _mmmd(windowStart));
  expect(_bottomLabel(data, windowDays - 1), _mmmd(today));
  expect(_bottomLabel(data, checkX), _mmmd(checkDay));
}

void main() {
  tearDown(() {
    WeightTrendChart.clock = DateTime.now;
  });

  group('calendar window (any zone)', () {
    testWidgets(
      'draws every entry of the last windowDays calendar days, one x per '
      'day, and drops the day before the window and the future',
      (tester) async {
        final today = DateTime(2026, 6, 15);
        WeightTrendChart.clock = () => DateTime(2026, 6, 15, 14, 30);
        const windowDays = 30;
        final windowStart = DateTime(2026, 5, 17);

        final entries = [
          _entry(DateTime(2026, 5, 16), 99), // the day before the window
          ..._dailyEntries(windowStart, today),
          _entry(DateTime(2026, 6, 16), 99), // tomorrow
        ];

        final data = await _pumpChart(
          tester,
          entries: entries,
          windowDays: windowDays,
        );

        _expectCalendarWindow(
          data,
          windowStart: windowStart,
          today: today,
          windowDays: windowDays,
          checkDay: DateTime(2026, 6, 1),
          checkX: 15,
        );
        expect(
          data.lineBarsData.single.spots.map((s) => s.y),
          isNot(contains(99.0)),
          reason: 'entries outside the window are not drawn',
        );
      },
    );
  });

  group(
    'window spanning an autumn fall-back',
    () {
      // Europe/Berlin fell back on 2025-10-26. Pinning today to 2025-11-10
      // puts that day inside a 30-day window (2025-10-12 .. 2025-11-10).
      final today = DateTime(2025, 11, 10);
      final windowStart = DateTime(2025, 10, 12);
      final transition = DateTime(2025, 10, 26);
      const windowDays = 30;

      testWidgets(
        'keeps the entry on the window-start day and on the 25-hour day, '
        'with one x per calendar day and labels on their days',
        (tester) async {
          WeightTrendChart.clock = () => DateTime(2025, 11, 10, 9);
          final entries = _dailyEntries(windowStart, today);

          final data = await _pumpChart(
            tester,
            entries: entries,
            windowDays: windowDays,
          );

          _expectCalendarWindow(
            data,
            windowStart: windowStart,
            today: today,
            windowDays: windowDays,
            checkDay: transition,
            checkX: 14,
          );
          // The label after the transition: `windowStart + Duration` would
          // land at 23:00 the evening before and print Oct 29 here.
          expect(_bottomLabel(data, 18), _mmmd(DateTime(2025, 10, 30)));
        },
      );
    },
    skip: _skipUnless(DateTime(2025, 10, 26), 25, 'autumn fall-back'),
  );

  group(
    'window spanning a spring-forward',
    () {
      // Europe/Berlin springs forward on 2026-03-29. Pinning today to
      // 2026-04-10 puts that day inside a 30-day window (2026-03-12 ..
      // 2026-04-10).
      final today = DateTime(2026, 4, 10);
      final windowStart = DateTime(2026, 3, 12);
      final transition = DateTime(2026, 3, 29);
      const windowDays = 30;

      testWidgets('still maps one x per calendar day across the 23-hour day', (
        tester,
      ) async {
        WeightTrendChart.clock = () => DateTime(2026, 4, 10, 9);
        final entries = _dailyEntries(windowStart, today);

        final data = await _pumpChart(
          tester,
          entries: entries,
          windowDays: windowDays,
        );

        _expectCalendarWindow(
          data,
          windowStart: windowStart,
          today: today,
          windowDays: windowDays,
          checkDay: transition,
          checkX: 17,
        );
        // A wall-clock `difference().inDays` from the calendar window
        // start would put every dot after the transition one step left.
        expect(_bottomLabel(data, 24), _mmmd(DateTime(2026, 4, 5)));
      });
    },
    skip: _skipUnless(DateTime(2026, 3, 29), 23, 'spring-forward'),
  );
}
