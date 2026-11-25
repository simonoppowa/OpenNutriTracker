import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/custom_text_input_formatter.dart';
import 'package:opennutritracker/generated/l10n.dart';

class EditDialog extends StatefulWidget {
  final IntakeEntity intakeEntity;
  final bool usesImperialUnits;

  const EditDialog({
    super.key,
    required this.intakeEntity,
    required this.usesImperialUnits,
  });

  @override
  State<StatefulWidget> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  /// The fractions offered for what was left uneaten.
  static const leftoverFractions = {'¼': 0.25, '⅓': 1 / 3, '½': 0.5, '¾': 0.75};

  late TextEditingController amountEditingController;
  final leftoverEditingController = TextEditingController();

  /// The amount as logged, in the units shown, which what is left over is
  /// taken from.
  late final double _loggedAmount;

  @override
  void initState() {
    super.initState();
    double initialAmount = _convertValue(
      widget.intakeEntity.amount,
      widget.intakeEntity.meal.mealUnit,
    );
    _loggedAmount = initialAmount;
    amountEditingController = TextEditingController(
      text: initialAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    amountEditingController.dispose();
    leftoverEditingController.dispose();
    super.dispose();
  }

  /// Sets the amount to what was logged minus what was left, so the new
  /// amount shows in its own field before it is saved. A leftover that is
  /// not a number, or more than was logged, changes nothing.
  void _onLeftoverChanged(String text) {
    final left = double.tryParse(text.replaceAll(',', '.'));
    if (left == null || left < 0 || left > _loggedAmount) return;
    amountEditingController.text = (_loggedAmount - left).toStringAsFixed(2);
  }

  void _onLeftoverFraction(double fraction) {
    leftoverEditingController.text = (_loggedAmount * fraction).toStringAsFixed(
      2,
    );
    _onLeftoverChanged(leftoverEditingController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).editItemDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: amountEditingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: CustomTextInputFormatter.doubleOnly(),
            decoration: InputDecoration(
              labelText: S.of(context).quantityLabel,
              suffixText: _convertUnit(widget.intakeEntity.meal.mealUnit ?? ''),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: leftoverEditingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: CustomTextInputFormatter.doubleOnly(),
            onChanged: _onLeftoverChanged,
            decoration: InputDecoration(
              labelText: S.of(context).leftoverLabel,
              suffixText: _convertUnit(widget.intakeEntity.meal.mealUnit ?? ''),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final MapEntry(key: label, value: fraction)
                  in leftoverFractions.entries)
                ActionChip(
                  label: Text(label),
                  onPressed: () => _onLeftoverFraction(fraction),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final newAmount = double.tryParse(
              amountEditingController.text.replaceAll(',', '.'),
            );
            if (newAmount == null) return;
            Navigator.of(context).pop(
              _convertBackToMetricValue(
                newAmount,
                widget.intakeEntity.meal.mealUnit,
              ),
            );
          },
          child: Text(S.of(context).dialogOKLabel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(S.of(context).dialogCancelLabel),
        ),
      ],
    );
  }

  double _convertValue(double value, String? unit) {
    switch (unit) {
      case 'g':
        return widget.usesImperialUnits ? UnitCalc.gToOz(value) : value;
      case 'ml':
        return widget.usesImperialUnits ? UnitCalc.mlToFlOz(value) : value;
      default:
        return value;
    }
  }

  double _convertBackToMetricValue(double value, String? unit) {
    switch (unit) {
      case 'g':
        return widget.usesImperialUnits ? UnitCalc.ozToG(value) : value;
      case 'ml':
        return widget.usesImperialUnits ? UnitCalc.flOzToMl(value) : value;
      default:
        return value;
    }
  }

  String _convertUnit(String unit) {
    switch (unit) {
      case 'g':
        return widget.usesImperialUnits ? 'oz' : 'g';
      case 'ml':
        return widget.usesImperialUnits ? 'fl.oz' : 'ml';
      default:
        return unit;
    }
  }
}
