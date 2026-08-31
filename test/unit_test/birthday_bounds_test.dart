import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/bounds/ranges_const.dart';
import 'package:opennutritracker/core/utils/bounds/validator.dart';

/// Birthday bounds: the picker used to open on yesterday and accept any age,
/// and the profile screen accepted dates as far out as 2100. These pin the
/// replacement rules down.
void main() {
  group('ageInYears', () {
    final now = DateTime(2026, 8, 1);

    test('counts completed years', () {
      expect(ValueValidator.ageInYears(DateTime(1996, 8, 1), now: now), 30);
    });

    test('does not count a birthday that has not come round yet', () {
      expect(ValueValidator.ageInYears(DateTime(1996, 8, 2), now: now), 29);
    });

    test('counts the birthday itself on the day', () {
      expect(ValueValidator.ageInYears(DateTime(2013, 8, 1), now: now), 13);
    });

    test('handles a birthday earlier in the same month', () {
      expect(ValueValidator.ageInYears(DateTime(2000, 7, 31), now: now), 26);
    });

    test('handles a 29 February birthday in a non-leap year', () {
      expect(ValueValidator.ageInYears(DateTime(2000, 2, 29), now: now), 26);
    });
  });

  group('getLastDate', () {
    test('is exactly minAgeYears before today', () {
      final now = DateTime(2026, 8, 1);
      expect(
        ValueValidator.getLastDate(now: now),
        DateTime(2026 - Ranges.minAgeYears, 8, 1),
      );
    });

    test('rejects a future birthday by construction', () {
      expect(ValueValidator.getLastDate().isBefore(DateTime.now()), isTrue);
    });

    test('a leap day does not hand out an extra day of slack', () {
      // 2028 is a leap year, 2015 is not. Left to normalise, Feb 29 2015
      // becomes Mar 1 2015 — a birthday that is still 12 by the count in
      // ageInYears, so the picker would offer a date the app rejects.
      final leapDay = DateTime(2028, 2, 29);
      final last = ValueValidator.getLastDate(now: leapDay);

      expect(last, DateTime(2015, 2, 28));
      expect(
        ValueValidator.ageInYears(last, now: leapDay),
        Ranges.minAgeYears,
        reason: 'the latest offered birthday must actually be old enough',
      );
    });

    test('someone turning 13 today is exactly at the boundary', () {
      final now = DateTime(2026, 8, 1);
      final thirteenToday = DateTime(2013, 8, 1);
      expect(ValueValidator.getLastDate(now: now), thirteenToday);
      expect(
        ValueValidator.ageInYears(thirteenToday, now: now),
        Ranges.minAgeYears,
      );
    });
  });

  group('isUnderAdultAge', () {
    final now = DateTime(2026, 8, 1);

    test('13 is under adult age', () {
      expect(
        ValueValidator.isUnderAdultAge(DateTime(2013, 8, 1), now: now),
        isTrue,
      );
    });

    test('17 is under adult age', () {
      expect(
        ValueValidator.isUnderAdultAge(DateTime(2009, 8, 1), now: now),
        isTrue,
      );
    });

    // The boundary is 19, not legal adulthood: IOM 2005 p. 204 heads its
    // equations "ages 19 years and older", so an 18-year-old is still being
    // handed a formula published for someone older (#987).
    test('18 is under adult-equation age', () {
      expect(
        ValueValidator.isUnderAdultAge(DateTime(2008, 8, 1), now: now),
        isTrue,
      );
    });

    test('19 today is not', () {
      expect(
        ValueValidator.isUnderAdultAge(DateTime(2007, 8, 1), now: now),
        isFalse,
      );
    });

    test('one day short of 19 still is', () {
      expect(
        ValueValidator.isUnderAdultAge(DateTime(2007, 8, 2), now: now),
        isTrue,
      );
    });
  });

  group('getInitialBirthdayDate', () {
    test('is 30 years back and inside the accepted range', () {
      final now = DateTime(2026, 8, 1);
      final initial = ValueValidator.getInitialBirthdayDate(now: now);

      expect(initial, DateTime(1996, 8, 1));
      expect(initial.isAfter(ValueValidator.getFirstDate(now: now)), isTrue);
      expect(initial.isBefore(ValueValidator.getLastDate(now: now)), isTrue);
    });
  });

  group('clampBirthday', () {
    final now = DateTime(2026, 8, 1);

    test('leaves an in-range birthday untouched', () {
      final birthday = DateTime(1990, 3, 4);
      expect(ValueValidator.clampBirthday(birthday, now: now), birthday);
    });

    test('pulls a too-young birthday back to the boundary', () {
      // Reachable from an older build, whose profile picker accepted
      // anything up to the year 2100.
      final clamped = ValueValidator.clampBirthday(
        DateTime(2099, 1, 1),
        now: now,
      );
      expect(clamped, ValueValidator.getLastDate(now: now));
    });

    test('pushes an implausibly old birthday up to the first date', () {
      final clamped = ValueValidator.clampBirthday(
        DateTime(1800, 1, 1),
        now: now,
      );
      expect(clamped, ValueValidator.getFirstDate(now: now));
    });
  });
}
