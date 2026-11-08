import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';

class WeightLogEntity extends Equatable {
  final DateTime date;
  final double weightKg;
  final String? note;

  /// The day the entry is filed under in the log — the day of its storage
  /// key, as local midnight — or null for an entry not read from the log.
  ///
  /// Entries are keyed by the local day they were saved on, but [date] is
  /// read back in the current time zone: after a time-zone change it can
  /// show the day before or after. Finding the stored row again, to delete
  /// it, goes by this day, never by [date] (#1418).
  ///
  /// Not part of equality: it says where a reading is kept, not what it is.
  final DateTime? filedDay;

  const WeightLogEntity({
    required this.date,
    required this.weightKg,
    this.note,
    this.filedDay,
  });

  factory WeightLogEntity.fromWeightLogDBO(WeightLogDBO dbo) {
    return WeightLogEntity(
      date: dbo.date,
      weightKg: dbo.weightKg,
      note: dbo.note,
      filedDay: _dayOfKey(dbo.key),
    );
  }

  /// The day of a `yyyy-MM-dd` storage key, as local midnight. Null for an
  /// object that is not in a box, or a key that is not a day.
  static DateTime? _dayOfKey(Object? key) {
    final parsed = key is String ? DateTime.tryParse(key) : null;
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  @override
  List<Object?> get props => [date, weightKg, note];
}
