import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/features/addItem/domain/entity/product_entity.dart';

class ItemDetailBloc {
  final _addIntakeUseCase = AddIntakeUsecase();

  void addIntake(BuildContext context, String unit, String amountText,
      IntakeTypeEntity type, ProductEntity product) {
    final quantity = double.parse(amountText);

    final intakeEntity = IntakeEntity(
        unit: unit,
        amount: quantity,
        type: type,
        product: product);

    _addIntakeUseCase.addIntake(context, intakeEntity);
  }
}
