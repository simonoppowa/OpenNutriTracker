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
  bool _isUpdating = false;

  // Lock states
  bool _isKcalLocked = false;
  bool _isProteinLocked = false;
  bool _isCarbsLocked = false;
  bool _isFatLocked = false;

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
        // Apply default defaults if no tracked day goals existed
        if (widget.trackedDayEntity == null) {
          _applyDefaults();
        }
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyDefaults() {
    // Default: Protein = 2g/kg, Fat = 1g/kg, Carbs = remaining cals
    final kcal = 2000.0;
    final proteinG = 2.0 * _latestWeightKg;
    final fatG = 1.0 * _latestWeightKg;
    final remainingCals = kcal - (proteinG * 4.0) - (fatG * 9.0);
    final carbsG = remainingCals > 0 ? remainingCals / 4.0 : 200.0;

    _kcalController.text = kcal.round().toString();
    _proteinController.text = proteinG.toStringAsFixed(0);
    _fatController.text = fatG.toStringAsFixed(0);
    _carbsController.text = carbsG.toStringAsFixed(0);
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

  // Convert current grams to target mode representation
  double _toGrams(double value, MacroGoalUnitMode mode, double kcal) {
    switch (mode) {
      case MacroGoalUnitMode.grams:
        return value;
      case MacroGoalUnitMode.percentage:
        return 0.0; // Handled per-macro with kcal
      case MacroGoalUnitMode.gramsPerKg:
        return value * _latestWeightKg;
    }
  }

  // Get current grams for all three macros
  (double carbsG, double proteinG, double fatG) _getCurrentGrams() {
    final kcal = _parse(_kcalController);
    var c = _parse(_carbsController);
    var p = _parse(_proteinController);
    var f = _parse(_fatController);

    if (_globalMode == MacroGoalUnitMode.percentage && kcal > 0) {
      return (
        (kcal * (c / 100.0)) / 4.0,
        (kcal * (p / 100.0)) / 4.0,
        (kcal * (f / 100.0)) / 9.0,
      );
    } else if (_globalMode == MacroGoalUnitMode.gramsPerKg && _latestWeightKg > 0) {
      return (c * _latestWeightKg, p * _latestWeightKg, f * _latestWeightKg);
    }
    return (c, p, f);
  }

  void _setGramsToControllers(double cG, double pG, double fG) {
    final kcal = _parse(_kcalController);
    if (_globalMode == MacroGoalUnitMode.percentage && kcal > 0) {
      _carbsController.text = ((cG * 4.0 / kcal) * 100.0).toStringAsFixed(0);
      _proteinController.text = ((pG * 4.0 / kcal) * 100.0).toStringAsFixed(0);
      _fatController.text = ((fG * 9.0 / kcal) * 100.0).toStringAsFixed(0);
    } else if (_globalMode == MacroGoalUnitMode.gramsPerKg && _latestWeightKg > 0) {
      _carbsController.text = (cG / _latestWeightKg).toStringAsFixed(1);
      _proteinController.text = (pG / _latestWeightKg).toStringAsFixed(1);
      _fatController.text = (fG / _latestWeightKg).toStringAsFixed(1);
    } else {
      _carbsController.text = cG.toStringAsFixed(0);
      _proteinController.text = pG.toStringAsFixed(0);
      _fatController.text = fG.toStringAsFixed(0);
    }
  }

  void _updateDisplayValuesForMode(MacroGoalUnitMode newMode) {
    if (_isUpdating) return;
    _isUpdating = true;

    final (cG, pG, fG) = _getCurrentGrams();
    _globalMode = newMode;
    _setGramsToControllers(cG, pG, fG);

    _isUpdating = false;
    setState(() {});
  }

  // Central rebalancing engine respecting locks
  void _rebalance({required String source}) {
    if (_isUpdating) return;
    _isUpdating = true;

    var kcal = _parse(_kcalController);
    var (cG, pG, fG) = _getCurrentGrams();

    if (source == 'kcal') {
      if (_isKcalLocked) {
        // Kcal is locked, ignore typed kcal change or revert it
        // Actually if user edits kcal, let's allow it if unlocked, but if locked we don't change kcal.
      }
      // If kcal changed and is unlocked, or even if locked, let's rebalance unlocked macros to match kcal
      final totalMacroCals = (cG * 4.0) + (pG * 4.0) + (fG * 9.0);
      if (totalMacroCals > 0 && !_isKcalLocked) {
        // proportional scale
        final scale = kcal / totalMacroCals;
        cG *= scale;
        pG *= scale;
        fG *= scale;
      }
    } else {
      // A macro changed.
      // If kcal is unlocked, compute kcal from macros unless kcal is locked.
      if (!_isKcalLocked) {
        kcal = (cG * 4.0) + (pG * 4.0) + (fG * 9.0);
        _kcalController.text = kcal.round().toString();
      } else {
        // Kcal is locked! We must make sure unlocked macros absorb the difference to keep Kcal exact.
        // Identify unlocked macros
        final unlocked = <String>[
          if (!_isCarbsLocked) 'carbs',
          if (!_isProteinLocked) 'protein',
          if (!_isFatLocked) 'fat',
        ];

        // Current macro cals
        final cCals = cG * 4.0;
        final pCals = pG * 4.0;
        final fCals = fG * 9.0;
        final currentMacroSum = cCals + pCals + fCals;
        final diff = kcal - currentMacroSum;

        if (unlocked.length == 1) {
          // Only one macro unlocked, it absorbs all diff
          if (unlocked.first == 'carbs') {
            cG = (cG * 4.0 + diff) / 4.0;
          } else if (unlocked.first == 'protein') {
            pG = (pG * 4.0 + diff) / 4.0;
          } else if (unlocked.first == 'fat') {
            fG = (fG * 9.0 + diff) / 9.0;
          }
        } else if (unlocked.length == 2) {
          // Split diff proportionally between the two unlocked macros
          final u1Cals = unlocked.first == 'carbs' ? cCals : (unlocked.first == 'protein' ? pCals : fCals);
          final u2Cals = unlocked.last == 'carbs' ? cCals : (unlocked.last == 'protein' ? pCals : fCals);
          final sumU = u1Cals + u2Cals;
          if (sumU > 0) {
            final r1 = u1Cals / sumU;
            final r2 = u2Cals / sumU;
            final target1 = u1Cals + diff * r1;
            final target2 = u2Cals + diff * r2;
            if (unlocked.first == 'carbs') cG = target1 / 4.0;
            else if (unlocked.first == 'protein') pG = target1 / 4.0;
            else if (unlocked.first == 'fat') fG = target1 / 9.0;

            if (unlocked.last == 'carbs') cG = target2 / 4.0;
            else if (unlocked.last == 'protein') pG = target2 / 4.0;
            else if (unlocked.last == 'fat') fG = target2 / 9.0;
          } else {
            // Split equally in calories
            final half = diff / 2.0;
            if (unlocked.first == 'carbs') cG += half / 4.0;
            else if (unlocked.first == 'protein') pG += half / 4.0;
            else if (unlocked.first == 'fat') fG += half / 9.0;

            if (unlocked.last == 'carbs') cG += half / 4.0;
            else if (unlocked.last == 'protein') pG += half / 4.0;
            else if (unlocked.last == 'fat') fG += half / 9.0;
          }
        }
      }
    }

    if (cG < 0) cG = 0;
    if (pG < 0) pG = 0;
    if (fG < 0) fG = 0;

    _setGramsToControllers(cG, pG, fG);
    _isUpdating = false;
    setState(() {});
  }

  Future<void> _save() async {
    final kcal = _parse(_kcalController);
    if (kcal <= 0) return;

    final (carbsGoal, proteinGoal, fatGoal) = _getCurrentGrams();

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
                        constraints: const BoxConstraints(minHeight: 36, minWidth: 64),
                        children: const [
                          Text('g'),
                          Text('%'),
                          Text('g/kg'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildFieldWithLock(
                    label: 'Meta de Calorias (kcal)',
                    controller: _kcalController,
                    isLocked: _isKcalLocked,
                    onLockChanged: (v) => setState(() => _isKcalLocked = v),
                    onChanged: (_) => _rebalance(source: 'kcal'),
                    isInteger: true,
                  ),
                  const SizedBox(height: 16),
                  _buildFieldWithLock(
                    label: s.proteinLabel,
                    controller: _proteinController,
                    isLocked: _isProteinLocked,
                    onLockChanged: (v) => setState(() => _isProteinLocked = v),
                    onChanged: (_) => _rebalance(source: 'protein'),
                    semanticId: 'day-goals-protein',
                  ),
                  const SizedBox(height: 16),
                  _buildFieldWithLock(
                    label: s.carbsLabel,
                    controller: _carbsController,
                    isLocked: _isCarbsLocked,
                    onLockChanged: (v) => setState(() => _isCarbsLocked = v),
                    onChanged: (_) => _rebalance(source: 'carbs'),
                    semanticId: 'day-goals-carbs',
                  ),
                  const SizedBox(height: 16),
                  _buildFieldWithLock(
                    label: s.fatLabel,
                    controller: _fatController,
                    isLocked: _isFatLocked,
                    onLockChanged: (v) => setState(() => _isFatLocked = v),
                    onChanged: (_) => _rebalance(source: 'fat'),
                    semanticId: 'day-goals-fat',
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

  Widget _buildFieldWithLock({
    required String label,
    required TextEditingController controller,
    required bool isLocked,
    required ValueChanged<bool> onLockChanged,
    required ValueChanged<String> onChanged,
    String? semanticId,
    bool isInteger = false,
  }) {
    String suffix = 'g';
    if (_globalMode == MacroGoalUnitMode.percentage) suffix = '%';
    if (_globalMode == MacroGoalUnitMode.gramsPerKg) suffix = 'g/kg';
    if (label.contains('Calorias')) suffix = 'kcal';

    return Row(
      children: [
        Expanded(
          child: Semantics(
            identifier: semanticId,
            child: TextField(
              controller: controller,
              keyboardType: isInteger
                  ? TextInputType.number
                  : const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: isInteger
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : [FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*'))],
              decoration: InputDecoration(
                labelText: label,
                suffixText: suffix,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (text) {
                if (isLocked) {
                  // If locked, prevent editing by restoring previous value or skip
                  return;
                }
                onChanged(text);
              },
              readOnly: isLocked,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
            color: isLocked ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
          tooltip: isLocked ? 'Destravar' : 'Travar',
          onPressed: () => onLockChanged(!isLocked),
        ),
      ],
    );
  }
}
