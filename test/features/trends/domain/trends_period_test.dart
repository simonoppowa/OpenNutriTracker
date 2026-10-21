import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/trends/domain/trends_period.dart';

void main() {
  final today = DateTime(2026, 10, 21, 14, 30);

  group('last days', () {
    test('end today and reach back the number of days', () {
      final period = TrendsPeriod.lastDays(7, today: today);

      expect(period.start, DateTime(2026, 10, 15));
      expect(period.end, DateTime(2026, 10, 21));
      expect(period.days, 7);
      expect(period.endsToday(today), isTrue);
    });

    test('cannot be moved', () {
      expect(TrendsPeriod.lastDays(7, today: today).canStep, isFalse);
    });
  });

  group('calendar week', () {
    test('runs Monday to Sunday', () {
      final week = TrendsPeriod.week(today);

      expect(week.start, DateTime(2026, 10, 19));
      expect(week.end, DateTime(2026, 10, 25));
      expect(week.days, 7);
      expect(week.isoWeek, 43);
    });

    test('a Sunday belongs to the week before', () {
      expect(
        TrendsPeriod.week(DateTime(2026, 10, 18)).start,
        DateTime(2026, 10, 12),
      );
    });

    test('steps a week back and forth', () {
      final week = TrendsPeriod.week(today);

      expect(week.step(-1).start, DateTime(2026, 10, 12));
      expect(week.step(1).end, DateTime(2026, 11, 1));
    });

    test('the ISO week of a turn of the year', () {
      expect(TrendsPeriod.week(DateTime(2026, 12, 31)).isoWeek, 53);
      expect(TrendsPeriod.week(DateTime(2027, 1, 4)).isoWeek, 1);
      expect(TrendsPeriod.week(DateTime(2025, 12, 29)).isoWeek, 1);
    });

    test('across the clock change it still has seven days', () {
      final week = TrendsPeriod.week(DateTime(2026, 3, 25));

      expect(week.start, DateTime(2026, 3, 23));
      expect(week.end, DateTime(2026, 3, 29));
      expect(week.step(1).start, DateTime(2026, 3, 30));
    });
  });

  group('month', () {
    test('runs from the first to the last day', () {
      final month = TrendsPeriod.month(today);

      expect(month.start, DateTime(2026, 10, 1));
      expect(month.end, DateTime(2026, 10, 31));
      expect(month.days, 31);
    });

    test('steps over the year', () {
      final december = TrendsPeriod.month(DateTime(2026, 12, 5));

      expect(december.step(1).start, DateTime(2027, 1, 1));
      expect(
        TrendsPeriod.month(DateTime(2027, 1, 9)).step(-1).end,
        DateTime(2026, 12, 31),
      );
    });

    test('February of a leap year', () {
      expect(TrendsPeriod.month(DateTime(2028, 2, 10)).days, 29);
    });
  });

  group('custom', () {
    test('keeps its dates, in order', () {
      final period = TrendsPeriod.custom(
        DateTime(2026, 10, 10, 9),
        DateTime(2026, 10, 3),
      );

      expect(period.start, DateTime(2026, 10, 3));
      expect(period.end, DateTime(2026, 10, 10));
      expect(period.days, 8);
      expect(period.canStep, isFalse);
    });
  });

  test('a period in the future is not over yet', () {
    expect(TrendsPeriod.week(today).endsToday(today), isFalse);
    expect(
      TrendsPeriod.week(today).contains(DateTime(2026, 10, 25, 23)),
      isTrue,
    );
    expect(TrendsPeriod.week(today).contains(DateTime(2026, 10, 26)), isFalse);
  });
}
