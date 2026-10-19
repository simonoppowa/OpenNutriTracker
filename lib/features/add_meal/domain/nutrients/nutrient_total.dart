/// A nutrient summed over several entries (a day, a week, a recipe's
/// ingredients) together with how many of them gave a value (#46), so a
/// total that nothing was known about reads "unknown" rather than 0, and
/// one that only some entries knew reads "at least".
class NutrientTotal {
  final double sum;
  final int knownEntries;
  final int unknownEntries;

  const NutrientTotal({
    required this.sum,
    required this.knownEntries,
    required this.unknownEntries,
  });

  static const empty = NutrientTotal(
    sum: 0,
    knownEntries: 0,
    unknownEntries: 0,
  );

  /// Sums `per100(item) × amountG(item) / 100` over [items], counting the
  /// items without a value, and divides the sum by [divisor] (7 for a
  /// weekly daily average).
  static NutrientTotal over<T>(
    Iterable<T> items, {
    required double? Function(T item) per100,
    required double Function(T item) amountG,
    double divisor = 1,
  }) {
    var sum = 0.0;
    var known = 0;
    var unknown = 0;
    for (final item in items) {
      final value = per100(item);
      if (value == null) {
        unknown++;
        continue;
      }
      known++;
      sum += value * amountG(item) / 100;
    }
    return NutrientTotal(
      sum: sum / divisor,
      knownEntries: known,
      unknownEntries: unknown,
    );
  }

  /// Nothing logged had a value for this nutrient.
  bool get isUnknown => knownEntries == 0 && unknownEntries > 0;

  /// Some entries gave a value and some did not: [sum] is a lower bound.
  bool get isPartial => knownEntries > 0 && unknownEntries > 0;

  /// [sum], or null while nothing is known.
  double? get valueOrNull => isUnknown ? null : sum;
}
