import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/reminders/domain/reminder.dart';
import 'package:opennutritracker/features/reminders/domain/reminder_planner.dart';

Reminder _reminder(
  ReminderType type, {
  Set<int> weekdays = Reminder.everyDay,
  int hour = 12,
}) => Reminder(
  id: type.name,
  type: type,
  hour: hour,
  minute: 0,
  weekdays: weekdays,
  enabled: true,
);

void main() {
  final wednesdayMorning = DateTime(2026, 10, 21, 9);

  test('a meal reminder is planned for each of the next seven days', () {
    final plan = planReminders([
      _reminder(ReminderType.lunch),
    ], now: wednesdayMorning);

    expect(plan.map((p) => p.at), [
      for (var d = 21; d <= 27; d++) DateTime(2026, 10, d, 12),
    ]);
    expect(plan.every((p) => p.weekday == null), isTrue);
  });

  test('only on its weekdays', () {
    final plan = planReminders([
      _reminder(ReminderType.dinner, weekdays: {1, 5}),
    ], now: wednesdayMorning);

    expect(plan.map((p) => p.at), [
      DateTime(2026, 10, 23, 12),
      DateTime(2026, 10, 26, 12),
    ]);
  });

  test("today's is left out once the meal is logged", () {
    final plan = planReminders(
      [_reminder(ReminderType.lunch)],
      now: wednesdayMorning,
      loggedToday: {ReminderType.lunch},
    );

    expect(plan.first.at, DateTime(2026, 10, 22, 12));
    expect(plan, hasLength(6));
  });

  test("today's is left out once its time has passed", () {
    final plan = planReminders([
      _reminder(ReminderType.breakfast, hour: 8),
    ], now: wednesdayMorning);

    expect(plan.first.at, DateTime(2026, 10, 22, 8));
  });

  test('another meal logged today does not stop it', () {
    final plan = planReminders(
      [_reminder(ReminderType.dinner)],
      now: wednesdayMorning,
      loggedToday: {ReminderType.breakfast},
    );

    expect(plan.first.at, DateTime(2026, 10, 21, 12));
  });

  test('water and weighing stay weekly', () {
    final plan = planReminders([
      _reminder(ReminderType.water, weekdays: {2}),
    ], now: wednesdayMorning);

    expect(plan.single.weekday, 2);
    expect(plan.single.at, isNull);
  });

  test('the days cross the clock change on the wall time', () {
    final plan = planReminders([
      _reminder(ReminderType.lunch),
    ], now: DateTime(2026, 10, 23, 9));

    expect(plan.map((p) => p.at!.hour).toSet(), {12});
    expect(plan.last.at, DateTime(2026, 10, 29, 12));
  });

  test('the budget still holds', () {
    final plan = planReminders([
      for (final type in ReminderType.values)
        for (var i = 0; i < 2; i++) _reminder(type),
    ], now: wednesdayMorning);

    expect(plan, hasLength(maxPlannedReminders));
  });
}
