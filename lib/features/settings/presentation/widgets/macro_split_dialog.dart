import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/reload_diary_and_trends.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// Rounds three macro percentage shares to integers that sum to exactly 100.
///
/// Uses the largest-remainder method so the result stays as close as possible
/// to the unconstrained ratio. Independent `.round()` is unsafe here: two
/// half-up `.5` remainders produce 101, and `SettingsBloc.setMacroGoals`
/// truncates via `toInt()/100`.
@visibleForTesting
(int carbs, int protein, int fat) roundMacroPercentsToHundred(
  double carbsPct,
  double proteinPct,
  double fatPct,
) {
  const defaultCarbs = 60.0;
  const defaultProtein = 15.0;
  const defaultFat = 25.0;

  final values = [carbsPct, proteinPct, fatPct];
  final total = values.fold<double>(0, (sum, v) => sum + v);
  final scaled = total <= 0
      ? const [defaultCarbs, defaultProtein, defaultFat]
      : [for (final v in values) v * 100.0 / total];

  final floors = [for (final v in scaled) v.floor()];
  final remaining = 100 - floors.reduce((a, b) => a + b);
  final order = List<int>.generate(3, (i) => i)
    ..sort((a, b) {
      final fracCmp = (scaled[b] - floors[b]).compareTo(scaled[a] - floors[a]);
      if (fracCmp != 0) return fracCmp;
      // Prefer the originally larger share; fall back to lower index for a
      // deterministic triple when both remainder and magnitude match.
      final sizeCmp = scaled[b].compareTo(scaled[a]);
      if (sizeCmp != 0) return sizeCmp;
      return a.compareTo(b);
    });
  final result = List<int>.from(floors);
  for (var i = 0; i < remaining; i++) {
    result[order[i]]++;
  }
  return (result[0], result[1], result[2]);
}

/// Three sliders that distribute the daily kcal goal across
/// carbohydrate, protein, and fat. Moving any one slider rebalances
/// the other two against 100% so the trio always adds up, with each
/// macro pinned to a 5% floor so the diary still has something to
/// track against if a user pulls one slider all the way down.
///
/// A `Percent | Grams` switch (#642) swaps the sliders for three gram
/// fields that are set independently and do not follow the calorie goal.
class MacroSplitDialog extends StatefulWidget {
  final SettingsBloc settingsBloc;
  final HomeBloc homeBloc;

  const MacroSplitDialog({
    super.key,
    required this.settingsBloc,
    required this.homeBloc,
  });

  @override
  State<MacroSplitDialog> createState() => _MacroSplitDialogState();
}

class _MacroSplitDialogState extends State<MacroSplitDialog> {
  static const double _defaultCarbsPct = 60;
  static const double _defaultProteinPct = 15;
  static const double _defaultFatPct = 25;
  static const double _minMacroPct = 5;
  static const double _maxMacroPct = 90;

  double _carbsPct = _defaultCarbsPct;
  double _proteinPct = _defaultProteinPct;
  double _fatPct = _defaultFatPct;
  bool _loaded = false;
  bool _syncingControllers = false;

  // #642: gram goals. [_grams] is the last valid value of each field, which
  // a cleared or non-numeric field snaps back to.
  bool _inGrams = false;
  MacroGrams? _grams;
  double _kcalGoal = 0;
  late final Map<_MacroField, TextEditingController> _gramControllers;
  late final Map<_MacroField, FocusNode> _gramFocusNodes;

  /// The field whose typed text has not been applied yet. Only this field's
  /// text is applied — last write wins. Reconciling conflicting edits across
  /// multiple fields at once isn't worth the complexity.
  ///
  /// Applying clears it. A controller's text is only a rounded copy of its
  /// value after a sync, so applying it a second time, after a slider has
  /// moved, would nudge the split away from the one on screen.
  _MacroField? _lastEditedMacro;

  late final TextEditingController _carbsController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;

  /// A typed value is applied when its field loses focus, not only on
  /// submit: the iOS number pad has no return key, so a submit never comes
  /// and the other two macros never visibly rebalanced (#1324).
  late final Map<_MacroField, FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _carbsController = TextEditingController();
    _proteinController = TextEditingController();
    _fatController = TextEditingController();
    _focusNodes = {
      for (final field in _MacroField.values)
        field: FocusNode()..addListener(() => _onFocusChanged(field)),
    };
    _gramControllers = {
      for (final field in _MacroField.values) field: TextEditingController(),
    };
    _gramFocusNodes = {
      for (final field in _MacroField.values)
        field: FocusNode()
          ..addListener(() {
            if (mounted && !_gramFocusNodes[field]!.hasFocus) {
              _commitGramInput(field);
            }
          }),
    };
    _load();
  }

  @override
  void dispose() {
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    for (final controller in _gramControllers.values) {
      controller.dispose();
    }
    for (final node in _gramFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged(_MacroField field) {
    if (!mounted || _focusNodes[field]!.hasFocus) return;
    if (_lastEditedMacro == field) _applyPendingTextInputs();
  }

  Future<void> _load() async {
    final carbs = await widget.settingsBloc.getUserCarbGoalPct();
    final protein = await widget.settingsBloc.getUserProteinGoalPct();
    final fat = await widget.settingsBloc.getUserFatGoalPct();
    final gramGoals = await widget.settingsBloc.getMacroGramGoals();
    final kcalGoal = await widget.settingsBloc.getKcalGoalWithoutActivities();
    if (!mounted) return;
    setState(() {
      _carbsPct = (carbs ?? _defaultCarbsPct / 100) * 100;
      _proteinPct = (protein ?? _defaultProteinPct / 100) * 100;
      _fatPct = (fat ?? _defaultFatPct / 100) * 100;
      _inGrams = gramGoals.inGrams;
      _grams = gramGoals.grams;
      _kcalGoal = kcalGoal.isFinite ? kcalGoal : 0;
      if (_inGrams) _grams ??= _gramsFromSplit();
      _loaded = true;
    });
    _syncControllers();
    _syncGramControllers();
  }

  /// The split on screen as whole grams of today's goal: where the gram
  /// fields start when the user first switches to grams.
  MacroGrams _gramsFromSplit() => MacroGramGoals.fromSplit(
    _kcalGoal,
    carbsPct: _carbsPct / 100,
    proteinPct: _proteinPct / 100,
    fatPct: _fatPct / 100,
  );

  double _gramsOf(_MacroField field) {
    final grams = _grams!;
    return switch (field) {
      _MacroField.carbs => grams.carbs,
      _MacroField.protein => grams.protein,
      _MacroField.fat => grams.fat,
    };
  }

  MacroGrams _withGrams(_MacroField field, double value) {
    final grams = _grams!;
    return (
      carbs: field == _MacroField.carbs ? value : grams.carbs,
      protein: field == _MacroField.protein ? value : grams.protein,
      fat: field == _MacroField.fat ? value : grams.fat,
    );
  }

  void _syncGramControllers() {
    if (_grams == null) return;
    for (final field in _MacroField.values) {
      _gramControllers[field]!.text = _gramsOf(field).round().toString();
    }
  }

  /// Applies a typed gram value as it is typed, so the energy line keeps
  /// up. Out-of-range and unparsable text waits for [_commitGramInput].
  void _onGramTextChanged(_MacroField field, String text) {
    final parsed = double.tryParse(text);
    if (!MacroGramGoals.isValidGrams(parsed)) return;
    setState(() => _grams = _withGrams(field, parsed!));
  }

  /// When a field is left or submitted: an empty or non-numeric value snaps
  /// back to the last valid one, and one above the maximum is clamped.
  void _commitGramInput(_MacroField field) {
    if (_grams == null) return;
    final parsed = double.tryParse(_gramControllers[field]!.text);
    if (parsed != null && parsed > MacroGramGoals.maxGrams) {
      setState(() => _grams = _withGrams(field, MacroGramGoals.maxGrams));
    } else if (MacroGramGoals.isValidGrams(parsed)) {
      setState(() => _grams = _withGrams(field, parsed!));
    }
    _gramControllers[field]!.text = _gramsOf(field).round().toString();
  }

  void _setInGrams(bool inGrams) {
    if (inGrams == _inGrams) return;
    if (inGrams) {
      _applyPendingTextInputs();
    } else {
      for (final field in _MacroField.values) {
        _commitGramInput(field);
      }
    }
    setState(() {
      _inGrams = inGrams;
      if (inGrams) _grams ??= _gramsFromSplit();
    });
    _syncGramControllers();
  }

  bool get _gramsAllZero {
    final grams = _grams;
    return grams == null || grams.carbs + grams.protein + grams.fat <= 0;
  }

  void _syncControllers() {
    _syncingControllers = true;
    try {
      _carbsController.text = _carbsPct.round().toString();
      _proteinController.text = _proteinPct.round().toString();
      _fatController.text = _fatPct.round().toString();
    } finally {
      _syncingControllers = false;
    }
  }

  void _markLastEdited(_MacroField field) {
    // Guard against programmatic controller updates from _syncControllers.
    // (Assigning controller.text doesn't currently fire TextField.onChanged,
    // but the flag keeps this correct if that ever changes.)
    if (_syncingControllers) return;
    _lastEditedMacro = field;
  }

  bool _isValidMacroPercentage(int? value) =>
      value != null && value >= _minMacroPct && value <= _maxMacroPct;

  int? _parseMacroPercentage(TextEditingController controller) {
    final parsed = int.tryParse(controller.text);
    return _isValidMacroPercentage(parsed) ? parsed : null;
  }

  /// Rebalance the two unmoved macros proportionally to their current
  /// ratio so the trio re-sums to 100. Each gets clamped to a 5% floor;
  /// anything that would push another macro below the floor is shaved
  /// off the larger of the two so the floors are always honoured.
  void _redistribute({
    required double moved,
    required void Function(double) setMoved,
    required double otherA,
    required void Function(double) setOtherA,
    required double otherB,
    required void Function(double) setOtherB,
    required double oldMoved,
  }) {
    final delta = moved - oldMoved;
    setMoved(moved);
    final totalOthers = otherA + otherB;
    if (totalOthers <= 0) return;
    final ratioA = otherA / totalOthers;
    final ratioB = otherB / totalOthers;
    var newA = otherA - delta * ratioA;
    var newB = otherB - delta * ratioB;
    if (newA < _minMacroPct) {
      newB -= _minMacroPct - newA;
      newA = _minMacroPct;
    }
    if (newB < _minMacroPct) {
      newA -= _minMacroPct - newB;
      newB = _minMacroPct;
    }
    setOtherA(newA);
    setOtherB(newB);
  }

  void _applyCarbsInput() {
    final parsed = _parseMacroPercentage(_carbsController);
    if (parsed == null) {
      _syncControllers();
      return;
    }
    setState(
      () => _redistribute(
        moved: parsed.toDouble(),
        oldMoved: _carbsPct,
        setMoved: (x) => _carbsPct = x,
        otherA: _proteinPct,
        setOtherA: (x) => _proteinPct = x,
        otherB: _fatPct,
        setOtherB: (x) => _fatPct = x,
      ),
    );
    _syncControllers();
  }

  void _applyProteinInput() {
    final parsed = _parseMacroPercentage(_proteinController);
    if (parsed == null) {
      _syncControllers();
      return;
    }
    setState(
      () => _redistribute(
        moved: parsed.toDouble(),
        oldMoved: _proteinPct,
        setMoved: (x) => _proteinPct = x,
        otherA: _carbsPct,
        setOtherA: (x) => _carbsPct = x,
        otherB: _fatPct,
        setOtherB: (x) => _fatPct = x,
      ),
    );
    _syncControllers();
  }

  void _applyFatInput() {
    final parsed = _parseMacroPercentage(_fatController);
    if (parsed == null) {
      _syncControllers();
      return;
    }
    setState(
      () => _redistribute(
        moved: parsed.toDouble(),
        oldMoved: _fatPct,
        setMoved: (x) => _fatPct = x,
        otherA: _carbsPct,
        setOtherA: (x) => _carbsPct = x,
        otherB: _proteinPct,
        setOtherB: (x) => _proteinPct = x,
      ),
    );
    _syncControllers();
  }

  void _applyPendingTextInputs() {
    final pending = _lastEditedMacro;
    _lastEditedMacro = null;
    switch (pending) {
      case _MacroField.carbs:
        _applyCarbsInput();
        break;
      case _MacroField.protein:
        _applyProteinInput();
        break;
      case _MacroField.fat:
        _applyFatInput();
        break;
      case null:
        break;
    }
  }

  Future<void> _save() async {
    if (_inGrams) {
      for (final field in _MacroField.values) {
        _commitGramInput(field);
      }
      if (_gramsAllZero) return;
      final grams = _grams!;
      await widget.settingsBloc.setMacroGramGoals(
        grams.carbs,
        grams.protein,
        grams.fat,
      );
    } else {
      await _saveSplit();
    }
    widget.settingsBloc.add(LoadSettingsEvent());
    widget.homeBloc.add(const LoadItemsEvent());
    await widget.settingsBloc.updateTrackedDay(
      await widget.settingsBloc.getCurrentLogicalDay(),
    );
    reloadDiaryAndTrends();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Saves the percentage split, which also switches gram goals off.
  Future<void> _saveSplit() async {
    _applyPendingTextInputs();
    // [_redistribute] leaves fractional percentages. Independent `.round()`
    // can sum to 99 or 101 (two half-up .5s → 101), and setMacroGoals stores
    // via toInt()/100 — so balance to an exact 100% integer triple first.
    final rounded = roundMacroPercentsToHundred(
      _carbsPct,
      _proteinPct,
      _fatPct,
    );
    await widget.settingsBloc.setMacroGoals(
      rounded.$1.toDouble(),
      rounded.$2.toDouble(),
      rounded.$3.toDouble(),
    );
  }

  List<Widget> _buildGramFields(BuildContext context, S s) {
    final theme = Theme.of(context);
    final usesKj =
        Provider.of<EnergyUnitProvider?>(
          context,
          listen: false,
        )?.usesKilojoules ??
        false;
    String energy(double kcal) =>
        (usesKj ? UnitCalc.kcalToKj(kcal) : kcal).round().toString();
    final grams = _grams;
    return [
      Text(s.macroGoalGramsExplanation, style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      for (final (field, label, id) in [
        (_MacroField.carbs, s.carbsLabel, 'macro-split-carbs-grams'),
        (_MacroField.protein, s.proteinLabel, 'macro-split-protein-grams'),
        (_MacroField.fat, s.fatLabel, 'macro-split-fat-grams'),
      ])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: MediaQuery.textScalerOf(context).scale(96),
                // The macro's name sits in a sibling Text, so the field
                // carries it for TalkBack and VoiceOver.
                child: Semantics(
                  identifier: id,
                  label: label,
                  child: TextField(
                    controller: _gramControllers[field],
                    focusNode: _gramFocusNodes[field],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      suffixText: s.gramUnit,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (text) => _onGramTextChanged(field, text),
                    onSubmitted: (_) => _commitGramInput(field),
                  ),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 8),
      if (grams != null)
        Text(
          s.macroGoalGramsEnergySum(
            energy(MacroGramGoals.kcalOf(grams)),
            energy(_kcalGoal),
            usesKj ? s.kjLabel : s.kcalLabel,
          ),
          style: theme.textTheme.bodySmall,
        ),
      if (_gramsAllZero)
        Text(
          s.macroGoalGramsAllZero,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final totalPct = _carbsPct.round() + _proteinPct.round() + _fatPct.round();
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              s.settingsMacroSplitLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Reset restores the default split; gram goals have no default.
          if (!_inGrams)
            TextButton(
              onPressed: _loaded
                  ? () {
                      _lastEditedMacro = null;
                      setState(() {
                        _carbsPct = _defaultCarbsPct;
                        _proteinPct = _defaultProteinPct;
                        _fatPct = _defaultFatPct;
                      });
                      _syncControllers();
                    }
                  : null,
              child: Text(s.buttonResetLabel),
            ),
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
                  Semantics(
                    identifier: 'macro-split-mode',
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(
                            s.macroGoalModePercentLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(
                            s.macroGoalModeGramsLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      selected: {_inGrams},
                      showSelectedIcon: false,
                      onSelectionChanged: (selected) =>
                          _setInGrams(selected.first),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_inGrams)
                    ..._buildGramFields(context, s)
                  else ...[
                    Text(
                      '$totalPct% total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    _MacroRow(
                      label: s.carbsLabel,
                      value: _carbsPct,
                      color: Colors.orange,
                      controller: _carbsController,
                      focusNode: _focusNodes[_MacroField.carbs]!,
                      semanticIdentifier: 'macro-split-carbs',
                      onSliderChanged: (v) => setState(
                        () => _redistribute(
                          moved: v,
                          oldMoved: _carbsPct,
                          setMoved: (x) => _carbsPct = x,
                          otherA: _proteinPct,
                          setOtherA: (x) => _proteinPct = x,
                          otherB: _fatPct,
                          setOtherB: (x) => _fatPct = x,
                        ),
                      ),
                      onSliderEnd: _syncControllers,
                      onTextChanged: (_) => _markLastEdited(_MacroField.carbs),
                      onTextSubmitted: _applyPendingTextInputs,
                    ),
                    _MacroRow(
                      label: s.proteinLabel,
                      value: _proteinPct,
                      color: Colors.blue,
                      controller: _proteinController,
                      focusNode: _focusNodes[_MacroField.protein]!,
                      semanticIdentifier: 'macro-split-protein',
                      onSliderChanged: (v) => setState(
                        () => _redistribute(
                          moved: v,
                          oldMoved: _proteinPct,
                          setMoved: (x) => _proteinPct = x,
                          otherA: _carbsPct,
                          setOtherA: (x) => _carbsPct = x,
                          otherB: _fatPct,
                          setOtherB: (x) => _fatPct = x,
                        ),
                      ),
                      onSliderEnd: _syncControllers,
                      onTextChanged: (_) =>
                          _markLastEdited(_MacroField.protein),
                      onTextSubmitted: _applyPendingTextInputs,
                    ),
                    _MacroRow(
                      label: s.fatLabel,
                      value: _fatPct,
                      color: Colors.green,
                      controller: _fatController,
                      focusNode: _focusNodes[_MacroField.fat]!,
                      semanticIdentifier: 'macro-split-fat',
                      onSliderChanged: (v) => setState(
                        () => _redistribute(
                          moved: v,
                          oldMoved: _fatPct,
                          setMoved: (x) => _fatPct = x,
                          otherA: _carbsPct,
                          setOtherA: (x) => _carbsPct = x,
                          otherB: _proteinPct,
                          setOtherB: (x) => _proteinPct = x,
                        ),
                      ),
                      onSliderEnd: _syncControllers,
                      onTextChanged: (_) => _markLastEdited(_MacroField.fat),
                      onTextSubmitted: _applyPendingTextInputs,
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogCancelLabel),
        ),
        Semantics(
          identifier: 'macro-split-save',
          child: TextButton(
            onPressed: _loaded && !(_inGrams && _gramsAllZero) ? _save : null,
            child: Text(s.dialogOKLabel),
          ),
        ),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String semanticIdentifier;
  final ValueChanged<double> onSliderChanged;
  final VoidCallback onSliderEnd;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onTextSubmitted;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.color,
    required this.controller,
    required this.focusNode,
    required this.semanticIdentifier,
    required this.onSliderChanged,
    required this.onSliderEnd,
    required this.onTextChanged,
    required this.onTextSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final macroRange =
        _MacroSplitDialogState._maxMacroPct -
        _MacroSplitDialogState._minMacroPct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            SizedBox(
              // Scale the field width with the user's text setting so the
              // value and its % suffix stay readable at large font scales.
              width: MediaQuery.textScalerOf(context).scale(96),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  suffixText: '%',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                onChanged: onTextChanged,
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
          child: Semantics(
            identifier: semanticIdentifier,
            child: Slider(
              min: _MacroSplitDialogState._minMacroPct,
              max: _MacroSplitDialogState._maxMacroPct,
              value: value.clamp(
                _MacroSplitDialogState._minMacroPct,
                _MacroSplitDialogState._maxMacroPct,
              ),
              divisions: macroRange.toInt(),
              // Read as the share it sets, not the slider's position.
              semanticFormatterCallback: (v) => '${v.round()}%',
              onChanged: (v) {
                final rounded = v.round().toDouble();
                if (100 - rounded >= 10) {
                  onSliderChanged(rounded);
                }
              },
              onChangeEnd: (_) => onSliderEnd(),
            ),
          ),
        ),
      ],
    );
  }
}

enum _MacroField { carbs, protein, fat }
