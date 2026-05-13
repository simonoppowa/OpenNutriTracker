import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/calories_profile_info_dialog.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
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

  // #173: per-nutrient absolute goals in grams. Stored on TrackedDayDBO,
  // not ConfigDBO — see CLAUDE.md note in the issue triage. Slider
  // ranges are picked to bracket the FDA Daily Value the panel uses as
  // its default: fibre 0–80g (DV 28g), sat fat 0–60g (DV 20g),
  // sugars 0–150g (DV 50g, with headroom for "treat" days).
  static const double _fibreMin = 0;
  static const double _fibreMax = 80;
  static const int _fibreDivisions = 80;
  static const double _satFatMin = 0;
  static const double _satFatMax = 60;
  static const int _satFatDivisions = 60;
  static const double _sugarsMin = 0;
  static const double _sugarsMax = 150;
  static const int _sugarsDivisions = 150;

  // Loaded from today's TrackedDayDBO when the dialog opens. Null means
  // "no override" — the user hasn't set a goal yet, so the slider sits
  // at the default reference and is treated as un-set when saving.
  double? _fibreGoalGrams;
  double? _satFatGoalGrams;
  double? _sugarsGoalGrams;

  // #297: Text controllers for direct input
  late TextEditingController _kcalAdjustmentController;
  late TextEditingController _carbsController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  // #173: text controllers for the new gram-target inputs
  late TextEditingController _fibreController;
  late TextEditingController _satFatController;
  late TextEditingController _sugarsController;

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
    // #173: nutrient-goal controllers start at the default reference so
    // the user sees a sensible value before they touch anything.
    _fibreController = TextEditingController(
      text: DailyNutrientPanel.defaultFibreRefG.round().toString(),
    );
    _satFatController = TextEditingController(
      text: DailyNutrientPanel.defaultSaturatedFatRefG.round().toString(),
    );
    _sugarsController = TextEditingController(
      text: DailyNutrientPanel.defaultSugarRefG.round().toString(),
    );
  }

  @override
  void dispose() {
    _kcalAdjustmentController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _fibreController.dispose();
    _satFatController.dispose();
    _sugarsController.dispose();
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
    // #173: pre-fill the new sliders from today's TrackedDayDBO so the
    // user picks up where they left off rather than seeing defaults
    // every time the dialog opens.
    final today =
        await widget.settingsBloc.getTodayTrackedDay(DateTime.now());

    setState(() {
      _kcalAdjustmentSelection = kcalAdjustment;
      _carbsPctSelection = (userCarbsPct ?? _defaultCarbsPctSelection) * 100;
      _proteinPctSelection =
          (userProteinPct ?? _defaultProteinPctSelection) * 100;
      _fatPctSelection = (userFatPct ?? _defaultFatPctSelection) * 100;
      _fibreGoalGrams = today?.fibreGoal;
      _satFatGoalGrams = today?.satFatGoal;
      _sugarsGoalGrams = today?.sugarsGoal;
      _user = user;
    });
    _kcalAdjustmentController.text =
        _kcalAdjustmentSelection.round().toString();
    _carbsController.text = _carbsPctSelection.round().toString();
    _proteinController.text = _proteinPctSelection.round().toString();
    _fatController.text = _fatPctSelection.round().toString();
    _fibreController.text =
        (_fibreGoalGrams ?? DailyNutrientPanel.defaultFibreRefG)
            .round()
            .toString();
    _satFatController.text =
        (_satFatGoalGrams ?? DailyNutrientPanel.defaultSaturatedFatRefG)
            .round()
            .toString();
    _sugarsController.text =
        (_sugarsGoalGrams ?? DailyNutrientPanel.defaultSugarRefG)
            .round()
            .toString();
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
                // #173: reset clears any nutrient overrides so the
                // panel goes back to the built-in default references.
                _fibreGoalGrams = null;
                _satFatGoalGrams = null;
                _sugarsGoalGrams = null;
              });
              _kcalAdjustmentController.text = '0';
              _syncControllersToState();
              _fibreController.text =
                  DailyNutrientPanel.defaultFibreRefG.round().toString();
              _satFatController.text = DailyNutrientPanel.defaultSaturatedFatRefG
                  .round()
                  .toString();
              _sugarsController.text =
                  DailyNutrientPanel.defaultSugarRefG.round().toString();
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
            // #173: per-nutrient gram targets. These persist on today's
            // TrackedDayDBO row (fibre / sat-fat / sugars columns) and
            // the diary panel uses them as reference values when set.
            const SizedBox(height: 16),
            Text(
              S.of(context).settingsNutrientGoalsLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              S.of(context).settingsNutrientGoalsHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _buildNutrientRow(
              label: S.of(context).settingsFibreGoalLabel,
              description: S.of(context).settingsFibreGoalDescription,
              value: _fibreGoalGrams ?? DailyNutrientPanel.defaultFibreRefG,
              min: _fibreMin,
              max: _fibreMax,
              divisions: _fibreDivisions,
              controller: _fibreController,
              onSliderChanged: (v) => setState(() => _fibreGoalGrams = v),
              onTextSubmitted: () => _applyDirectNutrientInput(
                _fibreController,
                _fibreMin,
                _fibreMax,
                (v) => _fibreGoalGrams = v,
              ),
            ),
            _buildNutrientRow(
              label: S.of(context).settingsSaturatedFatGoalLabel,
              description: S.of(context).settingsSaturatedFatGoalDescription,
              value: _satFatGoalGrams ??
                  DailyNutrientPanel.defaultSaturatedFatRefG,
              min: _satFatMin,
              max: _satFatMax,
              divisions: _satFatDivisions,
              controller: _satFatController,
              onSliderChanged: (v) => setState(() => _satFatGoalGrams = v),
              onTextSubmitted: () => _applyDirectNutrientInput(
                _satFatController,
                _satFatMin,
                _satFatMax,
                (v) => _satFatGoalGrams = v,
              ),
            ),
            _buildNutrientRow(
              label: S.of(context).settingsSugarsGoalLabel,
              description: S.of(context).settingsSugarsGoalDescription,
              value: _sugarsGoalGrams ?? DailyNutrientPanel.defaultSugarRefG,
              min: _sugarsMin,
              max: _sugarsMax,
              divisions: _sugarsDivisions,
              controller: _sugarsController,
              onSliderChanged: (v) => setState(() => _sugarsGoalGrams = v),
              onTextSubmitted: () => _applyDirectNutrientInput(
                _sugarsController,
                _sugarsMin,
                _sugarsMax,
                (v) => _sugarsGoalGrams = v,
              ),
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

  /// #173: render a single fibre / sat-fat / sugars row. Mirrors the
  /// macro row layout — a label, an editable text field for direct
  /// entry, and a slider underneath — but operates in grams and writes
  /// to a nullable goal value rather than redistributing percentages.
  Widget _buildNutrientRow({
    required String label,
    required String description,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required TextEditingController controller,
    required ValueChanged<double> onSliderChanged,
    required VoidCallback onTextSubmitted,
  }) {
    final clamped = value.clamp(min, max);
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    suffixText: 'g',
                    isDense: true,
                  ),
                  onSubmitted: (_) => onTextSubmitted(),
                  onEditingComplete: onTextSubmitted,
                ),
              ),
            ],
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ),
          Slider(
            min: min,
            max: max,
            value: clamped,
            divisions: divisions,
            onChanged: (v) {
              final rounded = v.roundToDouble();
              controller.text = rounded.round().toString();
              onSliderChanged(rounded);
            },
          ),
        ],
      ),
    );
  }

  /// #173: apply a directly typed gram value for a nutrient goal,
  /// clamping into the slider's valid range. Invalid input reverts to
  /// the previously stored value (or the default if none).
  void _applyDirectNutrientInput(
    TextEditingController controller,
    double min,
    double max,
    void Function(double) setter,
  ) {
    final parsed = int.tryParse(controller.text);
    if (parsed == null) {
      // Revert to current state; setter remains untouched.
      return;
    }
    final clamped = parsed.clamp(min.toInt(), max.toInt()).toDouble();
    setState(() => setter(clamped));
    controller.text = clamped.round().toString();
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

  void _saveCalculationSettings() async {
    // Flush any pending text input before saving
    _applyKcalInput();
    _applyDirectMacroInput(_carbsController, (v) => _carbsPctSelection = v);
    _applyDirectMacroInput(_proteinController, (v) => _proteinPctSelection = v);
    _applyDirectMacroInput(_fatController, (v) => _fatPctSelection = v);
    _normalizeMacros();
    // #173: flush nutrient inputs too. These are independent of the
    // macro normalization above — they're gram values, not percentages.
    _applyDirectNutrientInput(
      _fibreController,
      _fibreMin,
      _fibreMax,
      (v) => _fibreGoalGrams = v,
    );
    _applyDirectNutrientInput(
      _satFatController,
      _satFatMin,
      _satFatMax,
      (v) => _satFatGoalGrams = v,
    );
    _applyDirectNutrientInput(
      _sugarsController,
      _sugarsMin,
      _sugarsMax,
      (v) => _sugarsGoalGrams = v,
    );

    widget.settingsBloc.setKcalAdjustment(_kcalAdjustmentSelection.toInt().toDouble());
    widget.settingsBloc.setMacroGoals(
      _carbsPctSelection,
      _proteinPctSelection,
      _fatPctSelection,
    );

    widget.settingsBloc.add(LoadSettingsEvent());
    widget.profileBloc.add(LoadProfileEvent());
    widget.homeBloc.add(LoadItemsEvent());
    // updateTrackedDay either creates today's row from current goals or
    // refreshes the macro columns on the existing one. Either way the
    // row exists by the time we write the nutrient goals against it.
    await widget.settingsBloc.updateTrackedDay(DateTime.now());
    // #173: persist the nutrient goals onto today's TrackedDayDBO row.
    await widget.settingsBloc.setTodayNutrientGoals(
      DateTime.now(),
      fibreGoal: _fibreGoalGrams,
      satFatGoal: _satFatGoalGrams,
      sugarsGoal: _sugarsGoalGrams,
    );
    widget.diaryBloc.add(LoadDiaryYearEvent());
    widget.calendarDayBloc.add(RefreshCalendarDayEvent());

    if (mounted) {
      Navigator.of(context).pop();
    }
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
