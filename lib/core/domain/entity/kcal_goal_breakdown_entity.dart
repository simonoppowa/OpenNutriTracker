import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/calc/pal_calc.dart';
import 'package:opennutritracker/core/utils/calc/tdee_calc.dart';

/// Snapshot of every variable and intermediate result that goes into the
/// daily kcal goal, for the transparency screen ("How your calorie goal is
/// calculated").
///
/// All values are computed through the same [CalorieGoalCalc] / [TDEECalc] /
/// [PalCalc] code paths the home screen uses, so [totalKcalGoal] here is
/// always identical to the goal the rest of the app shows — the breakdown
/// can't drift from the real calculation.
class KcalGoalBreakdownEntity extends Equatable {
  // Inputs, copied so the breakdown is a stable snapshot.
  final int age;
  final double heightCM;
  final double weightKG;
  final UserGenderEntity gender;
  final CaloriesProfileEntity? caloriesProfile;
  final UserPALEntity palCategory;
  final UserWeightGoalEntity goal;
  final double? weeklyWeightGoalKg;
  final double? targetWeightKg;
  final bool taperEnabled;

  // Step 1 — TDEE. The male / female sides are null when that reference
  // formula does not participate in the user's TDEE (e.g. [paMaleFormula]
  // is null for a binary female profile). For the non-binary averaged
  // profile both sides are set and [tdeeKcal] is their midpoint.
  final double palValue;
  final double? paMaleFormula;
  final double? paFemaleFormula;
  final double? tdeeMaleReferenceKcal;
  final double? tdeeFemaleReferenceKcal;
  final double tdeeKcal;

  // Step 2 — weight-goal adjustment. [baseAdjustmentKcal] is the raw
  // deficit / surplus (flat ±500 or weekly rate × 1100);
  // [effectiveAdjustmentKcal] is what actually enters the goal after the
  // optional target-weight taper.
  final double baseAdjustmentKcal;
  final double effectiveAdjustmentKcal;

  // Step 3 — manual offset from Settings (0 when unset).
  final double manualKcalAdjustment;

  // Step 4 — kcal burned by today's logged activities.
  final double activityKcal;

  /// The resulting goal; always equals
  /// TDEE + effective adjustment + manual offset + activity kcal, and always
  /// equals [CalorieGoalCalc.getTotalKcalGoal] for the same inputs.
  final double totalKcalGoal;

  // Macronutrient split derived from [totalKcalGoal]. The fractions are the
  // effective ones — the user's custom split when set, otherwise the
  // [MacroCalc] defaults (0.60 / 0.25 / 0.15) — and the gram goals come from
  // the same [MacroCalc] calls the home screen uses.
  final double carbsFractionGoal;
  final double fatsFractionGoal;
  final double proteinsFractionGoal;
  final double carbsGoalGrams;
  final double fatsGoalGrams;
  final double proteinsGoalGrams;

  const KcalGoalBreakdownEntity({
    required this.age,
    required this.heightCM,
    required this.weightKG,
    required this.gender,
    required this.caloriesProfile,
    required this.palCategory,
    required this.goal,
    required this.weeklyWeightGoalKg,
    required this.targetWeightKg,
    required this.taperEnabled,
    required this.palValue,
    required this.paMaleFormula,
    required this.paFemaleFormula,
    required this.tdeeMaleReferenceKcal,
    required this.tdeeFemaleReferenceKcal,
    required this.tdeeKcal,
    required this.baseAdjustmentKcal,
    required this.effectiveAdjustmentKcal,
    required this.manualKcalAdjustment,
    required this.activityKcal,
    required this.totalKcalGoal,
    required this.carbsFractionGoal,
    required this.fatsFractionGoal,
    required this.proteinsFractionGoal,
    required this.carbsGoalGrams,
    required this.fatsGoalGrams,
    required this.proteinsGoalGrams,
  });

  /// Whether the taper actually changed the adjustment for this snapshot.
  bool get taperChangedAdjustment =>
      taperEnabled && baseAdjustmentKcal != effectiveAdjustmentKcal;

  /// Whether the averaged non-binary midpoint is in effect.
  bool get usesAveragedReference =>
      tdeeMaleReferenceKcal != null && tdeeFemaleReferenceKcal != null;

  factory KcalGoalBreakdownEntity.compute({
    required UserEntity user,
    double? userKcalAdjustment,
    required double totalKcalActivities,
    double? userCarbsGoalPct,
    double? userFatsGoalPct,
    double? userProteinsGoalPct,
  }) {
    final palValue = PalCalc.getPALValueFromActivityCategory(user);

    // Resolve which reference formula sides participate, mirroring
    // TDEECalc.getTDEEKcalIOM2005 exactly.
    bool usesMaleSide;
    bool usesFemaleSide;
    switch (user.gender) {
      case UserGenderEntity.male:
        usesMaleSide = true;
        usesFemaleSide = false;
        break;
      case UserGenderEntity.female:
        usesMaleSide = false;
        usesFemaleSide = true;
        break;
      case UserGenderEntity.nonBinary:
        switch (user.caloriesProfile ?? CaloriesProfileEntity.averaged) {
          case CaloriesProfileEntity.averaged:
            usesMaleSide = true;
            usesFemaleSide = true;
            break;
          case CaloriesProfileEntity.estrogenTypical:
            usesMaleSide = false;
            usesFemaleSide = true;
            break;
          case CaloriesProfileEntity.testosteroneTypical:
            usesMaleSide = true;
            usesFemaleSide = false;
            break;
        }
    }

    final paMale = usesMaleSide
        ? PalCalc.getPAValueForFormula(palValue: palValue, isMaleFormula: true)
        : null;
    final paFemale = usesFemaleSide
        ? PalCalc.getPAValueForFormula(palValue: palValue, isMaleFormula: false)
        : null;
    final tdeeMale = usesMaleSide
        ? TDEECalc.iom2005MaleReferenceKcal(user, palValue)
        : null;
    final tdeeFemale = usesFemaleSide
        ? TDEECalc.iom2005FemaleReferenceKcal(user, palValue)
        : null;
    final tdee = TDEECalc.getTDEEKcalIOM2005(user);

    final baseAdjustment = CalorieGoalCalc.getKcalGoalAdjustment(
      user.goal,
      weeklyWeightGoalKg: user.weeklyWeightGoalKg,
    );
    final effectiveAdjustment = CalorieGoalCalc.applyTargetWeightTaper(
      baseAdjustment: baseAdjustment,
      currentWeightKg: user.weightKG,
      targetWeightKg: user.targetWeightKg,
      goal: user.goal,
      taperEnabled: user.caloriesTaperEnabled,
    );

    final totalGoal = CalorieGoalCalc.getTotalKcalGoal(
      user,
      totalKcalActivities,
      kcalUserAdjustment: userKcalAdjustment,
      caloriesTaperEnabled: user.caloriesTaperEnabled,
    );

    final carbsGrams = MacroCalc.getTotalCarbsGoal(
      totalGoal,
      userCarbsGoal: userCarbsGoalPct,
    );
    final fatsGrams = MacroCalc.getTotalFatsGoal(
      totalGoal,
      userFatsGoal: userFatsGoalPct,
    );
    final proteinsGrams = MacroCalc.getTotalProteinsGoal(
      totalGoal,
      userProteinsGoal: userProteinsGoalPct,
    );

    return KcalGoalBreakdownEntity(
      age: user.age,
      heightCM: user.heightCM,
      weightKG: user.weightKG,
      gender: user.gender,
      caloriesProfile: user.caloriesProfile,
      palCategory: user.pal,
      goal: user.goal,
      weeklyWeightGoalKg: user.weeklyWeightGoalKg,
      targetWeightKg: user.targetWeightKg,
      taperEnabled: user.caloriesTaperEnabled,
      palValue: palValue,
      paMaleFormula: paMale,
      paFemaleFormula: paFemale,
      tdeeMaleReferenceKcal: tdeeMale,
      tdeeFemaleReferenceKcal: tdeeFemale,
      tdeeKcal: tdee,
      baseAdjustmentKcal: baseAdjustment,
      effectiveAdjustmentKcal: effectiveAdjustment,
      manualKcalAdjustment: userKcalAdjustment ?? 0,
      activityKcal: totalKcalActivities,
      totalKcalGoal: totalGoal,
      carbsFractionGoal: userCarbsGoalPct ?? MacroCalc.defaultCarbsPercentageGoal,
      fatsFractionGoal: userFatsGoalPct ?? MacroCalc.defaultFatsPercentageGoal,
      proteinsFractionGoal:
          userProteinsGoalPct ?? MacroCalc.defaultProteinsPercentageGoal,
      carbsGoalGrams: carbsGrams,
      fatsGoalGrams: fatsGrams,
      proteinsGoalGrams: proteinsGrams,
    );
  }

  @override
  List<Object?> get props => [
    age,
    heightCM,
    weightKG,
    gender,
    caloriesProfile,
    palCategory,
    goal,
    weeklyWeightGoalKg,
    targetWeightKg,
    taperEnabled,
    palValue,
    paMaleFormula,
    paFemaleFormula,
    tdeeMaleReferenceKcal,
    tdeeFemaleReferenceKcal,
    tdeeKcal,
    baseAdjustmentKcal,
    effectiveAdjustmentKcal,
    manualKcalAdjustment,
    activityKcal,
    totalKcalGoal,
    carbsFractionGoal,
    fatsFractionGoal,
    proteinsFractionGoal,
    carbsGoalGrams,
    fatsGoalGrams,
    proteinsGoalGrams,
  ];
}
