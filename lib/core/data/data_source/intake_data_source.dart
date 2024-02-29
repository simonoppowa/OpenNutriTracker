import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';

class IntakeDataSource {
  final log = Logger('IntakeDataSource');
  final Box<IntakeDBO> _intakeBox;

  IntakeDataSource(this._intakeBox);

  Future<void> addIntake(IntakeDBO intakeDBO) async {
    log.fine('Adding new intake item to db');
    _intakeBox.add(intakeDBO);
  }

  Future<void> deleteIntakeFromId(String intakeId) async {
    log.fine('Deleting intake item from db');
    _intakeBox.values
        .where((dbo) => dbo.id == intakeId)
        .toList()
        .forEach((element) {
      element.delete();
    });
  }

  Future<List<IntakeDBO>> getAllIntakesByDate(
      IntakeTypeDBO intakeType, DateTime dateTime) async {
    return _intakeBox.values
        .where((intake) =>
            DateUtils.isSameDay(dateTime, intake.dateTime) &&
            intake.type == intakeType)
        .toList();
  }

  Future<List<IntakeDBO>> getRecentlyAddedIntake({int number = 100}) async {
    final intakeList = _intakeBox.values.toList();

    //  sort list by date and filter unique intake
    intakeList
        .sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final filterCodes = <String>{};
    final uniqueIntake = intakeList
        .where((intake) =>
            filterCodes.add(intake.meal.code ?? intake.meal.name ?? ""))
        .toList();

    return uniqueIntake.take(number).toList();
  }
}
