import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';

class MealDetailBloc {
  final AddIntakeUsecase _addIntakeUseCase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetUserUsecase _getUserUsecase;

  MealDetailBloc(
      this._getUserUsecase, this._addTrackedDayUsecase, this._addIntakeUseCase);

  void addIntake(BuildContext context, String unit, String amountText,
      IntakeTypeEntity type, ProductEntity product) async {
    final quantity = double.parse(amountText);

    final intakeEntity = IntakeEntity(
        id: IdGenerator.getUniqueID(),
        unit: unit,
        amount: quantity,
        type: type,
        product: product,
        dateTime: DateTime.now());
    await _addIntakeUseCase.addIntake(intakeEntity);
    _updateTrackedDay(intakeEntity);
  }

  Future<void> _updateTrackedDay(IntakeEntity intakeEntity) async {
    final userEntity = await _getUserUsecase.getUserData();
    final totalKcalGoal = CalorieGoalCalc.getTdee(userEntity);

    final hasTrackedDay =
        await _addTrackedDayUsecase.hasTrackedDay(DateTime.now());
    if (!hasTrackedDay) {
      await _addTrackedDayUsecase.addNewTrackedDay(
          DateTime.now(), totalKcalGoal);
    }
    _addTrackedDayUsecase.addDayCaloriesTracked(
        DateTime.now(), intakeEntity.totalKcal);
  }
}
