part of 'bulk_add_bloc.dart';

abstract class BulkAddEvent extends Equatable {
  const BulkAddEvent();

  @override
  List<Object?> get props => [];
}

class ParseBulkTextEvent extends BulkAddEvent {
  final String text;
  final bool usesImperialUnits;

  const ParseBulkTextEvent({
    required this.text,
    required this.usesImperialUnits,
  });

  @override
  List<Object?> get props => [text, usesImperialUnits];
}

class ChangeRowCandidateEvent extends BulkAddEvent {
  final int rowIndex;
  final int candidateIndex;

  const ChangeRowCandidateEvent(this.rowIndex, this.candidateIndex);

  @override
  List<Object?> get props => [rowIndex, candidateIndex];
}

class ChangeRowAmountEvent extends BulkAddEvent {
  final int rowIndex;
  final String amountText;

  const ChangeRowAmountEvent(this.rowIndex, this.amountText);

  @override
  List<Object?> get props => [rowIndex, amountText];
}

class ChangeRowUnitEvent extends BulkAddEvent {
  final int rowIndex;
  final String unit;

  const ChangeRowUnitEvent(this.rowIndex, this.unit);

  @override
  List<Object?> get props => [rowIndex, unit];
}

class ToggleRowSkippedEvent extends BulkAddEvent {
  final int rowIndex;

  const ToggleRowSkippedEvent(this.rowIndex);

  @override
  List<Object?> get props => [rowIndex];
}
