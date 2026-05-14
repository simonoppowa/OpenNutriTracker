import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';

class TrackedDayEntity extends Equatable {
  static const maxKcalDifferenceOverGoal = 500;
  static const maxKcalDifferenceUnderGoal = 1000;

  final DateTime day;
  final double calorieGoal;
  final double caloriesTracked;
  final double? carbsGoal;
  final double? carbsTracked;
  final double? fatGoal;
  final double? fatTracked;
  final double? proteinGoal;
  final double? proteinTracked;

  // #173: user-set per-nutrient targets. Null means "fall back to the
  // default reference"; non-null means the user has set their own goal
  // in Settings → Calculations.
  //
  // Unit convention (mirrors TrackedDayDBO):
  //   fibreGoal, satFatGoal, sugarsGoal               — grams
  //   sodiumGoal, calciumGoal, ironGoal,
  //   potassiumGoal, magnesiumGoal, vitaminB12Goal    — milligrams
  //   vitaminDGoal                                    — micrograms
  final double? fibreGoal;
  final double? satFatGoal;
  final double? sugarsGoal;
  // Follow-up to #173: the remaining seven panel nutrients. The three
  // D / B12 / Mg fields are wired here too even though their panel rows
  // only land when #160's expansion follow-up rebases through.
  final double? sodiumGoal;
  final double? calciumGoal;
  final double? ironGoal;
  final double? potassiumGoal;
  final double? vitaminDGoal;
  final double? vitaminB12Goal;
  final double? magnesiumGoal;

  const TrackedDayEntity({
    required this.day,
    required this.calorieGoal,
    required this.caloriesTracked,
    this.carbsGoal,
    this.carbsTracked,
    this.fatGoal,
    this.fatTracked,
    this.proteinGoal,
    this.proteinTracked,
    this.fibreGoal,
    this.satFatGoal,
    this.sugarsGoal,
    this.sodiumGoal,
    this.calciumGoal,
    this.ironGoal,
    this.potassiumGoal,
    this.vitaminDGoal,
    this.vitaminB12Goal,
    this.magnesiumGoal,
  });

  factory TrackedDayEntity.fromTrackedDayDBO(TrackedDayDBO trackedDayDBO) {
    return TrackedDayEntity(
      day: trackedDayDBO.day,
      calorieGoal: trackedDayDBO.calorieGoal,
      caloriesTracked: trackedDayDBO.caloriesTracked,
      carbsGoal: trackedDayDBO.carbsGoal,
      carbsTracked: trackedDayDBO.carbsTracked,
      fatGoal: trackedDayDBO.fatGoal,
      fatTracked: trackedDayDBO.fatTracked,
      proteinGoal: trackedDayDBO.proteinGoal,
      proteinTracked: trackedDayDBO.proteinTracked,
      fibreGoal: trackedDayDBO.fibreGoal,
      satFatGoal: trackedDayDBO.satFatGoal,
      sugarsGoal: trackedDayDBO.sugarsGoal,
      sodiumGoal: trackedDayDBO.sodiumGoal,
      calciumGoal: trackedDayDBO.calciumGoal,
      ironGoal: trackedDayDBO.ironGoal,
      potassiumGoal: trackedDayDBO.potassiumGoal,
      vitaminDGoal: trackedDayDBO.vitaminDGoal,
      vitaminB12Goal: trackedDayDBO.vitaminB12Goal,
      magnesiumGoal: trackedDayDBO.magnesiumGoal,
    );
  }

  // TODO: make enum class for rating
  Color getCalendarDayRatingColor(BuildContext context) {
    if (_hasExceededMaxKcalDifferenceGoal(calorieGoal, caloriesTracked)) {
      return Theme.of(context).colorScheme.primary;
    } else {
      return Theme.of(context).colorScheme.error;
    }
  }

  Color getRatingDayTextColor(BuildContext context) {
    if (_hasExceededMaxKcalDifferenceGoal(calorieGoal, caloriesTracked)) {
      return Theme.of(context).colorScheme.onSecondaryContainer;
    } else {
      return Theme.of(context).colorScheme.onErrorContainer;
    }
  }

  Color getRatingDayTextBackgroundColor(BuildContext context) {
    if (_hasExceededMaxKcalDifferenceGoal(calorieGoal, caloriesTracked)) {
      return Theme.of(context).colorScheme.secondaryContainer;
    } else {
      return Theme.of(context).colorScheme.errorContainer;
    }
  }

  bool _hasExceededMaxKcalDifferenceGoal(double calorieGoal, caloriesTracked) {
    double difference = calorieGoal - caloriesTracked;

    if (calorieGoal < caloriesTracked) {
      return difference.abs() < maxKcalDifferenceOverGoal;
    } else {
      return difference < maxKcalDifferenceUnderGoal;
    }
  }

  @override
  List<Object?> get props => [
        day,
        calorieGoal,
        caloriesTracked,
        carbsGoal,
        carbsTracked,
        fatGoal,
        fatTracked,
        proteinGoal,
        proteinTracked,
        fibreGoal,
        satFatGoal,
        sugarsGoal,
        sodiumGoal,
        calciumGoal,
        ironGoal,
        potassiumGoal,
        vitaminDGoal,
        vitaminB12Goal,
        magnesiumGoal,
      ];
}
