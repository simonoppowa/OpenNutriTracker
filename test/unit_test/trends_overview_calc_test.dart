import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/trends/presentation/trends_overview_calc.dart';

void main() {
  group('windowAverage', () {
    test('divides the values present by the window, as the card does', () {
      expect(windowAverage([1400, null, 700], 7), 300);
    });

    test('is 0 with no value present', () {
      expect(windowAverage([null, null], 7), 0);
      expect(windowAverage([], 30), 0);
    });

    test('is 0 for an empty window rather than dividing by zero', () {
      expect(windowAverage([100], 0), 0);
    });
  });

  group('averageGoal', () {
    test('averages the goals above zero', () {
      expect(averageGoal([2000, 0, 2400]), 2200);
    });

    test('is null when no day has a goal', () {
      expect(averageGoal([0, 0]), isNull);
      expect(averageGoal([]), isNull);
    });
  });

  group('waterAverageMl', () {
    // Midsummer: no clock change in the 30 days before it in common zones.
    final today = DateTime(2026, 6, 20);

    test('totals the window and divides by its days', () {
      final byDay = {
        DateTime(2026, 6, 20): 1400,
        DateTime(2026, 6, 14): 700,
        // The day before a 7-day window: left out.
        DateTime(2026, 6, 13): 5000,
      };
      expect(waterAverageMl(byDay, today, 7), 300);
    });

    test('rounds to the nearest ml', () {
      expect(waterAverageMl({DateTime(2026, 6, 20): 1000}, today, 3), 333);
      expect(waterAverageMl({DateTime(2026, 6, 20): 1001}, today, 2), 501);
    });

    test('is 0 with nothing logged in the window', () {
      expect(waterAverageMl({DateTime(2026, 1, 1): 900}, today, 7), 0);
      expect(waterAverageMl(const {}, today, 7), 0);
    });

    test('a 30-day window starts 29 days back', () {
      expect(waterAverageMl({DateTime(2026, 5, 22): 3000}, today, 30), 100);
      expect(waterAverageMl({DateTime(2026, 5, 21): 3000}, today, 30), 0);
    });

    test('gives the water card\'s number across a clock change', () {
      // A day logged every day, each a different amount, so a day dropped
      // or counted twice changes the result.
      final byDay = {
        for (var d = 0; d < 120; d++) DateTime(2026, 2, 1 + d): 100 + d,
        for (var d = 0; d < 60; d++) DateTime(2026, 9, 15 + d): 300 + d,
      };
      for (final today in [
        DateTime(2026, 3, 29),
        DateTime(2026, 3, 30),
        DateTime(2026, 4, 5),
        DateTime(2026, 10, 25),
        DateTime(2026, 10, 26),
        DateTime(2026, 11, 2),
      ]) {
        for (final windowDays in [7, 30]) {
          expect(
            waterAverageMl(byDay, today, windowDays),
            _cardAverageMl(byDay, today, windowDays),
            reason: '$windowDays days to $today',
          );
        }
      }
    });
  });
}

/// The water card's average as trends_page.dart's _WaterTrendCard computes
/// it, copied here so the tile is pinned to the card.
int _cardAverageMl(
  Map<DateTime, int> waterByDay,
  DateTime today,
  int rangeDays,
) {
  var sum = 0;
  var loggedDays = 0;
  for (int i = 0; i < rangeDays; i++) {
    final day = today.subtract(Duration(days: rangeDays - 1 - i));
    final ml = waterByDay[DateTime(day.year, day.month, day.day)] ?? 0;
    if (ml > 0) {
      sum += ml;
      loggedDays++;
    }
  }
  return loggedDays == 0 ? 0 : (sum / rangeDays).round();
}
