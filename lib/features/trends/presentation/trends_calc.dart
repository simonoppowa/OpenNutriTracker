// Pure helpers behind the Trends cards — kept Flutter-free so they can be
// unit-tested directly. The presentation layer decides what's "on track"
// (it needs theme colours) and hands the resulting date set in here.

import 'package:opennutritracker/core/utils/calc/calendar_day_calc.dart';

/// Current and longest run of on-track days within [windowStart]..[today]
/// (both date-only, inclusive). A day not present in [onTrackDays] — whether
/// off-track or simply untracked — breaks the run. [current] counts the run
/// ending at [today]; if today isn't on track it's 0.
({int current, int longest}) streakStats(
  Set<DateTime> onTrackDays,
  DateTime windowStart,
  DateTime today,
) {
  // Calendar days, not a 24-hour span: across a spring-forward the span is an
  // hour short and `.inDays` would drop today from the window (#1224).
  final total = CalendarDayCalc.daysBetween(windowStart, today);
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

  // One calendar day is one x unit, however many hours it had (#1224).
  final first = points.first.date;
  final xs = [
    for (final p in points)
      CalendarDayCalc.daysBetween(first, p.date).toDouble(),
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
