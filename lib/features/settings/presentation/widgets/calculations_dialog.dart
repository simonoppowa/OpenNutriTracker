import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/calories_profile_info_dialog.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
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

  // #173: per-nutrient absolute goals. Stored on TrackedDayDBO, not
  // ConfigDBO — see CLAUDE.md note in the issue triage. Slider ranges
  // are picked to bracket the FDA Daily Value the panel uses as its
  // default. Units match the DBO convention: g for the first three;
  // mg for sodium/calcium/iron/potassium/magnesium/B12; µg for D.
  //
  // (B12 is conventionally reported in µg too; both B12 and D use µg
  // here even though they live alongside mg fields on the DBO. The
  // DBO comment is the source of truth for storage units; this UI is
  // free to use whichever unit makes sense for each row.)
  static const double _fibreMin = 0;
  static const double _fibreMax = 80;
  static const int _fibreDivisions = 80;
  static const double _satFatMin = 0;
  static const double _satFatMax = 60;
  static const int _satFatDivisions = 60;
  static const double _sugarsMin = 0;
  static const double _sugarsMax = 150;
  static const int _sugarsDivisions = 150;
  // Follow-up to #173: ranges for the remaining seven panel nutrients.
  static const double _sodiumMin = 0;
  static const double _sodiumMax = 3000;
  static const int _sodiumDivisions = 60; // 50mg steps
  static const double _calciumMin = 0;
  static const double _calciumMax = 1500;
  static const int _calciumDivisions = 60; // 25mg steps
  static const double _ironMin = 0;
  static const double _ironMax = 30;
  static const int _ironDivisions = 60; // 0.5mg steps
  static const double _potassiumMin = 0;
  static const double _potassiumMax = 5000;
  static const int _potassiumDivisions = 100; // 50mg steps
  static const double _magnesiumMin = 0;
  static const double _magnesiumMax = 600;
  static const int _magnesiumDivisions = 60; // 10mg steps
  static const double _vitaminDMin = 0;
  static const double _vitaminDMax = 50;
  static const int _vitaminDDivisions = 100; // 0.5µg steps
  static const double _vitaminB12Min = 0;
  static const double _vitaminB12Max = 10;
  static const int _vitaminB12Divisions = 100; // 0.1µg steps

  // Loaded from today's TrackedDayDBO when the dialog opens. Null means
  // "no override" — the user hasn't set a goal yet, so the slider sits
  // at the default reference and is treated as un-set when saving.
  double? _fibreGoalGrams;
  double? _satFatGoalGrams;
  double? _sugarsGoalGrams;
  // Follow-up to #173: per-nutrient targets in the unit declared above.
  double? _sodiumGoalMg;
  double? _calciumGoalMg;
  double? _ironGoalMg;
  double? _potassiumGoalMg;
  double? _magnesiumGoalMg;
  double? _vitaminDGoalUg;
  double? _vitaminB12GoalUg;

  // #297: Text controllers for direct input
  late TextEditingController _kcalAdjustmentController;
  late TextEditingController _carbsController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  // #119: Target weight is editable as a free-text numeric field. We
  // keep the value as a nullable double on the user entity; an empty
  // input clears the stored target.
  late TextEditingController _targetWeightController;
  // #173: text controllers for the new gram-target inputs
  late TextEditingController _fibreController;
  late TextEditingController _satFatController;
  late TextEditingController _sugarsController;
  // Follow-up to #173: text controllers for the seven additional
  // nutrient inputs (sodium, calcium, iron, potassium, magnesium,
  // vitamin D, vitamin B12).
  late TextEditingController _sodiumController;
  late TextEditingController _calciumController;
  late TextEditingController _ironController;
  late TextEditingController _potassiumController;
  late TextEditingController _magnesiumController;
  late TextEditingController _vitaminDController;
  late TextEditingController _vitaminB12Controller;

  UserEntity? _user;
  bool _usesImperialUnits = false;
  // #119 follow-up: opt-in taper that scales the daily kcal deficit
  // down as current weight approaches the target. Defaults to off.
  bool _caloriesTaperEnabled = false;

  /// Follow-up to #173: iron's DRI splits female 18 / male 8 (mg).
  /// We pick 14 as a gender-neutral midpoint for non-binary / unknown
  /// users — matches the panel's existing `_ironRefForGender` fallback.
  double _ironDefaultForGender() {
    switch (_user?.gender) {
      case UserGenderEntity.female:
        return 18.0;
      case UserGenderEntity.male:
        return 8.0;
      case UserGenderEntity.nonBinary:
      case null:
        return 14.0;
    }
  }

  /// Follow-up to #173: magnesium DRI is gender-aware too — 400mg for
  /// adult males, 310mg for adult females. Non-binary / unknown picks
  /// the midpoint at 355mg so neither group is misled.
  double _magnesiumDefaultForGender() {
    switch (_user?.gender) {
      case UserGenderEntity.female:
        return 310.0;
      case UserGenderEntity.male:
        return 400.0;
      case UserGenderEntity.nonBinary:
      case null:
        return 355.0;
    }
  }

  String _formatGoal(double value) {
    // Show integer for values >= 10, one decimal otherwise — matches
    // the panel's own formatting so the dialog and panel agree.
    return value >= 10 ? value.round().toString() : value.toStringAsFixed(1);
  }

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
    _targetWeightController = TextEditingController();
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
    // Follow-up to #173: prime the new controllers with the same
    // default references the panel uses so the slider position and
    // the text input agree before the user types anything.
    _sodiumController = TextEditingController(
      text: DailyNutrientPanel.defaultSodiumRefMg.round().toString(),
    );
    _calciumController = TextEditingController(
      text: DailyNutrientPanel.defaultCalciumRefMg.round().toString(),
    );
    _ironController = TextEditingController(
      text: _formatGoal(_ironDefaultForGender()),
    );
    _potassiumController = TextEditingController(
      text: DailyNutrientPanel.defaultPotassiumRefMg.round().toString(),
    );
    _magnesiumController = TextEditingController(
      text: _formatGoal(_magnesiumDefaultForGender()),
    );
    _vitaminDController = TextEditingController(
      text: _formatGoal(DailyNutrientPanel.defaultVitaminDRefUg),
    );
    _vitaminB12Controller = TextEditingController(
      text: _formatGoal(DailyNutrientPanel.defaultVitaminB12RefUg),
    );
  }

  @override
  void dispose() {
    _kcalAdjustmentController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _targetWeightController.dispose();
    _fibreController.dispose();
    _satFatController.dispose();
    _sugarsController.dispose();
    _sodiumController.dispose();
    _calciumController.dispose();
    _ironController.dispose();
    _potassiumController.dispose();
    _magnesiumController.dispose();
    _vitaminDController.dispose();
    _vitaminB12Controller.dispose();
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
    // #119: Read the unit preference once, on dialog open. The settings
    // screen has already loaded its state by the time this dialog can be
    // pushed, so reading from the bloc's state avoids a second async hop.
    final settingsState = widget.settingsBloc.state;
    final usesImperialUnits = settingsState is SettingsLoadedState
        ? settingsState.usesImperialUnits
        : false;
    final caloriesTaperEnabled = settingsState is SettingsLoadedState
        ? settingsState.caloriesTaperEnabled
        : false;
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
      _sodiumGoalMg = today?.sodiumGoal;
      _calciumGoalMg = today?.calciumGoal;
      _ironGoalMg = today?.ironGoal;
      _potassiumGoalMg = today?.potassiumGoal;
      _magnesiumGoalMg = today?.magnesiumGoal;
      _vitaminDGoalUg = today?.vitaminDGoal;
      _vitaminB12GoalUg = today?.vitaminB12Goal;
      _user = user;
      _usesImperialUnits = usesImperialUnits;
      _caloriesTaperEnabled = caloriesTaperEnabled;
    });
    _kcalAdjustmentController.text =
        _kcalAdjustmentSelection.round().toString();
    _carbsController.text = _carbsPctSelection.round().toString();
    _proteinController.text = _proteinPctSelection.round().toString();
    _fatController.text = _fatPctSelection.round().toString();
    // #119: Seed the target weight field from the user's stored value,
    // converted to the active unit. An empty field means "not set".
    final storedTargetKg = user.targetWeightKg;
    if (storedTargetKg != null) {
      final displayValue =
          usesImperialUnits ? UnitCalc.kgToLbs(storedTargetKg) : storedTargetKg;
      _targetWeightController.text = displayValue.toStringAsFixed(1);
    } else {
      _targetWeightController.text = '';
    }
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
    _sodiumController.text =
        (_sodiumGoalMg ?? DailyNutrientPanel.defaultSodiumRefMg)
            .round()
            .toString();
    _calciumController.text =
        (_calciumGoalMg ?? DailyNutrientPanel.defaultCalciumRefMg)
            .round()
            .toString();
    _ironController.text =
        _formatGoal(_ironGoalMg ?? _ironDefaultForGender());
    _potassiumController.text =
        (_potassiumGoalMg ?? DailyNutrientPanel.defaultPotassiumRefMg)
            .round()
            .toString();
    _magnesiumController.text =
        _formatGoal(_magnesiumGoalMg ?? _magnesiumDefaultForGender());
    _vitaminDController.text =
        _formatGoal(_vitaminDGoalUg ?? DailyNutrientPanel.defaultVitaminDRefUg);
    _vitaminB12Controller.text = _formatGoal(
      _vitaminB12GoalUg ?? DailyNutrientPanel.defaultVitaminB12RefUg,
    );
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
                // #173 (+follow-up): reset clears every nutrient
                // override so the panel goes back to the built-in
                // default references across the board.
                _fibreGoalGrams = null;
                _satFatGoalGrams = null;
                _sugarsGoalGrams = null;
                _sodiumGoalMg = null;
                _calciumGoalMg = null;
                _ironGoalMg = null;
                _potassiumGoalMg = null;
                _magnesiumGoalMg = null;
                _vitaminDGoalUg = null;
                _vitaminB12GoalUg = null;
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
              _sodiumController.text =
                  DailyNutrientPanel.defaultSodiumRefMg.round().toString();
              _calciumController.text =
                  DailyNutrientPanel.defaultCalciumRefMg.round().toString();
              _ironController.text = _formatGoal(_ironDefaultForGender());
              _potassiumController.text =
                  DailyNutrientPanel.defaultPotassiumRefMg.round().toString();
              _magnesiumController.text =
                  _formatGoal(_magnesiumDefaultForGender());
              _vitaminDController.text =
                  _formatGoal(DailyNutrientPanel.defaultVitaminDRefUg);
              _vitaminB12Controller.text =
                  _formatGoal(DailyNutrientPanel.defaultVitaminB12RefUg);
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
                  child: Semantics(
                    identifier: 'calculations-kcal-input',
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
            // ── Target weight (#119) ────────────────────────────────────────
            // A concrete target weight, paired with the existing weekly-rate
            // goal so users can see how far they are from where they want to
            // be. Calorie computation is deliberately unchanged for now — a
            // tapering adjustment as the target nears is a separate scope
            // question and would conflict with other in-flight calc work.
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context).settingsTargetWeightLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _targetWeightController,
                    keyboardType: const TextInputType.numberWithOptions(
                        signed: false, decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d{0,2}')),
                    ],
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      suffixText: _usesImperialUnits
                          ? S.of(context).lbsLabel
                          : S.of(context).kgLabel,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            // #119 follow-up: opt-in linear taper. We only surface it when
            // a target weight is set, since without one the toggle has
            // nothing to scale against. The helper line spells out the
            // shape of the curve plainly so users aren't left guessing.
            if (_user?.targetWeightKg != null) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(S.of(context).settingsCaloriesTaperLabel),
                subtitle: Text(
                  S.of(context).settingsCaloriesTaperDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: _caloriesTaperEnabled,
                onChanged: (v) => setState(() => _caloriesTaperEnabled = v),
              ),
            ],
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
              identifier: 'calculations-fibre-slider',
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
              identifier: 'calculations-sat-fat-slider',
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
              identifier: 'calculations-sugars-slider',
              onSliderChanged: (v) => setState(() => _sugarsGoalGrams = v),
              onTextSubmitted: () => _applyDirectNutrientInput(
                _sugarsController,
                _sugarsMin,
                _sugarsMax,
                (v) => _sugarsGoalGrams = v,
              ),
            ),
            // Follow-up to #173: the remaining seven panel nutrients
            // (sodium, calcium, iron, potassium, magnesium, vitamin D,
            // vitamin B12). Each one is independent of the others, so
            // setting a goal for sodium doesn't affect calcium and so
            // on. The D / B12 / Mg rows will only show up in the diary
            // panel once the #160 expansion follow-up rebases through,
            // but the values land cleanly either way.
            _buildNutrientRow(
              label: S.of(context).settingsSodiumGoalLabel,
              description: S.of(context).settingsSodiumGoalDescription,
              value: _sodiumGoalMg ?? DailyNutrientPanel.defaultSodiumRefMg,
              min: _sodiumMin,
              max: _sodiumMax,
              divisions: _sodiumDivisions,
              controller: _sodiumController,
              unit: 'mg',
              identifier: 'calculations-sodium-slider',
              onSliderChanged: (v) => setState(() => _sodiumGoalMg = v),
              onTextSubmitted: () => _applyDirectNutrientInput(
                _sodiumController,
                _sodiumMin,
                _sodiumMax,
                (v) => _sodiumGoalMg = v,
              ),
            ),
            _buildNutrientRow(
              label: S.of(context).settingsCalciumGoalLabel,
              description: S.of(context).settingsCalciumGoalDescription,
              value: _calciumGoalMg ?? DailyNutrientPanel.defaultCalciumRefMg,
              min: _calciumMin,
              max: _calciumMax,
              divisions: _calciumDivisions,
              controller: _calciumController,
              unit: 'mg',
              identifier: 'calculations-calcium-slider',
              onSliderChanged: (v) => setState(() => _calciumGoalMg = v),
              onTextSubmitted: () => _applyDirectNutrientInput(
                _calciumController,
                _calciumMin,
                _calciumMax,
                (v) => _calciumGoalMg = v,
              ),
            ),
            _buildNutrientRow(
              label: S.of(context).settingsIronGoalLabel,
              description: S.of(context).settingsIronGoalDescription,
              value: _ironGoalMg ?? _ironDefaultForGender(),
              min: _ironMin,
              max: _ironMax,
              divisions: _ironDivisions,
              controller: _ironController,
              unit: 'mg',
              decimalStep: true,
              identifier: 'calculations-iron-slider',
              onSliderChanged: (v) => setState(() => _ironGoalMg = v),
              onTextSubmitted: () => _applyDirectNutrientInput(
                _ironController,
                _ironMin,
                _ironMax,
                (v) => _ironGoalMg = v,
                decimalStep: true,
              ),
            ),
            _buildNutrientRow(
              label: S.of(context).settingsPotassiumGoalLabel,
              description: S.of(context).settingsPotassiumGoalDescription,
              value:
                  _potassiumGoalMg ?? DailyNutrientPanel.defaultPotassiumRefMg,
              min: _potassiumMin,
              max: _potassiumMax,
              divisions: _potassiumDivisions,
              controller: _potassiumController,
              unit: 'mg',
              identifier: 'calculations-potassium-slider',
              onSliderChanged: (v) => setState(() => _potassiumGoalMg = v),
              onTextSubmitted: () => _applyDirectNutrientInput(
                _potassiumController,
                _potassiumMin,
                _potassiumMax,
                (v) => _potassiumGoalMg = v,
              ),
            ),
            _buildNutrientRow(
              label: S.of(context).settingsMagnesiumGoalLabel,
              description: S.of(context).settingsMagnesiumGoalDescription,
              value: _magnesiumGoalMg ?? _magnesiumDefaultForGender(),
              min: _magnesiumMin,
              max: _magnesiumMax,
              divisions: _magnesiumDivisions,
              controller: _magnesiumController,
              unit: 'mg',
              identifier: 'calculations-magnesium-slider',
              onSliderChanged: (v) => setState(() => _magnesiumGoalMg = v),
              onTextSubmitted: () => _applyDirectNutrientInput(
                _magnesiumController,
                _magnesiumMin,
                _magnesiumMax,
                (v) => _magnesiumGoalMg = v,
              ),
            ),
            _buildNutrientRow(
              label: S.of(context).settingsVitaminDGoalLabel,
              description: S.of(context).settingsVitaminDGoalDescription,
              value:
                  _vitaminDGoalUg ?? DailyNutrientPanel.defaultVitaminDRefUg,
              min: _vitaminDMin,
              max: _vitaminDMax,
              divisions: _vitaminDDivisions,
              controller: _vitaminDController,
              unit: 'µg',
              decimalStep: true,
              identifier: 'calculations-vitamin-d-slider',
              onSliderChanged: (v) => setState(() => _vitaminDGoalUg = v),
              onTextSubmitted: () => _applyDirectNutrientInput(
                _vitaminDController,
                _vitaminDMin,
                _vitaminDMax,
                (v) => _vitaminDGoalUg = v,
                decimalStep: true,
              ),
            ),
            _buildNutrientRow(
              label: S.of(context).settingsVitaminB12GoalLabel,
              description: S.of(context).settingsVitaminB12GoalDescription,
              value: _vitaminB12GoalUg ??
                  DailyNutrientPanel.defaultVitaminB12RefUg,
              min: _vitaminB12Min,
              max: _vitaminB12Max,
              divisions: _vitaminB12Divisions,
              controller: _vitaminB12Controller,
              unit: 'µg',
              decimalStep: true,
              identifier: 'calculations-vitamin-b12-slider',
              onSliderChanged: (v) => setState(() => _vitaminB12GoalUg = v),
              onTextSubmitted: () => _applyDirectNutrientInput(
                _vitaminB12Controller,
                _vitaminB12Min,
                _vitaminB12Max,
                (v) => _vitaminB12GoalUg = v,
                decimalStep: true,
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

  /// #173 (+follow-up): render a single nutrient-goal row. Mirrors the
  /// macro row layout — a label, an editable text field for direct
  /// entry, and a slider underneath — but operates in a fixed unit (g,
  /// mg, or µg) and writes to a nullable goal value rather than
  /// redistributing percentages. `decimalStep` lets the row work for
  /// fractional values like B12 (0.1µg steps) where rounding to whole
  /// numbers would lose the entire useful range.
  ///
  /// Pass [identifier] to give the slider a stable `Semantics.identifier`
  /// handle so ADB uiautomator can locate it by resource-id.
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
    String unit = 'g',
    bool decimalStep = false,
    String? identifier,
  }) {
    final clamped = value.clamp(min, max).toDouble();
    final slider = Slider(
      min: min,
      max: max,
      value: clamped,
      divisions: divisions,
      onChanged: (v) {
        // Snap to the slider's division grid so the controller
        // text matches what the slider actually represents.
        final step = (max - min) / divisions;
        final snapped = (((v - min) / step).round() * step + min);
        controller.text =
            decimalStep ? snapped.toStringAsFixed(1) : snapped.round().toString();
        onSliderChanged(snapped);
      },
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: decimalStep,
                  ),
                  inputFormatters: decimalStep
                      ? [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ]
                      : [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    suffixText: unit,
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
          if (identifier != null && identifier.isNotEmpty)
            Semantics(identifier: identifier, child: slider)
          else
            slider,
        ],
      ),
    );
  }

  /// #173 (+follow-up): apply a directly typed value for a nutrient
  /// goal, clamping into the slider's valid range. Invalid input
  /// reverts to the previously stored value (or the default if none).
  /// `decimalStep` keeps fractional precision for B12 / vitamin D where
  /// rounding to whole numbers would erase the useful range.
  void _applyDirectNutrientInput(
    TextEditingController controller,
    double min,
    double max,
    void Function(double) setter, {
    bool decimalStep = false,
  }) {
    final parsed = double.tryParse(controller.text);
    if (parsed == null) {
      // Revert to current state; setter remains untouched.
      return;
    }
    final clamped = parsed.clamp(min, max).toDouble();
    setState(() => setter(clamped));
    controller.text =
        decimalStep ? clamped.toStringAsFixed(1) : clamped.round().toString();
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
    // Follow-up to #173: flush the seven additional nutrient inputs.
    _applyDirectNutrientInput(
      _sodiumController,
      _sodiumMin,
      _sodiumMax,
      (v) => _sodiumGoalMg = v,
    );
    _applyDirectNutrientInput(
      _calciumController,
      _calciumMin,
      _calciumMax,
      (v) => _calciumGoalMg = v,
    );
    _applyDirectNutrientInput(
      _ironController,
      _ironMin,
      _ironMax,
      (v) => _ironGoalMg = v,
      decimalStep: true,
    );
    _applyDirectNutrientInput(
      _potassiumController,
      _potassiumMin,
      _potassiumMax,
      (v) => _potassiumGoalMg = v,
    );
    _applyDirectNutrientInput(
      _magnesiumController,
      _magnesiumMin,
      _magnesiumMax,
      (v) => _magnesiumGoalMg = v,
    );
    _applyDirectNutrientInput(
      _vitaminDController,
      _vitaminDMin,
      _vitaminDMax,
      (v) => _vitaminDGoalUg = v,
      decimalStep: true,
    );
    _applyDirectNutrientInput(
      _vitaminB12Controller,
      _vitaminB12Min,
      _vitaminB12Max,
      (v) => _vitaminB12GoalUg = v,
      decimalStep: true,
    );

    widget.settingsBloc.setKcalAdjustment(_kcalAdjustmentSelection.toInt().toDouble());
    widget.settingsBloc.setMacroGoals(
      _carbsPctSelection,
      _proteinPctSelection,
      _fatPctSelection,
    );

    // #119: Persist target weight on the user entity. Empty/blank input
    // clears the stored value, matching the "Not set" framing on the
    // profile screen. The value is stored in kg regardless of the
    // user's display unit, so the data shape stays stable if they later
    // toggle units.
    _persistTargetWeight();

    // #119 follow-up: persist the taper toggle alongside the rest.
    widget.settingsBloc.setCaloriesTaperEnabled(_caloriesTaperEnabled);

    widget.settingsBloc.add(LoadSettingsEvent());
    widget.profileBloc.add(LoadProfileEvent());
    widget.homeBloc.add(LoadItemsEvent());
    // updateTrackedDay either creates today's row from current goals or
    // refreshes the macro columns on the existing one. Either way the
    // row exists by the time we write the nutrient goals against it.
    await widget.settingsBloc.updateTrackedDay(DateTime.now());
    // #173 (+follow-up): persist every per-nutrient goal onto today's
    // TrackedDayDBO row. Each field is sent unconditionally — passing
    // a non-null value updates the column; the data source skips any
    // value that's still null (i.e. the user never touched that row).
    await widget.settingsBloc.setTodayNutrientGoals(
      DateTime.now(),
      fibreGoal: _fibreGoalGrams,
      satFatGoal: _satFatGoalGrams,
      sugarsGoal: _sugarsGoalGrams,
      sodiumGoal: _sodiumGoalMg,
      calciumGoal: _calciumGoalMg,
      ironGoal: _ironGoalMg,
      potassiumGoal: _potassiumGoalMg,
      vitaminDGoal: _vitaminDGoalUg,
      vitaminB12Goal: _vitaminB12GoalUg,
      magnesiumGoal: _magnesiumGoalMg,
    );
    widget.diaryBloc.add(LoadDiaryYearEvent());
    widget.calendarDayBloc.add(RefreshCalendarDayEvent());

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// #119: Parse the target-weight text field and write to the user
  /// entity. Tolerates both `.` and `,` as decimal separators since the
  /// numeric keyboard varies by locale. An invalid or empty value
  /// clears the stored target — that's intentional so users can opt out
  /// after setting one.
  void _persistTargetWeight() {
    final user = _user;
    if (user == null) return;
    final raw = _targetWeightController.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) {
      if (user.targetWeightKg != null) {
        user.targetWeightKg = null;
        widget.profileBloc.updateUser(user);
      }
      return;
    }
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      return;
    }
    final kg = _usesImperialUnits ? UnitCalc.lbsToKg(parsed) : parsed;
    if (user.targetWeightKg != kg) {
      user.targetWeightKg = kg;
      widget.profileBloc.updateUser(user);
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
