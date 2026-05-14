import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';

class GetUserActivityUsecase {
  final UserActivityRepository _userActivityRepository;

  GetUserActivityUsecase(this._userActivityRepository);

  // #139: callers pass [dayStartOffsetHours] (and, since the follow-up,
  // [dayStartOffsetMinutes]) when they have the user's configured boundary.
  // Both default to 0 so every existing caller keeps wall-clock-midnight
  // behaviour exactly the same.
  Future<List<UserActivityEntity>> getTodayUserActivity({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) {
    return _userActivityRepository.getAllUserActivityByDate(
      DateTime.now(),
      dayStartOffsetHours: dayStartOffsetHours,
      dayStartOffsetMinutes: dayStartOffsetMinutes,
    );
  }

  Future<List<UserActivityEntity>> getUserActivityByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) {
    return _userActivityRepository.getAllUserActivityByDate(
      day,
      dayStartOffsetHours: dayStartOffsetHours,
      dayStartOffsetMinutes: dayStartOffsetMinutes,
    );
  }

  Future<List<UserActivityEntity>> getRecentUserActivity() {
    return _userActivityRepository.getRecentUserActivity();
  }
}
