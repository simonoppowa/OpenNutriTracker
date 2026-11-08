import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:file_picker/file_picker.dart';
import 'package:android_file_picker/android_file_picker.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/tasks/auto_backup_task.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class AutomaticBackupDialog extends StatefulWidget {
  final SettingsBloc settingsBloc;
  final ProfileBloc profileBloc;
  final DiaryBloc diaryBloc;
  final CalendarDayBloc calendarDayBloc;
  final UserEntity user;

  const AutomaticBackupDialog({
    super.key,
    required this.settingsBloc,
    required this.profileBloc,
    required this.diaryBloc,
    required this.calendarDayBloc,
    required this.user,
  });

  @override
  State<AutomaticBackupDialog> createState() => _AutomaticBackupDialogState();
}

enum MacroSelectionType {
  none,
  carbs,
  protein,
  fat,
}

class _AutomaticBackupDialogState extends State<AutomaticBackupDialog> {
  final log = Logger('_AutomaticBackupDialogState');

  static final dateFormat = DateFormat("MMM d, yyy hh:mm a");

  static const bool _backupsEnabledDefault = false;
  static const String? _backupLocationDefault = null;
  static const BackupIntervalDropDownType _backupIntervalDefault = BackupIntervalDropDownType.weekly;
  static const BackupBehaviorDropDownType _backupBehaviorDefault = BackupBehaviorDropDownType.overwrite;

  bool _backupsEnabled = _backupsEnabledDefault;
  String? _backupLocation = _backupLocationDefault;
  BackupIntervalDropDownType _backupInterval = _backupIntervalDefault;
  BackupBehaviorDropDownType _backupBehavior = _backupBehaviorDefault;

  DateTime? _lastBackupDate;
  DateTime? _nextBackupDate;

  @override
  void initState() {
    super.initState();

    initAutoBackupState();
  }

  void initAutoBackupState() async {
    final bool backupsEnabled = await widget.settingsBloc.getAutoBackupEnabled();
    final String? backupLocation = await widget.settingsBloc.getAutoBackupLocation();
    final BackupIntervalDropDownType backupInterval = getBackupIntervalEnumFromValue(await widget.settingsBloc.getAutoBackupIntervalDays() ?? 0) ?? _backupIntervalDefault;
    final BackupBehaviorDropDownType backupBehavior = (await widget.settingsBloc.getAutoBackupOverwrite()) ? BackupBehaviorDropDownType.overwrite : BackupBehaviorDropDownType.createNew;

    final DateTime? lastBackupDate = await getAutoBackupLastFinishedTime();
    final DateTime? nextBackupDate = null;  // TODO(ejoyce) get from storage

    setState(() {
      _backupsEnabled = backupsEnabled;
      _backupLocation = backupLocation;
      _backupInterval = backupInterval;
      _backupBehavior = backupBehavior;

      _lastBackupDate = lastBackupDate;
      _nextBackupDate = nextBackupDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              S.of(context).automaticBackupLabel,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8), // Add spacing between text and button
          TextButton(
            child: Text(S.of(context).buttonResetLabel),
            onPressed: () {
              setState(() {
                // Reset macros to default values
                _backupsEnabled = _backupsEnabledDefault;
                _backupLocation = _backupLocationDefault;
                _backupInterval = _backupIntervalDefault;
                _backupBehavior = _backupBehaviorDefault;
              });
            },
          ),
        ],
      ),
      content: Wrap(
        children: [
          SwitchListTile(
            title: Text(S.of(context).enableAutomaticBackupLabel),
            value: _backupsEnabled,
            onChanged: (bool value) {
              setState(() {
                _backupsEnabled = value;
              });
            },
          ),
          Visibility(
            visible: _backupsEnabled,
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(S.of(context).backupLocationLabel),
                  subtitle: Text(_backupLocation ?? S.of(context).backupNotSetLabel),
                  onTap: () => _selectBackupLocation(),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: DropdownButtonFormField(
                    initialValue: _backupInterval,
                    decoration: InputDecoration(
                      enabled: true,
                      filled: false,
                      labelText: S.of(context).backupIntervalLabel,
                    ),
                    onChanged: (value) {
                      _backupInterval = value ?? BackupIntervalDropDownType.weekly;
                    },
                    items: [
                      DropdownMenuItem(
                          value: BackupIntervalDropDownType.daily,
                          child: Text(S.of(context).backupIntervalDailyLabel)),
                      DropdownMenuItem(
                          value: BackupIntervalDropDownType.weekly,
                          child: Text(S.of(context).backupIntervalWeeklyLabel)),
                      DropdownMenuItem(
                          value: BackupIntervalDropDownType.monthly,
                          child: Text(S.of(context).backupIntervalMonthlyLabel))
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: DropdownButtonFormField(
                    initialValue: _backupBehavior,
                    decoration: InputDecoration(
                      enabled: true,
                      filled: false,
                      labelText: S.of(context).backupBehaviorLabel,
                    ),
                    onChanged: (value) {
                      _backupBehavior = value ?? _backupBehaviorDefault;
                    },
                    items: [
                      DropdownMenuItem(
                          value: BackupBehaviorDropDownType.overwrite,
                          child: Text(S.of(context).backupBehaviorOverwriteLabel)),
                      DropdownMenuItem(
                          value: BackupBehaviorDropDownType.createNew,
                          child: Text(S.of(context).backupBehaviorCreateNewLabel)),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(S.of(context).backupStatusLabel),
                  subtitle: Wrap(
                    direction: Axis.vertical,
                    children: [
                      Text("${S.of(context).backupStatusLastBackupLabel} ${_lastBackupDate != null ? dateFormat.format(_lastBackupDate!) : S.of(context).backupStatusNeverLabel}"),
                      Text("${S.of(context).backupStatusNextBackupLabel} ${_nextBackupDate != null ? dateFormat.format(_nextBackupDate!) : S.of(context).backupStatusNeverLabel}"),
                    ]
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel)),
        TextButton(
            onPressed: () {
              _saveSettings();
            },
            child: Text(S.of(context).dialogOKLabel))
      ],
    );
  }

  void _selectBackupLocation() async {
    final location = await FilePicker.getDirectoryPath(
      dialogTitle: S.of(context).backupLocationLabel,
      initialDirectory: _backupLocation,
      androidOptions: const FilePickerAndroidOptions(
        safOptions: AndroidSAFOptions(
          grant: AndroidSAFGrant.lifetime,
          accessMode: AndroidSAFAccessMode.readWrite,
          persistGrant: true,
        )
      )
    );
    setState(() {
      _backupLocation = location;
    });
    log.fine("Updated backup location: $location");
  }

  void _saveSettings() {
    final int? backupIntervalDays = getBackupIntervalValueFromEnum(_backupInterval);
    final bool backupOverwrite = _backupBehavior == BackupBehaviorDropDownType.overwrite;
    widget.settingsBloc
        .setAutoBackupConfig(_backupsEnabled, _backupLocation, backupIntervalDays, backupOverwrite);
    widget.settingsBloc.add(LoadSettingsEvent());

    refreshAutoBackupTask();

    Navigator.of(context).pop();
  }
}
