import 'package:flutter/material.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetWeightDialog extends StatelessWidget {
  static const weightRangeKg = 50.0;
  static const weightRangeLbs = 100.0;

  final double userWeight;
  final bool usesImperialUnits;

  const SetWeightDialog(
      {super.key, required this.userWeight, required this.usesImperialUnits});

  @override
  Widget build(BuildContext context) {
    double selectedWeight = userWeight;
    return AlertDialog(
      title: Text(S.of(context).selectWeightDialogLabel),
      content: Wrap(children: [
        Column(
          children: [
            HorizontalPicker(
                height: 100,
                backgroundColor: Colors.transparent,
                minValue: usesImperialUnits
                    ? userWeight - weightRangeLbs
                    : userWeight - weightRangeKg,
                maxValue: usesImperialUnits
                    ? userWeight + weightRangeLbs
                    : userWeight + weightRangeKg,
                initialPosition: InitialPosition.center,
                divisions: 1000,
                suffix: usesImperialUnits
                    ? S.of(context).lbsLabel
                    : S.of(context).kgLabel,
                onChanged: (value) {
                  selectedWeight = value;
                })
          ],
        )
      ]),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel)),
        TextButton(
            onPressed: () {
              // TODO validate selected weight
              Navigator.pop(context, selectedWeight);
            },
            child: Text(S.of(context).dialogOKLabel)),
      ],
    );
  }
}
