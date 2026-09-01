import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';

/// Suggests how much of an imported workout's energy should actually count
/// toward the daily calorie goal.
///
/// A watch reporting "480 kcal burned" is measuring the workout, not the day.
/// Bodies claw a good part of that back over the following hours — less
/// spontaneous movement, a lower resting burn — so crediting every reported
/// calorie systematically overstates the budget. How much is clawed back
/// varies with body composition, which is what this calculator estimates.
///
/// Source:
///   * Careau V, Halsey LG, Pontzer H, Ainslie PN, et al. (IAEA DLW database
///     group), "Energy compensation and adiposity in humans", Current Biology
///     2021;31(20):4659–4666.e2. doi:10.1016/j.cub.2021.08.016. PMID
///     34453886. PMC8551017.
///
/// Two figures are taken from that paper, and they come from two different
/// models in it — worth stating, because they don't line up arithmetically:
///
///   * the headline slope of total against basal expenditure implies
///     [meanCompensationPct] of activity energy is compensated on average
///     (`1 − 0.723`, reported as 27.7% and rounded to 28% in the abstract).
///     That is what [fallbackMultiplier] is built from, and it is what a user
///     we know nothing about gets;
///   * the fat-mass-moderated model behind the paper's Figure 3 gives
///     [leanCompensationPct] "in people at the 10th percentile of the BMI
///     distribution" and [heavyCompensationPct] at the 90th (the figure's own
///     caption says 45.8; the Results text, cited here, says 45.7). Those two
///     are the ends of the gradient interpolated below.
///
/// Two approximations sit on top of the source, both deliberate:
///
///   * the paper's illustrative percentiles are anchored on **BMI**, while
///     its actual statistical moderator is fat mass. Reading a body fat
///     percentile onto the same gradient is this app's inference, not the
///     paper's claim — it is the closer measure of the thing the paper found
///     mattered, so it is preferred when the health store has one;
///   * the BMI fallback maps BMI 20 to the 10th percentile and BMI 33 to the
///     90th. Those are rough round numbers for a US-adult BMI distribution,
///     not a published percentile table; they sit either side of the Careau
///     sample's median BMI of 25.2, which lands near the middle of the range.
class WorkoutCompensationCalc {
  /// Mean share of activity energy compensated across the whole IAEA DLW
  /// sample (Careau et al. 2021, Figure 2A: slope 0.723 ± 0.049).
  static const double meanCompensationPct = 27.7;

  /// Compensation at the 10th and 90th percentile of the sample's BMI
  /// distribution (Careau et al. 2021, Figure 3).
  static const double leanCompensationPct = 29.7;
  static const double heavyCompensationPct = 45.7;

  /// What a user with neither a body fat reading nor usable body metrics
  /// gets: the sample-wide mean, i.e. credit a bit under three quarters of
  /// each reported workout calorie.
  static const double fallbackMultiplier = 0.72;

  /// Body fat percentages at the 10th and 90th percentile of US adults aged
  /// 20+, whole-body DXA including the head.
  ///
  /// Source: Borrud LG, Flegal KM, Looker AC, Everhart JE, Harris TB,
  /// Shepherd JA, "Body composition data for individuals 8 years of age and
  /// older: U.S. population, 1999–2004", National Center for Health
  /// Statistics, Vital and Health Statistics Series 11, No. 250, April 2010,
  /// Table 3 (all race/ethnicity, age 20+, crude). PMID 20812448.
  static const double maleBodyFatP10 = 19.5;
  static const double maleBodyFatP90 = 35.9;
  static const double femaleBodyFatP10 = 30.5;
  static const double femaleBodyFatP90 = 48.4;

  /// Approximate BMI anchors for the same two percentiles — see the class
  /// doc: round numbers, not a published table.
  static const double bmiP10 = 20;
  static const double bmiP90 = 33;

  /// The suggested calorie-credit multiplier for [user], as a fraction
  /// within [ConfigEntity.minHealthWorkoutKcalMultiplier] ..
  /// [ConfigEntity.maxHealthWorkoutKcalMultiplier], rounded to whole
  /// percentage points.
  ///
  /// [bodyFatPercent] is a 0..100 reading from the platform health store when
  /// one is available. It is preferred over the user's BMI; when neither can
  /// be read the sample mean ([fallbackMultiplier]) is returned, so the
  /// suggestion is never fabricated from nothing.
  static double suggestedMultiplier({
    double? bodyFatPercent,
    required UserEntity user,
  }) {
    final percentile =
        _percentileFromBodyFat(bodyFatPercent, user) ??
        _percentileFromBmi(user);
    if (percentile == null) return fallbackMultiplier;

    final compensationPct =
        leanCompensationPct +
        (heavyCompensationPct - leanCompensationPct) *
            ((percentile - 10) / 80).clamp(0.0, 1.0);
    return _round(1 - compensationPct / 100);
  }

  /// Where [bodyFatPercent] sits in the adult distribution for this user's
  /// reference body chemistry, or null when there is no usable reading. A
  /// value outside 0..100 exclusive is a broken record, not a lean athlete.
  static double? _percentileFromBodyFat(
    double? bodyFatPercent,
    UserEntity user,
  ) {
    if (bodyFatPercent == null) return null;
    if (bodyFatPercent <= 0 || bodyFatPercent >= 100) return null;
    return _interpolatePercentile(
      bodyFatPercent,
      _bodyFatP10For(user),
      _bodyFatP90For(user),
    );
  }

  static double? _percentileFromBmi(UserEntity user) {
    if (user.heightCM <= 0 || user.weightKG <= 0) return null;
    final heightM = user.heightCM / 100;
    return _interpolatePercentile(
      user.weightKG / (heightM * heightM),
      bmiP10,
      bmiP90,
    );
  }

  /// Non-binary users fall back to the same `CaloriesProfileEntity` they pick
  /// for TDEE, so a user only states their reference body chemistry once —
  /// mirrors `ConfigEntity.seedWaterGoalForGender`.
  static double _bodyFatP10For(UserEntity user) => switch (user.gender) {
    UserGenderEntity.male => maleBodyFatP10,
    UserGenderEntity.female => femaleBodyFatP10,
    UserGenderEntity.nonBinary => switch (user.caloriesProfile ??
        CaloriesProfileEntity.averaged) {
      CaloriesProfileEntity.testosteroneTypical => maleBodyFatP10,
      CaloriesProfileEntity.estrogenTypical => femaleBodyFatP10,
      CaloriesProfileEntity.averaged => (maleBodyFatP10 + femaleBodyFatP10) / 2,
    },
  };

  static double _bodyFatP90For(UserEntity user) => switch (user.gender) {
    UserGenderEntity.male => maleBodyFatP90,
    UserGenderEntity.female => femaleBodyFatP90,
    UserGenderEntity.nonBinary => switch (user.caloriesProfile ??
        CaloriesProfileEntity.averaged) {
      CaloriesProfileEntity.testosteroneTypical => maleBodyFatP90,
      CaloriesProfileEntity.estrogenTypical => femaleBodyFatP90,
      CaloriesProfileEntity.averaged => (maleBodyFatP90 + femaleBodyFatP90) / 2,
    },
  };

  /// Linear read-off between the 10th and 90th percentile anchors. The result
  /// is deliberately left unclamped at the ends — [suggestedMultiplier]
  /// clamps the compensation it derives, which keeps one clamp in one place.
  static double _interpolatePercentile(
    double value,
    double anchorP10,
    double anchorP90,
  ) => 10 + (value - anchorP10) / (anchorP90 - anchorP10) * 80;

  static double _round(double multiplier) {
    final clamped = multiplier.clamp(
      ConfigEntity.minHealthWorkoutKcalMultiplier,
      ConfigEntity.maxHealthWorkoutKcalMultiplier,
    );
    return (clamped * 100).round() / 100;
  }
}
