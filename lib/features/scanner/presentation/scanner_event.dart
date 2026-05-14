part of 'scanner_bloc.dart';

@immutable
abstract class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object?> get props => [];
}

class ScannerLoadProductEvent extends ScannerEvent {
  final String barcode;

  const ScannerLoadProductEvent({required this.barcode});

  @override
  List<Object?> get props => [barcode];
}

/// Fired when the user picks one recipe from the multi-match chooser sheet.
/// The bloc resolves the chosen recipe into the same loaded state the
/// single-match path would have emitted, so the downstream meal-detail
/// navigation is unchanged.
class ScannerRecipeChosenEvent extends ScannerEvent {
  final RecipeEntity recipe;

  const ScannerRecipeChosenEvent(this.recipe);

  @override
  List<Object?> get props => [recipe];
}
