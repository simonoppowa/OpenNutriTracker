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
  /// after the other has happened. If one does, the first is undone before
  /// the error is rethrown, so a failed call leaves the saved switch and the
  /// alarm agreeing as they did before it (#1389):
  ///
  /// - on: "on" is saved only once the OS holds the reminder. If saving
  ///   fails, an alarm that was not there before is cancelled again.
  /// - off: "off" is saved first. If the cancel then fails, the alarm is
  ///   still set, so a switch that was on is put back to on.
  ///
  /// Should the undo fail as well, the switch reads off with an alarm still
  /// set, which the next [reschedule] cancels.
  Future<void> setEnabled(bool enabled, {required Locale locale}) =>
      _serialized(() async {
        final config = await _configRepository.getConfig();
        final wasEnabled = config.notificationsEnabled;
        if (enabled) {
          await _schedule(config, locale, null);
          await _undoIfFails(
            () => _configRepository.setNotificationsEnabled(true),
            undo: wasEnabled ? null : _notificationService.cancelDailyReminder,
          );
        } else {
          await _configRepository.setNotificationsEnabled(false);
          await _undoIfFails(
            _notificationService.cancelDailyReminder,
            undo: wasEnabled
                ? () => _configRepository.setNotificationsEnabled(true)
                : null,
          );
        }
      });

  /// Runs [step]; if it throws, runs [undo] and rethrows what [step] threw.
  /// A failing [undo] is logged rather than allowed to hide that error.
  Future<void> _undoIfFails(
    Future<void> Function() step, {
    required Future<void> Function()? undo,
  }) async {
    try {
      await step();
    } catch (_) {
      if (undo != null) {
        try {
          await undo();
        } catch (error, stackTrace) {
          _log.warning(
            'Could not undo a partial daily reminder change',
            error,
            stackTrace,
          );
        }
      }
      rethrow;
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
