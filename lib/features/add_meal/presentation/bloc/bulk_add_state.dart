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

  /// Per-segment complaints from the parser, carrying the item number and
  /// the reason rather than a message — the string is built at the render
  /// site so it can be localized (#631). Shown alongside the rows rather
  /// than replacing them: a line with one bad segment and three good ones
  /// should still log the three.
  final List<MealTextParseError> parseErrors;

  final bool usesImperialUnits;

  /// True when a model read the line rather than the deterministic parser.
  /// Surfaced so the user can see what they are being asked to confirm.
  final bool readByModel;

  const BulkAddLoadedState({
    required this.rows,
    required this.parseErrors,
    required this.usesImperialUnits,
    this.readByModel = false,
  });

  Iterable<BulkAddRow> get loggableRows =>
      rows.where((row) => row.willBeLogged);

  int get loggableCount => loggableRows.length;

  bool get hasUnresolved => rows.any((row) => !row.isResolved);

  BulkAddLoadedState copyWith({List<BulkAddRow>? rows}) => BulkAddLoadedState(
    rows: rows ?? this.rows,
    parseErrors: parseErrors,
    usesImperialUnits: usesImperialUnits,
    readByModel: readByModel,
  );

  @override
  List<Object?> get props => [
    rows,
    parseErrors,
    usesImperialUnits,
    readByModel,
  ];
}
