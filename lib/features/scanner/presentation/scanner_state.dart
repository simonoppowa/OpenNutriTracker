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

  const ScannerLoadedState(
      {required this.product, this.usesImperialUnits = false});

  @override
  List<Object?> get props => [product];
}

class ScannerFailedState extends ScannerState {
  final ScannerFailedStateType type;

  const ScannerFailedState(this.type);

  @override
  List<Object?> get props => [];
}

enum ScannerFailedStateType { productNotFound, error }
