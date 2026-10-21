import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/features/reminders/data/reminder_store.dart';
import 'package:opennutritracker/features/reminders/domain/reminder.dart';
import 'package:opennutritracker/features/reminders/domain/reminder_planner.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The notification title and body of a reminder [type] in the language of
/// [s].
(String, String) reminderTexts(ReminderType type, S s) => switch (type) {
  ReminderType.logMeals => (
    s.notificationsDailyReminderTitle,
    s.notificationsDailyReminderBody,
  ),
  ReminderType.breakfast => (s.reminderBreakfastTitle, s.reminderBreakfastBody),
  ReminderType.lunch => (s.reminderLunchTitle, s.reminderLunchBody),
  ReminderType.dinner => (s.reminderDinnerTitle, s.reminderDinnerBody),
  ReminderType.snack => (s.reminderSnackTitle, s.reminderSnackBody),
  ReminderType.water => (s.reminderWaterTitle, s.reminderWaterBody),
  ReminderType.weigh => (s.reminderWeighTitle, s.reminderWeighBody),
};

/// Puts the stored reminders into the system's notification schedule (#71):
/// clears every reminder slot and the daily reminder of earlier versions,
/// then schedules the plan of [planReminders]. Run at start, on resume (a
/// changed time zone), after an edit and after a language change.
class ReminderScheduler {
  final ReminderStore _store;
  final NotificationService _notifications;

  ReminderScheduler(this._store, this._notifications);

  Future<void> _last = Future.value();

  /// Runs after any sync still in progress, so two runs never interleave
  /// their cancelling and scheduling.
  Future<void> sync(S s) {
    final run = _last.catchError((_) {}).then((_) => _sync(s));
    _last = run;
    return run;
  }

  Future<void> _sync(S s) async {
    final plan = planReminders(await _store.load());
    await _notifications.cancelDailyReminder();
    await _notifications.cancelIds(reminderNotificationIds);
    for (final planned in plan) {
      final (title, body) = reminderTexts(planned.reminder.type, s);
      await _notifications.scheduleWeekly(
        id: planned.id,
        weekday: planned.weekday,
        hour: planned.reminder.hour,
        minute: planned.reminder.minute,
        title: title,
        body: body,
        channelName: s.reminderChannelName,
        channelDescription: s.reminderChannelDescription,
      );
    }
  }
}
