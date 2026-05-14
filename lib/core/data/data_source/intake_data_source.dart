import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';

class IntakeDataSource {
  final log = Logger('IntakeDataSource');
  final Box<IntakeDBO> _intakeBox;

  IntakeDataSource(this._intakeBox);

  Future<void> addIntake(IntakeDBO intakeDBO) async {
    log.fine('Adding new intake item to db');
    await _intakeBox.add(intakeDBO);
  }

  Future<void> addAllIntakes(List<IntakeDBO> intakeDBOList) async {
    log.fine('Adding new intake items to db');
    await _intakeBox.addAll(intakeDBOList);
  }

  Future<void> deleteIntakeFromId(String intakeId) async {
    log.fine('Deleting intake item from db');
    final toDelete =
        _intakeBox.values.where((dbo) => dbo.id == intakeId).toList();
    for (final element in toDelete) {
      await element.delete();
    }
  }

  Future<IntakeDBO?> updateIntake(
    String intakeId,
    Map<String, dynamic> fields,
  ) async {
    log.fine(
      'Updating intake $intakeId with fields ${fields.toString()} in db',
    );
    var intakeObject = _intakeBox.values.indexed
        .where((indexedDbo) => indexedDbo.$2.id == intakeId)
        .firstOrNull;
    if (intakeObject == null) {
      log.fine('Cannot update intake $intakeId as it is non existent');
      return null;
    }
    intakeObject.$2.amount = fields['amount'] ?? intakeObject.$2.amount;
    await _intakeBox.putAt(intakeObject.$1, intakeObject.$2);
    return _intakeBox.getAt(intakeObject.$1);
  }

  Future<IntakeDBO?> getIntakeById(String intakeId) async {
    return _intakeBox.values.firstWhereOrNull(
      (intake) => intake.id == intakeId,
    );
  }

  Future<List<IntakeDBO>> getAllIntakes() async {
    return _intakeBox.values.toList();
  }

  Future<List<IntakeDBO>> getAllIntakesByDate(
    IntakeTypeDBO intakeType,
    DateTime dateTime, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async {
    // #139: when a non-zero day-start offset is configured, an entry
    // logged before that hour rolls into the previous wall-clock day.
    // A zero total offset preserves the original wall-clock behaviour.
    // The follow-up to #139 adds a minutes companion; both compose
    // additively into a single total-minutes value here.
    final totalMinutes = dayStartOffsetHours * 60 +
        dayStartOffsetMinutes.clamp(0, 59);
    if (totalMinutes == 0) {
      return _intakeBox.values
          .where(
            (intake) =>
                DateUtils.isSameDay(dateTime, intake.dateTime) &&
                intake.type == intakeType,
          )
          .toList();
    }
    return _intakeBox.values
        .where(
          (intake) =>
              DayBoundaryCalc.isSameLogicalDayMinutes(
                dateTime,
                intake.dateTime,
                totalMinutes,
              ) &&
              intake.type == intakeType,
        )
        .toList();
  }

  Future<List<IntakeDBO>> getRecentlyAddedIntake({int number = 100000}) async {
    final intakeList = _intakeBox.values.toList();

    //  sort list by date (newest first) and filter unique intake
    intakeList.sort((a, b) => (-1) * a.dateTime.compareTo(b.dateTime));

    final filterCodes = <String>{};
    final uniqueIntake = intakeList
        .where(
          (intake) =>
              filterCodes.add(intake.meal.code ?? intake.meal.name ?? ""),
        )
        .toList();

    // Surface custom meals before remote-sourced results.
    final custom = uniqueIntake.where((i) => i.meal.source == MealSourceDBO.custom).toList();
    final others = uniqueIntake.where((i) => i.meal.source != MealSourceDBO.custom).toList();
    return [...custom, ...others].take(number).toList();
  }

  Future<List<IntakeDBO>> getCustomMealIntakes() async {
    return _intakeBox.values.where((dbo) => dbo.meal.source == MealSourceDBO.custom).toList();
  }
}
