import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:provider/provider.dart';

class AddIntakeUsecase {
  Future<void> addIntake(
      BuildContext context, IntakeEntity intakeEntity) async {
    final intakeRepository =
        Provider.of<IntakeRepository>(context, listen: false);
    return await intakeRepository.addIntake(intakeEntity);
  }
}
