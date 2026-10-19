import 'package:flutter/foundation.dart';
import 'package:opennutritracker/core/domain/entity/water_intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/delete_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';

/// The water entries of one logical day, for the lists in the water dialog
/// and the diary (#30), and single deletes from them.
class DayWaterLog {
  final GetWaterIntakeUsecase _getWaterIntake;
  final DeleteWaterIntakeUsecase _deleteWaterIntake;
  final Future<int> Function() _dayStartOffsetMinutes;
  final VoidCallback _onChanged;
  final Future<int> Function()? _goalMl;

  /// Goes up whenever entries were added or deleted, so a shown list
  /// reloads.
  final ValueNotifier<int> revision = ValueNotifier(0);

  /// [onChanged] runs after a delete here, to refresh the screens that
  /// show water totals; [goalMl] gives the daily goal for the progress bar.
  DayWaterLog(
    this._getWaterIntake,
    this._deleteWaterIntake, {
    required Future<int> Function() dayStartOffsetMinutes,
    required VoidCallback onChanged,
    Future<int> Function()? goalMl,
  }) : _dayStartOffsetMinutes = dayStartOffsetMinutes,
       _onChanged = onChanged,
       _goalMl = goalMl;

  /// The daily water goal, or null when none is known.
  Future<int?> goalMl() async => _goalMl?.call();

  /// The entries of the logical day starting on the calendar date [day],
  /// earliest first.
  Future<List<WaterIntakeEntity>> entriesFor(DateTime day) async {
    final entries = await _getWaterIntake.getEntriesForDay(
      DateTime(day.year, day.month, day.day),
      dayStartOffsetTotalMinutes: await _dayStartOffsetMinutes(),
    );
    return [...entries]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// The entries of the current logical day, earliest first.
  Future<List<WaterIntakeEntity>> entriesForToday() async {
    final entries = await _getWaterIntake.getTodayEntries(
      dayStartOffsetTotalMinutes: await _dayStartOffsetMinutes(),
    );
    return [...entries]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> delete(String id) async {
    await _deleteWaterIntake.deleteEntry(id);
    markChanged();
    _onChanged();
  }

  /// Records that entries changed somewhere else (the home screen's
  /// quick-add or undo).
  void markChanged() => revision.value++;
}
