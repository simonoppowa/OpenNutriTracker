part of 'scanner_bloc.dart';

@immutable
abstract class ScannerState extends Equatable {
  const ScannerState();
}

class ScannerInitial extends ScannerState {
  @override
  List<Object> get props => [];
}

class ScannerLoadingState extends ScannerState {
  @override
  List<Object?> get props => [];
}

class ScannerLoadedState extends ScannerState {
  final MealEntity product;
  final bool usesImperialUnits;

  const ScannerLoadedState({
    required this.product,
    this.usesImperialUnits = false,
  });

  @override
  List<Object?> get props => [product, usesImperialUnits];
}

class ScannerFailedState extends ScannerState {
  final ScannerFailedStateType type;

  const ScannerFailedState(this.type);

  // The type has to be part of equality. `emit` drops a state equal to the
  // current one, so leaving it out means a scan that fails a different way
  // than the last one keeps showing the old message. Nothing hits that today
  // because a loading state always separates two failures, but it is a quiet
  // trap to leave lying in the way of the next person here.
  @override
  List<Object?> get props => [type];
}

enum ScannerFailedStateType { productNotFound, error }
