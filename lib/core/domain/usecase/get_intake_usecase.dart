import 'package:flutter/cupertino.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:provider/provider.dart';

class GetIntakeUsecase {
  Future<List<IntakeEntity>> _getIntakeByDay(
      BuildContext context, IntakeTypeEntity type, DateTime day) async {
    final intakeRepository =
        Provider.of<IntakeRepository>(context, listen: false);

    return await intakeRepository.getIntakeByDateAndType(type, day);
  }

  Future<List<IntakeEntity>> getBreakfastIntakeByDay(
          BuildContext context, day) async =>
      await _getIntakeByDay(context, IntakeTypeEntity.breakfast, day);

  Future<List<IntakeEntity>> getTodayBreakfastIntake(
          BuildContext context) async =>
      getBreakfastIntakeByDay(context, DateTime.now());

  Future<List<IntakeEntity>> getLunchIntakeByDay(
          BuildContext context, day) async =>
      await _getIntakeByDay(context, IntakeTypeEntity.lunch, day);

  Future<List<IntakeEntity>> getTodayLunchIntake(BuildContext context) async =>
      await getLunchIntakeByDay(context, DateTime.now());

  Future<List<IntakeEntity>> getDinnerIntakeByDay(
          BuildContext context, day) async =>
      await _getIntakeByDay(context, IntakeTypeEntity.dinner, day);

  Future<List<IntakeEntity>> getTodayDinnerIntake(BuildContext context) async =>
      await getDinnerIntakeByDay(context, DateTime.now());

  Future<List<IntakeEntity>> getSnackIntakeByDay(
          BuildContext context, day) async =>
      await _getIntakeByDay(context, IntakeTypeEntity.snack, day);

  Future<List<IntakeEntity>> getTodaySnackIntake(BuildContext context) async =>
      await getSnackIntakeByDay(context, DateTime.now());

  Future<List<IntakeEntity>> getRecentIntake(BuildContext context) async {
    final intakeRepository =
        Provider.of<IntakeRepository>(context, listen: false);

    return intakeRepository.getRecentIntake();
  }
}
