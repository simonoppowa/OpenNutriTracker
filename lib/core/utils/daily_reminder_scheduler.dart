import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/l10n/app_locales.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Schedules the daily reminder at the saved time, with its text in the
/// language of [locale] — or, for "System default" (null), the language
/// `MaterialApp` resolves from [deviceLocales]. Does nothing while reminders
/// are off.
///
/// The OS keeps the title, body and channel name it was handed, so the
/// reminder only follows the app language if it is rescheduled whenever that
/// changes (#1366), not just at start-up (#312).
///
/// The strings are looked up for [locale] directly rather than read off a
/// `BuildContext`: when the language changes, the tree around the caller is
/// still the old language until the next frame.
Future<void> rescheduleDailyReminder({
  required ConfigRepository configRepository,
  required NotificationService notificationService,
  required Locale? locale,
  List<Locale>? deviceLocales,
}) async {
  final config = await configRepository.getConfig();
  if (!config.notificationsEnabled) return;

  final s = lookupS(
    basicLocaleListResolution(
      locale != null
          ? [locale]
          : deviceLocales ?? PlatformDispatcher.instance.locales,
      appLocales(S.supportedLocales),
    ),
  );
  await notificationService.initialize();
  await notificationService.scheduleDailyReminder(
    hour: config.notificationHour,
    minute: config.notificationMinute,
    title: s.notificationsDailyReminderTitle,
    body: s.notificationsDailyReminderBody,
    channelName: s.notificationsDailyReminderChannelName,
    channelDescription: s.notificationsDailyReminderChannelDescription,
  );
}
