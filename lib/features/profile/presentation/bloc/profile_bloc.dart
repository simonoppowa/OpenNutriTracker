import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/bmi_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';

part 'profile_event.dart';

part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetUserUsecase _getUserUsecase;
  final AddUserUsecase _addUserUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetConfigUsecase _getConfigUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;

  ProfileBloc(
    this._getUserUsecase,
    this._addUserUsecase,
    this._addTrackedDayUsecase,
    this._getConfigUsecase,
    this._getKcalGoalUsecase,
  ) : super(ProfileInitial()) {
    on<LoadProfileEvent>((event, emit) async {
      emit(ProfileLoadingState());

      final user = await _getUserUsecase.getUserData();
      final userBMIValue = BMICalc.getBMI(user);
      final userBMIEntity = UserBMIEntity(
        bmiValue: userBMIValue,
        nutritionalStatus: BMICalc.getNutritionalStatus(userBMIValue),
      );
      final userConfig = await _getConfigUsecase.getConfig();

      emit(
        ProfileLoadedState(
          userBMI: userBMIEntity,
          userEntity: user,
          bodyWeightUnit: userConfig.bodyWeightUnit,
          usesImperialHeightUnits: userConfig.usesImperialHeightUnits,
          effectiveWaterGoalMl: userConfig.effectiveDailyWaterGoalMl(
            user.gender,
            caloriesProfile: user.caloriesProfile,
          ),
        ),
      );
    });
  }

  Future<UserEntity> getUser() => _getUserUsecase.getUserData();

  /// Persist the opt-in calorie-deficit taper. Toggling re-runs the
  /// kcal-goal calc on today's tracked day so the saved goal reflects
  /// the new value immediately rather than waiting for the next day.
  Future<void> setCaloriesTaperEnabled(bool enabled) async {
    final startedOn = ProfileStamp.now();
    final user = await _getUserUsecase.getUserData();
    user.caloriesTaperEnabled = enabled;
    await _updateUser(user, startedOn);
  }

  Future<void> updateUser(UserEntity userEntity) =>
      _updateUser(userEntity, ProfileStamp.now());

  /// Runs what saving a weight change sets off — today's calorie goal and
  /// every screen that reads the user — for a weight that reached the user
  /// record without going through [updateUser]. The health weight import
  /// writes the current weight itself and calls this afterwards, as does
  /// deleting the imported entry that weight came from.
  ///
  /// The user is read inside the lock, not before it: an edit saved through
  /// [updateUser] while this waited would otherwise have its goal replaced
  /// by one worked out from the older user. Nothing is refreshed when no
  /// user is left — "Delete all my data" can land before a late signal.
  Future<void> reloadAfterWeightImport() async {
    final startedOn = ProfileStamp.now();
    final updated = await withTrackedDayLockOnProfile(() async {
      if (!await _getUserUsecase.hasUserData()) return false;
      final user = await _getUserUsecase.getUserData();
      await _updateTrackedDayCalorieGoal(user, DateTime.now());
      return true;
    }, startedOn: startedOn);
    if (updated != true) return;
    _reloadAfterUserChange();
  }

  Future<void> _updateUser(
    UserEntity userEntity,
    ProfileStamp startedOn,
  ) async {
    final updated = await withTrackedDayLockOnProfile(() async {
      await _addUserUsecase.addUser(userEntity);
      await _updateTrackedDayCalorieGoal(userEntity, DateTime.now());
      return true;
    }, startedOn: startedOn);
    if (updated != true) return;
    _reloadAfterUserChange();
  }

  void _reloadAfterUserChange() {
    // Refresh Profile
    add(LoadProfileEvent());
    // Refresh Home Page
    locator<HomeBloc>().add(const LoadItemsEvent());
    // Refresh Diary Page
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
    // Refresh Trends Page — preserve whatever range chip is currently
    // selected there rather than resetting it back to the 7-day default.
    final trendsBloc = locator<TrendsBloc>();
    final rangeDays = trendsBloc.state is TrendsLoaded
        ? (trendsBloc.state as TrendsLoaded).rangeDays
        : 7;
    trendsBloc.add(LoadTrendsEvent(rangeDays: rangeDays));
  }

  Future<void> _updateTrackedDayCalorieGoal(UserEntity user, DateTime day) =>
      // The goal counts the day's activities, so it is read and written
      // with no boundary move between (#1317).
      withTrackedDayLock(() async {
        final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);
        if (hasTrackedDay) {
          final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal(
            userEntity: user,
          );

          await _addTrackedDayUsecase.updateDayCalorieGoal(day, totalKcalGoal);
        }
      });
}
