import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class UserActivityDataSource {
  final log = Logger('UserActivityDataSource');
  final HiveDBProvider _db;

  UserActivityDataSource(this._db);

  Box<UserActivityDBO> get _userActivityBox => _db.userActivityBox;

  Future<void> addUserActivity(UserActivityDBO userActivityDBO) async {
    log.fine('Adding new user activity to db');
    await _userActivityBox.add(userActivityDBO);
  }

  Future<void> addAllUserActivities(
    List<UserActivityDBO> userActivityDBOList,
  ) async {
    log.fine('Adding new user activities to db');
    await _userActivityBox.addAll(userActivityDBOList);
  }

  Future<UserActivityDBO?> updateUserActivity(
    String id,
    double newDuration,
    double newBurnedKcal, {
    double? userKcal,
  }) async {
    log.fine('Updating user activity in db');
    final existing =
        _userActivityBox.values.firstWhereOrNull((dbo) => dbo.id == id);
    if (existing == null) return null;
    final updated = UserActivityDBO(
      existing.id,
      newDuration,
      newBurnedKcal,
      existing.date,
      existing.physicalActivityDBO,
      userKcal: userKcal ?? existing.userKcal,
    );
    await existing.delete();
    await _userActivityBox.add(updated);
    return updated;
  }

  Future<void> deleteIntakeFromId(String activityId) async {
    log.fine('Deleting activity item from db');
    final toDelete = _userActivityBox.values
        .where((dbo) => dbo.id == activityId)
        .toList();
    for (final element in toDelete) {
      await element.delete();
    }
  }

  Future<List<UserActivityDBO>> getAllUserActivities() async {
    return _userActivityBox.values.toList();
  }

  Future<List<UserActivityDBO>> getAllUserActivitiesByDate(
    DateTime dateTime, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async {
    // #139: see IntakeDataSource for the rationale — a zero total offset
    // preserves the original wall-clock day behaviour. The follow-up to
    // #139 adds the minutes companion which composes additively here.
    final totalMinutes = dayStartOffsetHours * 60 +
        dayStartOffsetMinutes.clamp(0, 59);
    if (totalMinutes == 0) {
      return _userActivityBox.values
          .where((activity) => DateUtils.isSameDay(dateTime, activity.date))
          .toList();
    }
    return _userActivityBox.values
        .where(
          (activity) => DayBoundaryCalc.isSameLogicalDayMinutes(
            dateTime,
            activity.date,
            totalMinutes,
          ),
        )
        .toList();
  }

  Future<List<UserActivityDBO>> getRecentlyAddedUserActivity(
      {int number = 100}) async {
    final userActivities = _userActivityBox.values.toList();

    //  sort list by date descending and filter unique activities
    userActivities.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    final filterActivityCodes = <String>{};
    final uniqueUserActivities = userActivities
        .where(
          (activity) =>
              filterActivityCodes.add(activity.physicalActivityDBO.code),
        )
        .toList();

    // return range or full list
    try {
      return uniqueUserActivities.getRange(0, number).toList();
    } on RangeError catch (_) {
      return uniqueUserActivities.toList();
    }
  }
}
