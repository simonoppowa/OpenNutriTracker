import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';

class TrackedDayEntity extends Equatable {
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

  // TODO Change calorie difference
  Color getRatingColor(BuildContext context) {
    if (calorieGoal - caloriesTracked < 500) {
      return Theme.of(context).colorScheme.primaryContainer;
    } else {
      return Theme.of(context).colorScheme.errorContainer;
    }
  }

  @override
  List<Object?> get props => [day, calorieGoal, caloriesTracked];
}
