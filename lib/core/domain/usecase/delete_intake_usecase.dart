import 'dart:async';

import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/export_meal_intake_usecase.dart';

class DeleteIntakeUsecase {
  final IntakeRepository _intakeRepository;
  final ExportMealIntakeUsecase? _exportMealIntakeUsecase;

  DeleteIntakeUsecase(this._intakeRepository, [this._exportMealIntakeUsecase]);

  Future<void> deleteIntake(IntakeEntity intakeEntity) async {
    await _intakeRepository.deleteIntake(intakeEntity);
    unawaited(_exportMealIntakeUsecase?.deleteIntake(intakeEntity));
  }
}
