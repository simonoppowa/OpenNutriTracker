import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/app_banner_version.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
            leading: const Icon(Icons.calculate_outlined),
            title: Text(S.of(context).settingsCalculationsLabel),
            onTap: () => _showCalculationsDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(S.of(context).settingsDisclaimerLabel),
            onTap: () => _showDisclaimerDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(S.of(context).settingsReportErrorLabel),
            onTap: () => _showReportErrorDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.error_outline_outlined),
            title: Text(S.of(context).settingAboutLabel),
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 32.0),
          const AppBannerVersion()
        ],
      ),
    );
  }

  void _showUnitsDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(S.of(context).settingsUnitsLabel),
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

  void _showCalculationsDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(S.of(context).settingsCalculationsLabel),
              content: Wrap(
                children: [
                  DropdownButtonFormField(
                      decoration: InputDecoration(
                        enabled: false,
                        filled: false,
                        labelText: S.of(context).calculationsTDEELabel,
                      ),
                      items: [
                        DropdownMenuItem(
                            child: Text(
                                '${S.of(context).calculationsTDEEIOM2006Label} ${S.of(context).calculationsRecommendedLabel}')),
                      ],
                      onChanged: null),
                  DropdownButtonFormField(
                    isExpanded: true,
                      decoration: InputDecoration(
                          enabled: false,
                          filled: false,
                          labelText: S
                              .of(context)
                              .calculationsMacronutrientsDistributionLabel),
                      items: [
                        DropdownMenuItem(
                            child: Text(
                          S
                              .of(context)
                              .calculationsMacrosDistribution("50", "20", "20"), // TODO
                          overflow: TextOverflow.ellipsis,
                        ))
                      ],
                      onChanged: null)
                ],
              ),
            ));
  }

  void _showDisclaimerDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(S.of(context).settingsDisclaimerLabel),
            content: Text(S.of(context).disclaimerText),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).dialogOKLabel))
            ],
          );
        });
  }

  void _showReportErrorDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(S.of(context).settingsReportErrorLabel),
            content: Text(S.of(context).reportErrorDialogText),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).dialogCancelLabel)),
              TextButton(
                  onPressed: () async {
                    _reportError(context);
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).dialogOKLabel))
            ],
          );
        });
  }

  Future<void> _reportError(BuildContext context) async {
    final reportUri =
        Uri.parse("mailto:${AppConst.reportErrorEmail}?subject=Report_Error");

    if (await canLaunchUrl(reportUri)) {
      launchUrl(reportUri);
    } else {
      // Cannot open email app, show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorOpeningEmail)));
    }
  }

  void _showAboutDialog(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    showAboutDialog(
        context: context,
        applicationName: S.of(context).appTitle,
        applicationIcon: SizedBox(
            width: 40, child: Image.asset('assets/icon/ont_logo_square.png')),
        applicationVersion: packageInfo.version,
        applicationLegalese: S.of(context).appLicenseLabel,
        children: [
          TextButton(
              onPressed: () {
                _launchSourceCodeUrl(context);
              },
              child: Row(
                children: [
                  const Icon(Icons.code_outlined),
                  const SizedBox(width: 8.0),
                  Text(S.of(context).settingsSourceCodeLabel),
                ],
              ))
        ]);
  }

  void _launchSourceCodeUrl(BuildContext context) async {
    final sourceCodeUri = Uri.parse(AppConst.sourceCodeUrl);
    if (await canLaunchUrl(sourceCodeUri)) {
      launchUrl(sourceCodeUri, mode: LaunchMode.externalApplication);
    } else {
      // Cannot open browser app, show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorOpeningBrowser)));
    }
  }

  Future<String> _getVersionNumber(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
