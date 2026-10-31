import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';

/// Logical diary dates that still contain food or activity entries.
///
/// Tracked-day rows may remain after their last entry moves away because
/// they also store goals. The calendar marker follows entries, not those
/// retained goal rows.
class GetDiaryEntryDayKeysUsecase {
  final IntakeRepository _intakes;
  final UserActivityRepository _activities;

  GetDiaryEntryDayKeysUsecase(this._intakes, this._activities);

  Future<Set<String>> getEntryDayKeys(int offsetMinutes) async {
    final keys = <String>{};
    for (final intake in await _intakes.getAllIntakesDBO()) {
      keys.add(DayBoundaryCalc.dayKeyOf(intake.dateTime, offsetMinutes));
    }
    for (final activity in await _activities.getAllUserActivityDBO()) {
      keys.add(
        DayBoundaryCalc.dayKeyOf(
          activity.date,
          offsetMinutes,
          clockReading: activity.externalId != null,
        ),
      );
    }
    return keys;
  }
}
