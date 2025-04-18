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

  Future<void> saveAllTrackedDays(List<TrackedDayDBO> trackedDayDBOList) async {
    log.fine('Updating tracked days in db');
    _trackedDayBox.putAll({
      for (var trackedDayDBO in trackedDayDBOList)
        trackedDayDBO.day.toParsedDay(): trackedDayDBO
    });
  }

  Future<List<TrackedDayDBO>> getAllTrackedDays() async {
    return _trackedDayBox.values.toList();
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

  Future<void> decreaseDayCaloriesTracked(
      DateTime day, double addCalories) async {
    log.fine('Decreasing tracked day calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.caloriesTracked -= addCalories;
      updateDay.save();
    }
  }

  Future<void> updateDayMacroGoals(DateTime day,
      {double? carbsGoal, double? fatGoal, double? proteinGoal}) async {
    log.fine('Updating tracked day macro goals');

    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      if (carbsGoal != null) {
        updateDay.carbsGoal = carbsGoal;
      }
      if (fatGoal != null) {
        updateDay.fatGoal = fatGoal;
      }
      if (proteinGoal != null) {
        updateDay.proteinGoal = proteinGoal;
      }
      updateDay.save();
    }
  }

  Future<void> increaseDayMacroGoal(DateTime day,
      {double? carbsAmount, double? fatAmount, double? proteinAmount}) async {
    log.fine('Increasing tracked day macro goals');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      if (carbsAmount != null) {
        updateDay.carbsGoal = (updateDay.carbsGoal ?? 0) + carbsAmount;
      }
      if (fatAmount != null) {
        updateDay.fatGoal = (updateDay.fatGoal ?? 0) + fatAmount;
      }
      if (proteinAmount != null) {
        updateDay.proteinGoal = (updateDay.proteinGoal ?? 0) + proteinAmount;
      }
      updateDay.save();
    }
  }

  Future<void> reduceDayMacroGoal(DateTime day,
      {double? carbsAmount, double? fatAmount, double? proteinAmount}) async {
    log.fine('Reducing tracked day macro goals');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      if (carbsAmount != null) {
        updateDay.carbsGoal = (updateDay.carbsGoal ?? 0) - carbsAmount;
      }
      if (fatAmount != null) {
        updateDay.fatGoal = (updateDay.fatGoal ?? 0) - fatAmount;
      }
      if (proteinAmount != null) {
        updateDay.proteinGoal = (updateDay.proteinGoal ?? 0) - proteinAmount;
      }
      updateDay.save();
    }
  }

  Future<void> addDayMacroTracked(DateTime day,
      {double? carbsAmount, double? fatAmount, double? proteinAmount}) async {
    log.fine('Adding new tracked day macro');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      if (carbsAmount != null) {
        updateDay.carbsTracked = (updateDay.carbsTracked ?? 0) + carbsAmount;
      }
      if (fatAmount != null) {
        updateDay.fatTracked = (updateDay.fatTracked ?? 0) + fatAmount;
      }
      if (proteinAmount != null) {
        updateDay.proteinTracked =
            (updateDay.proteinTracked ?? 0) + proteinAmount;
      }
      updateDay.save();
    }
  }

  Future<void> removeDayMacroTracked(DateTime day,
      {double? carbsAmount, double? fatAmount, double? proteinAmount}) async {
    log.fine('Removing tracked day macro');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      if (carbsAmount != null) {
        updateDay.carbsTracked = (updateDay.carbsTracked ?? 0) - carbsAmount;
      }
      if (fatAmount != null) {
        updateDay.fatTracked = (updateDay.fatTracked ?? 0) - fatAmount;
      }
      if (proteinAmount != null) {
        updateDay.proteinTracked =
            (updateDay.proteinTracked ?? 0) - proteinAmount;
      }
      updateDay.save();
    }
  }
}
