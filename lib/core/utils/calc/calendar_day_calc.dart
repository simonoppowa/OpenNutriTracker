/// Calendar-day arithmetic that survives daylight-saving transitions.
///
/// Weight entries are stored at local midnight and charted one calendar day
/// per x unit, so "how many days apart" has to count calendar days, not
/// elapsed 24-hour spans. `a.difference(b).inDays` truncates elapsed time:
/// across a spring-forward two local midnights N days apart measure
/// N*24 - 1 hours and come out as N-1, and a `Duration(days: N)` added to
/// or subtracted from a local midnight lands an hour off it on either side
/// of a transition (#1207).
class CalendarDayCalc {
  /// Whole calendar days from [from] to [to]; negative when [to] precedes
  /// [from]. Only the year/month/day of each argument is read — both are
  /// rebuilt in UTC, where every day is exactly 24 hours, before
  /// subtracting.
  static int daysBetween(DateTime from, DateTime to) {
    return DateTime.utc(
      to.year,
      to.month,
      to.day,
    ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
  }
}
