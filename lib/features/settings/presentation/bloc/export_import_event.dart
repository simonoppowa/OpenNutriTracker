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
