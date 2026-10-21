import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/features/reminders/domain/reminder.dart';

/// The user's reminders (#70), stored device-wide as JSON in the config
/// (field 118). The first read takes over the single daily reminder of
/// earlier versions when it was switched on; a list that cannot be read
/// (a broken backup, say) reads as empty. [changes] fires after every save.
class ReminderStore {
  static final _log = Logger('ReminderStore');
  static const _dailyId = 'daily';

  final ConfigDataSource _config;
  final changes = ValueNotifier<int>(0);

  ReminderStore(this._config);

  Future<List<Reminder>> load() async {
    final json = await _config.getRemindersJson();
    if (json != null) {
      try {
        return [
          for (final item in jsonDecode(json) as List)
            Reminder.fromJson(item as Map<String, dynamic>),
        ];
      } catch (error) {
        _log.warning('Stored reminders unreadable, starting empty: $error');
        return const [];
      }
    }
    final config = await _config.getConfig();
    if (config.notificationsEnabled != true) return const [];
    return [
      Reminder(
        id: _dailyId,
        type: ReminderType.logMeals,
        hour: config.notificationHour ?? 8,
        minute: config.notificationMinute ?? 0,
        weekdays: Reminder.everyDay,
        enabled: true,
      ),
    ];
  }

  /// Adds the daily "log your meals" reminder at 8:00 that onboarding offers,
  /// next to the reminders already there, or switches it back on.
  Future<void> addDailyReminder() async {
    final reminders = await load();
    final existing = reminders.where((r) => r.id == _dailyId).firstOrNull;
    await save([
      for (final r in reminders)
        r.id == _dailyId ? r.copyWith(enabled: true) : r,
      if (existing == null)
        const Reminder(
          id: _dailyId,
          type: ReminderType.logMeals,
          hour: 8,
          minute: 0,
          weekdays: Reminder.everyDay,
          enabled: true,
        ),
    ]);
  }

  Future<void> save(List<Reminder> reminders) async {
    await _config.setRemindersJson(
      jsonEncode([for (final reminder in reminders) reminder.toJson()]),
    );
    changes.value++;
  }
}
