import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:provider/provider.dart';

class GetIntakeUsecase {
  Future<List<IntakeEntity>> getTodayBreakfastIntake(
      BuildContext context) async {
    final intakeRepository =
        Provider.of<IntakeRepository>(context, listen: false);
    return await intakeRepository.getIntakeByDateAndType(
        IntakeTypeEntity.breakfast, DateTime.now());
  }
}
