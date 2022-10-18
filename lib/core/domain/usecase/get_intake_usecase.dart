import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:provider/provider.dart';

class GetIntakeUsecase {
  Future<List<IntakeEntity>> _getTodayIntake(
      BuildContext context, IntakeTypeEntity type) async {
    final intakeRepository =
        Provider.of<IntakeRepository>(context, listen: false);

    return await intakeRepository.getIntakeByDateAndType(type, DateTime.now());
  }

  Future<List<IntakeEntity>> getTodayBreakfastIntake(
          BuildContext context) async =>
      _getTodayIntake(context, IntakeTypeEntity.breakfast);

  Future<List<IntakeEntity>> getTodayLunchIntake(BuildContext context) async =>
      _getTodayIntake(context, IntakeTypeEntity.lunch);

  Future<List<IntakeEntity>> getTodayDinnerIntake(BuildContext context) async =>
      _getTodayIntake(context, IntakeTypeEntity.dinner);

  Future<List<IntakeEntity>> getTodaySnackIntake(BuildContext context) async =>
      _getTodayIntake(context, IntakeTypeEntity.snack);
}
