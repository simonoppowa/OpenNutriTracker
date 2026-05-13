import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';

void main() {
  group('DayBoundaryCalc.logicalDayOf', () {
    test('offset 0: midnight-exact rounds to the same wall-clock day', () {
      // The original behaviour, kept intact for everyone who has not
      // touched the new setting. A meal logged at 00:00:00 on Jan 15
      // belongs to Jan 15.
      final moment = DateTime(2024, 1, 15, 0, 0, 0);
      final logical = DayBoundaryCalc.logicalDayOf(moment, 0);
      expect(logical, DateTime(2024, 1, 15));
    });

    test('offset 0: late evening still rolls under today', () {
      // 23:59 with no offset is still today — this is the normal case
      // for anyone who has not set a custom boundary.
      final moment = DateTime(2024, 1, 15, 23, 59);
      final logical = DayBoundaryCalc.logicalDayOf(moment, 0);
      expect(logical, DateTime(2024, 1, 15));
    });

    test('offset 4: 01:00 resolves to the previous day', () {
      // The use case from the issue: a 01:00 snack while the user is
      // still up from the night before should file under yesterday's
      // diary, not the day that has technically just begun.
      final moment = DateTime(2024, 1, 15, 1, 0);
      final logical = DayBoundaryCalc.logicalDayOf(moment, 4);
      expect(logical, DateTime(2024, 1, 14));
    });

    test('offset 4: 05:00 resolves to today', () {
      // Once you cross the configured day boundary, you are firmly in
      // the new day. 05:00 with a 04:00 boundary is one hour into today.
      final moment = DateTime(2024, 1, 15, 5, 0);
      final logical = DayBoundaryCalc.logicalDayOf(moment, 4);
      expect(logical, DateTime(2024, 1, 15));
    });

    test('offset 4: 04:00 exact is the start of today (not the end of '
        'yesterday)', () {
      // The boundary itself is inclusive of the new day, so a 04:00
      // entry counts toward today.
      final moment = DateTime(2024, 1, 15, 4, 0);
      final logical = DayBoundaryCalc.logicalDayOf(moment, 4);
      expect(logical, DateTime(2024, 1, 15));
    });

    test('offset 4: 03:59 is the last minute of yesterday', () {
      final moment = DateTime(2024, 1, 15, 3, 59);
      final logical = DayBoundaryCalc.logicalDayOf(moment, 4);
      expect(logical, DateTime(2024, 1, 14));
    });

    test('mid-day entry stays in today for offsets at or below the hour', () {
      // A 14:00 entry resolves to today as long as the user's
      // configured boundary has already passed; at offset 12 we are
      // two hours into today, at offset 14 we would be on the cusp.
      final moment = DateTime(2024, 1, 15, 14, 0);
      for (final offset in [0, 1, 4, 8, 12]) {
        expect(
          DayBoundaryCalc.logicalDayOf(moment, offset),
          DateTime(2024, 1, 15),
          reason: 'offset=$offset',
        );
      }
      // At offset 15 or higher, 14:00 has not yet reached today's
      // boundary, so it still belongs to yesterday.
      expect(
        DayBoundaryCalc.logicalDayOf(moment, 15),
        DateTime(2024, 1, 14),
      );
    });

    test('offset 23: only the 23:00-23:59 window stays in today', () {
      // The extreme case: most of the calendar day belongs to "yesterday"
      // from the user's perspective. This is unusual but supported.
      expect(
        DayBoundaryCalc.logicalDayOf(DateTime(2024, 1, 15, 22, 59), 23),
        DateTime(2024, 1, 14),
      );
      expect(
        DayBoundaryCalc.logicalDayOf(DateTime(2024, 1, 15, 23, 0), 23),
        DateTime(2024, 1, 15),
      );
    });

    test('null offset behaves as 0 (no boundary configured yet)', () {
      // Fresh installs and existing users have no stored offset; null
      // should keep them on wall-clock midnight.
      final moment = DateTime(2024, 1, 15, 2, 0);
      expect(
        DayBoundaryCalc.logicalDayOf(moment, null),
        DateTime(2024, 1, 15),
      );
    });

    test('out-of-range offsets clamp to 0', () {
      // Defensive: a corrupt or hand-edited Hive value should not push
      // the diary into an impossible state. Anything outside 0-23 is
      // treated as the default.
      final moment = DateTime(2024, 1, 15, 2, 0);
      expect(
        DayBoundaryCalc.logicalDayOf(moment, -1),
        DateTime(2024, 1, 15),
      );
      expect(
        DayBoundaryCalc.logicalDayOf(moment, 24),
        DateTime(2024, 1, 15),
      );
      expect(
        DayBoundaryCalc.logicalDayOf(moment, 999),
        DateTime(2024, 1, 15),
      );
    });
  });

  group('DayBoundaryCalc.isSameLogicalDay', () {
    test('offset 0: behaves like wall-clock day equality', () {
      // A regression check — with no offset, the helper should be a
      // drop-in replacement for DateUtils.isSameDay.
      final a = DateTime(2024, 1, 15, 9, 0);
      final b = DateTime(2024, 1, 15, 23, 30);
      final c = DateTime(2024, 1, 16, 0, 30);
      expect(DayBoundaryCalc.isSameLogicalDay(a, b, 0), isTrue);
      expect(DayBoundaryCalc.isSameLogicalDay(a, c, 0), isFalse);
    });

    test('offset 4: a 02:00 snack matches the prior evening meal', () {
      // The exact scenario from #139 — a meal logged at 19:00 on Jan 14
      // and a snack logged at 02:00 on Jan 15 are the same logical day
      // under a 4-hour boundary.
      final dinner = DateTime(2024, 1, 14, 19, 0);
      final snack = DateTime(2024, 1, 15, 2, 0);
      expect(DayBoundaryCalc.isSameLogicalDay(dinner, snack, 4), isTrue);
    });

    test('offset 4: an entry just after the boundary is a new day', () {
      final lateLog = DateTime(2024, 1, 15, 3, 30);
      final earlyLog = DateTime(2024, 1, 15, 5, 30);
      expect(DayBoundaryCalc.isSameLogicalDay(lateLog, earlyLog, 4), isFalse);
    });
  });
}
