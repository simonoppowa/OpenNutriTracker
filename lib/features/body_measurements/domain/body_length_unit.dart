import 'package:intl/intl.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/body_measurements/domain/body_measurement.dart';

/// Centimetres or inches for body measurements, following the height unit
/// setting (#44). Stored values are always centimetres.
enum BodyLengthUnit {
  cm,
  inch;

  static BodyLengthUnit fromImperial(bool usesImperialHeightUnits) =>
      usesImperialHeightUnits ? inch : cm;

  double fromCm(double cm) =>
      this == BodyLengthUnit.cm ? cm : UnitCalc.cmToInches(cm);

  double toCm(double value) =>
      this == BodyLengthUnit.cm ? value : UnitCalc.inchesToCm(value);

  /// [cm] in this unit with at most one decimal, in the app's locale
  /// ("84,5" in German).
  String format(double cm) => NumberFormat('0.#').format(fromCm(cm));

  /// The allowed range in this unit, rounded inwards to whole numbers.
  ({int min, int max}) get range => (
    min: fromCm(BodyMeasurement.minCm).ceil(),
    max: fromCm(BodyMeasurement.maxCm).floor(),
  );
}
