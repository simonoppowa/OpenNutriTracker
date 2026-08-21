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
  ///
  /// An imported workout ([UserActivityEntity.externalId] set) is the third
  /// case: its kcal is what the device measured, scaled by the user's credit
  /// multiplier, and a MET recompute would throw that measurement away for a
  /// formula estimate. Its credit is scaled with the duration instead.
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
    if (activity.externalId != null) {
      // Proportional to the duration the user just corrected: half the time
      // credits half the calories. sourceReportedKcal is deliberately left
      // alone — the device reported what it reported, whatever the user
      // later says the session's length was.
      final oldDuration = activity.duration;
      final newBurnedKcal = oldDuration > 0
          ? activity.burnedKcal * (newValue / oldDuration)
          : activity.burnedKcal;
      return _userActivityRepository.updateUserActivity(
        activity.id,
        newValue,
        newBurnedKcal,
        // Kept in step with burnedKcal the way the importer writes them, so
        // the next edit still prefills a measured figure rather than a MET
        // one.
        userKcal: newBurnedKcal,
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
