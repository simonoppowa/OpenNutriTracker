import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:provider/provider.dart';

class AddTrackedDayUsecase {
  Future<void> updateDayCalorieGoal(
      BuildContext context, DateTime day, double calorieGoal) async {
    final trackedDayRepository =
        Provider.of<TrackedDayRepository>(context, listen: false);
    trackedDayRepository.updateDayCalorieGoal(day, calorieGoal);
  }

  Future<void> increaseDayCalorieGoal(
      BuildContext context, DateTime day, double amount) async {
    final trackedDayRepository =
        Provider.of<TrackedDayRepository>(context, listen: false);
    trackedDayRepository.increaseDayCalorieGoal(day, amount);
  }

  Future<void> reduceDayCalorieGoal(
      BuildContext context, DateTime day, double amount) async {
    final trackedDayRepository =
        Provider.of<TrackedDayRepository>(context, listen: false);
    trackedDayRepository.reduceDayCalorieGoal(day, amount);
  }

  Future<bool> hasTrackedDay(BuildContext context, DateTime day) async {
    final trackedDayRepository =
        Provider.of<TrackedDayRepository>(context, listen: false);
    return await trackedDayRepository.hasTrackedDay(day);
  }

  Future<void> addNewTrackedDay(
      BuildContext context, DateTime day, totalKcalGoal) async {
    final trackedDayRepository =
        Provider.of<TrackedDayRepository>(context, listen: false);
    return await trackedDayRepository.addNewTrackedDay(day, totalKcalGoal);
  }

  Future<void> addDayCaloriesTracked(
      BuildContext context, DateTime day, double caloriesTracked) async {
    final trackedDayRepository =
        Provider.of<TrackedDayRepository>(context, listen: false);
    trackedDayRepository.addDayTrackedCalories(day, caloriesTracked);
  }

  Future<void> removeDayCaloriesTracked(
      BuildContext context, DateTime day, double caloriesTracked) async {
    final trackedDayRepository =
        Provider.of<TrackedDayRepository>(context, listen: false);
    await trackedDayRepository.removeDayTrackedCalories(day, caloriesTracked);
  }
}
