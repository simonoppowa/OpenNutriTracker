import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';

class UserActivityDataSource {
  final log = Logger('UserActivityDataSource');
  final Box<UserActivityDBO> _userActivityBox;

  UserActivityDataSource(this._userActivityBox);

  Future<void> addUserActivity(UserActivityDBO userActivityDBO) async {
    log.fine('Adding new user activity to db');
    _userActivityBox.add(userActivityDBO);
  }

  Future<void> deleteIntakeFromId(String activityId) async {
    log.fine('Deleting activity item from db');
    _userActivityBox.values
        .where((dbo) => dbo.id == activityId)
        .toList()
        .forEach((element) {
      element.delete();
    });
  }

  Future<List<UserActivityDBO>> getAllUserActivitiesByDate(
      DateTime dateTime) async {
    return _userActivityBox.values
        .where((activity) => DateUtils.isSameDay(dateTime, activity.date))
        .toList();
  }

  Future<List<UserActivityDBO>> getRecentlyAddedUserActivity(
      {int number = 5}) async {
    final userActivities = _userActivityBox.values.toList();
    userActivities.sort((a, b) => a.date.toString().compareTo(b.toString()));
    return userActivities;
  }
}
