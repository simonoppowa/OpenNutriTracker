import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class MealDetailBloc {
  final AddIntakeUsecase _addIntakeUseCase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetUserUsecase _getUserUsecase;

  MealDetailBloc(
      this._getUserUsecase, this._addTrackedDayUsecase, this._addIntakeUseCase);

  void addIntake(BuildContext context, String unit, String amountText,
      IntakeTypeEntity type, MealEntity meal, DateTime day) async {
    final quantity = double.parse(amountText);

    final intakeEntity = IntakeEntity(
        id: IdGenerator.getUniqueID(),
        unit: unit,
        amount: quantity,
        type: type,
        meal: meal,
        dateTime: day);
    await _addIntakeUseCase.addIntake(intakeEntity);
    _updateTrackedDay(intakeEntity, day);
  }

  Future<void> _updateTrackedDay(
      IntakeEntity intakeEntity, DateTime day) async {
    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);
    if (!hasTrackedDay) {
      final userEntity = await _getUserUsecase.getUserData();
      final totalKcalGoal = CalorieGoalCalc.getTotalKcalGoal(userEntity, 0);

      await _addTrackedDayUsecase.addNewTrackedDay(day, totalKcalGoal);
    }
    _addTrackedDayUsecase.addDayCaloriesTracked(day, intakeEntity.totalKcal);
  }
}
