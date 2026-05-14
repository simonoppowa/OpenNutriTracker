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

  group('DayBoundaryCalc.logicalDayOfMinutes (hour + minute companion)', () {
    // #139 follow-up: shift workers on 04:30 / 03:45 want their day to
    // actually start at that time. The total-minutes form lets the
    // hours and minutes fields compose without losing precision.
    test('4 hours + 0 minutes = 240 minutes total, same as offset-4 hours', () {
      // The composition contract: a clean 4-hour boundary expressed as
      // total minutes should resolve identically to the hour-only path.
      final moment = DateTime(2024, 1, 15, 1, 0);
      expect(
        DayBoundaryCalc.logicalDayOfMinutes(moment, 4 * 60),
        DayBoundaryCalc.logicalDayOf(moment, 4),
      );
      expect(
        DayBoundaryCalc.logicalDayOfMinutes(moment, 240),
        DateTime(2024, 1, 14),
      );
    });

    test('4 hours + 30 minutes = 270 minutes, snack at 04:15 is yesterday', () {
      // 04:30 is the new day, so 04:15 still belongs to the day before.
      // This is the exact scenario the follow-up exists to support.
      final snack = DateTime(2024, 1, 15, 4, 15);
      expect(
        DayBoundaryCalc.logicalDayOfMinutes(snack, 4 * 60 + 30),
        DateTime(2024, 1, 14),
      );
      // One minute past the boundary lands in today.
      final justAfter = DateTime(2024, 1, 15, 4, 31);
      expect(
        DayBoundaryCalc.logicalDayOfMinutes(justAfter, 4 * 60 + 30),
        DateTime(2024, 1, 15),
      );
    });

    test('0 hours + 15 minutes = 15 minutes, 00:10 rolls back', () {
      // A small minute-only offset is unusual but supported — a 00:15
      // boundary means anything before 00:15 is still yesterday.
      final lateNight = DateTime(2024, 1, 15, 0, 10);
      expect(
        DayBoundaryCalc.logicalDayOfMinutes(lateNight, 15),
        DateTime(2024, 1, 14),
      );
      final justAfter = DateTime(2024, 1, 15, 0, 20);
      expect(
        DayBoundaryCalc.logicalDayOfMinutes(justAfter, 15),
        DateTime(2024, 1, 15),
      );
    });

    test('total minutes out of range falls back to 0', () {
      // Defensive: negative or ≥ 24h values are a sign of corruption,
      // and we'd rather show wall-clock midnight than an impossible day.
      final moment = DateTime(2024, 1, 15, 2, 0);
      expect(
        DayBoundaryCalc.logicalDayOfMinutes(moment, -1),
        DateTime(2024, 1, 15),
      );
      expect(
        DayBoundaryCalc.logicalDayOfMinutes(moment, 24 * 60),
        DateTime(2024, 1, 15),
      );
      expect(
        DayBoundaryCalc.logicalDayOfMinutes(moment, null),
        DateTime(2024, 1, 15),
      );
    });

    test('isSameLogicalDayMinutes: 04:30 boundary groups 04:00 with previous '
        'evening', () {
      // The use case from the follow-up review: a hospitality worker
      // finishing at 04:00 wants that wind-down period filed with the
      // shift's evening meal, not the new day.
      final dinner = DateTime(2024, 1, 14, 21, 0);
      final wrapUp = DateTime(2024, 1, 15, 4, 0);
      expect(
        DayBoundaryCalc.isSameLogicalDayMinutes(dinner, wrapUp, 4 * 60 + 30),
        isTrue,
      );
    });
  });

  group('ConfigEntity-level clamping (via the minutes companion)', () {
    // The actual clamping happens at the entity boundary, but the
    // data-source code path also defends itself. This documents the
    // expected behaviour at the call-site level: a stored 99-minute
    // value should not be able to produce a > 23:59 total offset.
    test('clamped minute=99 inside data-source path resolves as 59', () {
      // The data sources apply `.clamp(0, 59)` to the minute parameter
      // before composing the total. With hours=4 and minutes=99, the
      // effective offset is 4*60 + 59 = 299 minutes, not 4*60 + 99.
      const hours = 4;
      const rawMinutes = 99;
      final clampedTotal = hours * 60 + rawMinutes.clamp(0, 59);
      expect(clampedTotal, 299);
      // And 04:30 still rolls back to yesterday under this offset.
      final moment = DateTime(2024, 1, 15, 4, 30);
      expect(
        DayBoundaryCalc.logicalDayOfMinutes(moment, clampedTotal),
        DateTime(2024, 1, 14),
      );
    });
  });
}
