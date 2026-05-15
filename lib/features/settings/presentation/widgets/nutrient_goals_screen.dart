import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/daily_nutrient_panel.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// #173 + follow-up: full screen rather than a dialog because the ten
/// nutrient sliders are tall enough to need real scroll room on a
/// phone. Each row is a label + direct text input + description +
/// slider, persisted to today's TrackedDayDBO row so the diary panel
/// can read it back as a reference value.
///
/// Iron and magnesium open at gender-aware defaults — 8 / 18 / 14 mg
/// and 400 / 310 / 355 mg for male / female / non-binary — matching
/// the panel's own reference choices so the dialog and panel agree.
class NutrientGoalsScreen extends StatefulWidget {
  final SettingsBloc settingsBloc;
  final ProfileBloc profileBloc;
  final DiaryBloc diaryBloc;
  final CalendarDayBloc calendarDayBloc;
  final HomeBloc homeBloc;

  const NutrientGoalsScreen({
    super.key,
    required this.settingsBloc,
    required this.profileBloc,
    required this.diaryBloc,
    required this.calendarDayBloc,
    required this.homeBloc,
  });

  @override
  State<NutrientGoalsScreen> createState() => _NutrientGoalsScreenState();
}

class _NutrientGoalsScreenState extends State<NutrientGoalsScreen> {
  static const double _fibreMin = 0;
  static const double _fibreMax = 80;
  static const int _fibreDivisions = 80;
  static const double _satFatMin = 0;
  static const double _satFatMax = 60;
  static const int _satFatDivisions = 60;
  static const double _sugarsMin = 0;
  static const double _sugarsMax = 150;
  static const int _sugarsDivisions = 150;
  static const double _sodiumMin = 0;
  static const double _sodiumMax = 3000;
  static const int _sodiumDivisions = 60;
  static const double _calciumMin = 0;
  static const double _calciumMax = 1500;
  static const int _calciumDivisions = 60;
  static const double _ironMin = 0;
  static const double _ironMax = 30;
  static const int _ironDivisions = 60;
  static const double _potassiumMin = 0;
  static const double _potassiumMax = 5000;
  static const int _potassiumDivisions = 100;
  static const double _magnesiumMin = 0;
  static const double _magnesiumMax = 600;
  static const int _magnesiumDivisions = 60;
  static const double _vitaminDMin = 0;
  static const double _vitaminDMax = 50;
  static const int _vitaminDDivisions = 100;
  static const double _vitaminB12Min = 0;
  static const double _vitaminB12Max = 10;
  static const int _vitaminB12Divisions = 100;

  double? _fibre;
  double? _satFat;
  double? _sugars;
  double? _sodium;
  double? _calcium;
  double? _iron;
  double? _potassium;
  double? _magnesium;
  double? _vitaminD;
  double? _vitaminB12;
  UserEntity? _user;
  bool _loaded = false;

  late final TextEditingController _fibreController;
  late final TextEditingController _satFatController;
  late final TextEditingController _sugarsController;
  late final TextEditingController _sodiumController;
  late final TextEditingController _calciumController;
  late final TextEditingController _ironController;
  late final TextEditingController _potassiumController;
  late final TextEditingController _magnesiumController;
  late final TextEditingController _vitaminDController;
  late final TextEditingController _vitaminB12Controller;

  @override
  void initState() {
    super.initState();
    _fibreController = TextEditingController();
    _satFatController = TextEditingController();
    _sugarsController = TextEditingController();
    _sodiumController = TextEditingController();
    _calciumController = TextEditingController();
    _ironController = TextEditingController();
    _potassiumController = TextEditingController();
    _magnesiumController = TextEditingController();
    _vitaminDController = TextEditingController();
    _vitaminB12Controller = TextEditingController();
    _load();
  }

  @override
  void dispose() {
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

  /// Iron RDA splits female 18 / male 8 (mg). 14 mg is the
  /// gender-neutral midpoint we pick for non-binary / unknown,
  /// matching the panel's existing fallback.
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

  /// Magnesium DRI: 400 mg adult male, 310 mg adult female; 355 mg
  /// for non-binary / unknown so neither extreme is misled.
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

  String _formatGoal(double value) =>
      value >= 10 ? value.round().toString() : value.toStringAsFixed(1);

  Future<void> _load() async {
    final user = await widget.profileBloc.getUser();
    final today = await widget.settingsBloc.getTodayTrackedDay(DateTime.now());
    if (!mounted) return;
    setState(() {
      _user = user;
      _fibre = today?.fibreGoal;
      _satFat = today?.satFatGoal;
      _sugars = today?.sugarsGoal;
      _sodium = today?.sodiumGoal;
      _calcium = today?.calciumGoal;
      _iron = today?.ironGoal;
      _potassium = today?.potassiumGoal;
      _magnesium = today?.magnesiumGoal;
      _vitaminD = today?.vitaminDGoal;
      _vitaminB12 = today?.vitaminB12Goal;
      _loaded = true;
    });
    _syncControllers();
  }

  void _syncControllers() {
    _fibreController.text =
        (_fibre ?? DailyNutrientPanel.defaultFibreRefG).round().toString();
    _satFatController.text =
        (_satFat ?? DailyNutrientPanel.defaultSaturatedFatRefG)
            .round()
            .toString();
    _sugarsController.text =
        (_sugars ?? DailyNutrientPanel.defaultSugarRefG).round().toString();
    _sodiumController.text =
        (_sodium ?? DailyNutrientPanel.defaultSodiumRefMg).round().toString();
    _calciumController.text =
        (_calcium ?? DailyNutrientPanel.defaultCalciumRefMg)
            .round()
            .toString();
    _ironController.text =
        _formatGoal(_iron ?? _ironDefaultForGender());
    _potassiumController.text =
        (_potassium ?? DailyNutrientPanel.defaultPotassiumRefMg)
            .round()
            .toString();
    _magnesiumController.text =
        _formatGoal(_magnesium ?? _magnesiumDefaultForGender());
    _vitaminDController.text =
        _formatGoal(_vitaminD ?? DailyNutrientPanel.defaultVitaminDRefUg);
    _vitaminB12Controller.text = _formatGoal(
      _vitaminB12 ?? DailyNutrientPanel.defaultVitaminB12RefUg,
    );
  }

  void _resetAll() {
    setState(() {
      _fibre = null;
      _satFat = null;
      _sugars = null;
      _sodium = null;
      _calcium = null;
      _iron = null;
      _potassium = null;
      _magnesium = null;
      _vitaminD = null;
      _vitaminB12 = null;
    });
    _syncControllers();
  }

  Future<void> _save() async {
    // Make sure today's tracked-day row exists before we write per-
    // nutrient values onto it. updateTrackedDay creates the row from
    // current macro goals if missing, or refreshes the macro columns
    // on the existing one.
    await widget.settingsBloc.updateTrackedDay(DateTime.now());
    await widget.settingsBloc.setTodayNutrientGoals(
      DateTime.now(),
      fibreGoal: _fibre,
      satFatGoal: _satFat,
      sugarsGoal: _sugars,
      sodiumGoal: _sodium,
      calciumGoal: _calcium,
      ironGoal: _iron,
      potassiumGoal: _potassium,
      magnesiumGoal: _magnesium,
      vitaminDGoal: _vitaminD,
      vitaminB12Goal: _vitaminB12,
    );
    widget.settingsBloc.add(LoadSettingsEvent());
    widget.homeBloc.add(const LoadItemsEvent());
    widget.diaryBloc.add(const LoadDiaryYearEvent());
    widget.calendarDayBloc.add(RefreshCalendarDayEvent());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.settingsNutrientGoalsLabel),
        actions: [
          Semantics(
            identifier: 'nutrient-goals-reset',
            child: TextButton(
              onPressed: _loaded ? _resetAll : null,
              child: Text(s.buttonResetLabel),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: Semantics(
              identifier: 'nutrient-goals-save',
              child: FilledButton(
                onPressed: _loaded ? _save : null,
                child: Text(s.buttonSaveLabel),
              ),
            ),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  s.settingsNutrientGoalsHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _NutrientRow(
                  label: s.settingsFibreGoalLabel,
                  description: s.settingsFibreGoalDescription,
                  value: _fibre ?? DailyNutrientPanel.defaultFibreRefG,
                  min: _fibreMin,
                  max: _fibreMax,
                  divisions: _fibreDivisions,
                  controller: _fibreController,
                  identifier: 'nutrient-fibre-slider',
                  onSliderChanged: (v) => setState(() => _fibre = v),
                  onTextSubmitted: () => _applyText(
                      _fibreController, _fibreMin, _fibreMax, (v) => _fibre = v),
                ),
                _NutrientRow(
                  label: s.settingsSaturatedFatGoalLabel,
                  description: s.settingsSaturatedFatGoalDescription,
                  value:
                      _satFat ?? DailyNutrientPanel.defaultSaturatedFatRefG,
                  min: _satFatMin,
                  max: _satFatMax,
                  divisions: _satFatDivisions,
                  controller: _satFatController,
                  identifier: 'nutrient-sat-fat-slider',
                  onSliderChanged: (v) => setState(() => _satFat = v),
                  onTextSubmitted: () => _applyText(_satFatController,
                      _satFatMin, _satFatMax, (v) => _satFat = v),
                ),
                _NutrientRow(
                  label: s.settingsSugarsGoalLabel,
                  description: s.settingsSugarsGoalDescription,
                  value: _sugars ?? DailyNutrientPanel.defaultSugarRefG,
                  min: _sugarsMin,
                  max: _sugarsMax,
                  divisions: _sugarsDivisions,
                  controller: _sugarsController,
                  identifier: 'nutrient-sugars-slider',
                  onSliderChanged: (v) => setState(() => _sugars = v),
                  onTextSubmitted: () => _applyText(_sugarsController,
                      _sugarsMin, _sugarsMax, (v) => _sugars = v),
                ),
                _NutrientRow(
                  label: s.settingsSodiumGoalLabel,
                  description: s.settingsSodiumGoalDescription,
                  value: _sodium ?? DailyNutrientPanel.defaultSodiumRefMg,
                  min: _sodiumMin,
                  max: _sodiumMax,
                  divisions: _sodiumDivisions,
                  controller: _sodiumController,
                  unit: 'mg',
                  identifier: 'nutrient-sodium-slider',
                  onSliderChanged: (v) => setState(() => _sodium = v),
                  onTextSubmitted: () => _applyText(_sodiumController,
                      _sodiumMin, _sodiumMax, (v) => _sodium = v),
                ),
                _NutrientRow(
                  label: s.settingsCalciumGoalLabel,
                  description: s.settingsCalciumGoalDescription,
                  value: _calcium ?? DailyNutrientPanel.defaultCalciumRefMg,
                  min: _calciumMin,
                  max: _calciumMax,
                  divisions: _calciumDivisions,
                  controller: _calciumController,
                  unit: 'mg',
                  identifier: 'nutrient-calcium-slider',
                  onSliderChanged: (v) => setState(() => _calcium = v),
                  onTextSubmitted: () => _applyText(_calciumController,
                      _calciumMin, _calciumMax, (v) => _calcium = v),
                ),
                _NutrientRow(
                  label: s.settingsIronGoalLabel,
                  description: s.settingsIronGoalDescription,
                  value: _iron ?? _ironDefaultForGender(),
                  min: _ironMin,
                  max: _ironMax,
                  divisions: _ironDivisions,
                  controller: _ironController,
                  unit: 'mg',
                  decimalStep: true,
                  identifier: 'nutrient-iron-slider',
                  onSliderChanged: (v) => setState(() => _iron = v),
                  onTextSubmitted: () => _applyText(
                    _ironController,
                    _ironMin,
                    _ironMax,
                    (v) => _iron = v,
                    decimalStep: true,
                  ),
                ),
                _NutrientRow(
                  label: s.settingsPotassiumGoalLabel,
                  description: s.settingsPotassiumGoalDescription,
                  value:
                      _potassium ?? DailyNutrientPanel.defaultPotassiumRefMg,
                  min: _potassiumMin,
                  max: _potassiumMax,
                  divisions: _potassiumDivisions,
                  controller: _potassiumController,
                  unit: 'mg',
                  identifier: 'nutrient-potassium-slider',
                  onSliderChanged: (v) => setState(() => _potassium = v),
                  onTextSubmitted: () => _applyText(_potassiumController,
                      _potassiumMin, _potassiumMax, (v) => _potassium = v),
                ),
                _NutrientRow(
                  label: s.settingsMagnesiumGoalLabel,
                  description: s.settingsMagnesiumGoalDescription,
                  value: _magnesium ?? _magnesiumDefaultForGender(),
                  min: _magnesiumMin,
                  max: _magnesiumMax,
                  divisions: _magnesiumDivisions,
                  controller: _magnesiumController,
                  unit: 'mg',
                  identifier: 'nutrient-magnesium-slider',
                  onSliderChanged: (v) => setState(() => _magnesium = v),
                  onTextSubmitted: () => _applyText(_magnesiumController,
                      _magnesiumMin, _magnesiumMax, (v) => _magnesium = v),
                ),
                _NutrientRow(
                  label: s.settingsVitaminDGoalLabel,
                  description: s.settingsVitaminDGoalDescription,
                  value: _vitaminD ?? DailyNutrientPanel.defaultVitaminDRefUg,
                  min: _vitaminDMin,
                  max: _vitaminDMax,
                  divisions: _vitaminDDivisions,
                  controller: _vitaminDController,
                  unit: 'µg',
                  decimalStep: true,
                  identifier: 'nutrient-vitamin-d-slider',
                  onSliderChanged: (v) => setState(() => _vitaminD = v),
                  onTextSubmitted: () => _applyText(
                    _vitaminDController,
                    _vitaminDMin,
                    _vitaminDMax,
                    (v) => _vitaminD = v,
                    decimalStep: true,
                  ),
                ),
                _NutrientRow(
                  label: s.settingsVitaminB12GoalLabel,
                  description: s.settingsVitaminB12GoalDescription,
                  value:
                      _vitaminB12 ?? DailyNutrientPanel.defaultVitaminB12RefUg,
                  min: _vitaminB12Min,
                  max: _vitaminB12Max,
                  divisions: _vitaminB12Divisions,
                  controller: _vitaminB12Controller,
                  unit: 'µg',
                  decimalStep: true,
                  identifier: 'nutrient-vitamin-b12-slider',
                  onSliderChanged: (v) => setState(() => _vitaminB12 = v),
                  onTextSubmitted: () => _applyText(
                    _vitaminB12Controller,
                    _vitaminB12Min,
                    _vitaminB12Max,
                    (v) => _vitaminB12 = v,
                    decimalStep: true,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  /// Direct text-input clamp: malformed parses ignore the input and
  /// leave the slider where it was; valid ones snap into the row's
  /// declared min/max range.
  void _applyText(
    TextEditingController controller,
    double min,
    double max,
    void Function(double) setter, {
    bool decimalStep = false,
  }) {
    final parsed = double.tryParse(controller.text);
    if (parsed == null) return;
    final clamped = parsed.clamp(min, max).toDouble();
    setState(() => setter(clamped));
    controller.text =
        decimalStep ? clamped.toStringAsFixed(1) : clamped.round().toString();
  }
}

class _NutrientRow extends StatelessWidget {
  final String label;
  final String description;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final TextEditingController controller;
  final String identifier;
  final String unit;
  final bool decimalStep;
  final ValueChanged<double> onSliderChanged;
  final VoidCallback onTextSubmitted;

  const _NutrientRow({
    required this.label,
    required this.description,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.controller,
    required this.identifier,
    required this.onSliderChanged,
    required this.onTextSubmitted,
    this.unit = 'g',
    this.decimalStep = false,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max).toDouble();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
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
                            RegExp(r'^\d*\.?\d*'),
                          ),
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
          Semantics(
            identifier: identifier,
            child: Slider(
              min: min,
              max: max,
              value: clamped,
              divisions: divisions,
              onChanged: (v) {
                final step = (max - min) / divisions;
                final snapped = ((v - min) / step).round() * step + min;
                controller.text = decimalStep
                    ? snapped.toStringAsFixed(1)
                    : snapped.round().toString();
                onSliderChanged(snapped);
              },
            ),
          ),
        ],
      ),
    );
  }
}
