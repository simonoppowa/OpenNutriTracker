import 'package:opennutritracker/core/utils/calc/unit_calc.dart';

class Ranges {
  static const Duration maxDurationForBirthdayIntoTheFuture = Duration(days: -1);
  static const Duration maxAge = Duration(days: 365 * 130);

  static const double maxHeight = 300;
  static const double minHeight = 30;
  static const double maxWeight = 640;
  static const double minWeight = 2;

  /// Soft floor below which a computed daily kcal goal is flagged as low
  /// enough that the app surfaces a non-blocking warning encouraging the
  /// user to consult a professional. Aligned with the commonly-cited
  /// NIH / Mayo Clinic minimums for sustained healthy intake (≈1500 kcal
  /// for adults with a testosterone-typical hormonal profile, ≈1200 kcal
  /// otherwise). Non-binary users on the averaged midpoint, or who have
  /// not yet chosen a calories profile, use the lower (female) floor
  /// because the averaged TDEE is itself a midpoint and the lower bound
  /// sits more naturally beside it.
  static const double minRecommendedDailyKcalMale = 1500;
  static const double minRecommendedDailyKcalFemale = 1200;

  static const bool cmAllowDecimalPlaces = false;
  static const bool feetAllowDecimalPlaces = true;
  static const bool kgAllowDecimalPlaces = true;
  static const bool lbsAllowDecimalPlaces = true;

  static final RegExp cmRegExp =
      cmAllowDecimalPlaces ? RegExp(r'^[0-9]+([.,][0-9])?$') : RegExp(r'^[0-9]+$');
  static final RegExp feetRegExp =
      feetAllowDecimalPlaces ? RegExp(r'^[0-9]+([.,][0-9])?$') : RegExp(r'^[0-9]+$');
  static final RegExp kgRegExp =
      kgAllowDecimalPlaces ? RegExp(r'^[0-9]+([.,][0-9])?$') : RegExp(r'^[0-9]+$');
  static final RegExp lbsRegExp =
      lbsAllowDecimalPlaces ? RegExp(r'^[0-9]+([.,][0-9])?$') : RegExp(r'^[0-9]+$');

  static final double maxHeightInFeet = UnitCalc.cmToFeet(maxHeight);
  static final double minHeightInFeet = UnitCalc.cmToFeet(minHeight);
  static final double maxWeightInLbs = UnitCalc.kgToLbs(maxWeight);
  static final double minWeightInLbs = UnitCalc.kgToLbs(minWeight);
}