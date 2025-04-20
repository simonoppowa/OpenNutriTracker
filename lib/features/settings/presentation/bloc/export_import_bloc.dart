import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';

part 'export_import_event.dart';

part 'export_import_state.dart';

class ExportImportBloc extends Bloc<ExportImportEvent, ExportImportState> {
  static const exportZipFileName = 'opennutritracker-export.zip';
  static const userActivityJsonFileName = 'user_activity.json';
  static const userIntakeJsonFileName = 'user_intake.json';
  static const trackedDayJsonFileName = 'user_tracked_day.json';

  final ExportDataUsecase _exportDataUsecase;
  final ImportDataUsecase _importDataUsecase;

  ExportImportBloc(this._exportDataUsecase, this._importDataUsecase)
      : super(ExportImportInitial()) {
    on<ExportDataEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());

        final result = await _exportDataUsecase.exportData(
          exportZipFileName,
          userActivityJsonFileName,
          userIntakeJsonFileName,
          trackedDayJsonFileName,
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
            trackedDayJsonFileName);
        if (result) {
          emit(ExportImportSuccess());
        } else {
          emit(ExportImportInitial());
        }
      } catch (e) {
        emit(ExportImportError());
      }
    });
  }
}
