import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/features/reminders/data/reminder_scheduler.dart';
import 'package:opennutritracker/features/reminders/data/reminder_store.dart';
import 'package:opennutritracker/features/reminders/domain/reminder.dart';
import 'package:opennutritracker/features/reminders/domain/reminder_planner.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The label of a reminder [type] in lists and the type picker.
String reminderTypeLabel(ReminderType type, S s) => switch (type) {
  ReminderType.logMeals => s.reminderTypeLogMeals,
  ReminderType.breakfast => s.reminderBreakfastTitle,
  ReminderType.lunch => s.reminderLunchTitle,
  ReminderType.dinner => s.reminderDinnerTitle,
  ReminderType.snack => s.reminderSnackTitle,
  ReminderType.water => s.reminderWaterTitle,
  ReminderType.weigh => s.reminderWeighTitle,
};

IconData _icon(ReminderType type) => switch (type) {
  ReminderType.logMeals => Icons.edit_note_rounded,
  ReminderType.breakfast => Icons.free_breakfast_rounded,
  ReminderType.lunch => Icons.lunch_dining_rounded,
  ReminderType.dinner => Icons.dinner_dining_rounded,
  ReminderType.snack => Icons.cookie_rounded,
  ReminderType.water => Icons.water_drop_rounded,
  ReminderType.weigh => Icons.monitor_weight_rounded,
};

/// [hour]:[minute] as HH:mm, as the daily reminder showed it.
String _time(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// The short name of [weekday] (Monday is 1) in the app's language.
String _weekdayName(BuildContext context, int weekday) => DateFormat.E(
  Localizations.localeOf(context).toLanguageTag(),
).format(DateTime(2024, 1, weekday));

/// Settings → Reminders (#70): the user's reminders with their time and
/// days, a switch each, and a dialog to add, change or delete one. Every
/// change is saved and put into the notification schedule right away
/// (#71); switching one on asks for the notification permission first.
class RemindersScreen extends StatefulWidget {
  final ReminderStore? store;
  final ReminderScheduler? scheduler;
  final Future<bool> Function()? requestPermission;

  const RemindersScreen({
    super.key,
    this.store,
    this.scheduler,
    this.requestPermission,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late final ReminderStore _store = widget.store ?? locator<ReminderStore>();
  late final ReminderScheduler _scheduler =
      widget.scheduler ?? locator<ReminderScheduler>();
  List<Reminder>? _reminders;

  @override
  void initState() {
    super.initState();
    _store.load().then((reminders) {
      if (mounted) setState(() => _reminders = reminders);
    });
  }

  Future<bool> _permission() async {
    final request = widget.requestPermission;
    if (request != null) return request();
    final service = locator<NotificationService>();
    await service.initialize();
    return service.requestPermission();
  }

  /// Saves [reminders] and schedules them; a switched-on reminder without
  /// the permission is saved switched off.
  Future<void> _apply(List<Reminder> reminders) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var result = reminders;
    if (reminders.any((r) => r.enabled) && !await _permission()) {
      result = [for (final r in reminders) r.copyWith(enabled: false)];
      messenger.showSnackBar(
        SnackBar(content: Text(s.notificationsPermissionDeniedSnack)),
      );
    }
    await _store.save(result);
    if (mounted) setState(() => _reminders = result);
    await _scheduler.sync(s);
  }

  Future<void> _edit(Reminder? reminder) async {
    final current = _reminders ?? const [];
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (_) => _ReminderDialog(
        reminder:
            reminder ??
            Reminder(
              id: IdGenerator.getUniqueID(),
              type: ReminderType.breakfast,
              hour: 8,
              minute: 0,
              weekdays: Reminder.everyDay,
              enabled: true,
            ),
        isNew: reminder == null,
      ),
    );
    if (result == null) return;
    final updated = switch (result) {
      _Delete() => [
        for (final r in current)
          if (r.id != reminder?.id) r,
      ],
      _Save(:final reminder) =>
        current.any((r) => r.id == reminder.id)
            ? [for (final r in current) r.id == reminder.id ? reminder : r]
            : [...current, reminder],
    };
    await _apply(updated);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final reminders = _reminders;
    final planned = reminders == null
        ? 0
        : reminders
              .where((r) => r.enabled)
              .fold<int>(0, (sum, r) => sum + r.weekdays.length);
    return Scaffold(
      appBar: AppBar(title: Text(s.remindersLabel)),
      floatingActionButton: Semantics(
        identifier: 'reminders-add',
        child: FloatingActionButton(
          tooltip: s.remindersAdd,
          onPressed: () => _edit(null),
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: reminders == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                if (reminders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(Dimens.spacing20),
                    child: Text(s.remindersEmpty),
                  ),
                if (planned > maxPlannedReminders)
                  Padding(
                    padding: const EdgeInsets.all(Dimens.spacing16),
                    child: Text(
                      s.remindersOverBudget(maxPlannedReminders),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                for (final reminder in reminders)
                  Semantics(
                    identifier: 'reminder-tile-${reminder.id}',
                    child: ListTile(
                      leading: Icon(_icon(reminder.type)),
                      title: Text(reminderTypeLabel(reminder.type, s)),
                      subtitle: Text(
                        '${_time(reminder.hour, reminder.minute)}'
                        ' · ${_days(context, reminder.weekdays)}',
                      ),
                      onTap: () => _edit(reminder),
                      trailing: Semantics(
                        identifier: 'reminder-switch-${reminder.id}',
                        child: Switch(
                          value: reminder.enabled,
                          onChanged: (enabled) => _apply([
                            for (final r in reminders)
                              r.id == reminder.id
                                  ? r.copyWith(enabled: enabled)
                                  : r,
                          ]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String _days(BuildContext context, Set<int> weekdays) {
    final s = S.of(context);
    if (weekdays.length == 7) return s.reminderEveryDay;
    if (weekdays.isEmpty) return s.reminderNoDays;
    return [
      for (final day in weekdays.toList()..sort()) _weekdayName(context, day),
    ].join(', ');
  }
}

sealed class _EditResult {}

class _Save extends _EditResult {
  final Reminder reminder;
  _Save(this.reminder);
}

class _Delete extends _EditResult {}

class _ReminderDialog extends StatefulWidget {
  final Reminder reminder;
  final bool isNew;

  const _ReminderDialog({required this.reminder, required this.isNew});

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  late Reminder _reminder = widget.reminder;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminder.hour, minute: _reminder.minute),
    );
    if (picked == null) return;
    setState(
      () => _reminder = _reminder.copyWith(
        hour: picked.hour,
        minute: picked.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final time = _time(_reminder.hour, _reminder.minute);
    return AlertDialog(
      title: Text(s.reminderEditTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              identifier: 'reminder-type',
              child: DropdownButtonFormField<ReminderType>(
                initialValue: _reminder.type,
                decoration: InputDecoration(labelText: s.reminderTypeLabel),
                items: [
                  for (final type in ReminderType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(reminderTypeLabel(type, s)),
                    ),
                ],
                onChanged: (type) =>
                    setState(() => _reminder = _reminder.copyWith(type: type)),
              ),
            ),
            const SizedBox(height: Dimens.spacing12),
            Semantics(
              identifier: 'reminder-time',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time_rounded),
                title: Text(s.reminderTimeLabel),
                trailing: Text(time),
                onTap: _pickTime,
              ),
            ),
            Text(s.reminderWeekdaysLabel),
            const SizedBox(height: Dimens.spacing4),
            Wrap(
              spacing: Dimens.spacing4,
              children: [
                for (var day = 1; day <= 7; day++)
                  Semantics(
                    identifier: 'reminder-weekday-$day',
                    child: FilterChip(
                      label: Text(_weekdayName(context, day)),
                      selected: _reminder.weekdays.contains(day),
                      onSelected: (selected) => setState(
                        () => _reminder = _reminder.copyWith(
                          weekdays: selected
                              ? {..._reminder.weekdays, day}
                              : ({..._reminder.weekdays}..remove(day)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (!widget.isNew)
          Semantics(
            identifier: 'reminder-dialog-delete',
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(_Delete()),
              child: Text(s.dialogDeleteLabel),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogCancelLabel),
        ),
        Semantics(
          identifier: 'reminder-dialog-save',
          child: FilledButton(
            onPressed: _reminder.weekdays.isEmpty
                ? null
                : () => Navigator.of(context).pop(_Save(_reminder)),
            child: Text(s.buttonSaveLabel),
          ),
        ),
      ],
    );
  }
}
