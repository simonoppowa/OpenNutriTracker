part of 'export_import_bloc.dart';

abstract class ExportImportEvent extends Equatable {
  const ExportImportEvent();
}

class ExportDataEvent extends ExportImportEvent {
  @override
  List<Object?> get props => [];
}

class ImportDataEvent extends ExportImportEvent {
  @override
  List<Object?> get props => [];
}

/// User picked a CSV file to import as custom meals.
class ImportMealsCsvEvent extends ExportImportEvent {
  @override
  List<Object?> get props => [];
}

/// User picked a CSV file to import as recipes.
class ImportRecipesCsvEvent extends ExportImportEvent {
  @override
  List<Object?> get props => [];
}

/// User asked for a custom-meal CSV template to fill in.
class DownloadSampleCsvEvent extends ExportImportEvent {
  @override
  List<Object?> get props => [];
}

/// User asked for a recipe CSV template to fill in.
class DownloadSampleRecipesCsvEvent extends ExportImportEvent {
  @override
  List<Object?> get props => [];
}

/// User asked for a custom-meals JSON template to fill in.
class DownloadSampleJsonEvent extends ExportImportEvent {
  @override
  List<Object?> get props => [];
}

/// User asked for a recipe JSON template to fill in.
class DownloadSampleRecipesJsonEvent extends ExportImportEvent {
  @override
  List<Object?> get props => [];
}

/// User picked a JSON file to import as custom meals (#181).
class ImportMealsJsonEvent extends ExportImportEvent {
  @override
  List<Object?> get props => [];
}

/// User picked a JSON file to import as recipes.
class ImportRecipesJsonEvent extends ExportImportEvent {
  @override
  List<Object?> get props => [];
}

/// Reset the bloc state — used when the Import dialog flips between CSV
/// and JSON segments so stale success/error chrome doesn't bleed across.
class ResetExportImportStateEvent extends ExportImportEvent {
  @override
  List<Object?> get props => [];
}
