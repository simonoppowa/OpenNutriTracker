import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';

class UserWeightDataSource {
  final Box<UserWeightDbo> _userWeightBox;

  UserWeightDataSource(this._userWeightBox);

  Future<void> addUserWeight(UserWeightDbo userWeightDbo) async {
    if (_userWeightBox.isNotEmpty) {
      await _userWeightBox.clear();
    }
    await _userWeightBox.add(userWeightDbo);
  }

  Future<UserWeightDbo> getUserWeightByDate(DateTime dateTime) async {
    return _userWeightBox.values
        .firstWhere((dbo) => DateUtils.isSameDay(dbo.date, dateTime));
  }
}
