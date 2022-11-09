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

  /// Adds new tracked calories to DB.
  /// If day was not tracked, a new tracked day item will be persisted
  Future<void> addDayTrackedCalories(DateTime day, double addCalories) async {
    if (await _trackedDayDataSource.hasTrackedDay(day)) {
      _trackedDayDataSource.addDayCaloriesTracked(day, addCalories);
    } else {
      _trackedDayDataSource.saveTrackedDay(TrackedDayDBO(
          // TODO get total calories
          day: day,
          calorieGoal: 2000,
          caloriesTracked: addCalories));
    }
  }
}
