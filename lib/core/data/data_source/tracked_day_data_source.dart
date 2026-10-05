import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class TrackedDayDataSource {
  final log = Logger('TrackedDayDataSource');
  final HiveDBProvider _db;

  TrackedDayDataSource(this._db);

  Box<TrackedDayDBO> get _trackedDayBox => _db.trackedDayBox;

  /// The diary day whose row [day] names (#1317).
  ///
  /// Callers hand this source either a day label — a Diary cell, or
  /// HomeBloc's resolved logical day — or a moment: an entry's own
  /// timestamp, or a raw `DateTime.now()` from Home. A moment has to land
  /// on the row of the day the Diary lists an entry stamped with it
  /// under, or with a day-start boundary configured an entry logged at
  /// 02:00 is listed on one day while its row is created on the next, and
  /// the Diary reports "Nothing added" beside it. Labels pass through
  /// unchanged, so the boundary is only read for a moment.
  Future<DateTime> _diaryDayOf(DateTime day) async {
    if (DayBoundaryCalc.isDayLabel(day)) return day;
    final config = ConfigEntity.fromConfigDBO(
      await ConfigDataSource(_db).getConfig(),
    );
    return DayBoundaryCalc.dayLabelOf(day, config.dayStartOffsetTotalMinutes);
  }

  Future<void> saveTrackedDay(TrackedDayDBO trackedDayDBO) async {
    log.fine('Updating tracked day in db');
    // Stored as the label too: the Diary calendar keys its map by `day`.
    trackedDayDBO.day = await _diaryDayOf(trackedDayDBO.day);
    await _trackedDayBox.put(trackedDayDBO.day.toParsedDay(), trackedDayDBO);
  }

  Future<void> saveAllTrackedDays(List<TrackedDayDBO> trackedDayDBOList) async {
    log.fine('Updating tracked days in db');
    await _trackedDayBox.putAll({
      for (var trackedDayDBO in trackedDayDBOList)
        trackedDayDBO.day.toParsedDay(): trackedDayDBO,
    });
  }

  Future<List<TrackedDayDBO>> getAllTrackedDays() async {
    return _trackedDayBox.values.toList();
  }

  Future<TrackedDayDBO?> getTrackedDay(DateTime day) async {
    return _trackedDayBox.get((await _diaryDayOf(day)).toParsedDay());
  }

  Future<List<TrackedDayDBO>> getTrackedDaysInRange(
    DateTime start,
    DateTime end,
  ) async {
    List<TrackedDayDBO> trackedDays = _trackedDayBox.values
        .where(
          (trackedDay) =>
              !trackedDay.day.isBefore(start) && !trackedDay.day.isAfter(end),
        )
        .toList();
    return trackedDays;
  }

  Future<bool> hasTrackedDay(DateTime day) async =>
      await getTrackedDay(day) != null;

  Future<void> updateDayCalorieGoal(DateTime day, double calorieGoal) async {
    log.fine('Updating tracked day total calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.calorieGoal = calorieGoal;
      await updateDay.save();
    }
  }

  Future<void> increaseDayCalorieGoal(DateTime day, double amount) async {
    log.fine('Increasing tracked day total calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.calorieGoal += amount;
      await updateDay.save();
    }
  }

  Future<void> reduceDayCalorieGoal(DateTime day, double amount) async {
    log.fine('Reducing tracked day total calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.calorieGoal -= amount;
      await updateDay.save();
    }
  }

  Future<void> addDayCaloriesTracked(DateTime day, double addCalories) async {
    log.fine('Adding new tracked day calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.caloriesTracked += addCalories;
      await updateDay.save();
    }
  }

  Future<void> decreaseDayCaloriesTracked(
    DateTime day,
    double addCalories,
  ) async {
    log.fine('Decreasing tracked day calories');
    final updateDay = await getTrackedDay(day);

    if (updateDay != null) {
      updateDay.caloriesTracked -= addCalories;
      await updateDay.save();
    }
  }

  Future<void> updateDayMacroGoals(
    DateTime day, {
    double? carbsGoal,
    double? fatGoal,
    double? proteinGoal,
  }) async {
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
      await updateDay.save();
    }
  }

  Future<void> increaseDayMacroGoal(
    DateTime day, {
    double? carbsAmount,
    double? fatAmount,
    double? proteinAmount,
  }) async {
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
      await updateDay.save();
    }
  }

  Future<void> reduceDayMacroGoal(
    DateTime day, {
    double? carbsAmount,
    double? fatAmount,
    double? proteinAmount,
  }) async {
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
      await updateDay.save();
    }
  }

  Future<void> addDayMacroTracked(
    DateTime day, {
    double? carbsAmount,
    double? fatAmount,
    double? proteinAmount,
  }) async {
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
      await updateDay.save();
    }
  }

  Future<void> removeDayMacroTracked(
    DateTime day, {
    double? carbsAmount,
    double? fatAmount,
    double? proteinAmount,
  }) async {
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
      await updateDay.save();
    }
  }

  // #173 (+follow-up): update the user-configured per-nutrient goal
  // columns for the given day. Each value is optional — pass null to
  // leave that column untouched. The receiving columns themselves
  // remain nullable on disk, with null meaning "no override, use the
  // default reference". Units follow the convention documented on
  // TrackedDayDBO: g for fibre/satFat/sugars; mg for sodium, calcium,
  // iron, potassium, magnesium, B12; µg for vitamin D.
  Future<void> updateDayNutrientGoals(
    DateTime day, {
    double? fibreGoal,
    double? satFatGoal,
    double? sugarsGoal,
    double? sodiumGoal,
    double? calciumGoal,
    double? ironGoal,
    double? potassiumGoal,
    double? vitaminDGoal,
    double? vitaminB12Goal,
    double? magnesiumGoal,
  }) async {
    log.fine('Updating tracked day nutrient goals');
    final updateDay = await getTrackedDay(day);
    if (updateDay != null) {
      if (fibreGoal != null) {
        updateDay.fibreGoal = fibreGoal;
      }
      if (satFatGoal != null) {
        updateDay.satFatGoal = satFatGoal;
      }
      if (sugarsGoal != null) {
        updateDay.sugarsGoal = sugarsGoal;
      }
      if (sodiumGoal != null) {
        updateDay.sodiumGoal = sodiumGoal;
      }
      if (calciumGoal != null) {
        updateDay.calciumGoal = calciumGoal;
      }
      if (ironGoal != null) {
        updateDay.ironGoal = ironGoal;
      }
      if (potassiumGoal != null) {
        updateDay.potassiumGoal = potassiumGoal;
      }
      if (vitaminDGoal != null) {
        updateDay.vitaminDGoal = vitaminDGoal;
      }
      if (vitaminB12Goal != null) {
        updateDay.vitaminB12Goal = vitaminB12Goal;
      }
      if (magnesiumGoal != null) {
        updateDay.magnesiumGoal = magnesiumGoal;
      }
      await updateDay.save();
    }
  }

  Future<void> reconcileCaloriesAndMacrosTracked(
    DateTime day,
    double calories,
    double carbs,
    double fat,
    double protein,
  ) async {
    log.fine('Reconciling tracked day calories and macros from actual intakes');
    final updateDay = await getTrackedDay(day);
    if (updateDay != null) {
      updateDay.caloriesTracked = calories;
      updateDay.carbsTracked = carbs;
      updateDay.fatTracked = fat;
      updateDay.proteinTracked = protein;
      await updateDay.save();
    }
  }
}
