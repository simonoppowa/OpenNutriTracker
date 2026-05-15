import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/custom_activity_template_entity.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_custom_activity_template_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/get_custom_activity_templates_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/calc/met_calc.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';

part 'activity_detail_event.dart';

part 'activity_detail_state.dart';

class ActivityDetailBloc
    extends Bloc<ActivityDetailEvent, ActivityDetailState> {
  final GetUserUsecase _getUserUsecase;
  final AddUserActivityUsecase _addUserActivityUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;
  final AddCustomActivityTemplateUsecase _addCustomActivityTemplateUsecase;
  final GetCustomActivityTemplatesUsecase _getCustomActivityTemplatesUsecase;

  ActivityDetailBloc(
    this._getUserUsecase,
    this._addUserActivityUsecase,
    this._addTrackedDayUsecase,
    this._getKcalGoalUsecase,
    this._getMacroGoalUsecase,
    this._addCustomActivityTemplateUsecase,
    this._getCustomActivityTemplatesUsecase,
  ) : super(ActivityDetailInitial()) {
    on<LoadActivityDetailEvent>((event, emit) async {
      emit(ActivityDetailLoadingState());
      // For Custom activities (#70), the quantity entered by the user is
      // kcal — not minutes — so we start the form blank rather than at a
      // 60-minute prefilled default that wouldn't make sense as a kcal
      // figure.
      final isCustom = event.physicalActivity.isCustom;
      final quantityDefault = isCustom ? 0.0 : 60.0;
      final user = await _getUserUsecase.getUserData();
      final totalBurnedKcal = isCustom
          ? 0.0
          : getTotalKcalBurned(
              user,
              event.physicalActivity,
              quantityDefault,
            );

      emit(
        ActivityDetailLoadedState(
          totalBurnedKcal,
          user,
          quantityDefault.toInt(),
        ),
      );
    });
  }

  double getTotalKcalBurned(
    UserEntity user,
    PhysicalActivityEntity physicalActivity,
    double duration,
  ) {
    // Custom activities (#70) don't compute via MET — the user enters
    // the kcal directly, and that figure is returned untouched.
    if (physicalActivity.isCustom) {
      return duration;
    }
    return METCalc.getTotalBurnedKcal(user, physicalActivity, duration);
  }

  /// Loads the user's saved Custom activity templates (#70 follow-up).
  ///
  /// Only meaningful when [PhysicalActivityEntity.isCustom] is true on
  /// the current activity — callers should branch on that before
  /// surfacing the picker UI. Returns the alphabetised list straight
  /// from the repository so the bottom sheet doesn't have to do its own
  /// sort.
  Future<List<CustomActivityTemplateEntity>> loadCustomActivityTemplates() {
    return _getCustomActivityTemplatesUsecase.getAllTemplates();
  }

  /// Persists a new Custom activity template (#70 follow-up).
  ///
  /// Called from the bottom sheet when the user ticks "Save as
  /// template" and presses Add. A blank [name] is rejected at the call
  /// site, so by the time this is reached the entity is safe to write.
  Future<void> saveCustomActivityTemplate(
    CustomActivityTemplateEntity entity,
  ) async {
    await _addCustomActivityTemplateUsecase.addTemplate(entity);
  }

  void persistActivity(
    String quantityText,
    double totalKcalBurned,
    PhysicalActivityEntity activityEntity,
    DateTime day,
  ) async {
    final parsedQuantity = double.parse(quantityText);
    // Custom activities log the kcal directly: duration is meaningless, so
    // we store 0 there, and `userKcal` records the user's entered value so
    // the edit dialog can prefill it later.
    final isCustom = activityEntity.isCustom;
    final duration = isCustom ? 0.0 : parsedQuantity;
    final burnedKcal = isCustom ? parsedQuantity : totalKcalBurned;

    final userActivityEntity = UserActivityEntity(
      IdGenerator.getUniqueID(),
      duration,
      burnedKcal,
      day,
      activityEntity,
      userKcal: isCustom ? parsedQuantity : null,
    );

    await _addUserActivityUsecase.addUserActivity(userActivityEntity);
    _updateTrackedDay(day, burnedKcal);
  }

  void _updateTrackedDay(DateTime day, double caloriesBurned) async {
    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);
    if (!hasTrackedDay) {
      // If the tracked day does not exist, create a new one
      final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal(
        totalKcalActivitiesParam: 0,
      ); // Exclude persisted activities
      final totalCarbsGoal = await _getMacroGoalUsecase.getCarbsGoal(
        totalKcalGoal,
      );
      final totalFatGoal = await _getMacroGoalUsecase.getFatsGoal(
        totalKcalGoal,
      );
      final totalProteinGoal = await _getMacroGoalUsecase.getProteinsGoal(
        totalKcalGoal,
      );

      await _addTrackedDayUsecase.addNewTrackedDay(
        day,
        totalKcalGoal,
        totalCarbsGoal,
        totalFatGoal,
        totalProteinGoal,
      );
    }

    final carbsIncrease = MacroCalc.getTotalCarbsGoal(caloriesBurned);
    final fatIncrease = MacroCalc.getTotalFatsGoal(caloriesBurned);
    final proteinIncrease = MacroCalc.getTotalProteinsGoal(caloriesBurned);

    _addTrackedDayUsecase.increaseDayCalorieGoal(day, caloriesBurned);
    _addTrackedDayUsecase.increaseDayMacroGoals(
      day,
      carbsAmount: carbsIncrease,
      fatAmount: fatIncrease,
      proteinAmount: proteinIncrease,
    );
  }
}
