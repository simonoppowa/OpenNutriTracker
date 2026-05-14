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
  List<Object?> get props => [product];
}

/// More than one custom recipe matched the scanned barcode. The scanner
/// screen renders a chooser sheet from this state so the user can pick
/// which recipe they meant before the meal-detail flow continues.
class ScannerMultipleRecipesState extends ScannerState {
  final List<RecipeEntity> recipes;
  final bool usesImperialUnits;

  const ScannerMultipleRecipesState({
    required this.recipes,
    this.usesImperialUnits = false,
  });

  @override
  List<Object?> get props => [recipes, usesImperialUnits];
}

class ScannerFailedState extends ScannerState {
  final ScannerFailedStateType type;

  const ScannerFailedState(this.type);

  @override
  List<Object?> get props => [];
}

enum ScannerFailedStateType { productNotFound, error }
