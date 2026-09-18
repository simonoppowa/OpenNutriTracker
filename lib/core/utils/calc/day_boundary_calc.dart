import 'package:meta/meta.dart';

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
  /// The clock every "now" below reads.
  ///
  /// A boundary only misbehaves between midnight and the offset, so a
  /// test that reads the real clock silently proves nothing for most of
  /// the day — which is how the `…Today…` reads went a release without
  /// anyone noticing they asked for the wrong day (#586). Tests pin this
  /// and restore it; production never assigns it.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

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
      logicalDayOf(clock(), offsetHours);

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
      logicalDayOfMinutes(clock(), offsetTotalMinutes);

  /// Composes the hours + minutes pair the data layer passes around into
  /// the single total-minutes value the calculations below expect. A
  /// stored minute value outside 0-59 cannot inflate the total.
  static int totalMinutesOf(int offsetHours, int offsetMinutes) =>
      offsetHours * 60 + offsetMinutes.clamp(0, 59);

  /// The label of the logical day "now" falls in, from an hours +
  /// minutes pair.
  ///
  /// Queries that mean "today" must resolve the boundary *before* they
  /// filter, because the query itself takes a day label: on a 06:00
  /// boundary at 02:00, "today" is yesterday's label (#586).
  static DateTime currentLogicalDayLabel(int offsetHours, int offsetMinutes) =>
      currentLogicalDayMinutes(totalMinutesOf(offsetHours, offsetMinutes));

  /// True when the entry logged at [moment] belongs to the logical day
  /// labelled [dayLabel], given [offsetTotalMinutes].
  ///
  /// Use this — not [isSameLogicalDayMinutes] — whenever one side is a
  /// calendar date the user picked rather than a clock reading. A day
  /// label names a column in the diary; only its calendar date carries
  /// meaning, and applying the offset to it shifts the whole selection
  /// (#586: with a 06:00 boundary, tapping the 20th listed the 19th's
  /// entries, because subtracting six hours from midnight lands in the
  /// previous day). Only [moment] is resolved through the boundary.
  static bool isMomentInLogicalDayMinutes(
    DateTime dayLabel,
    DateTime moment,
    int? offsetTotalMinutes,
  ) {
    // Some stored entries are themselves labels rather than clock
    // readings, and must be compared as-is: rolling them back would file
    // them a day early. See [_isDayLabel] for who writes them.
    final momentDay = _isDayLabel(moment)
        ? moment
        : logicalDayOfMinutes(moment, offsetTotalMinutes);
    return momentDay.year == dayLabel.year &&
        momentDay.month == dayLabel.month &&
        momentDay.day == dayLabel.day;
  }

  /// True when [a] and [b] resolve to the same logical day under
  /// [offsetTotalMinutes].
  ///
  /// Both arguments must be real timestamps. If either is a user-picked
  /// calendar date, reach for [isMomentInLogicalDayMinutes] instead.
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
    final minutesSinceMidnight = moment.hour * 60 + moment.minute;
    final dayDelta = minutesSinceMidnight < totalMinutes ? -1 : 0;
    // The setting is a local wall-clock boundary, not an elapsed duration.
    // Stepping the calendar date avoids shifting an extra hour when a local
    // timezone enters or leaves daylight saving time.
    return DateTime(moment.year, moment.month, moment.day + dayDelta);
  }

  /// A bare midnight is how this app spells "the calendar day named
  /// y-m-d" (see [isMomentInLogicalDayMinutes]). Two writers produce
  /// one, in two different spellings:
  ///
  ///  * adding from the diary stamps the calendar cell itself —
  ///    table_calendar hands out `DateTime.utc(y, m, d)`, which
  ///    DayInfoWidget passes through AddMealScreenArguments into
  ///    MealDetailBloc.addIntake as the intake's `dateTime`;
  ///  * JsonMealImporter dates an entry `DateTime(y, m, d)` — *local*
  ///    midnight — from the optional `date` field (or today's date when
  ///    it is omitted), and CSV import can round-trip the same shape.
  ///
  /// Hence midnight, not the UTC flag, is the marker: keying off
  /// `isUtc` alone moved every date-only import back a day as soon as a
  /// boundary was configured. The cost is that a live entry logged at
  /// exactly 00:00:00.000000 local stays on its wall-clock day instead
  /// of rolling back; `DateTime.now()` carries microseconds, so that is
  /// a rounding error against mis-filing every import.
  static bool _isDayLabel(DateTime value) =>
      value.hour == 0 &&
      value.minute == 0 &&
      value.second == 0 &&
      value.millisecond == 0 &&
      value.microsecond == 0;

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
