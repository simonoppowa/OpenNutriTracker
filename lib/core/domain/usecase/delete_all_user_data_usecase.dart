import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
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
///
/// One thing it clears is **not** per-profile: the AI credential store, which
/// is keyed by provider and shared by every profile on the device. That is a
/// deliberate exception rather than an oversight — see [deleteAll] — and the
/// confirmation dialog says so.
class DeleteAllUserDataUsecase {
  final _log = Logger('DeleteAllUserDataUsecase');
  final HiveDBProvider _hiveDBProvider;
  final NotificationService _notificationService;
  final ConfigRepository _configRepository;
  final AiCredentialStorage _aiCredentials;

  DeleteAllUserDataUsecase(
    this._hiveDBProvider,
    this._notificationService,
    this._configRepository,
    this._aiCredentials,
  );

  Future<void> deleteAll() async {
    _log.info('Clearing the active profile\'s Hive boxes on user request');

    // Before the boxes, not after, and in two halves — either alone leaves
    // the reminder alive. #764 watched an 08:00 ping survive a delete-all,
    // where only uninstalling the app removed it.
    await _stopScheduledNotifications();

    // Closing Sentry before the clear stops any in-flight queue from
    // referencing boxes mid-clear. The user can re-enable crash reporting later from
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

    // The device-wide exception. This store is keyed by provider, not by
    // profile, so clearing it takes a credential the other profiles share —
    // which is why the confirmation dialog names it.
    //
    // Keeping it would be the worse trade. The caller lands on onboarding
    // straight after this, and onboarding reads this same store: the profile
    // would come back up already pointed at a provider, already enabled, so
    // whoever set it up next would inherit a working paid key and — for a
    // server the user runs — the address of a machine on someone's network.
    // #892.
    await _aiCredentials.clearAll();
  }

  /// Stops the reminder in both of the places that keep it alive.
  ///
  /// The OS holds the scheduled alarm, and it does not care that the data it
  /// was scheduled from is gone — so it has to be told. Switching the setting
  /// off matters just as much and is easier to miss: `notificationsEnabled`
  /// is a *shared* preference, kept in the app box that this wipe
  /// deliberately leaves alone so theme, language and units survive. Left
  /// standing, `main.dart` reschedules the reminder from it on the next cold
  /// start, and a cancel on its own would hold only until the user next quit
  /// the app.
  ///
  /// Each half is attempted separately and neither can stop the wipe. The
  /// user asked for their data to be gone, and refusing to delete it because
  /// a notification plugin was unavailable is the worse of the two failures:
  /// a surviving alarm can still be uninstalled, while data kept against an
  /// explicit request is not what they asked for at all.
  Future<void> _stopScheduledNotifications() async {
    await _bestEffort(
      () => _configRepository.setNotificationsEnabled(false),
      'Could not switch the daily reminder off; the next launch may schedule '
          'it again from a setting this wipe does not clear',
    );
    await _bestEffort(
      () => _notificationService.cancelAllScheduled(),
      'Could not cancel scheduled notifications; an alarm may outlive the '
          'data it was scheduled from',
    );
  }

  Future<void> _bestEffort(Future<void> Function() step, String failure) async {
    try {
      await step();
    } catch (error, stackTrace) {
      _log.severe(failure, error, stackTrace);
    }
  }
}
