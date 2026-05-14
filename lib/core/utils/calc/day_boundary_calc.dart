/// Helper for the configurable diary day boundary (#139).
///
/// Some reporters live by a 04:00-to-04:00 day rather than the wall-clock
/// 00:00-to-00:00 one — night shifts, late-eaters, anyone for whom a 02:00
/// snack genuinely belongs to the same day as the evening meal that
/// preceded it. The user can pick an hour-of-day (and, since the #139
/// follow-up, a minute-of-hour) in Settings → Calculations to shift the
/// diary's day boundary; an entry logged before that time is filed under
/// the previous wall-clock day.
///
/// The offset only affects which logical day an entry aggregates under.
/// Stored timestamps remain wall-clock (i.e. `DateTime.now()` at the time
/// the entry was created). Notification scheduling has its own timing
/// logic and is intentionally untouched here.
class DayBoundaryCalc {
  /// Returns the wall-clock midnight of the logical day that [moment]
  /// belongs to, given a configured [offsetHours] in the range 0–23.
  ///
  /// With offsetHours = 0 this is equivalent to stripping the time portion
  /// (the original behaviour). With offsetHours = 4, anything before 04:00
  /// rolls back to the previous wall-clock day's midnight.
  ///
  /// A null or out-of-range [offsetHours] is treated as 0 so existing
  /// users (and freshly upgraded ones with no stored value yet) keep the
  /// original behaviour without surprise.
  static DateTime logicalDayOf(DateTime moment, int? offsetHours) {
    final totalMinutes = _sanitiseHours(offsetHours) * 60;
    return _logicalDayOfTotalMinutes(moment, totalMinutes);
  }

  /// The logical day for "now", given the configured [offsetHours].
  static DateTime currentLogicalDay(int? offsetHours) =>
      logicalDayOf(DateTime.now(), offsetHours);

  /// True when [a] and [b] resolve to the same logical day under
  /// [offsetHours].
  static bool isSameLogicalDay(DateTime a, DateTime b, int? offsetHours) {
    final dayA = logicalDayOf(a, offsetHours);
    final dayB = logicalDayOf(b, offsetHours);
    return dayA.year == dayB.year &&
        dayA.month == dayB.month &&
        dayA.day == dayB.day;
  }

  /// Returns the wall-clock midnight of the logical day that [moment]
  /// belongs to, given a configured offset expressed as a single
  /// [offsetTotalMinutes] value — i.e. `hours * 60 + minutes`.
  ///
  /// This is the form the rest of the app should reach for once it has
  /// both the hours and minutes companion fields available. The
  /// hours-only overload above is retained so existing call sites
  /// remain valid; it simply delegates here with a multiplied value.
  ///
  /// Out-of-range values (negative, or ≥ 24 h) are treated as 0 — the
  /// same defensive behaviour as the hours-only overload.
  static DateTime logicalDayOfMinutes(DateTime moment, int? offsetTotalMinutes) {
    return _logicalDayOfTotalMinutes(
      moment,
      _sanitiseTotalMinutes(offsetTotalMinutes),
    );
  }

  /// The logical day for "now", given the configured [offsetTotalMinutes].
  static DateTime currentLogicalDayMinutes(int? offsetTotalMinutes) =>
      logicalDayOfMinutes(DateTime.now(), offsetTotalMinutes);

  /// True when [a] and [b] resolve to the same logical day under
  /// [offsetTotalMinutes].
  static bool isSameLogicalDayMinutes(
    DateTime a,
    DateTime b,
    int? offsetTotalMinutes,
  ) {
    final dayA = logicalDayOfMinutes(a, offsetTotalMinutes);
    final dayB = logicalDayOfMinutes(b, offsetTotalMinutes);
    return dayA.year == dayB.year &&
        dayA.month == dayB.month &&
        dayA.day == dayB.day;
  }

  static DateTime _logicalDayOfTotalMinutes(DateTime moment, int totalMinutes) {
    final shifted = moment.subtract(Duration(minutes: totalMinutes));
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  static int _sanitiseHours(int? offsetHours) {
    if (offsetHours == null) return 0;
    if (offsetHours < 0 || offsetHours > 23) return 0;
    return offsetHours;
  }

  static int _sanitiseTotalMinutes(int? offsetTotalMinutes) {
    if (offsetTotalMinutes == null) return 0;
    if (offsetTotalMinutes < 0 || offsetTotalMinutes >= 24 * 60) return 0;
    return offsetTotalMinutes;
  }
}
