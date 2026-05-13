/// Helper for the configurable diary day boundary (#139).
///
/// Some reporters live by a 04:00-to-04:00 day rather than the wall-clock
/// 00:00-to-00:00 one — night shifts, late-eaters, anyone for whom a 02:00
/// snack genuinely belongs to the same day as the evening meal that
/// preceded it. The user can pick an hour-of-day in Settings → Calculations
/// to shift the diary's day boundary; an entry logged before that hour
/// is filed under the previous wall-clock day.
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
    final hours = _sanitise(offsetHours);
    final shifted = moment.subtract(Duration(hours: hours));
    return DateTime(shifted.year, shifted.month, shifted.day);
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

  static int _sanitise(int? offsetHours) {
    if (offsetHours == null) return 0;
    if (offsetHours < 0 || offsetHours > 23) return 0;
    return offsetHours;
  }
}
