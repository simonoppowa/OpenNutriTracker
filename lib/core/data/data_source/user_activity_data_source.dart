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

  Future<List<UserActivityDBO>> getAllUserActivitiesByDate(
      DateTime dateTime) async {
    return _userActivityBox.values
        .where((activity) => DateUtils.isSameDay(dateTime, activity.date))
        .toList();
  }
}
