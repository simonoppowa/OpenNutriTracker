import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/calories_profile_info_dialog.dart';
import 'package:opennutritracker/core/utils/bounds/ranges_const.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/reload_diary_and_trends.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// The daily kcal goal, either calculated or fixed (#671).
///
/// Calculated: the daily kcal/kJ adjustment slider, paired with the TDEE
/// reference and (for non-binary users) the calorie-profile picker that
/// decides which reference equation is used. Fixed: one number the user
/// types in, which replaces the calculation; logged activities are still
/// added on top. The adjustment is kept while the goal is fixed, so
/// switching back restores it.
///
/// Everything in this dialog is about the daily kcal goal — macro
/// distribution, per-meal split, and nutrient goals each live behind their
/// own Settings entries.
class KcalAdjustmentDialog extends StatefulWidget {
  final SettingsBloc settingsBloc;
  final ProfileBloc profileBloc;
  final HomeBloc homeBloc;

  const KcalAdjustmentDialog({
    super.key,
    required this.settingsBloc,
    required this.profileBloc,
    required this.homeBloc,
  });

  @override
  State<KcalAdjustmentDialog> createState() => _KcalAdjustmentDialogState();
}

class _KcalAdjustmentDialogState extends State<KcalAdjustmentDialog> {
  static const double _minKcalAdjustment = -1000;
  static const double _maxKcalAdjustment = 1000;
  static const int _kcalDivisions = 200;

  static const double _fallbackFixedKcalGoal = 2000;

  /// Keeps the fixed-goal field to whole numbers by rejecting any edit
  /// that is not one, instead of stripping the offending characters: with
  /// stripping, a pasted "1660.0" became 16600 and was saved as the
  /// maximum. A rejected edit leaves the previous text in place.
  static final _wholeNumberOnly = TextInputFormatter.withFunction(
    (oldValue, newValue) =>
        RegExp(r'^\d*$').hasMatch(newValue.text) ? newValue : oldValue,
  );

  double _kcalAdjustment = 0;
  UserEntity? _user;
  bool _loaded = false;

  /// Whether the fixed goal is chosen (#671). Saved as a null fixed goal
  /// when false.
  bool _fixedMode = false;

  /// The fixed goal in kcal, always inside the allowed range. Null until
  /// there is one: none was stored and the user has not picked Fixed yet.
  double? _fixedKcalGoal;

  late final TextEditingController _kcalController;
  late final TextEditingController _fixedController;

  /// Same role as [_kcalTextEdited], for the fixed-goal field.
  bool _fixedTextEdited = false;
  late final FocusNode _fixedFocusNode;

  /// Whether the user has typed into the field since it was last filled
  /// in. Untouched kJ text is a rounded conversion (100 kcal shows as
  /// 418 kJ), so re-parsing it would drift the stored value (#1371).
  bool _kcalTextEdited = false;

  /// A typed value is also applied when the field loses focus, so the
  /// slider follows it once the keyboard closes: the iOS number pad has no
  /// return key, so a submit never comes (#1324).
  late final FocusNode _kcalFocusNode;

  @override
  void initState() {
    super.initState();
    _kcalController = TextEditingController(text: '0');
    _kcalFocusNode = FocusNode()..addListener(_onKcalFocusChanged);
    _fixedController = TextEditingController();
    _fixedFocusNode = FocusNode()..addListener(_onFixedFocusChanged);
    _load();
  }

  @override
  void dispose() {
    _kcalController.dispose();
    _kcalFocusNode.dispose();
    _fixedController.dispose();
    _fixedFocusNode.dispose();
    super.dispose();
  }

  void _onKcalFocusChanged() {
    if (!mounted || _kcalFocusNode.hasFocus) return;
    _applyKcalInput();
  }

  void _onFixedFocusChanged() {
    if (!mounted || _fixedFocusNode.hasFocus) return;
    _applyFixedInput();
  }

  bool get _usesKj =>
      Provider.of<EnergyUnitProvider>(context, listen: false).usesKilojoules;

  double _toDisplay(double kcal) => _usesKj ? UnitCalc.kcalToKj(kcal) : kcal;

  Future<void> _load() async {
    final kcal = await widget.settingsBloc.getKcalAdjustment();
    final fixed = CalorieGoalCalc.validFixedKcalGoal(
      await widget.settingsBloc.getFixedKcalGoal(),
    );
    final user = await widget.profileBloc.getUser();
    if (!mounted) return;
    setState(() {
      _kcalAdjustment = kcal;
      _user = user;
      _kcalController.text = _toDisplay(kcal).round().toString();
      _fixedMode = fixed != null;
      _fixedKcalGoal = fixed;
      if (fixed != null) {
        _fixedController.text = _toDisplay(fixed).round().toString();
      }
      _loaded = true;
    });
  }

  /// The calculated goal without today's activities, as the starting point
  /// for a fixed goal: the user edits the number they already know.
  double _calculatedKcalGoal() {
    final user = _user;
    if (user == null) return _fallbackFixedKcalGoal;
    final kcal = CalorieGoalCalc.getTotalKcalGoal(
      user,
      0,
      kcalUserAdjustment: _kcalAdjustment,
      caloriesTaperEnabled: user.caloriesTaperEnabled,
    ).roundToDouble();
    return kcal.clamp(
      Ranges.minFixedDailyKcalGoal,
      Ranges.maxFixedDailyKcalGoal,
    );
  }

  void _setFixedMode(bool fixed) {
    if (fixed == _fixedMode) return;
    // Keep whatever is typed in the field being left.
    if (fixed) {
      _applyKcalInput();
    } else {
      _applyFixedInput();
    }
    setState(() {
      _fixedMode = fixed;
      if (fixed && _fixedKcalGoal == null) {
        final start = _calculatedKcalGoal();
        _fixedKcalGoal = start;
        _fixedController.text = _toDisplay(start).round().toString();
        _fixedTextEdited = false;
      }
    });
  }

  /// Applies the typed fixed goal. Text that is not a number snaps back to
  /// the last good value; a number outside the range is moved to its
  /// nearest end, like the adjustment field does.
  void _applyFixedInput() {
    if (!_fixedTextEdited) return;
    _fixedTextEdited = false;
    final last = _fixedKcalGoal ?? _calculatedKcalGoal();
    final parsed = int.tryParse(_fixedController.text);
    if (parsed == null) {
      _fixedController.text = _toDisplay(last).round().toString();
      return;
    }
    final asKcal = _usesKj
        ? UnitCalc.kjToKcal(parsed.toDouble())
        : parsed.toDouble();
    final clamped = asKcal.clamp(
      Ranges.minFixedDailyKcalGoal,
      Ranges.maxFixedDailyKcalGoal,
    );
    setState(() => _fixedKcalGoal = clamped);
    _fixedController.text = _toDisplay(clamped).round().toString();
  }

  void _applyKcalInput() {
    if (!_kcalTextEdited) return;
    _kcalTextEdited = false;
    // The text field always reads in whichever unit the user is
    // seeing; convert back to kcal once for storage so the persisted
    // value stays consistent across unit toggles.
    final usesKj =
        Provider.of<EnergyUnitProvider>(context, listen: false).usesKilojoules;
    final parsed = int.tryParse(_kcalController.text);
    if (parsed == null) {
      // Bad input — snap the field back to the last good value.
      final display =
          usesKj ? UnitCalc.kcalToKj(_kcalAdjustment) : _kcalAdjustment;
      _kcalController.text = display.round().toString();
      return;
    }
    final asKcal =
        usesKj ? UnitCalc.kjToKcal(parsed.toDouble()) : parsed.toDouble();
    final clamped = asKcal.clamp(_minKcalAdjustment, _maxKcalAdjustment);
    final clampedDisplay = usesKj ? UnitCalc.kcalToKj(clamped) : clamped;
    setState(() => _kcalAdjustment = clamped);
    _kcalController.text = clampedDisplay.round().toString();
  }

  Future<void> _openCaloriesProfileDialog() async {
    final user = _user;
    if (user == null) return;
    final selected = await showDialog<CaloriesProfileEntity>(
      context: context,
      builder: (ctx) => CaloriesProfileInfoDialog(
        initialProfile:
            user.caloriesProfile ?? CaloriesProfileEntity.averaged,
      ),
    );
    if (selected == null) return;
    user.caloriesProfile = selected;
    await widget.profileBloc.updateUser(user);
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _save() async {
    // Apply any value still sitting in the text field. Without this,
    // typing a number and tapping OK (without pressing the keyboard's
    // Done key first) silently saved the slider's last value instead.
    // Same fix as the macro split dialog (#525).
    _applyKcalInput();
    _applyFixedInput();
    // round(), not toInt(): a kJ slider step converts to kcal with float
    // noise (209.2 / 4.184 = 49.999…) that truncation turns into 49.
    await widget.settingsBloc.setKcalAdjustment(
      _kcalAdjustment.round().toDouble(),
    );
    // The adjustment above is saved in either mode, so it is still there
    // when the user switches back to the calculated goal.
    final fixed = _fixedKcalGoal;
    await widget.settingsBloc.setFixedKcalGoal(
      _fixedMode && fixed != null ? fixed.roundToDouble() : null,
    );
    widget.settingsBloc.add(LoadSettingsEvent());
    widget.homeBloc.add(const LoadItemsEvent());
    // Recompute today's stored kcal goal so the diary card reflects
    // the new adjustment immediately instead of waiting for tomorrow.
    await widget.settingsBloc.updateTrackedDay(
      await widget.settingsBloc.getCurrentLogicalDay(),
    );
    reloadDiaryAndTrends();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              context.watch<EnergyUnitProvider>().usesKilojoules
                  ? s.settingsKjGoalLabel
                  : s.settingsKcalGoalLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Reset clears the adjustment, which a fixed goal does not use.
          if (!_fixedMode) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: _loaded
                  ? () {
                      setState(() => _kcalAdjustment = 0);
                      _kcalController.text = '0';
                      _kcalTextEdited = false;
                    }
                  : null,
              child: Text(s.buttonResetLabel),
            ),
          ],
        ],
      ),
      content: !_loaded
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModeSwitch(context),
                  const SizedBox(height: 16),
                  if (_fixedMode) _buildFixedGoal(context),
                  // The TDEE equation is fixed (IOM 2005 is what every
                  // build currently ships) but kept visible here as a
                  // read-only reference so the source of the kcal target
                  // doesn't feel hidden.
                  if (!_fixedMode)
                  DropdownButtonFormField(
                    isExpanded: true,
                    itemHeight: null,
                    decoration: InputDecoration(
                      enabled: false,
                      filled: false,
                      labelText: s.calculationsTDEELabel,
                    ),
                    items: [
                      DropdownMenuItem(
                        child: Text(
                          '${s.calculationsTDEEIOM2006Label} ${s.calculationsRecommendedLabel}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: null,
                  ),
                  // The calorie reference picker only shows for non-binary
                  // users since the male/female equations are unambiguous
                  // for binary ones — the picker has nothing to offer them.
                  if (!_fixedMode &&
                      _user?.gender == UserGenderEntity.nonBinary) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.tune_outlined),
                      title: Text(s.caloriesProfileInfoTitle),
                      subtitle: Text(
                        (_user?.caloriesProfile ??
                                CaloriesProfileEntity.averaged)
                            .getName(context),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openCaloriesProfileDialog,
                    ),
                  ],
                  if (!_fixedMode) const SizedBox(height: 24),
                  if (!_fixedMode)
                  Builder(builder: (context) {
                    final usesKj =
                        context.watch<EnergyUnitProvider>().usesKilojoules;
                    final unitLabel =
                        usesKj ? s.kjLabel : s.kcalLabel;
                    final headingLabel = usesKj
                        ? s.dailyKjAdjustmentLabel
                        : s.dailyKcalAdjustmentLabel;
                    final display = usesKj
                        ? UnitCalc.kcalToKj(_kcalAdjustment)
                        : _kcalAdjustment;
                    final displayMin = usesKj
                        ? UnitCalc.kcalToKj(_minKcalAdjustment)
                        : _minKcalAdjustment;
                    final displayMax = usesKj
                        ? UnitCalc.kcalToKj(_maxKcalAdjustment)
                        : _maxKcalAdjustment;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                headingLabel,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            SizedBox(
                              // Scale with the user's text setting so the value
                              // and unit suffix stay readable at large fonts.
                              width:
                                  MediaQuery.textScalerOf(context).scale(128),
                              child: Semantics(
                                identifier: 'kcal-adjustment-input',
                                child: TextField(
                                  controller: _kcalController,
                                  focusNode: _kcalFocusNode,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: false,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^-?\d*'),
                                    ),
                                  ],
                                  textAlign: TextAlign.right,
                                  decoration: InputDecoration(
                                    suffixText: unitLabel,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                  ),
                                  onChanged: (_) => _kcalTextEdited = true,
                                  onSubmitted: (_) => _applyKcalInput(),
                                  onEditingComplete: _applyKcalInput,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Semantics(
                          identifier: 'kcal-adjustment-slider',
                          child: Slider(
                            min: displayMin,
                            max: displayMax,
                            divisions: _kcalDivisions,
                            value: display.clamp(displayMin, displayMax),
                            label: '${display.round()} $unitLabel',
                            onChanged: (value) {
                              final asKcal = usesKj
                                  ? UnitCalc.kjToKcal(value)
                                  : value;
                              setState(() => _kcalAdjustment = asKcal);
                              _kcalController.text = value.round().toString();
                              _kcalTextEdited = false;
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogCancelLabel),
        ),
        Semantics(
          identifier: 'kcal-adjustment-save',
          child: TextButton(
            onPressed: _loaded ? _save : null,
            child: Text(s.dialogOKLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSwitch(BuildContext context) {
    final s = S.of(context);
    Widget label(String text) =>
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        identifier: 'kcal-goal-mode',
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: false,
              label: label(s.kcalGoalModeCalculatedLabel),
            ),
            ButtonSegment(value: true, label: label(s.kcalGoalModeFixedLabel)),
          ],
          selected: {_fixedMode},
          onSelectionChanged: (selection) => _setFixedMode(selection.first),
        ),
      ),
    );
  }

  Widget _buildFixedGoal(BuildContext context) {
    final s = S.of(context);
    final usesKj = context.watch<EnergyUnitProvider>().usesKilojoules;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The label sits in the field rather than beside it: a fixed-width
        // field beside a label overflowed narrow screens at large text
        // sizes, and as the field's own label it is what a screen reader
        // announces when the field gets focus.
        Semantics(
          identifier: 'kcal-goal-fixed-input',
          child: TextField(
            controller: _fixedController,
            focusNode: _fixedFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [_wholeNumberOnly],
            decoration: InputDecoration(
              labelText: s.fixedKcalGoalLabel,
              suffixText: usesKj ? s.kjLabel : s.kcalLabel,
            ),
            onChanged: (_) => _fixedTextEdited = true,
            onSubmitted: (_) => _applyFixedInput(),
            onEditingComplete: _applyFixedInput,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          s.fixedKcalGoalExplanation,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
