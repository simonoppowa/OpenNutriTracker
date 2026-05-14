import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/meal_pattern_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/calories_profile_info_dialog.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class CalculationsDialog extends StatefulWidget {
  final SettingsBloc settingsBloc;
  final ProfileBloc profileBloc;
  final HomeBloc homeBloc;
  final DiaryBloc diaryBloc;
  final CalendarDayBloc calendarDayBloc;

  const CalculationsDialog({
    super.key,
    required this.settingsBloc,
    required this.profileBloc,
    required this.homeBloc,
    required this.diaryBloc,
    required this.calendarDayBloc,
  });

  @override
  State<CalculationsDialog> createState() => _CalculationsDialogState();
}

class _CalculationsDialogState extends State<CalculationsDialog> {
  static const double _maxKcalAdjustment = 1000;
  static const double _minKcalAdjustment = -1000;
  static const int _kcalDivisions = 200;
  double _kcalAdjustmentSelection = 0;

  static const double _defaultCarbsPctSelection = 0.6;
  static const double _defaultFatPctSelection = 0.25;
  static const double _defaultProteinPctSelection = 0.15;

  double _carbsPctSelection = _defaultCarbsPctSelection * 100;
  double _proteinPctSelection = _defaultProteinPctSelection * 100;
  double _fatPctSelection = _defaultFatPctSelection * 100;

  // #297: Text controllers for direct input
  late TextEditingController _kcalAdjustmentController;
  late TextEditingController _carbsController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;

  // #150: per-meal kcal share sliders. Stored as doubles so the slider can
  // hand back fractional values mid-drag; we round and re-balance against
  // 100 on every change.
  double _breakfastSharePct =
      (ConfigEntity.defaultMealKcalSharesPct[ConfigEntity.mealKeyBreakfast]!)
          .toDouble();
  double _lunchSharePct =
      (ConfigEntity.defaultMealKcalSharesPct[ConfigEntity.mealKeyLunch]!)
          .toDouble();
  double _dinnerSharePct =
      (ConfigEntity.defaultMealKcalSharesPct[ConfigEntity.mealKeyDinner]!)
          .toDouble();
  double _snackSharePct =
      (ConfigEntity.defaultMealKcalSharesPct[ConfigEntity.mealKeySnack]!)
          .toDouble();

  UserEntity? _user;

  @override
  void initState() {
    super.initState();
    _kcalAdjustmentController =
        TextEditingController(text: _kcalAdjustmentSelection.round().toString());
    _carbsController =
        TextEditingController(text: _carbsPctSelection.round().toString());
    _proteinController =
        TextEditingController(text: _proteinPctSelection.round().toString());
    _fatController =
        TextEditingController(text: _fatPctSelection.round().toString());
  }

  @override
  void dispose() {
    _kcalAdjustmentController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeKcalAdjustment();
  }

  void _initializeKcalAdjustment() async {
    final kcalAdjustment = await widget.settingsBloc.getKcalAdjustment() * 1.0;
    final userCarbsPct = await widget.settingsBloc.getUserCarbGoalPct();
    final userProteinPct = await widget.settingsBloc.getUserProteinGoalPct();
    final userFatPct = await widget.settingsBloc.getUserFatGoalPct();
    final user = await widget.profileBloc.getUser();
    // #150: load existing per-meal kcal share so the sliders open at the
    // user's current setting rather than the defaults each time.
    final mealShares = await widget.settingsBloc.getMealKcalSharesPct();

    setState(() {
      _kcalAdjustmentSelection = kcalAdjustment;
      _carbsPctSelection = (userCarbsPct ?? _defaultCarbsPctSelection) * 100;
      _proteinPctSelection =
          (userProteinPct ?? _defaultProteinPctSelection) * 100;
      _fatPctSelection = (userFatPct ?? _defaultFatPctSelection) * 100;
      _breakfastSharePct =
          (mealShares[ConfigEntity.mealKeyBreakfast] ?? 30).toDouble();
      _lunchSharePct =
          (mealShares[ConfigEntity.mealKeyLunch] ?? 40).toDouble();
      _dinnerSharePct =
          (mealShares[ConfigEntity.mealKeyDinner] ?? 20).toDouble();
      _snackSharePct =
          (mealShares[ConfigEntity.mealKeySnack] ?? 10).toDouble();
      _user = user;
    });
    _kcalAdjustmentController.text =
        _kcalAdjustmentSelection.round().toString();
    _carbsController.text = _carbsPctSelection.round().toString();
    _proteinController.text = _proteinPctSelection.round().toString();
    _fatController.text = _fatPctSelection.round().toString();
  }

  void _syncControllersToState() {
    _carbsController.text = _carbsPctSelection.round().toString();
    _proteinController.text = _proteinPctSelection.round().toString();
    _fatController.text = _fatPctSelection.round().toString();
  }

  /// #297: Apply a directly typed macro percentage for one macro,
  /// leaving the others unchanged (normalization happens on save).
  void _applyDirectMacroInput(
      TextEditingController controller, void Function(double) setter) {
    final parsed = int.tryParse(controller.text);
    if (parsed == null || parsed < 5 || parsed > 90) {
      // Revert to last valid state
      _syncControllersToState();
      return;
    }
    setState(() => setter(parsed.toDouble()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              S.of(context).settingsCalculationsLabel,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            child: Text(S.of(context).buttonResetLabel),
            onPressed: () {
              setState(() {
                _kcalAdjustmentSelection = 0;
                _carbsPctSelection = _defaultCarbsPctSelection * 100;
                _proteinPctSelection = _defaultProteinPctSelection * 100;
                _fatPctSelection = _defaultFatPctSelection * 100;
                // #150: also restore the recommended meal-share defaults.
                _breakfastSharePct =
                    (ConfigEntity.defaultMealKcalSharesPct[
                        ConfigEntity.mealKeyBreakfast]!).toDouble();
                _lunchSharePct =
                    (ConfigEntity.defaultMealKcalSharesPct[
                        ConfigEntity.mealKeyLunch]!).toDouble();
                _dinnerSharePct =
                    (ConfigEntity.defaultMealKcalSharesPct[
                        ConfigEntity.mealKeyDinner]!).toDouble();
                _snackSharePct =
                    (ConfigEntity.defaultMealKcalSharesPct[
                        ConfigEntity.mealKeySnack]!).toDouble();
              });
              _kcalAdjustmentController.text = '0';
              _syncControllersToState();
            },
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField(
              isExpanded: true,
              decoration: InputDecoration(
                enabled: false,
                filled: false,
                labelText: S.of(context).calculationsTDEELabel,
              ),
              items: [
                DropdownMenuItem(
                  child: Text(
                    '${S.of(context).calculationsTDEEIOM2006Label} ${S.of(context).calculationsRecommendedLabel}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: null,
            ),
            const SizedBox(height: 32),
            if (_user?.gender == UserGenderEntity.nonBinary) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tune_outlined),
                title: Text(S.of(context).caloriesProfileInfoTitle),
                subtitle: Text(
                  (_user?.caloriesProfile ?? CaloriesProfileEntity.averaged)
                      .getName(context),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openCaloriesProfileDialog,
              ),
              const SizedBox(height: 8),
            ],
            // ── Kcal adjustment ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context).dailyKcalAdjustmentLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                // #297: Direct text input for kcal adjustment
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _kcalAdjustmentController,
                    keyboardType: const TextInputType.numberWithOptions(
                        signed: true, decimal: false),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                    ],
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      suffixText: S.of(context).kcalLabel,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _applyKcalInput(),
                    onEditingComplete: _applyKcalInput,
                  ),
                ),
              ],
            ),
            Slider(
              min: _minKcalAdjustment,
              max: _maxKcalAdjustment,
              divisions: _kcalDivisions,
              value: _kcalAdjustmentSelection,
              label: '${_kcalAdjustmentSelection.round()} ${S.of(context).kcalLabel}',
              onChanged: (value) {
                setState(() => _kcalAdjustmentSelection = value);
                _kcalAdjustmentController.text = value.round().toString();
              },
            ),
            const SizedBox(height: 16),
            // ── Macro distribution ───────────────────────────────────────────
            Text(
              S.of(context).macroDistributionLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // #297: hint that text fields allow direct entry
            Text(
              '${_carbsPctSelection.round() + _proteinPctSelection.round() + _fatPctSelection.round()}% total',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _buildMacroRow(
              S.of(context).carbsLabel,
              _carbsPctSelection,
              Colors.orange,
              _carbsController,
              onSliderChanged: (value) {
                setState(() {
                  double delta = value - _carbsPctSelection;
                  _carbsPctSelection = value;
                  double proteinRatio = _proteinPctSelection /
                      (_proteinPctSelection + _fatPctSelection);
                  double fatRatio = _fatPctSelection /
                      (_proteinPctSelection + _fatPctSelection);
                  _proteinPctSelection -= delta * proteinRatio;
                  _fatPctSelection -= delta * fatRatio;
                  if (_proteinPctSelection < 5) {
                    _fatPctSelection -= 5 - _proteinPctSelection;
                    _proteinPctSelection = 5;
                  }
                  if (_fatPctSelection < 5) {
                    _proteinPctSelection -= 5 - _fatPctSelection;
                    _fatPctSelection = 5;
                  }
                });
                _syncControllersToState();
              },
              onTextSubmitted: () => _applyDirectMacroInput(
                  _carbsController, (v) => _carbsPctSelection = v),
            ),
            _buildMacroRow(
              S.of(context).proteinLabel,
              _proteinPctSelection,
              Colors.blue,
              _proteinController,
              onSliderChanged: (value) {
                setState(() {
                  double delta = value - _proteinPctSelection;
                  _proteinPctSelection = value;
                  double carbsRatio = _carbsPctSelection /
                      (_carbsPctSelection + _fatPctSelection);
                  double fatRatio = _fatPctSelection /
                      (_carbsPctSelection + _fatPctSelection);
                  _carbsPctSelection -= delta * carbsRatio;
                  _fatPctSelection -= delta * fatRatio;
                  if (_carbsPctSelection < 5) {
                    _fatPctSelection -= 5 - _carbsPctSelection;
                    _carbsPctSelection = 5;
                  }
                  if (_fatPctSelection < 5) {
                    _carbsPctSelection -= 5 - _fatPctSelection;
                    _fatPctSelection = 5;
                  }
                });
                _syncControllersToState();
              },
              onTextSubmitted: () => _applyDirectMacroInput(
                  _proteinController, (v) => _proteinPctSelection = v),
            ),
            _buildMacroRow(
              S.of(context).fatLabel,
              _fatPctSelection,
              Colors.green,
              _fatController,
              onSliderChanged: (value) {
                setState(() {
                  double delta = value - _fatPctSelection;
                  _fatPctSelection = value;
                  double carbsRatio = _carbsPctSelection /
                      (_carbsPctSelection + _proteinPctSelection);
                  double proteinRatio = _proteinPctSelection /
                      (_carbsPctSelection + _proteinPctSelection);
                  _carbsPctSelection -= delta * carbsRatio;
                  _proteinPctSelection -= delta * proteinRatio;
                  if (_carbsPctSelection < 5) {
                    _proteinPctSelection -= 5 - _carbsPctSelection;
                    _carbsPctSelection = 5;
                  }
                  if (_proteinPctSelection < 5) {
                    _carbsPctSelection -= 5 - _proteinPctSelection;
                    _proteinPctSelection = 5;
                  }
                });
                _syncControllersToState();
              },
              onTextSubmitted: () => _applyDirectMacroInput(
                  _fatController, (v) => _fatPctSelection = v),
            ),
            // ── #150 Per-meal kcal share ────────────────────────────────────
            const SizedBox(height: 24),
            Text(
              S.of(context).settingsPerMealKcalShareLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              S.of(context).settingsPerMealKcalShareDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            // #150 follow-up: preset chips. One tap fills the four sliders;
            // users can still nudge things afterward. Useful for IF/OMAD
            // routines that don't fit the four-meal frame.
            Text(
              S.of(context).mealPatternPresetsLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final pattern in MealPatternEntity.values)
                  Semantics(
                    identifier: 'calculations-meal-pattern-${pattern.id}',
                    child: OutlinedButton(
                      onPressed: () => _applyMealPattern(pattern),
                      child: Text(_mealPatternLabel(context, pattern)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_breakfastSharePct.round() + _lunchSharePct.round() + _dinnerSharePct.round() + _snackSharePct.round()}% total',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _buildMealShareRow(
              S.of(context).settingsPerMealKcalShareBreakfast,
              _breakfastSharePct,
              (value) => _rebalanceMealShares(
                changedMeal: ConfigEntity.mealKeyBreakfast,
                newValue: value,
              ),
              identifier: 'calculations-meal-share-breakfast',
            ),
            _buildMealShareRow(
              S.of(context).settingsPerMealKcalShareLunch,
              _lunchSharePct,
              (value) => _rebalanceMealShares(
                changedMeal: ConfigEntity.mealKeyLunch,
                newValue: value,
              ),
              identifier: 'calculations-meal-share-lunch',
            ),
            _buildMealShareRow(
              S.of(context).settingsPerMealKcalShareDinner,
              _dinnerSharePct,
              (value) => _rebalanceMealShares(
                changedMeal: ConfigEntity.mealKeyDinner,
                newValue: value,
              ),
              identifier: 'calculations-meal-share-dinner',
            ),
            _buildMealShareRow(
              S.of(context).settingsPerMealKcalShareSnack,
              _snackSharePct,
              (value) => _rebalanceMealShares(
                changedMeal: ConfigEntity.mealKeySnack,
                newValue: value,
              ),
              identifier: 'calculations-meal-share-snack',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          onPressed: _saveCalculationSettings,
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }

  void _applyKcalInput() {
    final parsed = int.tryParse(_kcalAdjustmentController.text);
    if (parsed == null) {
      _kcalAdjustmentController.text =
          _kcalAdjustmentSelection.round().toString();
      return;
    }
    final clamped =
        parsed.clamp(_minKcalAdjustment.toInt(), _maxKcalAdjustment.toInt());
    setState(() => _kcalAdjustmentSelection = clamped.toDouble());
    _kcalAdjustmentController.text = clamped.toString();
  }

  Widget _buildMacroRow(
    String label,
    double value,
    Color color,
    TextEditingController controller, {
    required ValueChanged<double> onSliderChanged,
    required VoidCallback onTextSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            // #297: editable text field for direct % input
            SizedBox(
              width: 60,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  suffixText: '%',
                  isDense: true,
                ),
                onSubmitted: (_) => onTextSubmitted(),
                onEditingComplete: onTextSubmitted,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
          ),
          child: Slider(
            min: 5,
            max: 90,
            value: value.clamp(5, 90),
            divisions: 85,
            onChanged: (v) {
              final rounded = v.round().toDouble();
              if (100 - rounded >= 10) {
                onSliderChanged(rounded);
              }
            },
          ),
        ),
      ],
    );
  }

  /// #150: build a single per-meal share row (label, % text, slider). Sliders
  /// emit integer percentages between 0 and 100; the rebalance keeps the
  /// remaining three rows summing to 100 with the changed value held fixed.
  Widget _buildMealShareRow(
    String label,
    double value,
    ValueChanged<double> onSliderChanged, {
    required String identifier,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('${value.round()}%'),
          ],
        ),
        Semantics(
          identifier: identifier,
          child: Slider(
            min: 0,
            max: 100,
            value: value.clamp(0, 100),
            divisions: 100,
            onChanged: (v) => onSliderChanged(v.roundToDouble()),
          ),
        ),
      ],
    );
  }

  /// #150: hold [changedMeal] at [newValue] and redistribute what remains
  /// across the other three meals proportional to their current shares. Falls
  /// back to an even split when the other three are all zero.
  void _rebalanceMealShares({
    required String changedMeal,
    required double newValue,
  }) {
    final clamped = newValue.clamp(0, 100).toDouble();
    final shares = {
      ConfigEntity.mealKeyBreakfast: _breakfastSharePct,
      ConfigEntity.mealKeyLunch: _lunchSharePct,
      ConfigEntity.mealKeyDinner: _dinnerSharePct,
      ConfigEntity.mealKeySnack: _snackSharePct,
    };
    shares[changedMeal] = clamped;

    final others = shares.keys.where((k) => k != changedMeal).toList();
    final remaining = 100 - clamped;
    final othersTotal = others.fold<double>(0, (acc, k) => acc + shares[k]!);

    if (remaining <= 0) {
      for (final k in others) {
        shares[k] = 0;
      }
    } else if (othersTotal == 0) {
      final even = remaining / others.length;
      for (final k in others) {
        shares[k] = even;
      }
    } else {
      for (final k in others) {
        shares[k] = (shares[k]! / othersTotal) * remaining;
      }
    }

    // Round to integers and patch the largest "other" to absorb any drift.
    final rounded = {for (final k in shares.keys) k: shares[k]!.round()};
    final drift = 100 - rounded.values.fold<int>(0, (a, b) => a + b);
    if (drift != 0) {
      final adjustTarget = others.reduce(
        (a, b) => (rounded[a]! >= rounded[b]!) ? a : b,
      );
      rounded[adjustTarget] = rounded[adjustTarget]! + drift;
    }

    setState(() {
      _breakfastSharePct = rounded[ConfigEntity.mealKeyBreakfast]!.toDouble();
      _lunchSharePct = rounded[ConfigEntity.mealKeyLunch]!.toDouble();
      _dinnerSharePct = rounded[ConfigEntity.mealKeyDinner]!.toDouble();
      _snackSharePct = rounded[ConfigEntity.mealKeySnack]!.toDouble();
    });
  }

  /// #150 follow-up: drop the preset's percentages straight into the four
  /// sliders. No rebalancing — every preset is already authored to sum to 100.
  void _applyMealPattern(MealPatternEntity pattern) {
    setState(() {
      _breakfastSharePct = pattern.breakfastPct.toDouble();
      _lunchSharePct = pattern.lunchPct.toDouble();
      _dinnerSharePct = pattern.dinnerPct.toDouble();
      _snackSharePct = pattern.snackPct.toDouble();
    });
  }

  String _mealPatternLabel(BuildContext context, MealPatternEntity pattern) {
    switch (pattern) {
      case MealPatternEntity.standard:
        return S.of(context).mealPatternStandard;
      case MealPatternEntity.mediterranean:
        return S.of(context).mealPatternMediterranean;
      case MealPatternEntity.twoMeal:
        return S.of(context).mealPatternTwoMeal;
      case MealPatternEntity.omad:
        return S.of(context).mealPatternOmad;
      case MealPatternEntity.fiveSmall:
        return S.of(context).mealPatternFiveSmall;
    }
  }

  void _normalizeMacros() {
    _carbsPctSelection = _carbsPctSelection.roundToDouble();
    _proteinPctSelection = _proteinPctSelection.roundToDouble();
    _fatPctSelection = _fatPctSelection.roundToDouble();

    double total =
        _carbsPctSelection + _proteinPctSelection + _fatPctSelection;

    if (total != 100) {
      double factor = 100 / total;
      _carbsPctSelection = (_carbsPctSelection * factor).roundToDouble();
      _proteinPctSelection = (_proteinPctSelection * factor).roundToDouble();
      _fatPctSelection = 100 - _carbsPctSelection - _proteinPctSelection;
      if (_fatPctSelection < 5) {
        _fatPctSelection = 5;
        double remaining = 95;
        double ratio =
            _carbsPctSelection / (_carbsPctSelection + _proteinPctSelection);
        _carbsPctSelection = (remaining * ratio).roundToDouble();
        _proteinPctSelection = remaining - _carbsPctSelection;
      }
    }
  }

  void _saveCalculationSettings() {
    // Flush any pending text input before saving
    _applyKcalInput();
    _applyDirectMacroInput(_carbsController, (v) => _carbsPctSelection = v);
    _applyDirectMacroInput(_proteinController, (v) => _proteinPctSelection = v);
    _applyDirectMacroInput(_fatController, (v) => _fatPctSelection = v);
    _normalizeMacros();

    widget.settingsBloc.setKcalAdjustment(_kcalAdjustmentSelection.toInt().toDouble());
    widget.settingsBloc.setMacroGoals(
      _carbsPctSelection,
      _proteinPctSelection,
      _fatPctSelection,
    );

    // #150: persist the four meal-share percentages alongside macro goals.
    widget.settingsBloc.setMealKcalSharesPct({
      ConfigEntity.mealKeyBreakfast: _breakfastSharePct.round(),
      ConfigEntity.mealKeyLunch: _lunchSharePct.round(),
      ConfigEntity.mealKeyDinner: _dinnerSharePct.round(),
      ConfigEntity.mealKeySnack: _snackSharePct.round(),
    });

    widget.settingsBloc.add(LoadSettingsEvent());
    widget.profileBloc.add(LoadProfileEvent());
    widget.homeBloc.add(LoadItemsEvent());
    widget.settingsBloc.updateTrackedDay(DateTime.now());
    widget.diaryBloc.add(LoadDiaryYearEvent());
    widget.calendarDayBloc.add(RefreshCalendarDayEvent());

    Navigator.of(context).pop();
  }

  Future<void> _openCaloriesProfileDialog() async {
    final user = _user;
    if (user == null) return;
    final selected = await showDialog<CaloriesProfileEntity>(
      context: context,
      builder: (context) => CaloriesProfileInfoDialog(
        initialProfile:
            user.caloriesProfile ?? CaloriesProfileEntity.averaged,
      ),
    );
    if (selected == null) return;
    user.caloriesProfile = selected;
    await widget.profileBloc.updateUser(user);
    if (!mounted) return;
    setState(() {
      _user = user;
    });
  }
}
