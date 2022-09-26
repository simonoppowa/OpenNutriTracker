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
      body: const Center(child: Text("Settings Screen")),
    );
  }
}
