import 'package:opennutritracker/features/reminders/domain/reminder.dart';

/// iOS keeps at most 64 pending notifications per app. The reminders take
/// 60 of them, which leaves room for the fasting notification (#71).
const maxPlannedReminders = 60;

/// How many days ahead meal reminders are planned one by one (#72).
const mealReminderDays = 7;

/// The notification ids reserved for reminders; a sync cancels all of them
/// before it schedules the current plan.
final reminderNotificationIds = [
  for (var i = 0; i < maxPlannedReminders; i++) 100 + i,
];

/// The reminder types that ask to log a meal: planned one by one so the one
/// of a day can be left out once the meal is logged (#72).
const mealReminderTypes = {
  ReminderType.logMeals,
  ReminderType.breakfast,
  ReminderType.lunch,
  ReminderType.dinner,
  ReminderType.snack,
};

/// One notification under [id]: weekly on [weekday], or once at [at].
class PlannedReminder {
  final int id;
  final Reminder reminder;
  final int? weekday;
  final DateTime? at;

  const PlannedReminder({
    required this.id,
    required this.reminder,
    this.weekday,
    this.at,
  });
}

/// The notifications for the switched-on [reminders], in list order and cut
/// to [maxPlannedReminders].
///
/// Water and weigh-in reminders repeat weekly, one per chosen weekday (#71).
/// Meal reminders are single notifications for the chosen weekdays of the
/// next [mealReminderDays] days from [now] (#72); today's is left out when
/// its time has passed or its type is in [loggedToday]. The app tops the
/// window up whenever it syncs, so meal reminders end when it has not been
/// opened for that long.
List<PlannedReminder> planReminders(
  List<Reminder> reminders, {
  DateTime? now,
  Set<ReminderType> loggedToday = const {},
}) {
  final moment = now ?? DateTime.now();
  final plan = <PlannedReminder>[];
  bool add(Reminder reminder, {int? weekday, DateTime? at}) {
    if (plan.length == maxPlannedReminders) return false;
    plan.add(
      PlannedReminder(
        id: reminderNotificationIds[plan.length],
        reminder: reminder,
        weekday: weekday,
        at: at,
      ),
    );
    return true;
  }

  for (final reminder in reminders) {
    if (!reminder.enabled) continue;
    if (!mealReminderTypes.contains(reminder.type)) {
      for (final weekday in reminder.weekdays.toList()..sort()) {
        if (!add(reminder, weekday: weekday)) return plan;
      }
      continue;
    }
    for (var offset = 0; offset < mealReminderDays; offset++) {
      final at = DateTime(
        moment.year,
        moment.month,
        moment.day + offset,
        reminder.hour,
        reminder.minute,
      );
      if (!reminder.weekdays.contains(at.weekday)) continue;
      if (offset == 0 &&
          (!at.isAfter(moment) || loggedToday.contains(reminder.type))) {
        continue;
      }
      if (!add(reminder, at: at)) return plan;
    }
  }
  return plan;
}
