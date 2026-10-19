import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/settings/domain/backup_reminder.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// When the last JSON backup was saved, and after how many days the home
/// screen reminds of the next one. Shown in the export dialog; reloads when
/// [refreshKey] changes (the dialog bumps it after a finished export).
class BackupStatusRow extends StatefulWidget {
  final BackupReminder? reminder;
  final Object? refreshKey;

  const BackupStatusRow({super.key, this.reminder, this.refreshKey});

  @override
  State<BackupStatusRow> createState() => _BackupStatusRowState();
}

class _BackupStatusRowState extends State<BackupStatusRow> {
  late final BackupReminder _reminder =
      widget.reminder ?? locator<BackupReminder>();
  DateTime? _lastBackupAt;
  int? _reminderDays;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(BackupStatusRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) _load();
  }

  Future<void> _load() async {
    final state = await _reminder.load();
    if (!mounted) return;
    setState(() {
      _lastBackupAt = state.lastBackupAt;
      _reminderDays = state.reminderDays;
    });
  }

  Future<void> _setDays(int days) async {
    setState(() => _reminderDays = days);
    await _reminder.setReminderDays(days);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final days = _reminderDays;
    final last = _lastBackupAt;
    final lastText = last == null
        ? l10n.exportImportNoBackupLabel
        : l10n.exportImportLastBackupLabel(
            DateFormat.yMd(
              Localizations.localeOf(context).toLanguageTag(),
            ).add_Hm().format(last),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lastText, style: textTheme.bodyMedium),
        if (days != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.exportImportReminderLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                identifier: 'export-import-reminder-days',
                child: DropdownButton<int>(
                  value: BackupReminder.reminderDayOptions.contains(days)
                      ? days
                      : BackupReminder.defaultReminderDays,
                  items: [
                    for (final option in BackupReminder.reminderDayOptions)
                      DropdownMenuItem(
                        value: option,
                        child: Text(
                          option == 0
                              ? l10n.exportImportReminderOffLabel
                              : l10n.exportImportReminderDaysLabel(option),
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) _setDays(value);
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}
