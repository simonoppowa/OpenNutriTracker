import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Wipes the **active profile's** data, returning that profile to a
/// fresh, un-onboarded state. Used by the Settings "delete all my data"
/// tile. Other profiles and the shared Open Food Facts cache are left
/// untouched — clearing the cache would needlessly slow down food lookups
/// for everyone else sharing the device.
///
/// After this completes, `UserDataSource.hasUserData()` returns false for
/// the active profile, so the next launch (or the explicit navigation back
/// to the onboarding route the caller performs) will land on onboarding.
class DeleteAllUserDataUsecase {
  final _log = Logger('DeleteAllUserDataUsecase');
  final HiveDBProvider _hiveDBProvider;

  DeleteAllUserDataUsecase(this._hiveDBProvider);

  Future<void> deleteAll() async {
    _log.info('Clearing the active profile\'s Hive boxes on user request');

    // Closing Sentry first stops any in-flight queue from referencing
    // boxes mid-clear. The user can re-enable crash reporting later from
    // Settings; nothing here re-opens the SDK on its own.
    await Sentry.close();

    // Only the active profile's own data is cleared. The shared content
    // libraries (custom meals, recipes, activity templates) and the shared
    // app settings belong to every profile, so they're deliberately left
    // alone — wiping them here would take them from the other profiles too.
    await Future.wait([
      _hiveDBProvider.configBox.clear(),
      _hiveDBProvider.intakeBox.clear(),
      _hiveDBProvider.userActivityBox.clear(),
      _hiveDBProvider.userBox.clear(),
      _hiveDBProvider.trackedDayBox.clear(),
      _hiveDBProvider.weightLogBox.clear(),
      _hiveDBProvider.waterIntakeBox.clear(),
      _hiveDBProvider.fastingBox.clear(),
    ]);
  }
}
