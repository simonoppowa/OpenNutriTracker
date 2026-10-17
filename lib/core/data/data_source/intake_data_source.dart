import 'package:collection/collection.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/box_upsert.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class IntakeDataSource {
  final log = Logger('IntakeDataSource');
  final HiveDBProvider _db;

  IntakeDataSource(this._db);

  Box<IntakeDBO> get _intakeBox => _db.intakeBox;

  Future<void> addIntake(IntakeDBO intakeDBO) async {
    log.fine('Adding new intake item to db');
    await _intakeBox.add(intakeDBO);
  }

  /// Upserts by [IntakeDBO.id]: an intake whose id is already stored
  /// replaces it, so importing a bundle twice leaves one copy (#1357).
  /// Where a bundle holds an id twice the first row wins — the old edit
  /// rewrote the first copy in place. A row with a blank id gets one
  /// derived from its content first ([withContentIds]).
  Future<void> upsertAllIntakes(List<IntakeDBO> intakeDBOList) async {
    log.fine('Upserting intake items into db');
    await _intakeBox.upsertAllBy(
      withContentIds(
        intakeDBOList,
        idOf: (dbo) => dbo.id,
        contentOf: _contentOf,
        withId: (dbo, id) => IntakeDBO(
          id: id,
          unit: dbo.unit,
          amount: dbo.amount,
          type: dbo.type,
          meal: dbo.meal,
          dateTime: dbo.dateTime,
        ),
      ),
      (dbo) => isBlankId(dbo.id) ? null : dbo.id,
      winner: UpsertWinner.first,
    );
  }

  /// What a blank-id intake's derived id is made of: when, which meal
  /// slot, how much of which food. These fields are in every export ever
  /// written. The nutriments are left out — the import rescales old Open
  /// Food Facts values (#1152), so they are not a fixed property of the
  /// backup row — and two rows that differ only there still both stay, as
  /// any two equal rows do. Changing this list moves every derived id, and
  /// re-importing an old backup would then duplicate its blank-id rows.
  static List<String?> _contentOf(IntakeDBO dbo) => [
    dbo.dateTime.toIso8601String(),
    dbo.type.name,
    contentNumber(dbo.amount),
    dbo.unit,
    dbo.meal.source.name,
    dbo.meal.code,
    dbo.meal.name,
    dbo.meal.brands,
  ];

  Future<void> deleteIntakeFromId(String intakeId) async {
    log.fine('Deleting intake item from db');
    final toDelete =
        _intakeBox.values.where((dbo) => dbo.id == intakeId).toList();
    for (final element in toDelete) {
      await element.delete();
    }
  }

  /// Applies [fields] to every stored copy of [intakeId], so an install
  /// the old import doubled (#1357) ends up with copies that agree.
  Future<IntakeDBO?> updateIntake(
    String intakeId,
    Map<String, dynamic> fields,
  ) async {
    log.fine(
      'Updating intake $intakeId with fields ${fields.toString()} in db',
    );
    final copies = _intakeBox
        .toMap()
        .entries
        .where((entry) => entry.value.id == intakeId)
        .toList();
    if (copies.isEmpty) {
      log.fine('Cannot update intake $intakeId as it is non existent');
      return null;
    }
    for (final copy in copies) {
      copy.value.amount = fields['amount'] ?? copy.value.amount;
    }
    await _intakeBox.putAll({for (final copy in copies) copy.key: copy.value});
    return _intakeBox.get(copies.first.key);
  }

  Future<IntakeDBO?> getIntakeById(String intakeId) async {
    return _intakeBox.values.firstWhereOrNull(
      (intake) => intake.id == intakeId,
    );
  }

  Future<List<IntakeDBO>> getAllIntakes() async {
    return _intakeBox.values.toList();
  }

  /// Intakes of [intakeType] filed under the calendar day [day].
  ///
  /// [day] is a day label — the date the user is looking at — not a
  /// moment in time. #139: when a non-zero day-start offset is
  /// configured, an entry logged before that time rolls into the
  /// previous day; the label itself must stay put (#586). The follow-up
  /// to #139 adds a minutes companion, which composes additively into a
  /// single total-minutes value here. A zero total offset reduces to the
  /// original wall-clock-day behaviour.
  Future<List<IntakeDBO>> getAllIntakesByDate(
    IntakeTypeDBO intakeType,
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async {
    final totalMinutes = DayBoundaryCalc.totalMinutesOf(
      dayStartOffsetHours,
      dayStartOffsetMinutes,
    );
    return _intakeBox.values
        .where(
          (intake) =>
              DayBoundaryCalc.isMomentInLogicalDayMinutes(
                day,
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

  /// Replace the denormalised [MealDBO] snapshot on every intake whose
  /// `(meal.code ?? meal.name)` matches [fromMealKey] *and* whose meal source
  /// is custom. Used by the custom-meal merge flow: callers compute the
  /// kcal/macro deltas before invoking this and apply them to TrackedDay
  /// totals separately.
  ///
  /// Returns the list of `(oldIntake, newIntake)` pairs that were rewritten,
  /// so the caller can recompute totals from the diff.
  Future<List<(IntakeDBO, IntakeDBO)>> remapCustomMealOnIntakes({
    required String fromMealKey,
    required MealDBO toMeal,
  }) async {
    final rewrites = <(IntakeDBO, IntakeDBO)>[];
    final entries = _intakeBox.toMap().entries.toList();
    for (final entry in entries) {
      final dbo = entry.value;
      if (dbo.meal.source != MealSourceDBO.custom) continue;
      final key = dbo.meal.code ?? dbo.meal.name;
      if (key != fromMealKey) continue;
      final updated = IntakeDBO(
        id: dbo.id,
        unit: dbo.unit,
        amount: dbo.amount,
        type: dbo.type,
        meal: toMeal,
        dateTime: dbo.dateTime,
      );
      await _intakeBox.put(entry.key, updated);
      rewrites.add((dbo, updated));
    }
    return rewrites;
  }
}
