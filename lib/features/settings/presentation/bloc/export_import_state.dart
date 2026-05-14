part of 'export_import_bloc.dart';

abstract class ExportImportState extends Equatable {
  const ExportImportState();
}

class ExportImportInitial extends ExportImportState {
  @override
  List<Object?> get props => [];
}

class ExportImportLoadingState extends ExportImportState {
  @override
  List<Object?> get props => [];
}

class ExportImportSuccess extends ExportImportState {
  @override
  List<Object?> get props => [];
}

class ExportImportError extends ExportImportState {
  @override
  List<Object?> get props => [];
}

/// CSV import finished. [imported] is the number of meals saved;
/// [skipped] is the number of rows that failed validation;
/// [anyHadBarcode] is true when at least one imported meal had a barcode
/// (used to nudge the user to contribute back to Open Food Facts).
class CsvImportResultState extends ExportImportState {
  final int imported;
  final int skipped;
  final bool anyHadBarcode;

  const CsvImportResultState({
    required this.imported,
    required this.skipped,
    required this.anyHadBarcode,
  });

  @override
  List<Object?> get props => [imported, skipped, anyHadBarcode];
}

class CsvImportErrorState extends ExportImportState {
  final String message;

  const CsvImportErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

/// Result of a recipe CSV import. [imported] is the number of recipes saved;
/// [skipped] is the number of rows that failed validation.
class RecipeCsvImportResultState extends ExportImportState {
  final int imported;
  final int skipped;

  const RecipeCsvImportResultState({
    required this.imported,
    required this.skipped,
  });

  @override
  List<Object?> get props => [imported, skipped];
}

/// JSON meals import finished with at least one entry written (#181).
/// Symmetric with [CsvImportResultState]. [imported] is the number of
/// intakes saved; [savedAsCustomMeals] is how many of those entries also
/// landed in the saved-meals box (an import of an already-saved meal
/// name is deduped, so this count is <= imported); [errorMessages] is
/// the per-entry parse problems the user should see (may be empty).
class JsonImportResultState extends ExportImportState {
  final int imported;
  final int savedAsCustomMeals;
  final List<String> errorMessages;

  const JsonImportResultState({
    required this.imported,
    required this.savedAsCustomMeals,
    required this.errorMessages,
  });

  @override
  List<Object?> get props => [imported, savedAsCustomMeals, errorMessages];
}

/// JSON meals import produced no successful entries — every entry failed
/// validation or the JSON itself was malformed.
class JsonImportErrorState extends ExportImportState {
  final List<String> errorMessages;

  const JsonImportErrorState(this.errorMessages);

  @override
  List<Object?> get props => [errorMessages];
}

/// Result of a recipe JSON import. Mirrors [RecipeCsvImportResultState].
class RecipeJsonImportResultState extends ExportImportState {
  final int imported;
  final int skipped;
  final List<String> errorMessages;

  const RecipeJsonImportResultState({
    required this.imported,
    required this.skipped,
    required this.errorMessages,
  });

  @override
  List<Object?> get props => [imported, skipped, errorMessages];
}

/// Recipe JSON import produced no successful recipes.
class RecipeJsonImportErrorState extends ExportImportState {
  final List<String> errorMessages;

  const RecipeJsonImportErrorState(this.errorMessages);

  @override
  List<Object?> get props => [errorMessages];
}
