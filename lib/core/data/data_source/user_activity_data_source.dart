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

  Future<void> addAllUserActivities(
      List<UserActivityDBO> userActivityDBOList) async {
    log.fine('Adding new user activities to db');
    _userActivityBox.addAll(userActivityDBOList);
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

  Future<List<UserActivityDBO>> getAllUserActivities() async {
    return _userActivityBox.values.toList();
  }
  Future<List<UserActivityDBO>> getAllUserActivitiesByDate(
      DateTime dateTime) async {
    return _userActivityBox.values
        .where((activity) => DateUtils.isSameDay(dateTime, activity.date))
        .toList();
  }

  Future<List<UserActivityDBO>> getRecentlyAddedUserActivity(
      {int number = 20}) async {
    final userActivities = _userActivityBox.values.toList().reversed;

    //  sort list by date and filter unique activities
    userActivities
        .toList()
        .sort((a, b) => a.date.toString().compareTo(b.date.toString()));

    final filterActivityCodes = <String>{};
    final uniqueUserActivities = userActivities
        .where((activity) =>
            filterActivityCodes.add(activity.physicalActivityDBO.code))
        .toList();

    // return range or full list
    try {
      return uniqueUserActivities.getRange(0, number).toList();
    } on RangeError catch (_) {
      return uniqueUserActivities.toList();
    }
  }
}
