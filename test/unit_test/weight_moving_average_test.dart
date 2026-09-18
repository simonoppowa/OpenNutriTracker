import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/utils/calc/weight_moving_average.dart';

// #1119: rolling-mean smoothing for the weight-trend chart. The user's
// week-over-week direction is what a rolling average is supposed to make
// visible; day-to-day water swings are what it should hide.

WeightLogEntity _entry(DateTime date, double weightKg) =>
    WeightLogEntity(date: date, weightKg: weightKg);

void main() {
  group('WeightMovingAverage', () {
    test(
      'trailing window of consecutive daily readings lands the arithmetic mean',
      () {
        final entries = [
          _entry(DateTime(2026, 1, 1), 80),
          _entry(DateTime(2026, 1, 2), 80.5),
          _entry(DateTime(2026, 1, 3), 79.2),
          _entry(DateTime(2026, 1, 4), 80.1),
          _entry(DateTime(2026, 1, 5), 79.7),
          _entry(DateTime(2026, 1, 6), 79.5),
          _entry(DateTime(2026, 1, 7), 79.3),
        ];

        final points = const WeightMovingAverage().compute(entries);

        // Full 7-day window on the last entry: mean of the seven readings.
        expect(points.last.date, DateTime(2026, 1, 7));
        expect(points.last.weightKg, closeTo(79.7571428, 1e-6));
        expect(points.last.sampleCount, 7);
      },
    );

    test('drops points backed by fewer than minSamples entries', () {
      final entries = [
        _entry(DateTime(2026, 1, 1), 70),
      ];

      // The default minSamples of 2 means a single reading in the window is
      // never a "smoothed" point — the line only starts once smoothing kicks in.
      expect(const WeightMovingAverage().compute(entries), isEmpty);
    });

    test(
      'entries outside the trailing window are excluded, and the sample '
      'count only counts what falls inside',
      () {
        final entries = [
          _entry(DateTime(2026, 1, 1), 100), // 9 days before the anchor
          _entry(DateTime(2026, 1, 4), 90), // 6 days before
          _entry(DateTime(2026, 1, 10), 80), // anchor
        ];

        // Window on the anchor: [2026-01-04 .. 2026-01-10], which excludes
        // Jan 1 and includes Jan 4. Mean over the two entries in-window:
        // (90 + 80) / 2 = 85.
        final points = const WeightMovingAverage().compute(entries);
        expect(points, hasLength(2));
        expect(points.last.date, DateTime(2026, 1, 10));
        expect(points.last.weightKg, 85);
        expect(points.last.sampleCount, 2);
      },
    );

    test('two entries on the same day both count toward every window '
        'that day is in', () {
      final entries = [
        _entry(DateTime(2026, 1, 1, 7), 80),
        _entry(DateTime(2026, 1, 1, 20), 81),
        _entry(DateTime(2026, 1, 2, 7), 80.5),
      ];

      final points = const WeightMovingAverage().compute(entries);

      // Second entry on Jan 1: (80 + 81) / 2 = 80.5
      expect(points[0].weightKg, closeTo(80.5, 1e-9));
      expect(points[0].sampleCount, 2);
      // Jan 2: all three fold in — (80 + 81 + 80.5) / 3.
      expect(points.last.weightKg, closeTo(80.5, 1e-9));
      expect(points.last.sampleCount, 3);
    });

    test('unsorted input is sorted before computing', () {
      final chronological = [
        _entry(DateTime(2026, 1, 1), 70),
        _entry(DateTime(2026, 1, 2), 71),
        _entry(DateTime(2026, 1, 3), 72),
      ];
      final shuffled = [chronological[2], chronological[0], chronological[1]];

      final sorted = const WeightMovingAverage().compute(chronological);
      final fromShuffled = const WeightMovingAverage().compute(shuffled);

      expect(
        fromShuffled.map((p) => (p.date, p.weightKg)).toList(),
        sorted.map((p) => (p.date, p.weightKg)).toList(),
      );
    });

    test('an empty log returns no points', () {
      expect(const WeightMovingAverage().compute(const []), isEmpty);
    });

    test(
      'boundary: entry exactly windowDays-1 before the anchor is included, '
      'one earlier is excluded',
      () {
        // 7-day window on a Jan 10 anchor spans Jan 4..Jan 10 inclusive.
        // Jan 4 (six days before) is inside; Jan 3 (seven days) is outside.
        final entries = [
          _entry(DateTime(2026, 1, 3), 100), // out
          _entry(DateTime(2026, 1, 4), 90), // in — window edge
          _entry(DateTime(2026, 1, 10), 80), // anchor
        ];

        final points = const WeightMovingAverage().compute(entries);

        expect(points.last.date, DateTime(2026, 1, 10));
        expect(points.last.sampleCount, 2);
        expect(points.last.weightKg, 85);
      },
    );

    test('windowDays honoured — a 3-day window ignores older readings', () {
      final entries = [
        _entry(DateTime(2026, 1, 1), 100),
        _entry(DateTime(2026, 1, 5), 80),
        _entry(DateTime(2026, 1, 6), 81),
        _entry(DateTime(2026, 1, 7), 79),
      ];

      final points = const WeightMovingAverage(windowDays: 3).compute(entries);

      // 3-day window on Jan 7 = [Jan 5 .. Jan 7]: 80, 81, 79 → mean 80.
      expect(points.last.date, DateTime(2026, 1, 7));
      expect(points.last.weightKg, 80);
      // Jan 1 sits before the [Jan 4..Jan 10] trailing window; excluded.
    });
  });
}
