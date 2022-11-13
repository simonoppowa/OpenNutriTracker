import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/product_entity.dart';

class ItemDetailBloc {
  final _addIntakeUseCase = AddIntakeUsecase();
  final _addTrackedDayUsecase = AddTrackedDayUsecase();

  void addIntake(BuildContext context, String unit, String amountText,
      IntakeTypeEntity type, ProductEntity product) {
    final quantity = double.parse(amountText);

    final intakeEntity = IntakeEntity(
        unit: unit,
        amount: quantity,
        type: type,
        product: product,
        dateTime: DateTime.now());

    _addIntakeUseCase.addIntake(context, intakeEntity);
    _addTrackedDayUsecase.addDayCaloriesTracked(
        context, DateTime.now(), intakeEntity.totalKcal);
  }
}
