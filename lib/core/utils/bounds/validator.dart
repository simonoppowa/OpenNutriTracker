import 'package:opennutritracker/core/utils/bounds/ranges_const.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';

class ValueValidator {
  static String? heightStringValidator(
    String? value,
    String wrongHeightLabel, {
    bool isImperial = false,
  }) {
    if (value == null) return wrongHeightLabel;
    if (isImperial) {
      if (value.isEmpty || !Ranges.feetRegExp.hasMatch(value)) {
        return wrongHeightLabel;
      }
    } else {
      if (value.isEmpty || !Ranges.cmRegExp.hasMatch(value)) {
        return wrongHeightLabel;
      }
    }
    return null;
  }

  static String? weightStringValidator(
    String? value,
    String wrongWeightLabel, {
    bool isImperial = false,
  }) {
    if (value == null) return wrongWeightLabel;
    if (isImperial) {
      if (value.isEmpty || !Ranges.lbsRegExp.hasMatch(value)) {
        return wrongWeightLabel;
      }
    } else {
      if (value.isEmpty || !Ranges.kgRegExp.hasMatch(value)) {
        return wrongWeightLabel;
      }
    }
    return null;
  }

  static double? parseHeightInCm(double? height, {bool isImperial = false}) {
    if (height == null) return null;
    final belowMin =
        isImperial ? height < Ranges.minHeightInFeet : height < Ranges.minHeight;
    final aboveMax =
        isImperial ? height > Ranges.maxHeightInFeet : height > Ranges.maxHeight;
    if (belowMin || aboveMax) return null;
    return isImperial ? UnitCalc.feetToCm(height) : height;
  }

  static double? parseWeightInKg(double? weight, {bool isImperial = false}) {
    if (weight == null) return null;
    final belowMin =
        isImperial ? weight < Ranges.minWeightInLbs : weight < Ranges.minWeight;
    final aboveMax =
        isImperial ? weight > Ranges.maxWeightInLbs : weight > Ranges.maxWeight;
    if (belowMin || aboveMax) return null;
    return isImperial ? UnitCalc.lbsToKg(weight) : weight;
  }

  /// Combines a feet + inches entry into a bounds-checked centimetre value.
  /// Returns null when the parts are missing or the combined height falls
  /// outside the same cm range the metric path uses.
  static double? parseFeetInchesHeightInCm(int? feet, double? inches) {
    if (feet == null || inches == null) return null;
    if (feet < 0 || inches < 0) return null;
    final cm = UnitCalc.feetInchesToCm(feet, inches.round());
    if (cm < Ranges.minHeight || cm > Ranges.maxHeight) return null;
    return cm;
  }

  /// Combines a stones + pounds entry into a bounds-checked kilogram value.
  /// Returns null when the parts are missing or the combined weight falls
  /// outside the same kg range the kg/lb paths use. Pounds are taken modulo a
  /// stone is NOT enforced here — a user typing "0 st 200 lb" still resolves to
  /// a valid weight, the bounds check is what guards the extremes.
  static double? parseStLbWeightInKg(int? stones, double? pounds) {
    if (stones == null || pounds == null) return null;
    if (stones < 0 || pounds < 0) return null;
    final kg = UnitCalc.stLbToKg(stones, pounds);
    if (kg < Ranges.minWeight || kg > Ranges.maxWeight) return null;
    return kg;
  }

  static DateTime getFirstDate() => DateTime.now().subtract(Ranges.maxAge);

  static DateTime getLastDate() =>
      DateTime.now().add(Ranges.maxDurationForBirthdayIntoTheFuture);
}
