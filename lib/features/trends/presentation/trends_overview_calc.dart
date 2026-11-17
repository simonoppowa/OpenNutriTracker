// Pure helpers behind the Trends overview tiles. They divide the way the
// cards on the tiles' pages do, so a tile and its page show one number.

/// The per-day average of [values] over a window of [windowDays] days, as the
/// Daily average card computes it: a day without a value counts as zero, and
/// the result is 0 when no value is present.
double windowAverage(Iterable<double?> values, int windowDays) {
  final present = values.whereType<double>().toList();
  if (present.isEmpty || windowDays <= 0) return 0;
  return present.reduce((a, b) => a + b) / windowDays;
}

/// The mean of the [goals] above zero, as the calorie chart's dashed goal
/// line is drawn; null when no day has a goal.
double? averageGoal(Iterable<double> goals) {
  final set = goals.where((g) => g > 0).toList();
  if (set.isEmpty) return null;
  return set.reduce((a, b) => a + b) / set.length;
}

/// The average water a day in ml over the [windowDays] days ending [today],
/// as the water card's header shows it: the window's total over its days,
/// 0 when nothing was logged.
int waterAverageMl(Map<DateTime, int> byDay, DateTime today, int windowDays) {
  // Steps back by Durations, as the water card does, so the tile shows the
  // card's number even on a clock-change day; fix both together.
  var sum = 0;
  var loggedDays = 0;
  for (var i = 0; i < windowDays; i++) {
    final day = today.subtract(Duration(days: windowDays - 1 - i));
    final ml = byDay[DateTime(day.year, day.month, day.day)] ?? 0;
    if (ml > 0) {
      sum += ml;
      loggedDays++;
    }
  }
  return loggedDays == 0 ? 0 : (sum / windowDays).round();
}
