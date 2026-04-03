import 'package:flutter/material.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:file_picker/file_picker.dart';


class DataSourcesDialog extends StatefulWidget {
  final SettingsBloc settingsBloc;

  const DataSourcesDialog({
    super.key,
    required this.settingsBloc,
  });

  @override
  State<DataSourcesDialog> createState() => _DataSourcesDialogState();
}

class _DataSourcesDialogState extends State<DataSourcesDialog> {
  bool _useLocalDataBase = false;
  String? _databaseFile;
  String _infoText = "No database selected";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeKcalAdjustment();
  }

  void _initializeKcalAdjustment() async {
    final useLocalDataBase = await widget.settingsBloc.getUseLocalDatabase();

    setState(() {
      _useLocalDataBase = useLocalDataBase;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Data Sources"),
      content: StatefulBuilder(
        builder: (
          BuildContext context,
          void Function(void Function()) setState,
        ) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text("Use local database"),
                value: _useLocalDataBase,
                onChanged: (bool value) {
                  setState(() {
                    _useLocalDataBase = value;
                  });
                },
              ),
              Text(_infoText),
              TextButton(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                  );
                  String newText = "";
                  if (result == null || result.files.single.path == null) {
                    newText = "Error";
                    /// TODO: handle error
                  } else {
                    newText = "yay";
                    /// TODO: validate, store to settings
                  }

                  setState(() {
                    _infoText = newText;
                  });
                },
                child: Text("Select database"),
              ),
            ]
          );
        }
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          onPressed: () async {
            _saveDataSourcesSettings();
          },
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }

  void _saveDataSourcesSettings() {
    widget.settingsBloc.setUseLocalDatabase(_useLocalDataBase);
    widget.settingsBloc.add(LoadSettingsEvent());

    Navigator.of(context).pop();
  }
}
