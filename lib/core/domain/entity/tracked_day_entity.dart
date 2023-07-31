import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';

class TrackedDayEntity extends Equatable {
  
  static const maxKcalDifference = 500;
  
  final DateTime day;
  final double calorieGoal;
  final double caloriesTracked;

  const TrackedDayEntity(
      {required this.day,
      required this.calorieGoal,
      required this.caloriesTracked});

  factory TrackedDayEntity.fromTrackedDayDBO(TrackedDayDBO trackedDayDBO) {
    return TrackedDayEntity(
        day: trackedDayDBO.day,
        calorieGoal: trackedDayDBO.calorieGoal,
        caloriesTracked: trackedDayDBO.caloriesTracked);
  }

  // TODO: make enum class for rating
  Color getCalendarDayRatingColor(BuildContext context) {
    if ((calorieGoal - caloriesTracked).abs() < maxKcalDifference) {
      return Theme.of(context).colorScheme.primary;
    } else {
      return Theme.of(context).colorScheme.error;
    }
  }

  Color getRatingDayTextColor(BuildContext context) {
    if ((calorieGoal - caloriesTracked).abs() < maxKcalDifference) {
      return Theme.of(context).colorScheme.onSecondaryContainer;
    } else {
      return Theme.of(context).colorScheme.onErrorContainer;
    }
  }

  Color getRatingDayTextBackgroundColor(BuildContext context) {
    if ((calorieGoal - caloriesTracked).abs() < maxKcalDifference) {
      return Theme.of(context).colorScheme.secondaryContainer;
    } else {
      return Theme.of(context).colorScheme.errorContainer;
    }
  }

  @override
  List<Object?> get props => [day, calorieGoal, caloriesTracked];
}
