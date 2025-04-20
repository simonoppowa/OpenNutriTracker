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
