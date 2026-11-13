import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// #32: simple "how much did you just drink?" dialog. A slider feels
/// kinder than a numeric keypad for the common case where the person
/// already knows roughly how much they had — half a glass, a regular
/// glass, a large bottle — and only needs to land on the nearest
/// 50 ml. "Undo last" handles the more frustrating case where you tap
/// the wrong amount and want to take it back without doing the
/// mental arithmetic of "subtract X from the running total".
class LogWaterDialog extends StatefulWidget {
  static const int sliderMaxMl = 1000;
  static const int sliderStepMl = 50;
  static const int sliderDivisions = sliderMaxMl ~/ sliderStepMl;
  static const int sliderDefaultMl = 250;

  // #1306: with imperial food units the slider runs in whole fluid ounces,
  // up to a quart, starting on a cup. The amount is still stored in ml.
  static const int sliderMaxFlOz = 32;
  static const int sliderDefaultFlOz = 8;

  final bool usesImperialUnits;

  const LogWaterDialog({super.key, this.usesImperialUnits = false});

  @override
  State<LogWaterDialog> createState() => _LogWaterDialogState();
}

class _LogWaterDialogState extends State<LogWaterDialog> {
  // The slider value, in ml or in fl oz depending on the unit setting.
  late double _selected = widget.usesImperialUnits
      ? LogWaterDialog.sliderDefaultFlOz.toDouble()
      : LogWaterDialog.sliderDefaultMl.toDouble();

  int get _selectedMl => widget.usesImperialUnits
      ? UnitCalc.flOzToMl(_selected).round()
      : _selected.round();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      shape: Dimens.shapeL,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              s.logWaterDialogTitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            identifier: 'log-water-reset',
            container: true,
            child: TextButton(
              onPressed: _selected == 0
                  ? null
                  : () => setState(() => _selected = 0),
              child: Text(s.buttonResetLabel),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.usesImperialUnits
                ? s.logWaterAmountLabelFlOz(_selected.round())
                : s.logWaterAmountLabel(_selected.round()),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Semantics(
            identifier: 'log-water-slider',
            child: Slider(
              value: _selected,
              min: 0,
              max: widget.usesImperialUnits
                  ? LogWaterDialog.sliderMaxFlOz.toDouble()
                  : LogWaterDialog.sliderMaxMl.toDouble(),
              divisions: widget.usesImperialUnits
                  ? LogWaterDialog.sliderMaxFlOz
                  : LogWaterDialog.sliderDivisions,
              label: widget.usesImperialUnits
                  ? '${_selected.round()} ${s.flOzUnit}'
                  : '${_selected.round()} ${s.mlLabel}',
              onChanged: (value) {
                setState(() => _selected = value);
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              identifier: 'log-water-undo',
              child: TextButton.icon(
                icon: const Icon(Icons.undo_rounded),
                label: Text(s.logWaterUndoLabel),
                onPressed: _onUndoPressed,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Semantics(
          identifier: 'log-water-cancel',
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.dialogCancelLabel),
          ),
        ),
        Semantics(
          identifier: 'log-water-save',
          child: FilledButton(
            onPressed: _onSavePressed,
            child: Text(s.dialogOKLabel),
          ),
        ),
      ],
    );
  }

  Future<void> _onSavePressed() async {
    final amount = _selectedMl;
    final navigator = Navigator.of(context);
    if (amount > 0) {
      await locator<HomeBloc>().addWaterIntake(amount);
    }
    if (mounted) {
      navigator.pop();
    }
  }

  Future<void> _onUndoPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final undone = await locator<HomeBloc>().undoLastWaterIntake();
    if (!mounted) return;
    if (!undone) {
      messenger.showSnackBar(
        SnackBar(content: Text(S.of(context).logWaterNothingToUndoLabel)),
      );
    }
  }
}
