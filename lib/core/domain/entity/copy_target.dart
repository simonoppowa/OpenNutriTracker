import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

/// Where copied diary entries go (#40): the logical day labelled [day] and,
/// for intakes, the meal [type] (null keeps each entry's own).
class CopyTarget extends Equatable {
  final DateTime day;
  final IntakeTypeEntity? type;

  const CopyTarget({required this.day, this.type});

  @override
  List<Object?> get props => [day, type];
}
