/// What a [TrendsPeriod] covers.
enum TrendsPeriodKind { lastDays, week, month, custom }

/// A span of whole days the trends show (#57): the last N days, a calendar
/// week (Monday to Sunday), a month, or dates the user picked. [start] and
/// [end] are midnight of the first and the last day, both included. Weeks and
/// months step back and forth; days are counted as calendar days, so a clock
/// change does not shorten a period.
class TrendsPeriod {
  final TrendsPeriodKind kind;
  final DateTime start;
  final DateTime end;

  const TrendsPeriod._(this.kind, this.start, this.end);

  /// The [count] days up to and including [today].
  factory TrendsPeriod.lastDays(int count, {required DateTime today}) =>
      TrendsPeriod._(
        TrendsPeriodKind.lastDays,
        DateTime(today.year, today.month, today.day - (count - 1)),
        _date(today),
      );

  /// The Monday to Sunday week containing [day].
  factory TrendsPeriod.week(DateTime day) {
    final monday = DateTime(day.year, day.month, day.day - (day.weekday - 1));
    return TrendsPeriod._(
      TrendsPeriodKind.week,
      monday,
      DateTime(monday.year, monday.month, monday.day + 6),
    );
  }

  /// The calendar month containing [day].
  factory TrendsPeriod.month(DateTime day) => TrendsPeriod._(
    TrendsPeriodKind.month,
    DateTime(day.year, day.month),
    DateTime(day.year, day.month + 1, 0),
  );

  /// The days from [a] to [b], whichever comes first.
  factory TrendsPeriod.custom(DateTime a, DateTime b) {
    final first = _date(a);
    final last = _date(b);
    return last.isBefore(first)
        ? TrendsPeriod._(TrendsPeriodKind.custom, last, first)
        : TrendsPeriod._(TrendsPeriodKind.custom, first, last);
  }

  static DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The number of days, both ends included.
  int get days =>
      DateTime.utc(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
      1;

  /// Whether [step] moves the period: weeks and months only.
  bool get canStep =>
      kind == TrendsPeriodKind.week || kind == TrendsPeriodKind.month;

  /// The week or month [by] steps later (negative: earlier).
  TrendsPeriod step(int by) => switch (kind) {
    TrendsPeriodKind.week => TrendsPeriod.week(
      DateTime(start.year, start.month, start.day + 7 * by),
    ),
    TrendsPeriodKind.month => TrendsPeriod.month(
      DateTime(start.year, start.month + by),
    ),
    _ => this,
  };

  /// The ISO 8601 number of a week period, taken from its Thursday.
  int get isoWeek {
    final thursday = DateTime(start.year, start.month, start.day + 3);
    final dayOfYear = DateTime.utc(
      thursday.year,
      thursday.month,
      thursday.day,
    ).difference(DateTime.utc(thursday.year)).inDays;
    return dayOfYear ~/ 7 + 1;
  }

  /// Whether [moment] falls on one of the period's days.
  bool contains(DateTime moment) {
    final day = _date(moment);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  /// Whether the period's last day is [today].
  bool endsToday(DateTime today) => end == _date(today);

  @override
  bool operator ==(Object other) =>
      other is TrendsPeriod &&
      other.kind == kind &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(kind, start, end);
}
