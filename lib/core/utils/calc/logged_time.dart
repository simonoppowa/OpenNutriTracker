/// The clock an entry was logged on, kept across a change of time zone
/// (#1309).
///
/// Hive stores a local `DateTime` as an instant and reads it back in the
/// device's current zone. Every day key — the Diary's listing, the
/// tracked-day row an entry's calories went to, Trends — is taken from
/// those local fields. An entry logged at 22:30 in UTC−3 is 03:30 the
/// next morning once the phone is set to UTC+2, so it moved to the next
/// day while its calories stayed on the row of the day it was logged on.
///
/// Entries now record the UTC offset of the zone they were logged in, and
/// every reader takes the date from the clock in that zone. An entry
/// stays on the calendar day it was logged on, wherever it is read.
///
/// Entries stored before the offset was recorded carry `null` and are
/// read in the current zone, as before: the zone they were logged in is
/// not known. A UTC value is a Diary day label, not a clock reading, and
/// is never shifted.
abstract final class LoggedTime {
  /// The offset to record for an entry stamped [moment]: the current
  /// zone's offset at that instant, or null for a UTC day label.
  static int? offsetOf(DateTime moment) =>
      moment.isUtc ? null : moment.timeZoneOffset.inMinutes;

  /// [stored]'s wall clock in the zone [loggedOffsetMinutes] was recorded
  /// in, for day keys: a UTC `DateTime` whose fields are that clock, so
  /// no lookup of the current zone is needed. Unchanged when there is no
  /// recorded offset, or [stored] is a UTC day label.
  static DateTime wallClock(DateTime stored, int? loggedOffsetMinutes) {
    if (stored.isUtc || loggedOffsetMinutes == null) return stored;
    return DateTime.fromMicrosecondsSinceEpoch(
      stored.microsecondsSinceEpoch +
          loggedOffsetMinutes * Duration.microsecondsPerMinute,
      isUtc: true,
    );
  }

  /// [stored]'s wall clock in the zone it was logged in, as a local
  /// `DateTime` of the current zone: the same date and time of day the
  /// entry was logged at. This is what entities carry, so the screens,
  /// and everything that groups entries by day, see the logged clock.
  ///
  /// Saved again, it records the current zone's offset, which reads back
  /// to the same wall clock.
  static DateTime localWallClock(DateTime stored, int? loggedOffsetMinutes) {
    if (stored.isUtc || loggedOffsetMinutes == null) return stored;
    if (stored.timeZoneOffset.inMinutes == loggedOffsetMinutes) return stored;
    final clock = wallClock(stored, loggedOffsetMinutes);
    return DateTime(
      clock.year,
      clock.month,
      clock.day,
      clock.hour,
      clock.minute,
      clock.second,
      clock.millisecond,
      clock.microsecond,
    );
  }
}
