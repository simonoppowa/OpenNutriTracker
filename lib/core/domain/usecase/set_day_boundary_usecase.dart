import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/tracked_day_reconciler.dart';

/// Changes the diary's "Day starts at" boundary (#139).
///
/// Never just a config write: the boundary decides which day every entry
/// is listed under, and each day's tracked-day row has to follow its
/// entries, or the calendar double-counts the ones that moved and keeps a
/// marker on the day they left (#1317). See [moveDayBoundary].
class SetDayBoundaryUsecase {
  final HiveDBProvider _hiveDBProvider;
  final ConfigDataSource _configDataSource;

  SetDayBoundaryUsecase(this._hiveDBProvider, this._configDataSource);

  Future<void> setDayBoundary(int hours, int minutes) =>
      moveDayBoundary(_hiveDBProvider, _configDataSource, hours, minutes);
}
