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
