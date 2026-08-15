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

/// Which reader produced the rows on screen.
///
/// A bool would not survive the third case, and the third case is the one
/// that most needs saying out loud: rows read off a photograph rest on the
/// model having recognised the food correctly, with no typed text to check
/// it against.
enum BulkAddReadSource {
  /// The deterministic parser. Nothing to disclose — the user's own words,
  /// matched against the food database.
  parser,

  /// A model read the text the user typed.
  model,

  /// A model read a photograph.
  photo,
}

/// Why a photo could not be turned into rows.
///
/// Separate from [BulkAddErrorState] because the photo path has no
/// deterministic fallback, so its failures reach the user instead of being
/// absorbed — and each one wants different advice.
enum BulkAddPhotoError {
  /// No key stored, or the feature was switched off while the screen was
  /// open. A setting, not a fault.
  unavailable,

  /// The provider rejected the credential. "Try again later" is the wrong
  /// advice here and following it never stops being wrong.
  auth,

  /// No network, a rate limit, a provider error — worth another attempt.
  transient,

  /// The camera could not be opened, commonly because permission was denied.
  camera,

  /// The photo itself could not be encoded or was too large to send.
  unreadable,

  /// The configured model cannot read images at all. Sent to settings rather
  /// than offered a retry: nothing about trying again changes the answer.
  unsupported,
}

class BulkAddPhotoErrorState extends BulkAddState {
  final BulkAddPhotoError error;

  const BulkAddPhotoErrorState(this.error);

  @override
  List<Object?> get props => [error];
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

  /// What produced these rows. Surfaced so the user can see what they are
  /// being asked to confirm.
  final BulkAddReadSource source;

  /// Set when the model was asked, could not answer, and the reason will
  /// still be true tomorrow. The rows below are the parser's — this says why
  /// the better reader was not used, rather than withholding anything.
  final MealTextModelFailure? modelFailure;

  const BulkAddLoadedState({
    required this.rows,
    required this.parseErrors,
    required this.usesImperialUnits,
    this.source = BulkAddReadSource.parser,
    this.modelFailure,
  });

  Iterable<BulkAddRow> get loggableRows =>
      rows.where((row) => row.willBeLogged);

  int get loggableCount => loggableRows.length;

  bool get hasUnresolved => rows.any((row) => !row.isResolved);

  BulkAddLoadedState copyWith({List<BulkAddRow>? rows}) => BulkAddLoadedState(
    rows: rows ?? this.rows,
    parseErrors: parseErrors,
    usesImperialUnits: usesImperialUnits,
    source: source,
    modelFailure: modelFailure,
  );

  @override
  List<Object?> get props => [
    rows,
    parseErrors,
    usesImperialUnits,
    source,
    modelFailure,
  ];
}
