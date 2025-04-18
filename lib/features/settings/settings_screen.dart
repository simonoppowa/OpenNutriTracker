import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_banner_version.dart';
import 'package:opennutritracker/core/presentation/widgets/disclaimer_dialog.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/theme_mode_provider.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/export_import_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/calculations_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsBloc _settingsBloc;
  late ProfileBloc _profileBloc;
  late HomeBloc _homeBloc;
  late DiaryBloc _diaryBloc;
  late CalendarDayBloc _calendarDayBloc;

  @override
  void initState() {
    _settingsBloc = locator<SettingsBloc>();
    _profileBloc = locator<ProfileBloc>();
    _homeBloc = locator<HomeBloc>();
    _diaryBloc = locator<DiaryBloc>();
    _calendarDayBloc = locator<CalendarDayBloc>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settingsLabel),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        bloc: _settingsBloc,
        builder: (context, state) {
          if (state is SettingsInitial) {
            _settingsBloc.add(LoadSettingsEvent());
          } else if (state is SettingsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SettingsLoadedState) {
            return ListView(
              children: [
                const SizedBox(height: 16.0),
                ListTile(
                  leading: const Icon(Icons.ac_unit_outlined),
                  title: Text(S.of(context).settingsUnitsLabel),
                  onTap: () =>
                      _showUnitsDialog(context, state.usesImperialUnits),
                ),
                ListTile(
                  leading: const Icon(Icons.calculate_outlined),
                  title: Text(S.of(context).settingsCalculationsLabel),
                  onTap: () => _showCalculationsDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_medium_outlined),
                  title: Text(S.of(context).settingsThemeLabel),
                  onTap: () => _showThemeDialog(context, state.appTheme),
                ),
                ListTile(
                  leading: const Icon(Icons.import_export),
                  title: Text(S.of(context).exportImportLabel),
                  onTap: () => _showExportImportDialog(context),
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
                  leading: const Icon(Icons.policy_outlined),
                  title: Text(S.of(context).settingsPrivacySettings),
                  onTap: () =>
                      _showPrivacyDialog(context, state.sendAnonymousData),
                ),
                ListTile(
                  leading: const Icon(Icons.error_outline_outlined),
                  title: Text(S.of(context).settingAboutLabel),
                  onTap: () => _showAboutDialog(context),
                ),
                const SizedBox(height: 32.0),
                AppBannerVersion(versionNumber: state.versionNumber)
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _showUnitsDialog(BuildContext context, bool usesImperialUnits) async {
    SystemDropDownType selectedUnit = usesImperialUnits
        ? SystemDropDownType.imperial
        : SystemDropDownType.metric;
    final shouldUpdate = await showDialog<bool?>(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(S.of(context).settingsUnitsLabel),
              content: Wrap(children: [
                Column(
                  children: [
                    DropdownButtonFormField(
                      value: selectedUnit,
                      decoration: InputDecoration(
                        enabled: true,
                        filled: false,
                        labelText: S.of(context).settingsSystemLabel,
                      ),
                      onChanged: (value) {
                        selectedUnit = value ?? SystemDropDownType.metric;
                      },
                      items: [
                        DropdownMenuItem(
                            value: SystemDropDownType.metric,
                            child: Text(S.of(context).settingsMetricLabel)),
                        DropdownMenuItem(
                            value: SystemDropDownType.imperial,
                            child: Text(S.of(context).settingsImperialLabel))
                      ],
                    )
                  ],
                ),
              ]),
              actions: <Widget>[
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: Text(S.of(context).dialogOKLabel))
              ]);
        });
    if (shouldUpdate == true) {
      _settingsBloc
          .setUsesImperialUnits(selectedUnit == SystemDropDownType.imperial);
      _settingsBloc.add(LoadSettingsEvent());

      // Update blocs
      _profileBloc.add(LoadProfileEvent());
      _homeBloc.add(LoadItemsEvent());
      _diaryBloc.add(const LoadDiaryYearEvent());
    }
  }

  void _showCalculationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CalculationsDialog(
        settingsBloc: _settingsBloc,
        profileBloc: _profileBloc,
        homeBloc: _homeBloc,
        diaryBloc: _diaryBloc,
        calendarDayBloc: _calendarDayBloc,
      ),
    );
  }

  void _showExportImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ExportImportDialog(),
    );
  }

  void _showThemeDialog(BuildContext context, AppThemeEntity currentAppTheme) {
    AppThemeEntity selectedTheme = currentAppTheme;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            title: Text(S.of(context).settingsThemeLabel),
            content: StatefulBuilder(
              builder: (BuildContext context,
                  void Function(void Function()) setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile(
                      title:
                          Text(S.of(context).settingsThemeSystemDefaultLabel),
                      value: AppThemeEntity.system,
                      groupValue: selectedTheme,
                      onChanged: (value) {
                        setState(() {
                          selectedTheme = value as AppThemeEntity;
                        });
                      },
                    ),
                    RadioListTile(
                      title: Text(S.of(context).settingsThemeLightLabel),
                      value: AppThemeEntity.light,
                      groupValue: selectedTheme,
                      onChanged: (value) {
                        setState(() {
                          selectedTheme = value as AppThemeEntity;
                        });
                      },
                    ),
                    RadioListTile(
                      title: Text(S.of(context).settingsThemeDarkLabel),
                      value: AppThemeEntity.dark,
                      groupValue: selectedTheme,
                      onChanged: (value) {
                        setState(() {
                          selectedTheme = value as AppThemeEntity;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).dialogCancelLabel)),
              TextButton(
                  onPressed: () async {
                    _settingsBloc.setAppTheme(selectedTheme);
                    _settingsBloc.add(LoadSettingsEvent());
                    setState(() {
                      // Update Theme
                      Provider.of<ThemeModeProvider>(context, listen: false)
                          .updateTheme(selectedTheme);
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).dialogOKLabel)),
            ],
          );
        });
  }

  void _showDisclaimerDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return const DisclaimerDialog();
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).errorOpeningEmail)));
      }
    }
  }

  void _showPrivacyDialog(
      BuildContext context, bool hasAcceptedAnonymousData) async {
    bool switchActive = hasAcceptedAnonymousData;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(S.of(context).settingsPrivacySettings),
            content: StatefulBuilder(
              builder: (BuildContext context,
                  void Function(void Function()) setState) {
                return SwitchListTile(
                  title: Text(S.of(context).sendAnonymousUserData),
                  value: switchActive,
                  onChanged: (bool value) {
                    setState(() {
                      switchActive = value;
                    });
                  },
                );
              },
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).dialogCancelLabel)),
              TextButton(
                  onPressed: () async {
                    _settingsBloc.setHasAcceptedAnonymousData(switchActive);
                    if (!switchActive) Sentry.close();
                    _settingsBloc.add(LoadSettingsEvent());
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).dialogOKLabel))
            ],
          );
        });
  }

  void _showAboutDialog(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (context.mounted) {
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
                )),
            TextButton(
                onPressed: () {
                  _launchPrivacyPolicyUrl(context);
                },
                child: Row(
                  children: [
                    const Icon(Icons.policy_outlined),
                    const SizedBox(width: 8.0),
                    Text(S.of(context).privacyPolicyLabel),
                  ],
                ))
          ]);
    }
  }

  void _launchSourceCodeUrl(BuildContext context) async {
    final sourceCodeUri = Uri.parse(AppConst.sourceCodeUrl);
    _launchUrl(context, sourceCodeUri);
  }

  void _launchPrivacyPolicyUrl(BuildContext context) async {
    final sourceCodeUri = Uri.parse(URLConst.privacyPolicyURLEn);
    _launchUrl(context, sourceCodeUri);
  }

  void _launchUrl(BuildContext context, Uri url) async {
    if (await canLaunchUrl(url)) {
      launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Cannot open browser app, show error snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).errorOpeningBrowser)));
      }
    }
  }
}
