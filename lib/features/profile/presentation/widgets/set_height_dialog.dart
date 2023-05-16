import 'package:flutter/material.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetHeightDialog extends StatelessWidget {
  static const _heightRangeCM = 100.0;

  final double userHeightCM;

  const SetHeightDialog({Key? key, required this.userHeightCM})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double selectedHeightCM = userHeightCM;
    return AlertDialog(
      title: Text(S.of(context).selectHeightDialogLabel),
      content: Wrap(
        children: [
          Column(
            children: [
              HorizontalPicker(
                  height: 100,
                  backgroundColor: Colors.transparent,
                  minValue: selectedHeightCM - _heightRangeCM,
                  maxValue: selectedHeightCM + _heightRangeCM,
                  divisions: 400,
                  suffix: ' ${S.of(context).cmLabel}',
                  onChanged: (value) {
                    selectedHeightCM = value;
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
              Navigator.pop(context, selectedHeightCM);
            },
            child: Text(S.of(context).dialogOKLabel))
      ],
    );
  }
}
