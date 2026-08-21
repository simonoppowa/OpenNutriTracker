import 'package:opennutritracker/core/utils/calc/unit_calc.dart';

class Ranges {
  static const Duration maxAge = Duration(days: 365 * 130);

  /// Youngest accepted age. 13 is the digital-consent floor most consumer
  /// apps use, and it keeps the calorie goal away from the ages where the
  /// adult energy equations are furthest from the published child ones.
  static const int minAgeYears = 13;

  /// Below this age the goal is still calculated, but the onboarding form
  /// says out loud that it comes from adult reference equations: the
  /// IOM 2005 formulas behind [TDEECalc] are the adult set, and the IOM
  /// publishes separate equations for children and adolescents.
  static const int adultAgeYears = 18;

  static const double maxHeight = 300;
  static const double minHeight = 30;
  static const double maxWeight = 640;
  static const double minWeight = 2;

  // The hard bounds above are wide enough to cover every real person, which
  // also lets a typo like "3" cm or "6" kg through as valid. Values inside
  // the hard bounds but outside the plausible ones are accepted once the
  // user confirms them. A soft check on the way past, not a second wall.
  static const double plausibleMinHeight = 120;
  static const double plausibleMaxHeight = 230;
  static const double plausibleMinWeight = 30;
  static const double plausibleMaxWeight = 300;

  /// Soft floor below which a computed daily kcal goal is flagged as low
  /// enough that the app surfaces a non-blocking warning encouraging the
  /// user to consult a professional. Aligned with the commonly-cited
  /// minimums for sustained healthy intake (≈1500 kcal for adults with a
  /// testosterone-typical hormonal profile, ≈1200 kcal otherwise). These
  /// are the figures Harvard Health publishes for safe calorie counting:
  /// https://www.health.harvard.edu/healthy-aging-and-longevity/calorie-counting-made-easy
  /// Non-binary users on the averaged midpoint, or who have not yet chosen
  /// a calories profile, use the lower (female) floor because the averaged
  /// TDEE is itself a midpoint and the lower bound sits more naturally
  /// beside it.
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