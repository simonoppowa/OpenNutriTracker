import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// A [HiveDBProvider] that points the per-profile box getters at a
/// *specific* profile's boxes rather than the active one. It lets the
/// existing data sources / repositories / use cases run unchanged against
/// another profile — used when copying a meal into a profile that isn't
/// currently active.
///
/// Only the boxes needed for an intake copy (intake, tracked day, user,
/// config, user activity) are wired up; touching any other box throws,
/// which keeps callers honest about scope.
class ScopedHiveDBProvider extends HiveDBProvider {
  final Box<IntakeDBO> _intake;
  final Box<TrackedDayDBO> _trackedDay;
  final Box<UserDBO> _user;
  final Box<ConfigDBO> _config;
  final Box<UserActivityDBO> _userActivity;
  // The shared app config is global, so it's the real box passed straight
  // through — the per-profile [configBox] above only holds personal goals.
  final Box<ConfigDBO> _appConfig;

  ScopedHiveDBProvider({
    required Box<IntakeDBO> intakeBox,
    required Box<TrackedDayDBO> trackedDayBox,
    required Box<UserDBO> userBox,
    required Box<ConfigDBO> configBox,
    required Box<UserActivityDBO> userActivityBox,
    required Box<ConfigDBO> appConfigBox,
  })  : _intake = intakeBox,
        _trackedDay = trackedDayBox,
        _user = userBox,
        _config = configBox,
        _userActivity = userActivityBox,
        _appConfig = appConfigBox;

  @override
  Box<IntakeDBO> get intakeBox => _intake;
  @override
  Box<TrackedDayDBO> get trackedDayBox => _trackedDay;
  @override
  Box<UserDBO> get userBox => _user;
  @override
  Box<ConfigDBO> get configBox => _config;
  @override
  Box<UserActivityDBO> get userActivityBox => _userActivity;
  @override
  Box<ConfigDBO> get appConfigBox => _appConfig;
}
