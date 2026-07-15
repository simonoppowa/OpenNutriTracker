import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/generated/l10n.dart';

class UnitCalc {
  /// Thermochemical factor used by Open Food Facts, the USDA Food Data
  /// Central, and EU food labelling regulations to convert between kcal
  /// and kJ. This is the display-only conversion used for issue #177 —
  /// stored energy values are always kcal.
  static const double kcalToKjFactor = 4.184;

  static double kcalToKj(double kcal) {
    return kcal * kcalToKjFactor;
  }

  static double kjToKcal(double kj) {
    return kj / kcalToKjFactor;
  }

  static double cmToInches(double cm) {
    return cm / 2.54;
  }

  static double inchesToCm(double inches) {
    return inches * 2.54;
  }

  /// Converts centimeters to feet and rounds the result
  static double cmToFeet(double cm) {
    return (cm / 30.48).roundToPrecision(2);
  }

  /// Converts feet to centimeters and rounds the result
  static double feetToCm(double feet) {
    return (feet * 30.48).roundToDouble();
  }

  /// Splits a centimetre height into whole feet and whole inches, the way
  /// people actually read height ("5 ft 9 in") rather than decimal feet.
  /// Inches are rounded to the nearest whole inch and roll into the next foot
  /// at 12 so we never show "5 ft 12 in".
  static (int feet, int inches) cmToFeetInches(double cm) {
    final totalInches = cm / 2.54;
    var feet = totalInches ~/ 12;
    var inches = (totalInches - feet * 12).round();
    if (inches >= 12) {
      feet += 1;
      inches = 0;
    }
    return (feet, inches);
  }

  /// Combines feet and inches back into centimetres, rounded to a whole
  /// centimetre to match how metric heights are stored and entered.
  static double feetInchesToCm(int feet, int inches) {
    return ((feet * 12 + inches) * 2.54).roundToDouble();
  }

  /// Keeps one decimal place. Whole-pound rounding used to drop up to half a
  /// pound, so the same stored weight read differently across screens (the
  /// home chip and Trends show one decimal); this keeps every surface
  /// consistent and loses less precision on the way out.
  static double kgToLbs(double kg) {
    return double.parse((kg * 2.20462).toStringAsFixed(1));
  }

  /// Preserves two decimal places so round-tripping lbs→kg→lbs stays exact.
  static double lbsToKg(double lbs) {
    return double.parse((lbs / 2.20462).toStringAsFixed(2));
  }

  /// Splits a kilogram weight into whole stones and the remaining pounds for
  /// the UK-style "11 st 5.2 lb" display and input. Pounds keep two decimals,
  /// mirroring [lbsToKg], and a value that rounds up to a full 14 lb rolls
  /// into the next stone so we never show "10 st 14.0 lb".
  static (int stones, double pounds) kgToStLb(double kg) {
    final totalLbs = kg * 2.20462;
    var stones = totalLbs ~/ 14;
    var pounds = double.parse((totalLbs - stones * 14).toStringAsFixed(2));
    if (pounds >= 14.0) {
      stones += 1;
      pounds = 0.0;
    }
    return (stones, pounds);
  }

  /// Combines stones and pounds back into kilograms, preserving two decimals
  /// so a st+lb → kg → st+lb round-trip stays tight (matches [lbsToKg]).
  static double stLbToKg(int stones, double pounds) {
    return double.parse(((stones * 14 + pounds) / 2.20462).toStringAsFixed(2));
  }

  static double gToOz(double g) {
    return g / 28.3495;
  }

  static double ozToG(double oz) {
    return oz * 28.3495;
  }

  static double mlToFlOz(double ml) {
    return ml / 29.5735;
  }

  static double flOzToMl(double flOz) {
    return flOz * 29.5735;
  }

  static double metricToImperialValue(double metricValue, String unit) {
    switch (unit) {
      case 'g':
        return gToOz(metricValue);
      case 'ml':
        return mlToFlOz(metricValue);
      default:
        return metricValue;
    }
  }

  static double imperialToMetricValue(double imperialValue, String unit) {
    switch (unit) {
      case 'oz':
        return ozToG(imperialValue);
      case 'fl oz' || 'fl.oz':
        return flOzToMl(imperialValue);
      default:
        return imperialValue;
    }
  }

  static String metricToImperialUnit(BuildContext context, String unit) {
    switch (unit) {
      case 'g':
        return S.of(context).ozUnit;
      case 'ml':
        return S.of(context).flOzUnit;
      default:
        return unit;
    }
  }

  static String imperialToMetricUnit(BuildContext context, String unit) {
    switch (unit) {
      case 'oz':
        return S.of(context).gramUnit;
      case 'fl oz' || 'fl.oz':
        return S.of(context).milliliterUnit;
      default:
        return unit;
    }
  }
}
