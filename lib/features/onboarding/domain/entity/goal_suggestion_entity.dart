import 'dart:math';

import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/utils/calc/bmi_calc.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_goal_selection_entity.dart';

/// What the suggestion was derived from, so the goal page can state its
/// reasoning.
enum GoalSuggestionBasis {
  /// The user entered a target weight on the previous page.
  targetWeight,

  /// No target was entered, so the WHO BMI band is used instead.
  bmi,
}

/// The goal the onboarding flow suggests. Marked, never preselected.
class GoalSuggestionEntity {
  final UserGoalSelectionEntity goal;
  final GoalSuggestionBasis basis;

  /// Set for [GoalSuggestionBasis.bmi] so the page can quote the number and
  /// the band it falls in.
  final double? bmi;
  final UserNutritionalStatus? nutritionalStatus;

  const GoalSuggestionEntity({
    required this.goal,
    required this.basis,
    this.bmi,
    this.nutritionalStatus,
  });

  /// Distance from the target within which the goal reads as "maintain"
  /// rather than a change in either direction.
  static const double maintainToleranceKg = 1.0;

  /// Derives a suggestion, or null when there isn't enough to go on.
  ///
  /// A target weight the user typed one screen earlier wins over the BMI
  /// band. They have already stated where they want to be, and a BMI of 24
  /// with a target 8 kg lower would otherwise produce "maintain".
  static GoalSuggestionEntity? from({
    required double? heightCm,
    required double? weightKg,
    required double? targetWeightKg,
  }) {
    if (weightKg == null) return null;

    if (targetWeightKg != null) {
      final difference = targetWeightKg - weightKg;
      final UserGoalSelectionEntity goal;
      if (difference.abs() <= maintainToleranceKg) {
        goal = UserGoalSelectionEntity.maintainWeight;
      } else if (difference < 0) {
        goal = UserGoalSelectionEntity.loseWeight;
      } else {
        goal = UserGoalSelectionEntity.gainWeigh;
      }
      return GoalSuggestionEntity(
        goal: goal,
        basis: GoalSuggestionBasis.targetWeight,
      );
    }

    if (heightCm == null || heightCm <= 0) return null;
    final bmi = weightKg / pow(heightCm / 100, 2);
    final status = BMICalc.getNutritionalStatus(bmi);
    final UserGoalSelectionEntity goal;
    switch (status) {
      case UserNutritionalStatus.underWeight:
        goal = UserGoalSelectionEntity.gainWeigh;
      case UserNutritionalStatus.normalWeight:
        goal = UserGoalSelectionEntity.maintainWeight;
      case UserNutritionalStatus.preObesity:
      case UserNutritionalStatus.obesityClassI:
      case UserNutritionalStatus.obesityClassII:
      case UserNutritionalStatus.obesityClassIII:
        goal = UserGoalSelectionEntity.loseWeight;
    }
    return GoalSuggestionEntity(
      goal: goal,
      basis: GoalSuggestionBasis.bmi,
      bmi: bmi,
      nutritionalStatus: status,
    );
  }
}
