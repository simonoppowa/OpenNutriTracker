import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';

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
  String _infoText = "validating...";

  final _log = Logger('DataSourcesDialogState');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeLocalDataSources();
  }

  Future<List<String>> getColumnNames(Database db, String table) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    // result rows have a 'name' column
    return result.map((r) => r['name'] as String).toList();
  }

  Future<bool> validateDatabase(String filePath) async {
    try {
      /// TOOD: for some reason this handles DatabaseException internally and does not 
      /// throw it. Why?
      final Database db = await openDatabase(filePath);


      List<String> cols = await getColumnNames(db, "food");


      if(cols.isEmpty) {
        _log.warning("No columns not found in database");
        return false;
      }

      List<String> requiredCols = ["code", "product_name"];

      for(String col in requiredCols) {
        if(!cols.contains(col)) {
          _log.warning("Required column is missing in db: $col}");
          _log.fine("Available columns: $cols");
          return false;
        }
      }

      _log.fine("Database looks good");

    } on DatabaseException catch (e) {
      _log.warning("File is not a database");
      _log.warning(e.toString());
      return false;
    } catch (e) {
      _log.warning("Error while opening database file");
      _log.warning(e.toString());
      return false;
    }
    
    
   

    return true;
  }

  void _updateSelectedDatabaseFile(String? filePath) async {
    String newText = "";
    if (filePath == null) {
      newText = "No database selected";
      _databaseFile = null;
    } else {
      setState(() {
        _infoText = "validating...";
      });
      bool valid = await validateDatabase(filePath);
      if(valid) {
        newText = filePath;
        _databaseFile = filePath;
      } else {
        newText = "Selected file is not a valid database";
        _databaseFile = null;
      }
    }

    setState(() {
      _infoText = newText;
    });
  }

  void _initializeLocalDataSources() async {
    final useLocalDataBase = await widget.settingsBloc.getUseLocalDatabase();
    final String? localdbFile = await widget.settingsBloc.getUseLocalDatabaseFile();

    setState(() {
      _useLocalDataBase = useLocalDataBase;
      _databaseFile = localdbFile;

      _updateSelectedDatabaseFile(_databaseFile);
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
                  setState(() {
                    _infoText = "loading...";
                  });
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                  );

                  if(result != null) {
                    _updateSelectedDatabaseFile(result.files.single.path);
                  }

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
    widget.settingsBloc.setLocalDatabaseFile(_databaseFile);
    widget.settingsBloc.add(LoadSettingsEvent());

    Navigator.of(context).pop();
  }
}
