import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';

class TrackedDayEntity {
  final DateTime day;
  final double calorieGoal;
  final double caloriesTracked;

  TrackedDayEntity(
      {required this.day,
      required this.calorieGoal,
      required this.caloriesTracked});

  factory TrackedDayEntity.fromTrackedDayDBO(TrackedDayDBO trackedDayDBO) {
    return TrackedDayEntity(
        day: trackedDayDBO.day,
        calorieGoal: trackedDayDBO.calorieGoal,
        caloriesTracked: trackedDayDBO.caloriesTracked);
  }

  // TODO Change calorie difference
  Color getRatingColor(BuildContext context) {
    if (calorieGoal - caloriesTracked < 500) {
      return Theme.of(context).colorScheme.primaryContainer;
    } else {
      return Theme.of(context).colorScheme.error;
    }
  }

}
