import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';

class UserActivityRepository {
  final UserActivityDataSource _userActivityDataSource;

  UserActivityRepository(this._userActivityDataSource);

  Future<void> addUserActivity(UserActivityEntity activityEntity) async {
    final activityDBO = UserActivityDBO.fromUserActivityEntity(activityEntity);

    _userActivityDataSource.addUserActivity(activityDBO);
  }

  Future<void> addAllUserActivityDBOs(
      List<UserActivityDBO> userActivityDBOs) async {
    await _userActivityDataSource.addAllUserActivities(userActivityDBOs);
  }

  Future<void> deleteUserActivity(UserActivityEntity userActivityEntity) async {
    await _userActivityDataSource.deleteIntakeFromId(userActivityEntity.id);
  }

  Future<List<UserActivityDBO>> getAllUserActivityDBO() async {
    return await _userActivityDataSource.getAllUserActivities();
  }

  Future<List<UserActivityEntity>> getAllUserActivityByDate(
      DateTime dateTime) async {
    final userActivityDBOList =
        await _userActivityDataSource.getAllUserActivitiesByDate(dateTime);

    return userActivityDBOList
        .map((userActivityDBO) =>
            UserActivityEntity.fromUserActivityDBO(userActivityDBO))
        .toList();
  }

  Future<List<UserActivityEntity>> getRecentUserActivity() async {
    final userActivityDBOList =
        await _userActivityDataSource.getRecentlyAddedUserActivity();
    return userActivityDBOList
        .map((userActivityDBO) =>
            UserActivityEntity.fromUserActivityDBO(userActivityDBO))
        .toList();
  }
}
