import 'package:equatable/equatable.dart';

/// One way a food can be counted, with the weight that makes it scalable.
///
/// A food usually has several — 3,499 of the backend's foods carry two or
/// more, up to fifteen — and the app showed exactly one until now: whichever
/// `food_summary` picked, which is the lowest `seq_num`.
///
/// [label] is what the reader sees and [localized] says whether it is in
/// their language or the English the record carries. The two are
/// indistinguishable as strings, and showing the English one to a German
/// reader is the defect #966 gated against, so the answer travels beside the
/// text rather than being inferred from it.
///
/// Not persisted. A meal read back from the database has no portions, which
/// is the honest answer: nothing stores them, and the amount was converted to
/// grams before it was written.
class MealPortionEntity extends Equatable {
  const MealPortionEntity({
    required this.label,
    required this.gramWeight,
    required this.localized,
  });

  /// As published, count and all — "1 cup", "1 Tasse", "1 cup, cooked".
  final String label;

  /// What one of these weighs. Always greater than zero: the backend drops
  /// portions that cannot scale an amount, because offering one would put a
  /// unit on the screen that multiplies to nothing.
  final double gramWeight;

  /// True when [label] came from a translation a human verified.
  final bool localized;

  @override
  List<Object?> get props => [label, gramWeight, localized];
}
