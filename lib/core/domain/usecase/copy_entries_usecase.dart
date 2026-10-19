import 'package:opennutritracker/core/domain/entity/copy_target.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/water_intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_water_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/log_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';

/// Copies diary entries to another day (#40): single intakes, a meal, or a
/// whole day with its activities and water if wanted. Copies get new ids
/// and keep the meal snapshot, amount and unit; each lands at the same time
/// of its logical day on the target day, so the configured day start is
/// kept. The target day's tracked totals grow with the copied intakes, and
/// copied activities raise its goal as logged ones do.
class CopyEntriesUsecase {
  final AddIntakeUsecase _addIntakeUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;
  final GetConfigUsecase _getConfigUsecase;
  final GetIntakeUsecase _getIntakeUsecase;
  final GetUserActivityUsecase _getUserActivityUsecase;
  final LogUserActivityUsecase _logUserActivityUsecase;
  final GetWaterIntakeUsecase _getWaterIntakeUsecase;
  final AddWaterIntakeUsecase _addWaterIntakeUsecase;
  final String Function() _newId;

  CopyEntriesUsecase(
    this._addIntakeUsecase,
    this._addTrackedDayUsecase,
    this._getKcalGoalUsecase,
    this._getMacroGoalUsecase,
    this._getConfigUsecase,
    this._getIntakeUsecase,
    this._getUserActivityUsecase,
    this._logUserActivityUsecase,
    this._getWaterIntakeUsecase,
    this._addWaterIntakeUsecase, {
    String Function()? newId,
  }) : _newId = newId ?? IdGenerator.getUniqueID;

  /// Copies [intakes] to [target], one after the other so the target day's
  /// totals add up.
  Future<void> copyIntakes(
    List<IntakeEntity> intakes,
    CopyTarget target,
  ) async {
    final offset = await _offsetMinutes();
    final day = _dateOf(target.day);
    for (final intake in intakes) {
      final copy = IntakeEntity(
        id: _newId(),
        unit: intake.unit,
        amount: intake.amount,
        type: target.type ?? intake.type,
        meal: intake.meal,
        dateTime: _moveTo(intake.dateTime, day, offset),
      );
      await _addIntakeUsecase.addIntake(copy);
      await _addToTrackedDay(copy, day);
    }
  }

  Future<void> copyActivities(
    List<UserActivityEntity> activities,
    DateTime targetDay,
  ) async {
    final offset = await _offsetMinutes();
    final day = _dateOf(targetDay);
    for (final activity in activities) {
      await _logUserActivityUsecase.logActivity(
        UserActivityEntity(
          _newId(),
          activity.duration,
          activity.burnedKcal,
          _moveTo(activity.date, day, offset),
          activity.physicalActivityEntity,
          userKcal: activity.userKcal,
        ),
        day: day,
      );
    }
  }

  /// Copies every intake of the logical day [sourceDay] to [targetDay], and
  /// its activities and water when asked.
  Future<void> copyDay(
    DateTime sourceDay,
    DateTime targetDay, {
    bool activities = false,
    bool water = false,
  }) async {
    final config = await _getConfigUsecase.getConfig();
    final hours = config.dayStartOffsetHours;
    final minutes = config.dayStartOffsetMinutes;
    final source = _dateOf(sourceDay);
    final intakes = [
      ...await _getIntakeUsecase.getBreakfastIntakeByDay(
        source,
        dayStartOffsetHours: hours,
        dayStartOffsetMinutes: minutes,
      ),
      ...await _getIntakeUsecase.getLunchIntakeByDay(
        source,
        dayStartOffsetHours: hours,
        dayStartOffsetMinutes: minutes,
      ),
      ...await _getIntakeUsecase.getDinnerIntakeByDay(
        source,
        dayStartOffsetHours: hours,
        dayStartOffsetMinutes: minutes,
      ),
      ...await _getIntakeUsecase.getSnackIntakeByDay(
        source,
        dayStartOffsetHours: hours,
        dayStartOffsetMinutes: minutes,
      ),
    ]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await copyIntakes(intakes, CopyTarget(day: targetDay));
    if (activities) {
      await copyActivities(
        await _getUserActivityUsecase.getUserActivityByDay(
          source,
          dayStartOffsetHours: hours,
          dayStartOffsetMinutes: minutes,
        ),
        targetDay,
      );
    }
    if (water) {
      final offset = config.dayStartOffsetTotalMinutes;
      final target = _dateOf(targetDay);
      for (final entry in await _getWaterIntakeUsecase.getEntriesForDay(
        source,
        dayStartOffsetTotalMinutes: offset,
      )) {
        await _addWaterIntakeUsecase.addEntry(
          WaterIntakeEntity(
            id: 'water-${_newId()}',
            dateTime: _moveTo(entry.dateTime, target, offset),
            amountMl: entry.amountMl,
          ),
        );
      }
    }
  }

  Future<int> _offsetMinutes() async =>
      (await _getConfigUsecase.getConfig()).dayStartOffsetTotalMinutes;

  static DateTime _dateOf(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  /// [moment] at the same point of the logical day labelled [targetDay].
  static DateTime _moveTo(DateTime moment, DateTime targetDay, int offset) {
    final sourceDay = DayBoundaryCalc.logicalDayOfMinutes(moment, offset);
    final sourceStart = _dateOf(sourceDay).add(Duration(minutes: offset));
    final targetStart = targetDay.add(Duration(minutes: offset));
    return targetStart.add(moment.difference(sourceStart));
  }

  Future<void> _addToTrackedDay(IntakeEntity intake, DateTime day) async {
    if (!await _addTrackedDayUsecase.hasTrackedDay(day)) {
      final kcalGoal = await _getKcalGoalUsecase.getKcalGoalForDay(day);
      final macros = await _getMacroGoalUsecase.getMacroGoalsForDay(
        kcalGoal,
        day,
      );
      await _addTrackedDayUsecase.addNewTrackedDay(
        day,
        kcalGoal,
        macros.carbsG,
        macros.fatG,
        macros.proteinG,
      );
    }
    await _addTrackedDayUsecase.addDayCaloriesTracked(day, intake.totalKcal);
    await _addTrackedDayUsecase.addDayMacrosTracked(
      day,
      carbsTracked: intake.totalCarbsGram,
      fatTracked: intake.totalFatsGram,
      proteinTracked: intake.totalProteinsGram,
    );
  }
}
