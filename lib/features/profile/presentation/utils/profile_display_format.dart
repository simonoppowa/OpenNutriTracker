import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';

String formatProfileWeight(double weight) {
  final roundedToOneDecimal = double.parse(weight.toStringAsFixed(1));
  if (roundedToOneDecimal == roundedToOneDecimal.roundToDouble()) {
    return roundedToOneDecimal.toStringAsFixed(0);
  }
  return roundedToOneDecimal.toStringAsFixed(1);
}

/// Formats a stored centimetre height for display. Imperial reads as
/// "5 ft 9 in" rather than decimal feet, the way people actually say it.
/// Labels are passed in so this stays a pure, testable function.
String formatHeight(
  double cm,
  bool imperial, {
  required String cmLabel,
  required String ftLabel,
  required String inLabel,
}) {
  if (!imperial) {
    return '${cm.round()} $cmLabel';
  }
  final (feet, inches) = UnitCalc.cmToFeetInches(cm);
  return '$feet $ftLabel $inches $inLabel';
}

/// Formats a stored kilogram weight for display in the user's chosen body
/// weight unit, returning the full unit-suffixed string so callers don't have
/// to hand-assemble `'$value $unit'`. Stones are shown as "11 st 5.2 lb".
///
/// Labels are passed in (rather than reading from `BuildContext`) so this stays
/// a pure function that unit tests can exercise without a widget tree.
String formatBodyWeight(
  double weightKg,
  BodyWeightUnit unit, {
  required String kgLabel,
  required String lbLabel,
  required String stLabel,
}) {
  switch (unit) {
    case BodyWeightUnit.kg:
      return '${formatProfileWeight(weightKg)} $kgLabel';
    case BodyWeightUnit.lb:
      return '${formatProfileWeight(UnitCalc.kgToLbs(weightKg))} $lbLabel';
    case BodyWeightUnit.st:
      final (stones, pounds) = UnitCalc.kgToStLb(weightKg);
      return '$stones $stLabel ${formatProfileWeight(pounds)} $lbLabel';
  }
}
