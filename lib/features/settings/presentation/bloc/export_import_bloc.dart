import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';

part 'export_import_event.dart';

part 'export_import_state.dart';

class ExportImportBloc extends Bloc<ExportDataEvent, ExportImportState> {
  static const exportZipFileName = 'opennutritracker-export.zip';
  static const userActivityJsonFileName = 'user_activity.json';
  static const userIntakeJsonFileName = 'user_intake.json';
  static const trackedDayJsonFileName = 'user_tracked_day.json';

  final ExportDataUsecase _exportDataUsecase;

  ExportImportBloc(this._exportDataUsecase) : super(ExportImportInitial()) {
    on<ExportDataEvent>((event, emit) async {
      try {
        emit(ExportImportLoadingState());

        await _exportDataUsecase.exportData(
          exportZipFileName,
          userActivityJsonFileName,
          userIntakeJsonFileName,
          trackedDayJsonFileName,
        );

        emit(ExportImportSuccess());
      } catch (e) {
        emit(ExportImportError());
      }
    });
  }
}
