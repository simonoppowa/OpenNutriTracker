import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Wipes every Hive box the app owns, returning the device to a
/// fresh-install state. Used by the Settings "delete all my data" tile.
///
/// After this completes, `UserDataSource.hasUserData()` returns false,
/// so the next launch (or the explicit navigation back to the onboarding
/// route the caller performs) will land on the onboarding flow.
class DeleteAllUserDataUsecase {
  final _log = Logger('DeleteAllUserDataUsecase');
  final HiveDBProvider _hiveDBProvider;

  DeleteAllUserDataUsecase(this._hiveDBProvider);

  Future<void> deleteAll() async {
    _log.info('Clearing all Hive boxes on user request');

    // Closing Sentry first stops any in-flight queue from referencing
    // boxes mid-clear. The user can re-enable crash reporting later from
    // Settings; nothing here re-opens the SDK on its own.
    await Sentry.close();

    await Future.wait([
      _hiveDBProvider.configBox.clear(),
      _hiveDBProvider.intakeBox.clear(),
      _hiveDBProvider.userActivityBox.clear(),
      _hiveDBProvider.userBox.clear(),
      _hiveDBProvider.trackedDayBox.clear(),
      _hiveDBProvider.customMealBox.clear(),
      _hiveDBProvider.recipeBox.clear(),
      _hiveDBProvider.cachedOffMealBox.clear(),
      _hiveDBProvider.cachedOffMealTimestampsBox.clear(),
      _hiveDBProvider.customActivityTemplateBox.clear(),
      _hiveDBProvider.weightLogBox.clear(),
    ]);
  }
}
