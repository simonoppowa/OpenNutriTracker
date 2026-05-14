import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';

class WeightLogEntity extends Equatable {
  final DateTime date;
  final double weightKg;
  final String? note;

  const WeightLogEntity({
    required this.date,
    required this.weightKg,
    this.note,
  });

  factory WeightLogEntity.fromWeightLogDBO(WeightLogDBO dbo) {
    return WeightLogEntity(
      date: dbo.date,
      weightKg: dbo.weightKg,
      note: dbo.note,
    );
  }

  @override
  List<Object?> get props => [date, weightKg, note];
}
