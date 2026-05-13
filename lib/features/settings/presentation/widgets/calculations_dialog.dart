import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/calories_profile_info_dialog.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
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
  // #119: Target weight is editable as a free-text numeric field. We
  // keep the value as a nullable double on the user entity; an empty
  // input clears the stored target.
  late TextEditingController _targetWeightController;

  UserEntity? _user;
  bool _usesImperialUnits = false;

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
  }

  @override
  void dispose() {
    _kcalAdjustmentController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _targetWeightController.dispose();
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

    setState(() {
      _kcalAdjustmentSelection = kcalAdjustment;
      _carbsPctSelection = (userCarbsPct ?? _defaultCarbsPctSelection) * 100;
      _proteinPctSelection =
          (userProteinPct ?? _defaultProteinPctSelection) * 100;
      _fatPctSelection = (userFatPct ?? _defaultFatPctSelection) * 100;
      _user = user;
      _usesImperialUnits = usesImperialUnits;
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

    // #119: Persist target weight on the user entity. Empty/blank input
    // clears the stored value, matching the "Not set" framing on the
    // profile screen. The value is stored in kg regardless of the
    // user's display unit, so the data shape stays stable if they later
    // toggle units.
    _persistTargetWeight();

    widget.settingsBloc.add(LoadSettingsEvent());
    widget.profileBloc.add(LoadProfileEvent());
    widget.homeBloc.add(LoadItemsEvent());
    widget.settingsBloc.updateTrackedDay(DateTime.now());
    widget.diaryBloc.add(LoadDiaryYearEvent());
    widget.calendarDayBloc.add(RefreshCalendarDayEvent());

    Navigator.of(context).pop();
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
