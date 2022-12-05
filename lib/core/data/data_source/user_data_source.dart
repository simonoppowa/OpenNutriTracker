import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';

class UserDataSource {
  static const _userKey = "UserKey";
  final log = Logger('UserDataSource');
  final Box<UserDBO> _userBox;

  UserDataSource(this._userBox);

  Future<void> saveUserData(UserDBO userDBO) async {
    log.fine('Updating user in db');
    _userBox.put(_userKey, userDBO);
  }

  Future<bool> hasUserData() async => _userBox.containsKey(_userKey);

  // TODO remove dummy data
  Future<UserDBO> getUserData() async {
    return _userBox.get(_userKey) ??
        UserDBO(
            birthday: DateTime(2000, 1, 1),
            heightCM: 180,
            weightKG: 80,
            gender: UserGenderDBO.male,
            goal: UserWeightGoalDBO.maintainWeight,
            pal: UserPALDBO.active);
  }
}
