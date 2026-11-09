/// The keys of the user's per-nutrient goals as the per-profile config
/// stores them (`ConfigDBO.userNutrientGoals`, #1316).
///
/// Settings → Nutrient goals writes the goals there as well as onto the
/// day being edited, and every tracked day created afterwards starts with
/// them. A nutrient that is absent has no goal of the user's own, so the
/// panels use the default reference value for it.
abstract final class NutrientGoalKeys {
  static const fibre = 'fibre';
  static const satFat = 'satFat';
  static const sugars = 'sugars';
  static const sodium = 'sodium';
  static const calcium = 'calcium';
  static const iron = 'iron';
  static const potassium = 'potassium';
  static const vitaminD = 'vitaminD';
  static const vitaminB12 = 'vitaminB12';
  static const magnesium = 'magnesium';

  static const all = {
    fibre,
    satFat,
    sugars,
    sodium,
    calcium,
    iron,
    potassium,
    vitaminD,
    vitaminB12,
    magnesium,
  };

  /// [raw] without unknown keys and without amounts no goal can have
  /// (negative, NaN or infinite). 0 is a goal like any other.
  static Map<String, double> sanitise(Map<String, double>? raw) => {
    for (final entry in (raw ?? const <String, double>{}).entries)
      if (all.contains(entry.key) && entry.value.isFinite && entry.value >= 0)
        entry.key: entry.value,
  };
}
