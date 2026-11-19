import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/medication_dbo.dart';

class MedicationEntity extends Equatable {
  final String id;
  final DateTime day;
  final String name;
  final double amount;
  final String unit; // 'mL', 'mg', 'mcg'
  final bool taken;

  const MedicationEntity({
    required this.id,
    required this.day,
    required this.name,
    required this.amount,
    required this.unit,
    required this.taken,
  });

  factory MedicationEntity.fromMedicationDBO(MedicationDBO dbo) {
    return MedicationEntity(
      id: dbo.id,
      day: dbo.day,
      name: dbo.name,
      amount: dbo.amount,
      unit: dbo.unit,
      taken: dbo.taken,
    );
  }

  MedicationEntity copyWith({
    String? id,
    DateTime? day,
    String? name,
    double? amount,
    String? unit,
    bool? taken,
  }) {
    return MedicationEntity(
      id: id ?? this.id,
      day: day ?? this.day,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      taken: taken ?? this.taken,
    );
  }

  @override
  List<Object?> get props => [id, day, name, amount, unit, taken];
}
