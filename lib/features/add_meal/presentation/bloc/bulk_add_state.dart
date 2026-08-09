part of 'bulk_add_bloc.dart';

abstract class BulkAddState extends Equatable {
  const BulkAddState();

  @override
  List<Object?> get props => [];
}

class BulkAddInitial extends BulkAddState {
  const BulkAddInitial();
}

class BulkAddLoadingState extends BulkAddState {
  const BulkAddLoadingState();
}

/// Resolution itself failed. Distinct from "resolved but matched nothing",
/// which is a normal outcome carried by unresolved rows.
class BulkAddErrorState extends BulkAddState {
  const BulkAddErrorState();
}

class BulkAddLoadedState extends BulkAddState {
  final List<BulkAddRow> rows;

  /// Per-segment complaints from the parser, already indexed ("Item 2: ...").
  /// Shown alongside the rows rather than replacing them — a line with one
  /// bad segment and three good ones should still log the three.
  final List<String> parseErrors;

  final bool usesImperialUnits;

  const BulkAddLoadedState({
    required this.rows,
    required this.parseErrors,
    required this.usesImperialUnits,
  });

  Iterable<BulkAddRow> get loggableRows =>
      rows.where((row) => row.willBeLogged);

  int get loggableCount => loggableRows.length;

  bool get hasUnresolved => rows.any((row) => !row.isResolved);

  BulkAddLoadedState copyWith({List<BulkAddRow>? rows}) => BulkAddLoadedState(
    rows: rows ?? this.rows,
    parseErrors: parseErrors,
    usesImperialUnits: usesImperialUnits,
  );

  @override
  List<Object?> get props => [rows, parseErrors, usesImperialUnits];
}
