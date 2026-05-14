import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/met_calc.dart';

class UpdateUserActivityUsecase {
  final UserActivityRepository _userActivityRepository;
  final GetUserUsecase _getUserUsecase;

  UpdateUserActivityUsecase(
    this._userActivityRepository,
    this._getUserUsecase,
  );

  /// Updates a logged activity. For most activities [newValue] is the new
  /// duration in minutes, and burned kcal is recomputed via MET. For the
  /// Custom activity type (#70) [newValue] is the new kcal figure the user
  /// entered directly — duration stays at 0 and the kcal is stored on both
  /// [burnedKcal] (so daily aggregation keeps working unchanged) and
  /// [userKcal] (so the next edit prefills the exact value they typed).
  Future<UserActivityEntity?> updateUserActivity(
    UserActivityEntity activity,
    double newValue,
  ) async {
    if (activity.physicalActivityEntity.isCustom) {
      return _userActivityRepository.updateUserActivity(
        activity.id,
        0.0,
        newValue,
        userKcal: newValue,
      );
    }
    final user = await _getUserUsecase.getUserData();
    final newBurnedKcal = METCalc.getTotalBurnedKcal(
      user,
      activity.physicalActivityEntity,
      newValue,
    );
    return _userActivityRepository.updateUserActivity(
      activity.id,
      newValue,
      newBurnedKcal,
    );
  }
}
