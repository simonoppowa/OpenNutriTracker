import 'dart:async';

import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/export_meal_intake_usecase.dart';

class AddIntakeUsecase {
  final IntakeRepository _intakeRepository;
  final ExportMealIntakeUsecase? _exportMealIntakeUsecase;

  AddIntakeUsecase(this._intakeRepository, [this._exportMealIntakeUsecase]);

  Future<void> addIntake(IntakeEntity intakeEntity) async {
    await _intakeRepository.addIntake(intakeEntity);
    unawaited(_exportMealIntakeUsecase?.exportIntake(intakeEntity));
  }
}
