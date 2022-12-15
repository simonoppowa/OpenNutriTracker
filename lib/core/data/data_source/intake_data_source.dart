import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';

class IntakeDataSource {
  final log = Logger('IntakeDataSource');
  final Box<IntakeDBO> intakeBox;

  IntakeDataSource(this.intakeBox);

  Future<void> addIntake(IntakeDBO intakeDBO) async {
    log.fine('Adding new intake item to db');
    intakeBox.add(intakeDBO);
  }

  Future<void> deleteIntakeFromId(String intakeId) async {
    log.fine('Deleting intake item from db');
    intakeBox.values
        .where((dbo) => dbo.id == intakeId)
        .toList()
        .forEach((element) {
      element.delete();
    });
  }

  Future<List<IntakeDBO>> getAllIntakesByDate(
      IntakeTypeDBO intakeType, DateTime dateTime) async {
    return intakeBox.values
        .where((intake) =>
            DateUtils.isSameDay(dateTime, intake.dateTime) &&
            intake.type == intakeType)
        .toList();
  }
}
