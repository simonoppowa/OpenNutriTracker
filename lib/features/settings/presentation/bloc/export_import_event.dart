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

/// User pasted a JSON blob to log as one or more intakes (#181).
class PasteJsonMealsEvent extends ExportImportEvent {
  final String jsonContent;

  const PasteJsonMealsEvent(this.jsonContent);

  @override
  List<Object?> get props => [jsonContent];
}

/// Reset the bloc state — used when the paste-JSON sheet is reopened so
/// stale success/error chrome from a previous attempt doesn't bleed in.
class ResetExportImportStateEvent extends ExportImportEvent {
  @override
  List<Object?> get props => [];
}
