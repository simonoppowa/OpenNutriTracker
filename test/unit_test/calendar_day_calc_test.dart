import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/calendar_day_calc.dart';

// #1207: the weight-trend chart maps one calendar day to one x unit, so
// day arithmetic must not depend on how many hours a day actually had.
//
// Dart's DateTime only knows the process zone and UTC — there is no way to
// build a local date in a zone the test picks — so the DST cases can only
// run under a zone that has the transition (`TZ=Europe/Berlin flutter test
// …`). CI runs in UTC; there the DST groups skip with a reason instead of
// passing vacuously.

/// Hours in the local calendar day that starts at [day]'s midnight: 24
/// normally, 25 on an autumn fall-back day, 23 on a spring-forward day.
int _hoursIn(DateTime day) =>
    DateTime(day.year, day.month, day.day + 1).difference(day).inHours;

String? _skipUnless(DateTime day, int hours, String what) =>
    _hoursIn(day) == hours
    ? null
    : 'no $what on $day in zone ${day.timeZoneName}; '
          'run with TZ=Europe/Berlin';

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
}
