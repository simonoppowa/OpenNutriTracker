import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';

/// One point on the weight-trend moving-average line.
class WeightMovingAveragePoint {
  /// The day the moving-average value is anchored to — always the date of
  /// an existing entry, so the smoothed line lands on the raw dots.
  final DateTime date;

  /// Mean weight in kilograms over the trailing [WeightMovingAverage.windowDays]
  /// (inclusive) ending on [date], across every entry that falls in that
  /// window.
  final double weightKg;

  /// How many raw entries were folded into this point. `1` means the
  /// window held only the anchor's own reading, so smoothing has not kicked
  /// in yet; the caller can drop those points to keep the line honest.
  final int sampleCount;

  const WeightMovingAveragePoint({
    required this.date,
    required this.weightKg,
    required this.sampleCount,
  });
}

/// Rolling-mean smoothing over a weight log.
///
/// Daily weigh-ins swing several kilograms with water alone, and a raw
/// line makes real trends hard to see (#1119). A trailing-window mean
/// keeps a point on every reading — so the smoothed line lines up with
/// the raw dots — but replaces its y-value with the mean of every entry
/// within [windowDays] ending on that date, inclusive on both ends. If
/// two entries share a day, both count toward every window they fall in;
/// the caller decides how to collapse same-day duplicates upstream.
class WeightMovingAverage {
  /// Number of calendar days the trailing window spans, inclusive of the
  /// anchor day. `7` averages "today plus the six days before".
  final int windowDays;

  const WeightMovingAverage({this.windowDays = 7})
      : assert(windowDays >= 2, 'windowDays must be at least 2 to smooth');

  /// Rolling mean over [entries]. Result mirrors the entries in date
  /// order; when [minSamples] is > 1, points backed by fewer readings
  /// than the threshold are dropped so the returned line only starts
  /// once the smoothing is meaningful.
  List<WeightMovingAveragePoint> compute(
    Iterable<WeightLogEntity> entries, {
    int minSamples = 2,
  }) {
    assert(minSamples >= 1, 'minSamples must be positive');
    final sorted = entries.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.isEmpty) return const [];

    final points = <WeightMovingAveragePoint>[];
    // Two-pointer sweep: `head` advances one step ahead of the anchor,
    // dropping entries that fall outside the trailing window as the
    // anchor moves forward. Each entry is visited at most twice, so this
    // stays O(n) regardless of how long the log gets.
    var head = 0;
    var sum = 0.0;
    for (var anchor = 0; anchor < sorted.length; anchor++) {
      final anchorDate = sorted[anchor].date;
      final windowStart = anchorDate.subtract(Duration(days: windowDays - 1));
      while (head <= anchor && sorted[head].date.isBefore(windowStart)) {
        sum -= sorted[head].weightKg;
        head++;
      }
      sum += sorted[anchor].weightKg;
      final samples = anchor - head + 1;
      if (samples >= minSamples) {
        points.add(WeightMovingAveragePoint(
          date: anchorDate,
          weightKg: sum / samples,
          sampleCount: samples,
        ));
      }
    }
    return points;
  }
}
