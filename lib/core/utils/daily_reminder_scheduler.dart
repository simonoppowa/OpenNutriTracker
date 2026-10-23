import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/l10n/app_locales.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The one path that schedules or cancels the daily reminder, so that a
/// background refresh and the Settings switch cannot interleave.
///
/// The OS keeps the title, body and channel name it was handed, so the
/// reminder only follows the app language if it is rescheduled whenever that
/// changes (#1366), not just at start-up (#312). Those refreshes run in the
/// background; if one that had read "enabled" reached the OS after Settings
/// cancelled, a reminder would outlive the switch that turned it off. Every
/// operation here therefore runs one at a time, and a refresh reads the
/// saved state only once it is its turn.
///
/// The strings are looked up for the locale directly rather than read off a
/// `BuildContext`: when the language changes, the tree around the caller is
/// still the old language until the next frame.
class DailyReminderScheduler {
  DailyReminderScheduler(this._configRepository, this._notificationService);

  final ConfigRepository _configRepository;
  final NotificationService _notificationService;
  final _log = Logger('DailyReminderScheduler');

  Future<void> _last = Future.value();

  /// Schedules the reminder at the saved time, with its text in the language
  /// of [locale] — or, for "System default" (null), the language
  /// `MaterialApp` resolves from [deviceLocales]. While reminders are off it
  /// cancels the reminder instead, which is how an alarm left behind by a
  /// [setEnabled] that failed twice over is removed at the next start-up or
  /// language change.
  Future<void> reschedule({
    required Locale? locale,
    List<Locale>? deviceLocales,
  }) => _serialized(() => _reschedule(locale, deviceLocales));

  /// [reschedule] for callers that must not fail on it — start-up and
  /// language changes. A failure is logged, and the next refresh retries.
  Future<void> refresh({
    required Locale? locale,
    List<Locale>? deviceLocales,
  }) async {
    try {
      await reschedule(locale: locale, deviceLocales: deviceLocales);
    } catch (error, stackTrace) {
      _log.warning('Could not refresh the daily reminder', error, stackTrace);
    }
  }

  /// Turns the reminder on or off and saves that choice; [locale] is the
  /// language the app currently shows.
  ///
  /// Saving the flag and telling the OS are two steps, and either can fail
  /// after the other has happened. A save can even fail half-way: the
  /// config is written to the shared and the profile box separately, and
  /// the flag is read from the shared one. And an alarm can be set while
  /// the flag reads off before this call starts, left by an earlier
  /// failure such as a [stopAll] whose cancel failed. So whichever step
  /// fails, the outcome is decided from what is saved and what the OS
  /// holds, not from what this call meant to do (#1389):
  ///
  /// - the flag reads on: it stays on, and any alarm with it; if none is
  ///   set, the next [reschedule] sets it.
  /// - the flag reads off: the OS is asked whether it holds the reminder.
  ///   If it does, the reminder is cancelled, or, when the OS refuses that,
  ///   the flag is put back to on. If the OS cannot be asked, what this
  ///   call knows stands in: an alarm it set, or one the flag said was set.
  ///
  /// Only if all of that fails too does the switch read off with an alarm
  /// still set, which the next [reschedule] cancels.
  Future<void> setEnabled(bool enabled, {required Locale locale}) =>
      _serialized(() async {
        final config = await _configRepository.getConfig();
        // Whether the OS holds the reminder, as far as this call knows.
        var alarmSet = config.notificationsEnabled;
        var cancelFailed = false;
        try {
          if (enabled) {
            await _schedule(config, locale, null);
            alarmSet = true;
            await _configRepository.setNotificationsEnabled(true);
          } else {
            await _configRepository.setNotificationsEnabled(false);
            cancelFailed = true;
            await _notificationService.cancelDailyReminder();
          }
        } catch (_) {
          await _reconcile(alarmSet: alarmSet, cancelFailed: cancelFailed);
          rethrow;
        }
      });

  /// After a [setEnabled] step failed: while the saved flag reads off, no
  /// reminder may stay pending, so one that is gets cancelled — or, if the
  /// OS refuses, the flag goes back to on to match it. [alarmSet] answers
  /// for the OS when it cannot be asked; [cancelFailed] skips a second
  /// cancel straight after one that failed. A failure here is logged rather
  /// than allowed to hide the first error.
  Future<void> _reconcile({
    required bool alarmSet,
    required bool cancelFailed,
  }) async {
    try {
      final saved = (await _configRepository.getConfig()).notificationsEnabled;
      if (saved) return;
      if (!await _reminderPending(orElse: alarmSet)) return;
      if (!cancelFailed) {
        try {
          await _notificationService.cancelDailyReminder();
          return;
        } catch (error, stackTrace) {
          _log.warning(
            'Could not cancel the daily reminder',
            error,
            stackTrace,
          );
        }
      }
      await _configRepository.setNotificationsEnabled(true);
    } catch (error, stackTrace) {
      _log.warning(
        'Could not reconcile a partial daily reminder change',
        error,
        stackTrace,
      );
    }
  }

  /// Saves a new reminder time and reschedules at it.
  Future<void> setTime(int hour, int minute, {required Locale locale}) =>
      _serialized(() async {
        await _configRepository.setNotificationTime(hour, minute);
        await _reschedule(locale, null);
      });

  /// Switches reminders off and cancels every notification the app has
  /// scheduled, fasting included — for delete-all, which must not race a
  /// refresh that already read "enabled". The cancel is attempted even if
  /// saving "off" failed; either failure is rethrown.
  Future<void> stopAll() => _serialized(() async {
    try {
      await _configRepository.setNotificationsEnabled(false);
    } finally {
      await _notificationService.cancelAllScheduled();
    }
  });

  /// Whether the OS holds the reminder, or [orElse] if it cannot say.
  Future<bool> _reminderPending({required bool orElse}) async {
    try {
      return await _notificationService.isDailyReminderPending();
    } catch (error, stackTrace) {
      _log.warning(
        'Could not ask whether the daily reminder is set',
        error,
        stackTrace,
      );
      return orElse;
    }
  }

  /// Runs [operation] once every earlier one has finished, failed or not.
  Future<void> _serialized(Future<void> Function() operation) {
    final run = _last.then((_) => operation());
    _last = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  Future<void> _reschedule(Locale? locale, List<Locale>? deviceLocales) async {
    final config = await _configRepository.getConfig();
    if (!config.notificationsEnabled) {
      await _notificationService.cancelDailyReminder();
      return;
    }
    await _schedule(config, locale, deviceLocales);
  }

  Future<void> _schedule(
    ConfigEntity config,
    Locale? locale,
    List<Locale>? deviceLocales,
  ) async {
    final s = lookupS(
      basicLocaleListResolution(
        locale != null
            ? [locale]
            : deviceLocales ?? PlatformDispatcher.instance.locales,
        appLocales(S.supportedLocales),
      ),
    );
    await _notificationService.initialize();
    await _notificationService.scheduleDailyReminder(
      hour: config.notificationHour,
      minute: config.notificationMinute,
      title: s.notificationsDailyReminderTitle,
      body: s.notificationsDailyReminderBody,
      channelName: s.notificationsDailyReminderChannelName,
      channelDescription: s.notificationsDailyReminderChannelDescription,
    );
  }
}
