import 'dart:io' show Platform;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/health_import_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/import_workouts_usecase.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/workout_compensation_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/health_disclosure_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

/// What the platform health store is called in front of the user. Both names
/// are product names, so they are deliberately not localized. Lives here
/// because it is a presentation-layer label; the settings row that leads to
/// this screen shows the same name and reads it from here.
String get healthPlatformName =>
    Platform.isIOS ? 'Apple Health' : 'Health Connect';

/// Settings → Health sync: opts into importing finished workouts from Health
/// Connect / Apple Health, and tunes how much of the energy those workouts
/// report is credited toward the daily calorie goal.
///
/// The credit is a share rather than the raw figure because bodies compensate
/// for exercise (see [WorkoutCompensationCalc]); the screen offers a
/// suggestion derived from the user's body composition and lets them override
/// it. Changing the share affects future imports only — activities already in
/// the diary keep the calories they were filed with.
class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key});

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  /// Slider granularity, in percentage points.
  static const _multiplierStepPct = 5;

  final _log = Logger('HealthSyncScreen');

  bool _loading = true;

  /// Whether the device can serve health data at all. False keeps every
  /// control inert and puts the reason on screen rather than letting a tap
  /// fail silently.
  bool _isAvailable = false;

  /// True while a platform round trip is in flight, so a second tap cannot
  /// start a competing permission request or import.
  bool _busy = false;

  bool _importEnabled = false;

  /// The stored credit, null until the user opts in. Kept apart from
  /// [_multiplier] so the enable flow knows whether to seed a suggestion.
  double? _storedMultiplier;

  /// What the slider shows — the stored credit, or the effective default
  /// while nothing is stored.
  double _multiplier = ConfigEntity.maxHealthWorkoutKcalMultiplier;

  double? _suggestedMultiplier;
  DateTime? _lastImportAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isAvailable = await locator<HealthImportRepository>().isAvailable();
    final config = await locator<GetConfigUsecase>().getConfig();
    if (!mounted) return;
    setState(() {
      _isAvailable = isAvailable;
      _importEnabled = config.healthImportEnabled;
      _storedMultiplier = config.healthWorkoutKcalMultiplier;
      _multiplier = config.effectiveHealthWorkoutKcalMultiplier;
      _lastImportAt = config.healthLastImportAt;
      _loading = false;
    });
    // Only meaningful once the user has opted in: the body fat reading the
    // suggestion prefers is itself behind the permission the switch asks for.
    if (_importEnabled) await _loadSuggestion();
  }

  /// Computes the credit this user's body composition suggests, or leaves it
  /// null when the health store has nothing to offer and the calculator would
  /// only be able to guess.
  Future<void> _loadSuggestion() async {
    double? suggested;
    try {
      final bodyFatPercent = await locator<HealthImportRepository>()
          .getLatestBodyFatPercent();
      final user = await locator<GetUserUsecase>().getUserData();
      suggested = WorkoutCompensationCalc.suggestedMultiplier(
        bodyFatPercent: bodyFatPercent,
        user: user,
      );
    } catch (error, stackTrace) {
      // The suggestion is an offer, not a setting — a health store that will
      // not answer costs the user the hint, nothing else.
      _log.warning(
        'Could not suggest a workout calorie credit',
        error,
        stackTrace,
      );
    }
    if (!mounted) return;
    setState(() => _suggestedMultiplier = suggested);
  }

  Future<void> _onAutoImportChanged(bool enabled) async {
    if (!enabled) {
      setState(() => _importEnabled = false);
      await locator<SettingsBloc>().setHealthImportEnabled(false);
      return;
    }

    // The disclosure gates the request rather than merely preceding it (#926):
    // Play's User Data policy wants affirmative consent in the app before the
    // platform is asked, and a dialog the user could dismiss into a permission
    // prompt would not be consent. Anything other than the confirm action —
    // cancel, back, a killed activity — leaves the switch off and asks for
    // nothing.
    //
    // Shown on every opt-in, not once ever. Re-enabling is rare, and a
    // disclosure that only the first user of a device ever saw would be a
    // disclosure to the wrong person on a shared handset.
    if (!await _confirmDisclosure()) return;

    setState(() => _busy = true);
    try {
      final granted = await locator<HealthImportRepository>()
          .requestPermissions();
      if (!mounted) return;
      if (!granted) {
        setState(() => _importEnabled = false);
        _showMessage(
          S.of(context).healthSyncPermissionDeniedLabel(healthPlatformName),
        );
        return;
      }

      await locator<SettingsBloc>().setHealthImportEnabled(true);
      if (!mounted) return;
      setState(() => _importEnabled = true);

      // First opt-in: start the user on the credit their body composition
      // suggests rather than on a silent 100%, which would overstate the
      // budget for most people.
      if (_storedMultiplier == null) {
        await _loadSuggestion();
        final suggested = _suggestedMultiplier;
        if (suggested != null) await _applyMultiplier(suggested);
      }
      await _runImport(reportCount: false);
    } catch (error, stackTrace) {
      _log.warning('Enabling workout import failed', error, stackTrace);
      if (!mounted) return;
      setState(() => _importEnabled = false);
      _showMessage(
        S.of(context).healthSyncPermissionDeniedLabel(healthPlatformName),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Runs an import the user is waiting on, and tells them how it went.
  /// [reportCount] is false on the opt-in path, where the switch flipping is
  /// the feedback and a "no new workouts" toast would only read as a failure.
  Future<void> _runImport({bool reportCount = true}) async {
    try {
      final imported = await locator<ImportWorkoutsUsecase>().importNow();
      await _reloadWatermark();
      if (!mounted) return;
      if (reportCount) {
        _showMessage(S.of(context).healthSyncImportedCountLabel(imported));
      }
      if (imported > 0) {
        locator<HomeBloc>().add(const LoadItemsEvent());
        locator<DiaryBloc>().add(const LoadDiaryYearEvent());
        locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
      }
    } catch (error, stackTrace) {
      // Whatever the platform threw, the user's lever is the same one: the
      // read access this app was granted.
      _log.warning('Workout import failed', error, stackTrace);
      if (!mounted) return;
      _showMessage(
        S.of(context).healthSyncPermissionDeniedLabel(healthPlatformName),
      );
    }
  }

  Future<void> _onImportNowPressed() async {
    setState(() => _busy = true);
    try {
      await _runImport();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Re-reads the watermark the importer just wrote, so the "last import"
  /// subtitle reflects the run that finished rather than the one before it.
  Future<void> _reloadWatermark() async {
    final config = await locator<GetConfigUsecase>().getConfig();
    if (!mounted) return;
    setState(() => _lastImportAt = config.healthLastImportAt);
  }

  Future<void> _applyMultiplier(double multiplier) async {
    setState(() {
      _multiplier = multiplier;
      _storedMultiplier = multiplier;
    });
    await locator<SettingsBloc>().setHealthWorkoutKcalMultiplier(multiplier);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSources() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SourcesScreen()));
  }

  /// Puts the disclosure up and reports whether the user chose to go on.
  ///
  /// A dismissal returns null, which reads as a refusal — the one direction
  /// this must fail in, since the alternative is asking the platform for
  /// health data on the strength of a stray tap.
  Future<bool> _confirmDisclosure() async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const HealthDisclosureDialog(),
    );
    return accepted ?? false;
  }

  /// Opens the policy in the language the app is being read in, matching how
  /// Settings and the onboarding intro do it.
  Future<void> _openPrivacyPolicy() async {
    final url = Uri.parse(
      URLConst.privacyPolicyFor(Localizations.localeOf(context).languageCode),
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      _showMessage(S.of(context).errorOpeningBrowser);
    }
  }

  int _percentOf(double multiplier) => (multiplier * 100).round();

  /// The suggestion is only worth showing when acting on it would move the
  /// slider — within a percentage point it is the setting the user already
  /// has.
  double? get _divergentSuggestion {
    final suggested = _suggestedMultiplier;
    if (suggested == null) return null;
    if ((_percentOf(suggested) - _percentOf(_multiplier)).abs() <= 1) {
      return null;
    }
    return suggested;
  }

  String _formatLastImport(BuildContext context, DateTime lastImportAt) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(localeTag).add_Hm().format(lastImportAt);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final canEdit = _isAvailable && _importEnabled && !_busy;
    return Scaffold(
      appBar: AppBar(title: Text(healthPlatformName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (!_isAvailable)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimens.spacing16,
                      vertical: Dimens.spacing8,
                    ),
                    child: Text(
                      s.healthSyncUnavailableLabel,
                      style: textTheme.bodySmall,
                    ),
                  ),
                Semantics(
                  identifier: 'health-sync-auto-import',
                  child: SwitchListTile(
                    secondary: const Icon(Icons.sync_rounded),
                    title: Text(
                      s.healthSyncAutoImportLabel(healthPlatformName),
                    ),
                    value: _importEnabled,
                    onChanged: _isAvailable && !_busy
                        ? _onAutoImportChanged
                        : null,
                  ),
                ),
                _buildMultiplierSection(context, s, textTheme, canEdit),
                Semantics(
                  identifier: 'health-sync-import-now',
                  child: ListTile(
                    leading: const Icon(Icons.download_rounded),
                    title: Text(s.healthSyncImportNowLabel),
                    subtitle: Text(
                      _lastImportAt == null
                          ? s.healthSyncNeverImportedLabel
                          : s.healthSyncLastImportLabel(
                              _formatLastImport(context, _lastImportAt!),
                            ),
                    ),
                    enabled: canEdit,
                    onTap: _onImportNowPressed,
                  ),
                ),
                // Health Connect can send the user straight here to ask what
                // the app wants their data for (#927), and the policy is the
                // rest of that answer. Reachable from settings too, but a
                // reader who arrived from outside the app has no reason to
                // know that, and should not have to go looking.
                Semantics(
                  identifier: 'health-sync-privacy-policy',
                  child: ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(s.privacyPolicyLabel),
                    onTap: _openPrivacyPolicy,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMultiplierSection(
    BuildContext context,
    S s,
    TextTheme textTheme,
    bool canEdit,
  ) {
    final suggested = _divergentSuggestion;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.spacing16,
        Dimens.spacing8,
        Dimens.spacing16,
        Dimens.spacing8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                // A long localized label shares this row with the percentage
                // and the sources button, so it shrinks to stay on one line
                // rather than wrapping or striping the Row.
                child: AutoSizeText(
                  s.healthSyncKcalMultiplierLabel,
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  minFontSize: 11,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                s.healthSyncKcalMultiplierValueLabel(_percentOf(_multiplier)),
                style: textTheme.titleMedium,
              ),
              Semantics(
                identifier: 'health-sync-sources',
                child: IconButton(
                  icon: const Icon(Icons.info_outline_rounded),
                  tooltip: s.sourcesIconTooltip,
                  onPressed: _openSources,
                ),
              ),
            ],
          ),
          Semantics(
            identifier: 'health-sync-kcal-multiplier',
            child: Slider(
              min: ConfigEntity.minHealthWorkoutKcalMultiplier,
              max: ConfigEntity.maxHealthWorkoutKcalMultiplier,
              divisions: _multiplierDivisions,
              value: _multiplier,
              label: s.healthSyncKcalMultiplierValueLabel(
                _percentOf(_multiplier),
              ),
              onChanged: canEdit
                  ? (value) => setState(() => _multiplier = value)
                  : null,
              onChangeEnd: canEdit ? _applyMultiplier : null,
            ),
          ),
          Text(s.healthSyncKcalMultiplierSubtitle, style: textTheme.bodySmall),
          if (canEdit && suggested != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                identifier: 'health-sync-apply-suggestion',
                // Align fills the row, and the Semantics node would inherit
                // those bounds — see AGENTS.md "The `container: true`
                // gotcha" — leaving a coordinate tap short of the button.
                container: true,
                child: TextButton(
                  onPressed: () => _applyMultiplier(suggested),
                  child: Text(
                    s.healthSyncSuggestedLabel(_percentOf(suggested)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Whole 5% steps across the allowed range, derived so the two bounds stay
  /// the only place the range is stated.
  int get _multiplierDivisions =>
      ((ConfigEntity.maxHealthWorkoutKcalMultiplier -
                  ConfigEntity.minHealthWorkoutKcalMultiplier) *
              100 /
              _multiplierStepPct)
          .round();
}
