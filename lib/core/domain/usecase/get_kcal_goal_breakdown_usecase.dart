import 'package:collection/collection.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/kcal_goal_breakdown_entity.dart';

/// Assembles the full transparency breakdown of today's kcal goal.
///
/// Inputs are fetched exactly the way [GetKcalGoalUsecase] fetches them
/// (same repositories, same activity date) so the breakdown's total always
/// matches the goal shown on the home screen.
class GetKcalGoalBreakdownUsecase {
  final UserRepository _userRepository;
  final ConfigRepository _configRepository;
  final UserActivityRepository _userActivityRepository;

  GetKcalGoalBreakdownUsecase(
    this._userRepository,
    this._configRepository,
    this._userActivityRepository,
  );

  Future<KcalGoalBreakdownEntity> getBreakdown() async {
    final user = await _userRepository.getUserData();
    final config = await _configRepository.getConfig();
    final totalKcalActivities =
        (await _userActivityRepository.getAllUserActivityByDate(
          DateTime.now(),
        )).map((activity) => activity.burnedKcal).toList().sum;
    return KcalGoalBreakdownEntity.compute(
      user: user,
      userKcalAdjustment: config.userKcalAdjustment,
      totalKcalActivities: totalKcalActivities,
      userCarbsGoalPct: config.userCarbGoalPct,
      userFatsGoalPct: config.userFatGoalPct,
      userProteinsGoalPct: config.userProteinGoalPct,
    );
  }
}
