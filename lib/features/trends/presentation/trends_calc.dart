// Pure helpers behind the Trends cards — kept Flutter-free so they can be
// unit-tested directly. The presentation layer decides what's "on track"
// (it needs theme colours) and hands the resulting date set in here.

import 'dart:math' as math;

/// Current and longest run of on-track days within [windowStart]..[today]
/// (both date-only, inclusive). A day not present in [onTrackDays] — whether
/// off-track or simply untracked — breaks the run. [current] counts the run
/// ending at [today]; if today isn't on track it's 0.
({int current, int longest}) streakStats(
  Set<DateTime> onTrackDays,
  DateTime windowStart,
  DateTime today,
) {
  final total = today.difference(windowStart).inDays;
  if (total < 0) return (current: 0, longest: 0);

  var longest = 0;
  var run = 0;
  for (var i = 0; i <= total; i++) {
    final day = DateTime(windowStart.year, windowStart.month, windowStart.day + i);
    if (onTrackDays.contains(day)) {
      run++;
      if (run > longest) longest = run;
    } else {
      run = 0;
    }
  }

  var current = 0;
  for (var i = 0; i <= total; i++) {
    final day = DateTime(today.year, today.month, today.day - i);
    if (onTrackDays.contains(day)) {
      current++;
    } else {
      break;
    }
  }

  return (current: current, longest: longest);
}

/// Linear trend through weight [points] (sorted ascending by date), returning
/// the weekly rate of change and, when a [targetKg] is set and the trend moves
/// toward it, a whole-week estimate of when it'll be reached.
///
/// Returns null when there's too little data (fewer than two points) to draw a
/// line. [weeksToTarget] is null when there's no target, the weight is flat, or
/// the trend is moving away from the target (so we don't promise a date the
/// user isn't heading for).
({double ratePerWeek, int? weeksToTarget})? weightProjection(
  List<({DateTime date, double kg})> points,
  double? targetKg,
) {
  if (points.length < 2) return null;

  final first = points.first.date;
  final xs = [
    for (final p in points) p.date.difference(first).inDays.toDouble(),
  ];
  final ys = [for (final p in points) p.kg];
  final n = points.length;
  final meanX = xs.reduce((a, b) => a + b) / n;
  final meanY = ys.reduce((a, b) => a + b) / n;

  var numerator = 0.0;
  var denominator = 0.0;
  for (var i = 0; i < n; i++) {
    numerator += (xs[i] - meanX) * (ys[i] - meanY);
    denominator += (xs[i] - meanX) * (xs[i] - meanX);
  }
  final slopePerDay = denominator == 0 ? 0.0 : numerator / denominator;
  final ratePerWeek = slopePerDay * 7;

  int? weeksToTarget;
  if (targetKg != null && slopePerDay.abs() > 1e-6) {
    final current = ys.last;
    final daysToTarget = (targetKg - current) / slopePerDay;
    // Only project when heading toward the target and within a sane horizon.
    if (daysToTarget > 0 && daysToTarget < 3650) {
      weeksToTarget = (daysToTarget / 7).ceil();
    }
  }

  return (ratePerWeek: ratePerWeek, weeksToTarget: weeksToTarget);
}

/// The y range a chart of [values] spans: a little under the lowest to a
/// little over the highest, so a period's changes fill the chart instead of
/// sitting on top of a bar from zero. Values that are all positive keep the
/// range at or above zero. [minSpan] keeps a flat period from stretching
/// tiny differences across the whole chart.
({double min, double max}) fittedRange(
  Iterable<double> values, {
  double minSpan = 1,
}) {
  if (values.isEmpty) return (min: 0, max: minSpan);
  final lo = values.reduce(math.min), hi = values.reduce(math.max);
  final pad = math.max(hi - lo, minSpan) * 0.15;
  return (min: lo >= 0 && lo - pad < 0 ? 0 : lo - pad, max: hi + pad);
}
