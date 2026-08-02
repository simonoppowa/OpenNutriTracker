import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/kcal_goal_breakdown_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/bounds/ranges_const.dart';
import 'package:opennutritracker/core/utils/locale_units.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_data_mask_entity.dart';

part 'onboarding_event.dart';

part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final userSelection = UserDataMaskEntity();
  final AddUserUsecase _addUserUsecase;
  final AddConfigUsecase _addConfigUsecase;
  final GetConfigUsecase _getConfigUsecase;

  OnboardingBloc(
    this._addUserUsecase,
    this._addConfigUsecase,
    this._getConfigUsecase,
  ) : super(OnboardingInitialState()) {
    on<LoadOnboardingEvent>((event, emit) async {
      emit(OnboardingLoadingState());
      await _seedUnitSelection();
      await _seedFoodSourceSelection();
      emit(OnboardingLoadedState());
    });
  }

  /// Picks the unit toggles the height/weight page opens on.
  ///
  /// A stored preference always wins. Units live in the shared app config,
  /// so by the time someone adds a second profile they have already chosen
  /// once. Re-guessing would override that choice, and because finishing
  /// onboarding writes the units back to the shared box, it would change the
  /// first profile's units too.
  ///
  /// Only a genuine first run falls through to the locale.
  Future<void> _seedUnitSelection() async {
    if (await _getConfigUsecase.hasExplicitUnitPreferences()) {
      final config = await _getConfigUsecase.getConfig();
      userSelection.heightUsesImperial = config.usesImperialHeightUnits;
      userSelection.bodyWeightUnit = config.bodyWeightUnit;
      userSelection.foodUsesImperial = config.usesImperialFoodUnits;
      return;
    }

    final defaults = LocaleUnitDefaults.fromLocale(Platform.localeName);
    userSelection.heightUsesImperial = defaults.heightUsesImperial;
    userSelection.bodyWeightUnit = defaults.bodyWeightUnit;
    userSelection.foodUsesImperial = defaults.foodUsesImperial;
  }

  /// Picks which food databases the "Other options" page starts with.
  /// Follows the same rule as the units: a stored choice wins, and only a
  /// first run falls back to the locale.
  Future<void> _seedFoodSourceSelection() async {
    if (await _getConfigUsecase.hasExplicitFoodSourceToggles()) {
      final config = await _getConfigUsecase.getConfig();
      userSelection.foodSourceToggles = Map<String, bool>.from(
        config.foodSourceToggles,
      );
      return;
    }
    userSelection.foodSourceToggles = defaultFoodSourceToggles(
      Platform.localeName,
    );
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
    // Privacy policy is required to leave the intro page, so completing
    // onboarding always means the user accepted it. Persist that – the flag
    // previously only lived in ephemeral intro UI state.
    await _addConfigUsecase.setConfigHasAcceptedPolicy(true);
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
    // Defensive: real onboarding always starts from a wiped, un-onboarded
    // profile (either fresh install, or the demo-mode banner's own wipe
    // before returning here), so this is normally already false — but
    // clearing it explicitly means a real profile can never be left
    // showing the demo-mode banner by some other, future path into
    // onboarding.
    await _addConfigUsecase.setConfigIsDemoData(false);
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

  /// The full derivation of the goal shown on the overview page, computed
  /// from the in-progress selection. Nothing has been written to Hive yet at
  /// this point in the flow.
  ///
  /// Runs through the same [KcalGoalBreakdownEntity.compute] the Settings
  /// transparency screen uses, so the number explained here is the number
  /// the app shows afterwards.
  KcalGoalBreakdownEntity? getOverviewBreakdown() {
    final userEntity = userSelection.toUserEntity();
    if (userEntity == null) return null;
    return KcalGoalBreakdownEntity.compute(
      user: userEntity,
      // No manual offset or logged activity exists during onboarding; both
      // become available once the user is in the app.
      totalKcalActivities: 0,
    );
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
