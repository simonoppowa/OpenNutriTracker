import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/section_group.dart';
import 'package:opennutritracker/core/presentation/ai_assist_summary.dart';
import 'package:opennutritracker/core/presentation/widgets/badged_title.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/ai_assist_dialog.dart';
import 'package:opennutritracker/core/styles/accent_colors.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/core/utils/theme_mode_provider.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// Onboarding "Other options" page: app theme, the food databases used by
/// search, the daily logging reminder, and AI meal assistance. Everything
/// here is optional — the page is pre-filled with the defaults (system theme,
/// all sources on, no reminder, no AI key) and can be skipped by tapping next;
/// each choice can be revisited later in Settings.
///
/// **AI meal assistance is the one row that does not follow the page's staging
/// model**, and deliberately. Every other control publishes to the bloc and is
/// written only when onboarding completes; the AI dialog persists a provider,
/// a model and a keystore credential the moment they are touched. Staging a
/// credential to write later would mean holding it in memory across the rest
/// of onboarding for no benefit, and the dialog is shared with Settings, where
/// immediate writes are correct. So the row reads its state directly and
/// refreshes after the dialog closes. See #728.
class OnboardingOtherOptionsPageBody extends StatefulWidget {
  final Function(
    AppThemeEntity selectedTheme,
    Map<String, bool> foodSourceToggles,
    bool dailyReminderEnabled,
    bool useMaterialYou,
    int? accentColor,
  ) setPageContent;

  final AppThemeEntity initialTheme;
  final Map<String, bool> initialFoodSourceToggles;
  final bool initialDailyReminderEnabled;
  final bool initialUseMaterialYou;
  final int? initialAccentColor;

  /// Injected rather than pulled from the locator inside `build`, matching how
  /// every other value on this page arrives. Reaching for the locator here
  /// would make the existing tests on this page need one registered, for a
  /// dependency none of them exercise.
  final AiCredentialStorage? aiCredentials;

  const OnboardingOtherOptionsPageBody({
    super.key,
    required this.setPageContent,
    required this.initialTheme,
    required this.initialFoodSourceToggles,
    required this.initialDailyReminderEnabled,
    required this.initialUseMaterialYou,
    required this.initialAccentColor,
    this.aiCredentials,
  });

  @override
  State<OnboardingOtherOptionsPageBody> createState() =>
      _OnboardingOtherOptionsPageBodyState();
}

class _OnboardingOtherOptionsPageBodyState
    extends State<OnboardingOtherOptionsPageBody> {
  late AppThemeEntity _selectedTheme = widget.initialTheme;
  late final Map<String, bool> _foodSourceToggles =
      Map<String, bool>.from(widget.initialFoodSourceToggles);
  late bool _dailyReminderEnabled = widget.initialDailyReminderEnabled;
  late bool _useMaterialYou = widget.initialUseMaterialYou;
  late int? _accentColor = widget.initialAccentColor;

  /// Null until the first read completes, so the row shows no subtitle rather
  /// than briefly claiming the feature is off. Same three fields Settings
  /// keeps, read from the same store.
  bool? _aiHasKey;
  bool _aiEnabled = false;
  AiProvider _aiProvider = AiProvider.anthropic;

  @override
  void initState() {
    super.initState();
    _refreshAiState();
  }

  Future<void> _refreshAiState() async {
    final storage = widget.aiCredentials;
    if (storage == null) return;
    final summary = await storage.readSummary();
    if (!mounted) return;
    setState(() {
      _aiHasKey = summary.hasKey;
      _aiEnabled = summary.enabled;
      _aiProvider = summary.provider;
    });
  }

  /// Refreshed unconditionally rather than only when the dialog reports a
  /// change: the subtitle is cheap to recompute and a stale one misdescribes
  /// what leaves the device.
  Future<void> _openAiDialog(AiCredentialStorage storage) async {
    await AiAssistDialog.show(context, storage);
    await _refreshAiState();
  }

  void _publish() {
    widget.setPageContent(
      _selectedTheme,
      _foodSourceToggles,
      _dailyReminderEnabled,
      _useMaterialYou,
      _accentColor,
    );
  }

  void _onThemeSelected(AppThemeEntity theme) {
    setState(() => _selectedTheme = theme);
    // Apply immediately so the user sees the choice take effect; it is
    // persisted with the rest of the onboarding data on the final page.
    Provider.of<ThemeModeProvider>(context, listen: false).updateTheme(theme);
    _publish();
  }

  void _onMaterialYouSelected() {
    setState(() {
      _useMaterialYou = true;
      _accentColor = null;
    });
    final theme = Provider.of<ThemeModeProvider>(context, listen: false);
    theme.updateUseMaterialYou(true);
    theme.updateAccentColor(null);
    _publish();
  }

  void _onAccentColorSelected(Color color) {
    final argb = color.toARGB32();
    setState(() {
      _accentColor = argb;
      // A custom colour must win over Material You; otherwise the picked
      // shade silently does nothing on Android 12+.
      _useMaterialYou = false;
    });
    final theme = Provider.of<ThemeModeProvider>(context, listen: false);
    theme.updateAccentColor(argb);
    theme.updateUseMaterialYou(false);
    _publish();
  }

  void _onSourceToggled(String sourceCode, bool enabled) {
    setState(() => _foodSourceToggles[sourceCode] = enabled);
    _publish();
  }

  /// Horizontally scrollable swatch row: the Material You "auto" swatch
  /// (Android only, where the wallpaper palette actually exists) followed
  /// by the shared accent presets. Mirrors the Settings accent screen in a
  /// form compact enough for onboarding.
  Widget _buildAccentColorRow(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final materialYouSelected = _useMaterialYou && _accentColor == null;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (isAndroid)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: S.of(context).settingsMaterialYouTitle,
                child: _swatch(
                  context,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  selected: materialYouSelected,
                  onTap: _onMaterialYouSelected,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          for (final color in accentPresetColors)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _swatch(
                context,
                color: color,
                selected: !materialYouSelected &&
                    _accentColor == color.toARGB32(),
                onTap: () => _onAccentColorSelected(color),
              ),
            ),
        ],
      ),
    );
  }

  Widget _swatch(
    BuildContext context, {
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    Widget? child,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 3,
                )
              : Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
        ),
        child: selected && child == null
            ? const Icon(Icons.check_rounded, color: Colors.white)
            : child,
      ),
    );
  }

  String _themeLabel(BuildContext context, AppThemeEntity theme) {
    switch (theme) {
      case AppThemeEntity.system:
        return S.of(context).settingsThemeSystemDefaultLabel;
      case AppThemeEntity.light:
        return S.of(context).settingsThemeLightLabel;
      case AppThemeEntity.dark:
        return S.of(context).settingsThemeDarkLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.onboardingOtherOptionsLabel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              s.onboardingOtherOptionsSubtitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Dimens.spacing24),
            SectionHeader(label: s.settingsThemeLabel),
            const SizedBox(height: Dimens.spacing12),
            SectionGroup(
              tiles: [
                Padding(
                  padding: const EdgeInsets.all(Dimens.spacing12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<AppThemeEntity>(
                        segments: [
                          for (final theme in AppThemeEntity.values)
                            ButtonSegment(
                              value: theme,
                              label: Text(_themeLabel(context, theme)),
                            ),
                        ],
                        selected: {_selectedTheme},
                        onSelectionChanged: (selection) =>
                            _onThemeSelected(selection.first),
                      ),
                      const SizedBox(height: Dimens.spacing16),
                      Text(
                        s.settingsAccentColourTitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: Dimens.spacing8),
                      _buildAccentColorRow(context),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimens.spacing24),
            SectionHeader(label: s.settingsFoodSourcesLabel),
            const SizedBox(height: Dimens.spacing12),
            SectionGroup(tiles: [_buildFoodSourcesTile(context)]),
            const SizedBox(height: Dimens.spacing24),
            SectionHeader(label: s.settingsNotificationsLabel),
            const SizedBox(height: Dimens.spacing12),
            SectionGroup(
              tiles: [
                Semantics(
                  identifier: 'onboarding-daily-reminder',
                  child: SwitchListTile(
                    dense: true,
                    title: Text(s.settingsNotificationsLabel),
                    subtitle: Text(s.notificationsDailyReminderBody),
                    value: _dailyReminderEnabled,
                    onChanged: (value) {
                      setState(() => _dailyReminderEnabled = value);
                      _publish();
                    },
                  ),
                ),
              ],
            ),
            ...?_buildAiAssistSection(context, s),
          ],
        ),
      ),
    );
  }

  /// Last on the page on purpose: it is the least likely of these to be
  /// usable at first run — it needs an account and a card at Anthropic,
  /// OpenAI or OpenRouter — and the most consequential, since it is the only
  /// option here that changes what leaves the device.
  ///
  /// Opens the Settings dialog rather than restating it. The disclosure, the
  /// provider list and the per-provider retention text are the load-bearing
  /// part, and a second onboarding-shaped copy would be a second thing to
  /// keep true in nine languages.
  ///
  /// Absent when no storage was injected, which is the case for tests that
  /// predate this row and do not exercise it.
  List<Widget>? _buildAiAssistSection(BuildContext context, S s) {
    final storage = widget.aiCredentials;
    if (storage == null) return null;

    // Null until the keystore read lands, and it stays a null *widget* rather
    // than an empty `Text`: the point of the null is that the row says nothing
    // instead of something wrong, and a blank `Text` still occupies its line,
    // so the row would resize under the user as the read came back.
    final subtitle = aiAssistSubtitle(
      s,
      hasKey: _aiHasKey,
      enabled: _aiEnabled,
      provider: _aiProvider,
    );

    return [
      const SizedBox(height: Dimens.spacing24),
      SectionHeader(label: s.settingsAiAssistLabel),
      const SizedBox(height: Dimens.spacing12),
      SectionGroup(
        tiles: [
          Semantics(
            identifier: 'onboarding-ai-assist',
            child: ListTile(
              dense: true,
              title: BadgedTitle(
                title: s.settingsAiAssistLabel,
                badge: s.aiAssistExperimentalLabel,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: subtitle == null ? null : Text(subtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _openAiDialog(storage),
            ),
          ),
        ],
      ),
    ];
  }

  /// The database list is long and every entry is already set sensibly for
  /// the user's region, so it collapses. The subtitle reports the state
  /// while closed, which is the only thing most users need from it.
  Widget _buildFoodSourcesTile(BuildContext context) {
    final s = S.of(context);
    // Open Food Facts is always searched and has no switch, so it counts
    // towards both sides of the summary.
    const alwaysOnCount = 1;
    final enabled =
        alwaysOnCount +
        SPConst.settingsSelectableFoodSources
            .where((source) => _foodSourceToggles[source] ?? true)
            .length;
    final total = alwaysOnCount + SPConst.settingsSelectableFoodSources.length;

    return Semantics(
      identifier: 'onboarding-food-sources',
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          s.settingsFoodSourcesLabel,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(s.onboardingFoodSourcesEnabledCount(enabled, total)),
        children: [
          SwitchListTile(
            dense: true,
            title: const Text(OFFConst.offSourceName),
            subtitle: Text(s.foodSourcesAlwaysEnabledLabel),
            value: true,
            onChanged: null,
          ),
          for (final sourceCode in SPConst.settingsSelectableFoodSources)
            Semantics(
              identifier: 'onboarding-food-source-${sourceCode.replaceAll('_', '-')}',
              child: SwitchListTile(
                dense: true,
                title: Text(
                  SPConst.foodSourceDisplayNames[sourceCode] ?? sourceCode,
                ),
                value: _foodSourceToggles[sourceCode] ?? true,
                onChanged: (value) => _onSourceToggled(sourceCode, value),
              ),
            ),
        ],
      ),
    );
  }
}
