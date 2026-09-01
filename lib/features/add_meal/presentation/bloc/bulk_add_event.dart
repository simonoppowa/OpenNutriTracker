part of 'bulk_add_bloc.dart';

abstract class BulkAddEvent extends Equatable {
  const BulkAddEvent();

  @override
  List<Object?> get props => [];
}

class ParseBulkTextEvent extends BulkAddEvent {
  final String text;
  final bool usesImperialUnits;

  /// The app's language, passed to the model so food names come back in the
  /// language the food search is querying. Null leaves the model to infer it
  /// from the input.
  final String? localeCode;

  const ParseBulkTextEvent({
    required this.text,
    required this.usesImperialUnits,
    this.localeCode,
  });

  @override
  List<Object?> get props => [text, usesImperialUnits, localeCode];
}

/// Read an already-encoded photo.
///
/// Carries bytes rather than a path because picking and encoding are the
/// screen's job — they need a picker, a platform encoder and a
/// `BuildContext` — which keeps this bloc testable with a plain object and
/// keeps the photo out of any file the app owns.
class ReadMealPhotoEvent extends BulkAddEvent {
  final MealPhoto photo;
  final bool usesImperialUnits;

  /// The app's language, passed to the model so food names come back in the
  /// language the food search is querying.
  final String? localeCode;

  const ReadMealPhotoEvent({
    required this.photo,
    required this.usesImperialUnits,
    this.localeCode,
  });

  // The bytes are deliberately not compared: equality on a megabyte of image
  // would run on every rebuild to answer a question nothing asks.
  @override
  List<Object?> get props => [
    photo.mediaType,
    photo.bytes.length,
    usesImperialUnits,
    localeCode,
  ];
}

/// The photo never made it as far as the model — the picker threw, or the
/// encoder could not produce something sendable.
///
/// Routed through the bloc rather than shown as a snackbar from the screen so
/// that every way a photo can fail arrives in one place and reads the same.
/// A snackbar would also vanish while the previous batch of rows sat
/// underneath it, implying they came from the photo.
class ReadMealPhotoFailedEvent extends BulkAddEvent {
  final BulkAddPhotoError error;

  const ReadMealPhotoFailedEvent(this.error);

  @override
  List<Object?> get props => [error];
}

class ChangeRowCandidateEvent extends BulkAddEvent {
  final int rowIndex;
  final int candidateIndex;

  const ChangeRowCandidateEvent(this.rowIndex, this.candidateIndex);

  @override
  List<Object?> get props => [rowIndex, candidateIndex];
}

class ChangeRowAmountEvent extends BulkAddEvent {
  final int rowIndex;
  final String amountText;

  const ChangeRowAmountEvent(this.rowIndex, this.amountText);

  @override
  List<Object?> get props => [rowIndex, amountText];
}

class ChangeRowUnitEvent extends BulkAddEvent {
  final int rowIndex;
  final String unit;

  const ChangeRowUnitEvent(this.rowIndex, this.unit);

  @override
  List<Object?> get props => [rowIndex, unit];
}

class ToggleRowSkippedEvent extends BulkAddEvent {
  final int rowIndex;

  const ToggleRowSkippedEvent(this.rowIndex);

  @override
  List<Object?> get props => [rowIndex];
}
