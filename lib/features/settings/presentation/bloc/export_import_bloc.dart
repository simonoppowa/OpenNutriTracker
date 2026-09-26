import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/usecase/download_sample_csv_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/download_sample_json_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_meals_csv_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_meals_json_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_recipes_csv_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_recipes_json_usecase.dart';

part 'export_import_event.dart';

part 'export_import_state.dart';

class ExportImportBloc extends Bloc<ExportImportEvent, ExportImportState> {
  static const exportZipFileName = 'opennutritracker-export.zip';
  static const userActivityJsonFileName = 'user_activity.json';
  static const userIntakeJsonFileName = 'user_intake.json';
  static const trackedDayJsonFileName = 'user_tracked_day.json';
  static const recipeJsonFileName = 'user_recipes.json';
  static const weightLogJsonFileName = 'weight_log.json';
  // #70 follow-up: saved Custom activity templates (name + typical kcal).
  static const customActivityTemplateJsonFileName =
      'custom_activity_templates.json';

  static final _log = Logger('ExportImportBloc');

  final ExportDataUsecase _exportDataUsecase;
  final ImportDataUsecase _importDataUsecase;
  final ImportMealsCsvUsecase _importMealsCsvUsecase;
  final ImportRecipesCsvUsecase _importRecipesCsvUsecase;
  final DownloadSampleCsvUsecase _downloadSampleCsvUsecase;
  final DownloadSampleJsonUsecase _downloadSampleJsonUsecase;
  final ImportMealsJsonUsecase _importMealsJsonUsecase;
  final ImportRecipesJsonUsecase _importRecipesJsonUsecase;

  ExportImportBloc(
    this._exportDataUsecase,
    this._importDataUsecase,
    this._importMealsCsvUsecase,
    this._importRecipesCsvUsecase,
    this._downloadSampleCsvUsecase,
    this._downloadSampleJsonUsecase,
    this._importMealsJsonUsecase,
    this._importRecipesJsonUsecase,
  ) : super(ExportImportInitial()) {
    on<ExportDataEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());

        final result = await _exportDataUsecase.exportData(
          exportZipFileName,
          userActivityJsonFileName,
          userIntakeJsonFileName,
          trackedDayJsonFileName,
          recipeJsonFileName,
          weightLogJsonFileName,
          customActivityTemplateJsonFileName,
          format: event.format,
        );

        if (result) {
          emit(ExportImportSuccess());
        } else {
          emit(ExportImportInitial());
        }
      } catch (e, stackTrace) {
        emit(_failed('Export (${event.format.name})', e, stackTrace));
      }
    });

    on<ImportDataEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());

        final result = event.format == ExportFormat.csv
            ? await _importDataUsecase.importDataCsv()
            : await _importDataUsecase.importData(
                userActivityJsonFileName,
                userIntakeJsonFileName,
                trackedDayJsonFileName,
                recipeJsonFileName,
                weightLogJsonFileName,
                customActivityTemplateJsonFileName,
              );
        if (result) {
          emit(ExportImportSuccess());
        } else {
          emit(ExportImportInitial());
        }
      } catch (e, stackTrace) {
        emit(_failed('Import (${event.format.name})', e, stackTrace));
      }
    });

    on<ImportMealsCsvEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());
        final result = await _importMealsCsvUsecase.importFromPickedFile();
        if (result == null) {
          // User cancelled the file picker — go back to initial.
          emit(ExportImportInitial());
        } else {
          emit(CsvImportResultState(
            imported: result.imported,
            skipped: result.skipped,
            anyHadBarcode: result.anyImportedHadBarcode,
          ));
        }
      } catch (e, stackTrace) {
        _log.severe('Import meals CSV failed', e, stackTrace);
        emit(CsvImportErrorState(e.toString()));
      }
    });

    on<ImportRecipesCsvEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());
        final result = await _importRecipesCsvUsecase.importFromPickedFile();
        if (result == null) {
          emit(ExportImportInitial());
        } else {
          emit(RecipeCsvImportResultState(
            imported: result.imported,
            skipped: result.skippedRows,
          ));
        }
      } catch (e, stackTrace) {
        _log.severe('Import recipes CSV failed', e, stackTrace);
        emit(CsvImportErrorState(e.toString()));
      }
    });

    on<DownloadSampleCsvEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());
        final saved = await _downloadSampleCsvUsecase.downloadSample();
        emit(saved ? ExportImportSuccess() : ExportImportInitial());
      } catch (e, stackTrace) {
        emit(_failed('Download meals CSV sample', e, stackTrace));
      }
    });

    on<DownloadSampleRecipesCsvEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());
        final saved =
            await _downloadSampleCsvUsecase.downloadRecipeSample();
        emit(saved ? ExportImportSuccess() : ExportImportInitial());
      } catch (e, stackTrace) {
        emit(_failed('Download recipes CSV sample', e, stackTrace));
      }
    });

    on<DownloadSampleJsonEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());
        final saved = await _downloadSampleJsonUsecase.downloadSample();
        emit(saved ? ExportImportSuccess() : ExportImportInitial());
      } catch (e, stackTrace) {
        emit(_failed('Download meals JSON sample', e, stackTrace));
      }
    });

    on<ImportMealsJsonEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());
        final result = await _importMealsJsonUsecase.importFromPickedFile();
        if (result == null) {
          // User cancelled the file picker.
          emit(ExportImportInitial());
        } else if (result.imported == 0) {
          emit(JsonImportErrorState(result.errorMessages));
        } else {
          emit(JsonImportResultState(
            imported: result.imported,
            savedAsCustomMeals: result.savedAsCustomMeals,
            errorMessages: result.errorMessages,
          ));
        }
      } catch (e, stackTrace) {
        _log.severe('Import meals JSON failed', e, stackTrace);
        emit(JsonImportErrorState([e.toString()]));
      }
    });

    on<ImportRecipesJsonEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());
        final result = await _importRecipesJsonUsecase.importFromPickedFile();
        if (result == null) {
          emit(ExportImportInitial());
        } else if (result.imported == 0) {
          emit(RecipeJsonImportErrorState(result.errorMessages));
        } else {
          emit(RecipeJsonImportResultState(
            imported: result.imported,
            skipped: result.skippedRecipes,
            errorMessages: result.errorMessages,
          ));
        }
      } catch (e, stackTrace) {
        _log.severe('Import recipes JSON failed', e, stackTrace);
        emit(RecipeJsonImportErrorState([e.toString()]));
      }
    });

    on<DownloadSampleRecipesJsonEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());
        // Reuses the meals download usecase shape — recipes share the
        // same single-file save flow.
        final saved =
            await _downloadSampleJsonUsecase.downloadRecipeSample();
        emit(saved ? ExportImportSuccess() : ExportImportInitial());
      } catch (e, stackTrace) {
        emit(_failed('Download recipes JSON sample', e, stackTrace));
      }
    });

    on<ResetExportImportStateEvent>((event, emit) {
      emit(ExportImportInitial());
    });
  }

  /// The state to emit when [operation] threw [error].
  ///
  /// Every failure is logged with its stack trace — before #1103 these
  /// catch sites bound `e` and never read it, which left a bug report
  /// with nothing but "it says error". A dismissed picker is not a
  /// failure: it goes back to [ExportImportInitial], so the dialog shows
  /// its description again instead of an error row.
  ExportImportState _failed(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    if (error is ExportImportFailure) {
      if (error.reason == ExportImportFailureReason.cancelled) {
        _log.fine('$operation cancelled by the user');
        return ExportImportInitial();
      }
      _log.severe(
        '$operation failed (${error.reason.name})',
        error,
        stackTrace,
      );
      return ExportImportError(error.reason);
    }
    _log.severe('$operation failed (unexpected)', error, stackTrace);
    return const ExportImportError(ExportImportFailureReason.unexpected);
  }
}
