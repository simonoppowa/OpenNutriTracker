import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_log_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

enum MacroGoalUnitMode { grams, percentage, gramsPerKg }

class SetDayGoalsDialog extends StatefulWidget {
  final DateTime selectedDay;
  final TrackedDayEntity? trackedDayEntity;
  final CalendarDayBloc calendarDayBloc;

  const SetDayGoalsDialog({
    super.key,
    required this.selectedDay,
    required this.trackedDayEntity,
    required this.calendarDayBloc,
  });

  @override
  State<SetDayGoalsDialog> createState() => _SetDayGoalsDialogState();
}

class _SetDayGoalsDialogState extends State<SetDayGoalsDialog> {
  late final TextEditingController _kcalController;
  late final TextEditingController _carbsController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;

  MacroGoalUnitMode _globalMode = MacroGoalUnitMode.grams;
  double _latestWeightKg = 70.0;
  bool _isLoading = true;
  bool _isUpdating = false; // Prevents recursive controller triggers

  @override
  void initState() {
    super.initState();
    final td = widget.trackedDayEntity;
    final kcal = td?.calorieGoal ?? 2000.0;
    final carbs = td?.carbsGoal ?? 250.0;
    final protein = td?.proteinGoal ?? 150.0;
    final fat = td?.fatGoal ?? 70.0;

    _kcalController = TextEditingController(text: kcal.round().toString());
    _carbsController = TextEditingController(text: carbs.toStringAsFixed(0));
    _proteinController = TextEditingController(text: protein.toStringAsFixed(0));
    _fatController = TextEditingController(text: fat.toStringAsFixed(0));

    _loadLatestWeight();
  }

  Future<void> _loadLatestWeight() async {
    try {
      final entries = await locator<GetWeightLogUsecase>().getAllEntries();
      if (entries.isNotEmpty) {
        entries.sort((a, b) => b.date.compareTo(a.date));
        _latestWeightKg = entries.first.weightKg;
      }
    } catch (_) {
      // Fallback
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _kcalController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  double _parse(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
  }

  // Converts current stored grams to target mode representation for display
  void _updateDisplayValuesForMode(MacroGoalUnitMode newMode) {
    if (_isUpdating) return;
    _isUpdating = true;

    final kcal = _parse(_kcalController);
    var carbsG = _parse(_carbsController);
    var proteinG = _parse(_proteinController);
    var fatG = _parse(_fatController);

    // If currently in percentage or g/kg, we first resolve back to grams internally
    if (_globalMode == MacroGoalUnitMode.percentage && kcal > 0) {
      carbsG = (kcal * (carbsG / 100.0)) / 4.0;
      proteinG = (kcal * (proteinG / 100.0)) / 4.0;
      fatG = (kcal * (fatG / 100.0)) / 9.0;
    } else if (_globalMode == MacroGoalUnitMode.gramsPerKg && _latestWeightKg > 0) {
      carbsG = carbsG * _latestWeightKg;
      proteinG = proteinG * _latestWeightKg;
      fatG = fatG * _latestWeightKg;
    }

    // Now convert grams to newMode
    if (newMode == MacroGoalUnitMode.percentage && kcal > 0) {
      final carbsPct = ((carbsG * 4.0) / kcal) * 100.0;
      final proteinPct = ((proteinG * 4.0) / kcal) * 100.0;
      final fatPct = ((fatG * 9.0) / kcal) * 100.0;
      _carbsController.text = carbsPct.toStringAsFixed(0);
      _proteinController.text = proteinPct.toStringAsFixed(0);
      _fatController.text = fatPct.toStringAsFixed(0);
    } else if (newMode == MacroGoalUnitMode.gramsPerKg && _latestWeightKg > 0) {
      _carbsController.text = (carbsG / _latestWeightKg).toStringAsFixed(1);
      _proteinController.text = (proteinG / _latestWeightKg).toStringAsFixed(1);
      _fatController.text = (fatG / _latestWeightKg).toStringAsFixed(1);
    } else {
      // grams
      _carbsController.text = carbsG.toStringAsFixed(0);
      _proteinController.text = proteinG.toStringAsFixed(0);
      _fatController.text = fatG.toStringAsFixed(0);
    }

    _globalMode = newMode;
    _isUpdating = false;
    setState(() {});
  }

  // When Kcal changes, recalculate macros proportionally or keep current ratio
  void _onKcalChanged(String text) {
    if (_isUpdating) return;
    _isUpdating = true;

    final newKcal = _parse(_kcalController);
    if (newKcal <= 0) {
      _isUpdating = false;
      return;
    }

    if (_globalMode == MacroGoalUnitMode.percentage) {
      // Percentages stay same, but values change
      _isUpdating = false;
      setState(() {});
      return;
    }

    // Recalculate grams or g/kg based on ratio
    var carbs = _parse(_carbsController);
    var protein = _parse(_proteinController);
    var fat = _parse(_fatController);

    if (_globalMode == MacroGoalUnitMode.gramsPerKg) {
      carbs *= _latestWeightKg;
      protein *= _latestWeightKg;
      fat *= _latestWeightKg;
    }

    final totalCalsFromMacros = (carbs * 4.0) + (protein * 4.0) + (fat * 9.0);
    if (totalCalsFromMacros > 0) {
      final ratioC = (carbs * 4.0) / totalCalsFromMacros;
      final ratioP = (protein * 4.0) / totalCalsFromMacros;
      final ratioF = (fat * 9.0) / totalCalsFromMacros;

      final newCarbsG = (newKcal * ratioC) / 4.0;
      final newProteinG = (newKcal * ratioP) / 4.0;
      final newFatG = (newKcal * ratioF) / 9.0;

      if (_globalMode == MacroGoalUnitMode.gramsPerKg && _latestWeightKg > 0) {
        _carbsController.text = (newCarbsG / _latestWeightKg).toStringAsFixed(1);
        _proteinController.text = (newProteinG / _latestWeightKg).toStringAsFixed(1);
        _fatController.text = (newFatG / _latestWeightKg).toStringAsFixed(1);
      } else {
        _carbsController.text = newCarbsG.toStringAsFixed(0);
        _proteinController.text = newProteinG.toStringAsFixed(0);
        _fatController.text = newFatG.toStringAsFixed(0);
      }
    }

    _isUpdating = false;
    setState(() {});
  }

  // When one macro changes, rebalance the other two to keep total Kcal locked
  void _onMacroChanged(String changedMacro) {
    if (_isUpdating) return;
    _isUpdating = true;

    final kcal = _parse(_kcalController);
    if (kcal <= 0) {
      _isUpdating = false;
      return;
    }

    // Convert all to grams for rebalancing calculation
    var cG = _parse(_carbsController);
    var pG = _parse(_proteinController);
    var fG = _parse(_fatController);

    if (_globalMode == MacroGoalUnitMode.percentage) {
      cG = (kcal * (cG / 100.0)) / 4.0;
      pG = (kcal * (pG / 100.0)) / 4.0;
      fG = (kcal * (fG / 100.0)) / 9.0;
    } else if (_globalMode == MacroGoalUnitMode.gramsPerKg) {
      cG *= _latestWeightKg;
      pG *= _latestWeightKg;
      fG *= _latestWeightKg;
    }

    final changedCals = (changedMacro == 'carbs'
            ? cG * 4.0
            : (changedMacro == 'protein' ? pG * 4.0 : fG * 9.0));

    final remainingKcal = kcal - changedCals;
    if (remainingKcal >= 0) {
      // Rebalance remaining two macros proportionally
      if (changedMacro == 'carbs') {
        final oldRemainingCals = (pG * 4.0) + (fG * 9.0);
        if (oldRemainingCals > 0) {
          final pRatio = (pG * 4.0) / oldRemainingCals;
          pG = (remainingKcal * pRatio) / 4.0;
          fG = (remainingKcal * (1.0 - pRatio)) / 9.0;
        } else {
          pG = remainingKcal / 2.0 / 4.0;
          fG = remainingKcal / 2.0 / 9.0;
        }
      } else if (changedMacro == 'protein') {
        final oldRemainingCals = (cG * 4.0) + (fG * 9.0);
        if (oldRemainingCals > 0) {
          final cRatio = (cG * 4.0) / oldRemainingCals;
          cG = (remainingKcal * cRatio) / 4.0;
          fG = (remainingKcal * (1.0 - cRatio)) / 9.0;
        } else {
          cG = remainingKcal / 2.0 / 4.0;
          fG = remainingKcal / 2.0 / 9.0;
        }
      } else if (changedMacro == 'fat') {
        final oldRemainingCals = (cG * 4.0) + (pG * 4.0);
        if (oldRemainingCals > 0) {
          final cRatio = (cG * 4.0) / oldRemainingCals;
          cG = (remainingKcal * cRatio) / 4.0;
          pG = (remainingKcal * (1.0 - cRatio)) / 4.0;
        } else {
          cG = remainingKcal / 2.0 / 4.0;
          pG = remainingKcal / 2.0 / 4.0;
        }
      }
    }

    // Format back to current mode
    if (_globalMode == MacroGoalUnitMode.percentage && kcal > 0) {
      _carbsController.text = (((cG * 4.0) / kcal) * 100.0).toStringAsFixed(0);
      _proteinController.text = (((pG * 4.0) / kcal) * 100.0).toStringAsFixed(0);
      _fatController.text = (((fG * 9.0) / kcal) * 100.0).toStringAsFixed(0);
    } else if (_globalMode == MacroGoalUnitMode.gramsPerKg && _latestWeightKg > 0) {
      _carbsController.text = (cG / _latestWeightKg).toStringAsFixed(1);
      _proteinController.text = (pG / _latestWeightKg).toStringAsFixed(1);
      _fatController.text = (fG / _latestWeightKg).toStringAsFixed(1);
    } else {
      _carbsController.text = cG.toStringAsFixed(0);
      _proteinController.text = pG.toStringAsFixed(0);
      _fatController.text = fG.toStringAsFixed(0);
    }

    _isUpdating = false;
    setState(() {});
  }

  Future<void> _save() async {
    final kcal = _parse(_kcalController);
    if (kcal <= 0) return;

    var cInput = _parse(_carbsController);
    var pInput = _parse(_proteinController);
    var fInput = _parse(_fatController);

    double carbsGoal;
    double proteinGoal;
    double fatGoal;

    if (_globalMode == MacroGoalUnitMode.percentage) {
      carbsGoal = (kcal * (cInput / 100.0)) / 4.0;
      proteinGoal = (kcal * (pInput / 100.0)) / 4.0;
      fatGoal = (kcal * (fInput / 100.0)) / 9.0;
    } else if (_globalMode == MacroGoalUnitMode.gramsPerKg) {
      carbsGoal = cInput * _latestWeightKg;
      proteinGoal = pInput * _latestWeightKg;
      fatGoal = fInput * _latestWeightKg;
    } else {
      carbsGoal = cInput;
      proteinGoal = pInput;
      fatGoal = fInput;
    }

    await widget.calendarDayBloc.setDayGoals(
      widget.selectedDay,
      calorieGoal: kcal,
      carbsGoal: carbsGoal,
      fatGoal: fatGoal,
      proteinGoal: proteinGoal,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final dateStr = DateFormat.yMMMd().format(widget.selectedDay);

    return AlertDialog(
      title: Text('Definir Metas para $dateStr'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peso de referência: ${_latestWeightKg.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ToggleButtons(
                        isSelected: [
                          _globalMode == MacroGoalUnitMode.grams,
                          _globalMode == MacroGoalUnitMode.percentage,
                          _globalMode == MacroGoalUnitMode.gramsPerKg,
                        ],
                        onPressed: (index) {
                          if (index == 0) _updateDisplayValuesForMode(MacroGoalUnitMode.grams);
                          if (index == 1) _updateDisplayValuesForMode(MacroGoalUnitMode.percentage);
                          if (index == 2) _updateDisplayValuesForMode(MacroGoalUnitMode.gramsPerKg);
                        },
                        constraints: const BoxConstraints(minHeight: 36, minWidth: 72),
                        children: const [
                          Text('Gramas (g)'),
                          Text('Percentual (%)'),
                          Text('Por Kg (g/kg)'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _kcalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Meta de Calorias (kcal)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onKcalChanged,
                  ),
                  const SizedBox(height: 16),
                  _buildMacroField(
                    label: s.proteinLabel,
                    controller: _proteinController,
                    semanticId: 'day-goals-protein',
                    onChanged: (_) => _onMacroChanged('protein'),
                  ),
                  const SizedBox(height: 16),
                  _buildMacroField(
                    label: s.carbsLabel,
                    controller: _carbsController,
                    semanticId: 'day-goals-carbs',
                    onChanged: (_) => _onMacroChanged('carbs'),
                  ),
                  const SizedBox(height: 16),
                  _buildMacroField(
                    label: s.fatLabel,
                    controller: _fatController,
                    semanticId: 'day-goals-fat',
                    onChanged: (_) => _onMacroChanged('fat'),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogCancelLabel),
        ),
        Semantics(
          identifier: 'day-goals-save',
          child: TextButton(
            onPressed: _isLoading ? null : _save,
            child: Text(s.dialogOKLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroField({
    required String label,
    required TextEditingController controller,
    required String semanticId,
    required ValueChanged<String> onChanged,
  }) {
    String suffix = 'g';
    if (_globalMode == MacroGoalUnitMode.percentage) suffix = '%';
    if (_globalMode == MacroGoalUnitMode.gramsPerKg) suffix = 'g/kg';

    return Semantics(
      identifier: semanticId,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
        ],
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
