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

  /// Whether a height that already passed the hard bounds is also ordinary
  /// enough to accept without asking. Out-of-band values are still allowed;
  /// the caller confirms them with the user first.
  static bool isPlausibleHeightCm(double heightCm) =>
      heightCm >= Ranges.plausibleMinHeight &&
      heightCm <= Ranges.plausibleMaxHeight;

  /// Weight counterpart of [isPlausibleHeightCm].
  static bool isPlausibleWeightKg(double weightKg) =>
      weightKg >= Ranges.plausibleMinWeight &&
      weightKg <= Ranges.plausibleMaxWeight;

  static DateTime getFirstDate({DateTime? now}) =>
      (now ?? DateTime.now()).subtract(Ranges.maxAge);

  /// Latest birthday the app accepts, [Ranges.minAgeYears] before today.
  /// Walks the calendar so leap years can't drift the boundary.
  static DateTime getLastDate({DateTime? now}) {
    final today = now ?? DateTime.now();
    return DateTime(today.year - Ranges.minAgeYears, today.month, today.day);
  }

  /// Where the birthday picker opens when the user hasn't chosen yet.
  /// A birthday is picked year-first, and 30 years back sits near the middle
  /// of the plausible range, the shortest average travel to a real answer.
  static DateTime getInitialBirthdayDate({DateTime? now}) {
    final today = now ?? DateTime.now();
    return DateTime(today.year - 30, today.month, today.day);
  }

  /// Completed years between [birthday] and today, counted on the calendar
  /// (a birthday that hasn't come round yet this year doesn't count).
  static int ageInYears(DateTime birthday, {DateTime? now}) {
    final today = now ?? DateTime.now();
    var age = today.year - birthday.year;
    final hadBirthdayThisYear =
        today.month > birthday.month ||
        (today.month == birthday.month && today.day >= birthday.day);
    if (!hadBirthdayThisYear) age--;
    return age;
  }

  /// Whether the goal for this birthday should carry the adult-equation
  /// notice. Ages below [Ranges.minAgeYears] can't be picked, so in practice
  /// this covers 13 to 17.
  static bool isUnderAdultAge(DateTime birthday, {DateTime? now}) =>
      ageInYears(birthday, now: now) < Ranges.adultAgeYears;

  /// Clamps a stored birthday into the accepted range so it can be handed to
  /// `showDatePicker` as `initialDate`. The picker asserts when that falls
  /// outside first/last, and older builds allowed dates today's bounds
  /// reject.
  static DateTime clampBirthday(DateTime birthday, {DateTime? now}) {
    final first = getFirstDate(now: now);
    final last = getLastDate(now: now);
    if (birthday.isBefore(first)) return first;
    if (birthday.isAfter(last)) return last;
    return birthday;
  }
}
