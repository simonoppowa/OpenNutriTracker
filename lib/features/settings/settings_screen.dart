import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/app_banner_version.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/presentation/widgets/disclaimer_dialog.dart';
import 'package:opennutritracker/core/domain/usecase/delete_all_user_data_usecase.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
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
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/export_import_dialog.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/import_custom_food_data_dialog.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/food_sources_screen.dart';
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
  /// When true, renders the settings list inline (no Scaffold/AppBar, the list
  /// shrink-wraps) so it can be hosted inside the You tab's scroll. The pushed
  /// route uses the default (full-screen) form.
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsBloc _settingsBloc;
  late ProfileBloc _profileBloc;
  late HomeBloc _homeBloc;
  late DiaryBloc _diaryBloc;
  late CalendarDayBloc _calendarDayBloc;
  late TrendsBloc _trendsBloc;

  @override
  void initState() {
    _settingsBloc = locator<SettingsBloc>();
    _profileBloc = locator<ProfileBloc>();
    _homeBloc = locator<HomeBloc>();
    _diaryBloc = locator<DiaryBloc>();
    _calendarDayBloc = locator<CalendarDayBloc>();
    _trendsBloc = locator<TrendsBloc>();
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
    final Widget body = BlocBuilder<SettingsBloc, SettingsState>(
        bloc: _settingsBloc,
        builder: (context, state) {
          if (state is SettingsInitial) {
            _settingsBloc.add(LoadSettingsEvent());
          } else if (state is SettingsLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SettingsLoadedState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final palette = isDark ? AppPalette.dark : AppPalette.light;
            final error = Theme.of(context).colorScheme.error;
            return ListView(
              shrinkWrap: widget.embedded,
              physics:
                  widget.embedded ? const NeverScrollableScrollPhysics() : null,
              padding: widget.embedded
                  ? EdgeInsets.zero
                  : const EdgeInsets.fromLTRB(
                      Dimens.spacing16,
                      Dimens.spacing16,
                      Dimens.spacing16,
                      Dimens.spacing32,
                    ),
              children: [
                _categoryHeader(
                    context, palette, S.of(context).settingsCategoryUnits),
                _SettingsGroup(
                  palette: palette,
                  tiles: [
                    _SettingsTile(
                      identifier: 'settings-food-units',
                      palette: palette,
                      icon: Icons.kitchen_rounded,
                      title: S.of(context).settingsFoodUnitsLabel,
                      subtitle: state.usesImperialFoodUnits
                          ? S.of(context).settingsFoodUnitsImperial
                          : S.of(context).settingsFoodUnitsMetric,
                      onTap: () => _showFoodUnitsDialog(
                          context, state.usesImperialFoodUnits),
                    ),
                    _SettingsTile(
                      identifier: 'settings-height-units',
                      palette: palette,
                      icon: Icons.height_rounded,
                      title: S.of(context).settingsHeightUnitsLabel,
                      subtitle: state.usesImperialHeightUnits
                          ? S.of(context).settingsHeightUnitsImperial
                          : S.of(context).settingsHeightUnitsMetric,
                      onTap: () => _showHeightUnitsDialog(
                          context, state.usesImperialHeightUnits),
                    ),
                    _SettingsTile(
                      identifier: 'settings-body-weight-unit',
                      palette: palette,
                      icon: Icons.monitor_weight_rounded,
                      title: S.of(context).settingsBodyWeightUnitLabel,
                      subtitle: state.bodyWeightUnit.getLabel(context),
                      onTap: () =>
                          _showBodyWeightUnitDialog(context, state.bodyWeightUnit),
                    ),
                    _SettingsTile(
                      identifier: 'settings-energy-unit',
                      palette: palette,
                      icon: Icons.local_fire_department_rounded,
                      title: S.of(context).settingsEnergyUnitLabel,
                      subtitle: state.usesKilojoules
                          ? S.of(context).energyUnitKjLabel
                          : S.of(context).energyUnitKcalLabel,
                      onTap: () =>
                          _showEnergyUnitDialog(context, state.usesKilojoules),
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.spacing20),
                _categoryHeader(
                    context, palette, S.of(context).settingsCategoryGoals),
                _SettingsGroup(
                  palette: palette,
                  tiles: [
                    // The old Calculations dialog had grown into a wall of
                    // sliders covering daily kcal, macros, per-meal split,
                    // ten nutrient goals, and the diary day boundary. Each
                    // is now its own focused entry so people can find the
                    // setting they want and only see the controls for it.
                    _SettingsTile(
                      identifier: 'settings-kcal-adjustment',
                      palette: palette,
                      icon: Icons.calculate_rounded,
                      title: S.of(context).settingsKcalAdjustmentLabel,
                      onTap: () => _showKcalAdjustmentDialog(context),
                    ),
                    _SettingsTile(
                      identifier: 'settings-macro-split',
                      palette: palette,
                      icon: Icons.pie_chart_rounded,
                      title: S.of(context).settingsMacroSplitLabel,
                      onTap: () => _showMacroSplitDialog(context),
                    ),
                    _SettingsTile(
                      identifier: 'settings-per-meal-share',
                      palette: palette,
                      icon: Icons.restaurant_menu_rounded,
                      title: S.of(context).settingsPerMealKcalShareLabel,
                      onTap: () => _showPerMealKcalShareDialog(context),
                    ),
                    _SettingsTile(
                      identifier: 'settings-nutrient-goals',
                      palette: palette,
                      icon: Icons.spa_rounded,
                      title: S.of(context).settingsNutrientGoalsLabel,
                      showChevron: true,
                      onTap: () => _openNutrientGoalsScreen(context),
                    ),
                    _SettingsTile(
                      identifier: 'settings-day-boundary',
                      palette: palette,
                      icon: Icons.schedule_rounded,
                      title: S.of(context).settingsDayStartLabel,
                      onTap: () => _showDayBoundaryDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.spacing20),
                _categoryHeader(
                    context, palette, S.of(context).settingsCategoryDisplay),
                _SettingsGroup(
                  palette: palette,
                  tiles: [
                    _SettingsSwitchTile(
                      palette: palette,
                      icon: Icons.directions_run_rounded,
                      title: S.of(context).settingsShowActivityTracking,
                      value: state.showActivityTracking,
                      onChanged: (bool value) {
                        _settingsBloc.setShowActivityTracking(value);
                        _settingsBloc.add(LoadSettingsEvent());
                        _homeBloc.add(LoadItemsEvent());
                        // DiaryBloc is a lazy singleton so its loaded state
                        // survives navigation. Without an explicit reload here
                        // the diary keeps the stale flag and the per-day
                        // Activity section stays visible after toggling off.
                        _diaryBloc.add(const LoadDiaryYearEvent());
                      },
                    ),
                    _SettingsSwitchTile(
                      palette: palette,
                      icon: Icons.bar_chart_rounded,
                      title: S.of(context).settingsShowMealMacros,
                      value: state.showMealMacros,
                      onChanged: (bool value) {
                        _settingsBloc.setShowMealMacros(value);
                        _settingsBloc.add(LoadSettingsEvent());
                        _homeBloc.add(LoadItemsEvent());
                      },
                    ),
                    _SettingsSwitchTile(
                      palette: palette,
                      icon: Icons.science_rounded,
                      title: S.of(context).settingsShowMicronutrientsLabel,
                      value: state.showMicronutrients,
                      onChanged: (bool value) {
                        _settingsBloc.setShowMicronutrients(value);
                        _settingsBloc.add(LoadSettingsEvent());
                      },
                    ),
                    // #160 follow-up: lets the user pick which nutrients show
                    // on the diary's daily nutrient panel. Lives next to the
                    // meal-detail micronutrient toggle above; both shape what
                    // the user sees from the same underlying nutrient data.
                    _SettingsTile(
                      identifier: 'settings-nutrient-visibility',
                      palette: palette,
                      icon: Icons.tune_rounded,
                      title: S.of(context).settingsNutrientsLabel,
                      subtitle: S.of(context).settingsNutrientsSubtitle,
                      onTap: () => _openNutrientVisibilityScreen(context),
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.spacing20),
                _categoryHeader(
                    context, palette, S.of(context).settingsCategoryAppearance),
                _SettingsGroup(
                  palette: palette,
                  tiles: [
                    _SettingsTile(
                      palette: palette,
                      icon: Icons.brightness_medium_rounded,
                      title: S.of(context).settingsThemeLabel,
                      onTap: () => _showThemeDialog(context, state.appTheme),
                    ),
                    _SettingsTile(
                      identifier: 'settings-accent-colour',
                      palette: palette,
                      icon: Icons.palette_rounded,
                      title: S.of(context).settingsAccentColourTitle,
                      subtitle: _accentSubtitle(
                        context,
                        useMaterialYou: state.useMaterialYou,
                        accentColor: state.accentColor,
                      ),
                      trailing: _AccentTrailingSwatch(
                        useMaterialYou: state.useMaterialYou,
                        accentColor: state.accentColor,
                      ),
                      onTap: () => Navigator.of(context).pushNamed(
                        NavigationOptions.accentColourRoute,
                      ),
                    ),
                    _SettingsTile(
                      palette: palette,
                      icon: Icons.language_rounded,
                      title: S.of(context).settingsLanguageLabel,
                      subtitle: _localeDisplayName(state.selectedLocale) ??
                          S.of(context).settingsThemeSystemDefaultLabel,
                      onTap: () =>
                          _showLanguageDialog(context, state.selectedLocale),
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.spacing20),
                _categoryHeader(context, palette,
                    S.of(context).settingsNotificationsLabel),
                _SettingsGroup(
                  palette: palette,
                  tiles: [
                    _SettingsSwitchTile(
                      palette: palette,
                      icon: Icons.notifications_rounded,
                      title: S.of(context).settingsNotificationsLabel,
                      subtitle: state.notificationsEnabled
                          ? S.of(context).settingsNotificationsTimeLabel(
                              _formatNotificationTime(
                                state.notificationHour,
                                state.notificationMinute,
                              ),
                            )
                          : null,
                      value: state.notificationsEnabled,
                      onChanged: (bool value) =>
                          _onNotificationToggled(context, value, state),
                    ),
                    if (state.notificationsEnabled)
                      _SettingsTile(
                        palette: palette,
                        icon: Icons.access_time_rounded,
                        title: S.of(context).settingsNotificationsTimeLabel(
                          _formatNotificationTime(
                            state.notificationHour,
                            state.notificationMinute,
                          ),
                        ),
                        onTap: () => _pickNotificationTime(
                          context,
                          TimeOfDay(
                            hour: state.notificationHour,
                            minute: state.notificationMinute,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Dimens.spacing20),
                _categoryHeader(
                    context, palette, S.of(context).settingsCategoryData),
                _SettingsGroup(
                  palette: palette,
                  tiles: [
                    _SettingsTile(
                      identifier: 'settings-food-sources',
                      palette: palette,
                      icon: Icons.travel_explore_rounded,
                      title: S.of(context).settingsFoodSourcesLabel,
                      subtitle: S.of(context).settingsFoodSourcesSubtitle,
                      onTap: () => _openFoodSourcesScreen(context),
                    ),
                    _SettingsTile(
                      identifier: 'settings-import-custom-food',
                      palette: palette,
                      icon: Icons.restaurant_menu_rounded,
                      title: S.of(context).importCustomFoodDataLabel,
                      onTap: () => _showImportCustomFoodDataDialog(context),
                    ),
                    _SettingsTile(
                      palette: palette,
                      icon: Icons.import_export_rounded,
                      title: S.of(context).exportImportAppDataLabel,
                      onTap: () => _showExportImportDialog(context),
                    ),
                    _SettingsTile(
                      palette: palette,
                      icon: Icons.cached_rounded,
                      title: S.of(context).clearOffCacheLabel,
                      subtitle: S.of(context).clearOffCacheSubtitle(
                        state.offCacheCount,
                        _formatBytes(state.offCacheSizeBytes),
                      ),
                      enabled: state.offCacheCount > 0,
                      onTap: () => _confirmClearOffCache(context),
                    ),
                    _SettingsTile(
                      identifier: 'settings-delete-all-data',
                      palette: palette,
                      icon: Icons.delete_forever_rounded,
                      iconColor: error,
                      titleColor: error,
                      title: S.of(context).settingsDeleteAllDataLabel,
                      subtitle: S.of(context).settingsDeleteAllDataSubtitle,
                      onTap: () => _confirmDeleteAllData(context),
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.spacing20),
                _categoryHeader(
                    context, palette, S.of(context).settingsCategoryAbout),
                _SettingsGroup(
                  palette: palette,
                  tiles: [
                    _SettingsTile(
                      palette: palette,
                      icon: Icons.policy_rounded,
                      title: S.of(context).settingsPrivacySettings,
                      onTap: () =>
                          _showPrivacyDialog(context, state.sendAnonymousData),
                    ),
                    _SettingsTile(
                      palette: palette,
                      icon: Icons.description_rounded,
                      title: S.of(context).settingsDisclaimerLabel,
                      onTap: () => _showDisclaimerDialog(context),
                    ),
                    _SettingsTile(
                      palette: palette,
                      icon: Icons.menu_book_rounded,
                      title: S.of(context).settingsSourcesLabel,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SourcesScreen(),
                        ),
                      ),
                    ),
                    _SettingsTile(
                      palette: palette,
                      icon: Icons.bug_report_rounded,
                      title: S.of(context).settingsReportErrorLabel,
                      onTap: () => _showReportErrorDialog(context),
                    ),
                    _SettingsTile(
                      palette: palette,
                      icon: Icons.error_outline_rounded,
                      title: S.of(context).settingAboutLabel,
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.spacing24),
                AppBannerVersion(versionNumber: state.versionNumber),
              ],
            );
          }
          return const SizedBox();
        },
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settingsLabel)),
      body: body,
    );
  }

  Widget _categoryHeader(BuildContext context, AppPalette palette, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing12,
        Dimens.spacing4,
        Dimens.spacing12,
        Dimens.spacing8,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: palette.textMuted,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  String _formatNotificationTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _onNotificationToggled(
    BuildContext context,
    bool enabled,
    SettingsLoadedState state,
  ) async {
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
        channelName: l10n.notificationsDailyReminderChannelName,
        channelDescription: l10n.notificationsDailyReminderChannelDescription,
      );
    } else {
      await notificationService.cancelDailyReminder();
    }
    _settingsBloc.setNotificationsEnabled(enabled);
    _settingsBloc.add(LoadSettingsEvent());
  }

  Future<void> _pickNotificationTime(
    BuildContext context,
    TimeOfDay current,
  ) async {
    final l10n = S.of(context);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null) return;
    _settingsBloc.setNotificationTime(picked.hour, picked.minute);
    final notificationService = locator<NotificationService>();
    await notificationService.scheduleDailyReminder(
      hour: picked.hour,
      minute: picked.minute,
      title: l10n.notificationsDailyReminderTitle,
      body: l10n.notificationsDailyReminderBody,
      channelName: l10n.notificationsDailyReminderChannelName,
      channelDescription: l10n.notificationsDailyReminderChannelDescription,
    );
    _settingsBloc.add(LoadSettingsEvent());
  }

  void _showFoodUnitsDialog(BuildContext context, bool currentUsesImperial) async {
    bool selectedUsesImperial = currentUsesImperial;
    final shouldUpdate = await showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          title: Text(S.of(context).settingsFoodUnitsLabel),
          content: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setState) {
              return RadioGroup<bool>(
                groupValue: selectedUsesImperial,
                onChanged: (value) {
                  setState(() {
                    selectedUsesImperial = value ?? false;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<bool>(
                      title: Text(S.of(context).settingsFoodUnitsMetric),
                      value: false,
                    ),
                    RadioListTile<bool>(
                      title: Text(S.of(context).settingsFoodUnitsImperial),
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
      _settingsBloc.setUsesImperialFoodUnits(selectedUsesImperial);
      _settingsBloc.add(LoadSettingsEvent());
      _homeBloc.add(LoadItemsEvent());
      _diaryBloc.add(const LoadDiaryYearEvent());
    }
  }

  void _showHeightUnitsDialog(BuildContext context, bool currentUsesImperial) async {
    bool selectedUsesImperial = currentUsesImperial;
    final shouldUpdate = await showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          title: Text(S.of(context).settingsHeightUnitsLabel),
          content: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setState) {
              return RadioGroup<bool>(
                groupValue: selectedUsesImperial,
                onChanged: (value) {
                  setState(() {
                    selectedUsesImperial = value ?? false;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<bool>(
                      title: Text(S.of(context).settingsHeightUnitsMetric),
                      value: false,
                    ),
                    RadioListTile<bool>(
                      title: Text(S.of(context).settingsHeightUnitsImperial),
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
      _settingsBloc.setUsesImperialHeightUnits(selectedUsesImperial);
      _settingsBloc.add(LoadSettingsEvent());
      _profileBloc.add(LoadProfileEvent());
    }
  }

  void _showBodyWeightUnitDialog(BuildContext context, BodyWeightUnit currentUnit) async {
    BodyWeightUnit selectedUnit = currentUnit;
    final shouldUpdate = await showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          title: Text(S.of(context).settingsBodyWeightUnitLabel),
          content: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setState) {
              return RadioGroup<BodyWeightUnit>(
                groupValue: selectedUnit,
                onChanged: (value) {
                  setState(() {
                    selectedUnit = value ?? BodyWeightUnit.kg;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<BodyWeightUnit>(
                      title: Text(S.of(context).kgLabel),
                      value: BodyWeightUnit.kg,
                    ),
                    RadioListTile<BodyWeightUnit>(
                      title: Text(S.of(context).lbsLabel),
                      value: BodyWeightUnit.lb,
                    ),
                    RadioListTile<BodyWeightUnit>(
                      title: Text(S.of(context).stLabel),
                      value: BodyWeightUnit.st,
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
      _settingsBloc.setBodyWeightUnit(selectedUnit);
      _settingsBloc.add(LoadSettingsEvent());
      // Body weight shows on the profile card, the home weight chip, and the
      // Trends weight chart, so all three need to re-read the new unit. Keep
      // the Trends range the user had picked rather than snapping back to the
      // default.
      _profileBloc.add(LoadProfileEvent());
      _homeBloc.add(const LoadItemsEvent());
      final trendsState = _trendsBloc.state;
      _trendsBloc.add(LoadTrendsEvent(
        rangeDays:
            trendsState is TrendsLoaded ? trendsState.rangeDays : 7,
      ));
    }
  }

  // #177: Pick between kilocalories (default) and kilojoules for the
  // energy display unit. Internal storage stays in kcal; this only
  // toggles how energy is rendered everywhere it appears.
  void _showEnergyUnitDialog(
    BuildContext context,
    bool currentUsesKilojoules,
  ) async {
    bool selectedUsesKilojoules = currentUsesKilojoules;
    final shouldUpdate = await showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          title: Text(S.of(context).settingsEnergyUnitLabel),
          content: StatefulBuilder(
            builder:
                (
                  BuildContext context,
                  void Function(void Function()) setState,
                ) {
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
        Provider.of<EnergyUnitProvider>(
          context,
          listen: false,
        ).updateUsesKilojoules(selectedUsesKilojoules);
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
      builder: (context) =>
          MacroSplitDialog(settingsBloc: _settingsBloc, homeBloc: _homeBloc),
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
      MaterialPageRoute<void>(builder: (_) => const NutrientVisibilityScreen()),
    );
  }

  void _openFoodSourcesScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FoodSourcesScreen()),
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

  Future<void> _confirmDeleteAllData(BuildContext context) async {
    final l10n = S.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsDeleteAllDataConfirmTitle),
        content: Text(l10n.settingsDeleteAllDataConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.dialogCancelLabel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.settingsDeleteAllDataConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await locator<DeleteAllUserDataUsecase>().deleteAll();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil(
      NavigationOptions.onboardingRoute,
      (_) => false,
    );
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
            builder:
                (
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
                          title: Text(
                            S.of(context).settingsThemeSystemDefaultLabel,
                          ),
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
            builder:
                (
                  BuildContext context,
                  void Function(void Function()) setState,
                ) {
                  return RadioGroup<String>(
                    groupValue: selectedCode,
                    onChanged: (v) =>
                        setState(() => selectedCode = v as String),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          title: Text(
                            S.of(context).settingsThemeSystemDefaultLabel,
                          ),
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
                final locale = selectedCode.isEmpty ? null : selectedCode;
                _settingsBloc.setSelectedLocale(locale);
                _settingsBloc.add(LoadSettingsEvent());
                Provider.of<LocaleProvider>(
                  context,
                  listen: false,
                ).updateLocale(locale != null ? Locale(locale) : null);
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
            builder:
                (
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
          child: Image.asset(
            Theme.of(context).brightness == Brightness.dark
                ? 'assets/icon/ont_logo_square_color_white_1024x1024.png'
                : 'assets/icon/ont_logo_square_color_back_1024x1024.png',
          ),
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


String _accentSubtitle(
  BuildContext context, {
  required bool useMaterialYou,
  required int? accentColor,
}) {
  final isAndroid = Theme.of(context).platform == TargetPlatform.android;
  if (isAndroid && useMaterialYou) {
    return S.of(context).settingsAccentSubtitleMaterialYou;
  }
  if (accentColor != null) {
    return S.of(context).settingsAccentSubtitleCustom;
  }
  return S.of(context).settingsAccentSubtitleDefault;
}

class _AccentTrailingSwatch extends StatelessWidget {
  final bool useMaterialYou;
  final int? accentColor;

  const _AccentTrailingSwatch({
    required this.useMaterialYou,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    if (isAndroid && useMaterialYou) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: <Color>[
              Color(0xFFFF5252),
              Color(0xFFFFD740),
              Color(0xFF69F0AE),
              Color(0xFF40C4FF),
              Color(0xFFB388FF),
              Color(0xFFFF5252),
            ],
          ),
        ),
      );
    }
    final color = accentColor != null
        ? Color(accentColor!)
        : const Color(0xFF43A047); // default green disc preview
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Wraps a run of related settings rows inside one [AppCard], with a hairline
/// divider between rows. Gives the screen the same calm grouped rhythm as the
/// Profile tab rather than one long ungrouped list.
class _SettingsGroup extends StatelessWidget {
  final AppPalette palette;
  final List<Widget> tiles;

  const _SettingsGroup({required this.palette, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) {
        rows.add(Divider(height: Dimens.hairline, color: palette.border));
      }
      rows.add(tiles[i]);
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: Dimens.spacing4),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// A single tappable settings row. Keeps the underlying [ListTile] (so its
/// role semantics carry through) and an optional [Semantics] identifier where
/// the original markup carried one, but dresses the leading icon as a soft
/// rounded chip in the friendly-flat style.
class _SettingsTile extends StatelessWidget {
  final String? identifier;
  final AppPalette palette;
  final IconData icon;
  final Color? iconColor;
  final Color? titleColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final bool enabled;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.palette,
    required this.icon,
    required this.title,
    required this.onTap,
    this.identifier,
    this.iconColor,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.showChevron = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    final tint = iconColor ?? accent;
    final tile = ListTile(
      enabled: enabled,
      leading: _SettingsIconChip(palette: palette, icon: icon, color: tint),
      title: Text(
        title,
        style: text.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: text.bodyMedium?.copyWith(color: palette.textMuted),
            )
          : null,
      trailing: trailing ??
          (showChevron
              ? Icon(Icons.chevron_right_rounded, color: accent)
              : null),
      onTap: onTap,
    );
    if (identifier == null) return tile;
    return Semantics(identifier: identifier!, child: tile);
  }
}

/// Switch variant of [_SettingsTile] for the boolean toggles.
class _SettingsSwitchTile extends StatelessWidget {
  final AppPalette palette;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.palette,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    return SwitchListTile(
      secondary: _SettingsIconChip(palette: palette, icon: icon, color: accent),
      title: Text(
        title,
        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: text.bodyMedium?.copyWith(color: palette.textMuted),
            )
          : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

/// The soft rounded leading chip shared by every settings row.
class _SettingsIconChip extends StatelessWidget {
  final AppPalette palette;
  final IconData icon;
  final Color color;

  const _SettingsIconChip({
    required this.palette,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Dimens.borderRadiusS,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
