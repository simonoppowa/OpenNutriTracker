import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/demo/demo_content.dart';
import 'package:opennutritracker/core/utils/demo/demo_seeder.dart';

// #1224: the demo weight log dates its entries in calendar days, like the
// four user-facing weight write sites. `startOfToday.subtract(Duration(days:
// n))` lands at 23:00 the evening before across a spring-forward and at 01:00
// across a fall-back. The DST groups run under `just test_dst`
// (TZ=Europe/Berlin) and skip with a reason elsewhere.

int _hoursIn(DateTime day) =>
    DateTime(day.year, day.month, day.day + 1).difference(day).inHours;

String? _skipUnless(DateTime day, int hours, String what) =>
    _hoursIn(day) == hours
    ? null
    : 'no $what on $day in zone ${day.timeZoneName}; '
          'run `just test_dst` (TZ=Europe/Berlin)';

DemoSeedOptions _options(int daysOfHistory) => DemoSeedOptions(
  daysOfHistory: daysOfHistory,
  missedDayProbability: 0,
  guaranteedStreakDays: daysOfHistory,
  startWeightKg: 90,
);

void _expectCalendarDays(DateTime today, int daysOfHistory) {
  resetDemoRng();
  final dates = buildDemoWeightLog(
    today,
    87,
    _options(daysOfHistory),
  ).map((e) => e.date).toList();
  final first = DateTime(
    today.year,
    today.month,
    today.day - (daysOfHistory - 1),
  );

  expect(dates.first, first, reason: 'the log starts on the first day');
  expect(dates.last, today, reason: 'and ends on today');
  expect(dates.toSet(), hasLength(dates.length), reason: 'no day doubled');
  for (final d in dates) {
    expect(d, DateTime(d.year, d.month, d.day), reason: '$d is not midnight');
    expect(d.isBefore(first) || d.isAfter(today), isFalse);
  }
}

void main() {
  test('a one-day history is just today', () {
    resetDemoRng();
    final log = buildDemoWeightLog(DateTime(2026, 6, 15), 87, _options(1));
    expect(log.map((e) => e.date), [DateTime(2026, 6, 15)]);
    expect(log.single.weightKg, 87);
  });

  test('outside DST, every entry sits on a calendar midnight', () {
    _expectCalendarDays(DateTime(2026, 6, 15), 30);
  });

  group(
    'history spanning an autumn fall-back',
    () {
      // Europe/Berlin fell back on 2025-10-26: 2025-10-12 .. 2025-11-10.
      test('every entry sits on a calendar midnight', () {
        _expectCalendarDays(DateTime(2025, 11, 10), 30);
      });
    },
    skip: _skipUnless(DateTime(2025, 10, 26), 25, 'autumn fall-back'),
  );

  group(
    'history spanning a spring-forward',
    () {
      // Europe/Berlin springs forward on 2026-03-29: 2026-03-12 .. 2026-04-10.
      test('every entry sits on a calendar midnight', () {
        _expectCalendarDays(DateTime(2026, 4, 10), 30);
      });
    },
    skip: _skipUnless(DateTime(2026, 3, 29), 23, 'spring-forward'),
  );
}
