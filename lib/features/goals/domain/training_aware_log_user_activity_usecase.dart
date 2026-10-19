import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/log_user_activity_usecase.dart';
import 'package:opennutritracker/features/goals/domain/auto_training_day_usecase.dart';

/// [LogUserActivityUsecase] that also applies automatic training days
/// (#36), so every activity written through it (quick add, the workout
/// import) can make its day a training day. Kept as a subclass so
/// upstream's usecase stays as it is.
///
/// The activity is saved before the switch, so a failed switch is only
/// logged: reporting it as a failed save would invite a duplicate.
class TrainingAwareLogUserActivityUsecase extends LogUserActivityUsecase {
  static final _log = Logger('TrainingAwareLogUserActivityUsecase');

  final AutoTrainingDayUsecase _autoTrainingDayUsecase;

  TrainingAwareLogUserActivityUsecase(
    super._addUserActivityUsecase,
    super._addTrackedDayUsecase,
    super._getKcalGoalUsecase,
    super._getMacroGoalUsecase,
    this._autoTrainingDayUsecase,
  );

  @override
  Future<void> logActivity(
    UserActivityEntity activity, {
    required DateTime day,
  }) async {
    await super.logActivity(activity, day: day);
    try {
      await _autoTrainingDayUsecase.applyAutomatic(day);
    } catch (error, stackTrace) {
      _log.warning('Could not switch to a training day', error, stackTrace);
    }
  }
}
