import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/settings/domain/backup_reminder.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/export_import_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A dismissible card on the home screen when the last JSON backup is older
/// than the chosen period, or when there is none yet (see [BackupReminder]).
/// Dismissing hides it until the next app start; backing up from it hides
/// it for the period.
class BackupReminderCard extends StatefulWidget {
  final BackupReminder? reminder;
  final DateTime Function() clock;

  const BackupReminderCard({
    super.key,
    this.reminder,
    this.clock = DateTime.now,
  });

  @override
  State<BackupReminderCard> createState() => _BackupReminderCardState();
}

class _BackupReminderCardState extends State<BackupReminderCard> {
  static bool _dismissedThisSession = false;

  late final BackupReminder _reminder =
      widget.reminder ?? locator<BackupReminder>();
  DateTime? _lastBackupAt;
  bool _due = false;

  @override
  void initState() {
    super.initState();
    _reminder.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _reminder.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final state = await _reminder.load();
    if (!mounted) return;
    setState(() {
      _lastBackupAt = state.lastBackupAt;
      _due = state.isDue;
    });
  }

  Future<void> _backUp() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const ExportImportDialog(),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_due || _dismissedThisSession) return const SizedBox.shrink();
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    final accent = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    final last = _lastBackupAt;
    final body = last == null
        ? l10n.backupReminderNoBackupBody
        : l10n.backupReminderOldBody(widget.clock().difference(last).inDays);

    return Semantics(
      identifier: 'home-backup-reminder',
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimens.spacing16,
          vertical: Dimens.spacing8,
        ),
        child: AppCard(
          color: palette.surfaceMuted,
          padding: const EdgeInsets.fromLTRB(
            Dimens.spacing16,
            Dimens.spacing8,
            Dimens.spacing4,
            Dimens.spacing8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.backup_outlined, color: accent, size: 22),
                  const SizedBox(width: Dimens.spacing12),
                  Expanded(
                    child: Text(
                      l10n.backupReminderTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: palette.textStrong,
                      ),
                    ),
                  ),
                  Semantics(
                    identifier: 'home-backup-reminder-dismiss',
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () =>
                          setState(() => _dismissedThisSession = true),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: Dimens.spacing12,
                ),
                child: Text(
                  body,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Semantics(
                  identifier: 'home-backup-reminder-action',
                  child: TextButton(
                    onPressed: _backUp,
                    child: Text(l10n.backupReminderAction),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
