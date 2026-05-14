import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/settings/domain/usecase/download_sample_csv_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/download_sample_json_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_meals_csv_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_meals_json_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_recipes_csv_usecase.dart';

part 'export_import_event.dart';

part 'export_import_state.dart';

class ExportImportBloc extends Bloc<ExportImportEvent, ExportImportState> {
  static const exportZipFileName = 'opennutritracker-export.zip';
  static const userActivityJsonFileName = 'user_activity.json';
  static const userIntakeJsonFileName = 'user_intake.json';
  static const trackedDayJsonFileName = 'user_tracked_day.json';
  static const recipeJsonFileName = 'user_recipes.json';

  final ExportDataUsecase _exportDataUsecase;
  final ImportDataUsecase _importDataUsecase;
  final ImportMealsCsvUsecase _importMealsCsvUsecase;
  final ImportRecipesCsvUsecase _importRecipesCsvUsecase;
  final DownloadSampleCsvUsecase _downloadSampleCsvUsecase;
  final DownloadSampleJsonUsecase _downloadSampleJsonUsecase;
  final ImportMealsJsonUsecase _importMealsJsonUsecase;

  ExportImportBloc(
    this._exportDataUsecase,
    this._importDataUsecase,
    this._importMealsCsvUsecase,
    this._importRecipesCsvUsecase,
    this._downloadSampleCsvUsecase,
    this._downloadSampleJsonUsecase,
    this._importMealsJsonUsecase,
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
        );

        if (result) {
          emit(ExportImportSuccess());
        } else {
          emit(ExportImportInitial());
        }
      } catch (e) {
        emit(ExportImportError());
      }
    });

    on<ImportDataEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());

        final result = await _importDataUsecase.importData(
          userActivityJsonFileName,
          userIntakeJsonFileName,
          trackedDayJsonFileName,
          recipeJsonFileName,
        );
        if (result) {
          emit(ExportImportSuccess());
        } else {
          emit(ExportImportInitial());
        }
      } catch (e) {
        emit(ExportImportError());
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
      } catch (e) {
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
      } catch (e) {
        emit(CsvImportErrorState(e.toString()));
      }
    });

    on<DownloadSampleCsvEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());
        final saved = await _downloadSampleCsvUsecase.downloadSample();
        emit(saved ? ExportImportSuccess() : ExportImportInitial());
      } catch (e) {
        emit(ExportImportError());
      }
    });

    on<DownloadSampleRecipesCsvEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());
        final saved =
            await _downloadSampleCsvUsecase.downloadRecipeSample();
        emit(saved ? ExportImportSuccess() : ExportImportInitial());
      } catch (e) {
        emit(ExportImportError());
      }
    });

    on<DownloadSampleJsonEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());
        final saved = await _downloadSampleJsonUsecase.downloadSample();
        emit(saved ? ExportImportSuccess() : ExportImportInitial());
      } catch (e) {
        emit(ExportImportError());
      }
    });

    on<PasteJsonMealsEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());
        final result =
            await _importMealsJsonUsecase.importFromJsonString(event.jsonContent);
        if (result.imported == 0) {
          emit(JsonImportErrorState(result.errorMessages));
        } else {
          emit(JsonImportResultState(
            imported: result.imported,
            savedAsCustomMeals: result.savedAsCustomMeals,
            errorMessages: result.errorMessages,
          ));
        }
      } catch (e) {
        emit(JsonImportErrorState([e.toString()]));
      }
    });

    on<ResetExportImportStateEvent>((event, emit) {
      emit(ExportImportInitial());
    });
  }
}
