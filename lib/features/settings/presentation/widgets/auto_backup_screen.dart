import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/settings/data/auto_backup_settings.dart';
import 'package:opennutritracker/features/settings/domain/auto_backup_service.dart';
import 'package:opennutritracker/features/settings/domain/profiles_backup.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/reload_after_import.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Imports a downloaded backup into the app, as the import dialog does.
typedef RestoreArchive =
    Future<void> Function(Archive archive, {required bool replaceExisting});

Future<void> _restoreIntoApp(
  Archive archive, {
  required bool replaceExisting,
}) async {
  await locator<ImportDataUsecase>().importArchive(
    archive,
    ProfilesBackup.activityFileName,
    ProfilesBackup.intakeFileName,
    ProfilesBackup.trackedDayFileName,
    ProfilesBackup.recipeFileName,
    ProfilesBackup.weightLogFileName,
    ProfilesBackup.templateFileName,
    goalSettingsJsonFileName: ProfilesBackup.goalSettingsFileName,
    replaceExisting: replaceExisting,
  );
  try {
    await locator<SettingsBloc>().updateTrackedDay(DateTime.now());
  } catch (error, stackTrace) {
    Logger('AutoBackupScreen').warning(
      "Could not recompute today's goals after the restore",
      error,
      stackTrace,
    );
  }
  reloadScreensAfterImport();
}

/// Settings → Automatic backup: the WebDAV folder, token and schedule, the
/// state of the last attempt, and the restore from the server.
///
/// Opened [forOnboarding] (#100), a restore always replaces everything and
/// the screen closes with `true` once it succeeded, so onboarding can go
/// straight into the app; going back closes it with null.
class AutoBackupScreen extends StatefulWidget {
  final AutoBackupSettingsStore? store;
  final AutoBackupService? service;
  final RestoreArchive restore;
  final bool forOnboarding;

  const AutoBackupScreen({
    super.key,
    this.store,
    this.service,
    this.restore = _restoreIntoApp,
    this.forOnboarding = false,
  });

  @override
  State<AutoBackupScreen> createState() => _AutoBackupScreenState();
}

class _AutoBackupScreenState extends State<AutoBackupScreen> {
  static const _intervalOptions = [6, 12, 24, 48, 168];
  static const _keepOptions = [7, 14, 30, 60];

  late final AutoBackupSettingsStore _store =
      widget.store ?? locator<AutoBackupSettingsStore>();
  late final AutoBackupService _service =
      widget.service ?? locator<AutoBackupService>();

  final _folder = TextEditingController();
  final _token = TextEditingController();
  final _password = TextEditingController();
  AutoBackupSettings? _settings;
  bool _busy = false;
  String? _folderError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _folder.dispose();
    _token.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _store.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _folder.text = settings.folderUrl;
      _token.text = settings.token;
      _password.text = settings.password ?? '';
    });
  }

  /// The form as settings, or null (with the field error set) when the
  /// address is not https.
  AutoBackupSettings? _fromForm() {
    final folder = _folder.text.trim();
    final uri = Uri.tryParse(folder);
    final valid = uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
    setState(
      () => _folderError = valid || folder.isEmpty
          ? null
          : S.of(context).autoBackupInvalidUrl,
    );
    if (!valid && folder.isNotEmpty) return null;
    final password = _password.text;
    return _settings!.copyWith(
      folderUrl: folder,
      token: _token.text.trim(),
      password: password.isEmpty ? null : password,
      clearPassword: password.isEmpty,
    );
  }

  /// Applies [change] to the stored settings as they are now (an upload may
  /// have written its status meanwhile) and shows the result.
  Future<void> _update(
    AutoBackupSettings Function(AutoBackupSettings fresh) change,
  ) async {
    final updated = change(await _store.load());
    await _store.save(updated);
    if (mounted) setState(() => _settings = updated);
  }

  Future<bool> _save() async {
    final form = _fromForm();
    if (form == null) return false;
    await _update(
      (fresh) => fresh.copyWith(
        folderUrl: form.folderUrl,
        token: form.token,
        password: form.password,
        clearPassword: form.password == null,
      ),
    );
    return true;
  }

  Future<void> _withBusy(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _reason(S l10n, String code) {
    if (code == 'unauthorized') return l10n.autoBackupReasonUnauthorized;
    if (code == 'invalid address') return l10n.autoBackupReasonInvalidAddress;
    if (code.startsWith('server error ')) {
      return l10n.autoBackupServerError(code.substring('server error '.length));
    }
    return l10n.autoBackupReasonUnreachable;
  }

  Future<void> _test() => _withBusy(() async {
    final l10n = S.of(context);
    final settings = _fromForm();
    if (settings == null) return;
    try {
      await _service.testConnection(settings);
      _show(l10n.autoBackupTestSuccess);
    } catch (error) {
      _show(
        l10n.autoBackupTestFailed(
          _reason(l10n, AutoBackupService.describe(error)),
        ),
      );
    }
  });

  Future<void> _backUpNow() => _withBusy(() async {
    if (!await _save()) return;
    await _service.runNow();
    await _load();
  });

  Future<void> _restore() async {
    final l10n = S.of(context);
    List<String>? names;
    await _withBusy(() async {
      if (!await _save()) return;
      try {
        names = await _service.listBackups();
      } catch (error) {
        _show(
          l10n.autoBackupTestFailed(
            _reason(l10n, AutoBackupService.describe(error)),
          ),
        );
      }
    });
    final available = names;
    if (available == null || !mounted) return;
    if (available.isEmpty) {
      _show(l10n.autoBackupRestoreEmpty);
      return;
    }
    final choice = await showDialog<({String name, bool replace})>(
      context: context,
      builder: (_) =>
          _RestorePicker(names: available, replaceOnly: widget.forOnboarding),
    );
    if (choice == null || !mounted) return;
    if (choice.replace && !await _confirmReplace()) return;
    await _withBusy(() async {
      try {
        final archive = await _service.download(choice.name);
        await widget.restore(archive, replaceExisting: choice.replace);
        if (widget.forOnboarding) {
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
        _show(l10n.autoBackupRestoreDone);
      } catch (error, stackTrace) {
        Logger('AutoBackupScreen').warning('Restore failed', error, stackTrace);
        _show(l10n.autoBackupRestoreFailed);
      }
    });
  }

  Future<bool> _confirmReplace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(dialogContext).exportImportReplaceConfirmTitle),
        content: Text(S.of(dialogContext).exportImportReplaceConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(S.of(dialogContext).dialogCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(S.of(dialogContext).exportImportReplaceConfirmAction),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final settings = _settings;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat.yMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_Hm();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.autoBackupTitle)),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.autoBackupLocalFolderNote,
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Semantics(
                  identifier: 'auto-backup-enabled',
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.autoBackupEnabledLabel),
                    value: settings.enabled,
                    onChanged: (value) =>
                        _update((fresh) => fresh.copyWith(enabled: value)),
                  ),
                ),
                Semantics(
                  identifier: 'auto-backup-folder',
                  child: TextField(
                    controller: _folder,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l10n.autoBackupFolderLabel,
                      hintText: 'https://files.example.org/dav/backups/',
                      errorText: _folderError,
                    ),
                  ),
                ),
                Semantics(
                  identifier: 'auto-backup-token',
                  child: TextField(
                    controller: _token,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: l10n.autoBackupTokenLabel,
                    ),
                  ),
                ),
                Semantics(
                  identifier: 'auto-backup-password',
                  child: TextField(
                    controller: _password,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: l10n.autoBackupPasswordLabel,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _OptionRow(
                  identifier: 'auto-backup-interval',
                  label: l10n.autoBackupIntervalLabel,
                  value: settings.intervalHours,
                  options: _intervalOptions,
                  optionLabel: l10n.autoBackupIntervalHours,
                  onChanged: (value) =>
                      _update((fresh) => fresh.copyWith(intervalHours: value)),
                ),
                _OptionRow(
                  identifier: 'auto-backup-keep',
                  label: l10n.autoBackupKeepLabel,
                  value: settings.keepCount,
                  options: _keepOptions,
                  optionLabel: l10n.autoBackupKeepCount,
                  onChanged: (value) =>
                      _update((fresh) => fresh.copyWith(keepCount: value)),
                ),
                const SizedBox(height: 8),
                Text(
                  settings.lastSuccessAt == null
                      ? l10n.autoBackupNeverLabel
                      : l10n.autoBackupLastSuccessLabel(
                          dateFormat.format(settings.lastSuccessAt!),
                        ),
                  style: textTheme.bodyMedium,
                ),
                if (settings.lastError != null && settings.lastErrorAt != null)
                  Text(
                    l10n.autoBackupLastErrorLabel(
                      dateFormat.format(settings.lastErrorAt!),
                      _reason(l10n, settings.lastError!),
                    ),
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 16),
                if (_busy) const LinearProgressIndicator(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Semantics(
                      identifier: 'auto-backup-save',
                      child: FilledButton(
                        onPressed: _busy ? null : () => _withBusy(_save),
                        child: Text(l10n.autoBackupSaveAction),
                      ),
                    ),
                    Semantics(
                      identifier: 'auto-backup-test',
                      child: OutlinedButton(
                        onPressed: _busy ? null : _test,
                        child: Text(l10n.autoBackupTestAction),
                      ),
                    ),
                    Semantics(
                      identifier: 'auto-backup-now',
                      child: OutlinedButton(
                        onPressed: _busy ? null : _backUpNow,
                        child: Text(l10n.autoBackupNowAction),
                      ),
                    ),
                    Semantics(
                      identifier: 'auto-backup-restore',
                      child: OutlinedButton(
                        onPressed: _busy ? null : _restore,
                        child: Text(l10n.autoBackupRestoreAction),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String identifier;
  final String label;
  final int value;
  final List<int> options;
  final String Function(int option) optionLabel;
  final ValueChanged<int> onChanged;

  const _OptionRow({
    required this.identifier,
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Semantics(
          identifier: identifier,
          child: DropdownButton<int>(
            value: options.contains(value) ? value : options.first,
            items: [
              for (final option in options)
                DropdownMenuItem(
                  value: option,
                  child: Text(optionLabel(option)),
                ),
            ],
            onChanged: (option) {
              if (option != null) onChanged(option);
            },
          ),
        ),
      ],
    );
  }
}

/// Lists the server's backups; returns the chosen one and whether to
/// replace everything on the device.
class _RestorePicker extends StatefulWidget {
  final List<String> names;

  /// Hides the choice and always replaces, for the restore from onboarding.
  final bool replaceOnly;

  const _RestorePicker({required this.names, this.replaceOnly = false});

  @override
  State<_RestorePicker> createState() => _RestorePickerState();
}

class _RestorePickerState extends State<_RestorePicker> {
  late String _selected = widget.names.first;
  late bool _replace = widget.replaceOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.autoBackupRestoreAction),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: RadioGroup<String>(
                groupValue: _selected,
                onChanged: (value) {
                  if (value != null) setState(() => _selected = value);
                },
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final name in widget.names)
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: name,
                      ),
                  ],
                ),
              ),
            ),
            if (!widget.replaceOnly)
              Semantics(
                identifier: 'auto-backup-restore-replace',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.exportImportReplaceLabel),
                  value: _replace,
                  onChanged: (value) => setState(() => _replace = value),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.dialogCancelLabel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop((name: _selected, replace: _replace)),
          child: Text(l10n.importAction),
        ),
      ],
    );
  }
}
