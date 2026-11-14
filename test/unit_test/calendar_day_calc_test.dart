import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/calendar_day_calc.dart';

// #1207: the weight-trend chart maps one calendar day to one x unit, so
// day arithmetic must not depend on how many hours a day actually had.
//
// Dart's DateTime only knows the process zone and UTC — there is no way to
// build a local date in a zone the test picks — so the DST cases can only
// run under a zone that has the transition. `just test` runs in the process
// zone (UTC on CI), where the DST groups skip with a reason instead of
// passing vacuously; `just test_dst` reruns this file under Europe/Berlin,
// on CI too, so they execute.

/// Hours in the local calendar day that starts at [day]'s midnight: 24
/// normally, 25 on an autumn fall-back day, 23 on a spring-forward day.
int _hoursIn(DateTime day) =>
    DateTime(day.year, day.month, day.day + 1).difference(day).inHours;

String? _skipUnless(DateTime day, int hours, String what) =>
    _hoursIn(day) == hours
    ? null
    : 'no $what on $day in zone ${day.timeZoneName}; '
          'run `just test_dst` (TZ=Europe/Berlin)';

void main() {
  group('CalendarDayCalc.daysBetween', () {
    test('is zero on the same day and ignores the time of day', () {
      expect(
        CalendarDayCalc.daysBetween(
          DateTime(2026, 6, 15),
          DateTime(2026, 6, 15, 23, 59),
        ),
        0,
      );
      expect(
        CalendarDayCalc.daysBetween(
          DateTime(2026, 6, 15, 22),
          DateTime(2026, 6, 16, 1),
        ),
        1,
      );
    });

    test('counts whole days forward and negative days backward', () {
      expect(
        CalendarDayCalc.daysBetween(DateTime(2026, 1, 1), DateTime(2026, 3, 1)),
        59,
      );
      expect(
        CalendarDayCalc.daysBetween(DateTime(2026, 3, 1), DateTime(2026, 1, 1)),
        -59,
      );
    });

    group(
      'across an autumn fall-back',
      () {
        // Pins the contract; it does not discriminate the helper from the
        // wall-clock form, which also passes here: a 25-hour day makes the
        // span N days plus an hour and `.inDays` truncates that to N. The
        // fall-back defect is `subtract(Duration)` on the window start,
        // which the weight_trend_chart widget test covers.
        test('a 25-hour day still counts as one day', () {
          final before = DateTime(2025, 10, 12);
          final transition = DateTime(2025, 10, 26);
          final after = DateTime(2025, 11, 10);
          expect(CalendarDayCalc.daysBetween(before, transition), 14);
          expect(CalendarDayCalc.daysBetween(before, after), 29);
          expect(CalendarDayCalc.daysBetween(transition, after), 15);
        });
      },
      // Europe/Berlin fell back on 2025-10-26.
      skip: _skipUnless(DateTime(2025, 10, 26), 25, 'autumn fall-back'),
    );

    group(
      'across a spring-forward',
      () {
        test('a 23-hour day still counts as one day', () {
          final before = DateTime(2026, 3, 12);
          final transition = DateTime(2026, 3, 29);
          final after = DateTime(2026, 4, 10);
          expect(CalendarDayCalc.daysBetween(before, transition), 17);
          expect(CalendarDayCalc.daysBetween(before, after), 29);
          expect(CalendarDayCalc.daysBetween(transition, after), 12);
          // The wall-clock form this helper replaces measures 29 days minus
          // one hour here and truncates to 28.
          expect(after.difference(before).inDays, 28);
        });
      },
      // Europe/Berlin springs forward on 2026-03-29.
      skip: _skipUnless(DateTime(2026, 3, 29), 23, 'spring-forward'),
    );
  });
  // #1224: the Trends page, its bloc and the demo seeder step back from today
  // in calendar days. `today.subtract(Duration(days: n))` lands at 23:00 the
  // evening before across a spring-forward (so its date is a day early) and
  // at 01:00 across a fall-back (so it is no longer midnight).
  group('CalendarDayCalc.addDays and daysEnding', () {
    test('addDays steps forward and back to local midnight', () {
      expect(
        CalendarDayCalc.addDays(DateTime(2026, 6, 15), -6),
        DateTime(2026, 6, 9),
      );
      expect(
        CalendarDayCalc.addDays(DateTime(2026, 6, 15), 20),
        DateTime(2026, 7, 5),
      );
      expect(
        CalendarDayCalc.addDays(DateTime(2026, 6, 15, 18, 30), 0),
        DateTime(2026, 6, 15),
        reason: 'the time of day is dropped',
      );
    });

    test('an empty range has no days', () {
      expect(CalendarDayCalc.daysEnding(DateTime(2026, 6, 15), 0), isEmpty);
      expect(CalendarDayCalc.daysEnding(DateTime(2026, 6, 15), -3), isEmpty);
    });

    test('a one-day range is just today at midnight', () {
      expect(CalendarDayCalc.daysEnding(DateTime(2026, 6, 15, 9), 1), [
        DateTime(2026, 6, 15),
      ]);
    });

    group(
      'across a fall-back and a spring-forward in one window',
      () {
        // 2025-10-05 .. 2026-04-02: Europe/Berlin fell back on 2025-10-26 and
        // springs forward on 2026-03-29, both inside these 180 days.
        final today = DateTime(2026, 4, 2);
        final days = CalendarDayCalc.daysEnding(today, 180);

        test('has every calendar day once, oldest first, at midnight', () {
          expect(days, hasLength(180));
          expect(days.first, DateTime(2025, 10, 5));
          expect(days.last, today);
          expect(days.toSet(), hasLength(180), reason: 'no day doubled');
          for (var i = 0; i < days.length; i++) {
            final d = days[i];
            expect(d.hour, 0, reason: '$d is not midnight');
            if (i > 0) {
              expect(
                CalendarDayCalc.daysBetween(days[i - 1], d),
                1,
                reason: 'a day is skipped before $d',
              );
            }
          }
          expect(days, contains(DateTime(2025, 10, 26)));
          expect(days, contains(DateTime(2026, 3, 29)));
        });

        test('addDays lands on midnight of the right day either side', () {
          expect(CalendarDayCalc.addDays(today, -6), DateTime(2026, 3, 27));
          expect(
            CalendarDayCalc.addDays(DateTime(2025, 10, 30), -6),
            DateTime(2025, 10, 24),
          );
          // The 24-hour form this replaces, for contrast.
          expect(
            today.subtract(const Duration(days: 6)),
            DateTime(2026, 3, 26, 23),
          );
          expect(
            DateTime(2025, 10, 30).subtract(const Duration(days: 6)),
            DateTime(2025, 10, 24, 1),
          );
        });
      },
      skip:
          _skipUnless(DateTime(2025, 10, 26), 25, 'autumn fall-back') ??
          _skipUnless(DateTime(2026, 3, 29), 23, 'spring-forward'),
    );
  });
}
