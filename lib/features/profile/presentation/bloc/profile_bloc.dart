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
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';

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
    final user = await _getUserUsecase.getUserData();
    user.caloriesTaperEnabled = enabled;
    await updateUser(user);
  }

  Future<void> updateUser(UserEntity userEntity) async {
    // Update user in DB
    await _addUserUsecase.addUser(userEntity);

    // Update Tracked Day
    await _updateTrackedDayCalorieGoal(userEntity, DateTime.now());

    // Refresh Profile
    add(LoadProfileEvent());
    // Refresh Home Page
    locator<HomeBloc>().add(const LoadItemsEvent());
    // Refresh Diary Page
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
  }

  Future<void> _updateTrackedDayCalorieGoal(
    UserEntity user,
    DateTime day,
  ) async {
    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);
    if (hasTrackedDay) {
      final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal(
        userEntity: user,
      );

      await _addTrackedDayUsecase.updateDayCalorieGoal(day, totalKcalGoal);
    }
  }
}
