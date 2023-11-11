import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/bmi_calc.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
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
  final GetUserActivityUsecase _getUserActivityUsecase;

  ProfileBloc(this._getUserUsecase, this._addUserUsecase,
      this._addTrackedDayUsecase, this._getUserActivityUsecase)
      : super(ProfileInitial()) {
    on<LoadProfileEvent>((event, emit) async {
      emit(ProfileLoadingState());

      final user = await _getUserUsecase.getUserData();
      final userBMIValue = BMICalc.getBMI(user);
      final userBMIEntity = UserBMIEntity(
          bmiValue: userBMIValue,
          nutritionalStatus: BMICalc.getNutritionalStatus(userBMIValue));

      emit(ProfileLoadedState(userBMI: userBMIEntity, userEntity: user));
    });
  }

  void updateUser(UserEntity userEntity) async {
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
    locator<CalendarDayBloc>().add(LoadCalendarDayEvent(DateTime.now()));
  }

  Future<void> _updateTrackedDayCalorieGoal(
      UserEntity user, DateTime day) async {
    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);
    if (hasTrackedDay) {
      final activityDayList =
          await _getUserActivityUsecase.getTodayUserActivity();
      final totalActivityKcal =
          activityDayList.map((activity) => activity.burnedKcal).sum;
      final totalKcalGoal = CalorieGoalCalc.getTotalKcalGoal(user, totalActivityKcal);

      await _addTrackedDayUsecase.updateDayCalorieGoal(day, totalKcalGoal);
    }
  }
}
