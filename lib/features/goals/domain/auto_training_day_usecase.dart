import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/training_plan.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_type_usecase.dart';

/// Turns a rest day with a logged activity into a training day, or offers
/// to, as the user chose (#36, [TrainingPlan.decisionAfterActivity]).
class AutoTrainingDayUsecase {
  final ConfigRepository _configRepository;
  final SetDayTypeUsecase _setDayTypeUsecase;
  final void Function() _onSwitched;

  /// [onSwitched] runs after a day was switched, to refresh what shows it.
  AutoTrainingDayUsecase(
    this._configRepository,
    this._setDayTypeUsecase, {
    required void Function() onSwitched,
  }) : _onSwitched = onSwitched;

  Future<AutoTrainingDayDecision> decide(DateTime day) async =>
      (await _configRepository.getConfig()).trainingPlan.decisionAfterActivity(
        day,
      );

  Future<void> switchToTraining(DateTime day) async {
    await _setDayTypeUsecase.setDayType(day, DayType.training);
    _onSwitched();
  }

  /// Switches [day] when the user chose automatic switching; returns
  /// whether it did. A suggestion is left to the screens that can ask.
  Future<bool> applyAutomatic(DateTime day) async {
    if (await decide(day) != AutoTrainingDayDecision.switchToTraining) {
      return false;
    }
    await switchToTraining(day);
    return true;
  }
}
