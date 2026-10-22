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
  /// cancels the reminder instead: "off" is saved before the OS is told, so
  /// if that cancel failed, start-up or the next language change is where
  /// the surviving alarm gets removed.
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
  /// language the app currently shows. "On" is saved only once the OS holds
  /// the reminder, so a failed schedule throws and leaves the switch off.
  Future<void> setEnabled(bool enabled, {required Locale locale}) =>
      _serialized(() async {
        if (enabled) {
          final config = await _configRepository.getConfig();
          await _schedule(config, locale, null);
          await _configRepository.setNotificationsEnabled(true);
        } else {
          await _configRepository.setNotificationsEnabled(false);
          await _notificationService.cancelDailyReminder();
        }
      });

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
