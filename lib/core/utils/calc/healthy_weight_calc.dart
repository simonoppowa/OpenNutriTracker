import 'dart:math';

import 'package:opennutritracker/core/utils/calc/bmi_calc.dart';

/// The body-weight span that puts someone of a given height inside the WHO
/// healthy BMI band. The BMI formula solved for mass instead of index.
///
/// Onboarding shows this beside the optional target-weight field, so the
/// suggested number arrives with its derivation.
class HealthyWeightRange {
  final double minKg;
  final double maxKg;

  const HealthyWeightRange({required this.minKg, required this.maxKg});

  /// BMI = kg / m², so kg = BMI × m².
  factory HealthyWeightRange.forHeightCm(double heightCm) {
    final heightM2 = pow(heightCm / 100, 2);
    return HealthyWeightRange(
      minKg: BMICalc.healthyBmiMin * heightM2,
      maxKg: BMICalc.healthyBmiMaxInclusive * heightM2,
    );
  }

  bool contains(double weightKg) => weightKg >= minKg && weightKg <= maxKg;

  /// Midpoint of the band, BMI 21.7 at any height.
  double get midpointKg => (minKg + maxKg) / 2;

  /// What the suggestion chip offers as a target.
  ///
  /// Someone already inside the healthy band is offered their current
  /// weight, i.e. maintain. Offering the midpoint instead would invent a
  /// weight-change goal they never asked for.
  double suggestionFor(double currentWeightKg) =>
      contains(currentWeightKg) ? currentWeightKg : midpointKg;
}
