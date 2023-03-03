import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:provider/provider.dart';

class DeleteIntakeUsecase {
  Future<void> deleteIntake(
      BuildContext context, IntakeEntity intakeEntity) async {
    final intakeRepository =
        Provider.of<IntakeRepository>(context, listen: false);
    await intakeRepository.deleteIntake(intakeEntity);
  }
}
