import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';

/// Brings a tracked day's calorie goal in line with the stored user, as
/// `ProfileBloc.updateUser` does after a profile edit.
///
/// The weight log's writers — saving or deleting a weight, and the health
/// weight import — call it themselves when they move the current weight,
/// inside the tracked-day lock they moved it under. The refresh their
/// screens run afterwards is bound to the profile active at that moment, so
/// a profile switch queued behind the write drops it, and nothing later
/// would correct that profile's goal: switching back keeps an existing
/// day's goal.
class UpdateTodayCalorieGoalUsecase {
  final UserRepository _userRepository;
  final TrackedDayRepository _trackedDayRepository;
  final GetKcalGoalUsecase _getKcalGoalUsecase;

  UpdateTodayCalorieGoalUsecase(
    this._userRepository,
    this._trackedDayRepository,
    this._getKcalGoalUsecase,
  );

  /// Recalculates the goal of the tracked day [day] falls on, if it has
  /// one, and returns whether the stored goal changed. Does nothing when no
  /// user is stored, and writes nothing when the goal is already in line.
  Future<bool> updateGoal(DateTime day) async {
    if (!await _userRepository.hasUserData()) return false;
    final trackedDay = await _trackedDayRepository.getTrackedDay(day);
    if (trackedDay == null) return false;
    final user = await _userRepository.getUserData();
    final goal = await _getKcalGoalUsecase.getKcalGoal(userEntity: user);
    if (goal == trackedDay.calorieGoal) return false;
    await _trackedDayRepository.updateDayCalorieGoal(day, goal);
    return true;
  }
}
