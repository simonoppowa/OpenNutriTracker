import 'dart:async';

import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/export_meal_intake_usecase.dart';

class UpdateIntakeUsecase {
  final IntakeRepository _intakeRepository;
  final ExportMealIntakeUsecase? _exportMealIntakeUsecase;

  UpdateIntakeUsecase(this._intakeRepository, [this._exportMealIntakeUsecase]);

  Future<IntakeEntity?> updateIntake(
    String intakeId,
    Map<String, dynamic> intakeFields,
  ) async {
    final result = await _intakeRepository.updateIntake(intakeId, intakeFields);
    if (result != null) {
      unawaited(_exportMealIntakeUsecase?.exportIntake(result));
    }
    return result;
  }
}
