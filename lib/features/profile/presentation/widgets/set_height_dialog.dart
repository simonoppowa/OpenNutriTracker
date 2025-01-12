import 'package:flutter/material.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetHeightDialog extends StatelessWidget {
  static const _heightRangeCM = 100.0;
  static const _heightRangeFt = 10;

  final double userHeight;
  final bool usesImperialUnits;

  const SetHeightDialog(
      {super.key, required this.userHeight, required this.usesImperialUnits});

  @override
  Widget build(BuildContext context) {
    double selectedHeight = userHeight;
    return AlertDialog(
      title: Text(S.of(context).selectHeightDialogLabel),
      content: Wrap(
        children: [
          Column(
            children: [
              HorizontalPicker(
                  height: 100,
                  backgroundColor: Colors.transparent,
                  minValue: usesImperialUnits
                      ? selectedHeight - _heightRangeFt
                      : selectedHeight - _heightRangeCM,
                  maxValue: usesImperialUnits
                      ? selectedHeight + _heightRangeFt
                      : selectedHeight + _heightRangeCM,
                  divisions: 400,
                  suffix: usesImperialUnits
                      ? S.of(context).ftLabel
                      : S.of(context).cmLabel,
                  onChanged: (value) {
                    selectedHeight = value;
                  })
            ],
          )
        ],
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel)),
        TextButton(
            onPressed: () {
              // TODO validate selected height
              Navigator.pop(context, selectedHeight);
            },
            child: Text(S.of(context).dialogOKLabel))
      ],
    );
  }
}
