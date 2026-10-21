import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/reminders/domain/reminder.dart';
import 'package:opennutritracker/features/reminders/domain/reminder_planner.dart';

Reminder _reminder(
  String id, {
  ReminderType type = ReminderType.breakfast,
  Set<int> weekdays = Reminder.everyDay,
  bool enabled = true,
}) => Reminder(
  id: id,
  type: type,
  hour: 8,
  minute: 30,
  weekdays: weekdays,
  enabled: enabled,
);

void main() {
  group('Reminder', () {
    test('survives a JSON round trip', () {
      final reminder = _reminder(
        'r1',
        type: ReminderType.water,
        weekdays: {1, 3, 5},
      );

      expect(Reminder.fromJson(reminder.toJson()), reminder);
    });

    test('an unknown type from a newer version reads as the meal log', () {
      final json = _reminder('r1').toJson()..['type'] = 'sleep';

      expect(Reminder.fromJson(json).type, ReminderType.logMeals);
    });
  });

  group('planning', () {
    test('one weekly notification per chosen weekday', () {
      final plan = planReminders([
        _reminder('a', weekdays: {1, 3}),
      ]);

      expect(plan.map((p) => p.weekday), [1, 3]);
      expect(plan.every((p) => p.reminder.id == 'a'), isTrue);
    });

    test('switched off reminders are not planned', () {
      expect(planReminders([_reminder('a', enabled: false)]), isEmpty);
    });

    test('ids are unique and inside the reserved range', () {
      final plan = planReminders([_reminder('a'), _reminder('b')]);
      final ids = plan.map((p) => p.id).toSet();

      expect(ids, hasLength(14));
      expect(ids.every(reminderNotificationIds.contains), isTrue);
    });

    test('the iOS limit is never exceeded', () {
      final plan = planReminders([
        for (var i = 0; i < 20; i++) _reminder('r$i'),
      ]);

      expect(plan, hasLength(maxPlannedReminders));
      expect(maxPlannedReminders, lessThanOrEqualTo(63));
    });

    test('a reminder without weekdays plans nothing', () {
      expect(planReminders([_reminder('a', weekdays: {})]), isEmpty);
    });
  });
}
