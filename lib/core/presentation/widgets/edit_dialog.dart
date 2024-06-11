import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class EditDialog extends StatefulWidget {
  final IntakeEntity intakeEntity;

  const EditDialog({super.key, required this.intakeEntity});

  @override
  State<StatefulWidget> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {


  @override
  Widget build(BuildContext context) {
    var amountEditingController = TextEditingController(text: widget.intakeEntity.amount.toInt().toString());
    return AlertDialog(
      title: Text(S.of(context).editItemDialogTitle),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(
          controller: amountEditingController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: S.of(context).quantityLabel,
            suffixText: widget.intakeEntity.meal.mealUnit ?? S.of(context).gramMilliliterUnit
          ),
        )
      ]),
      actions: [
        TextButton(
            onPressed: () {
              double newAmount = double.parse(amountEditingController.text);
              Navigator.of(context).pop(newAmount);
            },
            child: Text(S.of(context).dialogOKLabel)),
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel))
      ],
    );
  }
}
