import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';

class WeightLogEntity extends Equatable {
  final DateTime date;
  final double weightKg;
  final String? note;

  /// Platform record id of an imported reading, null for a manual entry.
  final String? externalId;

  /// When an imported reading was taken, null for a manual entry.
  final DateTime? measuredAt;

  const WeightLogEntity({
    required this.date,
    required this.weightKg,
    this.note,
    this.externalId,
    this.measuredAt,
  });

  bool get isImported => externalId != null;

  /// When the reading was taken: [measuredAt] for an imported entry that
  /// recorded it, otherwise the start of its day, the earliest it can have
  /// been — which errs toward keeping a weight the user gave.
  DateTime get takenAt => measuredAt ?? date;

  /// The entry the user's current weight follows: the newest entry, with
  /// imported entries ordered by when they were taken rather than the day
  /// they are filed under (an entry keeps its day across a time-zone change,
  /// so a later reading can sit on an earlier date). A manual entry has only
  /// a day, so an imported one beats it only on a later day. Null for an
  /// empty log.
  ///
  /// The health weight import promotes this entry, and deleting it hands
  /// the current weight to whichever entry this picks next.
  static WeightLogEntity? newestOf(Iterable<WeightLogEntity> entries) {
    WeightLogEntity? newestImported;
    WeightLogEntity? newestManual;
    for (final entry in entries) {
      if (entry.isImported) {
        if (newestImported == null ||
            entry.takenAt.isAfter(newestImported.takenAt)) {
          newestImported = entry;
        }
      } else if (newestManual == null ||
          entry.date.isAfter(newestManual.date)) {
        newestManual = entry;
      }
    }
    if (newestImported == null) return newestManual;
    if (newestManual == null) return newestImported;
    return newestImported.date.isAfter(newestManual.date)
        ? newestImported
        : newestManual;
  }

  factory WeightLogEntity.fromWeightLogDBO(WeightLogDBO dbo) {
    return WeightLogEntity(
      date: dbo.date,
      weightKg: dbo.weightKg,
      note: dbo.note,
      externalId: dbo.externalId,
      measuredAt: dbo.measuredAt,
    );
  }

  @override
  List<Object?> get props => [date, weightKg, note, externalId, measuredAt];
}
