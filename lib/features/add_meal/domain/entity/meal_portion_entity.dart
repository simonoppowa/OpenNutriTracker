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
    this.englishLabel,
  });

  /// As published, count and all — "1 cup", "1 Tasse", "1 cup, cooked".
  final String label;

  /// The English `portion_description` the record carries, whatever [label]
  /// arrived as — "1 medium or regular slice" beside a verified
  /// "1 mittlere oder normale Scheibe".
  ///
  /// A matching key, never a presentation string. A model names a portion
  /// in English in every locale (#1157), so this is what its word is tried
  /// against; the reader still sees [label], and the typed path still
  /// matches the user's own words against [label] as before. Null while the
  /// backend does not send it — the column is added beside the coalesced
  /// label, and an app built before it must keep working — in which case
  /// the matcher falls back to [label], which in eight of nine locales is
  /// the English string anyway.
  final String? englishLabel;

  /// What one of these weighs. Always greater than zero: the backend drops
  /// portions that cannot scale an amount, because offering one would put a
  /// unit on the screen that multiplies to nothing.
  final double gramWeight;

  /// True when [label] came from a translation a human verified.
  final bool localized;

  @override
  List<Object?> get props => [label, gramWeight, localized, englishLabel];
}
