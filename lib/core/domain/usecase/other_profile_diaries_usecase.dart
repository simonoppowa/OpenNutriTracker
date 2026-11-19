import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/scoped_hive_db_provider.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/core/utils/tracked_day_reconciler.dart';

/// Runs a change to a custom meal's diary entries on the profiles that are
/// not active (#1421).
///
/// The custom-meal library is shared by every profile, while each logs its
/// own entries, so deleting or merging a meal has to reach the entries the
/// other profiles logged with it too. Each such profile's diary is opened
/// scoped, the way [SendIntakeToProfilesUsecase] does, and its rows are
/// first brought in line with its entries, so the totals [action] adjusts
/// are keyed by the current day boundary.
class OtherProfileDiariesUsecase {
  final HiveDBProvider _db;

  OtherProfileDiariesUsecase(this._db);

  /// Calls [action] with the intake repository and tracked-day usecase of
  /// every other profile that logged the custom meal known as [mealKey]
  /// (`meal.code ?? meal.name`). A profile without such an entry is not
  /// opened beyond its intake box.
  ///
  /// Runs under the tracked-day lock, which excludes a profile switch, so
  /// the active profile stays the same throughout.
  Future<void> forEachLoggingCustomMeal(
    String mealKey,
    Future<void> Function(
      IntakeRepository intakeRepository,
      AddTrackedDayUsecase addTrackedDayUsecase,
    )
    action,
  ) => withTrackedDayLock(() async {
    final suffixes = [
      for (final profile in _db.profileBox.values)
        if (profile.id != _db.activeProfileId) profile.boxSuffix,
    ];
    for (final suffix in suffixes) {
      await _runOn(suffix, mealKey, action);
    }
  });

  Future<void> _runOn(
    String suffix,
    String mealKey,
    Future<void> Function(IntakeRepository, AddTrackedDayUsecase) action,
  ) async {
    final opened = <Future<void> Function()>[];
    Future<Box<E>> open<E>(String baseName) async {
      final box = await _db.openScopedBox<E>(baseName, suffix);
      opened.add(() => _db.closeScopedBox<E>(baseName, suffix));
      return box;
    }

    try {
      final intakeBox = await open<IntakeDBO>(HiveDBProvider.intakeBoxName);
      final logged = intakeBox.values.any(
        (dbo) =>
            dbo.meal.source == MealSourceDBO.custom &&
            (dbo.meal.code ?? dbo.meal.name) == mealKey,
      );
      if (!logged) return;

      final scoped = ScopedHiveDBProvider(
        intakeBox: intakeBox,
        trackedDayBox: await open<TrackedDayDBO>(
          HiveDBProvider.trackedDayBoxName,
        ),
        userBox: await open<UserDBO>(HiveDBProvider.userBoxName),
        configBox: await open<ConfigDBO>(HiveDBProvider.configBoxName),
        userActivityBox: await open<UserActivityDBO>(
          HiveDBProvider.userActivityBoxName,
        ),
        // App config is shared, so the real global box passes through.
        appConfigBox: _db.appConfigBox,
      );
      await ensureTrackedDaysMatchEntries(scoped, ConfigDataSource(scoped));
      await action(
        IntakeRepository(IntakeDataSource(scoped)),
        AddTrackedDayUsecase(
          TrackedDayRepository(TrackedDayDataSource(scoped)),
        ),
      );
    } finally {
      for (final close in opened.reversed) {
        await close();
      }
    }
  }
}
