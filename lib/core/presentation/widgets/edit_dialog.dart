import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/custom_text_input_formatter.dart';
import 'package:opennutritracker/generated/l10n.dart';

class EditDialog extends StatefulWidget {
  /// What the dialog returns when the user taps Delete. OK never returns
  /// it: an amount of 0 or less is refused.
  static const deleteResult = -1.0;

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
  late TextEditingController amountEditingController;

  @override
  void initState() {
    super.initState();
    double initialAmount = _convertValue(
      widget.intakeEntity.amount,
      widget.intakeEntity.meal.mealUnit,
    );
    amountEditingController = TextEditingController(
      text: initialAmount.toStringAsFixed(2),
    );
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
        ],
      ),
      // Delete on its own on the left, so deleting needs no long-press or
      // drag; Cancel and the confirming OK together on the right.
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        Semantics(
          identifier: 'edit-item-delete',
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(EditDialog.deleteResult),
            child: Text(S.of(context).dialogDeleteLabel),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).dialogCancelLabel),
            ),
            TextButton(
              onPressed: () {
                final newAmount = double.tryParse(
                  amountEditingController.text.replaceAll(',', '.'),
                );
                if (newAmount == null || newAmount <= 0) return;
                Navigator.of(context).pop(
                  _convertBackToMetricValue(
                    newAmount,
                    widget.intakeEntity.meal.mealUnit,
                  ),
                );
              },
              child: Text(S.of(context).dialogOKLabel),
            ),
          ],
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
