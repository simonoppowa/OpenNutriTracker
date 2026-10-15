import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Translates the English measure-unit word in a serving label at display
/// time — "1 slice (38 g)" becomes "1 Scheibe (38 g)" for a German user.
///
/// Labels are built once in English when a food is fetched and then
/// persisted with the meal (see MealEntity._spServingLabel), so they cannot
/// be localized at construction time without freezing the language into the
/// cache. Only the finite set of common household units is translated;
/// longer FDC modifier prose ("cup, sliced") is left in English rather than
/// rendered half-translated. Unit words use ICU plurals so quantity
/// agreement works per locale ("1 Scheibe" / "2 Scheiben").
String localizeServingLabel(S s, String label) {
  final match = _servingLabelPattern.firstMatch(label.trim());
  if (match == null) return label;
  final amountText = match.group(1)!;
  final amount = num.tryParse(amountText.replaceAll(',', '.'));
  if (amount == null) return label;
  final localizedUnit =
      _localizedUnit(s, match.group(2)!.trim().toLowerCase(), amount);
  if (localizedUnit == null) return label;
  final weightSuffix = match.group(3);
  return weightSuffix != null
      ? '$amountText $localizedUnit $weightSuffix'
      : '$amountText $localizedUnit';
}

/// Rewrites the gram and millilitre amounts in a serving label in ounces
/// and fluid ounces, for a user who has chosen imperial food units —
/// "15 g (Portion)" becomes "0.53 oz (Portion)", "1 slice (38 g)" becomes
/// "1 slice (1.34 oz)". Everything else in the label is left as it is.
String imperialServingLabel(S s, String label) {
  return label.replaceAllMapped(_metricAmountPattern, (match) {
    final amount = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (amount == null) return match.group(0)!;
    final isVolume = match.group(2)!.toLowerCase() == 'ml';
    final converted = isVolume
        ? UnitCalc.mlToFlOz(amount)
        : UnitCalc.gToOz(amount);
    return '${_formatAmount(converted)} ${isVolume ? s.flOzUnit : s.ozUnit}';
  });
}

/// A whole number followed by `g` or `ml` as a word of its own ("15 g",
/// "250ml", ".5 g"), so "mg", "kg" and "grams" are not mistaken for one.
/// The amount must not continue another number ("1/2 g", the "5" of
/// "1.5"), and the unit must not be half of a compound one ("g/ml").
final _metricAmountPattern = RegExp(
  r'(?<![\d.,/])(\d+(?:[.,]\d+)?|\.\d+)\s*(g|ml)\b(?!/)',
  caseSensitive: false,
);

/// Two decimals at most, without trailing zeros: 0.53, 1.1, 2.
String _formatAmount(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'\.?0+$'), '')
      : fixed;
}

/// "`<amount> <unit words> (weight)`" — the unit part deliberately excludes
/// commas so descriptive modifiers ("cup, sliced") don't match.
final _servingLabelPattern =
    RegExp(r'^(\d+(?:[.,]\d+)?)\s+([A-Za-z ]+?)\s*(\(.*\))?$');

String? _localizedUnit(S s, String unit, num count) {
  switch (unit) {
    case 'portion':
    case 'portions':
      return s.measureUnitPortion(count);
    case 'serving':
    case 'servings':
      return s.measureUnitServing(count);
    case 'cup':
    case 'cups':
      return s.measureUnitCup(count);
    case 'tablespoon':
    case 'tablespoons':
    case 'tbsp':
      return s.measureUnitTablespoon(count);
    case 'teaspoon':
    case 'teaspoons':
    case 'tsp':
      return s.measureUnitTeaspoon(count);
    case 'slice':
    case 'slices':
      return s.measureUnitSlice(count);
    case 'piece':
    case 'pieces':
      return s.measureUnitPiece(count);
    case 'package':
    case 'packages':
      return s.measureUnitPackage(count);
    case 'can':
    case 'cans':
      return s.measureUnitCan(count);
    case 'bottle':
    case 'bottles':
      return s.measureUnitBottle(count);
    case 'bar':
    case 'bars':
      return s.measureUnitBar(count);
    case 'egg':
    case 'eggs':
      return s.measureUnitEgg(count);
    default:
      return null;
  }
}
