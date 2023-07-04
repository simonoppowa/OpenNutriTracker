import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';

class AddTrackedDayUsecase {
  final TrackedDayRepository _trackedDayRepository;

  AddTrackedDayUsecase(this._trackedDayRepository);

  Future<void> updateDayCalorieGoal(DateTime day, double calorieGoal) async {
    await _trackedDayRepository.updateDayCalorieGoal(day, calorieGoal);
  }

  Future<void> increaseDayCalorieGoal(DateTime day, double amount) async {
    await _trackedDayRepository.increaseDayCalorieGoal(day, amount);
  }

  Future<void> reduceDayCalorieGoal(DateTime day, double amount) async {
    await _trackedDayRepository.reduceDayCalorieGoal(day, amount);
  }

  Future<bool> hasTrackedDay(DateTime day) async {
    return await _trackedDayRepository.hasTrackedDay(day);
  }

  Future<void> addNewTrackedDay(DateTime day, totalKcalGoal) async {
    return await _trackedDayRepository.addNewTrackedDay(day, totalKcalGoal);
  }

  Future<void> addDayCaloriesTracked(
      DateTime day, double caloriesTracked) async {
    _trackedDayRepository.addDayTrackedCalories(day, caloriesTracked);
  }

  Future<void> removeDayCaloriesTracked(
      DateTime day, double caloriesTracked) async {
    await _trackedDayRepository.removeDayTrackedCalories(day, caloriesTracked);
  }
}
