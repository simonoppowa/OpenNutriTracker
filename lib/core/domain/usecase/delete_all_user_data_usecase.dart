import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/daily_reminder_scheduler.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/core/utils/tracked_day_reconciler.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_writer.dart';
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
  final DailyReminderScheduler _reminders;
  final AiCredentialStorage _aiCredentials;
  final CalorieWidgetStore _calorieWidgetStore;

  DeleteAllUserDataUsecase(
    this._hiveDBProvider,
    this._reminders,
    this._aiCredentials, {
    CalorieWidgetStore? calorieWidgetStore,
  }) : _calorieWidgetStore =
           calorieWidgetStore ?? HomeWidgetCalorieStore();

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
    //
    // The day boundary is one of those shared settings, so the emptied
    // profile records it straight away, in the same locked step as the
    // clear: rows it writes from here on are keyed by it, not by the
    // midnight an unrecorded history is assumed to use (#1317).
    await withTrackedDayLock(() async {
      await Future.wait([
        _hiveDBProvider.configBox.clear(),
        _hiveDBProvider.intakeBox.clear(),
        _hiveDBProvider.userActivityBox.clear(),
        _hiveDBProvider.userBox.clear(),
        _hiveDBProvider.trackedDayBox.clear(),
        _hiveDBProvider.weightLogBox.clear(),
        _hiveDBProvider.waterIntakeBox.clear(),
        _hiveDBProvider.fastingBox.clear(),
        _hiveDBProvider.favouriteMealBox.clear(),
      ]);
      await recordTrackedDayBoundary(ConfigDataSource(_hiveDBProvider));
    });

    // The iOS widget reads its own copy of today's figures from the App
    // Group, not from Hive, so it would keep showing the deleted profile
    // until the next day boundary. Best effort for the same reason as the
    // reminder: a widget plugin failing must not keep the data.
    try {
      await _calorieWidgetStore.clear();
    } catch (error, stackTrace) {
      _log.severe(
        'Could not clear the home-screen widget; it may show the deleted '
        'figures until the day ends',
        error,
        stackTrace,
      );
    }

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
  /// Both halves go through [DailyReminderScheduler], so a language refresh
  /// that already read "enabled" finishes first instead of scheduling the
  /// reminder again after this cancelled it.
  ///
  /// Neither half can stop the wipe, and the cancel is attempted even if
  /// switching the setting off failed. The user asked for their data to be
  /// gone, and refusing to delete it because a notification plugin was
  /// unavailable is the worse of the two failures: a surviving alarm can
  /// still be uninstalled — and with the setting off, the next start-up
  /// cancels the daily reminder again — while data kept against an explicit
  /// request is not what they asked for at all.
  Future<void> _stopScheduledNotifications() async {
    try {
      await _reminders.stopAll();
    } catch (error, stackTrace) {
      _log.severe(
        'Could not fully stop scheduled notifications; an alarm may outlive '
        'the data it was scheduled from',
        error,
        stackTrace,
      );
    }
  }
}
