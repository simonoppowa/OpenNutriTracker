import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/utils/bounds/ranges_const.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_data_mask_entity.dart';

part 'onboarding_event.dart';

part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final userSelection = UserDataMaskEntity();
  final AddUserUsecase _addUserUsecase;
  final AddConfigUsecase _addConfigUsecase;

  OnboardingBloc(this._addUserUsecase, this._addConfigUsecase)
      : super(OnboardingInitialState()) {
    on<LoadOnboardingEvent>((event, emit) async {
      emit(OnboardingLoadingState());

      emit(OnboardingLoadedState());
    });
  }

  Future<void> saveOnboardingData(
    UserEntity userEntity,
    bool hasAcceptedDataCollection,
    bool heightImperial,
    BodyWeightUnit bodyWeightUnit,
    bool foodImperial, {
    required AppThemeEntity appTheme,
    required Map<String, bool> foodSourceToggles,
    required bool dailyReminderEnabled,
    required bool useMaterialYou,
    required int? accentColor,
  }) async {
    await _addUserUsecase.addUser(userEntity);
    await _addConfigUsecase.setConfigHasAcceptedAnonymousData(
      hasAcceptedDataCollection,
    );
    await _addConfigUsecase.setConfigUsesImperialHeightUnits(heightImperial);
    await _addConfigUsecase.setConfigBodyWeightUnit(bodyWeightUnit);
    // Food units are chosen explicitly during onboarding, so someone on feet
    // and stones can still log food in grams.
    await _addConfigUsecase.setConfigUsesImperialFoodUnits(foodImperial);
    // "Other options" page: theme, food databases and the daily reminder
    // flag. The reminder's permission request and scheduling are handled by
    // the screen before this is called — dailyReminderEnabled arrives here
    // already downgraded to false when the permission was denied.
    await _addConfigUsecase.setConfigAppTheme(appTheme);
    if (foodSourceToggles.isNotEmpty) {
      await _addConfigUsecase.setConfigFoodSourceToggles(foodSourceToggles);
    }
    await _addConfigUsecase.setNotificationsEnabled(dailyReminderEnabled);
    await _addConfigUsecase.setConfigUseMaterialYou(useMaterialYou);
    await _addConfigUsecase.setConfigAccentColor(accentColor);
  }

  double? getOverviewCalorieGoal() {
    final userEntity = userSelection.toUserEntity();
    double? calorieGoal;
    if (userEntity != null) {
      calorieGoal = CalorieGoalCalc.getTotalKcalGoal(userEntity, 0);
    }
    return calorieGoal;
  }

  double? getOverviewCarbsGoal() {
    final userEntity = userSelection.toUserEntity();
    final calorieGoal = getOverviewCalorieGoal();
    double? carbsGoal;
    if (userEntity != null && calorieGoal != null) {
      carbsGoal = MacroCalc.getTotalCarbsGoal(calorieGoal);
    }
    return carbsGoal;
  }

  double? getOverviewFatGoal() {
    final userEntity = userSelection.toUserEntity();
    final calorieGoal = getOverviewCalorieGoal();
    double? fatGoal;
    if (userEntity != null && calorieGoal != null) {
      fatGoal = MacroCalc.getTotalFatsGoal(calorieGoal);
    }
    return fatGoal;
  }

  double? getOverviewProteinGoal() {
    final userEntity = userSelection.toUserEntity();
    final calorieGoal = getOverviewCalorieGoal();
    double? proteinGoal;
    if (userEntity != null && calorieGoal != null) {
      proteinGoal = MacroCalc.getTotalProteinsGoal(calorieGoal);
    }
    return proteinGoal;
  }

  /// Whether the calorie goal computed for the current onboarding
  /// selection has dropped below the research-backed floor for the user's
  /// hormonal profile. Used by the overview page to decide whether to
  /// surface the soft low-kcal warning.
  bool isOverviewBelowRecommendedKcalFloor() {
    final userEntity = userSelection.toUserEntity();
    final calorieGoal = getOverviewCalorieGoal();
    if (userEntity == null || calorieGoal == null) return false;
    return CalorieGoalCalc.isBelowRecommendedDailyKcalFloor(
      goalKcal: calorieGoal,
      gender: userEntity.gender,
      caloriesProfile: userEntity.caloriesProfile,
    );
  }

  /// The kcal floor the overview warning quotes back to the user. Falls
  /// back to the lower (female-typical) bound when the selection isn't
  /// resolvable yet, so the displayed number is always a sensible default.
  double getOverviewRecommendedKcalFloor() {
    final userEntity = userSelection.toUserEntity();
    if (userEntity == null) return Ranges.minRecommendedDailyKcalFemale;
    return CalorieGoalCalc.recommendedDailyKcalFloor(
      gender: userEntity.gender,
      caloriesProfile: userEntity.caloriesProfile,
    );
  }
}
