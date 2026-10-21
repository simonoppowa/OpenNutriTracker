import 'package:opennutritracker/features/reminders/domain/reminder.dart';

/// iOS keeps at most 64 pending notifications per app. The reminders take
/// 60 of them, which leaves room for the fasting notification (#71).
const maxPlannedReminders = 60;

/// The notification ids reserved for reminders; a sync cancels all of them
/// before it schedules the current plan.
final reminderNotificationIds = [
  for (var i = 0; i < maxPlannedReminders; i++) 100 + i,
];

/// One weekly notification: [reminder] on [weekday] under [id].
class PlannedReminder {
  final int id;
  final Reminder reminder;
  final int weekday;

  const PlannedReminder({
    required this.id,
    required this.reminder,
    required this.weekday,
  });
}

/// The weekly notifications for the switched-on [reminders], one per chosen
/// weekday, in list order and cut to [maxPlannedReminders] (#71).
List<PlannedReminder> planReminders(List<Reminder> reminders) {
  final plan = <PlannedReminder>[];
  for (final reminder in reminders) {
    if (!reminder.enabled) continue;
    for (final weekday in reminder.weekdays.toList()..sort()) {
      if (plan.length == maxPlannedReminders) return plan;
      plan.add(
        PlannedReminder(
          id: reminderNotificationIds[plan.length],
          reminder: reminder,
          weekday: weekday,
        ),
      );
    }
  }
  return plan;
}
