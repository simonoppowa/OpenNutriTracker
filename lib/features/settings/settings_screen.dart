import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/app_banner_version.dart';
import 'package:opennutritracker/core/presentation/widgets/disclaimer_dialog.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/core/utils/locale_provider.dart';
import 'package:opennutritracker/core/utils/theme_mode_provider.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/export_import_dialog.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/import_custom_food_data_dialog.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/nutrient_visibility_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/diary_day_boundary_dialog.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/kcal_adjustment_dialog.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/macro_split_dialog.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/nutrient_goals_screen.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/per_meal_kcal_share_dialog.dart';

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
    // SettingsBloc is registered as a singleton so the previous
    // SettingsLoadedState survives across screen visits. The cache
    // count and on-disk size in particular are written in the
    // background by search and barcode-scan flows, so reading them
    // once at the bloc's first transition out of SettingsInitial
    // leaves stale values on the screen for the rest of the session.
    // Refresh on every entry instead.
    _settingsBloc.add(LoadSettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settingsLabel)),
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
                Semantics(
                  identifier: 'settings-energy-unit',
                  child: ListTile(
                    leading: const Icon(Icons.local_fire_department_outlined),
                    title: Text(S.of(context).settingsEnergyUnitLabel),
                    subtitle: Text(state.usesKilojoules
                        ? S.of(context).energyUnitKjLabel
                        : S.of(context).energyUnitKcalLabel),
                    onTap: () =>
                        _showEnergyUnitDialog(context, state.usesKilojoules),
                  ),
                ),
                // The old Calculations dialog had grown into a wall of
                // sliders covering daily kcal, macros, per-meal split,
                // ten nutrient goals, and the diary day boundary. Each
                // is now its own focused entry so people can find the
                // setting they want and only see the controls for it.
                Semantics(
                  identifier: 'settings-kcal-adjustment',
                  child: ListTile(
                    leading: const Icon(Icons.calculate_outlined),
                    title: Text(S.of(context).settingsKcalAdjustmentLabel),
                    onTap: () => _showKcalAdjustmentDialog(context),
                  ),
                ),
                Semantics(
                  identifier: 'settings-macro-split',
                  child: ListTile(
                    leading: const Icon(Icons.pie_chart_outline),
                    title: Text(S.of(context).settingsMacroSplitLabel),
                    onTap: () => _showMacroSplitDialog(context),
                  ),
                ),
                Semantics(
                  identifier: 'settings-per-meal-share',
                  child: ListTile(
                    leading: const Icon(Icons.restaurant_menu_outlined),
                    title:
                        Text(S.of(context).settingsPerMealKcalShareLabel),
                    onTap: () => _showPerMealKcalShareDialog(context),
                  ),
                ),
                Semantics(
                  identifier: 'settings-nutrient-goals',
                  child: ListTile(
                    leading: const Icon(Icons.spa_outlined),
                    title: Text(S.of(context).settingsNutrientGoalsLabel),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openNutrientGoalsScreen(context),
                  ),
                ),
                Semantics(
                  identifier: 'settings-day-boundary',
                  child: ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(S.of(context).settingsDayStartLabel),
                    onTap: () => _showDayBoundaryDialog(context),
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.directions_run_outlined),
                  title: Text(S.of(context).settingsShowActivityTracking),
                  value: state.showActivityTracking,
                  onChanged: (bool value) {
                    _settingsBloc.setShowActivityTracking(value);
                    _settingsBloc.add(LoadSettingsEvent());
                    _homeBloc.add(LoadItemsEvent());
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.bar_chart_outlined),
                  title: Text(S.of(context).settingsShowMealMacros),
                  value: state.showMealMacros,
                  onChanged: (bool value) {
                    _settingsBloc.setShowMealMacros(value);
                    _settingsBloc.add(LoadSettingsEvent());
                    _homeBloc.add(LoadItemsEvent());
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.science_outlined),
                  title: Text(S.of(context).settingsShowMicronutrientsLabel),
                  value: state.showMicronutrients,
                  onChanged: (bool value) {
                    _settingsBloc.setShowMicronutrients(value);
                    _settingsBloc.add(LoadSettingsEvent());
                  },
                ),
                // #160 follow-up: lets the user pick which nutrients show on
                // the diary's daily nutrient panel. Lives next to the meal-
                // detail micronutrient toggle above; both shape what the
                // user sees from the same underlying nutrient data.
                Semantics(
                  identifier: 'settings-nutrient-visibility',
                  child: ListTile(
                    leading: const Icon(Icons.tune_outlined),
                    title: Text(S.of(context).settingsNutrientsLabel),
                    subtitle: Text(S.of(context).settingsNutrientsSubtitle),
                    onTap: () => _openNutrientVisibilityScreen(context),
                  ),
                ),
                const Divider(),
                // App
                ListTile(
                  leading: const Icon(Icons.brightness_medium_outlined),
                  title: Text(S.of(context).settingsThemeLabel),
                  onTap: () => _showThemeDialog(context, state.appTheme),
                ),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(S.of(context).settingsLanguageLabel),
                  subtitle: Text(
                      _localeDisplayName(state.selectedLocale) ??
                          S.of(context).settingsThemeSystemDefaultLabel),
                  onTap: () =>
                      _showLanguageDialog(context, state.selectedLocale),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: Text(S.of(context).settingsNotificationsLabel),
                  subtitle: state.notificationsEnabled
                      ? Text(S.of(context).settingsNotificationsTimeLabel(
                          _formatNotificationTime(
                              state.notificationHour, state.notificationMinute)))
                      : null,
                  value: state.notificationsEnabled,
                  onChanged: (bool value) =>
                      _onNotificationToggled(context, value, state),
                ),
                if (state.notificationsEnabled)
                  ListTile(
                    leading: const Icon(Icons.access_time_outlined),
                    title: Text(S.of(context).settingsNotificationsTimeLabel(
                        _formatNotificationTime(state.notificationHour,
                            state.notificationMinute))),
                    onTap: () => _pickNotificationTime(
                        context,
                        TimeOfDay(
                            hour: state.notificationHour,
                            minute: state.notificationMinute)),
                  ),
                const Divider(),
                // Data
                Semantics(
                  identifier: 'settings-import-custom-food',
                  child: ListTile(
                    leading: const Icon(Icons.restaurant_menu_outlined),
                    title: Text(S.of(context).importCustomFoodDataLabel),
                    onTap: () => _showImportCustomFoodDataDialog(context),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.import_export),
                  title: Text(S.of(context).exportImportAppDataLabel),
                  onTap: () => _showExportImportDialog(context),
                ),
                ListTile(
                  leading: const Icon(Icons.cached_outlined),
                  title: Text(S.of(context).clearOffCacheLabel),
                  subtitle: Text(S.of(context).clearOffCacheSubtitle(
                    state.offCacheCount,
                    _formatBytes(state.offCacheSizeBytes),
                  )),
                  enabled: state.offCacheCount > 0,
                  onTap: () => _confirmClearOffCache(context),
                ),
                const Divider(),
                // About
                ListTile(
                  leading: const Icon(Icons.policy_outlined),
                  title: Text(S.of(context).settingsPrivacySettings),
                  onTap: () =>
                      _showPrivacyDialog(context, state.sendAnonymousData),
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
                AppBannerVersion(versionNumber: state.versionNumber),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  String _formatNotificationTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _onNotificationToggled(
      BuildContext context, bool enabled, SettingsLoadedState state) async {
    final l10n = S.of(context);
    final notificationService = locator<NotificationService>();
    await notificationService.initialize();
    if (enabled) {
      final granted = await notificationService.requestPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.notificationsPermissionDeniedSnack)),
          );
        }
        return;
      }
      await notificationService.scheduleDailyReminder(
        hour: state.notificationHour,
        minute: state.notificationMinute,
        title: l10n.notificationsDailyReminderTitle,
        body: l10n.notificationsDailyReminderBody,
      );
    } else {
      await notificationService.cancelDailyReminder();
    }
    _settingsBloc.setNotificationsEnabled(enabled);
    _settingsBloc.add(LoadSettingsEvent());
  }

  Future<void> _pickNotificationTime(
      BuildContext context, TimeOfDay current) async {
    final l10n = S.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked == null) return;
    _settingsBloc.setNotificationTime(picked.hour, picked.minute);
    final notificationService = locator<NotificationService>();
    await notificationService.scheduleDailyReminder(
      hour: picked.hour,
      minute: picked.minute,
      title: l10n.notificationsDailyReminderTitle,
      body: l10n.notificationsDailyReminderBody,
    );
    _settingsBloc.add(LoadSettingsEvent());
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
          content: Wrap(
            children: [
              Column(
                children: [
                  DropdownButtonFormField(
                    initialValue: selectedUnit,
                    key: ValueKey(selectedUnit),
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
                        child: Text(S.of(context).settingsMetricLabel),
                      ),
                      DropdownMenuItem(
                        value: SystemDropDownType.imperial,
                        child: Text(S.of(context).settingsImperialLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(S.of(context).dialogOKLabel),
            ),
          ],
        );
      },
    );
    if (shouldUpdate == true) {
      _settingsBloc.setUsesImperialUnits(
        selectedUnit == SystemDropDownType.imperial,
      );
      _settingsBloc.add(LoadSettingsEvent());

      // Update blocs
      _profileBloc.add(LoadProfileEvent());
      _homeBloc.add(LoadItemsEvent());
      _diaryBloc.add(const LoadDiaryYearEvent());
    }
  }

  // #177: Pick between kilocalories (default) and kilojoules for the
  // energy display unit. Internal storage stays in kcal; this only
  // toggles how energy is rendered everywhere it appears.
  void _showEnergyUnitDialog(
      BuildContext context, bool currentUsesKilojoules) async {
    bool selectedUsesKilojoules = currentUsesKilojoules;
    final shouldUpdate = await showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          title: Text(S.of(context).settingsEnergyUnitLabel),
          content: StatefulBuilder(
            builder: (BuildContext context,
                void Function(void Function()) setState) {
              return RadioGroup<bool>(
                groupValue: selectedUsesKilojoules,
                onChanged: (value) {
                  setState(() {
                    selectedUsesKilojoules = value ?? false;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<bool>(
                      title: Text(S.of(context).energyUnitKcalLabel),
                      value: false,
                    ),
                    RadioListTile<bool>(
                      title: Text(S.of(context).energyUnitKjLabel),
                      value: true,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).dialogCancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).dialogOKLabel),
            ),
          ],
        );
      },
    );
    if (shouldUpdate == true) {
      _settingsBloc.setUsesKilojoules(selectedUsesKilojoules);
      _settingsBloc.add(LoadSettingsEvent());
      if (context.mounted) {
        Provider.of<EnergyUnitProvider>(context, listen: false)
            .updateUsesKilojoules(selectedUsesKilojoules);
      }
    }
  }

  void _showKcalAdjustmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => KcalAdjustmentDialog(
        settingsBloc: _settingsBloc,
        profileBloc: _profileBloc,
        homeBloc: _homeBloc,
      ),
    );
  }

  void _showMacroSplitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MacroSplitDialog(
        settingsBloc: _settingsBloc,
        homeBloc: _homeBloc,
      ),
    );
  }

  void _showPerMealKcalShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PerMealKcalShareDialog(
        settingsBloc: _settingsBloc,
        homeBloc: _homeBloc,
        calendarDayBloc: _calendarDayBloc,
      ),
    );
  }

  void _openNutrientGoalsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NutrientGoalsScreen(
          settingsBloc: _settingsBloc,
          profileBloc: _profileBloc,
          diaryBloc: _diaryBloc,
          calendarDayBloc: _calendarDayBloc,
          homeBloc: _homeBloc,
        ),
      ),
    );
  }

  void _showDayBoundaryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DiaryDayBoundaryDialog(
        settingsBloc: _settingsBloc,
        homeBloc: _homeBloc,
        calendarDayBloc: _calendarDayBloc,
      ),
    );
  }

  void _showExportImportDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => ExportImportDialog());
  }

  void _showImportCustomFoodDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ImportCustomFoodDataDialog(),
    );
  }

  void _openNutrientVisibilityScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NutrientVisibilityScreen(),
      ),
    );
  }

  Future<void> _confirmClearOffCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).clearOffCacheConfirmTitle),
        content: Text(S.of(context).clearOffCacheConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.of(context).dialogCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(S.of(context).dialogOKLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _settingsBloc.clearOffCache();
    }
  }

  /// Format a byte count for display in the cache-clear tile subtitle.
  /// Uses KB up to 1 MB, then MB with one decimal place above that.
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
            builder: (
              BuildContext context,
              void Function(void Function()) setState,
            ) {
              return RadioGroup(
                groupValue: selectedTheme,
                onChanged: (value) {
                  setState(() {
                    selectedTheme = value as AppThemeEntity;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile(
                      title: Text(S.of(context).settingsThemeSystemDefaultLabel),
                      value: AppThemeEntity.system,
                    ),
                    RadioListTile(
                      title: Text(S.of(context).settingsThemeLightLabel),
                      value: AppThemeEntity.light,
                    ),
                    RadioListTile(
                      title: Text(S.of(context).settingsThemeDarkLabel),
                      value: AppThemeEntity.dark,
                    ),
                  ],
                ),
              );
            },
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
                _settingsBloc.setAppTheme(selectedTheme);
                _settingsBloc.add(LoadSettingsEvent());
                setState(() {
                  // Update Theme
                  Provider.of<ThemeModeProvider>(
                    context,
                    listen: false,
                  ).updateTheme(selectedTheme);
                });
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).dialogOKLabel),
            ),
          ],
        );
      },
    );
  }

  static const _supportedLocales = <String, String>{
    'en': 'English',
    'de': 'Deutsch',
    'tr': 'Türkçe',
    'cs': 'Čeština',
    'it': 'Italiano',
    'uk': 'Українська',
    'zh': '中文',
    'pl': 'Polski',
    'sk': 'Slovenčina',
  };

  String? _localeDisplayName(String? code) => _supportedLocales[code];

  // Sentinel value meaning "follow system locale"
  static const _systemLocale = '';

  void _showLanguageDialog(BuildContext context, String? currentLocale) {
    String selectedCode = currentLocale ?? _systemLocale;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          title: Text(S.of(context).settingsLanguageLabel),
          content: StatefulBuilder(
            builder: (BuildContext context,
                void Function(void Function()) setState) {
              return RadioGroup<String>(
                groupValue: selectedCode,
                onChanged: (v) => setState(() => selectedCode = v as String),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title:
                          Text(S.of(context).settingsThemeSystemDefaultLabel),
                      value: _systemLocale,
                    ),
                    ..._supportedLocales.entries.map(
                      (e) => RadioListTile<String>(
                        title: Text(e.value),
                        value: e.key,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).dialogCancelLabel),
            ),
            TextButton(
              onPressed: () {
                final locale =
                    selectedCode.isEmpty ? null : selectedCode;
                _settingsBloc.setSelectedLocale(locale);
                _settingsBloc.add(LoadSettingsEvent());
                Provider.of<LocaleProvider>(context, listen: false)
                    .updateLocale(
                  locale != null ? Locale(locale) : null,
                );
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).dialogOKLabel),
            ),
          ],
        );
      },
    );
  }

  void _showDisclaimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const DisclaimerDialog();
      },
    );
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
              child: Text(S.of(context).dialogCancelLabel),
            ),
            TextButton(
              onPressed: () async {
                _reportError(context);
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).dialogOKLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _reportError(BuildContext context) async {
    final reportUri = Uri.parse(
      "mailto:${AppConst.reportErrorEmail}?subject=Report_Error",
    );

    if (await canLaunchUrl(reportUri)) {
      launchUrl(reportUri);
    } else {
      // Cannot open email app, show error snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorOpeningEmail)),
        );
      }
    }
  }

  void _showPrivacyDialog(
    BuildContext context,
    bool hasAcceptedAnonymousData,
  ) async {
    bool switchActive = hasAcceptedAnonymousData;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).settingsPrivacySettings),
          content: StatefulBuilder(
            builder: (
              BuildContext context,
              void Function(void Function()) setState,
            ) {
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
              child: Text(S.of(context).dialogCancelLabel),
            ),
            TextButton(
              onPressed: () async {
                _settingsBloc.setHasAcceptedAnonymousData(switchActive);
                if (!switchActive) Sentry.close();
                _settingsBloc.add(LoadSettingsEvent());
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).dialogOKLabel),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (context.mounted) {
      showAboutDialog(
        context: context,
        applicationName: S.of(context).appTitle,
        applicationIcon: SizedBox(
          width: 40,
          child: Image.asset('assets/icon/ont_logo_square.png'),
        ),
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
            ),
          ),
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
            ),
          ),
        ],
      );
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
          SnackBar(content: Text(S.of(context).errorOpeningBrowser)),
        );
      }
    }
  }
}
