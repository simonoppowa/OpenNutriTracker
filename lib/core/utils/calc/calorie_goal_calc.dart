import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/bounds/ranges_const.dart';
import 'package:opennutritracker/core/utils/calc/tdee_calc.dart';

class CalorieGoalCalc {
  static const double loseWeightKcalAdjustment = -500;
  static const double maintainWeightKcalAdjustment = 0;
  static const double gainWeightKcalAdjustment = 500;

  /// Distance from target (kg) at which the taper begins easing the
  /// adjustment down from full strength.
  static const double taperStartDistanceKg = 5.0;

  /// Distance from target (kg) at which the taper has fully collapsed
  /// the weight-goal adjustment to zero (maintenance).
  static const double taperEndDistanceKg = 1.0;

  static double getDailyKcalLeft(
    double totalKcalGoal,
    double totalKcalIntake,
  ) =>
      totalKcalGoal - totalKcalIntake;

  static double getTdee(UserEntity userEntity) =>
      TDEECalc.getTDEEKcalIOM2005(userEntity);

  // 1 kg of body fat ≈ 7700 kcal; spread over 7 days → ~1100 kcal/day per kg/week
  static const double _kcalPerKgPerWeekDaily = 1100.0;

  /// [fixedKcalGoal] is the user's own daily goal (#671). When it is set it
  /// replaces the TDEE, the weight-goal adjustment and [kcalUserAdjustment];
  /// [totalKcalActivities] is still added, as it is to the calculated goal.
  /// A value outside the allowed range is ignored (see [validFixedKcalGoal]).
  static double getTotalKcalGoal(
    UserEntity userEntity,
    double totalKcalActivities, {
    double? kcalUserAdjustment,
    bool caloriesTaperEnabled = false,
    double? fixedKcalGoal,
  }) {
    final fixed = validFixedKcalGoal(fixedKcalGoal);
    if (fixed != null) return fixed + totalKcalActivities;
    final baseAdjustment = getKcalGoalAdjustment(
      userEntity.goal,
      weeklyWeightGoalKg: userEntity.weeklyWeightGoalKg,
    );
    final adjustment = applyTargetWeightTaper(
      baseAdjustment: baseAdjustment,
      currentWeightKg: userEntity.weightKG,
      targetWeightKg: userEntity.targetWeightKg,
      goal: userEntity.goal,
      taperEnabled: caloriesTaperEnabled,
    );
    return getTdee(userEntity) +
        adjustment +
        (kcalUserAdjustment ?? 0) +
        totalKcalActivities;
  }

  /// [kcal] when it is a usable fixed daily goal, otherwise null.
  ///
  /// The Settings dialog only stores values inside
  /// [Ranges.minFixedDailyKcalGoal]..[Ranges.maxFixedDailyKcalGoal], and an
  /// import rejects anything else, so a value outside it is corruption.
  /// Reading it as "no fixed goal" falls back to the calculated goal rather
  /// than showing a goal of 0, a negative one or NaN.
  static double? validFixedKcalGoal(double? kcal) {
    if (kcal == null || !kcal.isFinite) return null;
    if (kcal < Ranges.minFixedDailyKcalGoal ||
        kcal > Ranges.maxFixedDailyKcalGoal) {
      return null;
    }
    return kcal;
  }

  static double getKcalGoalAdjustment(UserWeightGoalEntity goal,
      {double? weeklyWeightGoalKg}) {
    if (weeklyWeightGoalKg != null) {
      return weeklyWeightGoalKg * _kcalPerKgPerWeekDaily;
    }
    double kcalAdjustment;
    if (goal == UserWeightGoalEntity.loseWeight) {
      kcalAdjustment = loseWeightKcalAdjustment;
    } else if (goal == UserWeightGoalEntity.gainWeight) {
      kcalAdjustment = gainWeightKcalAdjustment;
    } else {
      kcalAdjustment = maintainWeightKcalAdjustment;
    }
    return kcalAdjustment;
  }

  /// Scales the daily weight-goal kcal adjustment as the user nears
  /// their target weight, so the last stretch becomes maintenance
  /// instead of an ever-thinner slice.
  ///
  /// Returns the raw [baseAdjustment] when the taper is off, when no
  /// [targetWeightKg] is set, or when the goal is maintenance. When the
  /// taper is on:
  ///
  /// - Past the target (already reached or overshot, judged by the
  ///   direction of [goal]): zero adjustment.
  /// - Within [taperEndDistanceKg] of target: zero adjustment.
  /// - Beyond [taperStartDistanceKg]: full [baseAdjustment].
  /// - In between: linearly interpolated from full → zero.
  static double applyTargetWeightTaper({
    required double baseAdjustment,
    required double currentWeightKg,
    required double? targetWeightKg,
    required UserWeightGoalEntity goal,
    required bool taperEnabled,
  }) {
    if (!taperEnabled) return baseAdjustment;
    if (targetWeightKg == null) return baseAdjustment;
    if (goal == UserWeightGoalEntity.maintainWeight) return baseAdjustment;
    if (baseAdjustment == 0) return baseAdjustment;

    final signedDistance = targetWeightKg - currentWeightKg;
    // Direction-aware "past target" check: a user losing weight has
    // reached the target once current ≤ target (signedDistance ≥ 0
    // there means they still have weight to lose, ≤ 0 means done).
    // For gainers it is the mirror image.
    final reachedOrOvershot = goal == UserWeightGoalEntity.loseWeight
        ? signedDistance >= 0
        : signedDistance <= 0;
    if (reachedOrOvershot) return 0;

    final distance = signedDistance.abs();
    if (distance <= taperEndDistanceKg) return 0;
    if (distance >= taperStartDistanceKg) return baseAdjustment;

    final span = taperStartDistanceKg - taperEndDistanceKg;
    final progress = (distance - taperEndDistanceKg) / span;
    return baseAdjustment * progress;
  }

  /// Whether the computed daily kcal goal sits below the research-backed
  /// minimum for the user's hormonal profile. Used to decide whether to
  /// surface the soft low-kcal warning card next to the target value.
  ///
  /// The male floor (≈1500 kcal) is used when there is positive evidence
  /// for it: a binary male profile, or a non-binary user who explicitly
  /// picked a testosterone-typical calories profile. Everywhere else —
  /// binary female, non-binary on estrogen-typical, non-binary on the
  /// averaged midpoint (because that maps to a TDEE midpoint and the
  /// lower floor sits more naturally beside it), or non-binary who hasn't
  /// chosen a profile yet — the female floor (≈1200 kcal) is used.
  ///
  /// The check is intentionally non-strict (`<`), so a value sitting
  /// exactly on the floor does not trip the warning.
  static bool isBelowRecommendedDailyKcalFloor({
    required double goalKcal,
    required UserGenderEntity gender,
    CaloriesProfileEntity? caloriesProfile,
  }) =>
      goalKcal <
      recommendedDailyKcalFloor(
        gender: gender,
        caloriesProfile: caloriesProfile,
      );

  /// Returns the floor used by [isBelowRecommendedDailyKcalFloor] for the
  /// given user, so UI surfaces can quote the actual number in the
  /// warning message.
  static double recommendedDailyKcalFloor({
    required UserGenderEntity gender,
    CaloriesProfileEntity? caloriesProfile,
  }) {
    final usesMaleFloor = gender == UserGenderEntity.male ||
        caloriesProfile == CaloriesProfileEntity.testosteroneTypical;
    return usesMaleFloor
        ? Ranges.minRecommendedDailyKcalMale
        : Ranges.minRecommendedDailyKcalFemale;
  }
}
