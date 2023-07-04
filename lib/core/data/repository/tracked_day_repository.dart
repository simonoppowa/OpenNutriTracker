import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';

class TrackedDayRepository {
  final TrackedDayDataSource _trackedDayDataSource;

  TrackedDayRepository(this._trackedDayDataSource);

  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async {
    final trackedDay = await _trackedDayDataSource.getTrackedDay(day);
    if (trackedDay != null) {
      return TrackedDayEntity.fromTrackedDayDBO(trackedDay);
    } else {
      return null;
    }
  }

  Future<bool> hasTrackedDay(DateTime day) async {
    final trackedDay = await getTrackedDay(day);
    if (trackedDay != null) {
      return true;
    } else {
      return false;
    }
  }

  Future<List<TrackedDayEntity>> getTrackedDayByRange(
      DateTime start, DateTime end) async {
    final List<TrackedDayDBO> trackedDaysDBO =
        await _trackedDayDataSource.getTrackedDaysInRange(start, end);

    return trackedDaysDBO
        .map((trackedDayDBO) =>
            TrackedDayEntity.fromTrackedDayDBO(trackedDayDBO))
        .toList();
  }

  Future<void> updateDayCalorieGoal(DateTime day, double calorieGoal) async {
    _trackedDayDataSource.updateDayCalorieGoal(day, calorieGoal);
  }

  Future<void> increaseDayCalorieGoal(DateTime day, double amount) async {
    _trackedDayDataSource.increaseDayCalorieGoal(day, amount);
  }

  Future<void> reduceDayCalorieGoal(DateTime day, double amount) async {
    _trackedDayDataSource.reduceDayCalorieGoal(day, amount);
  }

  Future<void> addNewTrackedDay(DateTime day, double totalKcalGoal) async {
    _trackedDayDataSource.saveTrackedDay(TrackedDayDBO(
        day: day, calorieGoal: totalKcalGoal, caloriesTracked: 0));
  }

  Future<void> addDayTrackedCalories(DateTime day, double addCalories) async {
    if (await _trackedDayDataSource.hasTrackedDay(day)) {
      _trackedDayDataSource.addDayCaloriesTracked(day, addCalories);
    }
  }

  Future<void> removeDayTrackedCalories(
      DateTime day, double addCalories) async {
    if (await _trackedDayDataSource.hasTrackedDay(day)) {
      _trackedDayDataSource.removeDayCaloriesTracked(day, addCalories);
    }
  }
}
