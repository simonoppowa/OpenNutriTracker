import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settingsLabel),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16.0),
          ListTile(
            leading: const Icon(Icons.ac_unit_outlined),
            title: Text(S.of(context).settingsUnitsLabel),
            onTap: () => _showUnitsDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(S.of(context).settingsDisclaimerLabel),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(S.of(context).settingsReportErrorLabel),
          ),
          ListTile(
            leading: const Icon(Icons.error_outline_outlined),
            title: Text(S.of(context).settingAboutLabel),
          )
        ],
      ),
    );
  }

  void _showUnitsDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              content: Wrap(children: [
                Column(
                  children: [
                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        enabled: false,
                        filled: false,
                        labelText: S.of(context).settingsMassLabel,
                      ),
                      onChanged: null,
                      items: const [
                        DropdownMenuItem(child: Text('kg, g, mg'))
                      ], // TODO add units
                    ),
                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        enabled: false,
                        filled: false,
                        labelText: S.of(context).settingsDistanceLabel,
                      ),
                      onChanged: null,
                      items: const [DropdownMenuItem(child: Text('cm, m, km'))],
                    ),
                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        enabled: false,
                        filled: false,
                        labelText: S.of(context).settingsVolumeLabel,
                      ),
                      onChanged: null,
                      items: const [DropdownMenuItem(child: Text('ml, l'))],
                    ),
                  ],
                ),
              ]),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(S.of(context).dialogOKLabel))
              ]);
        });
  }
}
