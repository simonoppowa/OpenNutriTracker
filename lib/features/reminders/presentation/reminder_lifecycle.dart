import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/features/reminders/data/reminder_scheduler.dart';
import 'package:opennutritracker/features/reminders/data/reminder_store.dart';
import 'package:opennutritracker/generated/l10n.dart';

final _log = Logger('Reminders');

/// Kept alive for the app's lifetime once [startReminders] ran.
AppLifecycleListener? _resumeListener;

S _stringsFor(Locale locale) =>
    lookupS(basicLocaleListResolution([locale], S.supportedLocales));

/// Puts the stored reminders into the notification schedule with the texts
/// of [locale], or of the stored or device language (#71). Unless [always],
/// it does nothing while no reminder is switched on; the reminders screen
/// syncs itself after every edit, and a restored backup passes [always] so
/// reminders it switched off are cleared too. Never throws.
Future<void> syncReminders({Locale? locale, bool always = false}) async {
  try {
    if (!always &&
        !(await locator<ReminderStore>().load()).any((r) => r.enabled)) {
      return;
    }
    final code = await locator<ConfigDataSource>().getSelectedLocale();
    final resolved =
        locale ??
        (code != null ? Locale(code) : PlatformDispatcher.instance.locale);
    await locator<ReminderScheduler>().sync(_stringsFor(resolved));
  } catch (error, stackTrace) {
    _log.warning('Could not schedule the reminders', error, stackTrace);
  }
}

/// Schedules the reminders at start and again whenever the app comes back:
/// that tops up the meal reminders planned a week ahead (#72), and after
/// reading the time zone again keeps weekly reminders on the local wall
/// time after travelling (#71).
void startReminders() {
  unawaited(syncReminders());
  _resumeListener ??= AppLifecycleListener(
    onResume: () async {
      try {
        await locator<NotificationService>().refreshTimeZone();
      } catch (error, stackTrace) {
        _log.warning('Could not check the time zone', error, stackTrace);
      }
      await syncReminders();
    },
  );
}
