import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
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
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;

  UpdateTodayCalorieGoalUsecase(
    this._userRepository,
    this._addTrackedDayUsecase,
    this._getKcalGoalUsecase,
  );

  /// Recalculates the goal of the tracked day [day] falls on, if it has
  /// one. Does nothing when no user is stored.
  Future<void> updateGoal(DateTime day) async {
    if (!await _userRepository.hasUserData()) return;
    if (!await _addTrackedDayUsecase.hasTrackedDay(day)) return;
    final user = await _userRepository.getUserData();
    final goal = await _getKcalGoalUsecase.getKcalGoal(userEntity: user);
    await _addTrackedDayUsecase.updateDayCalorieGoal(day, goal);
  }
}
