import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

class TrackedDayDataSource {
  final log = Logger('TrackedDayDataSource');
  final Box<TrackedDayDBO> _trackedDayBox;

  TrackedDayDataSource(this._trackedDayBox);

  Future<void> saveTrackedDay(TrackedDayDBO trackedDayDBO) async {
    log.fine('Updating tracked day in db');
    _trackedDayBox.put(trackedDayDBO.day.toParsedDay(), trackedDayDBO);
  }

  Future<TrackedDayDBO?> getTrackedDay(DateTime day) async {
    return _trackedDayBox.get(day.toParsedDay());
  }

  Future<List<TrackedDayDBO>> getTrackedDaysInRange(
      DateTime start, DateTime end) async {
    List<TrackedDayDBO> trackedDays = _trackedDayBox.values
        .where((trackedDay) =>
            (trackedDay.day.isAfter(start) && trackedDay.day.isBefore(end)))
        .toList();
    return trackedDays;
  }

  Future<bool> hasTrackedDay(DateTime day) async =>
      _trackedDayBox.get(day.toParsedDay()) != null;

  Future<void> updateDayCalorieGoal(DateTime day, double calorieGoal) async {
    log.fine('Updating tracked day total calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.calorieGoal = calorieGoal;
      updateDay.save();
    }
  }

  Future<void> increaseDayCalorieGoal(DateTime day, double amount) async {
    log.fine('Increasing tracked day total calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.calorieGoal += amount;
      updateDay.save();
    }
  }

  Future<void> reduceDayCalorieGoal(DateTime day, double amount) async {
    log.fine('Reducing tracked day total calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.calorieGoal -= amount;
      updateDay.save();
    }
  }

  Future<void> addDayCaloriesTracked(DateTime day, double addCalories) async {
    log.fine('Adding new tracked day calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.caloriesTracked += addCalories;
      updateDay.save();
    }
  }

  Future<void> removeDayCaloriesTracked(
      DateTime day, double addCalories) async {
    log.fine('Removing tracked day calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.caloriesTracked -= addCalories;
      updateDay.save();
    }
  }
}
