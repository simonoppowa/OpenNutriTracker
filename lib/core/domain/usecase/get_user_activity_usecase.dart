import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';

class GetUserActivityUsecase {
  final UserActivityRepository _userActivityRepository;

  GetUserActivityUsecase(this._userActivityRepository);

  // #139: callers pass [dayStartOffsetHours] when they have the user's
  // configured boundary; defaulting to 0 keeps every existing caller's
  // wall-clock-midnight behaviour exactly the same.
  Future<List<UserActivityEntity>> getTodayUserActivity({
    int dayStartOffsetHours = 0,
  }) {
    return _userActivityRepository.getAllUserActivityByDate(
      DateTime.now(),
      dayStartOffsetHours: dayStartOffsetHours,
    );
  }

  Future<List<UserActivityEntity>> getUserActivityByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
  }) {
    return _userActivityRepository.getAllUserActivityByDate(
      day,
      dayStartOffsetHours: dayStartOffsetHours,
    );
  }

  Future<List<UserActivityEntity>> getRecentUserActivity() {
    return _userActivityRepository.getRecentUserActivity();
  }
}
